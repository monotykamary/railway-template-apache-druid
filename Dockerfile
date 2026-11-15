FROM apache/druid:38.0.0@sha256:4156a8ca87b855ff6c14f9d95529149b64fe56e25cb394d3043957efae0b9054 AS druid

FROM eclipse-temurin:21.0.13_9-jre-jammy@sha256:dff6eb46527bd293a3c06bbbe9e64e8c9f91f01905b5abbdad31761c03059d2c

RUN apt-get update \
  && apt-get install -y --no-install-recommends perl procps \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --gid 1000 druid \
  && useradd --uid 1000 --gid 1000 --home-dir /opt/druid --shell /bin/bash druid

COPY --from=druid --chown=druid:druid /opt/druid /opt/druid
COPY --chown=druid:druid entrypoint.sh /opt/druid/railway-entrypoint
RUN mkdir -p /opt/shared \
  && chown -R druid:druid /opt/shared \
  && chmod 755 /opt/druid/railway-entrypoint

USER root
WORKDIR /opt/druid
EXPOSE 8888

ENTRYPOINT ["/opt/druid/railway-entrypoint"]
