---
name: init-claude-md-v2
description: "在项目根目录生成 CLAUDE.md 文件和 .claude/ 配置骨架，采用 DDD 架构模式，包含标准化架构设计文档和代码模板。手动触发，检查是否存在后写入模板。"
---

# init-claude-md-v2 Skill

## 概述

此 skill 用于在项目根目录生成 `CLAUDE.md` 入口文件和 `.claude/` 骨架，建立面向 Claude Code 的 DDD 项目指令体系。

核心设计原则：

- **CLAUDE.md 是指令入口，不是百科全书**：~150 行的指令文件，详细内容放在规则文件中
- **DDD 架构优先**：标准四层架构（领域/应用/基础设施/接口）
- **代码模板驱动**：按主题拆分模板文件，每个模板独立维护
- **指令分层**：CLAUDE.md 定义核心指令，详细规范放在 `.claude/rules/` 中
- **渐进式披露**：从骨架开始，规则随项目复杂度按需创建
- **自动加载**：Claude Code 自动读取 CLAUDE.md 和 `.claude/rules/` 下的规则文件

## 使用方式

在项目中执行：

```
/init-claude-md-v2
```

## 工作流程

1. 检查项目根目录是否已存在 `CLAUDE.md`
2. 如果存在 → 提示用户选择覆盖或跳过
3. 如果不存在 → 写入 `CLAUDE.md` 模板 + 创建 `.claude/` 骨架
4. 显示成功消息，提示用户填写占位内容

---

## 目录结构

```
init-claude-md-v2/
├── SKILL.md                  # Skill 入口文件
└── references/               # 参考文件
    ├── go.md                 # Go 语言代码模型
    ├── typescript.md         # TypeScript 代码模型
    ├── python.md             # Python 代码模型
    └── java.md               # Java 代码模型
```

---

## CLAUDE.md 模板

```markdown
# CLAUDE.md

> 此文件是 Claude Code 在本项目的**指令入口**，保持精简（~150 行）。
> 原则：指令，不是百科全书。Claude Code 会自动读取此文件。

## 指令加载方式

Claude Code 自动加载以下内容：

```
CLAUDE.md                    # 项目级指令（本文件）
.claude/rules/               # 规则文件目录
   ├─ common/                # 通用规则（跨项目共享）
   └─ local/                 # 本地规则（项目特定）
       ├─ ddd-design.md      # DDD 设计指南
       ├─ naming.md          # 命名约定
       ├─ framework.md       # 框架使用模板
       └─ api.md             # API 开发模板
```

## 项目概述

[项目维护者在此描述项目目的、核心业务领域和关键功能]

## 技术栈

- **语言**：[待填写]
- **框架**：[待填写]
- **数据库**：[待填写]

---

## DDD 四层架构

```
┌─────────────────────────────────────────────────────┐
│              用户界面层 (Interfaces)                 │
│   Controller · DTO · Assembler · Facade            │
├─────────────────────────────────────────────────────┤
│                应用层 (Application)                  │
│   Service · Command · Query · EventHandler         │
├─────────────────────────────────────────────────────┤
│                 领域层 (Domain)                      │
│   Entity · ValueObject · Aggregate · Repository接口 │
│   DomainService · DomainEvent                      │
├─────────────────────────────────────────────────────┤
│             基础设施层 (Infrastructure)              │
│   Repository实现 · MQ · Cache · ExternalService     │
└─────────────────────────────────────────────────────┘
```

**依赖原则**：上层依赖下层，领域层不依赖技术框架。

详细设计指南见 `.claude/rules/local/ddd-design.md`。

## 限界上下文

[待填写：定义核心限界上下文及其边界]

---

## 构建命令

```bash
# 安装依赖
[待填写]

# 开发模式
[待填写]

# 测试
[待填写]

