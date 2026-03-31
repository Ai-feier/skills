# Go 语言 DDD 代码模型

> 参考：webook 项目 (github.com/ecodeclub/webook)

---

## 目录结构

```
project/
├── main.go                         # 应用入口
├── go.mod
├── config/                         # 配置文件
├── api/                            # API 定义（protobuf/openapi）
│
├── internal/                       # 内部实现（不对外暴露）
│   ├── pkg/                        # 内部共享包
│   │   ├── errs/                   # 错误码定义
│   │   └── sequencenumber/         # 序列号生成器
│   │
│   └── {module}/                   # 业务模块（如 order、user、payment）
│       ├── module.go               # 模块入口（依赖注入）
│       ├── wire.go                 # Wire 依赖注入定义
│       ├── wire_gen.go             # Wire 生成代码
│       ├── mocks/                  # Mock 文件（测试用）
│       │
│       └── internal/               # 模块内部
│           ├── domain/             # 领域层
│           │   └── {entity}.go     # 实体、值对象、聚合
│           │
│           ├── service/            # 应用层服务
│           │   └── service.go      # 用例编排
│           │
│           ├── repository/         # 仓储层
│           │   ├── repository.go   # 仓储接口实现
│           │   └── dao/            # 数据访问对象
│           │       ├── init.go     # DAO 初始化
│           │       └── {entity}.go # 数据库操作
│           │
│           ├── web/                # 用户界面层
│           │   ├── handler.go      # HTTP 处理器
│           │   ├── vo.go           # 视图对象（请求/响应）
│           │   └── result.go       # 统一响应格式
│           │
│           ├── event/              # 领域事件
│           │   ├── event.go        # 事件定义
│           │   ├── producer.go     # 事件生产者
│           │   └── consumer.go     # 事件消费者
│           │
│           ├── job/                # 定时任务
│           │   └── {job}.go
│           │
│           ├── errs/               # 模块错误码
│           │   └── code.go
│           │
│           └── integration/        # 集成测试
│               └── module_test.go
│
└── ioc/                            # 依赖注入容器
    ├── db.go                       # 数据库连接
    ├── redis.go                    # Redis 连接
    ├── mq.go                       # 消息队列
    ├── gin.go                      # HTTP 路由
    └── wire.go                     # 全局 Wire 配置
```

---

## 各层代码示例

### 领域层 (domain)

```go
// internal/order/internal/domain/order.go
package domain

// OrderStatus 订单状态（值对象）
type OrderStatus uint8

const (
    StatusInit          OrderStatus = 1
    StatusProcessing    OrderStatus = 2
    StatusSuccess       OrderStatus = 3
    StatusFailed        OrderStatus = 4
    StatusCanceled      OrderStatus = 5
)

func (s OrderStatus) ToUint8() uint8 {
    return uint8(s)
}

// Order 订单聚合根
type Order struct {
    ID               int64
    SN               string
    BuyerID          int64
    Payment          Payment
    OriginalTotalAmt int64
    RealTotalAmt     int64
    Status           OrderStatus
    Items            []OrderItem
    Ctime            int64
    Utime            int64
}

// Payment 支付信息（值对象）
type Payment struct {
    ID int64
    SN string
}

// OrderItem 订单项（实体）
type OrderItem struct {
    SPU SPU
    SKU SKU
}

// SPU 标准产品单元
type SPU struct {
    ID        int64
    Category0 string
    Category1 string
}

// SKU 库存单元
type SKU struct {
    ID            int64
    SN            string
    Name          string
    Image         string
    OriginalPrice int64
    RealPrice     int64
    Quantity      int64
}
```

---

### 应用层服务 (service)

