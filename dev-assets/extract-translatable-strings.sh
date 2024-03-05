#!/usr/bin/env bash
# Extract Gettext translatable strings to a PO message catalog file

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

printf \
    'Info: Checking required commands...\n'
required_commands=(
    mkdir
    realpath
    xgettext
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

application_id='taic-patient-callno-monitoring'
project_dir="${script_dir%/*}"

po_dir="${project_dir}/po"

printf \
    'Info: Checking the existence of the POTFILES.in file...\n'
potfiles_input_file="${po_dir}/POTFILES.in"
if ! test -e "${potfiles_input_file}"; then
    printf \
        'Error: The POTFILES.in file does not exist in the po directory.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Loading source files containing translatable strings...\n'
mapfile_opts=(
    # Strip line ending from read lines
    -t
)
if ! mapfile \
    "${mapfile_opts[@]}" \
    potfiles_lines \
    <"${po_dir}/POTFILES.in"; then
    printf \
        'Error: Unable to load the POTFILES.in file into the "potfiles_lines" array.\n' \
        1>&2
    exit 2
fi

source_files=()
for line in "${potfiles_lines[@]}"; do
    regex_comment_line='^#.*$'
    regex_blank_line='^[[:space:]]*$'
    
    if [[ "${line}" =~ ${regex_comment_line} ]] \
        || [[ "${line}" =~ ${regex_blank_line} ]]; then
        continue
    fi
    source_file="${line}"
    source_files+=("${source_file}")
done
if test "${#source_files[@]}" -eq 0; then
    printf \
        'Error: No source files are listed in the po/POTFILES.in file.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Extracting translatable strings from the source files...\n'
template_file="${po_dir}/${application_id}.pot"
xgettext_opts=(
    --default-domain="${application_id}"
    --package-name="${application_id}"
    --package-version=main
    --msgid-bugs-address="https://gitlab.com/brlin/taic-patient-callno-monitoring/-/issues/new"
    --copyright-holder='林博仁 <buo.ren.lin+legal@gmail.com>'
    --output="${template_file}"
    --from-code=UTF-8
    --verbose
    --debug
    --join-existing
)
if ! xgettext "${xgettext_opts[@]}" "${source_files[@]}"; then
    printf \
        'Error: Unable to extract the translatable strings from the program file.\n' \
        1>&2
    exit 2
fi

printf \
    'Info: Operation completed without errors.\n'
