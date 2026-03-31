# Java/Spring DDD 代码模型

> 适用于 Spring Boot、Spring Cloud 等框架

---

## 目录结构

```
src/main/java/com/example/
├── interfaces/                     # 用户界面层
│   ├── controller/
│   │   └── OrderController.java
│   ├── dto/
│   │   ├── CreateOrderRequest.java
│   │   └── OrderResponse.java
│   └── assembler/
│       └── OrderAssembler.java
│
├── application/                    # 应用层
│   ├── OrderApplicationService.java
│   ├── command/
│   │   ├── CreateOrderCommand.java
│   │   └── CancelOrderCommand.java
│   └── query/
│       └── OrderQueryService.java
│
├── domain/                         # 领域层
│   ├── model/
│   │   ├── order/
│   │   │   ├── Order.java          # 聚合根
│   │   │   ├── OrderItem.java      # 实体
│   │   │   ├── OrderId.java        # 值对象
│   │   │   └── OrderStatus.java    # 枚举
│   │   └── shared/
│   │       └── Money.java          # 值对象
│   ├── repository/
│   │   └── OrderRepository.java    # 仓储接口
│   ├── service/
│   │   └── OrderDomainService.java
│   └── event/
│       └── OrderCreatedEvent.java
│
├── infrastructure/                 # 基础设施层
│   ├── persistence/
│   │   ├── OrderRepositoryImpl.java
│   │   ├── OrderPO.java            # 持久化对象
│   │   └── OrderMapper.java
│   ├── messaging/
│   │   └── OrderEventPublisher.java
│   └── config/
│       └── OrderConfig.java
│
└── Application.java                # 启动类
```

---

## 各层代码示例

### 领域层

```java
// domain/model/shared/Money.java
package com.example.domain.model.shared;

import java.math.BigDecimal;
import java.util.Objects;

public class Money {
    private final BigDecimal amount;
    private final String currency;

    public Money(BigDecimal amount) {
        this(amount, "CNY");
    }

    public Money(BigDecimal amount, String currency) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("金额不能为负数");
        }
        this.amount = amount;
        this.currency = currency;
    }

    public static final Money ZERO = new Money(BigDecimal.ZERO);

    public Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("币种不同，无法相加");
        }
        return new Money(this.amount.add(other.amount), this.currency);
    }

    public Money multiply(int factor) {
        return new Money(this.amount.multiply(BigDecimal.valueOf(factor)), this.currency);
    }

    public BigDecimal getAmount() { return amount; }
    public String getCurrency() { return currency; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Money)) return false;
        Money money = (Money) o;
        return Objects.equals(amount, money.amount) && Objects.equals(currency, money.currency);
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount, currency);
    }
}
```

```java
// domain/model/order/OrderId.java
package com.example.domain.model.order;

import java.util.Objects;
import java.util.UUID;

public class OrderId {
    private final String value;

    private OrderId(String value) {
        this.value = Objects.requireNonNull(value);
    }

    public static OrderId generate() {
        return new OrderId(UUID.randomUUID().toString());
    }

    public static OrderId fromString(String value) {
        return new OrderId(value);
    }

    public String getValue() { return value; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof OrderId)) return false;
        OrderId orderId = (OrderId) o;
        return Objects.equals(value, orderId.value);
    }

    @Override
    public int hashCode() {
        return Objects.hash(value);
    }
}
```

```java
// domain/model/order/OrderStatus.java
package com.example.domain.model.order;

public enum OrderStatus {
    INIT(1),
    PROCESSING(2),
    SUCCESS(3),
    FAILED(4),
    CANCELED(5);

    private final int code;

    OrderStatus(int code) {
        this.code = code;
    }

    public int getCode() { return code; }

    public static OrderStatus fromCode(int code) {
        for (OrderStatus status : values()) {
            if (status.code == code) {
                return status;
            }
        }
        throw new IllegalArgumentException("Unknown order status code: " + code);
    }
}
```

