#!/bin/bash

set -eu
LOG_FILE="${GITHUB_WORKSPACE}/backup_script.log"
exec 2>>"$LOG_FILE"

# 스크립트 종료 시 청소 작업 실행
trap cleanup EXIT

#----------------------------------------
# 오류 메시지 출력 함수
#----------------------------------------
error_exit() {
    echo "❌ Error: $1" | tee -a "$LOG_FILE"
    exit 1
}

#----------------------------------------
# 환경 변수 유효성 검사 및 로깅
#----------------------------------------
check_required_env() {
    local VAR_NAME=$1
    local DISPLAY_VAR_NAME="${VAR_NAME#INPUT_}"
    echo "🔍 Checking environment variable: $DISPLAY_VAR_NAME" | tee -a "$LOG_FILE"
    if [[ -z "${!VAR_NAME:-}" ]]; then
        error_exit "환경 변수 '${DISPLAY_VAR_NAME}'가 설정되지 않았습니다. 이 변수는 필수입니다."
    fi
}

# 지원되는 DB 유형 검증
validate_db_type() {
    case "$INPUT_DB_TYPE" in
        mysql|mongo|postgres) ;;
        *) error_exit "지원하지 않는 DB 타입입니다: $INPUT_DB_TYPE" ;;
    esac
}

# 필수 환경 변수 검증
validate_required_envs() {
    check_required_env "INPUT_DB_TYPE"
    validate_db_type

    if [[ -z "${INPUT_DB_STRING:-}" ]]; then
        check_required_env "INPUT_DB_HOST"
        check_required_env "INPUT_DB_NAME"
        check_required_env "INPUT_DB_USER"
        check_required_env "INPUT_DB_PASS"
    fi

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
                error_exit "지원하지 않는 원격 설정: ${INPUT_REMOTE}"
                ;;
        esac
    fi
}

validate_required_envs || error_exit "환경 변수 유효성 검사 중 오류 발생"
echo "✅ 모든 필수 환경 변수가 설정되었습니다. 백업을 시작합니다." | tee -a "$LOG_FILE"

