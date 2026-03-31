# TypeScript/Node.js DDD 代码模型

> 适用于 NestJS、Express 等框架

---

## 目录结构

```
src/
├── modules/                        # 业务模块
│   └── {module}/                   # 模块目录（如 order、user）
│       ├── domain/                 # 领域层
│       │   ├── {Entity}.ts         # 实体
│       │   ├── {ValueObject}.ts    # 值对象
│       │   ├── {Aggregate}.ts      # 聚合根
│       │   └── {Aggregate}Repository.ts  # 仓储接口
│       │
│       ├── application/            # 应用层
│       │   ├── {Module}Service.ts  # 应用服务
│       │   ├── commands/           # 命令
│       │   │   └── Create{Entity}Command.ts
│       │   └── queries/            # 查询
│       │       └── {Entity}Query.ts
│       │
│       ├── infrastructure/         # 基础设施层
│       │   ├── persistence/        # 持久化
│       │   │   ├── {Entity}RepositoryImpl.ts
│       │   │   ├── {Entity}ORM.ts  # ORM 实体
│       │   │   └── {Entity}Mapper.ts
│       │   ├── messaging/          # 消息队列
│       │   └── external/           # 外部服务
│       │
│       ├── interfaces/             # 用户界面层
│       │   ├── http/               # HTTP 接口
│       │   │   ├── {Entity}Controller.ts
│       │   │   ├── {Entity}DTO.ts
│       │   │   └── {Entity}Assembler.ts
│       │   └── graphql/            # GraphQL（可选）
│       │
│       └── {Module}Module.ts       # 模块定义（NestJS）
│
├── shared/                         # 共享内核
│   ├── domain/                     # 领域基类
│   │   ├── Entity.ts
│   │   ├── ValueObject.ts
│   │   └── AggregateRoot.ts
│   └── infrastructure/             # 基础设施
│       └── EventBus.ts
│
└── main.ts                         # 应用入口
```

---

## 各层代码示例

### 共享内核

```typescript
// shared/domain/Entity.ts
export abstract class Entity<T> {
    protected readonly _id: T;

    constructor(id: T) {
        this._id = id;
    }

    get id(): T {
        return this._id;
    }

    equals(other?: Entity<T>): boolean {
        if (!other || !(other instanceof this.constructor)) {
            return false;
        }
        return this._id === other._id;
    }
}
```

```typescript
// shared/domain/ValueObject.ts
export abstract class ValueObject {
    abstract get value(): unknown;

    equals(other?: ValueObject): boolean {
        if (!other || !(other instanceof this.constructor)) {
            return false;
        }
        return JSON.stringify(this.value) === JSON.stringify(other.value);
    }
}
```

```typescript
// shared/domain/AggregateRoot.ts
import { Entity } from './Entity';

export abstract class AggregateRoot<T> extends Entity<T> {
    private _domainEvents: unknown[] = [];

    protected addDomainEvent(event: unknown): void {
        this._domainEvents.push(event);
    }

    get domainEvents(): unknown[] {
        return [...this._domainEvents];
    }

    clearDomainEvents(): void {
        this._domainEvents = [];
    }
}
```

---

### 领域层

```typescript
// modules/order/domain/OrderId.ts
import { ValueObject } from '@/shared/domain/ValueObject';

export class OrderId extends ValueObject {
    private constructor(private readonly _value: string) {
        super();
    }

    static generate(): OrderId {
        return new OrderId(crypto.randomUUID());
    }

    static fromString(value: string): OrderId {
        return new OrderId(value);
    }

    get value(): string {
        return this._value;
    }
}
```