```java
// domain/model/order/OrderItem.java
package com.example.domain.model.order;

import com.example.domain.model.shared.Money;

public class OrderItem {
    private final Long skuId;
    private final String skuName;
    private final int quantity;
    private final Money unitPrice;

    public OrderItem(Long skuId, String skuName, int quantity, Money unitPrice) {
        if (quantity <= 0) {
            throw new IllegalArgumentException("数量必须大于0");
        }
        this.skuId = skuId;
        this.skuName = skuName;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
    }

    public Money getSubtotal() {
        return unitPrice.multiply(quantity);
    }

    public Long getSkuId() { return skuId; }
    public String getSkuName() { return skuName; }
    public int getQuantity() { return quantity; }
    public Money getUnitPrice() { return unitPrice; }
}
```

```java
// domain/model/order/Order.java
package com.example.domain.model.order;

import com.example.domain.model.shared.Money;
import com.example.domain.event.OrderCreatedEvent;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class Order {
    private final OrderId id;
    private final String sn;
    private final Long buyerId;
    private final List<OrderItem> items;
    private OrderStatus status;
    private Money totalAmount;
    private final List<Object> domainEvents = new ArrayList<>();

    // 私有构造函数
    private Order(OrderId id, String sn, Long buyerId) {
        this.id = id;
        this.sn = sn;
        this.buyerId = buyerId;
        this.status = OrderStatus.INIT;
        this.items = new ArrayList<>();
    }

    // 工厂方法 - 创建订单
    public static Order create(String sn, Long buyerId, List<OrderItem> items) {
        OrderId id = OrderId.generate();
        Order order = new Order(id, sn, buyerId);
        order.items.addAll(items);
        order.calculateTotal();
        order.registerEvent(new OrderCreatedEvent(order));
        return order;
    }

    // 重建订单（从数据库恢复）
    public static Order reconstitute(
            OrderId id,
            String sn,
            Long buyerId,
            List<OrderItem> items,
            OrderStatus status) {
        Order order = new Order(id, sn, buyerId);
        order.items.addAll(items);
        order.status = status;
        order.calculateTotal();
        return order;
    }

    // 业务方法
    public void cancel() {
        if (status != OrderStatus.PROCESSING) {
            throw new IllegalStateException("只能取消处理中的订单");
        }
        this.status = OrderStatus.CANCELED;
    }

    public void markAsPaid() {
        if (status != OrderStatus.PROCESSING) {
            throw new IllegalStateException("只能标记处理中的订单");
        }
        this.status = OrderStatus.SUCCESS;
    }

    private void calculateTotal() {
        this.totalAmount = items.stream()
            .map(OrderItem::getSubtotal)
            .reduce(Money.ZERO, Money::add);
    }

    private void registerEvent(Object event) {
        this.domainEvents.add(event);
    }

    public List<Object> getDomainEvents() {
        return Collections.unmodifiableList(domainEvents);
    }

    public void clearDomainEvents() {
        this.domainEvents.clear();
    }

    // Getters
    public OrderId getId() { return id; }
    public String getSn() { return sn; }
    public Long getBuyerId() { return buyerId; }
    public OrderStatus getStatus() { return status; }
    public List<OrderItem> getItems() { return Collections.unmodifiableList(items); }
    public Money getTotalAmount() { return totalAmount; }
}
```

```java
// domain/repository/OrderRepository.java
package com.example.domain.repository;

import com.example.domain.model.order.Order;
import com.example.domain.model.order.OrderId;
import java.util.List;
import java.util.Optional;

public interface OrderRepository {
    Order save(Order order);
    Optional<Order> findById(OrderId id);
    Optional<Order> findBySn(String sn);
    List<Order> findByBuyerId(Long buyerId, int offset, int limit);
    long countByBuyerId(Long buyerId);
    void delete(Order order);
}
```