```go
// internal/order/internal/service/service.go
package service

import (
    "context"
    "github.com/ecodeclub/webook/internal/order/internal/domain"
    "github.com/ecodeclub/webook/internal/order/internal/repository"
)

// Service 应用服务接口
//go:generate mockgen -source=./service.go -package=ordermocks -destination=../../mocks/order.mock.go -typed Service
type Service interface {
    // CreateOrder 创建订单（web 调用）
    CreateOrder(ctx context.Context, order domain.Order) (domain.Order, error)
    // FindUserVisibleOrdersByUID 分页查询用户订单（web 调用）
    FindUserVisibleOrdersByUID(ctx context.Context, uid int64, offset, limit int) ([]domain.Order, int64, error)
    // CancelOrder 取消订单（web 调用）
    CancelOrder(ctx context.Context, uid, oid int64) error
    // SucceedOrder 订单支付成功（event 调用）
    SucceedOrder(ctx context.Context, uid int64, orderSN string) error
    // FindTimeoutOrders 查询超时订单（job 调用）
    FindTimeoutOrders(ctx context.Context, offset, limit int, ctime int64) ([]domain.Order, int64, error)
}

// service 应用服务实现
type service struct {
    repo repository.OrderRepository
}

func NewService(repo repository.OrderRepository) Service {
    return &service{repo: repo}
}

func (s *service) CreateOrder(ctx context.Context, order domain.Order) (domain.Order, error) {
    return s.repo.CreateOrder(ctx, order)
}

func (s *service) CancelOrder(ctx context.Context, uid, oid int64) error {
    return s.repo.CancelOrder(ctx, uid, oid)
}
```

---

### 仓储层 (repository)

```go
// internal/order/internal/repository/repository.go
package repository

import (
    "context"
    "github.com/ecodeclub/webook/internal/order/internal/domain"
    "github.com/ecodeclub/webook/internal/order/internal/repository/dao"
)

// OrderRepository 仓储接口
type OrderRepository interface {
    CreateOrder(ctx context.Context, order domain.Order) (domain.Order, error)
    FindUserVisibleOrderByUIDAndSN(ctx context.Context, uid int64, sn string) (domain.Order, error)
    FindUserVisibleOrdersByUID(ctx context.Context, uid int64, offset, limit int) ([]domain.Order, error)
    CancelOrder(ctx context.Context, uid, oid int64) error
    SucceedOrder(ctx context.Context, uid int64, orderSN string) error
}

// orderRepository 仓储实现
type orderRepository struct {
    dao dao.OrderDAO
}

func NewRepository(d dao.OrderDAO) OrderRepository {
    return &orderRepository{dao: d}
}

func (r *orderRepository) CreateOrder(ctx context.Context, order domain.Order) (domain.Order, error) {
    oid, err := r.dao.CreateOrder(ctx, r.toOrderEntity(order), r.toOrderItemEntities(order.Items))
    if err != nil {
        return domain.Order{}, err
    }
    order.ID = oid
    return order, nil
}

// toOrderEntity 领域对象转持久化对象
func (r *orderRepository) toOrderEntity(order domain.Order) dao.Order {
    return dao.Order{
        Id:               order.ID,
        SN:               order.SN,
        BuyerId:          order.BuyerID,
        OriginalTotalAmt: order.OriginalTotalAmt,
        RealTotalAmt:     order.RealTotalAmt,
        Status:           order.Status.ToUint8(),
    }
}

// toOrderDomain 持久化对象转领域对象
func (r *orderRepository) toOrderDomain(order dao.Order, items []dao.OrderItem) domain.Order {
    return domain.Order{
        ID:      order.Id,
        SN:      order.SN,
        BuyerID: order.BuyerId,
        Status:  domain.OrderStatus(order.Status),
        // ... 其他字段转换
    }
}
```

---

### DAO 层 (dao)