```typescript
// modules/order/domain/Order.ts
import { AggregateRoot } from '@/shared/domain/AggregateRoot';
import { OrderId } from './OrderId';
import { OrderItem } from './OrderItem';
import { OrderCreatedEvent } from './events/OrderCreatedEvent';

export enum OrderStatus {
    INIT = 1,
    PROCESSING = 2,
    SUCCESS = 3,
    FAILED = 4,
    CANCELED = 5,
}

export class Order extends AggregateRoot<OrderId> {
    private _sn: string;
    private _buyerId: number;
    private _items: OrderItem[];
    private _status: OrderStatus;
    private _totalAmount: number;

    private constructor(id: OrderId, sn: string, buyerId: number) {
        super(id);
        this._sn = sn;
        this._buyerId = buyerId;
        this._status = OrderStatus.INIT;
        this._items = [];
    }

    // 工厂方法
    static create(sn: string, buyerId: number, items: OrderItem[]): Order {
        const id = OrderId.generate();
        const order = new Order(id, sn, buyerId);
        order._items = items;
        order._totalAmount = items.reduce((sum, item) => sum + item.totalPrice, 0);

        // 发布领域事件
        order.addDomainEvent(new OrderCreatedEvent(order));
        return order;
    }

    // 重建（从数据库恢复）
    static reconstitute(
        id: OrderId,
        sn: string,
        buyerId: number,
        items: OrderItem[],
        status: OrderStatus,
    ): Order {
        const order = new Order(id, sn, buyerId);
        order._items = items;
        order._status = status;
        order._totalAmount = items.reduce((sum, item) => sum + item.totalPrice, 0);
        return order;
    }

    // 业务方法
    cancel(): void {
        if (this._status !== OrderStatus.PROCESSING) {
            throw new Error('只能取消处理中的订单');
        }
        this._status = OrderStatus.CANCELED;
    }

    markAsPaid(): void {
        if (this._status !== OrderStatus.PROCESSING) {
            throw new Error('只能标记处理中的订单为已支付');
        }
        this._status = OrderStatus.SUCCESS;
    }

    // Getters
    get sn(): string { return this._sn; }
    get buyerId(): number { return this._buyerId; }
    get status(): OrderStatus { return this._status; }
    get items(): ReadonlyArray<OrderItem> { return this._items; }
    get totalAmount(): number { return this._totalAmount; }
}
```

```typescript
// modules/order/domain/OrderItem.ts
import { ValueObject } from '@/shared/domain/ValueObject';

export class OrderItem extends ValueObject {
    constructor(
        private readonly _skuId: number,
        private readonly _skuName: string,
        private readonly _quantity: number,
        private readonly _unitPrice: number,
    ) {
        super();
        this.validate();
    }

    private validate(): void {
        if (this._quantity <= 0) {
            throw new Error('数量必须大于0');
        }
        if (this._unitPrice < 0) {
            throw new Error('单价不能为负');
        }
    }

    get totalPrice(): number {
        return this._quantity * this._unitPrice;
    }

    get skuId(): number { return this._skuId; }
    get skuName(): string { return this._skuName; }
    get quantity(): number { return this._quantity; }
    get unitPrice(): number { return this._unitPrice; }

    get value() {
        return {
            skuId: this._skuId,
            skuName: this._skuName,
            quantity: this._quantity,
            unitPrice: this._unitPrice,
        };
    }
}
```

```typescript
// modules/order/domain/OrderRepository.ts
import { Order } from './Order';
import { OrderId } from './OrderId';

export interface OrderRepository {
    findById(id: OrderId): Promise<Order | null>;
    findBySN(sn: string): Promise<Order | null>;
    findByBuyerId(buyerId: number, offset: number, limit: number): Promise<Order[]>;
    countByBuyerId(buyerId: number): Promise<number>;
    save(order: Order): Promise<void>;
    delete(order: Order): Promise<void>;
}
```

---

### 应用层

```typescript
// modules/order/application/commands/CreateOrderCommand.ts
import { OrderItem } from '../../domain/OrderItem';

export class CreateOrderCommand {
    constructor(
        public readonly sn: string,
        public readonly buyerId: number,
        public readonly items: OrderItem[],
    ) {}
}
```