# 代码检查
[待填写]
```

---

## 编码规范

- **命名约定**：见 `.claude/rules/local/naming.md`
- **框架模板**：见 `.claude/rules/local/framework.md`
- **API 模板**：见 `.claude/rules/local/api.md`

---

## 测试策略

| 层级 | 测试类型 | 重点 |
|-----|---------|------|
| 领域层 | 单元测试 | 业务规则、不变性约束 |
| 应用层 | 单元测试 | 用例编排、命令处理 |
| 基础设施层 | 集成测试 | 仓储实现、外部服务 |
| 接口层 | E2E 测试 | API 契约、请求响应 |

---

## 规则治理

### 规则文件约定
- **规则目录**：`.claude/rules/local/` 存放项目特定规则
- **命名规范**：`{类别}.md`
- **规则粒度**：每个规则文件专注一个主题

### 渐进式规则策略
- 初始包含 DDD 设计指南和基础模板
- 需要新规则时：创建规则文件 → 在 CLAUDE.md 中引用
- 规则文件应按需扩展，避免冗余

## 注意事项

[项目维护者在此添加项目特定的注意事项和约束]
```

---

## 初始生成的骨架

执行此 skill 时，生成以下结构：

```
CLAUDE.md
.claude/
└── rules/
    └── local/
        ├── ddd-design.md           # DDD 设计指南
        ├── naming.md               # 命名约定
        ├── framework.md            # 框架使用模板
        └── api.md                  # API 开发模板
```

---

## 规则文件内容

### ddd-design.md

```markdown
# DDD 设计指南

> 基于 DDD 实战课程，引导领域驱动设计思考过程。

---

## 一、DDD 核心概念

### 1. 领域与子域

- **领域**：特定业务范围的业务问题域
- **子域**：领域拆分后的业务问题子集
- **核心域**：决定产品竞争力的核心业务
- **通用域**：多个子域通用的业务能力
- **支撑域**：支撑核心业务的辅助能力

### 2. 限界上下文

- 定义领域边界的利器
- 一个限界上下文 = 一个微服务
- 上下文内：统一语言、模型一致
- 上下文间：通过上下文映射集成

### 3. 实体与值对象

| 特性 | 实体 | 值对象 |
|-----|------|--------|
| 唯一标识 | 有（ID） | 无 |
| 可变性 | 可变 | 不可变 |
| 相等判断 | ID 相等 | 属性值相等 |
| 生命周期 | 有生命周期 | 无生命周期 |

**值对象使用场景**：地址、金额、日期范围等描述性属性

### 4. 聚合与聚合根

**聚合**：一组相关领域对象的集合，作为数据修改和持久化的基本单元

**聚合根**：聚合的入口和管理者，对外代表整个聚合

---

## 二、聚合设计原则

### 核心原则（必须遵守）

1. **聚合内强一致性**：聚合内的所有对象必须保持一致状态
2. **聚合间最终一致性**：聚合之间通过 ID 引用，不直接持有对象引用
3. **单一事务原则**：一个事务只修改一个聚合实例
4. **聚合根守门员**：外部只能通过聚合根访问聚合内对象

### 聚合设计步骤

1. **识别业务规则**：找出必须保持一致的业务约束
2. **确定一致性边界**：哪些对象必须在同一事务内修改
3. **设计聚合根**：选择最合适的实体作为聚合根
4. **最小化聚合**：聚合越小越好，只包含必要的对象

### 聚合设计反模式

- ❌ 聚合过大：包含过多对象，性能差、并发冲突多
- ❌ 聚合过小：无法保证业务一致性
- ❌ 跨聚合直接引用：导致事务边界混乱

---

## 三、DDD 四层架构

```
┌─────────────────────────────────────────────────────┐
│                  用户界面层 (Interfaces)              │
│     Controller、DTO、Assembler、Facade              │
├─────────────────────────────────────────────────────┤
│                    应用层 (Application)              │
│     Service、Command、Query、EventHandler           │
├─────────────────────────────────────────────────────┤
│                    领域层 (Domain)                   │
│     Entity、ValueObject、Aggregate、Repository接口   │
│     DomainService、DomainEvent                      │
├─────────────────────────────────────────────────────┤
│                  基础设施层 (Infrastructure)          │
│     Repository实现、MQ、Cache、ExternalService       │
└─────────────────────────────────────────────────────┘
```

### 各层职责

| 层级 | 职责 | 关键规则 |
|-----|------|---------|
| 用户界面层 | 接收请求、返回响应 | 只做格式转换，不含业务逻辑 |
| 应用层 | 编排业务用例 | 不含业务规则，只协调领域对象 |
| 领域层 | 核心业务逻辑 | 纯粹的业务规则，不依赖技术实现 |
| 基础设施层 | 技术实现 | 实现领域层定义的接口 |

### 依赖原则

- **单向依赖**：上层依赖下层，下层不依赖上层
- **依赖倒置**：领域层定义接口，基础设施层实现
- **领域层纯净**：领域层不依赖任何技术框架

---

## 四、代码模型

> 详细的多语言代码模型示例见 skill 的 `references/` 目录：
> - **Go**: 见 `references/go.md`
> - **TypeScript**: 见 `references/typescript.md`
> - **Python**: 见 `references/python.md`
> - **Java**: 见 `references/java.md`

### 通用目录结构原则

```
{module}/                          # 模块/限界上下文
├── internal/                      # 内部实现（不对外暴露）
│   ├── domain/                   # 领域层
│   ├── service/                  # 应用层服务
│   ├── repository/               # 仓储层
│   ├── web/                      # 用户界面层
│   ├── event/                    # 领域事件
│   ├── job/                      # 定时任务
│   └── errs/                     # 错误码定义
└── module.go                     # 模块入口
```

### 各层对象职责

| 对象 | 所在层 | 职责 |
|-----|-------|------|
| Handler/Controller | 用户界面层 | 接收 HTTP 请求，调用应用服务，返回响应 |
| VO/DTO | 用户界面层 | 数据传输对象，隔离外部与内部模型 |
| Service | 应用层 | 编排用例，不包含业务规则 |
| Entity | 领域层 | 有唯一标识，封装业务行为 |
| ValueObject | 领域层 | 无标识，不可变，描述属性 |
| Repository接口 | 领域层 | 定义数据访问抽象 |
| DAO | 基础设施层 | 数据库访问对象 |
| Event | 领域层 | 表达业务状态变更 |

---

## 五、领域事件

### 事件设计

```typescript
// 领域事件定义
interface DomainEvent {
  eventId: string;        // 事件唯一ID
  eventType: string;      // 事件类型
  aggregateId: string;    // 聚合ID
  occurredOn: Date;       // 发生时间
  payload: object;        // 事件数据
}

