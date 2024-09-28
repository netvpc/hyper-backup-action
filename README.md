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
        uses: netvpc/hyper-backup-action@v0.2.3
        with:
          db_type: 'mysql'
          db_user: 'your_db_user'
          db_name: 'your_db_name'
          db_host: 'localhost'
          db_port: '3306'
          db_pass: '${{ secrets.DB_PASSWORD }}'
          backup_type: 'db'
          remote: 's3'
          rclone_s3_access_key_id: '${{ secrets.S3_ACCESS_KEY_ID }}'
          rclone_s3_secret_access_key: '${{ secrets.S3_SECRET_ACCESS_KEY }}'
          rclone_s3_region: 'your-region'
          rclone_s3_endpoint: 'https://s3.your-provider.com'
          rclone_s3_acl: 'private'
```

### Inputs

| **Input Name** | **Description**                                      | **Required** | **Default** |
| -------------- | ---------------------------------------------------- | ------------ | ----------- |
| `db_type`      | The type of the database (mysql, mongo, postgres).   | Yes          |             |
| `db_user`      | The database user.                                   | Yes          |             |
| `db_name`      | The database name.                                   | Yes          |             |
| `db_host`      | The database host.                                   | No           | `localhost` |
| `db_port`      | The database port.                                   | No           |             |
| `db_pass`      | The database password.                               | Yes          |             |
| `db_auth_db`   | The authentication database for MongoDB.             | No           | `admin`     |
| `args`         | Additional arguments with backup command if needed.  | No           |             |
| `backup_type`  | The type of backup (db or directory).                | Yes          | `db`        |
| `dirpath`      | The directory path to back up.                       | No           |             |
| `remote`       | The remote storage type for rclone (s3, r2, gdrive). | No           |             |

For detailed information on all inputs related to `rclone` configuration for S3, R2, or Google Drive, refer to the `action.yml` file or the example above.

### Outputs

This action does not produce any direct outputs, but it will log the backup process and report any errors encountered.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
