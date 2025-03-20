#!/bin/bash
set -euo pipefail

# shellcheck source=lib/plugin.bash
. "$DIR/../lib/plugin.bash"
# shellcheck source=lib/curl.bash
. "$DIR/../lib/curl.bash"


if [ "${BUILDKITE_PIPELINE_PROVIDER}" != 'gitlab' ] && [ "${BUILDKITE_PIPELINE_PROVIDER}" != 'gitlab_ee' ]; then
  echo '+++ Provider is not gitlab, can not do anything'
  exit 1
fi

GITLAB_TOKEN_ENV_VAR=$(plugin_read_config API_TOKEN_VAR_NAME "GITLAB_ACCESS_TOKEN")
if [ -z "${!GITLAB_TOKEN_ENV_VAR:-}" ]; then
  echo "+++ ERROR: gitlab access token not configured in variable ${GITLAB_TOKEN_ENV_VAR}"
  exit 1
fi

buildkite_job_name() {
  echo -n "${BUILDKITE_LABEL:-${BUILDKITE_STEP_KEY:-}}"
  if [[ -n "${BUILDKITE_PARALLEL_JOB:-}" && -n "${BUILDKITE_PARALLEL_JOB_COUNT:-}" ]]; then
    echo -n " (${BUILDKITE_PARALLEL_JOB:-}/${BUILDKITE_PARALLEL_JOB_COUNT:-})"
  fi
  echo
}

STATUS_NAME=$(plugin_read_config CHECK_NAME "$(buildkite_job_name)")

if [ -z "${STATUS_NAME}" ]; then
  echo "+++ ERROR: if the step has no key, check-name must be provided"
  exit 1
fi

GITLAB_HOST=$(plugin_read_config GITLAB_HOST "gitlab.com")
PROJECT="$(echo "${BUILDKITE_REPO##*"${GITLAB_HOST}"}" | cut -c 2- )"
PROJECT_SLUG=$(urlencode "${PROJECT%.git}")

TOKEN="${!GITLAB_TOKEN_ENV_VAR}"
