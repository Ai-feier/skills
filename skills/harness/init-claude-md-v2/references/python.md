# Python DDD 代码模型

> 适用于 FastAPI、Django、Flask 等框架

---

## 目录结构

```
src/
├── main.py                         # 应用入口
├── config.py                       # 配置
│
├── modules/                        # 业务模块
│   └── {module}/                   # 模块目录（如 order、user）
│       ├── domain/                 # 领域层
│       │   ├── __init__.py
│       │   ├── entities.py         # 实体
│       │   ├── value_objects.py    # 值对象
│       │   ├── aggregates.py       # 聚合根
│       │   ├── repositories.py     # 仓储接口
│       │   └── events.py           # 领域事件
│       │
│       ├── application/            # 应用层
│       │   ├── __init__.py
│       │   ├── services.py         # 应用服务
│       │   ├── commands.py         # 命令
│       │   └── queries.py          # 查询
│       │
│       ├── infrastructure/         # 基础设施层
│       │   ├── __init__.py
│       │   ├── persistence/        # 持久化
│       │   │   ├── __init__.py
│       │   │   ├── models.py       # ORM 模型
│       │   │   ├── repositories.py # 仓储实现
│       │   │   └── mappers.py      # 对象映射
│       │   ├── messaging/          # 消息队列
│       │   └── external/           # 外部服务
│       │
│       ├── interfaces/             # 用户界面层
│       │   ├── __init__.py
│       │   ├── api/                # API 接口
│       │   │   ├── __init__.py
│       │   │   ├── routes.py       # 路由
│       │   │   ├── schemas.py      # Pydantic 模型
│       │   │   └── dependencies.py # 依赖注入
│       │   └── grpc/               # gRPC（可选）
│       │
│       └── __init__.py
│
├── shared/                         # 共享内核
│   ├── __init__.py
│   ├── domain/                     # 领域基类
│   │   ├── __init__.py
│   │   ├── entity.py
│   │   ├── value_object.py
│   │   └── aggregate_root.py
│   └── infrastructure/             # 基础设施
│       ├── __init__.py
│       └── event_bus.py
│
└── tests/                          # 测试
    ├── unit/
    ├── integration/
    └── e2e/
```

---

## 各层代码示例

### 共享内核

```python
# shared/domain/entity.py
from abc import ABC
from typing import TypeVar, Generic
from dataclasses import dataclass

T = TypeVar('T')

@dataclass
class Entity(ABC, Generic[T]):
    """实体基类"""
    _id: T

    @property
    def id(self) -> T:
        return self._id

    def __eq__(self, other) -> bool:
        if not isinstance(other, self.__class__):
            return False
        return self._id == other._id

    def __hash__(self) -> int:
        return hash(self._id)
```

```python
# shared/domain/value_object.py
from abc import ABC
from dataclasses import dataclass
from typing import Any

@dataclass(frozen=True)
class ValueObject(ABC):
    """值对象基类 - 不可变"""

    def __eq__(self, other) -> bool:
        if not isinstance(other, self.__class__):
            return False
        return self.__dict__ == other.__dict__

    def __hash__(self) -> int:
        return hash(tuple(sorted(self.__dict__.items())))
```

```python
# shared/domain/aggregate_root.py
from typing import List, Any
from .entity import Entity

class AggregateRoot(Entity):
    """聚合根基类"""

    def __init__(self, id):
        super().__init__(id)
        self._domain_events: List[Any] = []

    def _add_domain_event(self, event: Any) -> None:
        self._domain_events.append(event)

    @property
    def domain_events(self) -> List[Any]:
        return list(self._domain_events)

    def clear_domain_events(self) -> None:
        self._domain_events.clear()
```

---

### 领域层

```python
# modules/order/domain/value_objects.py
from dataclasses import dataclass
from shared.domain.value_object import ValueObject
from decimal import Decimal

@dataclass(frozen=True)
class OrderId(ValueObject):
    """订单ID值对象"""
    value: str

    @classmethod
    def generate(cls) -> 'OrderId':
        import uuid
        return cls(str(uuid.uuid4()))

    @classmethod
    def from_string(cls, value: str) -> 'OrderId':
        return cls(value)


@dataclass(frozen=True)
class Money(ValueObject):
    """金额值对象"""
    amount: Decimal
    currency: str = "CNY"

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("金额不能为负数")

    def add(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("币种不同，无法相加")
        return Money(self.amount + other.amount, self.currency)

    def multiply(self, factor: int) -> 'Money':
        return Money(self.amount * factor, self.currency)


@dataclass(frozen=True)
class OrderItem(ValueObject):
    """订单项值对象"""
    sku_id: int
    sku_name: str
    quantity: int
    unit_price: Money

    def __post_init__(self):
        if self.quantity <= 0:
            raise ValueError("数量必须大于0")

    @property
    def total_price(self) -> Money:
        return self.unit_price.multiply(self.quantity)
```

