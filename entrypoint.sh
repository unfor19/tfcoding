#!/bin/bash
set -e
set -o pipefail


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT
ctrl_c() {
    echo "Stopped"
    exit 0
}

# Global variables
_CODE_FILE_NAME="tfcoding.tf"
_SRC_DIR_ROOT="/src"
_SRC_DIR_RELATIVE_PATH="${1:-"$RELATIVE_PATH"}"
_SRC_DIR_RELATIVE_PATH="${_SRC_DIR_RELATIVE_PATH:-"$_ROOT_DIR"}"
_SRC_DIR_ABSOLUTE_PATH="${_SRC_DIR_ROOT}/${_SRC_DIR_RELATIVE_PATH}"
_CODE_DIR_ROOT="/code"

_LOGGING="${LOGGING:-"true"}"
_DEBUG="${DEBUG:-"false"}"

# Valid values: true or watch
_WATCHING="${2:-"$WATCHING"}"
_WATCHING="${_WATCHING:-"false"}"
[[ "$_WATCHING" = "watch" ]] && _WATCHING="true"


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
  terraform apply -auto-approve 1>/dev/null
  terraform output -json | jq 'map_values(.value)'
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

if [[ "$_WATCHING" = "true" ]] ; then
  # Execute on file change in source dir
  log_msg "Rendered for the first time"
  main
  [[ "$_LOGGING" = "true" ]] && log_msg "Watching for changes in $_SRC_DIR_ABSOLUTE_PATH"
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