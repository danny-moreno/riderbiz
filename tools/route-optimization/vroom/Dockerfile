FROM ghcr.io/vroom-project/vroom-docker@sha256:189fabbb238f4891d821008b47b62085357be6a74f178656af5b253ced8f7069

COPY disable-access-log.cjs /opt/riderbiz/disable-access-log.cjs
RUN node /opt/riderbiz/disable-access-log.cjs
