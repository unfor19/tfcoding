#!/bin/bash

# bargs
source /usr/local/bin/bargs.sh "$@"

set -e
set -o pipefail

# Global variables
[[ "$SINGLE_VALUE_OUTPUT" = "all" ]] && SINGLE_VALUE_OUTPUT=""
_SINGLE_VALUE_OUTPUT="${SINGLE_VALUE_OUTPUT:-""}"

_SRC_DIR_ROOT="${SRC_DIR_ROOT:-"/src"}"
_SRC_DIR_RELATIVE_PATH="$SRC_DIR_RELATIVE_PATH"
[[ -z "$_SRC_DIR_RELATIVE_PATH" ]] && error_msg "Relative path is required, create a directory that contains tfcoding.tf"
_SRC_DIR_ABSOLUTE_PATH="${_SRC_DIR_ROOT}/${_SRC_DIR_RELATIVE_PATH}"
_CODE_FILE_NAME="tfcoding.tf"
_CODE_DIR_TMP="/tmp"
_SRC_FILE_ABSOLUTE_PATH="${_SRC_DIR_ABSOLUTE_PATH}/${_CODE_FILE_NAME}"


# Terraform Plugins (providers) cache dir
export TF_PLUGIN_CACHE_DIR="${_CODE_DIR_TMP}/.terraform.d/plugin-cache"
[[ ! -d "$TF_PLUGIN_CACHE_DIR" ]] && mkdir -p "$TF_PLUGIN_CACHE_DIR"


# Terraform Modules cache dir
export TF_DATA_DIR="${_CODE_DIR_TMP}/.terraform"
[[ ! -d "$_CODE_DIR_TMP" ]] && mkdir -p "$_CODE_DIR_TMP"


# Flags and boolean args
_LOGGING="${LOGGING:-"true"}"
_DEBUG="${DEBUG:-"false"}"
_WATCHING="${WATCHING:-"false"}"
_MOCK_AWS="${MOCK_AWS:-"false"}"


_TMP_DIR_TF_FILES="${_CODE_DIR_TMP}/code"

# Functions
error_msg(){
  local msg="$1"
  echo -e "[ERROR] $(date) :: $msg"
  exit 1
}


log_msg(){
  local msg="$1"
  echo -e "[LOG] $(date) :: $msg"
}


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
ctrl_c() {
    log_msg "Stopped"
    exit 0
}


validation(){
  if [[ -d "$_SRC_DIR_ABSOLUTE_PATH" ]]; then
  :
  else
    error_msg "Directory does not exist - $_SRC_DIR_ABSOLUTE_PATH"
  fi
}


copy_files(){
  [[ -f "${_TMP_DIR_TF_FILES}/terraform.tfstate" ]] && mv "${_TMP_DIR_TF_FILES}/terraform.tfstate" "${_CODE_DIR_TMP}/terraform.tfstate"
  rm -rf "${_TMP_DIR_TF_FILES}"
  mkdir -p "${_TMP_DIR_TF_FILES}"
  find "$_SRC_DIR_ABSOLUTE_PATH" -type f \( -name '*.tf' -o -name '*.tpl' -o -name '*.json' \) \
    -and \( -not -path '.git/' -not -path '.terraform/' \) -exec cp {} "$_TMP_DIR_TF_FILES" \;
  [[ -f "${_CODE_DIR_TMP}/terraform.tfstate" ]] && cp "${_CODE_DIR_TMP}/terraform.tfstate" "${_TMP_DIR_TF_FILES}/terraform.tfstate"
  wait # prevents sudden exit
}


terraform_init(){
  # Create a local empty tfstate file
  cd "$_TMP_DIR_TF_FILES"
  if [[ "$_MOCK_AWS" = "true" ]]; then
    terraform init
  else
    terraform init 1>/dev/null
  fi
}


inject_outputs(){
  # Inject outputs to $_CODE_FILE_NAME according to locals{}
  declare -a arr=($(hcl2json "${_TMP_DIR_TF_FILES}/${_CODE_FILE_NAME}" | jq -r '.locals[] | keys[]'))
  for local_value in "${arr[@]}"; do
      cat <<EOF >> "${_TMP_DIR_TF_FILES}/${_CODE_FILE_NAME}"


output "${local_value}" {
    value = local.${local_value}
}


EOF
  done

}


debug_mode(){
  if [[ $_DEBUG = "true" ]]; then
    cat "$_TMP_DIR_TF_FILES/$_CODE_FILE_NAME"
  fi
}


render_tfcoding(){
  # terraform apply renders the outputs
  cd "$_TMP_DIR_TF_FILES"
  terraform fmt 1>/dev/null
  if ! terraform validate 1>/dev/null ; then
    log_msg "Fix the above syntax error\n${output_msg}"
    return
  fi
  terraform apply -auto-approve 1>/dev/null
  if [[ -n $_SINGLE_VALUE_OUTPUT ]]; then
    # single output
    local output_msg
    output_msg="$(terraform output -json "${_SINGLE_VALUE_OUTPUT}" 2>&1 || true)"
    if [[ "$output_msg" =~ .*output.*not.*found ]]; then
      error_msg "Local Value not defined: ${_SINGLE_VALUE_OUTPUT}"
    else
      log_msg "terraform plan - Fix the above error"
      return
    fi
  elif [[ "$_MOCK_AWS" != "true" ]]; then  
    # Local Values only
    if ! terraform apply -lock=false -input=false -auto-approve -compact-warnings 1>/dev/null ; then
      log_msg "terraform apply - Fix the above error"
      return
    fi

    if [[ -n $_SINGLE_VALUE_OUTPUT ]]; then
      # Single Local Value Output
      local output_msg
      output_msg="$(terraform output -json "${_SINGLE_VALUE_OUTPUT}" 2>&1 || true)"
      if [[ "$output_msg" =~ .*output.*not.*found ]]; then
        error_msg "Local Value not defined: ${_SINGLE_VALUE_OUTPUT}"
      else
        echo "{\"${_SINGLE_VALUE_OUTPUT}\":${output_msg}}" | jq
      fi
    else
      # All Outputs (Local Values)
      terraform output -json | jq 'map_values(.value)'
    fi
  fi
}


# Main
main(){
  validation
  copy_files
  terraform_init
  inject_outputs
  debug_mode
  render_tfcoding
  [[ "$_LOGGING" = "true" && "$_WATCHING" = "true" ]] && log_msg "Watching for changes in ${_SRC_FILE_ABSOLUTE_PATH}"
}

[[ "$_LOGGING" = "true" ]] && log_msg "$(terraform version)"
if [[ "$_WATCHING" = "true" ]]; then
  # Execute on file change in code file - tfcoding.tf
  log_msg "Rendered for the first time"
  main
  fswatch -0 -m poll_monitor --batch-marker --event-flags "${_SRC_DIR_ABSOLUTE_PATH}/${_CODE_FILE_NAME}" | while read -r -d "" event; do
    if [[ "$event" = "NoOp" ]]; then
      [[ "$_LOGGING" = "true" ]] && log_msg "Rendered"
      main
    fi
  done
else
  # Run-once
  main
fi