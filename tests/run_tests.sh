#!/bin/bash

# CleanMyDeepin 单元测试运行脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查构建目录
BUILD_DIR="build"
if [ ! -d "$BUILD_DIR" ]; then
    print_info "创建构建目录: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
fi

cd "$BUILD_DIR"

# 配置项目
print_info "配置 CMake 项目..."
cmake .. -DCMAKE_BUILD_TYPE=Debug

# 编译项目
print_info "编译项目..."
make -j$(nproc)

# 运行测试
print_info "运行单元测试..."

# 测试列表
TESTS=(
    "test_scanmanager"
    "test_cleanmanager"
    "test_configmanager"
    "test_logger"
    "test_integration"
)

# 运行结果统计
TOTAL_TESTS=${#TESTS[@]}
PASSED_TESTS=0
FAILED_TESTS=0

print_info "开始运行 $TOTAL_TESTS 个测试套件..."
echo

# 运行每个测试
for test in "${TESTS[@]}"; do
    print_info "运行测试: $test"

    if ./"$test"; then
        print_success "$test 测试通过"
        ((PASSED_TESTS++))
    else
        print_error "$test 测试失败"
        ((FAILED_TESTS++))
    fi
    echo
done

# 打印测试结果摘要
echo "=================================="
print_info "测试结果摘要:"
echo "总测试数: $TOTAL_TESTS"
echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "所有测试都通过了！"
    exit 0
else
    print_error "有 $FAILED_TESTS 个测试失败"
    exit 1
fi