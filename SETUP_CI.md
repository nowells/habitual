# CI/CD Setup: Auto-Deploy to TestFlight

This project includes a GitHub Actions workflow that automatically builds and
uploads to TestFlight on every push to `main`. Here's how to set it up.

## Prerequisites

- Apple Developer Program membership ($99/year)
- A Mac (one-time setup only)

## One-Time Setup Steps

### 1. Create the App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. My Apps → "+" → New App
3. Fill in: Name: "Habitual", Bundle ID: `com.habitual-helper.app`, SKU: `habitual`

### 2. Create an App Store Connect API Key

1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to generate a new key
3. Name: "GitHub Actions", Access: "App Manager"
4. Download the `.p8` file (you can only download it once!)
5. Note the **Key ID** and **Issuer ID** shown on the page

### 3. Export Your Signing Certificate (on your Mac)

```bash
# Open Keychain Access, find your "Apple Distribution" certificate
# Right-click → Export → Save as .p12 with a password

# Then base64 encode it:
base64 -i Certificates.p12 | pbcopy
# This copies the base64 string to your clipboard
```

### 4. Download Your Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles/list
2. Create an "App Store" provisioning profile for `com.habitual-helper.app`
3. Download the `.mobileprovision` file

```bash
# Base64 encode it:
base64 -i Habitual_AppStore.mobileprovision | pbcopy
```

### 5. Add GitHub Secrets

Go to your repo → Settings → Secrets and variables → Actions, and add:

| Secret Name | Value |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate |
| `P12_PASSWORD` | Password you set when exporting the .p12 |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64-encoded .mobileprovision file |
| `KEYCHAIN_PASSWORD` | Any random password (used for temp keychain) |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from step 2 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 2 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded .p8 file content |

To base64 encode the API key:
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```

### 6. Enable iCloud Entitlements

Before CI can build successfully, ensure:
1. The CloudKit container `iCloud.com.habitual-helper.app` exists in your developer portal
2. App Group `group.com.habitual-helper.app` is registered
3. Both are included in your provisioning profile

## How It Works

Once configured:

1. Push code to `main`
2. GitHub Actions triggers the workflow
3. Fastlane builds the app with your signing credentials
4. The IPA is uploaded to App Store Connect
5. After Apple's processing (~15 min), the build appears in TestFlight
6. Open the TestFlight app on your phone and install it

## Testing the Workflow

You can manually trigger the workflow from the Actions tab in GitHub
(the workflow has `workflow_dispatch` enabled).

## Troubleshooting

- **Code signing errors**: Double-check that your provisioning profile includes
  the correct certificate and bundle ID
- **Upload failures**: Ensure your API key has "App Manager" access
- **Build number conflicts**: The workflow auto-increments based on the latest
  TestFlight build number
