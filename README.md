# Hyper Backup with Rclone Upload

This GitHub Action enables you to back up databases or directories and upload them to remote storage using [Rclone](https://rclone.org/). It supports multiple database types and various remote storage services, making it a flexible and powerful solution for backup tasks in your CI/CD workflows.

## Features

- **Database Backup**: Supports backing up MySQL, MongoDB, and PostgreSQL databases.
- **Directory Backup**: Backs up specified directories.
- **Rclone Integration**: Easily upload backups to cloud storage providers like Amazon S3, Cloudflare R2, and Google Drive.

## Getting Started

### Prerequisites

- A GitHub repository where you want to use this action.
- Rclone configuration details for your preferred remote storage.

### Usage

You can configure this action in your workflow YAML file as follows:

```yaml
name: Database Backup
on:
  schedule:
    - cron: '0 0 * * *' # Runs daily at midnight
  workflow_dispatch: # Allows manual triggering of the workflow

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Run Database Backup
        uses: netvpc/hyper-backup-action@v0.5.7
        with:
          db_type: 'mysql'
          db_user: 'your_db_user'
          db_name: 'your_db_name'
          db_host: 'localhost'
          db_port: '3306'
          db_pass: '${{ secrets.DB_PASSWORD }}'
          backup_type: 'rclone'
          remote: 's3'
          rclone_s3_access_key_id: '${{ secrets.S3_ACCESS_KEY_ID }}'
          rclone_s3_secret_access_key: '${{ secrets.S3_SECRET_ACCESS_KEY }}'
          rclone_s3_region: 'your-region'
          rclone_s3_endpoint: 'https://s3.your-provider.com'
          rclone_s3_acl: 'private'
```

### Inputs

| **Input Name**                | **Description**                                                          | **Required**                          | **Default**  |
| ----------------------------- | ------------------------------------------------------------------------ | ------------------------------------- | ------------ |
| `db_type`                     | The type of the database (`mysql`, `mongo`, `postgres`).                 | Yes                                   |              |
| `db_string`                   | Full connection string to the database.                                  | No                                    |              |
| `db_user`                     | The database user.                                                       | Yes (if `db_string` is not provided)  |              |
| `db_name`                     | The database name.                                                       | Yes (if `db_string` is not provided)  |              |
| `db_host`                     | The database host.                                                       | No                                    | `localhost`  |
| `db_port`                     | The database port.                                                       | No                                    |              |
| `db_pass`                     | The database password.                                                   | Yes                                   |              |
| `db_auth_db`                  | The authentication database for MongoDB.                                 | No                                    | `admin`      |
| `backup_type`                 | The backup type (`rclone` or `directory`).                               | Yes                                   |              |
| `remote`                      | The remote storage type for `rclone` (e.g., `s3`, `r2`, `google_drive`). | Yes                                   |              |
| `rclone_s3_access_key_id`     | S3 access key ID for Rclone.                                             | Yes (if using `s3`)                   |              |
| `rclone_s3_secret_access_key` | S3 secret access key for Rclone.                                         | Yes (if using `s3`)                   |              |
| `rclone_s3_region`            | S3 region for Rclone.                                                    | Yes (if using `s3`)                   |              |
| `rclone_s3_endpoint`          | S3 endpoint for Rclone.                                                  | Yes (if using `s3`)                   |              |
| `rclone_s3_acl`               | S3 ACL (Access Control List) for Rclone.                                 | No                                    | `private`    |
| `rclone_r2_access_key_id`     | R2 access key ID for Rclone.                                             | Yes (if using `r2`)                   |              |
| `rclone_r2_secret_access_key` | R2 secret access key for Rclone.                                         | Yes (if using `r2`)                   |              |
| `rclone_r2_region`            | R2 region for Rclone.                                                    | Yes (if using `r2`)                   |              |
| `rclone_r2_endpoint`          | R2 endpoint for Rclone.                                                  | Yes (if using `r2`)                   |              |
| `rclone_r2_acl`               | R2 ACL (Access Control List) for Rclone.                                 | No                                    | `private`    |
| `rclone_gdrive_client_id`     | Google Drive client ID for Rclone.                                       | Yes (if using `google_drive`)         |              |
| `rclone_gdrive_client_secret` | Google Drive client secret for Rclone.                                   | Yes (if using `google_drive`)         |              |
| `rclone_gdrive_scope`         | Google Drive scope for Rclone.                                           | No                                    |              |
| `rclone_gdrive_token`         | Google Drive token for Rclone.                                           | Yes (if using `google_drive`)         |              |
| `template_dir`                | Directory containing the Rclone template configuration files.            | No                                    | `/templates` |
| `dirpath`                     | Directory path to back up (if `backup_type` is `directory`).             | Yes (if `backup_type` is `directory`) |              |

### Outputs

- The action does not provide any direct outputs but will log the status and path of the backup process.

### Notes

- The `backup_type` determines whether you are backing up a database (`db`) or a directory (`directory`).
- Make sure you configure your `secrets` in your GitHub repository settings to securely store sensitive information like `db_pass`, `rclone_s3_access_key_id`, etc.
