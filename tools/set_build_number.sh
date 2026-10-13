#!/bin/sh
# set_build_number.sh
# 每次 archive 前，把 App 的 build number（CFBundleVersion = git 提交次数）写入生成的
# xcconfig（build/generated/BuildNumber.generated.xcconfig），由根目录 BuildNumber.xcconfig
# 通过 #include? 注入为 CURRENT_PROJECT_VERSION。
#
#   - Release 归档：纯数字（如 52），符合 App Store 上架要求
#   - Debug 归档：追加分支后缀（如 52-main），避免 feature 分支撞号
#
# 触发方式：scheme 的 Archive Pre-action（仅在归档时执行一次，先于构建）。
# 命令行走 tools/package.sh 时不经过本脚本——package.sh 已通过
# CURRENT_PROJECT_VERSION=<git 提交次数> 显式传入，无需 pre-action。
#
# 生效条件（按优先级串行判断，全部满足才执行）：
#   1. 总开关   BUILD_NUMBER_SCRIPT_AUTO = YES（build setting，可在工程配置中关闭）
#   2. 环境     git 仓库存在（无 git 环境时优雅退出，回退到 xcconfig 中的默认值）

set -e

# 工程根目录：以脚本自身位置解析，不依赖 Xcode 注入的环境变量
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERATED_XCCONFIG="$ROOT_DIR/build/generated/BuildNumber.generated.xcconfig"

# ---- 条件 A：总开关 ----
if [ "${BUILD_NUMBER_SCRIPT_AUTO}" != "YES" ]; then
    echo "set_build_number: BUILD_NUMBER_SCRIPT_AUTO 未开启，跳过 build number 更新。"
    exit 0
fi

# ---- 条件 B：git 仓库（用 command -v 解析 git 路径，适配 PATH 受限的环境）----
GIT_BIN="$(command -v git 2>/dev/null || true)"
if [ -z "${GIT_BIN}" ] || ! "${GIT_BIN}" -C "$ROOT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    echo "set_build_number: 未检测到 git 仓库，跳过 build number 更新。"
    exit 0
fi

# 计算提交次数（当前分支历史，输出为干净整数，无 wc 的前导空格问题）
BUILD_NUMBER="$("${GIT_BIN}" -C "$ROOT_DIR" rev-list --count HEAD)"

# Debug 归档追加分支后缀；分支名中的 '/' 对 CFBundleVersion 非法，替换为 '-'
BUNDLE_VALUE="${BUILD_NUMBER}"
if [ "${CONFIGURATION}" = "Debug" ]; then
    BRANCH="$("${GIT_BIN}" -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD | tr '/' '-')"
    BUNDLE_VALUE="${BUILD_NUMBER}-${BRANCH}"
fi

mkdir -p "$(dirname "$GENERATED_XCCONFIG")"
printf '// 本文件由 tools/set_build_number.sh 自动生成，请勿手改。\nCURRENT_PROJECT_VERSION = %s\n' "${BUNDLE_VALUE}" > "$GENERATED_XCCONFIG"
echo "set_build_number: 已写入 ${GENERATED_XCCONFIG}（CURRENT_PROJECT_VERSION = ${BUNDLE_VALUE}）"
