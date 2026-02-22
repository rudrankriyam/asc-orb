#!/usr/bin/env bash
set -euo pipefail

REPO="${ASC_REPO:-rudrankriyam/App-Store-Connect-CLI}"
BIN_NAME="asc"
VERSION="${ASC_VERSION:-latest}"
INSTALL_PATH="${ASC_INSTALL_PATH:-/usr/local/bin}"
CHECKSUM="${ASC_CHECKSUM:-}"

os_name="$(uname -s)"
arch_name="$(uname -m)"

case "${os_name}" in
  Darwin)
    os_asset="macOS"
    ;;
  Linux)
    os_asset="linux"
    ;;
  *)
    echo "Unsupported OS: ${os_name}"
    exit 1
    ;;
esac

case "${arch_name}" in
  x86_64|amd64)
    arch_asset="amd64"
    ;;
  arm64|aarch64)
    arch_asset="arm64"
    ;;
  *)
    echo "Unsupported architecture: ${arch_name}"
    exit 1
    ;;
esac

if [ "${VERSION}" = "latest" ]; then
  latest_url="$(curl -fsSL -o /dev/null -w "%{url_effective}" "https://github.com/${REPO}/releases/latest")"
  VERSION="${latest_url##*/}"
fi

if [ -z "${VERSION}" ] || [ "${VERSION}" = "latest" ]; then
  echo "Could not determine a valid asc version."
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

calc_sha256() {
  local file_path="$1"

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${file_path}" | awk '{print $1}'
    return 0
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${file_path}" | awk '{print $1}'
    return 0
  fi

  return 1
}

build_release_candidates() {
  local requested="$1"

  printf '%s\n' "${requested}"
  case "${requested}" in
    v*)
      printf '%s\n' "${requested#v}"
      ;;
    *)
      printf '%s\n' "v${requested}"
      ;;
  esac
}

selected_tag=""
selected_asset=""
downloaded_file=""

while IFS= read -r candidate_tag; do
  [ -z "${candidate_tag}" ] && continue

  candidate_asset="${BIN_NAME}_${candidate_tag}_${os_asset}_${arch_asset}"
  candidate_url="https://github.com/${REPO}/releases/download/${candidate_tag}/${candidate_asset}"
  candidate_file="${tmp_dir}/${candidate_asset}"

  echo "Attempting download for tag ${candidate_tag}..."
  if curl -fsSL "${candidate_url}" -o "${candidate_file}"; then
    selected_tag="${candidate_tag}"
    selected_asset="${candidate_asset}"
    downloaded_file="${candidate_file}"
    break
  fi
done <<EOF
$(build_release_candidates "${VERSION}")
EOF

if [ -z "${selected_tag}" ] || [ -z "${selected_asset}" ] || [ -z "${downloaded_file}" ]; then
  echo "Could not download asc release asset for version ${VERSION} (${os_asset}/${arch_asset})."
  exit 1
fi

chmod +x "${downloaded_file}"

if [ -n "${CHECKSUM}" ]; then
  if ! actual_checksum="$(calc_sha256 "${downloaded_file}")"; then
    echo "No checksum tool available (shasum or sha256sum)."
    exit 1
  fi

  if [ "${actual_checksum}" != "${CHECKSUM}" ]; then
    echo "Checksum verification failed for ${selected_asset}."
    exit 1
  fi
  echo "Checksum verified from provided checksum parameter."
else
  checksums_url="https://github.com/${REPO}/releases/download/${selected_tag}/${BIN_NAME}_${selected_tag}_checksums.txt"
fi

if [ -z "${CHECKSUM}" ] && curl -fsSL "${checksums_url}" -o "${tmp_dir}/checksums.txt"; then
  expected_checksum="$(awk -v target="${selected_asset}" '{
    name = $2
    sub(/^\*/, "", name)
    if (name == target) {
      print $1
      exit
    }
  }' "${tmp_dir}/checksums.txt")"

  if [ -n "${expected_checksum}" ]; then
    if actual_checksum="$(calc_sha256 "${downloaded_file}")"; then
      if [ "${actual_checksum}" != "${expected_checksum}" ]; then
        echo "Checksum verification failed for ${selected_asset}."
        exit 1
      fi
      echo "Checksum verified from release checksums."
    else
      echo "No checksum tool available; skipping checksum verification."
    fi
  else
    echo "Asset checksum not found in release checksums; skipping checksum verification."
  fi
else
  echo "Release checksums not available; skipping checksum verification."
fi

if ! mkdir -p "${INSTALL_PATH}" 2>/dev/null; then
  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "${INSTALL_PATH}"
  else
    echo "Cannot create ${INSTALL_PATH}; set install_path to a writable directory."
    exit 1
  fi
fi

if [ -w "${INSTALL_PATH}" ]; then
  install -m 755 "${downloaded_file}" "${INSTALL_PATH}/${BIN_NAME}"
elif command -v sudo >/dev/null 2>&1; then
  sudo install -m 755 "${downloaded_file}" "${INSTALL_PATH}/${BIN_NAME}"
else
  echo "Cannot write to ${INSTALL_PATH}; set install_path to a writable directory."
  exit 1
fi

if [ -n "${BASH_ENV:-}" ] && [[ ":${PATH}:" != *":${INSTALL_PATH}:"* ]]; then
  printf 'export PATH="%s:$PATH"\n' "${INSTALL_PATH}" >> "${BASH_ENV}"
fi

echo "Installed ${BIN_NAME} to ${INSTALL_PATH}/${BIN_NAME}"
"${INSTALL_PATH}/${BIN_NAME}" --version
