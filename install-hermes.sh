#!/bin/bash

# ========================================
# AI 朝廷 · Hermes Agent 安装脚本
# ========================================
# 与 install-lite.sh 平行,装 Hermes Agent runtime。
# OpenClaw 路线请用 install-lite.sh。
# ========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
echo "========================================"
echo "   AI 朝廷 · Hermes Agent 安装向导"
echo "========================================"
echo -e "${NC}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

# ========================================
# 步骤 1: 检测/安装 Hermes
# ========================================
echo -e "${YELLOW}[1/5] 检测 Hermes Agent${NC}"

if command -v hermes &>/dev/null; then
    HERMES_VER=$(hermes --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓ Hermes 已安装: $HERMES_VER${NC}"
else
    echo -e "${YELLOW}⚠ 未检测到 Hermes,准备安装...${NC}"
    echo "  下载源: https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh"
    read -p "确认安装? (y/N): " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo -e "${RED}✗ 取消安装${NC}"
        exit 1
    fi
    curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
    # 装完通常需要 source ~/.bashrc 或 ~/.zshrc
    if ! command -v hermes &>/dev/null; then
        export PATH="$HOME/.hermes/bin:$PATH"
    fi
    if ! command -v hermes &>/dev/null; then
        echo -e "${YELLOW}⚠ hermes 命令未在当前 shell 生效,请手动 source ~/.bashrc 或 ~/.zshrc 后重跑本脚本${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Hermes 安装完成${NC}"
fi

mkdir -p "$HERMES_HOME"
mkdir -p "$HERMES_HOME/personalities"

# ========================================
# 步骤 2: LLM API 配置
# ========================================
echo ""
echo -e "${YELLOW}[2/5] 配置 LLM API${NC}"
echo ""
echo "Hermes 支持多种 provider,常用:"
echo "  - openrouter (推荐): https://openrouter.ai (200+ 模型)"
echo "  - anthropic: https://console.anthropic.com"
echo "  - openai: https://platform.openai.com"
echo "  - custom (自托管 OpenAI 兼容网关)"
echo ""
read -p "Provider (openrouter/anthropic/openai/custom,默认 openrouter): " PROVIDER
PROVIDER="${PROVIDER:-openrouter}"

case "$PROVIDER" in
    openrouter)
        read -s -p "OPENROUTER_API_KEY: " API_KEY
        echo ""
        read -p "默认模型 (默认 anthropic/claude-opus-4.6): " MODEL_ID
        MODEL_ID="${MODEL_ID:-anthropic/claude-opus-4.6}"
        ENV_LINES="OPENROUTER_API_KEY=$API_KEY"
        ;;
    anthropic)
        read -s -p "ANTHROPIC_API_KEY: " API_KEY
        echo ""
        read -p "默认模型 (默认 claude-opus-4.6): " MODEL_ID
        MODEL_ID="${MODEL_ID:-claude-opus-4.6}"
        ENV_LINES="ANTHROPIC_API_KEY=$API_KEY"
        ;;
    openai)
        read -s -p "OPENAI_API_KEY: " API_KEY
        echo ""
        read -p "默认模型 (默认 gpt-4o): " MODEL_ID
        MODEL_ID="${MODEL_ID:-gpt-4o}"
        ENV_LINES="OPENAI_API_KEY=$API_KEY"
        ;;
    custom)
        read -p "OPENAI_BASE_URL (如 https://api.deepseek.com/v1): " BASE_URL
        read -s -p "OPENAI_API_KEY: " API_KEY
        echo ""
        read -p "默认模型 ID: " MODEL_ID
        ENV_LINES="OPENAI_BASE_URL=$BASE_URL
OPENAI_API_KEY=$API_KEY"
        ;;
    *)
        echo -e "${RED}✗ 未知 provider${NC}"
        exit 1
        ;;
esac
echo -e "${GREEN}✓ LLM 配置完成${NC}"

# ========================================
# 步骤 3: 生成 ~/.hermes/config.yaml
# ========================================
echo ""
echo -e "${YELLOW}[3/5] 生成 config.yaml${NC}"

CONFIG_SOURCE="$REPO_DIR/hermes.example.yaml"
CONFIG_TARGET="$HERMES_HOME/config.yaml"

