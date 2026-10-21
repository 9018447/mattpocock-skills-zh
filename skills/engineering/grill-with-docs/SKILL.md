---
name: grill-with-docs
description: 在项目上下文中严格盘问计划或设计，整理需要沉淀的领域决策，并提示用户明确派发领域建模工作。
disable-model-invocation: true
---

调用 Skill 工具并传入 "grilling"，进行需求与设计盘问。

`domain-modeling` 现为用户调用的 acpx 派发入口，不得通过 Skill 工具自动调用它，也不得自行代替它更新 Glossary 或 ADR。涉及确定领域术语、领域边界或需要记录 ADR 时，汇总当前对话中已经确认的内容，提示用户显式调用 `/domain-modeling` 并指定执行 Agent；待派发结果返回后继续本流程。
