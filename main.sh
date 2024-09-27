#!/bin/bash

set -eu

#----------------------------------------
# Initialise the constants
#----------------------------------------
THEDATE=$(date +%d%m%y%H%M)
BACKUP_DIR="${GITHUB_WORKSPACE}/backups"
CONFIG_DIR="${GITHUB_WORKSPACE}/config"
mkdir -p "${BACKUP_DIR}"
mkdir -p "${CONFIG_DIR}"

config_file="${CONFIG_DIR}/rclone.conf"

#----------------------------------------
# Validate required environment variables
#----------------------------------------
REQUIRED_VARS=("INPUT_DB_TYPE" "INPUT_DB_USER" "INPUT_DB_NAME")
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "😔 필수 환경 변수 ${var} 설정되지 않았습니다."
        exit 1
    fi
done

# GitHub 환경 변수를 활용하여 경로를 설정
echo "🗃️ GitHub Workflows에서 설정된 경로: ${GITHUB_WORKSPACE}"

# Function to validate required input values
validate_input() {  
    local input_name=$1
    local input_value=${!input_name:-}
    if [[ -z "$input_value" ]]; then
        echo "😔 ${input_name}이 설정되지 않았습니다. 지정해 주세요."
        exit 1
    fi
}

# Function to validate template files
validate_template() {
    local template_file=$1
    if [[ ! -f "/templates/${template_file}.template" ]]; then
        echo "😔 템플릿 파일이 존재하지 않습니다: ${template_file}.template"
        exit 1
    fi
}

# Function to handle Rclone configuration
configure_rclone() {
    local config_type=$1
    local template_file=$2

    validate_template "${template_file}"
    cp "/templates/${template_file}.template" "${config_file}"

    case "$config_type" in
        s3)
            sed -i \
                -e "s|{{RCLONE_S3_ACCESS_KEY_ID}}|${INPUT_RCLONE_S3_ACCESS_KEY_ID}|g" \
                -e "s|{{RCLONE_S3_SECRET_ACCESS_KEY}}|${INPUT_RCLONE_S3_SECRET_ACCESS_KEY}|g" \
                -e "s|{{RCLONE_S3_REGION}}|${INPUT_RCLONE_S3_REGION}|g" \
                -e "s|{{RCLONE_S3_ENDPOINT}}|${INPUT_RCLONE_S3_ENDPOINT}|g" \
                -e "s|{{RCLONE_S3_ACL}}|${INPUT_RCLONE_S3_ACL}|g" \
                "${config_file}"
            ;;
        r2)
            sed -i \
                -e "s|{{RCLONE_R2_ACCESS_KEY_ID}}|${INPUT_RCLONE_R2_ACCESS_KEY_ID}|g" \
                -e "s|{{RCLONE_R2_SECRET_ACCESS_KEY}}|${INPUT_RCLONE_R2_SECRET_ACCESS_KEY}|g" \
                -e "s|{{RCLONE_R2_REGION}}|${INPUT_RCLONE_R2_REGION}|g" \
                -e "s|{{RCLONE_R2_ENDPOINT}}|${INPUT_RCLONE_R2_ENDPOINT}|g" \
                -e "s|{{RCLONE_R2_ACL}}|${INPUT_RCLONE_R2_ACL}|g" \
                "${config_file}"
            ;;
        gdrive)
            sed -i \
                -e "s|{{RCLONE_GDRIVE_CLIENT_ID}}|${INPUT_RCLONE_GDRIVE_CLIENT_ID}|g" \
                -e "s|{{RCLONE_GDRIVE_CLIENT_SECRET}}|${INPUT_RCLONE_GDRIVE_CLIENT_SECRET}|g" \
                -e "s|{{RCLONE_GDRIVE_SCOPE}}|${INPUT_RCLONE_GDRIVE_SCOPE}|g" \
                -e "s|{{RCLONE_GDRIVE_TOKEN}}|${INPUT_RCLONE_GDRIVE_TOKEN}|g" \
                "${config_file}"
            ;;
        *)
            echo "😔 지원하지 않는 원격 스토리지 타입입니다: ${config_type}"
            exit 1
            ;;
    esac
}