```java
// domain/event/OrderCreatedEvent.java
package com.example.domain.event;

import com.example.domain.model.order.Order;
import java.time.LocalDateTime;

public class OrderCreatedEvent {
    private final String orderId;
    private final String orderSn;
    private final Long buyerId;
    private final String totalAmount;
    private final LocalDateTime occurredOn;

    public OrderCreatedEvent(Order order) {
        this.orderId = order.getId().getValue();
        this.orderSn = order.getSn();
        this.buyerId = order.getBuyerId();
        this.totalAmount = order.getTotalAmount().getAmount().toString();
        this.occurredOn = LocalDateTime.now();
    }

    public String getOrderId() { return orderId; }
    public String getOrderSn() { return orderSn; }
    public Long getBuyerId() { return buyerId; }
    public String getTotalAmount() { return totalAmount; }
    public LocalDateTime getOccurredOn() { return occurredOn; }
}
```

---

### 应用层

```java
// application/command/CreateOrderCommand.java
package com.example.application.command;

import com.example.domain.model.order.OrderItem;
import java.util.List;

public class CreateOrderCommand {
    private final String sn;
    private final Long buyerId;
    private final List<OrderItem> items;

    public CreateOrderCommand(String sn, Long buyerId, List<OrderItem> items) {
        this.sn = sn;
        this.buyerId = buyerId;
        this.items = items;
    }

    public String getSn() { return sn; }
    public Long getBuyerId() { return buyerId; }
    public List<OrderItem> getItems() { return items; }
}
```

```java
// application/command/CancelOrderCommand.java
package com.example.application.command;

public class CancelOrderCommand {
    private final Long buyerId;
    private final String orderSn;

    public CancelOrderCommand(Long buyerId, String orderSn) {
        this.buyerId = buyerId;
        this.orderSn = orderSn;
    }

    public Long getBuyerId() { return buyerId; }
    public String getOrderSn() { return orderSn; }
}
```

```java
// application/OrderApplicationService.java
package com.example.application;

import com.example.domain.model.order.Order;
import com.example.domain.repository.OrderRepository;
import com.example.application.command.CreateOrderCommand;
import com.example.application.command.CancelOrderCommand;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class OrderApplicationService {
    private final OrderRepository orderRepository;
    private final EventPublisher eventPublisher;

    public OrderApplicationService(OrderRepository orderRepository, EventPublisher eventPublisher) {
        this.orderRepository = orderRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public String createOrder(CreateOrderCommand command) {
        Order order = Order.create(
            command.getSn(),
            command.getBuyerId(),
            command.getItems()
        );

        orderRepository.save(order);

        // 发布领域事件
        order.getDomainEvents().forEach(eventPublisher::publish);
        order.clearDomainEvents();

        return order.getSn();
    }

    @Transactional
    public void cancelOrder(CancelOrderCommand command) {
        Order order = orderRepository.findBySn(command.getOrderSn())
            .orElseThrow(() -> new IllegalArgumentException("订单不存在"));

        if (!order.getBuyerId().equals(command.getBuyerId())) {
            throw new IllegalArgumentException("无权操作此订单");
        }

        order.cancel();
        orderRepository.save(order);
    }

    @Transactional(readOnly = true)
    public OrderResult queryOrders(Long buyerId, int offset, int limit) {
        List<Order> orders = orderRepository.findByBuyerId(buyerId, offset, limit);
        long total = orderRepository.countByBuyerId(buyerId);
        return new OrderResult(total, orders);
    }

    @Transactional(readOnly = true)
    public Order getOrderDetail(String orderSn, Long buyerId) {
        Order order = orderRepository.findBySn(orderSn)
            .orElseThrow(() -> new IllegalArgumentException("订单不存在"));
        if (!order.getBuyerId().equals(buyerId)) {
            throw new IllegalArgumentException("无权查看此订单");
        }
        return order;
    }
}
```

---

### 用户界面层

