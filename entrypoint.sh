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
_CODE_DIR_ROOT="/code"
_SRC_FILE_ABSOLUTE_PATH="${_SRC_DIR_ABSOLUTE_PATH}/${_CODE_FILE_NAME}"

_LOGGING="${LOGGING:-"true"}"
_DEBUG="${DEBUG:-"false"}"
_WATCHING="${WATCHING:-"false"}"

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
  # Copy relevant files from /src/ to /code/ dir
  rm -rf /code/*
  find "$_SRC_DIR_ABSOLUTE_PATH" -type f \( -name ''"$_CODE_FILE_NAME"'' -o -name '*.tpl' -o -name '*.json' \) \
    -and \( -not -path '.git/' -not -path '.terraform/' -and -not -path ''"$_CODE_DIR_ROOT"'*' \) -exec cp {} ${_CODE_DIR_ROOT} \;
  
  if [[ ! -f "$_CODE_FILE_NAME" ]]; then
    error_msg "File does not exist - $_CODE_FILE_NAME"
  fi
}


terraform_init(){
  # Create a local empty tfstate file
  terraform init 1>/dev/null
}


inject_outputs(){
  # Inject outputs to $_CODE_FILE_NAME according to locals{}
  declare -a arr=($(hcl2json "$_CODE_FILE_NAME" | jq -r '.locals[] | keys[]'))
  for local_value in "${arr[@]}"; do
      cat <<EOF >> "$_CODE_FILE_NAME"


output "${local_value}" {
    value = local.${local_value}
}


EOF
  done
}


debug_mode(){
  if [[ $_DEBUG = "true" ]]; then
    cat "$_CODE_FILE_NAME"
  fi
}


render_tfcoding(){
  # terraform apply renders the outputs
  terraform fmt 1>/dev/null
  terraform validate 1>/dev/null
  terraform apply -auto-approve 1>/dev/null
  if [[ -n $_SINGLE_VALUE_OUTPUT ]]; then
    # single output
    local output_msg
    output_msg="$(terraform output -json "${_SINGLE_VALUE_OUTPUT}" 2>&1 || true)"
    if [[ "$output_msg" =~ .*output.*not.*found ]]; then
      error_msg "Local Value not defined: ${_SINGLE_VALUE_OUTPUT}"
    else
      echo "{\"${_SINGLE_VALUE_OUTPUT}\":${output_msg}}" | jq
    fi
  else
    # all outputs (local values)
    terraform output -json | jq 'map_values(.value)'
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
}

[[ "$_LOGGING" = "true" ]] && log_msg "$(terraform version)"
if [[ "$_WATCHING" = "true" ]] ; then
  # Execute on file change in code file - tfcoding.tf
  log_msg "Rendered for the first time"
  main
  [[ "$_LOGGING" = "true" ]] && log_msg "Watching for changes in ${_SRC_FILE_ABSOLUTE_PATH}"
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