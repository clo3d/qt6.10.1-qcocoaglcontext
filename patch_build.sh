#!/bin/bash

set -e

# 환경 변수 설정
QT_VERSION="6.10.3"
QT_TAG="v${QT_VERSION}"
QTBASE_REPO="https://code.qt.io/qt/qtbase.git"
QTBASE_REPO_MIRROR="https://github.com/qt/qtbase.git"

SOURCE_DIR="${HOME}/qt-source-build"
QTBASE_DIR="${SOURCE_DIR}/qtbase"
BUILD_DIR="${SOURCE_DIR}/build_qtbase"
INSTALL_DIR="/usr/local/Qt-${QT_VERSION}-CocoaOnly"
DEPLOY_TARGET="12.0"
ARCHS="arm64;x86_64"

# 이 스크립트가 있는 저장소 루트 (패치 소스 위치)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE_REL="qtbase/src/plugins/platforms/cocoa/qcocoaglcontext.mm"
PATCH_SRC="${SCRIPT_DIR}/${PATCH_FILE_REL}"

echo "🎯 qtbase 단독 빌드를 통해 Cocoa 플러그인을 생성합니다. (Target: ${DEPLOY_TARGET})"

# 0. 패치 소스 존재 확인
if [ ! -f "${PATCH_SRC}" ]; then
    echo "❌ 패치 소스를 찾을 수 없습니다: ${PATCH_SRC}"
    exit 1
fi

# 1. qtbase 소스 가져오기 (git clone, 태그 ${QT_TAG})
mkdir -p "${SOURCE_DIR}"
if [ ! -d "${QTBASE_DIR}/.git" ]; then
    if [ -d "${QTBASE_DIR}" ]; then
        echo "ℹ️ 기존 비-Git qtbase 폴더를 백업합니다: ${QTBASE_DIR} -> ${QTBASE_DIR}.bak.$(date +%s)"
        mv "${QTBASE_DIR}" "${QTBASE_DIR}.bak.$(date +%s)"
    fi
    echo "📥 qtbase ${QT_TAG} 클론 중..."
    if ! git clone --depth 1 --branch "${QT_TAG}" "${QTBASE_REPO}" "${QTBASE_DIR}"; then
        echo "⚠️ 공식 저장소 클론 실패 → GitHub 미러로 재시도합니다."
        git clone --depth 1 --branch "${QT_TAG}" "${QTBASE_REPO_MIRROR}" "${QTBASE_DIR}"
    fi
else
    echo "🔄 기존 qtbase 저장소를 ${QT_TAG}로 업데이트합니다."
    git -C "${QTBASE_DIR}" fetch --depth 1 origin "refs/tags/${QT_TAG}:refs/tags/${QT_TAG}"
    git -C "${QTBASE_DIR}" checkout -f "${QT_TAG}"
    git -C "${QTBASE_DIR}" reset --hard "${QT_TAG}"
    git -C "${QTBASE_DIR}" clean -fdx
fi

# 2. 패치된 소스 파일 덮어쓰기
PATCH_DST="${QTBASE_DIR}/src/plugins/platforms/cocoa/qcocoaglcontext.mm"
echo "🩹 패치 적용: ${PATCH_FILE_REL}"
cp "${PATCH_SRC}" "${PATCH_DST}"

# 3. 빌드 폴더 완전 재생성
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# 4. qtbase 전용 Configure 실행
"${QTBASE_DIR}/configure" \
    -prefix "${INSTALL_DIR}" \
    -opensource -confirm-license -release \
    -nomake examples -nomake tests \
    -no-icu \
    -qt-zlib -qt-libpng -qt-libjpeg -qt-freetype \
    -- \
    -DCMAKE_OSX_ARCHITECTURES="${ARCHS}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOY_TARGET}" \
    -DCMAKE_BUILD_TYPE=Release \
    -GNinja

# 5. Cocoa 플러그인 타겟 빌드
echo "🏗️ 빌드 시작..."
cmake --build . --target QCocoaIntegrationPlugin --parallel "$(sysctl -n hw.ncpu)"

# 6. 결과 확인
RESULT_FILE="plugins/platforms/libqcocoa.dylib"
if [ -f "${RESULT_FILE}" ]; then
    echo "✨ 성공! 결과물 위치: $(pwd)/${RESULT_FILE}"
    file "${RESULT_FILE}"
else
    echo "❌ 여전히 에러가 발생한다면, 아래 로그 파일의 마지막 내용을 확인해야 합니다:"
    echo "📍 ${BUILD_DIR}/config.log"
    exit 1
fi
