#!/bin/bash
set -e
set -o pipefail

# Global variables
_CODE_FILE_NAME="tfcoding.tf"
_DEBUG=${DEBUG:-"false"}
_SRC_DIR_ROOT="/src"
_SRC_DIR_RELATIVE_PATH="${1:-"$RELATIVE_PATH"}"
_SRC_DIR_RELATIVE_PATH="${_SRC_DIR_RELATIVE_PATH:-"$_ROOT_DIR"}"
_SRC_DIR_ABSOLUTE_PATH="${_SRC_DIR_ROOT}/${_SRC_DIR_RELATIVE_PATH}"
_CODE_DIR_ROOT="/code"


# Functions
error_msg(){
    local msg=$1
    echo -e "[ERROR] $msg"
    exit 1
}


validation(){
  # [[ -d "$_SRC_DIR_ABSOLUTE_PATH" ]] && error_msg "Directory does not exist - $_SRC_DIR_ABSOLUTE_PATH"
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
    -and \( -not -path '*.git/*' -not -path '*.terraform/*' -and -not -path ''"$_CODE_DIR_ROOT"'*' \) -exec cp {} ${_CODE_DIR_ROOT} \;
  
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
  # perl removes all strings from start to "Outputs:"
  # hcl2json | jq - pretty formatting
  terraform apply -auto-approve -no-color | perl -p0e 's/.*Outputs:.*\n\n//s' | hcl2json | jq
}


# Main
validation
copy_files
terraform_init
inject_outputs
debug_mode
render_tfcoding