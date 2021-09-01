# This needs to be here in order to pass environment variables from
# the container -> apache. After we get these values will source the file
# in /etc/apache2/envvars

export SITE_URL="${SITE_URL}"
export OIDC_CRYPTO_PASSPHRASE="${OIDC_CRYPTO_PASSPHRASE}"
export OIDC_CLIENT_ID="${OIDC_CLIENT_ID}"
export OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET}"
export MEMCACHED_HOST="${MEMCACHED_HOST}"
export MEMCACHED_PORT="${MEMCACHED_PORT}"
