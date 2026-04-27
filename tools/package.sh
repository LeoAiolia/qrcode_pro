#!/usr/bin/env bash

set -Eeuo pipefail

# 技术栈确认：本脚本服务于当前 SwiftUI + Xcode 多平台项目。
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly PROJECT_PATH="$ROOT_DIR/QRScan Pro.xcodeproj"
readonly IOS_SCHEME="QRScan Pro iOS"
readonly MAC_SCHEME="QRScan Pro Mac"
readonly APP_NAME="QRScan Pro"
readonly DIST_ROOT="${DIST_ROOT:-$ROOT_DIR/dist}"
readonly BUILD_ROOT="${BUILD_ROOT:-$ROOT_DIR/build/package}"

platform=""
package_type=""
version=""
build_number=""
allow_provisioning_updates=0

log() {
    printf '[package] %s\n' "$1"
}

die() {
    printf '[package][error] %s\n' "$1" >&2
    exit 1
}

usage() {
    cat <<'USAGE'
用法：
  tools/package.sh [ios|mac|all] [develop|AppStore] [version]
  tools/package.sh --platform ios --type develop --version 1.0.1

参数：
  -p, --platform    打包平台：ios、mac、all。未指定时会交互选择，回车默认 all。
  -t, --type        打包类型：develop、AppStore。未指定时会交互选择，回车默认 develop。
  -v, --version     版本号，格式必须为 x.y.z。未指定时会提示输入，默认使用当前工程版本号。
  --allow-provisioning-updates
                    允许 xcodebuild 自动更新签名配置。
  -h, --help        显示帮助。

环境变量：
  DIST_ROOT         最终产物输出目录，默认 ./dist。
  BUILD_ROOT        中间构建目录，默认 ./build/package。

产物：
  iOS               .ipa
  macOS             .dmg

说明：
  buildNumber       自动使用当前 Git 提交次数，不需要手动输入。
USAGE
}

current_marketing_version() {
    awk -F '= ' '/MARKETING_VERSION = / { gsub(/;/, "", $2); print $2; exit }' "$PROJECT_PATH/project.pbxproj"
}

current_team_id() {
    awk -F '= ' '/DEVELOPMENT_TEAM = / { gsub(/;/, "", $2); print $2; exit }' "$PROJECT_PATH/project.pbxproj"
}

current_build_number() {
    git -C "$ROOT_DIR" rev-list --count HEAD
}

normalize_platform() {
    local raw
    raw="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

    case "$raw" in
        1|ios|iphone|iphoneos)
            printf 'ios'
            ;;
        2|mac|macos|osx)
            printf 'mac'
            ;;
        3|all)
            printf 'all'
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_package_type() {
    local raw
    raw="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

    case "$raw" in
        1|develop|development|dev)
            printf 'develop'
            ;;
        2|appstore|app-store|app_store|app-store-connect)
            printf 'appstore'
            ;;
        *)
            return 1
            ;;
    esac
}

validate_version() {
    [[ "$1" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]]
}

require_interactive() {
    [[ -t 0 ]] || die "$1"
}

prompt_platform() {
    require_interactive "未指定平台，且当前不是交互式终端。请传入 --platform ios|mac|all。"

    local input normalized
    while true; do
        printf '请选择打包平台：\n'
        printf '  1) iOS\n'
        printf '  2) macOS\n'
        printf '  3) all（默认）\n'
        read -r -p "请输入选项 [1/2/3] (默认 3): " input
        input="${input:-3}"
        if normalized="$(normalize_platform "$input")"; then
            platform="$normalized"
            return
        fi
        printf '输入无效，请输入 1、2 或 3。\n'
    done
}

prompt_package_type() {
    require_interactive "未指定打包类型，且当前不是交互式终端。请传入 --type develop|AppStore。"

    local input normalized
    while true; do
        printf '请选择打包类型：\n'
        printf '  1) develop（默认）\n'
        printf '  2) AppStore\n'
        read -r -p "请输入选项 [1/2] (默认 1): " input
        input="${input:-1}"
        if normalized="$(normalize_package_type "$input")"; then
            package_type="$normalized"
            return
        fi
        printf '输入无效，请输入 1 或 2。\n'
    done
}

prompt_version() {
    require_interactive "未指定版本号，且当前不是交互式终端。请传入 --version，例如 --version 1.0.1。"

    local default_version input
    default_version="$(current_marketing_version)"
    [[ -n "$default_version" ]] || die "无法从工程读取当前版本号。"

    while true; do
        read -r -p "请输入版本号 (默认 $default_version): " input
        input="${input:-$default_version}"
        if validate_version "$input"; then
            version="$input"
            return
        fi
        printf '版本号格式无效，请使用 x.y.z 格式，例如 1.0.0。\n'
    done
}