```java
// interfaces/dto/CreateOrderRequest.java
package com.example.interfaces.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public class CreateOrderRequest {
    private String requestId;

    @NotNull
    @Size(min = 1)
    private List<SkuInput> skus;

    private List<PaymentItemInput> paymentItems;

    // Getters and Setters
    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }
    public List<SkuInput> getSkus() { return skus; }
    public void setSkus(List<SkuInput> skus) { this.skus = skus; }
    public List<PaymentItemInput> getPaymentItems() { return paymentItems; }
    public void setPaymentItems(List<PaymentItemInput> paymentItems) { this.paymentItems = paymentItems; }

    public static class SkuInput {
        @NotNull
        private Long skuId;
        private String skuName;

        @Min(1)
        private int quantity;

        @NotNull
        private BigDecimal unitPrice;

        // Getters and Setters
        public Long getSkuId() { return skuId; }
        public void setSkuId(Long skuId) { this.skuId = skuId; }
        public String getSkuName() { return skuName; }
        public void setSkuName(String skuName) { this.skuName = skuName; }
        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }
        public BigDecimal getUnitPrice() { return unitPrice; }
        public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    }

    public static class PaymentItemInput {
        private int type;
        private BigDecimal amount;

        // Getters and Setters
        public int getType() { return type; }
        public void setType(int type) { this.type = type; }
        public BigDecimal getAmount() { return amount; }
        public void setAmount(BigDecimal amount) { this.amount = amount; }
    }
}
```

```java
// interfaces/dto/OrderResponse.java
package com.example.interfaces.dto;

import java.math.BigDecimal;
import java.util.List;

public class OrderResponse {
    private String sn;
    private int status;
    private BigDecimal originalTotalAmt;
    private BigDecimal realTotalAmt;
    private List<OrderItemResponse> items;
    private long ctime;

    // Getters and Setters
    public String getSn() { return sn; }
    public void setSn(String sn) { this.sn = sn; }
    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }
    public BigDecimal getOriginalTotalAmt() { return originalTotalAmt; }
    public void setOriginalTotalAmt(BigDecimal originalTotalAmt) { this.originalTotalAmt = originalTotalAmt; }
    public BigDecimal getRealTotalAmt() { return realTotalAmt; }
    public void setRealTotalAmt(BigDecimal realTotalAmt) { this.realTotalAmt = realTotalAmt; }
    public List<OrderItemResponse> getItems() { return items; }
    public void setItems(List<OrderItemResponse> items) { this.items = items; }
    public long getCtime() { return ctime; }
    public void setCtime(long ctime) { this.ctime = ctime; }

    public static class OrderItemResponse {
        private Long skuId;
        private String skuName;
        private int quantity;
        private BigDecimal unitPrice;
        private BigDecimal totalPrice;

        // Getters and Setters
        public Long getSkuId() { return skuId; }
        public void setSkuId(Long skuId) { this.skuId = skuId; }
        public String getSkuName() { return skuName; }
        public void setSkuName(String skuName) { this.skuName = skuName; }
        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }
        public BigDecimal getUnitPrice() { return unitPrice; }
        public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
        public BigDecimal getTotalPrice() { return totalPrice; }
        public void setTotalPrice(BigDecimal totalPrice) { this.totalPrice = totalPrice; }
    }
}
```

```java
// interfaces/assembler/OrderAssembler.java
package com.example.interfaces.assembler;

import com.example.domain.model.order.Order;
import com.example.domain.model.order.OrderItem;
import com.example.domain.model.shared.Money;
import com.example.interfaces.dto.CreateOrderRequest;
import com.example.interfaces.dto.OrderResponse;
import com.example.application.command.CreateOrderCommand;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.util.stream.Collectors;

@Component
public class OrderAssembler {

    public CreateOrderCommand toCommand(CreateOrderRequest request, Long buyerId) {
        var items = request.getSkus().stream()
            .map(sku -> new OrderItem(
                sku.getSkuId(),
                sku.getSkuName(),
                sku.getQuantity(),
                new Money(sku.getUnitPrice())
            ))
            .collect(Collectors.toList());

        return new CreateOrderCommand(request.getRequestId(), buyerId, items);
    }

    public OrderResponse toResponse(Order order) {
        var response = new OrderResponse();
        response.setSn(order.getSn());
        response.setStatus(order.getStatus().getCode());
        response.setOriginalTotalAmt(order.getTotalAmount().getAmount());
        response.setRealTotalAmt(order.getTotalAmount().getAmount());

        var items = order.getItems().stream()
            .map(this::toItemResponse)
            .collect(Collectors.toList());
        response.setItems(items);

        return response;
    }

    private OrderResponse.OrderItemResponse toItemResponse(OrderItem item) {
        var response = new OrderResponse.OrderItemResponse();
        response.setSkuId(item.getSkuId());
        response.setSkuName(item.getSkuName());
        response.setQuantity(item.getQuantity());
        response.setUnitPrice(item.getUnitPrice().getAmount());
        response.setTotalPrice(item.getSubtotal().getAmount());
        return response;
    }
}
```

