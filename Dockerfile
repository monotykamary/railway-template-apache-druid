FROM apache/druid:37.0.0@sha256:0116fb802786649fc3635d6d4ab5be4da8abee3edafbe95c7f358a564d4c82e8 AS druid

FROM eclipse-temurin:17.0.19_10-jre-jammy@sha256:89e68b9bb83713510b63e2059a415792a7fc77e14b739a7d7ede97f6d9ca2c38

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

USER druid
WORKDIR /opt/druid
VOLUME ["/opt/druid/var"]
EXPOSE 8888

ENTRYPOINT ["/opt/druid/railway-entrypoint"]
