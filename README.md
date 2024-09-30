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

---
  
  # Rclone을 활용한 하이퍼 백업 (Hyper Backup with Rclone Upload)

이 GitHub 액션은 데이터베이스나 디렉토리를 백업하고 [Rclone](https://rclone.org/)을 통해 원격 스토리지에 업로드할 수 있도록 도와줍니다. 다양한 데이터베이스 유형과 원격 스토리지 서비스를 지원하여 CI/CD 워크플로우에서 백업 작업을 유연하고 강력하게 수행할 수 있는 솔루션을 제공합니다.

## 주요 기능

- **데이터베이스 백업**: MySQL, MongoDB, PostgreSQL 데이터베이스를 백업할 수 있습니다.
- **디렉토리 백업**: 지정된 디렉토리를 백업합니다.
- **Rclone 통합**: Amazon S3, Cloudflare R2, Google Drive 등 다양한 클라우드 스토리지 제공업체에 백업 파일을 손쉽게 업로드할 수 있습니다.

## 시작하기

### 사전 준비 사항

- 이 액션을 사용하려는 GitHub 리포지토리
- 원하는 원격 스토리지에 대한 Rclone 구성 정보

### 사용 방법

GitHub 워크플로우 YAML 파일에 다음과 같이 이 액션을 설정할 수 있습니다:

```yaml
name: Database Backup
on:
  schedule:
    - cron: '0 0 * * *' # 매일 자정에 실행
  workflow_dispatch: # 워크플로우를 수동으로 실행 가능

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

### 입력 값 (Inputs)

| **입력 변수 이름**            | **설명**                                                    | **필수 여부**               | **기본값**   |
| ----------------------------- | ----------------------------------------------------------- | --------------------------- | ------------ |
| `db_type`                     | 데이터베이스 유형 (`mysql`, `mongo`, `postgres`).           | 예                          |              |
| `db_string`                   | 데이터베이스 연결 문자열 전체.                              | 아니요                      |              |
| `db_user`                     | 데이터베이스 사용자 이름.                                   | `db_string`이 없을 때 필수  |              |
| `db_name`                     | 데이터베이스 이름.                                          | `db_string`이 없을 때 필수  |              |
| `db_host`                     | 데이터베이스 호스트.                                        | 아니요                      | `localhost`  |
| `db_port`                     | 데이터베이스 포트.                                          | 아니요                      |              |
| `db_pass`                     | 데이터베이스 비밀번호.                                      | 예                          |              |
| `db_auth_db`                  | MongoDB의 인증 데이터베이스.                                | 아니요                      | `admin`      |
| `backup_type`                 | 백업 유형 (`rclone` 또는 `directory`).                      | 예                          |              |
| `remote`                      | Rclone 원격 스토리지 유형 (예: `s3`, `r2`, `google_drive`). | 예                          |              |
| `rclone_s3_access_key_id`     | Rclone의 S3 액세스 키 ID.                                   | `s3` 사용 시 필수           |              |
| `rclone_s3_secret_access_key` | Rclone의 S3 비밀 액세스 키.                                 | `s3` 사용 시 필수           |              |
| `rclone_s3_region`            | Rclone의 S3 리전.                                           | `s3` 사용 시 필수           |              |
| `rclone_s3_endpoint`          | Rclone의 S3 엔드포인트.                                     | `s3` 사용 시 필수           |              |
| `rclone_s3_acl`               | Rclone의 S3 ACL(액세스 제어 목록).                          | 아니요                      | `private`    |
| `rclone_r2_access_key_id`     | Rclone의 R2 액세스 키 ID.                                   | `r2` 사용 시 필수           |              |
| `rclone_r2_secret_access_key` | Rclone의 R2 비밀 액세스 키.                                 | `r2` 사용 시 필수           |              |
| `rclone_r2_region`            | Rclone의 R2 리전.                                           | `r2` 사용 시 필수           |              |
| `rclone_r2_endpoint`          | Rclone의 R2 엔드포인트.                                     | `r2` 사용 시 필수           |              |
| `rclone_r2_acl`               | Rclone의 R2 ACL(액세스 제어 목록).                          | 아니요                      | `private`    |
| `rclone_gdrive_client_id`     | Rclone의 Google Drive 클라이언트 ID.                        | `google_drive` 사용 시 필수 |              |
| `rclone_gdrive_client_secret` | Rclone의 Google Drive 클라이언트 시크릿.                    | `google_drive` 사용 시 필수 |              |
| `rclone_gdrive_scope`         | Rclone의 Google Drive 액세스 범위.                          | 아니요                      |              |
| `rclone_gdrive_token`         | Rclone의 Google Drive 토큰.                                 | `google_drive` 사용 시 필수 |              |
| `template_dir`                | Rclone 템플릿 구성 파일을 포함하는 디렉토리 경로.           | 아니요                      | `/templates` |
| `dirpath`                     | `backup_type`이 `directory`인 경우 백업할 디렉토리 경로.    | `directory` 사용 시 필수    |              |

### 출력 값 (Outputs)

- 이 액션은 직접적인 출력 값을 제공하지 않지만 백업 프로세스의 상태와 경로를 로그로 기록합니다.

### 참고 사항

- `backup_type`에 따라 데이터베이스(`db`) 또는 디렉토리(`directory`) 백업을 선택할 수 있습니다.
- GitHub 리포지토리 설정에서 `secrets`를 구성하여 `db_pass`, `rclone_s3_access_key_id` 등의 민감한 정보를 안전하게 저장하세요.

### Notes

- The `backup_type` determines whether you are backing up a database (`db`) or a directory (`directory`).
- Make sure you configure your `secrets` in your GitHub repository settings to securely store sensitive information like `db_pass`, `rclone_s3_access_key_id`, etc.
