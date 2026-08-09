#!/bin/sh
set -eu
umask 077

require() {
  name="$1"
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    printf 'Required variable %s is not set.\n' "$name" >&2
    exit 1
  fi
}

for name in DRUID_ADMIN_PASSWORD DRUID_INTERNAL_PASSWORD; do
  require "$name"
done

for value in "$DRUID_ADMIN_PASSWORD" "$DRUID_INTERNAL_PASSWORD"; do
  case "$value" in
    *[!A-Za-z0-9_-]*|'')
      printf 'Druid passwords may contain only letters, numbers, underscore, and hyphen.\n' >&2
      exit 1
      ;;
  esac
  if [ "${#value}" -lt 20 ]; then
    printf 'Druid passwords must contain at least 20 characters.\n' >&2
    exit 1
  fi
done

source_config=conf/druid/single-server/nano-quickstart
common="$source_config/_common/common.runtime.properties"

{
  printf '\n'
  printf '%s\n' 'druid.extensions.loadList=["druid-hdfs-storage", "druid-kafka-indexing-service", "druid-datasketches", "druid-parquet-extensions", "druid-basic-security"]'
  printf '%s\n' 'druid.startup.logging.logProperties=false'
  printf '%s\n' 'druid.auth.authenticatorChain=["MyBasicMetadataAuthenticator"]'
  printf '%s\n' 'druid.auth.authenticator.MyBasicMetadataAuthenticator.type=basic'
  printf '%s\n' 'druid.auth.authenticator.MyBasicMetadataAuthenticator.credentialsValidator.type=metadata'
  printf '%s\n' 'druid.auth.authenticator.MyBasicMetadataAuthenticator.skipOnFailure=false'
  printf '%s\n' "druid.auth.authenticator.MyBasicMetadataAuthenticator.initialAdminPassword=$DRUID_ADMIN_PASSWORD"
  printf '%s\n' "druid.auth.authenticator.MyBasicMetadataAuthenticator.initialInternalClientPassword=$DRUID_INTERNAL_PASSWORD"
  printf '%s\n' 'druid.auth.authenticator.MyBasicMetadataAuthenticator.authorizerName=MyBasicMetadataAuthorizer'
  printf '%s\n' 'druid.auth.authorizers=["MyBasicMetadataAuthorizer"]'
  printf '%s\n' 'druid.auth.authorizer.MyBasicMetadataAuthorizer.type=basic'
  printf '%s\n' 'druid.escalator.type=basic'
  printf '%s\n' 'druid.escalator.internalClientUsername=druid_system'
  printf '%s\n' "druid.escalator.internalClientPassword=$DRUID_INTERNAL_PASSWORD"
  printf '%s\n' 'druid.escalator.authorizerName=MyBasicMetadataAuthorizer'
  printf '%s\n' 'druid.auth.unsecuredPaths=["/status/health","/status/ready"]'
} >>"$common"

unset DRUID_ADMIN_PASSWORD DRUID_INTERNAL_PASSWORD
exec perl bin/supervise -c conf/supervise/single-server/nano-quickstart.conf