```typescript
// modules/order/application/queries/OrderQuery.ts
export class OrderQuery {
    constructor(
        public readonly buyerId: number,
        public readonly offset: number = 0,
        public readonly limit: number = 20,
    ) {}
}
```

```typescript
// modules/order/application/OrderService.ts
import { Injectable } from '@nestjs/common';
import { OrderRepository } from '../domain/OrderRepository';
import { Order } from '../domain/Order';
import { CreateOrderCommand } from './commands/CreateOrderCommand';
import { OrderQuery } from './queries/OrderQuery';
import { EventBus } from '@/shared/infrastructure/EventBus';

@Injectable()
export class OrderService {
    constructor(
        private readonly orderRepo: OrderRepository,
        private readonly eventBus: EventBus,
    ) {}

    async createOrder(cmd: CreateOrderCommand): Promise<string> {
        // 创建订单
        const order = Order.create(cmd.sn, cmd.buyerId, cmd.items);

        // 持久化
        await this.orderRepo.save(order);

        // 发布领域事件
        await this.eventBus.publishAll(order.domainEvents);

        return order.sn;
    }

    async cancelOrder(buyerId: number, orderSN: string): Promise<void> {
        const order = await this.orderRepo.findBySN(orderSN);
        if (!order) {
            throw new Error('订单不存在');
        }
        if (order.buyerId !== buyerId) {
            throw new Error('无权操作此订单');
        }
        order.cancel();
        await this.orderRepo.save(order);
    }

    async queryOrders(query: OrderQuery): Promise<{ total: number; orders: Order[] }> {
        const [orders, total] = await Promise.all([
            this.orderRepo.findByBuyerId(query.buyerId, query.offset, query.limit),
            this.orderRepo.countByBuyerId(query.buyerId),
        ]);
        return { total, orders };
    }

    async getOrderBySN(sn: string): Promise<Order | null> {
        return this.orderRepo.findBySN(sn);
    }
}
```

---

### 用户界面层

```typescript
// modules/order/interfaces/http/OrderController.ts
import { Controller, Post, Get, Body, Param, Query, UseGuards } from '@nestjs/common';
import { OrderService } from '../../application/OrderService';
import { CreateOrderRequest, OrderListResponse, OrderResponse } from './OrderDTO';
import { OrderAssembler } from './OrderAssembler';
import { JwtAuthGuard } from '@/shared/infrastructure/auth/JwtAuthGuard';
import { CurrentUser } from '@/shared/infrastructure/auth/CurrentUser';

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrderController {
    constructor(
        private readonly orderService: OrderService,
        private readonly assembler: OrderAssembler,
    ) {}

    @Post()
    async create(
        @Body() req: CreateOrderRequest,
        @CurrentUser() user: UserPayload,
    ): Promise<{ sn: string }> {
        const cmd = this.assembler.toCreateCommand(req, user.id);
        const sn = await this.orderService.createOrder(cmd);
        return { sn };
    }

    @Post(':sn/cancel')
    async cancel(
        @Param('sn') sn: string,
        @CurrentUser() user: UserPayload,
    ): Promise<void> {
        await this.orderService.cancelOrder(user.id, sn);
    }

    @Get()
    async list(
        @Query() query: ListOrderQuery,
        @CurrentUser() user: UserPayload,
    ): Promise<OrderListResponse> {
        const result = await this.orderService.queryOrders({
            ...query,
            buyerId: user.id,
        });
        return this.assembler.toListResponse(result);
    }

    @Get(':sn')
    async detail(
        @Param('sn') sn: string,
        @CurrentUser() user: UserPayload,
    ): Promise<OrderResponse> {
        const order = await this.orderService.getOrderBySN(sn);
        if (!order || order.buyerId !== user.id) {
            throw new NotFoundException('订单不存在');
        }
        return this.assembler.toResponse(order);
    }
}
```

