#!/bin/bash

# 定义路径和仓库地址
LOG_BUILD_PATH="C:/Users/36117/Desktop/zcx/LogBuild"
DEPLOY_PATH="C:/Users/36117/Desktop/zcx/Zcxx0322.github.io"

LOG_BUILD_REPO="git@github.com:Zcxx0322/LogBuild.git"
DEPLOY_REPO="git@github.com:Zcxx0322/Zcxx0322.github.io.git"

# 用户输入 commit 信息
read -p "请输入 Git 提交信息: " COMMIT_MESSAGE

# 进度条显示函数
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

# 第一步：清除 Hexo 缓存
echo "清除 Hexo 缓存..."
cd "$LOG_BUILD_PATH" || exit
hexo clean
show_progress 2

# 第二步：生成静态资源
echo "生成静态资源..."
hexo generate
show_progress 3

# 第三步：提交 LogBuild 仓库
echo "提交 LogBuild 仓库..."
cd "$LOG_BUILD_PATH" || exit

# 初始化 Git 仓库（如果没有初始化）
if [ ! -d ".git" ]; then
    git init
    git remote add origin "$LOG_BUILD_REPO"
fi

git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 3

# 第四步：清空旧的 Zcxx0322.github.io 部署目录
echo "清空 Zcxx0322.github.io 部署目录..."
rm -rf "$DEPLOY_PATH"/*
show_progress 2

# 第五步：拷贝生成的静态资源到部署目录
echo "拷贝静态资源到 Zcxx0322.github.io..."
cp -r "$LOG_BUILD_PATH/public/"* "$DEPLOY_PATH"
show_progress 3

# 第六步：提交 Zcxx0322.github.io 仓库
echo "提交 Zcxx0322.github.io 仓库..."
cd "$DEPLOY_PATH" || exit

# 初始化 Git 仓库（如果没有初始化）
if [ ! -d ".git" ]; then
    git init
    git remote add origin "$DEPLOY_REPO"
fi

git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 5

echo "部署完成！提交信息：$COMMIT_MESSAGE"
