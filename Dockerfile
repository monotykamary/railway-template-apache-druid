FROM apache/druid:38.0.0@sha256:4156a8ca87b855ff6c14f9d95529149b64fe56e25cb394d3043957efae0b9054 AS druid

FROM eclipse-temurin:21.0.12.1_1-jre-jammy@sha256:f04fb34e053148344e83317976114ec3f37e4b830ec8bdab5a2fe3cecd7d010b

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
