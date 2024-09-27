## 환경 변수 목록

### For actions

| 환경 변수                           | 설명                                                                |                 예시                 |
| ----------------------------------- | ------------------------------------------------------------------- | :----------------------------------: |
| INPUT_DB_TYPE (필수)                | 입력 데이터베이스 유형 (`mysql`, `postgres`, `mongo`)               |       `mysql, postgres, mongo`       |
| INPUT_DB_STRING                     | 데이터베이스 연결 문자열 (직접 사용)                                | `mysql://user:pass@host:3306/dbname` |
| INPUT_DB_HOST                       | 데이터베이스 호스트                                                 |             `localhost`              |
| INPUT_DB_PORT                       | 데이터베이스 포트 번호                                              |                `3306`                |
| INPUT_DB_NAME                       | 데이터베이스 이름                                                   |             `mydatabase`             |
| INPUT_DB_USER                       | 데이터베이스 사용자 이름                                            |               `admin`                |
| INPUT_DB_PASS                       | 데이터베이스 비밀번호                                               |              `password`              |
| INPUT_DB_AUTH_DB                    | 입력 데이터베이스 인증 DB                                           |               `admin`                |
| INPUT_BACKUP_TYPE (기본 값: rclone) | 백업 유형                                                           |         `directory, rclone`          |
| INPUT_BACKUP_TARGET                 | 백업을 원하는 디렉토리 경로 (백업 유형이 `directory`에서만 사용됨 ) |         `/path/to/directory`         |
| INPUT_REMOTE                        | 원격 설정                                                           |        `s3, r2, google_drive`        |
| INPUT_RCLONE_R2_ACCESS_KEY_ID       | Rclone R2 접근 키 ID                                                |         `example-access-key`         |
| INPUT_RCLONE_R2_SECRET_ACCESS_KEY   | Rclone R2 비밀 접근 키                                              |         `example-secret-key`         |
| INPUT_RCLONE_R2_REGION              | Rclone R2 지역                                                      |             `us-west-1`              |
| INPUT_RCLONE_R2_ENDPOINT            | Rclone R2 엔드포인트                                                |    `https://example-endpoint.com`    |
| INPUT_ARGS                          | 입력 인자                                                           |             `--verbose`              |
| INPUT_RCLONE_S3_ACCESS_KEY_ID       | Rclone S3 접근 키 ID                                                |         `example-access-key`         |
| INPUT_RCLONE_S3_SECRET_ACCESS_KEY   | Rclone S3 비밀 접근 키                                              |         `example-secret-key`         |
| INPUT_RCLONE_S3_REGION              | Rclone S3 지역                                                      |             `us-east-1`              |
| INPUT_RCLONE_S3_ENDPOINT            | Rclone S3 엔드포인트                                                |       `https://s3.example.com`       |
| INPUT_RCLONE_S3_ACL                 | Rclone S3 ACL 설정                                                  |            `public-read`             |
| INPUT_RCLONE_R2_ACL                 | Rclone R2 ACL 설정                                                  |              `private`               |
| INPUT_RCLONE_GDRIVE_CLIENT_ID       | Rclone Google Drive 클라이언트 ID                                   |           `client-id-123`            |
| INPUT_RCLONE_GDRIVE_CLIENT_SECRET   | Rclone Google Drive 클라이언트 비밀                                 |           `client-secret`            |
| INPUT_RCLONE_GDRIVE_SCOPE           | Rclone Google Drive 범위 설정                                       |           `drive.readonly`           |
| INPUT_RCLONE_GDRIVE_TOKEN           | Rclone Google Drive 토큰                                            |            `token-string`            |

## 구성 흐름

1. `INPUT_DB_TYPE` 검증

현재 MySQL, MongoDB, Postgres 지원 중임 case로 지원 중인 것을 지정해서 확인.
지원 하지 않는 것은 `*)`로 처리

```bash

```

2. `INPUT_DB_STRING`을 구성

