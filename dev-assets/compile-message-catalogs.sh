#!/usr/bin/env bash
# Compile Gettext message catalog to a MO message catalog file

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
    msgfmt
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

application_id='taic-patient-callno-monitoring'
project_dir="${script_dir%/*}"

printf \
    'Info: Loading available languages...\n'
po_dir="${project_dir}/po"
linguas_file="${po_dir}/LINGUAS"

if ! test -e "${linguas_file}"; then
    printf \
        'Error: The LINGUAS file does not exist in the po folder.\n' \
        1>&2
    exit 2
fi

mapfile_opts=(
    # Strip line endings from each read line
    -t
)
if ! mapfile "${mapfile_opts[@]}" linguas_lines <"${linguas_file}"; then
    printf \
        'Error: Unable to load the lines of the LINGUAS file to the languages array.\n' \
        1>&2
    exit 2
fi

languages=()
for line in "${linguas_lines[@]}"; do
    regex_comment_line='^#.*$'
    regex_blank_line='^[[:space:]]*$'

    if [[ "${line}" =~ ${regex_comment_line} ]] \
        || [[ "${line}" =~ ${regex_blank_line} ]]; then
        continue
    fi
    language="${line}"
    languages+=("${language}")
done
if test "${#languages[@]}" -eq 0; then
    printf \
        'Error: No languages are listed in the po/LINGUAS file.\n' \
        1>&2
    exit 2
fi

# Avoid printing full path of the source file in the generated message
# catalog files
printf \
    'Info: Switching the working directory to the project directory...\n'
if ! cd "${project_dir}"; then
    printf \
        'Error: Unable to switch the working directory to the project directory.\n' \
        1>&2
    exit 2
fi

locale_dir="${project_dir}/share/locale"
for language in "${languages[@]}"; do
    printf \
        'Info: Compiling message catalog file for the "%s" language...\n' \
        "${language}"

    lc_messages_dir="${locale_dir}/${language}/LC_MESSAGES"
    if ! test -e "${lc_messages_dir}"; then
        mkdir_opts=(
            --parents
            --verbose
        )
        if ! mkdir "${mkdir_opts[@]}" "${lc_messages_dir}"; then
            printf \
                'Error: Unable to create the locale messages localization data directory for the "%s" language.\n' \
                "${language}" \
                1>&2
            exit 2
        fi
    fi

    compiled_message_catalog_file="${lc_messages_dir}/${application_id}.mo"

    message_catalog_file="${po_dir}/${language}.po"
    msgfmt_opts=(
        --output-file="${compiled_message_catalog_file}"
        --check
        --strict
    )
    if ! msgfmt "${msgfmt_opts[@]}" "${message_catalog_file}"; then
        printf \
            'Error: Unable to compile the message catalog for the "%s" language.\n' \
            "${language}" \
            1>&2
        exit 2
    fi
done

printf \
    'Info: Operation completed without errors.\n'
