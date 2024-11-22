#!/bin/bash

LOG_BUILD_PATH="C:/Users/36117/Desktop/zcx/LogBuild"
DEPLOY_PATH="C:/Users/36117/Desktop/zcx/Zcxx0322.github.io"

LOG_BUILD_REPO="git@github.com:Zcxx0322/LogBuild.git"
DEPLOY_REPO="git@github.com:Zcxx0322/Zcxx0322.github.io.git"

read -p "请输入更新信息: " COMMIT_MESSAGE

show_progress() {
    local duration=$1
    local bar="##################################################"
    local bar_length=${#bar}

    for ((i = 1; i <= duration; i++)); do
        local percent=$((i * 100 / duration))
        local bar_fill_length=$((percent * bar_length / 100))
        printf "\r[%s%*s] %d%%" "${bar:0:bar_fill_length}" $((bar_length - bar_fill_length)) "" "$percent"
        sleep 1
    done
    echo ""
}

echo "开始部署 Hexo 博客..."

# 清除 Hexo 缓存并生成静态资源
echo "清除 Hexo 缓存并生成静态资源..."
cd "$LOG_BUILD_PATH" || exit
hexo clean && hexo generate
show_progress 3

# 提交 LogBuild 仓库
echo "提交 LogBuild 仓库..."
git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 3

# 清空 Zcxx0322.github.io 部署目录，保留 .git 和 README.md
echo "清空 Zcxx0322.github.io 部署目录（保留 .git 和 README.md）..."
cd "$DEPLOY_PATH" || exit
find . -mindepth 1 ! -name "README.md" ! -name ".git" -exec rm -rf {} +
show_progress 2

# 拷贝静态资源到部署目录
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
cd "$DEPLOY_PATH" || exit

# 确保在 main 分支，并拉取最新代码
git checkout main || exit  # 如果不在 main 分支，则切换到 main 分支
git pull origin main --rebase || exit  # 拉取远程最新代码

git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 3

echo "部署完成！提交信息：$COMMIT_MESSAGE"
