#!/bin/bash

# echo to stderr: https://stackpointer.io/script/shell-script-echo-to-stderr/355/


# get_latest_release from here https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
get_latest_release() {
  curl --silent "$1" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

SPECFILE=$(find "$(pwd)" -type f -name '*.rb' | head -n1)

if [ -z "${SPECFILE}" ]; then
    echo "Failed to find specfile, bailing!"
    exit 1
fi

# grab the update url from the spec file
URL=$(grep -E homepage "${SPECFILE}" | awk '{print $NF}' | tr -d '"')
if [ -z "${URL}" ]; then
    echo "Failed to find check URL, bailing!"
    exit 1
fi


# pull the latest version
LATEST=$(get_latest_release "${URL}" )
if [ -z "${LATEST}" ]; then
    echo "Failed to find latest version, bailing!"
    exit 1
fi

# pull the download url from the spec file and update it
DOWNLOAD_URL=$(grep -E 'url \"http.*' "${SPECFILE}" | awk '{print $NF}' | tr -d '"' | sed -E "s/#{version}/${LATEST}/g")
if [ -z "${DOWNLOAD_URL}" ]; then
    echo "Failed to find download URL, bailing!"
    exit 1
fi

# calculate the shasum based on the file
FILEHASH=$(curl -L --silent "${DOWNLOAD_URL}" | shasum -a 256 | awk '{print $1}')
if [ -z "${FILEHASH}" ]; then
    echo "Couldn't get file hash, bailing"
    exit 1
fi

# updates the file
find "$(pwd)" -maxdepth 1 -type f -name '*.rb' -exec sed -i "" -E "s/version \\\".*/version \"${LATEST}\"/g" "{}" \;
find "$(pwd)" -maxdepth 1 -type f -name '*.rb' -exec sed -i "" -E "s/sha256 \\\".*/sha256 \"${FILEHASH}\"/g" "{}" \;

echo "::set-env name=LATEST::${LATEST}"