```go
// internal/order/internal/repository/dao/order.go
package dao

import (
    "context"
    "gorm.io/gorm"
    "database/sql"
)

// Order 订单持久化对象
type Order struct {
    Id               int64          `gorm:"primaryKey,autoIncrement"`
    SN               string         `gorm:"uniqueIndex"`
    BuyerId          int64          `gorm:"index"`
    PaymentId        sql.NullInt64
    PaymentSn        sql.NullString
    OriginalTotalAmt int64
    RealTotalAmt     int64
    Status           uint8          `gorm:"index"`
    Ctime            int64
    Utime            int64
}

func (Order) TableName() string {
    return "orders"
}

// OrderItem 订单项持久化对象
type OrderItem struct {
    Id              int64 `gorm:"primaryKey,autoIncrement"`
    OrderId         int64 `gorm:"index"`
    SPUId           int64
    SKUId           int64
    SKUSN           string
    SKUName         string
    Quantity        int64
}

func (OrderItem) TableName() string {
    return "order_items"
}

// OrderDAO 数据访问接口
type OrderDAO interface {
    CreateOrder(ctx context.Context, order Order, items []OrderItem) (int64, error)
    FindOrderByUIDAndSN(ctx context.Context, uid int64, sn string) (Order, error)
    FindOrdersByUID(ctx context.Context, offset, limit int, uid int64, status uint8) ([]Order, error)
    SetOrderCanceled(ctx context.Context, uid, oid int64) error
}

// orderDAOImpl DAO 实现
type orderDAOImpl struct {
    db *gorm.DB
}

func NewOrderDAO(db *gorm.DB) OrderDAO {
    return &orderDAOImpl{db: db}
}

func (d *orderDAOImpl) CreateOrder(ctx context.Context, order Order, items []OrderItem) (int64, error) {
    err := d.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
        if err := tx.Create(&order).Error; err != nil {
            return err
        }
        for i := range items {
            items[i].OrderId = order.Id
        }
        return tx.Create(&items).Error
    })
    return order.Id, err
}
```

---

### 用户界面层 (web)

```go
// internal/order/internal/web/handler.go
package web

import (
    "github.com/ecodeclub/ginx"
    "github.com/ecodeclub/webook/internal/order/internal/domain"
    "github.com/ecodeclub/webook/internal/order/internal/service"
    "github.com/gin-gonic/gin"
)

// Handler HTTP 处理器
var _ ginx.Handler = &Handler{}

type Handler struct {
    svc         service.Service
    productSvc  product.Service
    snGenerator *sequencenumber.Generator
}

func NewHandler(svc service.Service, productSvc product.Service, snGenerator *sequencenumber.Generator) *Handler {
    return &Handler{svc: svc, productSvc: productSvc, snGenerator: snGenerator}
}

// PrivateRoutes 私有路由（需登录）
func (h *Handler) PrivateRoutes(server *gin.Engine) {
    g := server.Group("/order")
    g.POST("/preview", ginx.BS[PreviewOrderReq](h.PreviewOrder))
    g.POST("/create", ginx.BS[CreateOrderReq](h.CreateOrder))
    g.POST("/list", ginx.BS[ListOrdersReq](h.ListOrders))
    g.POST("/detail", ginx.BS[OrderSNReq](h.RetrieveOrderDetail))
    g.POST("/cancel", ginx.BS[OrderSNReq](h.CancelOrder))
}

// PublicRoutes 公开路由
func (h *Handler) PublicRoutes(_ *gin.Engine) {}

// CreateOrder 创建订单
func (h *Handler) CreateOrder(ctx *ginx.Context, req CreateOrderReq, sess session.Session) (ginx.Result, error) {
    uid := sess.Claims().Uid
    order, err := h.createOrder(ctx, req.SKUs, uid)
    if err != nil {
        return systemErrorResult, err
    }
    return ginx.Result{Data: CreateOrderResp{SN: order.SN}}, nil
}

// ListOrders 查询订单列表
func (h *Handler) ListOrders(ctx *ginx.Context, req ListOrdersReq, sess session.Session) (ginx.Result, error) {
    orders, total, err := h.svc.FindUserVisibleOrdersByUID(ctx, sess.Claims().Uid, req.Offset, req.Limit)
    if err != nil {
        return systemErrorResult, err
    }
    return ginx.Result{
        Data: ListOrdersResp{
            Total:  total,
            Orders: slice.Map(orders, toOrderVO),
        },
    }, nil
}
```

