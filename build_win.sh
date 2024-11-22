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

# 清除 Hexo 缓存
echo "清除 Hexo 缓存..."
cd "$LOG_BUILD_PATH" || exit
hexo clean
show_progress 2

# 检查并删除意外生成的 nul 文件
if [ -f "$LOG_BUILD_PATH/nul" ]; then
    echo "检测到意外生成的 nul 文件，正在清理..."
    rm -f "$LOG_BUILD_PATH/nul"
fi

# 生成静态资源
echo "生成静态资源..."
hexo generate
show_progress 3

# 提交 LogBuild 仓库
echo "提交 LogBuild 仓库..."
cd "$LOG_BUILD_PATH" || exit

# 确保本地切换到 main 分支
git checkout main

if [ ! -d ".git" ]; then
    git init
    git remote add origin "$LOG_BUILD_REPO"
else
    git pull origin main --rebase  # 拉取远程仓库最新的提交，避免冲突
fi

git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 3

# 清空 Zcxx0322.github.io 部署目录，但保留 README.md
echo "清空 Zcxx0322.github.io 部署目录（保留 README.md）..."
cd "$DEPLOY_PATH" || exit
find . -mindepth 1 ! -name "README.md" -exec rm -rf {} +
show_progress 2

# 拷贝静态资源
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

# 确保本地切换到 main 分支
git checkout main

if [ ! -d ".git" ]; then
    git init
    git remote add origin "$DEPLOY_REPO"
else
    git pull origin main --rebase  # 拉取远程仓库最新的提交，避免冲突
fi

git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 5

echo "部署完成！提交信息：$COMMIT_MESSAGE"
