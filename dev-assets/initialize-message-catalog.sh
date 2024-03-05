#!/usr/bin/env bash
# Initialize Gettext message catalog for a new language from the
# template
#
# Copyright 2024 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0

printf \
    'Info: Setting defensive interpreter behaviors...\n'
set_opts=(
    # Terminate script execution when an unhandled error occurs
    -o errexit
    -o errtrace

    # Terminate script execution when an unset parameter variable is
    # referenced
    -o nounset
)
if ! set "${set_opts[@]}"; then
    printf \
        'Error: Unable to set the defensive interpreter behaviors.\n' \
        1>&2
    exit 1
fi

required_commands=(
    mkdir
    msginit
    realpath
)
required_command_check_failed=false
for command in "${required_commands[@]}"; do
    if ! command -v "${command}" >/dev/null; then
        printf \
            'Error: This program requires the "%s" command to be available in your command search PATHs.\n' \
            "${command}" \
            1>&2
        required_command_check_failed=true
    fi
done
if test "${required_command_check_failed}" == true; then
    printf \
        'Error: Required command check failed.\n' \
        1>&2
    exit 1
fi

if test -v BASH_SOURCE; then
    # Convenience variables
    # shellcheck disable=SC2034
    {
        script="$(
            realpath \
                --strip \
                "${BASH_SOURCE[0]}"
        )"
        script_dir="${script%/*}"
        script_filename="${script##*/}"
        script_name="${script_filename%%.*}"
        if test "${#}" -eq 0; then
            script_args=()
        else
            script_args=("${@}")
        fi
        script_basecommand="${0}"
    }
fi

project_dir="${script_dir%/*}"

if test "${#script_args[@]}" -ne 1; then
    printf \
        'Usage: %s _language_code_.\n' \
        "${script_basecommand}" \
    1>&2
    exit 1
fi

language="${script_args[0]}"

po_dir="${project_dir}/po"
application_id='taic-patient-callno-monitoring'
pot_template_file="${po_dir}/${application_id}.pot"

printf \
    'Info: Checking whether the message catalog template file exists...\n'
if ! test -e "${pot_template_file}"; then\
    printf \
        'Error: The message catalog template file does not exist.\n' \
        1>&2
    exit 2
else
    printf \
        'Info: Message catalog template file found.\n'
fi

printf \
    'Info: Initializing the message catalog file for the "%s" language...\n' \
    "${language}"
initialized_message_catalog_file="${po_dir}/${language}.po"
msginit_opts=(
    --locale="${language}"
    --input="${pot_template_file}"
    --output-file="${initialized_message_catalog_file}"
)
if ! msginit "${msginit_opts[@]}"; then
    printf \
        'Error: Unable to initialize the message catalog file for the "%s" language.\n' \
        "${language}"
    exit 2
fi

printf \
    'Info: Operation completed without errors.\n'