// 示例
class OrderCreatedEvent implements DomainEvent {
  eventId = uuid();
  eventType = 'order.created';
  aggregateId: string;    // 订单ID
  occurredOn = new Date();
  payload: {
    customerId: string;
    totalAmount: number;
    items: OrderItemDTO[];
  };
}
```

### 事件发布时机

- 聚合状态变更后立即发布
- 在事务内发布，保证一致性
- 通过事件总线分发到订阅者

### 事件用途

1. **解耦聚合**：聚合间通过事件通信，避免直接依赖
2. **解耦微服务**：跨限界上下文的异步通信
3. **事件溯源**：通过事件重建聚合状态
4. **业务审计**：记录完整的业务变更历史

---

## 六、事件风暴建模

### 核心要素

| 便利贴颜色 | 要素 | 说明 |
|-----------|------|------|
| 橙色 | 领域事件 | 业务状态变更（过去式命名） |
| 蓝色 | 命令 | 触发事件的动作 |
| 黄色 | 聚合 | 处理命令、产生事件的实体 |
| 粉色 | 角色/参与者 | 发起命令的人或系统 |
| 绿色 | 读模型 | 查询数据的视图 |
| 紫色 | 策略 | 事件触发的后续动作 |

### 建模步骤

1. **梳理领域事件**：找出业务中的关键状态变更
2. **识别命令**：什么动作触发了这些事件
3. **确定聚合**：哪个对象处理命令、产生事件
4. **划分边界**：根据聚合簇确定限界上下文
5. **识别角色**：谁发起命令
6. **定义读模型**：需要展示什么数据

### 事件命名规范

- 过去式动词 + 名词
- 例：`OrderCreated`、`PaymentCompleted`、`InventoryReserved`

---

## 七、设计检查清单

### 聚合设计检查

- [ ] 聚合边界是否清晰？
- [ ] 聚合根是否明确？
- [ ] 聚合内是否保证强一致性？
- [ ] 聚合间是否通过 ID 引用？
- [ ] 一个事务是否只修改一个聚合？

### 实体设计检查

- [ ] 是否有唯一标识？
- [ ] 是否封装了业务行为（不只是数据）？
- [ ] 是否通过方法而非 setter 修改状态？
- [ ] 是否在修改时发布领域事件？

### 值对象设计检查

- [ ] 是否真正不可变？
- [ ] 是否通过值判断相等？
- [ ] 是否替换而非修改？

### 分层检查

- [ ] 领域层是否不依赖技术框架？
- [ ] 应用层是否不包含业务规则？
- [ ] 基础设施层是否只实现领域层定义的接口？
- [ ] 用户界面层是否只做格式转换？

---

## 八、常见反模式

| 反模式 | 问题 | 正确做法 |
|-------|------|---------|
| 贫血模型 | 实体只有 getter/setter | 实体封装业务行为 |
| 聚合过大 | 性能差、并发冲突 | 最小化聚合，只包含必要对象 |
| 跨聚合引用 | 事务边界混乱 | 通过 ID 引用 |
| 领域层依赖框架 | 难以测试、复用 | 领域层保持纯净 |
| 应用层包含业务规则 | 违反分层原则 | 业务规则下沉到领域层 |
| 忽视值对象 | 代码冗余 | 用值对象封装概念完整性 |
```

