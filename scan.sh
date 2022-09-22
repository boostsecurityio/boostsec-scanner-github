#!/bin/bash

set -e
set -o pipefail
set -u

export BOOST_TMP_DIR=${BOOST_TMP_DIR:-${WORKSPACE_TMP:-${TMPDIR:-/tmp}}}
export BOOST_EXE=${BOOST_EXE:-${BOOST_TMP_DIR}/boost-cli/latest}


log.info ()
{ # $@=message
  printf "$(date +'%H:%M:%S') [\033[34m%s\033[0m] %s\n" "INFO" "${*}";
}

log.error ()
{ # $@=message
  printf "$(date +'%H:%M:%S') [\033[31m%s\033[0m] %s\n" "ERROR" "${*}";
}

init.config ()
{
  log.info "initializing configuration"

  export BOOST_CLI_URL=${BOOST_CLI_URL:-https://assets.build.boostsecurity.io}
         BOOST_CLI_URL=${BOOST_CLI_URL%*/}
  export BOOST_DOWNLOAD_URL=${BOOST_DOWNLOAD_URL:-${BOOST_CLI_URL}/boost-cli/get-boost-cli}
  export BOOST_FORCE_COLORS="true"
}

init.cli ()
{
  if [ -f "${BOOST_BIN:-}" ]; then
    return
  fi

  mkdir -p "${BOOST_TMP_DIR}"
  curl --silent "${BOOST_DOWNLOAD_URL}" | bash
}

main.scan ()
{
  init.config
  init.cli

  # shellcheck disable=SC2086
  exec ${BOOST_EXE} scan run ${BOOST_CLI_ARGUMENTS:-}
}

main.scan
