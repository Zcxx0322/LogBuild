#!/bin/bash

LOG_BUILD_PATH="E:\\workspace\\LogBuild"
DEPLOY_PATH="E:\\workspace\\Zcxx0322.github.io"
LOG_BUILD_REPO="git@github.com:Zcxx0322/LogBuild.git"
DEPLOY_REPO="git@github.com:Zcxx0322/Zcxx0322.github.io.git"

# 提示输入提交信息
read -p "请输入更新信息: " COMMIT_MESSAGE

# 显示进度条    
show_progress() {
    local duration=$1
    local bar="##################################################"
    local bar_length=${#bar}
    local sleep_time=$2

    for ((i = 1; i <= duration; i++)); do
        local percent=$((i * 100 / duration))
        local bar_fill_length=$((percent * bar_length / 100))
        printf "\r[%s%*s] %d%%" "${bar:0:bar_fill_length}" $((bar_length - bar_fill_length)) "" "$percent"
        [ -n "$sleep_time" ] && sleep "$sleep_time"
    done
    echo ""
}

# Git 提交操作
git_commit_push() {
    local repo_path=$1
    local commit_message=$2

    cd "$repo_path" || exit
    git add .
    git commit -m "$commit_message"
    git push -u origin main
    show_progress 3
}

echo "开始部署 Hexo 博客..."

# 清除 Hexo 缓存并生成静态资源
echo "清除 Hexo 缓存并生成静态资源..."
cd "$LOG_BUILD_PATH" || exit
hexo clean && hexo generate
show_progress 3

# 提交 LogBuild 仓库
echo "提交 LogBuild 仓库..."
git_commit_push "$LOG_BUILD_PATH" "$COMMIT_MESSAGE"

# 拷贝静态资源到部署目录，覆盖现有文件
echo "拷贝静态资源到 Zcxx0322.github.io..."
if [ -d "$LOG_BUILD_PATH/public" ]; then
    cp -r "$LOG_BUILD_PATH/public/"* "$DEPLOY_PATH"
    echo "静态资源拷贝完成。"
else
    echo "错误：未找到 public 目录，请检查 Hexo 是否正确生成静态文件。"
    exit 1
fi
show_progress 3

# 提交 Zcxx0322.github.io 仓库
echo "提交 Zcxx0322.github.io 仓库..."
git_commit_push "$DEPLOY_PATH" "$COMMIT_MESSAGE"

echo "部署完成！提交信息：$COMMIT_MESSAGE"
