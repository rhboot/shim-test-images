#!/bin/bash
# SPDX-License-Identifier: BSD-2-Clause-Patent 
#
# mkraw.sh - 
#
set -eu

declare progname="${0##*/}"

usage() {
    local status
    status="$1" && shift
    local outf
    if [[ "$status" = "0" ]] ; then
        outf=/dev/stdout
    else
        outf=/dev/stderr
    fi
    if [ $# -gt 0 ] ; then
        local msg="${1}" && shift
        echo "${progname}: ${msg}" >>"${outf}"
    fi
    echo "USAGE: ${progname} --size SIZE --output FILE" >>"${outf}"
    exit "${status}"
}

cleanup() {
    local out="${1}"
    local -a loops=()
    mapfile -t loops < <(losetup -j "${out}" | cut -d: -f1)
    local loop
    for loop in "${loops[@]}" ; do
        losetup -d "${loop}"
    done
    rm -vf "${out}"
}

declare loop
declare out
declare size

while [[ $# -gt 0 ]] ; do
    case " $1 " in
        " --size ")
            if [[ $# -lt 2 ]] ; then
                usage 1 "--size requires an argument"
            fi
            size="$2" && shift
            ;;
        " --size="*)
            size="${1/--size=}"
            ;;
        " --output ")
            if [[ $# -lt 2 ]] ; then
                usage 1 "--output requires an argument"
            fi
            out="$2" && shift
            ;;
        " --output="*)
            out="${1/--output=}"
            ;;
        " --help "|" -? "|" --usage ")
            usage 0
            ;;
    esac
    shift
done

if ! [[ -v size ]] ; then
    usage 1 "size is required"
fi
if ! [[ -v out ]] ; then
    usage 1 "output file is required"
fi

trap 'cleanup "${out}"' INT QUIT SEGV ABRT ERR EXIT
truncate -s "${size}" "${out}"
parted -s "${out}" \
    mklabel gpt \
    mkpart '"EFI System Partition"' fat32 1M 1G \
    mkpart '""' ext4 1G 2G \
    mkpart '""' xfs 2G "${size}-1M" \
    p
loop="$(losetup -f)"
losetup -P "${loop}" "${out}"
mkfs.vfat "${loop}p1"
mkfs.ext4 "${loop}p2"
mkfs.xfs "${loop}p3"
losetup -d "${loop}"
trap - INT QUIT SEGV ABRT ERR EXIT

# vim:fenc=utf-8:tw=75