```go
// internal/order/internal/web/vo.go
package web

// 请求对象

type CreateOrderReq struct {
    RequestID     string        `json:"requestId"`
    SKUs          []SKU         `json:"skus"`
    PaymentItems  []PaymentItem `json:"paymentItems"`
}

type SKU struct {
    SN       string `json:"sn"`
    Quantity int64  `json:"quantity"`
}

type ListOrdersReq struct {
    Offset int `json:"offset"`
    Limit  int `json:"limit"`
}

type OrderSNReq struct {
    SN string `json:"sn"`
}

// 响应对象

type CreateOrderResp struct {
    SN            string `json:"sn"`
    WechatCodeURL string `json:"wechatCodeURL,omitempty"`
}

type ListOrdersResp struct {
    Total  int64   `json:"total"`
    Orders []Order `json:"orders"`
}

type Order struct {
    SN               string      `json:"sn"`
    OriginalTotalAmt int64       `json:"originalTotalAmt"`
    RealTotalAmt     int64       `json:"realTotalAmt"`
    Status           uint8       `json:"status"`
    Items            []OrderItem `json:"items"`
    Ctime            int64       `json:"ctime"`
}
```

---

### 领域事件 (event)

```go
// internal/order/internal/event/event.go
package event

const (
    EventOrderCreated = "order.created"
    EventOrderPaid    = "order.paid"
    EventOrderCanceled = "order.canceled"
)

// OrderEvent 订单事件
type OrderEvent struct {
    OID    int64  `json:"oid"`
    SN     string `json:"sn"`
    UID    int64  `json:"uid"`
    Status uint8  `json:"status"`
}
```

```go
// internal/order/internal/event/producer.go
package event

import "context"

// Producer 事件生产者
type Producer interface {
    ProduceOrderCreatedEvent(ctx context.Context, evt OrderEvent) error
    ProduceOrderPaidEvent(ctx context.Context, evt OrderEvent) error
}
```

```go
// internal/order/internal/event/consumer.go
package event

import "context"

// Consumer 事件消费者
type Consumer interface {
    ConsumePaymentEvents(ctx context.Context) error
}
```

---

### 模块入口 (module.go)

```go
// internal/order/module.go
package order

import (
    "github.com/ecodeclub/webook/internal/order/internal/repository"
    "github.com/ecodeclub/webook/internal/order/internal/repository/dao"
    "github.com/ecodeclub/webook/internal/order/internal/service"
    "github.com/ecodeclub/webook/internal/order/internal/web"
    "gorm.io/gorm"
)

type Module struct {
    Handler *web.Handler
    Service service.Service
}

func InitModule(db *gorm.DB, productSvc product.Service, snGenerator *sequencenumber.Generator) *Module {
    // 初始化 DAO
    orderDAO := dao.NewOrderDAO(db)

    // 初始化 Repository
    orderRepo := repository.NewRepository(orderDAO)

    // 初始化 Service
    orderSvc := service.NewService(orderRepo)

    // 初始化 Handler
    handler := web.NewHandler(orderSvc, productSvc, snGenerator)

    return &Module{
        Handler: handler,
        Service: orderSvc,
    }
}
```

---

## 关键设计要点

### 模块组织

- **按业务领域划分**：一个限界上下文对应一个模块目录
- **internal 双层嵌套**：外层暴露模块接口，内层隐藏实现细节
- **依赖注入**：使用 Wire 管理依赖

### 分层职责

| 层级 | 目录 | 职责 |
|-----|------|------|
| 用户界面层 | web/ | HTTP 处理、请求响应转换 |
| 应用层 | service/ | 用例编排、事务管理 |
| 领域层 | domain/ | 业务规则、领域对象 |
| 仓储层 | repository/ | 数据访问抽象 |
| 基础设施层 | dao/、event/ | 数据库操作、消息队列 |

### 对象转换

```
HTTP Request → VO → Service → Domain Object → DAO → Database
                              ↓
                         Event → MQ
```

### 测试策略

- **单元测试**：领域层业务逻辑
- **集成测试**：repository 层与数据库交互
- **Mock**：使用 mockgen 生成 Mock 对象