# Function to perform backup for a specific DB type
perform_backup() {
    local db_type=$1
    case "$db_type" in
        mysql)
            INPUT_DB_PORT="${INPUT_DB_PORT:-3306}"
            [[ -n "$INPUT_DB_PASS" ]] && INPUT_PASS="-p${INPUT_DB_PASS}"
            FILENAME="${BACKUP_DIR}/${db_type}-${INPUT_DB_NAME}.${THEDATE}.sql.gz"
            BACKUP_CMD="mysqldump -q -h $INPUT_DB_HOST -u $INPUT_DB_USER -P $INPUT_DB_PORT $INPUT_PASS $INPUT_ARGS $INPUT_DB_NAME | gzip -9 > \"$FILENAME\""
            ;;
        mongo)
            INPUT_DB_PORT="${INPUT_DB_PORT:-27017}"
            INPUT_AUTH_DB="${INPUT_AUTH_DB:-admin}"
            [[ -n "$INPUT_DB_PASS" ]] && INPUT_PASS="-p${INPUT_DB_PASS}"
            FILENAME="${BACKUP_DIR}/${db_type}-${INPUT_DB_NAME}.${THEDATE}.gz"
            BACKUP_CMD="mongodump --gzip --archive=\"$FILENAME\" --host=$INPUT_DB_HOST --port=$INPUT_DB_PORT -d $INPUT_DB_NAME -u $INPUT_DB_USER $INPUT_PASS --authenticationDatabase=$INPUT_AUTH_DB $INPUT_ARGS"
            ;;
        postgres)
            INPUT_DB_PORT="${INPUT_DB_PORT:-5432}"
            export PGPASSWORD="${INPUT_DB_PASS}"
            FILENAME="${BACKUP_DIR}/${db_type}-${INPUT_DB_NAME}.${THEDATE}.pgsql.gz"
            BACKUP_CMD="pg_dump -h $INPUT_DB_HOST -U $INPUT_DB_USER $INPUT_ARGS $INPUT_DB_NAME | gzip -9 > \"$FILENAME\""
            ;;
        *)
            echo "😔 지원하지 않는 DB 타입입니다: ${db_type}"
            exit 1
            ;;
    esac
}

# Check backup type
if [[ "$INPUT_BACKUP_TYPE" == "db" ]]; then
    perform_backup "$INPUT_DB_TYPE"
elif [[ "$INPUT_BACKUP_TYPE" == "directory" ]]; then
    validate_input "INPUT_DIRPATH"
    SLUG=$(echo "$INPUT_DIRPATH" | sed -r 's/[~\^]+//g' | sed -r 's/[^a-zA-Z0-9]+/-/g' | sed -r 's/^-+|-+$//g')
    FILENAME="${BACKUP_DIR}/${INPUT_BACKUP_TYPE}-${SLUG}.${THEDATE}.tar.gz"
    BACKUP_CMD="tar -czf $FILENAME $INPUT_DIRPATH"
else
    echo "😔 지원하지 않는 백업 타입입니다: ${INPUT_BACKUP_TYPE}"
    exit 1
fi

# Display the database type and name being backed up
echo "🔄 ${INPUT_DB_TYPE} 데이터베이스 백업을 시작합니다: ${INPUT_DB_NAME}"

# Execute the backup command
echo "🏃‍♂️ 꽉 잡으세요"
if ! bash -c "$BACKUP_CMD"; then
    echo "😔 ${INPUT_DB_TYPE} 데이터베이스의 백업 명령 실행 중 오류 발생: ${INPUT_DB_NAME}"
    exit 1
fi

# Verify backup file creation
if [[ ! -f "$FILENAME" ]]; then
    echo "😔 백업 파일이 생성되지 않았습니다: $FILENAME"
    exit 1
fi

echo "✅ 백업 완료: ${FILENAME}"

#----------------------------------------
# Rclone 설정 파일 생성 로직 (INPUT_REMOTE이 설정된 경우에만 실행)
#----------------------------------------
if [[ -n "${INPUT_REMOTE}" ]]; then
    case "$INPUT_REMOTE" in
        s3)
            configure_rclone "s3" "s3"
            ;;
        r2)
            configure_rclone "r2" "r2"
            ;;
        gdrive)
            configure_rclone "gdrive" "gdrive"
            ;;
        *)
            echo "😔 지원하지 않는 원격 스토리지 타입입니다: ${INPUT_REMOTE}"
            exit 1
            ;;
    esac

    # Rclone을 사용하여 파일을 업로드
    echo "🚀 Rclone을 사용하여 백업 파일을 업로드 중..."
    rclone --config "${config_file}" copy "${FILENAME}" "${INPUT_REMOTE}":backup/

    if [[ $? -ne 0 ]]; then
        echo "😔 Rclone 업로드 중 오류 발생"
        exit 1
    fi

    echo "✅ Rclone 업로드 완료"
fi

# Backup file 위치 및 목록 확인
echo "📂 백업 파일 위치: ${BACKUP_DIR}"
echo "🔍 백업 파일 목록:"
ls -lhS "${BACKUP_DIR}/"
