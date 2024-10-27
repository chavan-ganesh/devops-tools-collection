# Azure KeyVault Secret Migration Script

This script copies secrets from one Azure Key Vault to another, including the secret values, attributes (enabled/disabled status, expiration date, not-before date, content type), and tags. If a secret with the same name already exists in the destination Key Vault, it will be skipped.

## Prerequisites

- **Azure CLI**: Ensure that the Azure CLI (`az`) is installed and configured with access to both the source and destination Key Vaults.
- **jq**: This script uses `jq` to parse JSON data. Install it via package manager, e.g., `sudo apt-get install jq` on Debian/Ubuntu or `brew install jq` on macOS.

### Important Note for macOS Users

On macOS, replace any `date` command with `gdate` (from GNU coreutils) to handle date formatting. Install GNU coreutils via `brew install coreutils` if necessary.

## Usage

1. Open the script and update the following variables:
   - `SOURCE_KEYVAULT`: The name of the source Key Vault from which secrets will be copied.
   - `DESTINATION_KEYVAULT`: The name of the destination Key Vault to which secrets will be copied.

2. Run the script:

   ```bash
   ./copy_keyvault_secrets.sh
   ```

   Ensure the script has execute permissions. If not, set it with:

   ```bash
   chmod +x copy_keyvault_secrets.sh
   ```

## Script Overview

### Variables

- `SOURCE_KEYVAULT`: Name of the source Key Vault.
- `DESTINATION_KEYVAULT`: Name of the destination Key Vault.

### Main Logic

1. **Retrieve Secrets**: Fetches all secret IDs from the source Key Vault.
2. **Iterate Over Secrets**: For each secret:
   - **Check for Existing Secret**: Skips the secret if it already exists in the destination Key Vault.
   - **Copy Secret Value**: Copies the secret’s value to the destination Key Vault.
   - **Set Secret Attributes**: Replicates attributes (enabled, expiration, etc.) to the destination Key Vault.
3. **Clean Up**: Deletes the temporary JSON file storing secret information.

## Example

Set up the environment with your Key Vault names and run the script:

```bash
export SOURCE_KEYVAULT="your-source-keyvault-name"
export DESTINATION_KEYVAULT="your-destination-keyvault-name"
./copy_keyvault_secrets.sh
```

### Sample Output

The script will log each secret’s copy status:

```
Copying secret 'example-secret' to KeyVault: destination-keyvault
Executing command: az keyvault secret set-attributes ...
A secret with name 'existing-secret' already exists in destination-keyvault. Skipping...
```

## Contributing

Feel free to submit issues or pull requests to improve this script.