```typescript
// modules/order/interfaces/http/OrderDTO.ts
import { IsArray, IsNumber, IsString, Min } from 'class-validator';

// 请求对象
export class CreateOrderRequest {
    @IsArray()
    skus: SkuInput[];

    @IsArray()
    paymentItems: PaymentItemInput[];
}

export class SkuInput {
    @IsString()
    sn: string;

    @IsNumber()
    @Min(1)
    quantity: number;
}

export class PaymentItemInput {
    @IsNumber()
    type: number;

    @IsNumber()
    amount: number;
}

export class ListOrderQuery {
    @IsNumber()
    @Min(0)
    offset: number = 0;

    @IsNumber()
    @Min(1)
    limit: number = 20;
}

// 响应对象
export class OrderResponse {
    sn: string;
    status: number;
    originalTotalAmt: number;
    realTotalAmt: number;
    items: OrderItemResponse[];
    ctime: number;
}

export class OrderItemResponse {
    skuId: number;
    skuName: string;
    quantity: number;
    unitPrice: number;
    totalPrice: number;
}

export class OrderListResponse {
    total: number;
    orders: OrderResponse[];
}
```

```typescript
// modules/order/interfaces/http/OrderAssembler.ts
import { Injectable } from '@nestjs/common';
import { Order } from '../../domain/Order';
import { CreateOrderRequest, OrderResponse, OrderListResponse } from './OrderDTO';
import { CreateOrderCommand } from '../../application/commands/CreateOrderCommand';
import { OrderItem } from '../../domain/OrderItem';

@Injectable()
export class OrderAssembler {
    toCreateCommand(req: CreateOrderRequest, buyerId: number): CreateOrderCommand {
        const items = req.skus.map(sku =>
            new OrderItem(sku.skuId, sku.skuName, sku.quantity, sku.unitPrice)
        );
        return new CreateOrderCommand(req.sn, buyerId, items);
    }

    toResponse(order: Order): OrderResponse {
        return {
            sn: order.sn,
            status: order.status,
            originalTotalAmt: order.totalAmount,
            realTotalAmt: order.totalAmount,
            items: order.items.map(item => ({
                skuId: item.skuId,
                skuName: item.skuName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.totalPrice,
            })),
            ctime: order.ctime,
        };
    }

    toListResponse(result: { total: number; orders: Order[] }): OrderListResponse {
        return {
            total: result.total,
            orders: result.orders.map(this.toResponse),
        };
    }
}
```

---

### 基础设施层

```typescript
// modules/order/infrastructure/persistence/OrderORM.ts
import { Entity, Column, PrimaryColumn, OneToMany } from 'typeorm';

@Entity('orders')
export class OrderORM {
    @PrimaryColumn('uuid')
    id: string;

    @Column({ unique: true })
    sn: string;

    @Column()
    buyerId: number;

    @Column()
    status: number;

    @Column()
    totalAmount: number;

    @Column()
    ctime: number;

    @Column()
    utime: number;

    @OneToMany(() => OrderItemORM, item => item.order)
    items: OrderItemORM[];
}

@Entity('order_items')
export class OrderItemORM {
    @PrimaryColumn('uuid')
    id: string;

    @Column()
    orderId: string;

    @Column()
    skuId: number;

    @Column()
    skuName: string;

    @Column()
    quantity: number;

    @Column()
    unitPrice: number;

    @ManyToOne(() => OrderORM, order => order.items)
    order: OrderORM;
}
```

