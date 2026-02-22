#!/usr/bin/env bash
set -euo pipefail

if [ -z "${BASH_ENV:-}" ]; then
  echo "BASH_ENV is not set. This command must run in CircleCI."
  exit 1
fi

require_value_from_env_var_name() {
  local env_var_name="$1"
  local label="$2"
  local value

  if [ -z "${env_var_name}" ]; then
    echo "Missing env_var_name for ${label}."
    exit 1
  fi

  value="${!env_var_name:-}"
  if [ -z "${value}" ]; then
    echo "Environment variable ${env_var_name} is required for ${label}."
    exit 1
  fi

  printf '%s' "${value}"
}

optional_value_from_env_var_name() {
  local env_var_name="$1"
  if [ -z "${env_var_name}" ]; then
    return 0
  fi
  printf '%s' "${!env_var_name:-}"
}

key_id="$(require_value_from_env_var_name "${ASC_KEY_ID_ENV_VAR:-}" "key_id")"
issuer_id="$(require_value_from_env_var_name "${ASC_ISSUER_ID_ENV_VAR:-}" "issuer_id")"
private_key_path="$(optional_value_from_env_var_name "${ASC_PRIVATE_KEY_PATH_ENV_VAR:-}")"
private_key="$(optional_value_from_env_var_name "${ASC_PRIVATE_KEY_ENV_VAR:-}")"
private_key_b64="$(optional_value_from_env_var_name "${ASC_PRIVATE_KEY_B64_ENV_VAR:-}")"

if [ -z "${private_key_path}${private_key}${private_key_b64}" ]; then
  echo "One private key source is required: private_key_path, private_key, or private_key_b64."
  exit 1
fi

{
  printf 'export ASC_KEY_ID=%q\n' "${key_id}"
  printf 'export ASC_ISSUER_ID=%q\n' "${issuer_id}"

  if [ -n "${private_key_path}" ]; then
    printf 'export ASC_PRIVATE_KEY_PATH=%q\n' "${private_key_path}"
  fi

  if [ -n "${private_key}" ]; then
    printf 'export ASC_PRIVATE_KEY=%q\n' "${private_key}"
  fi

  if [ -n "${private_key_b64}" ]; then
    printf 'export ASC_PRIVATE_KEY_B64=%q\n' "${private_key_b64}"
  fi

  if [ -n "${ASC_PROFILE_VALUE:-}" ]; then
    printf 'export ASC_PROFILE=%q\n' "${ASC_PROFILE_VALUE}"
  fi

  if [ -n "${ASC_STRICT_AUTH_VALUE:-}" ]; then
    printf 'export ASC_STRICT_AUTH=%q\n' "${ASC_STRICT_AUTH_VALUE}"
  fi
} >> "${BASH_ENV}"

echo "asc authentication environment exported to BASH_ENV."