### naming.md

```markdown
# 命名约定

> 定义项目的命名规范，遵循 DDD 最佳实践。

---

## 一、领域层命名

### 实体与值对象

| 类型 | 规范 | 示例 |
|-----|------|------|
| 实体 | PascalCase（业务名词） | `User`, `Order`, `Product` |
| 值对象 | PascalCase（描述性名词） | `Money`, `Address`, `DateRange` |
| 聚合根 | PascalCase（与聚合同名） | `Order`（订单聚合根） |

### 仓储接口

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}Repository | `OrderRepository` | 接口定义在领域层 |

```typescript
// 领域层定义
interface OrderRepository {
  findById(id: OrderId): Promise<Order | null>;
  save(order: Order): Promise<void>;
  delete(order: Order): Promise<void>;
}
```

### 领域服务

| 规范 | 示例 | 说明 |
|------|------|------|
| {业务动作}DomainService | `PaymentDomainService` | 跨聚合的业务逻辑 |

### 领域事件

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}{过去式动词}Event | `OrderCreatedEvent` | 表达业务状态变更 |

常用过去式动词：`Created`, `Updated`, `Deleted`, `Completed`, `Cancelled`, `Reserved`, `Released`

---

## 二、应用层命名

### 应用服务

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}ApplicationService | `OrderApplicationService` | 编排用例 |

### 命令（Command）

| 规范 | 示例 | 说明 |
|------|------|------|
| {动词}{聚合名}Command | `CreateOrderCommand` | 写操作参数 |
| {动词}{聚合名}Command | `UpdateOrderCommand` | 写操作参数 |

常用动词：`Create`, `Update`, `Delete`, `Confirm`, `Cancel`, `Submit`

### 查询（Query）

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}By{条件}Query | `OrderByIdQuery` | 读操作参数 |
| {聚合名}ListQuery | `OrderListQuery` | 列表查询 |

### 事件处理器

| 规范 | 示例 | 说明 |
|------|------|------|
| {事件名}Handler | `OrderCreatedEventHandler` | 处理领域事件 |

---

## 三、用户界面层命名

### Controller

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}Controller | `OrderController` | REST API 入口 |

### DTO

| 类型 | 规范 | 示例 |
|-----|------|------|
| 请求 DTO | {动作}{聚合名}Request | `CreateOrderRequest` |
| 响应 DTO | {聚合名}Response | `OrderResponse` |
| 列表响应 | {聚合名}ListResponse | `OrderListResponse` |

### Assembler

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}Assembler | `OrderAssembler` | DTO 与领域对象转换 |

---

## 四、基础设施层命名

### 仓储实现

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}RepositoryImpl | `OrderRepositoryImpl` | 实现领域层接口 |

### 持久化对象（PO）

| 规范 | 示例 | 说明 |
|------|------|------|
| {聚合名}PO | `OrderPO` | 数据库映射对象 |

### 外部服务适配器

| 规范 | 示例 | 说明 |
|------|------|------|
| {服务名}Adapter | `PaymentGatewayAdapter` | 外部服务封装 |

---

## 五、文件命名规范

### 领域层文件

| 类型 | 规范 | 示例 |
|-----|------|------|
| 实体 | {EntityName}.ts | `Order.ts` |
| 值对象 | {ValueObjectName}.ts | `Money.ts` |
| 仓储接口 | {AggregateName}Repository.ts | `OrderRepository.ts` |
| 领域服务 | {ServiceName}.ts | `PaymentDomainService.ts` |
| 领域事件 | {EventName}.ts | `OrderCreatedEvent.ts` |

### 应用层文件

| 类型 | 规范 | 示例 |
|-----|------|------|
| 应用服务 | {AggregateName}ApplicationService.ts | `OrderApplicationService.ts` |
| 命令 | {CommandName}.ts | `CreateOrderCommand.ts` |
| 查询 | {QueryName}.ts | `OrderByIdQuery.ts` |
| 事件处理器 | {EventName}Handler.ts | `OrderCreatedEventHandler.ts` |

### 用户界面层文件

| 类型 | 规范 | 示例 |
|-----|------|------|
| Controller | {AggregateName}Controller.ts | `OrderController.ts` |
| DTO | {DTOName}.ts | `CreateOrderRequest.ts` |
| Assembler | {AggregateName}Assembler.ts | `OrderAssembler.ts` |

### 基础设施层文件

| 类型 | 规范 | 示例 |
|-----|------|------|
| 仓储实现 | {AggregateName}RepositoryImpl.ts | `OrderRepositoryImpl.ts` |
| PO | {AggregateName}PO.ts | `OrderPO.ts` |
| Mapper | {AggregateName}Mapper.ts | `OrderMapper.ts` |

---

## 六、变量命名规范

### 领域对象变量

| 类型 | 规范 | 示例 |
|-----|------|------|
| 实体变量 | 业务名词 | `order`, `customer` |
| 值对象变量 | 描述性名词 | `money`, `address` |
| ID 类型 | 名词 + Id | `orderId`, `customerId` |

### 集合变量

| 类型 | 规范 | 示例 |
|-----|------|------|
| 列表 | 复数形式 | `orders`, `items` |
| Map | 名词 + Map | `orderMap`, `productMap` |

---

## 七、方法命名规范

### 实体方法

| 类型 | 规范 | 示例 |
|-----|------|------|
| 业务行为 | 动词 + 名词 | `addItem()`, `calculateTotal()` |
| 状态变更 | set + 状态 | `setAsCompleted()`, `setAsCancelled()` |
| 查询 | is/has/can + 形容词 | `isCompleted()`, `hasItems()` |

### 仓储方法

| 类型 | 规范 | 示例 |
|-----|------|------|
| 单条查询 | findBy + 条件 | `findById()`, `findByOrderNo()` |
| 列表查询 | findAll + 条件 | `findAllByCustomerId()` |
| 保存 | save | `save(order)` |
| 删除 | delete | `delete(order)` |

### 应用服务方法

| 类型 | 规范 | 示例 |
|-----|------|------|
| 命令处理 | handle + Command | `handleCreateOrder()` |
| 查询处理 | handle + Query | `handleOrderByIdQuery()` |
```

