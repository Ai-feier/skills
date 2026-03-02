# Skill Template

使用此模板创建新的 skill。

## 创建新 Skill

1. 复制模板目录：
   ```bash
   cp -r template skills/your-skill-name
   ```

2. 编辑 `skills/your-skill-name/SKILL.md`

3. 更新 YAML frontmatter：
   ```yaml
   ---
   name: your-skill-name
   description: "具体描述 skill 做什么、什么时候触发。宁可多触发，不可漏触发。"
   ---
   ```

4. 编写 skill 指令内容

## Skill 结构

```
your-skill-name/
├── SKILL.md      # 必需：skill 主文件
├── README.md     # 可选：使用说明
├── examples/    # 可选：示例文件
└── scripts/     # 可选：脚本文件
```

## 必填字段

`SKILL.md` 必须包含 YAML frontmatter：
- `name`：skill 名称（kebab-case）
- `description`：触发描述

## 可选字段

根据需要添加：
- `disable-model-invocation`: `true` - 禁用自动触发
- `user-invocable`: `false` - 隐藏从 / 菜单
- `allowed-tools`: 允许使用的工具列表
- `context`: `fork` - 隔离子代理执行

## 触发原则

`description` 要写得具体且"pushy"：
- 覆盖所有触发场景
- 宁可多触发，不可漏触发
- 使用明确的触发短语