if [ ! -f "$CONFIG_SOURCE" ]; then
    echo -e "${RED}✗ 找不到模板 $CONFIG_SOURCE${NC}"
    exit 1
fi

if [ -f "$CONFIG_TARGET" ]; then
    echo -e "${YELLOW}⚠ $CONFIG_TARGET 已存在${NC}"
    read -p "覆盖? (y/N): " OVR
    if [ "$OVR" != "y" ] && [ "$OVR" != "Y" ]; then
        echo "  → 跳过 config.yaml"
    else
        cp "$CONFIG_SOURCE" "$CONFIG_TARGET"
        sed -i.bak "s|default: \"anthropic/claude-opus-4.6\"|default: \"$MODEL_ID\"|" "$CONFIG_TARGET"
        rm -f "$CONFIG_TARGET.bak"
        echo -e "${GREEN}✓ 已写入 $CONFIG_TARGET${NC}"
    fi
else
    cp "$CONFIG_SOURCE" "$CONFIG_TARGET"
    sed -i.bak "s|default: \"anthropic/claude-opus-4.6\"|default: \"$MODEL_ID\"|" "$CONFIG_TARGET"
    rm -f "$CONFIG_TARGET.bak"
    echo -e "${GREEN}✓ 已写入 $CONFIG_TARGET${NC}"
fi

# ========================================
# 步骤 4: 生成 ~/.hermes/.env
# ========================================
echo ""
echo -e "${YELLOW}[4/5] 生成 .env${NC}"

ENV_TARGET="$HERMES_HOME/.env"
if [ -f "$ENV_TARGET" ]; then
    echo -e "${YELLOW}⚠ $ENV_TARGET 已存在,追加新 key 而非覆盖${NC}"
    echo "" >> "$ENV_TARGET"
    echo "# === added by install-hermes.sh ===" >> "$ENV_TARGET"
    echo "$ENV_LINES" >> "$ENV_TARGET"
else
    cp "$REPO_DIR/configs/hermes/env.example" "$ENV_TARGET"
    echo "" >> "$ENV_TARGET"
    echo "# === filled by install-hermes.sh ===" >> "$ENV_TARGET"
    echo "$ENV_LINES" >> "$ENV_TARGET"
fi
chmod 600 "$ENV_TARGET"
echo -e "${GREEN}✓ 已写入 $ENV_TARGET${NC}"

# ========================================
# 步骤 5: 拷贝朝廷人设
# ========================================
echo ""
echo -e "${YELLOW}[5/5] 安装朝廷角色 (personalities)${NC}"

PERSONA_SRC="$REPO_DIR/configs/hermes/personalities"
if [ -d "$PERSONA_SRC" ]; then
    cp -n "$PERSONA_SRC"/*.md "$HERMES_HOME/personalities/" 2>/dev/null || true
    PERSONA_COUNT=$(ls "$HERMES_HOME/personalities/"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ 当前已安装 $PERSONA_COUNT 个角色${NC}"
    echo "  完整 14 角色可后续运行: hermes claw migrate (从已有 OpenClaw 配置迁移)"
else
    echo -e "${YELLOW}⚠ $PERSONA_SRC 不存在,跳过${NC}"
fi

# ========================================
# 完成
# ========================================
echo ""
echo -e "${GREEN}========================================"
echo "  ✓ Hermes Agent 安装完成"
echo "========================================${NC}"
echo ""
echo "下一步:"
echo "  1. 完善 token (Discord/Telegram/飞书): ${CYAN}vim $HERMES_HOME/.env${NC}"
echo "  2. 启动 CLI:                          ${CYAN}hermes${NC}"
echo "  3. 启动多平台网关:                    ${CYAN}hermes gateway setup && hermes gateway start${NC}"
echo "  4. 切换角色:                          REPL 内 ${CYAN}/personality silijian${NC}"
echo "  5. Dashboard:                         ${CYAN}hermes dashboard${NC} (默认 http://localhost:8765)"
echo ""
echo "更多:"
echo "  - 配置说明: $REPO_DIR/EXTERNAL_HERMES.md"
echo "  - 官方文档: https://hermes-agent.nousresearch.com/docs/"
