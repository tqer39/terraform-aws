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

async function dependency(manager, updateType, security = false) {
  const [defaults, utils, rules] = await modules;
  let result = utils.mergeChildConfig(defaults.getConfig(), config);
  result = await rules.applyPackageRules({ ...result, manager, updateType });
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