```bash
#!/bin/bash

set -eu

#----------------------------------------
# Initialise the constants
#----------------------------------------
THEDATE=$(date +%d%m%y%H%M)
BACKUP_DIR="${GITHUB_WORKSPACE}/backups"
CONFIG_DIR="${GITHUB_WORKSPACE}/config"
TEMPLATES_DIR="/templates"
CONFIG_FILE="${CONFIG_DIR}/rclone.conf"
GZIP_LEVEL="${INPUT_GZIP_LEVEL:-9}" # 사용자 지정 압축 레벨 (기본값은 9)
DEBUG_MODE="${DEBUG_MODE:-false}"   # 디버깅 모드 활성화 여부

mkdir -p "${BACKUP_DIR}" "${CONFIG_DIR}"

# 필수 환경 변수를 확인하는 함수
check_required_env() {
    local var_name=$1
    if [[ -z "${!var_name:-}" ]]; then
        echo "❌ 환경 변수 '${var_name}'가 설정되지 않았습니다. 이 변수는 필수입니다."
        exit 1
    fi
}

# 디버깅 모드에서 환경 변수 출력 함수
log_env_vars() {
    if [[ "${DEBUG_MODE}" == "true" ]]; then
        echo "🔍 현재 설정된 환경 변수:"
        env | grep 'INPUT_'
    fi
}

# 1. 필수 환경 변수 확인
check_required_env "INPUT_DB_TYPE"

# INPUT_DB_STRING이 설정되어 있지 않은 경우에만 개별적인 DB 정보 확인
if [[ -z "${INPUT_DB_STRING:-}" ]]; then
    check_required_env "INPUT_DB_HOST"
    check_required_env "INPUT_DB_NAME"
    check_required_env "INPUT_DB_USER"
    check_required_env "INPUT_DB_PASS"
fi

# Rclone 백업을 사용하려는 경우에 필요한 환경 변수 확인
if [[ "${INPUT_BACKUP_TYPE:-rclone}" == "rclone" ]]; then
    check_required_env "INPUT_REMOTE"

    case "${INPUT_REMOTE}" in
        r2)
            check_required_env "INPUT_RCLONE_R2_ACCESS_KEY_ID"
            check_required_env "INPUT_RCLONE_R2_SECRET_ACCESS_KEY"
            ;;
        s3)
            check_required_env "INPUT_RCLONE_S3_ACCESS_KEY_ID"
            check_required_env "INPUT_RCLONE_S3_SECRET_ACCESS_KEY"
            ;;
        google_drive)
            check_required_env "INPUT_RCLONE_GDRIVE_CLIENT_ID"
            check_required_env "INPUT_RCLONE_GDRIVE_CLIENT_SECRET"
            check_required_env "INPUT_RCLONE_GDRIVE_TOKEN"
            ;;
        *)
            echo "❌ 지원하지 않는 원격 설정: ${INPUT_REMOTE}"
            exit 1
            ;;
    esac
fi

# 디버깅 모드일 경우 환경 변수 출력
log_env_vars

# 환경 변수 설정 확인 결과 출력
echo "✅ 모든 필수 환경 변수가 설정되었습니다."

perform_backup() {
    # 기본 포트 및 인증 DB 설정
    case "${INPUT_DB_TYPE}" in
        mysql)
            INPUT_DB_PORT="${INPUT_DB_PORT:-3306}"
            FILENAME="${BACKUP_DIR}/${INPUT_DB_TYPE}-${GITHUB_HEAD_REF:-${INPUT_DB_NAME}}.${THEDATE}.sql.gz"
            ;;
        mongo)
            INPUT_DB_PORT="${INPUT_DB_PORT:-27017}"
            INPUT_AUTH_DB="${INPUT_AUTH_DB:-admin}"
            FILENAME="${BACKUP_DIR}/${INPUT_DB_TYPE}-${GITHUB_HEAD_REF:-${INPUT_DB_NAME}}.${THEDATE}.gz"
            ;;
        postgres)
            INPUT_DB_PORT="${INPUT_DB_PORT:-5432}"
            FILENAME="${BACKUP_DIR}/${INPUT_DB_TYPE}-${GITHUB_HEAD_REF:-${INPUT_DB_NAME}}.${THEDATE}.pgsql.gz"
            ;;
        *)
            echo "😔 지원하지 않는 DB 타입입니다: ${INPUT_DB_TYPE}"
            exit 1
            ;;
    esac

    # 백업 명령어 구성
    case "${INPUT_DB_TYPE}" in
        mysql)
            if [[ -n "${INPUT_DB_STRING:-}" ]]; then
                BACKUP_CMD="mysqldump ${INPUT_DB_STRING} ${INPUT_DB_ARGS} | gzip -${GZIP_LEVEL} > \"${FILENAME}\""
            else
                BACKUP_CMD="mysqldump -h \"${INPUT_DB_HOST}\" -P \"${INPUT_DB_PORT}\" \"${INPUT_DB_NAME}\" -u \"${INPUT_DB_USER}\" -p\"${INPUT_DB_PASS}\" ${INPUT_DB_ARGS} | gzip -${GZIP_LEVEL} > \"${FILENAME}\""
            fi
            ;;
        mongo)
            if [[ -n "${INPUT_DB_STRING:-}" ]]; then
                BACKUP_CMD="mongodump ${INPUT_DB_STRING} ${INPUT_DB_ARGS} | gzip -${GZIP_LEVEL} > \"${FILENAME}\""
            else
                if [[ "${INPUT_DB_HOST}" == *"mongodb.net"* ]]; then
                    BACKUP_CMD="mongodump --gzip --archive=\"${FILENAME}\" --uri=\"mongodb+srv://${INPUT_DB_USER}:${INPUT_DB_PASS}@${INPUT_DB_HOST}/${INPUT_DB_NAME}\" --authenticationDatabase=${INPUT_AUTH_DB} ${INPUT_DB_ARGS}"
                else
                    BACKUP_CMD="mongodump --gzip --archive=\"${FILENAME}\" --host=\"${INPUT_DB_HOST}\" --port=\"${INPUT_DB_PORT}\" -d \"${INPUT_DB_NAME}\" -u \"${INPUT_DB_USER}\" -p\"${INPUT_DB_PASS}\" --authenticationDatabase=${INPUT_AUTH_DB} ${INPUT_DB_ARGS}"
                fi
            fi
            ;;
        postgres)
            if [[ -n "${INPUT_DB_STRING:-}" ]]; then
                BACKUP_CMD="pg_dump ${INPUT_DB_STRING} ${INPUT_DB_ARGS} | gzip -${GZIP_LEVEL} > \"${FILENAME}\""
            else
                BACKUP_CMD="PGPASSWORD=\"${INPUT_DB_PASS}\" pg_dump -h \"${INPUT_DB_HOST}\" -p \"${INPUT_DB_PORT}\" -d \"${INPUT_DB_NAME}\" -U \"${INPUT_DB_USER}\" ${INPUT_DB_ARGS} | gzip -${GZIP_LEVEL} > \"${FILENAME}\""
            fi
            ;;
    esac

    # Display the database type and name being backed up
    echo "🔄 ${INPUT_DB_TYPE} 데이터베이스 백업을 시작합니다: ${INPUT_DB_NAME}"

    echo "🚀 실행 중인 백업 명령: ${BACKUP_CMD}"
    if ! bash -c "$BACKUP_CMD"; then
        echo "😔 ${INPUT_DB_TYPE} 데이터베이스의 백업 명령 실행 중 오류 발생: ${INPUT_DB_NAME}"
        exit 1
    fi

    # Verify backup file creation
    if [[ ! -f "$FILENAME" ]]; then
        echo "😔 백업 파일이 생성되지 않았습니다: $FILENAME"
        exit 1
    fi

    # Check file size
    if [[ ! -s "$FILENAME" ]]; then
        echo "😔 백업 파일이 비어 있습니다: $FILENAME"
        exit 1
    fi

    echo "✅ 백업이 성공적으로 완료되었습니다: ${FILENAME}"

    # Backup file 위치 및 목록 확인
    echo "📂 백업 파일 위치: ${BACKUP_DIR}"
    echo "🔍 백업 파일 목록:"
    ls -lhS "${BACKUP_DIR}/"
}

validate_template() {
    local template_file=$1
    if [[ ! -f "${TEMPLATES_DIR}/${template_file}.template" ]]; then
        echo "😔 템플릿 파일이 존재하지 않습니다: ${template_file}.template"
        exit 1
    fi
}

configure_rclone() {
    local config_type=$1

    validate_template "${config_type}"
    cp "${TEMPLATES_DIR}/${config_type}.template" "${CONFIG_FILE}"

    case "${config_type}" in
        s3)
            sed -i '' \
                -e "s|{{RCLONE_S3_ACCESS_KEY_ID}}|${INPUT_RCLONE_S3_ACCESS_KEY_ID}|g" \
                -e "s|{{RCLONE_S3_SECRET_ACCESS_KEY}}|${INPUT_RCLONE_S3_SECRET_ACCESS_KEY}|g" \
                -e "s|{{RCLONE_S3_REGION}}|${INPUT_RCLONE_S3_REGION}|g" \
                -e "s|{{RCLONE_S3_ENDPOINT}}|${INPUT_RCLONE_S3_ENDPOINT}|g" \
                -e "s|{{RCLONE_S3_ACL}}|${INPUT_RCLONE_S3_ACL}|g" \
                "${CONFIG_FILE}"
            ;;
        r2)
            sed -i '' \
                -e "s|{{RCLONE_R2_ACCESS_KEY_ID}}|${INPUT_RCLONE_R2_ACCESS_KEY_ID}|g" \
                -e "s|{{RCLONE_R2_SECRET_ACCESS_KEY}}|${INPUT_RCLONE_R2_SECRET_ACCESS_KEY}|g" \
                -e "s|{{RCLONE_R2_REGION}}|${INPUT_RCLONE_R2_REGION}|g" \
                -e "s|{{RCLONE_R2_ENDPOINT}}|${INPUT_RCLONE_R2_ENDPOINT}|g" \
                -e "s|{{RCLONE_R2_ACL}}|${INPUT_RCLONE_R2_ACL}|g" \
                "${CONFIG_FILE}"
            ;;
        gdrive)
            sed -i '' \
                -e "s|{{RCLONE_GDRIVE_CLIENT_ID}}|${INPUT_RCLONE_GDRIVE_CLIENT_ID}|g" \
                -e "s|{{RCLONE_GDRIVE_CLIENT_SECRET}}|${INPUT_RCLONE_GDRIVE_CLIENT_SECRET}|g" \
                -e "s|{{RCLONE_GDRIVE_SCOPE}}|${INPUT_RCLONE_GDRIVE_SCOPE}|g" \
                -e "s|{{RCLONE_GDRIVE_TOKEN}}|${INPUT_RCLONE_GDRIVE_TOKEN}|g" \
                "${CONFIG_FILE}"
            ;;
        *)
            echo "😔 지원하지 않는 원격 스토리지 타입입니다: ${config_type}"
            exit 1
            ;;
    esac
}

if [[ -n "${INPUT_REMOTE}" ]]; then
    configure_rclone "${INPUT_REMOTE}"

    echo "🚀 Rclone을 사용하여 백업 파일을 업로드 중..."
    rclone --config "${CONFIG_FILE}" copy "${FILENAME}" "${INPUT_REMOTE}":backup/
    echo "✅ Rclone 업로드 완료"
fi


```

