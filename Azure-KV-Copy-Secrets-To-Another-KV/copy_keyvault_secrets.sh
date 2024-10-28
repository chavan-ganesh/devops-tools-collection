#!/bin/bash
set -e

# Define source and destination KeyVault names
SOURCE_KEYVAULT="<source_key_vault>"
DESTINATION_KEYVAULT="<destination_key_vault>"

# Retrieve a list of secret IDs from the source KeyVault
SECRETS=($(az keyvault secret list --vault-name "${SOURCE_KEYVAULT}" --query "[].id" -o tsv))

# Loop through each secret ID in the source KeyVault
for SECRET_ID in "${SECRETS[@]}"; do
    # Extract the secret name from the secret ID
    SECRET_NAME=$(echo "${SECRET_ID}" | sed 's|.*/||')

    # Check if the secret already exists in the destination KeyVault
    EXISTING_SECRET=$(az keyvault secret list --vault-name "${DESTINATION_KEYVAULT}" --query "[?name=='${SECRET_NAME}']" -o tsv)

    # Inform about copying the secret
    printf "Copying secret '%s' to KeyVault: %s\n" "${SECRET_NAME}" "${DESTINATION_KEYVAULT}"

    # Create a temporary file to store the secret data
    TMP_FILE="/tmp/${SECRET_NAME}.json"

    # Retrieve the secret value and store it in the temporary file
    az keyvault secret show --vault-name "${SOURCE_KEYVAULT}" -n "${SECRET_NAME}" -o json > "${TMP_FILE}"
    SECRET_VALUE=$(jq -r '.value' "${TMP_FILE}")

    # Set the secret in the destination KeyVault if it doesn't already exist
    DESTINATION_SECRET_NAME="${SECRET_NAME}"
    if [ -n "${EXISTING_SECRET}" ]; then
        printf "A secret with name '%s' already exists in %s. Skipping...\n" "${SECRET_NAME}" "${DESTINATION_KEYVAULT}"
    else
        az keyvault secret set --vault-name "${DESTINATION_KEYVAULT}" -n "${DESTINATION_SECRET_NAME}" --value "${SECRET_VALUE}" >/dev/null
    fi

    # Retrieve secret attributes from the source KeyVault
    ENABLED=$(jq -r '.attributes.enabled' "${TMP_FILE}")
    EXPIRES=$(jq -r '.attributes.expires' "${TMP_FILE}")
    NOT_BEFORE=$(jq -r '.attributes.notBefore' "${TMP_FILE}")
    CONTENT_TYPE=$(jq -r '.contentType' "${TMP_FILE}")
    TAGS=$(jq -r '.tags' "${TMP_FILE}")

    # Construct the command to set secret attributes in the destination KeyVault
    CMD="az keyvault secret set-attributes --vault-name \"${DESTINATION_KEYVAULT}\" --name \"${DESTINATION_SECRET_NAME}\""

    if [ "${ENABLED}" != "null" ]; then
        CMD+=" --enabled \"${ENABLED}\""
    fi
    if [ "${EXPIRES}" != "null" ]; then
        # For macOS Users, use `gdate` instead of `date` to format the date
        CMD+=" --expires $(date -d "${EXPIRES}" '+%Y-%m-%dT%H:%M:%SZ')"
    fi
    if [ "${NOT_BEFORE}" != "null" ]; then
        CMD+=" --not-before $(date -d "${NOT_BEFORE}" '+%Y-%m-%dT%H:%M:%SZ')"
    fi
    if [ "${CONTENT_TYPE}" != "null" ]; then
        CMD+=" --content-type \"${CONTENT_TYPE}\""
    fi
    if [ "${TAGS}" != "{}" ]; then
        key_value_pairs=$(echo "${TAGS}" | jq -r '. | to_entries | .[] | ("\"" + .key + "=" + .value + "\"")')
        result=$(echo "${key_value_pairs}" | tr "\n" " ")
        CMD+=" --tags ${result}"
    fi

    # Execute the command to set attributes
    printf "Executing command: %s\n" "${CMD}"
    eval "${CMD}"

    # Remove the temporary file
    rm -f "${TMP_FILE}"
done
