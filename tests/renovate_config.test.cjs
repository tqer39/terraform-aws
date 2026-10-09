// 実行: node --test tests/renovate_config.test.cjs
// 別のインストールを使う場合はRENOVATE_PACKAGE_DIRでRenovateのディレクトリを指定する。
// Renovate本体で設定を解決し、独自のルール評価や日付判定を再実装しない。
// cspell:ignore datasource
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { createRequire } = require('node:module');
const { dirname, join, resolve } = require('node:path');
const { pathToFileURL } = require('node:url');
const { test } = require('node:test');

const renovateDir = process.env.RENOVATE_PACKAGE_DIR || dirname(require.resolve('renovate/package.json'));
const renovateRequire = createRequire(join(resolve(renovateDir), 'package.json'));
const config = renovateRequire('json5').parse(
  readFileSync(join(__dirname, '..', 'renovate.json5'), 'utf8'),
);
const load = (path) => import(pathToFileURL(join(renovateDir, 'dist', path)).href);
const modules = Promise.all([
  load('config/defaults.js'),
  load('config/utils.js'),
  load('util/package-rules/index.js'),
  load('util/minimum-release-age.js'),
  load('workers/repository/process/lookup/filter-checks.js'),
  load('modules/versioning/semver/index.js'),
]);

async function dependency(manager, updateType, security = false, details = {}) {
  const [defaults, utils, rules] = await modules;
  let result = utils.mergeChildConfig(defaults.getConfig(), config);
  result = await rules.applyPackageRules({
    ...result, manager, updateType,
    depType: manager === 'github-actions' ? 'action' : undefined,
    ...details,
  });
  if (security) result = utils.mergeChildConfig(result, result.vulnerabilityAlerts);
  return result;
}

test('新規リリースと公開日時不明の通常更新を保留する', async () => {
  const [, , , age] = await modules;
  for (const manager of ['npm', 'terraform', 'github-actions']) {
    const policy = await dependency(manager, 'patch');
    const yesterday = new Date(Date.now() - 86400000).toISOString();
    const lastWeek = new Date(Date.now() - 8 * 86400000).toISOString();
    assert.equal(age.checkMinimumReleaseAge(policy, yesterday).isPending, true);
    assert.equal(age.checkMinimumReleaseAge(policy, undefined).isPending, true);
    assert.equal(age.checkMinimumReleaseAge(policy, lastWeek).isPending, false);
  }
});

test('Terraform本体の3種類の参照をまとめ、AWS providerは別に更新する', async () => {
  const { GlobalConfig } = await load('config/global.js');
  GlobalConfig.set({ localDir: join(__dirname, '..') });
  const refs = [
    ['mise', 'mise.toml'],
    ['terraform-version', '.terraform-version'],
    ['terraform', 'terraform/envs/management/base/terraform.tf'],
  ];
  for (const [manager, file] of refs) {
    const extraction = await load(`modules/manager/${manager}/extract.js`);
    const result = await extraction.extractPackageFile(
      readFileSync(join(__dirname, '..', file), 'utf8'), file, {},
    );
    const terraform = result.deps.find((dep) =>
      (dep.packageName || dep.depName) === 'hashicorp/terraform');
    assert.ok(terraform, file);
    const policy = await dependency(manager, 'patch', false, terraform);
    assert.equal(policy.groupName, 'Terraform runtime', file);
    assert.equal(policy.groupSlug, 'terraform-runtime', file);
    assert.equal(policy.minimumReleaseAge, '7 days', file);
    if (manager === 'terraform') {
      const aws = result.deps.find((dep) => dep.depName === 'aws');
      assert.notEqual((await dependency(manager, 'minor', false, aws)).groupName,
        'Terraform runtime');
    }
  }
});

test('最新候補が新しすぎるときは待機を終えた版を選ぶ', async () => {
  const [, , , , checks, versioning] = await modules;
  const policy = await dependency('npm', 'patch');
  const result = await checks.filterInternalChecks({
    ...policy,
    datasource: 'npm',
    depName: 'fixture',
    packageName: 'fixture',
    currentVersion: '1.0.0',
  }, versioning.api, 'patch', [
    { version: '1.0.1', releaseTimestamp: new Date(Date.now() - 8 * 86400000).toISOString() },
    { version: '1.0.2', releaseTimestamp: new Date(Date.now() - 86400000).toISOString() },
  ]);
  assert.equal(result.release.version, '1.0.1');
  assert.equal(result.pendingChecks, false);
});

test('全候補が新しすぎる場合は通常PRの作成を保留する', async () => {
  const [, , , , checks, versioning] = await modules;
  const policy = await dependency('npm', 'patch');
  const result = await checks.filterInternalChecks({
    ...policy,
    datasource: 'npm',
    depName: 'fixture',
    packageName: 'fixture',
    currentVersion: '1.0.0',
  }, versioning.api, 'patch', [
    { version: '1.0.1', releaseTimestamp: new Date().toISOString() },
  ]);
  assert.equal(result.pendingChecks, true);
});

test('Actionsの初回固定だけを急ぎ、digest更新は待機する', async () => {
  const [, , , age] = await modules;
  const pin = await dependency('github-actions', 'pinDigest');
  const update = await dependency('github-actions', 'digest');
  assert.equal(pin.pinDigests, true);
  assert.equal(age.checkMinimumReleaseAge(pin, new Date().toISOString()).isPending, false);
  assert.equal(age.checkMinimumReleaseAge(update, new Date().toISOString()).isPending, true);
  const otherManager = await dependency('npm', 'pinDigest');
  assert.equal(age.checkMinimumReleaseAge(otherManager, new Date().toISOString()).isPending, true);
});

test('脆弱性修正は即時提案するが自動マージもスクリプト実行もしない', async () => {
  const [, , , age] = await modules;
  for (const security of [false, true]) {
    const policy = await dependency('npm', 'patch', security);
    assert.equal(policy.automerge, false);
    assert.equal(policy.platformAutomerge, false);
    assert.equal(policy.ignoreScripts, true);
    if (security) {
      assert.equal(age.checkMinimumReleaseAge(policy, new Date().toISOString()).isPending, false);
      assert.equal(policy.prCreation, 'immediate');
    }
  }
});

test('TFLintのCLIバージョンをSHAに置き換えず、Actionとコンテナは固定する', async () => {
  const { GlobalConfig } = await load('config/global.js');
  GlobalConfig.set({ localDir: join(__dirname, '..') });
  const extraction = await load('modules/manager/github-actions/extract.js');
  const fixture = 'name: Test\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n' +
    '    steps:\n      - uses: terraform-linters/setup-tflint@v6.3.2\n' +
    '        with:\n          tflint_version: v0.55.1\n';
  const result = await extraction.extractPackageFile(fixture, '.github/workflows/test.yml');
  const tool = result.deps.find((dep) => dep.depName === 'tflint');
  assert.equal(tool.depType, 'uses-with');
  const toolPolicy = await dependency('github-actions', 'pinDigest', false, tool);
  assert.equal(toolPolicy.pinDigests, false);
  assert.equal(toolPolicy.minimumReleaseAge, '7 days');
  const [, , , age] = await modules;
  assert.equal(age.checkMinimumReleaseAge(toolPolicy, new Date().toISOString()).isPending, true);
  for (const depType of ['action', 'workflow', 'docker', 'container', 'service']) {
    const policy = await dependency('github-actions', 'pinDigest', false, { depType });
    assert.equal(policy.pinDigests, true);
  }
});
