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

ensure_git_repo_is_synced() {
    local repo_path=$1
    local repo_url=$2

    cd "$repo_path" || exit

    if [ ! -d ".git" ]; then
        echo "初始化 Git 仓库..."
        git init
        git remote add origin "$repo_url"
    fi

    echo "检查远程更新..."
    git fetch origin
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    BASE=$(git merge-base HEAD origin/main)

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "本地仓库已是最新。"
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "拉取最新更新..."
        git pull origin main || { echo "拉取失败，请手动解决冲突。"; exit 1; }
    elif [ "$REMOTE" = "$BASE" ]; then
        echo "本地存在未推送的提交，继续处理。"
    else
        echo "本地与远程仓库存在冲突，请手动解决后再继续。"
        exit 1
    fi
}

echo "开始部署 Hexo 博客..."

echo "清除 Hexo 缓存..."
cd "$LOG_BUILD_PATH" || exit
hexo clean
show_progress 2

echo "生成静态资源..."
hexo generate
show_progress 3

echo "确保 LogBuild 仓库同步..."
ensure_git_repo_is_synced "$LOG_BUILD_PATH" "$LOG_BUILD_REPO"

echo "提交 LogBuild 仓库..."
cd "$LOG_BUILD_PATH" || exit
git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 3

echo "同步到 Zcxx0322.github.io 部署目录（保留 README.md 文件）..."
robocopy "$LOG_BUILD_PATH/public/" "$DEPLOY_PATH" /MIR /XF "README.md" > nul
show_progress 2

echo "确保 Zcxx0322.github.io 仓库同步..."
ensure_git_repo_is_synced "$DEPLOY_PATH" "$DEPLOY_REPO"

echo "提交 Zcxx0322.github.io 仓库..."
cd "$DEPLOY_PATH" || exit
git add .
git commit -m "$COMMIT_MESSAGE"
git push -u origin main
show_progress 5

echo "部署完成！提交信息：$COMMIT_MESSAGE"