```python
# modules/order/domain/entities.py
from enum import IntEnum
from dataclasses import dataclass, field
from typing import List
from shared.domain.aggregate_root import AggregateRoot
from .value_objects import OrderId, OrderItem, Money

class OrderStatus(IntEnum):
    """订单状态枚举"""
    INIT = 1
    PROCESSING = 2
    SUCCESS = 3
    FAILED = 4
    CANCELED = 5


@dataclass
class Order(AggregateRoot):
    """订单聚合根"""
    sn: str
    buyer_id: int
    items: List[OrderItem] = field(default_factory=list)
    status: OrderStatus = OrderStatus.INIT
    _total_amount: Money = field(default=Money(Decimal("0")), repr=False)

    def __post_init__(self):
        super().__init__(OrderId.generate())
        self._calculate_total()

    @classmethod
    def create(cls, sn: str, buyer_id: int, items: List[OrderItem]) -> 'Order':
        """工厂方法 - 创建订单"""
        order = cls(sn=sn, buyer_id=buyer_id, items=items)
        # 发布领域事件
        from .events import OrderCreatedEvent
        order._add_domain_event(OrderCreatedEvent(order))
        return order

    @classmethod
    def reconstitute(
        cls,
        order_id: OrderId,
        sn: str,
        buyer_id: int,
        items: List[OrderItem],
        status: OrderStatus,
    ) -> 'Order':
        """重建订单（从数据库恢复）"""
        order = cls.__new__(cls)
        AggregateRoot.__init__(order, order_id)
        order.sn = sn
        order.buyer_id = buyer_id
        order.items = items
        order.status = status
        order._calculate_total()
        return order

    def cancel(self) -> None:
        """取消订单"""
        if self.status != OrderStatus.PROCESSING:
            raise ValueError("只能取消处理中的订单")
        self.status = OrderStatus.CANCELED

    def mark_as_paid(self) -> None:
        """标记为已支付"""
        if self.status != OrderStatus.PROCESSING:
            raise ValueError("只能标记处理中的订单")
        self.status = OrderStatus.SUCCESS

    def _calculate_total(self) -> None:
        """计算总金额"""
        total = Money(Decimal("0"))
        for item in self.items:
            total = total.add(item.total_price)
        self._total_amount = total

    @property
    def total_amount(self) -> Money:
        return self._total_amount

    @property
    def id(self) -> OrderId:
        return self._id
```

```python
# modules/order/domain/events.py
from dataclasses import dataclass
from typing import Any
from .entities import Order

@dataclass
class OrderCreatedEvent:
    """订单创建事件"""
    order: Order
    event_type: str = "order.created"

    @property
    def aggregate_id(self) -> str:
        return self.order.id.value

    @property
    def payload(self) -> dict:
        return {
            "order_id": self.order.id.value,
            "sn": self.order.sn,
            "buyer_id": self.order.buyer_id,
            "total_amount": str(self.order.total_amount.amount),
        }


@dataclass
class OrderPaidEvent:
    """订单支付事件"""
    order_id: str
    order_sn: str
    buyer_id: int
    event_type: str = "order.paid"
```

```python
# modules/order/domain/repositories.py
from abc import ABC, abstractmethod
from typing import List, Optional
from .entities import Order
from .value_objects import OrderId

class OrderRepository(ABC):
    """订单仓储接口"""

    @abstractmethod
    async def find_by_id(self, id: OrderId) -> Optional[Order]:
        pass

    @abstractmethod
    async def find_by_sn(self, sn: str) -> Optional[Order]:
        pass

    @abstractmethod
    async def find_by_buyer_id(
        self, buyer_id: int, offset: int, limit: int
    ) -> List[Order]:
        pass

    @abstractmethod
    async def count_by_buyer_id(self, buyer_id: int) -> int:
        pass

    @abstractmethod
    async def save(self, order: Order) -> None:
        pass

    @abstractmethod
    async def delete(self, order: Order) -> None:
        pass
```

---

### 应用层