### 기본적으로 제공되는 환경 변수

| 환경 변수                  | 설명                         | 예시 |
| -------------------------- | ---------------------------- | :--: |
| HOME                       | 홈 디렉토리                  |      |
| GITHUB_JOB                 | GitHub 작업 이름             |      |
| GITHUB_REF                 | GitHub 참조                  |      |
| GITHUB_SHA                 | GitHub 커밋 SHA              |      |
| GITHUB_REPOSITORY          | GitHub 저장소                |      |
| GITHUB_REPOSITORY_OWNER    | GitHub 저장소 소유자         |      |
| GITHUB_REPOSITORY_OWNER_ID | GitHub 저장소 소유자 ID      |      |
| GITHUB_RUN_ID              | GitHub 실행 ID               |      |
| GITHUB_RUN_NUMBER          | GitHub 실행 번호             |      |
| GITHUB_RETENTION_DAYS      | GitHub 보존 기간             |      |
| GITHUB_RUN_ATTEMPT         | GitHub 실행 시도             |      |
| GITHUB_REPOSITORY_ID       | GitHub 저장소 ID             |      |
| GITHUB_ACTOR_ID            | GitHub 액터 ID               |      |
| GITHUB_ACTOR               | GitHub 액터                  |      |
| GITHUB_TRIGGERING_ACTOR    | GitHub 트리거링 액터         |      |
| GITHUB_WORKFLOW            | GitHub 워크플로우            |      |
| GITHUB_HEAD_REF            | GitHub 헤드 참조             |      |
| GITHUB_BASE_REF            | GitHub 기본 참조             |      |
| GITHUB_EVENT_NAME          | GitHub 이벤트 이름           |      |
| GITHUB_SERVER_URL          | GitHub 서버 URL              |      |
| GITHUB_API_URL             | GitHub API URL               |      |
| GITHUB_GRAPHQL_URL         | GitHub GraphQL URL           |      |
| GITHUB_REF_NAME            | GitHub 참조 이름             |      |
| GITHUB_REF_PROTECTED       | GitHub 참조 보호 상태        |      |
| GITHUB_REF_TYPE            | GitHub 참조 유형             |      |
| GITHUB_WORKFLOW_REF        | GitHub 워크플로우 참조       |      |
| GITHUB_WORKFLOW_SHA        | GitHub 워크플로우 SHA        |      |
| GITHUB_WORKSPACE           | GitHub 작업 공간             |      |
| GITHUB_ACTION              | GitHub 액션                  |      |
| GITHUB_EVENT_PATH          | GitHub 이벤트 경로           |      |
| GITHUB_ACTION_REPOSITORY   | GitHub 액션 저장소           |      |
| GITHUB_ACTION_REF          | GitHub 액션 참조             |      |
| GITHUB_PATH                | GitHub 경로                  |      |
| GITHUB_ENV                 | GitHub 환경 설정             |      |
| GITHUB_STEP_SUMMARY        | GitHub 단계 요약             |      |
| GITHUB_STATE               | GitHub 상태                  |      |
| GITHUB_OUTPUT              | GitHub 출력                  |      |
| RUNNER_OS                  | 러너 운영체제                |      |
| RUNNER_ARCH                | 러너 아키텍처                |      |
| RUNNER_NAME                | 러너 이름                    |      |
| RUNNER_ENVIRONMENT         | 러너 환경                    |      |
| RUNNER_TOOL_CACHE          | 러너 도구 캐시               |      |
| RUNNER_TEMP                | 러너 임시 디렉토리           |      |
| RUNNER_WORKSPACE           | 러너 작업 공간               |      |
| ACTIONS_RUNTIME_URL        | 액션 런타임 URL              |      |
| ACTIONS_RUNTIME_TOKEN      | 액션 런타임 토큰             |      |
| ACTIONS_CACHE_URL          | 액션 캐시 URL                |      |
| ACTIONS_RESULTS_URL        | 액션 결과 URL                |      |
| GITHUB_ACTIONS             | GitHub 액션 실행 여부 (true) |      |
| CI                         | CI 환경 (true)               |      |