```typescript
// modules/order/infrastructure/persistence/OrderRepositoryImpl.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OrderRepository } from '../../domain/OrderRepository';
import { Order } from '../../domain/Order';
import { OrderId } from '../../domain/OrderId';
import { OrderORM, OrderItemORM } from './OrderORM';
import { OrderMapper } from './OrderMapper';

@Injectable()
export class OrderRepositoryImpl implements OrderRepository {
    constructor(
        @InjectRepository(OrderORM)
        private readonly repo: Repository<OrderORM>,
        private readonly mapper: OrderMapper,
    ) {}

    async findById(id: OrderId): Promise<Order | null> {
        const po = await this.repo.findOne({
            where: { id: id.value },
            relations: ['items'],
        });
        return po ? this.mapper.toDomain(po) : null;
    }

    async findBySN(sn: string): Promise<Order | null> {
        const po = await this.repo.findOne({
            where: { sn },
            relations: ['items'],
        });
        return po ? this.mapper.toDomain(po) : null;
    }

    async findByBuyerId(buyerId: number, offset: number, limit: number): Promise<Order[]> {
        const pos = await this.repo.find({
            where: { buyerId },
            relations: ['items'],
            skip: offset,
            take: limit,
            order: { ctime: 'DESC' },
        });
        return pos.map(po => this.mapper.toDomain(po));
    }

    async save(order: Order): Promise<void> {
        const po = this.mapper.toPersistence(order);
        await this.repo.save(po);
    }

    async delete(order: Order): Promise<void> {
        await this.repo.delete(order.id.value);
    }
}
```

```typescript
// modules/order/infrastructure/persistence/OrderMapper.ts
import { Injectable } from '@nestjs/common';
import { Order, OrderStatus } from '../../domain/Order';
import { OrderId } from '../../domain/OrderId';
import { OrderItem } from '../../domain/OrderItem';
import { OrderORM, OrderItemORM } from './OrderORM';

@Injectable()
export class OrderMapper {
    toDomain(po: OrderORM): Order {
        const items = po.items.map(item =>
            new OrderItem(item.skuId, item.skuName, item.quantity, item.unitPrice)
        );
        return Order.reconstitute(
            OrderId.fromString(po.id),
            po.sn,
            po.buyerId,
            items,
            po.status as OrderStatus,
        );
    }

    toPersistence(order: Order): OrderORM {
        const po = new OrderORM();
        po.id = order.id.value;
        po.sn = order.sn;
        po.buyerId = order.buyerId;
        po.status = order.status;
        po.totalAmount = order.totalAmount;
        po.ctime = Date.now();
        po.utime = Date.now();
        po.items = order.items.map((item, index) => {
            const itemPO = new OrderItemORM();
            itemPO.id = `${po.id}-${index}`;
            itemPO.orderId = po.id;
            itemPO.skuId = item.skuId;
            itemPO.skuName = item.skuName;
            itemPO.quantity = item.quantity;
            itemPO.unitPrice = item.unitPrice;
            return itemPO;
        });
        return po;
    }
}
```

---

### 模块定义

```typescript
// modules/order/OrderModule.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrderController } from './interfaces/http/OrderController';
import { OrderService } from './application/OrderService';
import { OrderRepositoryImpl } from './infrastructure/persistence/OrderRepositoryImpl';
import { OrderORM, OrderItemORM } from './infrastructure/persistence/OrderORM';
import { OrderAssembler } from './interfaces/http/OrderAssembler';

@Module({
    imports: [TypeOrmModule.forFeature([OrderORM, OrderItemORM])],
    controllers: [OrderController],
    providers: [
        OrderService,
        OrderRepositoryImpl,
        OrderAssembler,
        {
            provide: 'OrderRepository',
            useClass: OrderRepositoryImpl,
        },
    ],
    exports: [OrderService],
})
export class OrderModule {}
```

---

## 关键设计要点

### 领域对象设计

- **Entity**：有唯一标识，通过 ID 判断相等
- **ValueObject**：无标识，不可变，通过属性值判断相等
- **AggregateRoot**：聚合根，管理领域事件

### 依赖注入

- 使用 NestJS 的 DI 容器
- 领域层定义接口，基础设施层实现
- 通过 `provide/useClass` 实现依赖倒置

### 对象转换

```
HTTP Request → DTO → Command → Domain Object → PO → Database
                              ↓
                         Domain Event → EventBus
```

### 测试策略

- **单元测试**：领域对象业务逻辑
- **集成测试**：Repository 与数据库交互
- **E2E 测试**：Controller 层 API 测试
