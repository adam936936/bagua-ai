# Git使用指南

## SSH配置完成
- ✅ Git用户信息已配置
- ✅ SSH密钥已生成
- ✅ SSH配置已完成

## 使用方法

### 1. 提交代码
使用提交脚本:
```bash
./scripts/git-commit.sh
```

### 2. 常用Git命令
```bash
# 查看状态
git status

# 添加文件
git add .

# 提交代码
git commit -m "提交信息"

# 推送代码
git push origin main

# 拉取代码
git pull origin main
```

### 3. 远程仓库管理
```bash
# 查看远程仓库
git remote -v

# 添加远程仓库
git remote add origin <仓库URL>

# 修改远程仓库URL
git remote set-url origin <新URL>
```

### 4. 网络问题解决
如果遇到连接问题，可以尝试使用443端口:
```bash
# GitHub
git remote set-url origin git@github-443:username/repo.git

# Gitee
git remote set-url origin git@gitee-443:username/repo.git
```

## 公钥信息
您的SSH公钥位置: ~/.ssh/id_rsa.pub

请确保已将公钥添加到:
- GitHub: https://github.com/settings/ssh/new
- Gitee: https://gitee.com/profile/sshkeys
