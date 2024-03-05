#!/usr/bin/env bash
# Monitor and report the change of the current calling patient number
#
# Copyright 2024 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0
#
# Not enforceable when Gettext I18N is integrated
# shellcheck disable=SC2059
CHECK_INTERVAL_BASE="${CHECK_INTERVAL_BASE:-15}"
CHECK_INTERVAL_VARIANCE_MAX="${CHECK_INTERVAL_VARIANCE_MAX:-10}"
CHECK_URL="${CHECK_URL:-unset}"
CHECK_TIMEOUT="${CHECK_TIMEOUT:-30}"

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
        'Error: Unable to set the defensive interpreter behavior.\n' \
        1>&2
    exit 1
fi

required_commands=(
    curl
    gettext.sh
    hq
    jq
    notify-send
    realpath
    sleep
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

TEXTDOMAIN="${application_id}"
TEXTDOMAINDIR="${script_dir}/share/locale"
export TEXTDOMAIN TEXTDOMAINDIR

# Out of project scope
# shellcheck source=/dev/null
if ! . gettext.sh; then
    printf \
        'Error: Unable to load the gettext support functions file.\n' \
        1>&2
    exit 1
fi

application_name="$(gettext 'Taichung Hospital currently called patient number monitoring')"

if test "${CHECK_URL}" == unset; then
    printf \
        'Error: The CHECK_URL environment variable is not set, please check the product README for more information.\n' \
        1>&2
    exit 1
fi

check_interval_base="${CHECK_INTERVAL_BASE}"
current_called_number=0
notify_id=0
while true; do
    check_interval_variance="$(( RANDOM % CHECK_INTERVAL_VARIANCE_MAX + 1 ))"
    check_interval="$(( check_interval_base + check_interval_variance ))"

    curl_opts=(
        --location
        --silent
        --show-error

        --user-agent 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:123.0) Gecko/20100101 Firefox/123.0'

        --max-time "${CHECK_TIMEOUT}"
    )
    if ! check_page="$(
        curl \
            "${curl_opts[@]}" \
            "${CHECK_URL}"
        )"; then
        curl_exit_status="${?}"
        if ! error_msg="$(
            printf \
                'Error: The curl command exit status is not zero(%s).\n' \
                "${curl_exit_status}"
            )"; then
            printf \
                "$(gettext 'Error: Unable to generate the error message from the format string.\n')" \
                1>&2
        fi

        notify_send_opts=(
            --app-name="${application_name}"
            --urgency=critical
        )
        if ! notify-send \
            "${notify_send_opts[@]}" \
            "$(gettext 'Patient call number check failed')" \
            "${error_msg}"; then
            printf \
                "$(gettext 'Error: Unable to send desktop notification.\n')" \
                1>&2
        fi
        exit 2
    fi

    if ! regroom_now_see_raw="$(
        hq \
            '{ elements: .regroom-now-see | [ {text: @text} ] }' \
            <<<"${check_page}"
        )"; then
        if ! error_msg="$(
            printf \
                "$(gettext 'Error: Unable to parse the check page.\n')"
            )"; then
            printf \
                "$(gettext 'Error: Unable to generate the error message from the format string.\n')" \
                1>&2
        fi

        notify_send_opts=(
            --app-name="${application_name}"
            --urgency=critical
        )
        if ! notify-send \
            "${notify_send_opts[@]}" \
            "$(gettext 'Patient call number check failed')" \
            "${error_msg}"; then
            printf \
                "$(gettext 'Error: Unable to send desktop notification.\n')" \
                1>&2
        fi
        exit 2
    fi

    jq_opts=(
        --raw-output
    )
    if ! regroom_now_see_text_raw="$(
        jq \
            "${jq_opts[@]}" \
            '.elements[0].text' \
            <<<"${regroom_now_see_raw}"
        )"; then
        if ! error_msg="$(
            printf \
                "$(gettext 'Error: Unable to parse the regroom_now_see HTML element parse results.\n')"
            )"; then
            printf \
                "$(gettext 'Error: Unable to generate the error message from the format string.\n')" \
                1>&2
        fi

        notify_send_opts=(
            --app-name="${application_name}"
            --urgency=critical
        )
        if ! notify-send \
            "${notify_send_opts[@]}" \
            "$(gettext 'Patient call number check failed')" \
            "${error_msg}"; then
            printf \
                "$(gettext 'Error: Unable to send desktop notification.\n')" \
                1>&2
        fi
        exit 2
    fi

    regex_regroom_now_see_text_raw='^[[:digit:]]+號$'
    if ! [[ "${regroom_now_see_text_raw}" =~ ${regex_regroom_now_see_text_raw} ]]; then
        if ! error_msg="$(
            printf \
                "$(gettext 'Error: Invalid regroom_now_see_text_raw parse result detected, please check.\n')"
            )"; then
            printf \
                "$(gettext 'Error: Unable to generate the error message from the format string.\n')" \
                1>&2
        fi

        notify_send_opts=(
            --app-name "${application_name}"
            --urgency=critical
        )
        if ! notify-send \
            "${notify_send_opts[@]}" \
            "$(gettext 'Patient call number check failed')" \
            "${error_msg}"; then
            printf \
                "$(gettext 'Error: Unable to send desktop notification.\n')" \
                1>&2
        fi
        exit 2
    fi

    current_called_number="${regroom_now_see_text_raw%號}"

    notify_send_opts=(
        --app-name="${application_name}"
        --urgency=normal
        --expire-time=30000
        --print-id
    )
    if test "${notify_id}" -ne 0; then
        notify_send_opts+=(--replace-id="${notify_id}")
    fi

    message="$(
        printf \
            "$(gettext 'Currently called patient number: %s')" \
            "${current_called_number}"
    )"
    if ! notify_id="$(
        notify-send \
            "${notify_send_opts[@]}" \
            "$(gettext 'Patient call number check')" \
            "${message}"
        )"; then
        printf \
            "$(gettext 'Error: Unable to send desktop notification.\n')" \
            1>&2
        exit 2
    fi

    sleep "${check_interval}"
done