```python
# modules/order/application/commands.py
from dataclasses import dataclass
from typing import List
from ..domain.value_objects import OrderItem

@dataclass
class CreateOrderCommand:
    """创建订单命令"""
    sn: str
    buyer_id: int
    items: List[OrderItem]


@dataclass
class CancelOrderCommand:
    """取消订单命令"""
    buyer_id: int
    order_sn: str
```

```python
# modules/order/application/queries.py
from dataclasses import dataclass

@dataclass
class OrderQuery:
    """订单查询"""
    buyer_id: int
    offset: int = 0
    limit: int = 20


@dataclass
class OrderDetailQuery:
    """订单详情查询"""
    order_sn: str
    buyer_id: int
```

```python
# modules/order/application/services.py
from typing import List, Dict, Any
from ..domain.repositories import OrderRepository
from ..domain.entities import Order
from ..domain.value_objects import OrderItem
from .commands import CreateOrderCommand, CancelOrderCommand
from .queries import OrderQuery, OrderDetailQuery

class OrderService:
    """订单应用服务"""

    def __init__(
        self,
        order_repo: OrderRepository,
        event_bus: Any,  # EventBus
    ):
        self._order_repo = order_repo
        self._event_bus = event_bus

    async def create_order(self, cmd: CreateOrderCommand) -> str:
        """创建订单"""
        order = Order.create(
            sn=cmd.sn,
            buyer_id=cmd.buyer_id,
            items=cmd.items,
        )

        await self._order_repo.save(order)

        # 发布领域事件
        for event in order.domain_events:
            await self._event_bus.publish(event)
        order.clear_domain_events()

        return order.sn

    async def cancel_order(self, cmd: CancelOrderCommand) -> None:
        """取消订单"""
        order = await self._order_repo.find_by_sn(cmd.order_sn)
        if not order:
            raise ValueError("订单不存在")
        if order.buyer_id != cmd.buyer_id:
            raise PermissionError("无权操作此订单")

        order.cancel()
        await self._order_repo.save(order)

    async def query_orders(self, query: OrderQuery) -> Dict[str, Any]:
        """查询订单列表"""
        orders = await self._order_repo.find_by_buyer_id(
            query.buyer_id, query.offset, query.limit
        )
        total = await self._order_repo.count_by_buyer_id(query.buyer_id)
        return {"total": total, "orders": orders}

    async def get_order_detail(self, query: OrderDetailQuery) -> Order:
        """获取订单详情"""
        order = await self._order_repo.find_by_sn(query.order_sn)
        if not order or order.buyer_id != query.buyer_id:
            raise ValueError("订单不存在")
        return order
```

---

### 用户界面层

```python
# modules/order/interfaces/api/schemas.py
from pydantic import BaseModel, Field
from typing import List, Optional
from decimal import Decimal

# 请求模型

class SkuInput(BaseModel):
    """SKU 输入"""
    sku_id: int
    sku_name: str
    quantity: int = Field(..., gt=0)
    unit_price: Decimal = Field(..., ge=0)


class CreateOrderRequest(BaseModel):
    """创建订单请求"""
    request_id: Optional[str] = None
    skus: List[SkuInput]
    payment_items: List[dict]


class CancelOrderRequest(BaseModel):
    """取消订单请求"""
    pass


class ListOrderQuery(BaseModel):
    """订单列表查询"""
    offset: int = Field(0, ge=0)
    limit: int = Field(20, ge=1, le=100)


# 响应模型

class OrderItemResponse(BaseModel):
    """订单项响应"""
    sku_id: int
    sku_name: str
    quantity: int
    unit_price: Decimal
    total_price: Decimal


class OrderResponse(BaseModel):
    """订单响应"""
    sn: str
    status: int
    original_total_amt: Decimal
    real_total_amt: Decimal
    items: List[OrderItemResponse]
    ctime: int


class OrderListResponse(BaseModel):
    """订单列表响应"""
    total: int
    orders: List[OrderResponse]
```

