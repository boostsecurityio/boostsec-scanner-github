setup ()
{
  bats_load_library "bats-assert"
  bats_load_library "bats-file"
  bats_load_library "bats-support"

  PROJECT_ROOT=$(git rev-parse --show-toplevel)

  export BOOST_MAIN_BRANCH="main" # do not attempt git ops

  # shellcheck disable=SC1091
  source "${PROJECT_ROOT}/lib/scan.sh"
}

teardown ()
{
  :
}

@test "init.config BOOST_TMP_DIR defined" {
  export BOOST_TMP_DIR=""
  export TMPDIR=""
  init.config

  assert_equal "${BOOST_TMP_DIR}" "/tmp"
}

@test "init.config BOOST_TMP_DIR preserved" {
  export BOOST_TMP_DIR="/tmp/assert/path"
  init.config

  assert_equal "${BOOST_TMP_DIR}" "/tmp/assert/path"
}

@test "init.config BOOST_TMP_DIR built from WORKSPACE_TMP" {
  export BOOST_TMP_DIR=""
  export WORKSPACE_TMP="/tmp/assert/path"
  init.config

  assert_equal "${BOOST_TMP_DIR}" "/tmp/assert/path"
}

@test "init.config BOOST_TMP_DIR built from TMPDIR" {
  export BOOST_TMP_DIR=""
  export WORKSPACE_TMP=""
  export TMPDIR="/tmp/assert/path"
  init.config

  assert_equal "${BOOST_TMP_DIR}" "/tmp/assert/path"
}

@test "init.config BOOST_EXE defined" {
  export BOOST_EXE=""
  export BOOST_TMP_DIR="/tmp"
  init.config

  assert_equal "${BOOST_EXE}" "/tmp/boost-cli/latest"
}

@test "init.config BOOST_EXE preserved" {
  export BOOST_EXE="/tmp/assert/boost"
  init.config

  assert_equal "${BOOST_EXE}" "/tmp/assert/boost"
}

@test "init.config BOOST_EXE built from BOOST_TMP_DIR" {
  export BOOST_EXE=""
  export BOOST_TMP_DIR="/tmp/assert/path"
  init.config

  assert_equal "${BOOST_EXE}" "/tmp/assert/path/boost-cli/latest"
}

@test "init.config BOOST_CLI_URL defined" {
  export BOOST_CLI_URL=""
  init.config

  assert_equal "${BOOST_CLI_URL}" "https://assets.build.boostsecurity.io"
}

@test "init.config BOOST_CLI_URL preserved" {
  export BOOST_CLI_URL="https://localhost/"
  init.config

  assert_equal "${BOOST_CLI_URL}" "https://localhost"
}

@test "init.config BOOST_DOWNLOAD_URL defined" {
  export BOOST_DOWNLOAD_URL=""
  init.config

  assert_equal "${BOOST_DOWNLOAD_URL}" "https://assets.build.boostsecurity.io/boost-cli/get-boost-cli"
}

@test "init.config BOOST_DOWNLOAD_URL preserved" {
  export BOOST_DOWNLOAD_URL="https://localhost/file"
  init.config

  assert_equal "${BOOST_DOWNLOAD_URL}" "https://localhost/file"
}

@test "init.config BOOST_DOWNLOAD_URL built from BOOST_CLI_URL" {
  export BOOST_CLI_URL="https://localhost/"
  export BOOST_DOWNLOAD_URL=""
  init.config

  assert_equal "${BOOST_DOWNLOAD_URL}" "https://localhost/boost-cli/get-boost-cli"
}

@test "init.config BOOST_LOG_COLORS defined" {
  export BOOST_LOG_COLORS=""
  init.config

  assert_equal "${BOOST_LOG_COLORS}" true
}

@test "init.config BOOST_MAIN_BRANCH defined" {
  export BOOST_MAIN_BRANCH=""

  pushd ${BATS_TEST_TMPDIR} > /dev/null
  git init test-repo
  pushd test-repo > /dev/null
  git remote add origin https://github.com/bats-core/bats-core.git
  init.config

  assert_equal "${BOOST_MAIN_BRANCH}" "master"
}

@test "init.config BOOST_MAIN_BRANCH preserved" {
  export BOOST_MAIN_BRANCH="main"
  init.config

  assert_equal "${BOOST_MAIN_BRANCH}" "main"
}

@test "init.cli creates tmpdir" {
  export BOOST_TMP_DIR=${BATS_TEST_TMPDIR}/tmpdir

  curl () {
    echo "echo ran"
  }

  init.config
  init.cli

  assert test -d "${BOOST_TMP_DIR}"
}


@test "init.cli executes the installer" {
  export BOOST_TMP_DIR=${BATS_TEST_TMPDIR}/tmpdir

  curl () {
    echo "${*}" > ${BATS_TEST_TMPDIR}/curl.call_args
    echo "echo ok"
  }

  init.config
  run init.cli

  curl_call_args=$(cat "${BATS_TEST_TMPDIR}/curl.call_args")

  assert test -d "${BOOST_TMP_DIR}"
  assert_equal "${curl_call_args}" "--silent ${BOOST_DOWNLOAD_URL}"
  assert_output "ok"
}


@test "init.cli noops if executable found" {
  export BOOST_TMP_DIR=${BATS_TEST_TMPDIR}/tmpdir
  export BOOST_EXE=${BATS_TEST_TMPDIR}/file
  touch "${BOOST_EXE}"

  curl () { return 1; }

  init.cli
}

@test "main.scan calls init.config, init.cli" {
  export BOOST_TMP_DIR=${BATS_TEST_TMPDIR}/tmpdir
  export BOOST_EXE=${BATS_TEST_TMPDIR}/boost

  echo "echo \${*} > ${BATS_TEST_TMPDIR}/boost.call_args" > ${BOOST_EXE}
  chmod 755 ${BOOST_EXE}

  init.config () {
    echo "${*}" > ${BATS_TEST_TMPDIR}/init.config.call_args
  }

  init.cli () {
    echo "${*}" > ${BATS_TEST_TMPDIR}/init.cli.call_args
  }

  run main.scan

  assert test -f "${BATS_TEST_TMPDIR}/boost.call_args"
  assert test -f "${BATS_TEST_TMPDIR}/init.config.call_args"
  assert test -f "${BATS_TEST_TMPDIR}/init.cli.call_args"
}

@test "main.scan executes with arguments" {
  export BOOST_TMP_DIR=${BATS_TEST_TMPDIR}/tmpdir
  export BOOST_EXE=${BATS_TEST_TMPDIR}/boost
  export BOOST_CLI_ARGUMENTS=arguments

  echo "echo \${*} > ${BATS_TEST_TMPDIR}/boost.call_args" > ${BOOST_EXE}
  chmod 755 ${BOOST_EXE}

  run main.scan

  boost_call_args=$(cat "${BATS_TEST_TMPDIR}/boost.call_args")
  assert_equal "${boost_call_args}" "scan repo arguments HEAD"
}

@test "scan" {
  export BOOST_TMP_DIR=${BATS_TEST_TMPDIR}
  export BOOST_CLI_ARGUMENTS=--help

  run main.scan

  assert test -f "${BATS_TEST_TMPDIR}/boost-cli/latest"
  assert test -d "${BATS_TEST_TMPDIR}/boost-cli/$(ls -1d 1*)"
}

# vim: set ft=bash ts=2 sw=2 et :