```java
// interfaces/controller/OrderController.java
package com.example.interfaces.controller;

import com.example.application.OrderApplicationService;
import com.example.interfaces.dto.CreateOrderRequest;
import com.example.interfaces.dto.OrderResponse;
import com.example.interfaces.assembler.OrderAssembler;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/orders")
public class OrderController {
    private final OrderApplicationService orderService;
    private final OrderAssembler assembler;

    public OrderController(OrderApplicationService orderService, OrderAssembler assembler) {
        this.orderService = orderService;
        this.assembler = assembler;
    }

    @PostMapping
    public ResponseEntity<Map<String, String>> create(
            @Valid @RequestBody CreateOrderRequest request,
            @CurrentUser UserPayload user) {
        var cmd = assembler.toCommand(request, user.getId());
        String sn = orderService.createOrder(cmd);
        return ResponseEntity.ok(Map.of("sn", sn));
    }

    @PostMapping("/{sn}/cancel")
    public ResponseEntity<Void> cancel(
            @PathVariable String sn,
            @CurrentUser UserPayload user) {
        orderService.cancelOrder(new CancelOrderCommand(user.getId(), sn));
        return ResponseEntity.noContent().build();
    }

    @GetMapping
    public ResponseEntity<OrderListResponse> list(
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(defaultValue = "20") int limit,
            @CurrentUser UserPayload user) {
        var result = orderService.queryOrders(user.getId(), offset, limit);
        var response = new OrderListResponse(
            result.total(),
            result.orders().stream().map(assembler::toResponse).toList()
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{sn}")
    public ResponseEntity<OrderResponse> detail(
            @PathVariable String sn,
            @CurrentUser UserPayload user) {
        var order = orderService.getOrderDetail(sn, user.getId());
        return ResponseEntity.ok(assembler.toResponse(order));
    }
}
```

---

### 基础设施层

```java
// infrastructure/persistence/OrderPO.java
package com.example.infrastructure.persistence;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
public class OrderPO {
    @Id
    @Column(length = 36)
    private String id;

    @Column(unique = true, nullable = false, length = 64)
    private String sn;

    @Column(nullable = false)
    private Long buyerId;

    @Column(nullable = false)
    private Integer status;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal totalAmount;

    @Column(nullable = false)
    private Long ctime;

    @Column(nullable = false)
    private Long utime;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderItemPO> items = new ArrayList<>();

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getSn() { return sn; }
    public void setSn(String sn) { this.sn = sn; }
    public Long getBuyerId() { return buyerId; }
    public void setBuyerId(Long buyerId) { this.buyerId = buyerId; }
    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    public Long getCtime() { return ctime; }
    public void setCtime(Long ctime) { this.ctime = ctime; }
    public Long getUtime() { return utime; }
    public void setUtime(Long utime) { this.utime = utime; }
    public List<OrderItemPO> getItems() { return items; }
    public void setItems(List<OrderItemPO> items) { this.items = items; }
}

@Entity
@Table(name = "order_items")
public class OrderItemPO {
    @Id
    @Column(length = 36)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private OrderPO order;

    @Column(nullable = false)
    private Long skuId;

    @Column(nullable = false, length = 255)
    private String skuName;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal unitPrice;

    // Getters and Setters
    // ...
}
```

