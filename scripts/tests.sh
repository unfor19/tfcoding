#!/bin/bash
set -e
set -o pipefail

_DOCKERHUB_TAG="${DOCKERHUB_TAG:-"unfor19/tfcoding:latest"}"


error_msg(){
    local msg=$1
    echo -e "[ERROR] $msg"
    export DEBUG=1
    exit 1
}

should(){
    local expected=$1
    local test_name=$2
    local expr=$3
    echo "-------------------------------------------------------"
    echo "[LOG] $test_name - Should $expected"
    echo "[LOG] Executing: $expr"
    output_msg=$(trap '$expr' EXIT)
    output_code=$?

    echo -e "[LOG] Output:\n\n$output_msg\n"

    if [[ $expected == "pass" && $output_code -eq 0 && ! $output_msg =~ .*(ERROR|Error|error).* ]]; then
        echo "[LOG] Test passed as expected"
    elif [[ $expected == "fail" && $output_code -eq 1 ]] || [[ $expected == "fail" && $output_msg =~ .*(ERROR|Error|error).* ]]; then
        echo "[LOG] Test failed as expected"
    else
        error_msg "Test output is not expected, terminating"
    fi
}


tfcoding(){
    docker run --rm -t -v "${PWD}"/:/src/:ro \
        "${_DOCKERHUB_TAG}" "$@"
}


# Tests
should pass "Basic Example" "tfcoding -r examples/basic"
should pass "Complex Example" "tfcoding -r examples/complex"
should fail "No arguments provided" "tfcoding"
should fail "Non existing dir" "tfcoding -r examples/non-existing-dir"
