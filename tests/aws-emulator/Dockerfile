FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal@sha256:158a9044f9dc0777f098b76c8b54346f6ed4560b9a6a416dec7a5ba3bc483af4
ARG EMULATOR_VERSION
ARG PACKAGE_ARCH
ARG PACKAGE_SHA256
ADD https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/aws-emulator-${EMULATOR_VERSION}-1-${PACKAGE_ARCH}.rpm /tmp/emulator.rpm
RUN echo "${PACKAGE_SHA256}  /tmp/emulator.rpm" | sha256sum -c - \
    && rpm -i /tmp/emulator.rpm && rm /tmp/emulator.rpm \
    && mkdir -p /home/emulator && chown 1000 /home/emulator
USER 1000
ENV HOME=/home/emulator
EXPOSE 9297
ENTRYPOINT ["aws-emulator", "-b", "0.0.0.0", "--telemetry", "off"]