```java
// infrastructure/persistence/OrderMapper.java
package com.example.infrastructure.persistence;

import com.example.domain.model.order.Order;
import com.example.domain.model.order.OrderId;
import com.example.domain.model.order.OrderItem;
import com.example.domain.model.order.OrderStatus;
import com.example.domain.model.shared.Money;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.util.UUID;

@Component
public class OrderMapper {

    public Order toDomain(OrderPO po) {
        var items = po.getItems().stream()
            .map(itemPO -> new OrderItem(
                itemPO.getSkuId(),
                itemPO.getSkuName(),
                itemPO.getQuantity(),
                new Money(itemPO.getUnitPrice())
            ))
            .toList();

        return Order.reconstitute(
            OrderId.fromString(po.getId()),
            po.getSn(),
            po.getBuyerId(),
            items,
            OrderStatus.fromCode(po.getStatus())
        );
    }

    public OrderPO toPersistence(Order order) {
        var po = new OrderPO();
        po.setId(order.getId().getValue());
        po.setSn(order.getSn());
        po.setBuyerId(order.getBuyerId());
        po.setStatus(order.getStatus().getCode());
        po.setTotalAmount(order.getTotalAmount().getAmount());
        po.setCtime(System.currentTimeMillis());
        po.setUtime(System.currentTimeMillis());

        var itemPOs = order.getItems().stream()
            .map(item -> {
                var itemPO = new OrderItemPO();
                itemPO.setId(UUID.randomUUID().toString());
                itemPO.setOrder(po);
                itemPO.setSkuId(item.getSkuId());
                itemPO.setSkuName(item.getSkuName());
                itemPO.setQuantity(item.getQuantity());
                itemPO.setUnitPrice(item.getUnitPrice().getAmount());
                return itemPO;
            })
            .toList();
        po.setItems(itemPOs);

        return po;
    }
}
```

```java
// infrastructure/persistence/OrderRepositoryImpl.java
package com.example.infrastructure.persistence;

import com.example.domain.model.order.Order;
import com.example.domain.model.order.OrderId;
import com.example.domain.repository.OrderRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.List;
import java.util.Optional;

@Repository
public class OrderRepositoryImpl implements OrderRepository {
    @PersistenceContext
    private EntityManager entityManager;

    private final OrderMapper mapper;
    private final OrderJpaRepository jpaRepository;

    public OrderRepositoryImpl(OrderMapper mapper, OrderJpaRepository jpaRepository) {
        this.mapper = mapper;
        this.jpaRepository = jpaRepository;
    }

    @Override
    @Transactional
    public Order save(Order order) {
        OrderPO po = mapper.toPersistence(order);
        OrderPO saved = jpaRepository.save(po);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<Order> findById(OrderId id) {
        return jpaRepository.findById(id.getValue())
            .map(mapper::toDomain);
    }

    @Override
    public Optional<Order> findBySn(String sn) {
        return jpaRepository.findBySn(sn)
            .map(mapper::toDomain);
    }

    @Override
    public List<Order> findByBuyerId(Long buyerId, int offset, int limit) {
        return jpaRepository.findByBuyerIdOrderByCtimeDesc(buyerId)
            .stream()
            .skip(offset)
            .limit(limit)
            .map(mapper::toDomain)
            .toList();
    }

    @Override
    public long countByBuyerId(Long buyerId) {
        return jpaRepository.countByBuyerId(buyerId);
    }

    @Override
    @Transactional
    public void delete(Order order) {
        jpaRepository.deleteById(order.getId().getValue());
    }
}
```

---

## 关键设计要点

### 领域对象设计

- **Entity**：有唯一标识，实现 `equals()` 和 `hashCode()`
- **ValueObject**：不可变，通过属性值判断相等
- **AggregateRoot**：管理领域事件，提供工厂方法

### 依赖注入

- 使用 Spring 的 `@Autowired` 或构造函数注入
- 领域层定义接口，基础设施层使用 `@Repository` 实现
- 使用 `@Component` 注册 Assembler

### 事务管理

- 应用服务使用 `@Transactional`
- 查询方法使用 `@Transactional(readOnly = true)`

### 对象转换

```
HTTP Request → DTO → Command → Domain Object → PO → Database
                              ↓
                         Domain Event → EventPublisher
```

### 测试策略

- **单元测试**：领域对象业务逻辑（JUnit 5）
- **集成测试**：Repository 与数据库交互（@DataJpaTest）
- **E2E 测试**：Controller 层 API 测试（MockMvc）