```python
# modules/order/interfaces/api/routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any

from .schemas import (
    CreateOrderRequest,
    CancelOrderRequest,
    ListOrderQuery,
    OrderResponse,
    OrderListResponse,
)
from .dependencies import get_order_service, get_current_user
from ...application.services import OrderService
from ...application.commands import CreateOrderCommand, CancelOrderCommand
from ...application.queries import OrderQuery, OrderDetailQuery

router = APIRouter(prefix="/orders", tags=["订单"])


@router.post("", response_model=Dict[str, str])
async def create_order(
    request: CreateOrderRequest,
    user: Dict = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
):
    """创建订单"""
    from ...domain.value_objects import OrderItem, Money
    from decimal import Decimal

    items = [
        OrderItem(
            sku_id=sku.sku_id,
            sku_name=sku.sku_name,
            quantity=sku.quantity,
            unit_price=Money(Decimal(str(sku.unit_price))),
        )
        for sku in request.skus
    ]

    cmd = CreateOrderCommand(
        sn=request.request_id or "",
        buyer_id=user["id"],
        items=items,
    )

    sn = await service.create_order(cmd)
    return {"sn": sn}


@router.post("/{sn}/cancel", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_order(
    sn: str,
    user: Dict = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
):
    """取消订单"""
    cmd = CancelOrderCommand(buyer_id=user["id"], order_sn=sn)
    await service.cancel_order(cmd)


@router.get("", response_model=OrderListResponse)
async def list_orders(
    query: ListOrderQuery = Depends(),
    user: Dict = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
):
    """查询订单列表"""
    result = await service.query_orders(
        OrderQuery(buyer_id=user["id"], offset=query.offset, limit=query.limit)
    )
    return _to_list_response(result)


@router.get("/{sn}", response_model=OrderResponse)
async def get_order_detail(
    sn: str,
    user: Dict = Depends(get_current_user),
    service: OrderService = Depends(get_order_service),
):
    """获取订单详情"""
    query = OrderDetailQuery(order_sn=sn, buyer_id=user["id"])
    order = await service.get_order_detail(query)
    return _to_response(order)


def _to_response(order) -> OrderResponse:
    """转换为响应模型"""
    return OrderResponse(
        sn=order.sn,
        status=order.status,
        original_total_amt=order.total_amount.amount,
        real_total_amt=order.total_amount.amount,
        items=[
            OrderItemResponse(
                sku_id=item.sku_id,
                sku_name=item.sku_name,
                quantity=item.quantity,
                unit_price=item.unit_price.amount,
                total_price=item.total_price.amount,
            )
            for item in order.items
        ],
        ctime=0,  # 需要从 order 获取
    )


def _to_list_response(result: Dict[str, Any]) -> OrderListResponse:
    """转换为列表响应"""
    return OrderListResponse(
        total=result["total"],
        orders=[_to_response(order) for order in result["orders"]],
    )
```

```python
# modules/order/interfaces/api/dependencies.py
from functools import lru_cache
from typing import Dict

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from ...application.services import OrderService
from ...infrastructure.persistence.repositories import OrderRepositoryImpl
from shared.infrastructure.event_bus import EventBus

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> Dict:
    """获取当前用户"""
    # 这里应该验证 JWT token
    # 简化示例
    token = credentials.credentials
    # ... 验证逻辑
    return {"id": 1, "username": "user"}


@lru_cache
def get_order_repository() -> OrderRepositoryImpl:
    """获取订单仓储"""
    from ...infrastructure.persistence.repositories import OrderRepositoryImpl
    return OrderRepositoryImpl()


@lru_cache
def get_event_bus() -> EventBus:
    """获取事件总线"""
    return EventBus()


def get_order_service(
    repo: OrderRepositoryImpl = Depends(get_order_repository),
    event_bus: EventBus = Depends(get_event_bus),
) -> OrderService:
    """获取订单服务"""
    return OrderService(repo, event_bus)
```

---

### 基础设施层

```python
# modules/order/infrastructure/persistence/models.py
from sqlalchemy import Column, String, Integer, BigInteger, Numeric, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class OrderModel(Base):
    """订单 ORM 模型"""
    __tablename__ = "orders"

    id = Column(String(36), primary_key=True)
    sn = Column(String(64), unique=True, nullable=False, index=True)
    buyer_id = Column(BigInteger, nullable=False, index=True)
    status = Column(Integer, nullable=False, default=1)
    total_amount = Column(Numeric(10, 2), nullable=False)
    ctime = Column(BigInteger, nullable=False)
    utime = Column(BigInteger, nullable=False)

    items = relationship("OrderItemModel", back_populates="order")


class OrderItemModel(Base):
    """订单项 ORM 模型"""
    __tablename__ = "order_items"

    id = Column(String(36), primary_key=True)
    order_id = Column(String(36), ForeignKey("orders.id"), nullable=False, index=True)
    sku_id = Column(BigInteger, nullable=False)
    sku_name = Column(String(255), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)

    order = relationship("OrderModel", back_populates="items")
```

