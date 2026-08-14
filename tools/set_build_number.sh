#!/bin/sh
# set_build_number.sh
# 每次 archive 时，自动把 App 的 build number（CFBundleVersion）设为 git 提交次数。
#   - Debug 归档：追加分支后缀（如 52-main），避免 feature 分支撞号
#   - Release 归档：纯数字（如 52），符合 App Store 上架要求
#
# 三个条件按优先级串行判断，全部满足才执行：
#   1. 总开关   BUILD_NUMBER_SCRIPT_AUTO = YES（Xcode build setting，可手动开关）
#   2. 阶段     仅 archive 阶段（$ACTION = "install"；ARCHIVE_PATH 在 Run Script 阶段为空，不可用）
#   3. 环境     git 仓库存在（编译服务 / 无 git 环境时优雅退出）
#
# 用法：作为 target 的 Run Script build phase 调用本脚本即可，无需内联多行逻辑。

set -e

# ---- 条件 A：总开关 ----
if [ "${BUILD_NUMBER_SCRIPT_AUTO}" != "YES" ]; then
    exit 0
fi

# ---- 条件 B：仅 archive 阶段（xcodebuild archive 内部跑的是 install action）----
if [ "${ACTION}" != "install" ]; then
    exit 0
fi

# ---- 条件 C：git 仓库（用 command -v 解析 git 路径，适配 PATH 受限的 CI）----
GIT_BIN="$(command -v git 2>/dev/null || true)"
if [ -z "${GIT_BIN}" ] || ! "${GIT_BIN}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "set_build_number: 未检测到 git 仓库，跳过 build number 更新。"
    exit 0
fi

# 计算提交次数（当前分支历史，输出为干净整数，无 wc 的前导空格问题）
BUILD_NUMBER="$("${GIT_BIN}" rev-list --count HEAD)"

# Debug 归档追加分支后缀；分支名中的 '/' 对 CFBundleVersion 非法，替换为 '-'
BUNDLE_VALUE="${BUILD_NUMBER}"
if [ "${CONFIGURATION}" = "Debug" ]; then
    BRANCH="$("${GIT_BIN}" rev-parse --abbrev-ref HEAD | tr '/' '-')"
    BUNDLE_VALUE="${BUILD_NUMBER}-${BRANCH}"
fi

echo "set_build_number: 设置 CFBundleVersion = ${BUNDLE_VALUE}（来自 git 提交次数）"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUNDLE_VALUE}" \
    "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
