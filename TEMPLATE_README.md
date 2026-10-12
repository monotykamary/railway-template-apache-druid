# Deploy and Host Apache Druid on Railway

## About Hosting Apache Druid

Apache Druid is a high-performance analytics database for event-oriented data and low-latency OLAP queries. This template packages the Druid `38.0.0` nano quickstart with Basic Security and persistent local storage for evaluation and small workloads.

## Common Use Cases

- Explore Druid ingestion and SQL
- Build analytics proofs of concept
- Evaluate event and time-series query performance
- Run a small, single-node development dataset

## Dependencies for Apache Druid Hosting

### Deployment Dependencies

The template creates one source-backed service and one volume mounted at `/opt/druid/var`. The service needs at least 4 GB RAM. All Druid roles, ZooKeeper, embedded Derby metadata, and local deep storage intentionally share that service and volume. JVM processor detection is capped at two cores so the six quickstart roles remain within Railway's container thread limit.

### Implementation Details

The Druid Router owns the public domain on port `8888`. The wrapper loads `druid-basic-security`, creates the `admin` user from `DRUID_ADMIN_PASSWORD`, creates the internal `druid_system` identity from `DRUID_INTERNAL_PASSWORD`, and configures an authenticated escalator for role-to-role calls. `/status/health` and `/status/ready` are the only unauthenticated paths.

The generated admin password is the first administrator credential. Do not expose the independently generated internal password. After restart, segment availability can lag Router health briefly while the Coordinator and Historical converge.

### Why Deploy Apache Druid on Railway?

Railway offers a fast source deploy, HTTPS endpoint, generated credentials, health checks, and persistent disk for a self-contained Druid evaluation environment. The template is deliberately labeled single-node and does not disguise the need for a real cluster topology in production.