```python
# modules/order/infrastructure/persistence/repositories.py
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..domain.repositories import OrderRepository
from ..domain.entities import Order, OrderStatus
from ..domain.value_objects import OrderId, OrderItem, Money
from .models import OrderModel, OrderItemModel
from .mappers import OrderMapper


class OrderRepositoryImpl(OrderRepository):
    """订单仓储实现"""

    def __init__(self, session: AsyncSession):
        self._session = session
        self._mapper = OrderMapper()

    async def find_by_id(self, id: OrderId) -> Optional[Order]:
        stmt = select(OrderModel).where(OrderModel.id == id.value)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._mapper.to_domain(model) if model else None

    async def find_by_sn(self, sn: str) -> Optional[Order]:
        stmt = select(OrderModel).where(OrderModel.sn == sn)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        return self._mapper.to_domain(model) if model else None

    async def find_by_buyer_id(
        self, buyer_id: int, offset: int, limit: int
    ) -> List[Order]:
        stmt = (
            select(OrderModel)
            .where(OrderModel.buyer_id == buyer_id)
            .order_by(OrderModel.ctime.desc())
            .offset(offset)
            .limit(limit)
        )
        result = await self._session.execute(stmt)
        models = result.scalars().all()
        return [self._mapper.to_domain(m) for m in models]

    async def count_by_buyer_id(self, buyer_id: int) -> int:
        from sqlalchemy import func
        stmt = select(func.count()).where(OrderModel.buyer_id == buyer_id)
        result = await self._session.execute(stmt)
        return result.scalar()

    async def save(self, order: Order) -> None:
        model = self._mapper.to_persistence(order)
        self._session.add(model)
        await self._session.commit()

    async def delete(self, order: Order) -> None:
        stmt = select(OrderModel).where(OrderModel.id == order.id.value)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()
        if model:
            await self._session.delete(model)
            await self._session.commit()
```

```python
# modules/order/infrastructure/persistence/mappers.py
from decimal import Decimal
from ..domain.entities import Order, OrderStatus
from ..domain.value_objects import OrderId, OrderItem, Money
from .models import OrderModel, OrderItemModel


class OrderMapper:
    """订单对象映射器"""

    def to_domain(self, model: OrderModel) -> Order:
        """持久化对象 -> 领域对象"""
        items = [
            OrderItem(
                sku_id=item.sku_id,
                sku_name=item.sku_name,
                quantity=item.quantity,
                unit_price=Money(Decimal(str(item.unit_price))),
            )
            for item in model.items
        ]

        return Order.reconstitute(
            order_id=OrderId(model.id),
            sn=model.sn,
            buyer_id=model.buyer_id,
            items=items,
            status=OrderStatus(model.status),
        )

    def to_persistence(self, order: Order) -> OrderModel:
        """领域对象 -> 持久化对象"""
        import uuid
        import time

        model = OrderModel(
            id=order.id.value,
            sn=order.sn,
            buyer_id=order.buyer_id,
            status=order.status,
            total_amount=order.total_amount.amount,
            ctime=int(time.time()),
            utime=int(time.time()),
        )

        model.items = [
            OrderItemModel(
                id=str(uuid.uuid4()),
                order_id=order.id.value,
                sku_id=item.sku_id,
                sku_name=item.sku_name,
                quantity=item.quantity,
                unit_price=item.unit_price.amount,
            )
            for item in order.items
        ]

        return model
```

---

### 模块注册

```python
# modules/order/__init__.py
from fastapi import APIRouter
from .interfaces.api.routes import router as order_router

def get_router() -> APIRouter:
    """获取模块路由"""
    return order_router
```

```python
# main.py
from fastapi import FastAPI
from modules.order import get_router as get_order_router

app = FastAPI(title="DDD Example")

# 注册模块路由
app.include_router(get_order_router())
```

---

## 关键设计要点

### 领域对象设计

- **Entity**：使用 `@dataclass`，有唯一标识
- **ValueObject**：使用 `@dataclass(frozen=True)`，不可变
- **AggregateRoot**：继承 Entity，管理领域事件

### 依赖注入

- 使用 FastAPI 的 `Depends` 实现依赖注入
- 使用 `@lru_cache` 缓存单例
- 领域层定义接口，基础设施层实现

### 对象转换

```
HTTP Request → Pydantic Model → Command → Domain Object → ORM Model → Database
                                    ↓
                              Domain Event → EventBus
```

### 测试策略

- **单元测试**：领域对象业务逻辑（pytest）
- **集成测试**：Repository 与数据库交互
- **E2E 测试**：API 接口测试（TestClient）