### framework.md

```markdown
# 框架使用模板

> 定义项目使用的框架及其使用模板。

## 框架信息

- **框架名称**：[待填写]
- **版本**：[待填写]
- **文档链接**：[待填写]

---

## 项目结构模板

[待填写：基于该框架的标准项目结构]

```
src/
├── [待填写]
└── [待填写]
```

---

## 核心组件模板

### 组件/模块模板

```
[待填写：框架特定的组件或模块代码模板]
```

### 配置模板

```
[待填写：框架配置文件模板]
```

### 依赖注入模板

```
[待填写：依赖注入或服务注册模板]
```

---

## 最佳实践

[待填写：框架特定的最佳实践和注意事项]
```

### api.md

```markdown
# API 开发模板

> 定义项目的 API 开发规范和模板。

## API 设计原则

- RESTful 风格
- 统一响应格式
- 完善的错误处理
- 版本控制

---

## 路由命名

| 操作 | HTTP 方法 | 路径 | 示例 |
|-----|----------|------|------|
| 列表 | GET | /resources | GET /users |
| 详情 | GET | /resources/:id | GET /users/123 |
| 创建 | POST | /resources | POST /users |
| 更新 | PUT/PATCH | /resources/:id | PUT /users/123 |
| 删除 | DELETE | /resources/:id | DELETE /users/123 |

---

## 响应格式模板

### 成功响应

```json
{
  "success": true,
  "data": {},
  "meta": {
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### 分页响应

```json
{
  "success": true,
  "data": [],
  "meta": {
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "totalPages": 5
  }
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "请求参数验证失败",
    "details": []
  }
}
```

---

## Controller 模板

```
[待填写：项目特定的 Controller 代码模板]
```

## Service 模板

```
[待填写：项目特定的 Service 代码模板]
```

## 中间件模板

```
[待填写：项目特定的中间件代码模板]
```

---

## 错误码定义

| 错误码 | HTTP 状态码 | 描述 |
|-------|------------|------|
| VALIDATION_ERROR | 400 | 请求参数验证失败 |
| UNAUTHORIZED | 401 | 未授权 |
| FORBIDDEN | 403 | 禁止访问 |
| NOT_FOUND | 404 | 资源不存在 |
| INTERNAL_ERROR | 500 | 服务器内部错误 |

[待填写：项目特定的错误码]
```

---

## 渐进式扩展规范

### 新建规则文件时的步骤

1. 在 `.claude/rules/local/` 目录创建规则文件
2. 使用规则文件模板编写规则
3. 在 `CLAUDE.md` 中引用该规则

### 规则文件模板

```markdown
# [规则名称]

> 一句话描述本规则的用途。

## 核心规则

1. **[规则1]**：[具体描述]
2. **[规则2]**：[具体描述]

## 示例

### 正确示例

[代码或描述]

### 错误示例

[代码或描述]

## 适用范围

[描述本规则适用的文件、目录或场景]
```

### 规则文件写作规则

- **专注单一主题**：每个文件只描述一类规则
- **提供示例**：正确/错误示例对比，便于理解
- **明确适用范围**：说明规则适用的场景
- **保持精简**：每个规则文件不超过 150 行

---

## 实现细节

### 写入顺序

1. 写入 `CLAUDE.md`
2. 创建 `.claude/rules/local/` 目录
3. 写入 `ddd-design.md`
4. 写入 `naming.md`
5. 写入 `framework.md`
6. 写入 `api.md`

### 文件保护

- 已存在的文件不覆盖（`CLAUDE.md` 除外，由用户决定）
- 创建完成后，输出需要人工填写的占位内容列表

### 错误处理

- 捕获文件写入异常，显示友好错误消息
- 确保操作原子性：全部成功或全部回滚

---

## 与 init-claude-md 的对比

| 特性 | init-claude-md | init-claude-md-v2 |
|------|----------------|-------------------|
| 入口文件大小 | <100 行 | ~150 行 |
| 规则文件 | 无预置 | 4 个预置规则文件 |
| 架构模式 | 无特定要求 | DDD 架构 |
| 设计引导 | 无 | DDD 思考流程 |
| 代码模板 | 无 | 按主题拆分（框架、API） |
| 多语言支持 | 无 | references 目录 |
| 适用场景 | 通用项目 | DDD 架构项目 |

---

## 示例输出

执行成功后显示：

```
✓ CLAUDE.md 已创建
✓ .claude/rules/local/ 目录已创建
✓ ddd-design.md 已创建
✓ naming.md 已创建
✓ framework.md 已创建
✓ api.md 已创建

请填写以下占位内容：
- 项目概述
- 技术栈
- 限界上下文
- 构建命令
- 注意事项
- framework.md 中的框架模板
- api.md 中的代码模板

已包含的规则文件：
- ddd-design.md      # DDD 设计指南
- naming.md          # 命名约定
- framework.md       # 框架使用模板
- api.md             # API 开发模板

多语言代码模型参考（见 references/ 目录）：
- go.md              # Go 语言代码模型
- typescript.md      # TypeScript 代码模型
- python.md          # Python 代码模型
- java.md            # Java 代码模型

提示：CLAUDE.md 会被 Claude Code 自动读取，保持精简（~150 行）。
详细规范在 .claude/rules/local/ 目录下。
```
