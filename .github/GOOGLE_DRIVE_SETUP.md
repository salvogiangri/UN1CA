# Google Drive Upload Setup

This document explains how to configure the required secrets for Google Drive upload integration in the build workflow.

## Required Secrets

The workflow requires two repository secrets to be configured:

### 1. `GOOGLE_DRIVE_CREDENTIALS`

This secret should contain the **base64-encoded** service account credentials JSON for Google Drive API access.

**Steps to create:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Drive API:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Google Drive API"
   - Click "Enable"
4. Create a service account:
   - Navigate to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "Service Account"
   - Fill in the service account details and click "Create"
   - Grant the service account appropriate permissions (if needed)
   - Click "Done"
5. Create a service account key:
   - Click on the created service account
   - Go to the "Keys" tab
   - Click "Add Key" > "Create new key"
   - Select "JSON" as the key type
   - Click "Create" - the JSON file will be downloaded
6. Base64 encode the JSON file:
   - On Linux/Mac: `base64 credentials.json -w0` (or just `base64 credentials.json` on Mac)
   - On Windows PowerShell: `[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("credentials.json"))`
   - Copy the output (it will be a long string)
7. In your GitHub repository:
   - Go to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `GOOGLE_DRIVE_CREDENTIALS`
   - Value: Paste the base64-encoded string
   - Click "Add secret"

### 2. `GOOGLE_DRIVE_FOLDER_ID`

This secret should contain the ID of the Google Drive folder where ROM files will be uploaded.

**Steps to create:**

1. Create a folder in Google Drive where you want to store the ROM files
2. Share the folder with the service account email:
   - Right-click on the folder and select "Share"
   - Add the service account email (found in the credentials JSON, usually looks like `service-account-name@project-id.iam.gserviceaccount.com`)
   - Give it "Editor" permissions
   - Click "Send"
3. Get the folder ID:
   - Open the folder in Google Drive
   - The URL will look like: `https://drive.google.com/drive/folders/FOLDER_ID_HERE`
   - Copy the `FOLDER_ID_HERE` part
4. In your GitHub repository:
   - Go to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `GOOGLE_DRIVE_FOLDER_ID`
   - Value: Paste the folder ID
   - Click "Add secret"

## Workflow Features

Once configured, the workflow will:

1. **Build Job**: 
   - Build the ROM
   - Upload the ROM to Google Drive
   - Display the Google Drive download link in the workflow summary

2. **Release Job**:
   - Download build artifacts
   - Upload all ROM files to Google Drive
   - Create a GitHub release with the Google Drive download link in the description
   - No files are attached directly to the GitHub release

## Troubleshooting

- **Authentication Error**: Verify that the `GOOGLE_DRIVE_CREDENTIALS` secret contains valid JSON credentials
- **Permission Error**: Ensure the Google Drive folder is shared with the service account email with Editor permissions
- **Folder Not Found**: Verify the `GOOGLE_DRIVE_FOLDER_ID` is correct and the folder exists
- **Quota Exceeded**: Check Google Drive API quotas in Google Cloud Console

## References

- [Google Drive Upload Action](https://github.com/marketplace/actions/google-drive-upload-git-action)
- [Google Cloud Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [Google Drive API](https://developers.google.com/drive/api/v3/about-sdk)
