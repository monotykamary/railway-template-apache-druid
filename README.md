# Apache Druid on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/apache-druid-single-node)

A secured, persistent [Apache Druid](https://druid.apache.org/) single-node quickstart for evaluation and small analytics workloads. The wrapper pins Druid `38.0.0`, copies the official Java distribution into Temurin `17.0.19+10`, enables Druid Basic Security, and persists metadata, task state, and segments on one volume.

## Architecture

One container supervises ZooKeeper plus Druid Coordinator/Overlord, Broker, Router, Historical, and MiddleManager processes. This consolidation is deliberate: the upstream nano quickstart uses shared local metadata, deep storage, and task directories.

- **Router**: public web console and API on port `8888`.
- **Volume** at `/opt/druid/var`: embedded Derby metadata, ZooKeeper state, local deep storage, segment cache, and indexing logs.

## After deployment

1. Allocate at least **4 GB RAM**; 5 GB or more is recommended for ingestion.
2. Open the generated domain. The browser prompts for Basic Auth.
3. Sign in as `admin` with `DRUID_ADMIN_PASSWORD`.
4. Load a sample from the web console or submit an ingestion task, then query it with Druid SQL.
5. Back up the volume before upgrades.

`DRUID_INTERNAL_PASSWORD` is generated separately for authenticated communication among Druid roles. Never make it public.

## Important limitations

- This is the upstream **nano quickstart**, not a production HA cluster.
- ZooKeeper, Derby metadata, local deep storage, and every Druid role share one container and volume.
- Horizontal scaling, rolling role upgrades, replication across hosts, and failure isolation are not provided.
- JVM processor detection is capped at two cores so the six quickstart roles remain within Railway's container thread limit.
- The Router can become healthy before Historical has re-announced every segment after restart; allow a short convergence period before querying.
- Production deployments should use external metadata storage, durable deep storage, separate roles, and capacity planning.

## Updating

Update the Druid image tag/digest and compatible Temurin tag/digest, rebuild for amd64, then test unauthenticated denial, admin console access, internal role discovery, ingestion, SQL, graceful shutdown, and restart persistence.

## Upstream

- Source: https://github.com/apache/druid
- Documentation: https://druid.apache.org/docs/latest/
- Release: https://github.com/apache/druid/releases/tag/druid-38.0.0
- License: [Apache License 2.0](LICENSE)
- Temurin: https://adoptium.net/temurin/releases/?version=17
