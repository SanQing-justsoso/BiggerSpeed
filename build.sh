#!/usr/bin/env bash
# BiggerSpeed 一键编译：两个设备的 .prg + 上架用 .iq
#
# 用法：
#   1. 把【当初上架用的那个】developer_key.der 复制到本目录
#   2. bash build.sh
#
# 产物：
#   bin/BiggerSpeed-edge840.prg   侧载到 Edge 840
#   bin/BiggerSpeed-edge540.prg   侧载到 Edge 540
#   BiggerSpeed.iq                上传 Garmin 商店（自动含全部设备 + 签名）
set -e

# 自动探测本机最新版 Connect IQ SDK
SDK_DIR=$(ls -d "$HOME/AppData/Roaming/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-"* 2>/dev/null | sort -V | tail -1)
if [ -z "$SDK_DIR" ]; then
    echo "错误：找不到 SDK，请确认已安装 Connect IQ SDK" >&2
    exit 1
fi

JAR="$SDK_DIR/bin/monkeybrains.jar"
APIDB="$SDK_DIR/bin/api.db"
APIMIR="$SDK_DIR/bin/api.mir"
KEY="$(pwd)/developer_key.der"

if [ ! -f "$KEY" ]; then
    echo "错误：找不到 $KEY" >&2
    echo "请把当初上架用的 developer_key.der 复制到项目根目录" >&2
    exit 1
fi

echo "SDK : $SDK_DIR"
echo "密钥: $KEY"
echo ""
mkdir -p bin

# 1) 两个设备的 .prg（USB 侧载用）
for DEV in edge840 edge540; do
    echo "===== 编译 .prg : $DEV ====="
    MSYS_NO_PATHCONV=1 java -Xms1g -Dfile.encoding=UTF-8 \
        -jar "$(cygpath -w "$JAR")" \
        -a "$(cygpath -w "$APIDB")" \
        -b "$(cygpath -w "$APIMIR")" \
        -o "$(cygpath -w "$PWD/bin/BiggerSpeed-$DEV.prg")" \
        -f monkey.jungle \
        -d "$DEV" \
        -y "$(cygpath -w "$KEY")" \
        -w
done

# 2) 上架用 .iq（不带 -d，自动打包 manifest 里所有设备）
echo "===== 编译 .iq（含全部设备 + 签名）====="
MSYS_NO_PATHCONV=1 java -Xms1g -Dfile.encoding=UTF-8 \
    -jar "$(cygpath -w "$JAR")" \
    -a "$(cygpath -w "$APIDB")" \
    -b "$(cygpath -w "$APIMIR")" \
    -o "$(cygpath -w "$PWD/BiggerSpeed.iq")" \
    -f monkey.jungle \
    -y "$(cygpath -w "$KEY")" \
    -e -w

echo ""
echo "完成："
echo "  bin/BiggerSpeed-edge840.prg   (侧载到 840)"
echo "  bin/BiggerSpeed-edge540.prg   (侧载到 540)"
echo "  BiggerSpeed.iq                (上传 Garmin 商店)"
