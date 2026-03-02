---
name: lesson
description: "Use when user says 'lesson', '/lesson', '记录经验', '铁律', '记住这个', or when the agent encounters a significant pitfall, unexpected behavior, hard-won insight, or project-specific pattern during work that would prevent future mistakes. MUST trigger proactively when: debugging took 2+ attempts, a wrong assumption was corrected, a non-obvious project convention was discovered, or counter-intuitive framework/tool behavior was encountered. Always write to the project's MEMORY.md."
---

# Lesson — Iron Rule Capture

Record hard-won lessons as iron rules in the project's `MEMORY.md`.

## Trigger

**Manual**: User says `lesson`, `/lesson`, `记录经验`, `铁律`, `记住这个`.

**Auto-detect**: Proactively suggest recording when ANY of these occur during work:
- Debugging took 2+ attempts
- A wrong assumption was corrected
- Non-obvious project convention discovered
- Counter-intuitive framework/tool behavior encountered
- A repeated pattern worth codifying

Auto-detect MUST ask user confirmation before writing. Present:
```
🔔 检测到潜在铁律:
**{rule}** — {reason}

写入 MEMORY.md？
```

## Process

1. **Identify** the lesson from conversation context or user input
2. **Read** project root `MEMORY.md`
3. **Quality check** — the rule must be:
   - Actionable (clear do/don't)
   - Specific (not generic advice)
   - Concise (rule + reason ≤ ~80 chars)
   - Useful (would prevent a real future mistake)
4. **Dedup** — compare against existing rules:
   - Semantic duplicate → skip, tell user "已存在类似铁律: {existing}"
   - Partial overlap → merge into more precise version
   - New → append
5. **Categorize** — place under existing `## Section` in MEMORY.md; create new section only if none fits
6. **Write** via Edit tool (append to correct section)
7. **Confirm** — show user what was written

## Iron Rule Format

```markdown
- **{Actionable rule}** — {Reason, max 15 chars}
```

One bullet per rule. Bold = the instruction. Dash-suffix = minimal why.

## Examples

Good:
- **gitaly image tag 必须与 Chart.appVersion 一致** — 否则 CrashLoopBackOff
- **禁止在 CronJob 中使用 latest tag** — 导致不可复现部署

Bad (too vague):
- 注意 Helm values 的配置 ← not actionable
- Kubernetes 很复杂要小心 ← not specific

## Scope

- Writes ONLY to the current project's `MEMORY.md` (project root)
- Does NOT create learned skills (those are separate, detailed pattern docs)
- Does NOT modify global config
