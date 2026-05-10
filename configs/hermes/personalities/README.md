# Hermes Personalities — 朝廷角色人设

本目录是 OpenClaw `agents.list[]` 在 Hermes Agent 中的等价物。

## 用法

```bash
mkdir -p ~/.hermes/personalities
cp configs/hermes/personalities/*.md ~/.hermes/personalities/

# 启动 Hermes 后
/personality silijian   # 切换到司礼监
/personality neige      # 切换到内阁
/personality duchayuan  # 切换到都察院
```

## 已提供的核心角色

| 文件 | 朝廷职位 | 职责 |
|---|---|---|
| `silijian.md` | 司礼监 | 任务调度中枢(默认人设,推荐做主入口) |
| `neige.md` | 内阁 | Prompt 优化 + 执行计划生成 |
| `duchayuan.md` | 都察院 | 代码审查 + 质量评估 |

## 想要全部 14 角色?

两条路:

### 1. 自动迁移 OpenClaw 配置

```bash
hermes claw migrate
```

会读 `~/.openclaw/openclaw.json` 里的 `agents.list[].identity.theme`,
转换成 personality 文件落到 `~/.hermes/personalities/`。

### 2. 手动从 openclaw.example.json 导出

```bash
python3 -c "
import json
with open('openclaw.example.json') as f:
    d = json.load(f)
for ag in d['agents']['list']:
    aid = ag['id']
    name = ag['name']
    theme = ag.get('identity',{}).get('theme','')
    fname = f'{aid}.md'
    with open(fname, 'w') as out:
        out.write(f'---\nname: {aid}\ndisplay_name: {name}\n---\n\n{theme}\n')
    print(f'wrote {fname}')
"
```

把生成的所有 `*.md` 拷到 `~/.hermes/personalities/` 即可。

## 字段约定

每个文件用 YAML frontmatter:
- `name`: personality id(切换时用,英文 snake_case)
- `display_name`: 显示名(中文)

frontmatter 之后是 system prompt 正文。