parse_args() {
    local positional=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--platform)
                [[ $# -ge 2 ]] || die "$1 缺少参数值。"
                platform="$2"
                shift 2
                ;;
            -t|--type)
                [[ $# -ge 2 ]] || die "$1 缺少参数值。"
                package_type="$2"
                shift 2
                ;;
            -v|--version)
                [[ $# -ge 2 ]] || die "$1 缺少参数值。"
                version="$2"
                shift 2
                ;;
            --allow-provisioning-updates)
                allow_provisioning_updates=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                die "未知参数：$1"
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#positional[@]} -gt 3 ]]; then
        die "位置参数过多。"
    fi

    if [[ -z "$platform" && ${#positional[@]} -ge 1 ]]; then
        platform="${positional[0]}"
    fi
    if [[ -z "$package_type" && ${#positional[@]} -ge 2 ]]; then
        package_type="${positional[1]}"
    fi
    if [[ -z "$version" && ${#positional[@]} -ge 3 ]]; then
        version="${positional[2]}"
    fi
}

prepare_options() {
    local normalized

    if [[ -n "$platform" ]]; then
        normalized="$(normalize_platform "$platform")" || die "平台无效：${platform}。可选值：ios、mac、all。"
        platform="$normalized"
    else
        prompt_platform
    fi

    if [[ -n "$package_type" ]]; then
        normalized="$(normalize_package_type "$package_type")" || die "打包类型无效：${package_type}。可选值：develop、AppStore。"
        package_type="$normalized"
    else
        prompt_package_type
    fi

    if [[ -n "$version" ]]; then
        validate_version "$version" || die "版本号格式无效：${version}。请使用 x.y.z 格式，例如 1.0.0。"
    else
        prompt_version
    fi
}

prepare_build_number() {
    command -v git >/dev/null 2>&1 || die "找不到 git，无法根据提交次数生成 buildNumber。"
    build_number="$(current_build_number)"
    [[ "$build_number" =~ ^[0-9]+$ && "$build_number" -gt 0 ]] || die "无法获取有效的 Git 提交次数作为 buildNumber。"
}

configuration_for_type() {
    case "$package_type" in
        develop)
            printf 'Debug'
            ;;
        appstore)
            printf 'Release'
            ;;
        *)
            die "未支持的打包类型：$package_type"
            ;;
    esac
}

export_method_for_type() {
    case "$package_type" in
        develop)
            printf 'debugging'
            ;;
        appstore)
            printf 'app-store-connect'
            ;;
        *)
            die "未支持的打包类型：$package_type"
            ;;
    esac
}

package_label() {
    case "$package_type" in
        develop)
            printf 'develop'
            ;;
        appstore)
            printf 'AppStore'
            ;;
        *)
            die "未支持的打包类型：$package_type"
            ;;
    esac
}

write_export_options() {
    local method="$1"
    local plist_path="$2"
    local team_id="$3"

    cat > "$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
    <key>method</key>
    <string>$method</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
PLIST

    if [[ -n "$team_id" ]]; then
        cat >> "$plist_path" <<PLIST
    <key>teamID</key>
    <string>$team_id</string>
PLIST
    fi

    if [[ "$method" == "app-store-connect" ]]; then
        cat >> "$plist_path" <<'PLIST'
    <key>uploadSymbols</key>
    <true/>
PLIST
    fi

    cat >> "$plist_path" <<'PLIST'
</dict>
</plist>
PLIST
}

find_first() {
    local root="$1"
    local pattern="$2"
    [[ -d "$root" ]] || return 0
    find "$root" -name "$pattern" -print -quit
}

archive_common_args() {
    local scheme="$1"
    local configuration="$2"
    local destination="$3"
    local archive_path="$4"
    local derived_data_path="$5"
    local command_args=(
        xcodebuild
        -project "$PROJECT_PATH" \
        -scheme "$scheme" \
        -configuration "$configuration" \
        -destination "$destination" \
        -archivePath "$archive_path" \
        -derivedDataPath "$derived_data_path" \
        MARKETING_VERSION="$version" \
        CURRENT_PROJECT_VERSION="$build_number"
    )

    if [[ "$allow_provisioning_updates" -eq 1 ]]; then
        command_args+=(-allowProvisioningUpdates)
    fi

    command_args+=(
        archive
    )

    "${command_args[@]}"
}

export_archive() {
    local archive_path="$1"
    local export_path="$2"
    local export_options_path="$3"
    local command_args=(
        xcodebuild
        -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "$export_path" \
        -exportOptionsPlist "$export_options_path"
    )

    if [[ "$allow_provisioning_updates" -eq 1 ]]; then
        command_args+=(-allowProvisioningUpdates)
    fi

    "${command_args[@]}"
}

package_ios() {
    local configuration="$1"
    local method="$2"
    local team_id="$3"
    local label="$4"
    local archive_path="$archive_dir/iOS.xcarchive"
    local export_path="$export_dir/iOS"
    local export_options_path="$work_dir/ExportOptions-iOS.plist"
    local ipa_path
    local output_path="$output_dir/QRScanPro-iOS-$version-$label.ipa"

    log "开始 iOS 打包：scheme=${IOS_SCHEME}，configuration=${configuration}，method=$method"
    write_export_options "$method" "$export_options_path" "$team_id"
    archive_common_args "$IOS_SCHEME" "$configuration" "generic/platform=iOS" "$archive_path" "$work_dir/DerivedData-iOS"

    mkdir -p "$export_path"
    export_archive "$archive_path" "$export_path" "$export_options_path"

    ipa_path="$(find_first "$export_path" '*.ipa')"
    [[ -n "$ipa_path" ]] || die "iOS 导出完成但未找到 IPA：$export_path"

    ditto "$ipa_path" "$output_path"
    log "iOS 产物：$output_path"
}

package_mac() {
    local configuration="$1"
    local method="$2"
    local team_id="$3"
    local label="$4"
    local archive_path="$archive_dir/macOS.xcarchive"
    local export_path="$export_dir/macOS"
    local export_options_path="$work_dir/ExportOptions-macOS.plist"
    local app_path
    local staging_dir="$work_dir/dmg-staging"
    local dmg_path="$output_dir/QRScanPro-macOS-$version-$label.dmg"

    log "开始 macOS 打包：scheme=${MAC_SCHEME}，configuration=${configuration}，method=$method"
    write_export_options "$method" "$export_options_path" "$team_id"
    archive_common_args "$MAC_SCHEME" "$configuration" "generic/platform=macOS" "$archive_path" "$work_dir/DerivedData-macOS"

    mkdir -p "$export_path"
    export_archive "$archive_path" "$export_path" "$export_options_path"

    app_path="$(find_first "$export_path" '*.app')"
    if [[ -z "$app_path" ]]; then
        app_path="$(find_first "$archive_path/Products/Applications" '*.app')"
    fi
    [[ -n "$app_path" ]] || die "macOS 导出完成但未找到 App：$export_path"

    rm -rf "$staging_dir"
    mkdir -p "$staging_dir"
    ditto "$app_path" "$staging_dir/$APP_NAME.app"
    ln -s /Applications "$staging_dir/Applications"

    hdiutil create \
        -volname "$APP_NAME $version" \
        -srcfolder "$staging_dir" \
        -ov \
        -format UDZO \
        "$dmg_path"

    log "macOS 产物：$dmg_path"
}

main() {
    parse_args "$@"
    prepare_options
    prepare_build_number

    [[ -d "$PROJECT_PATH" ]] || die "找不到 Xcode 工程：$PROJECT_PATH"
    command -v xcodebuild >/dev/null 2>&1 || die "找不到 xcodebuild，请先安装 Xcode。"
    if [[ "$platform" == "mac" || "$platform" == "all" ]]; then
        command -v hdiutil >/dev/null 2>&1 || die "找不到 hdiutil，无法创建 DMG。"
    fi

    local timestamp configuration method label team_id
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    configuration="$(configuration_for_type)"
    method="$(export_method_for_type)"
    label="$(package_label)"
    team_id="$(current_team_id)"

    readonly work_dir="$BUILD_ROOT/$timestamp"
    readonly archive_dir="$work_dir/archives"
    readonly export_dir="$work_dir/exports"
    readonly output_dir="$DIST_ROOT/$version/$label/$timestamp"

    mkdir -p "$archive_dir" "$export_dir" "$output_dir"

    log "平台：$platform"
    log "类型：$label"
    log "版本号：$version"
    log "buildNumber：$build_number"
    log "输出目录：$output_dir"

    case "$platform" in
        ios)
            package_ios "$configuration" "$method" "$team_id" "$label"
            ;;
        mac)
            package_mac "$configuration" "$method" "$team_id" "$label"
            ;;
        all)
            package_ios "$configuration" "$method" "$team_id" "$label"
            package_mac "$configuration" "$method" "$team_id" "$label"
            ;;
        *)
            die "未支持的平台：$platform"
            ;;
    esac

    log "打包完成。"
}

main "$@"