#----------------------------------------
# 백업 디렉토리 및 상수 초기화
#----------------------------------------
THEDATE=$(TZ=Asia/Seoul date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${GITHUB_WORKSPACE}/backups"
CONFIG_DIR="${GITHUB_WORKSPACE}/config"
mkdir -p "${BACKUP_DIR}" "${CONFIG_DIR}" || error_exit "백업 및 설정 디렉토리 생성 실패"

CONFIG_FILE="${CONFIG_DIR}/rclone.conf"
TEMPLATE_DIR="${INPUT_TEMPLATE_DIR:-/templates}"

#----------------------------------------
# 템플릿 유효성 검사 함수
#----------------------------------------
validate_template() {
    local TEMPLATE_FILE=$1
    echo "🔍 템플릿 파일을 확인 중입니다: ${TEMPLATE_DIR}/${TEMPLATE_FILE}.template" | tee -a "$LOG_FILE"
    if [[ ! -f "${TEMPLATE_DIR}/${TEMPLATE_FILE}.template" ]]; then
        error_exit "템플릿 파일이 존재하지 않습니다: ${TEMPLATE_FILE}.template (경로: ${TEMPLATE_DIR})"
    fi
}

#----------------------------------------
# DB 백업 수행 함수
#----------------------------------------
perform_backup() {
    local DB_TYPE=$1
    echo "🔄 ${DB_TYPE} 데이터베이스 백업을 시작합니다..." | tee -a "$LOG_FILE"

    # 백업 시작 시간 기록
    local START_TIME=$(date +%s)
    case "$DB_TYPE" in
        mysql)
            INPUT_DB_PORT="${INPUT_DB_PORT:-3306}"
            FILENAME="${BACKUP_DIR}/${INPUT_DB_TYPE}-${GITHUB_HEAD_REF:-${INPUT_DB_NAME}}.${THEDATE}.sql.gz"
            if [[ -n "${INPUT_DB_STRING:-}" ]]; then
                BACKUP_CMD="mysqldump ${INPUT_DB_STRING} | gzip -9 > \"${FILENAME}\""
            else
                BACKUP_CMD="mysqldump -h \"$INPUT_DB_HOST\" -P \"$INPUT_DB_PORT\" \"$INPUT_DB_NAME\" -u \"$INPUT_DB_USER\" -p\"$INPUT_DB_PASS\" | gzip -9 > \"$FILENAME\""
            fi
            ;;
        mongo)
            INPUT_DB_PORT="${INPUT_DB_PORT:-27017}"
            INPUT_AUTH_DB="${INPUT_AUTH_DB:-admin}"
            FILENAME="${BACKUP_DIR}/${INPUT_DB_TYPE}-${GITHUB_HEAD_REF:-${INPUT_DB_NAME}}.${THEDATE}.gz"
            if [[ -n "${INPUT_DB_STRING:-}" ]]; then
                BACKUP_CMD="mongodump ${INPUT_DB_STRING} | gzip -9 > \"${FILENAME}\""
            else
                if [[ "$INPUT_DB_HOST" == *"mongodb.net"* ]]; then
                    BACKUP_CMD="mongodump --gzip --archive=\"$FILENAME\" --uri=\"mongodb+srv://$INPUT_DB_USER:$INPUT_DB_PASS@$INPUT_DB_HOST/$INPUT_DB_NAME\" --authenticationDatabase=$INPUT_AUTH_DB"
                else
                    BACKUP_CMD="mongodump --gzip --archive=\"$FILENAME\" --host=\"$INPUT_DB_HOST\" --port=\"$INPUT_DB_PORT\" -d \"$INPUT_DB_NAME\" -u \"$INPUT_DB_USER\" -p \"$INPUT_DB_PASS\" --authenticationDatabase=$INPUT_AUTH_DB"
                fi
            fi
            ;;
        postgres)
            INPUT_DB_PORT="${INPUT_DB_PORT:-5432}"
            export PGPASSWORD="${INPUT_DB_PASS}"
            FILENAME="${BACKUP_DIR}/${INPUT_DB_TYPE}-${GITHUB_HEAD_REF:-${INPUT_DB_NAME}}.${THEDATE}.pgsql.gz"
            if [[ -n "${INPUT_DB_STRING:-}" ]]; then
                BACKUP_CMD="pg_dump ${INPUT_DB_STRING} | gzip -9 > \"${FILENAME}\""
            else
                BACKUP_CMD="PGPASSWORD=\"$INPUT_DB_PASS\" pg_dump -h \"$INPUT_DB_HOST\" -p \"$INPUT_DB_PORT\" -d \"$INPUT_DB_NAME\" -U \"$INPUT_DB_USER\" | gzip -9 > \"$FILENAME\""
            fi
            ;;
        *)
            error_exit "지원하지 않는 DB 타입입니다: ${DB_TYPE}"
            ;;
    esac

    echo "🏃‍♂️ 백업 명령 실행 중..." | tee -a "$LOG_FILE"
    if ! bash -c "$BACKUP_CMD"; then
        error_exit "${INPUT_DB_TYPE} 데이터베이스의 백업 명령 실행 중 오류 발생: ${INPUT_DB_NAME}"
    fi

    # 백업 종료 시간 기록
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))

    if [[ ! -f "$FILENAME" ]]; then
        error_exit "백업 파일이 생성되지 않았습니다: $FILENAME"
    fi

    echo "✅ 백업 완료: ${FILENAME}" | tee -a "$LOG_FILE"
    echo "⏱️ ${DB_TYPE} 백업에 걸린 시간: ${DURATION}초" | tee -a "$LOG_FILE"
}

# 백업 수행
perform_backup "$INPUT_DB_TYPE" || error_exit "백업 수행 중 오류 발생"

# Rclone 업로드
if [[ -n "${INPUT_REMOTE}" ]]; then
    configure_rclone "$INPUT_REMOTE" || error_exit "Rclone 설정 중 오류 발생"
    echo "🚀 Rclone을 사용하여 백업 파일을 업로드 중..." | tee -a "$LOG_FILE"
    if ! rclone --config "${CONFIG_FILE}" copy "${FILENAME}" "${INPUT_REMOTE}":backup/; then
        error_exit "Rclone 업로드 실패"
    fi
    echo "✅ Rclone 업로드 완료" | tee -a "$LOG_FILE"
fi

# 청소 작업
cleanup() {
    echo "🧹 백업 및 설정 파일을 삭제 중입니다..." | tee -a "$LOG_FILE"
    rm -f "${FILENAME}"
    rm -f "${CONFIG_FILE}"
    rm -rf "${BACKUP_DIR}"
    rm -rf "${CONFIG_DIR}"
    echo "✅ 파일 삭제 완료. 모든 작업이 끝났습니다." | tee -a "$LOG_FILE"
    
    # Markdown 형식의 로그 파일 출력
    {
        echo "# 📋 백업 스크립트 로그 요약"
        
        if grep -q "❌ Error" "$LOG_FILE"; then
            echo "## ❌ 오류 발생"
            grep "❌ Error" "$LOG_FILE" | sed 's/^/ - /'
        else
            echo "## ✅ 성공적으로 수행된 작업"
            echo " - 모든 작업이 성공적으로 완료되었습니다."
            echo " - 생성된 백업 파일: \`$FILENAME\`"
        fi
        
        echo "## ⏱️ 백업 수행 시간"
        grep -E "⏱️|백업 완료" "$LOG_FILE" | sed 's/^/ - /'
        
        echo "## 📄 전체 로그"
        cat "$LOG_FILE"
    } >> "$GITHUB_STEP_SUMMARY"
}

