# 前端 FSD (Feature-Sliced Design) 代码模型

> Feature-Sliced Design 是一种前端架构方法论，通过分层和切片组织代码，提高项目稳定性和可维护性。

---

## 核心概念

### 三级层次结构

1. **Layers（层）**：标准化的文件夹，如 `app`、`pages`、`features`、`entities`、`shared`
2. **Slices（切片）**：层内的业务领域划分
3. **Segments（分段）**：切片内的技术目的划分，如 `ui`、`api`、`model`

### 导入规则

**核心原则**：一个层上的模块只能从严格位于其下方的层上的模块导入。

```
app → pages → widgets → features → entities → shared
```

这确保了修改的隔离性，避免意外的副作用。

---

## 目录结构

```
src/
├── app/                          # 应用层 - 应用全局配置
│   ├── routes/                   # 路由配置
│   │   ├── index.tsx
│   │   └── routes.tsx
│   ├── store/                    # 全局状态配置
│   │   └── index.ts
│   ├── providers/                # 全局 Provider
│   │   └── index.tsx
│   ├── styles/                   # 全局样式
│   │   └── global.css
│   └── entrypoint.tsx            # 应用入口
│
├── pages/                        # 页面层 - 完整页面
│   ├── home/
│   │   ├── ui/
│   │   │   └── HomePage.tsx
│   │   └── index.ts
│   ├── profile/
│   │   ├── ui/
│   │   │   └── ProfilePage.tsx
│   │   ├── api/
│   │   │   └── fetchProfile.ts
│   │   └── index.ts
│   └── settings/
│       └── ...
│
├── widgets/                      # 组件层 - 大型独立 UI 块
│   ├── header/
│   │   ├── ui/
│   │   │   ├── Header.tsx
│   │   │   └── HeaderNav.tsx
│   │   ├── model/
│   │   │   └── useHeader.ts
│   │   └── index.ts
│   ├── sidebar/
│   │   ├── ui/
│   │   │   └── Sidebar.tsx
│   │   └── index.ts
│   └── product-card/
│       └── ...
│
├── features/                     # 功能层 - 可复用的业务功能
│   ├── auth/                     # 认证功能
│   │   ├── ui/
│   │   │   ├── LoginForm.tsx
│   │   │   └── RegisterForm.tsx
│   │   ├── api/
│   │   │   ├── login.ts
│   │   │   └── register.ts
│   │   ├── model/
│   │   │   ├── authSlice.ts
│   │   │   └── types.ts
│   │   └── index.ts
│   ├── comments/                 # 评论功能
│   │   ├── ui/
│   │   │   ├── CommentCard.tsx
│   │   │   ├── CommentForm.tsx
│   │   │   └── CommentList.tsx
│   │   ├── api/
│   │   │   ├── createComment.ts
│   │   │   └── fetchComments.ts
│   │   ├── model/
│   │   │   ├── commentsSlice.ts
│   │   │   └── types.ts
│   │   └── index.ts
│   └── add-to-cart/              # 添加购物车功能
│       └── ...
│
├── entities/                     # 实体层 - 业务实体
│   ├── user/                     # 用户实体
│   │   ├── ui/
│   │   │   ├── UserAvatar.tsx
│   │   │   └── UserName.tsx
│   │   ├── api/
│   │   │   └── fetchUser.ts
│   │   ├── model/
│   │   │   ├── userSlice.ts
│   │   │   ├── types.ts
│   │   │   └── selectors.ts
│   │   └── index.ts
│   ├── product/                  # 产品实体
│   │   ├── ui/
│   │   │   └── ProductImage.tsx
│   │   ├── model/
│   │   │   ├── types.ts
│   │   │   └── selectors.ts
│   │   └── index.ts
│   └── cart/                     # 购物车实体
│       └── ...
│
└── shared/                       # 共享层 - 可复用功能
    ├── ui/                       # UI 组件库
    │   ├── Button/
    │   │   ├── Button.tsx
    │   │   └── index.ts
    │   ├── Input/
    │   ├── Modal/
    │   ├── Card/
    │   └── index.ts
    ├── api/                      # API 基础设施
    │   ├── axios.ts
    │   ├── baseApi.ts
    │   └── index.ts
    ├── lib/                      # 工具库
    │   ├── formatDate.ts
    │   ├── debounce.ts
    │   └── index.ts
    ├── config/                   # 配置
    │   ├── env.ts
    │   └── constants.ts
    ├── types/                    # 类型定义
    │   └── common.ts
    └── hooks/                    # 通用 Hooks
        ├── useDebounce.ts
        └── useLocalStorage.ts
```

---

## 各层职责

| 层级 | 职责 | 示例 |
|-----|------|------|
| **app** | 应用全局配置：路由、状态管理、Provider、全局样式 | 路由配置、Redux Store、ThemeProvider |
| **pages** | 完整页面或嵌套路由中的大型页面部分 | HomePage、ProfilePage、SettingsPage |
| **widgets** | 大型独立的 UI 块，通常实现完整用例 | Header、Sidebar、ProductCard |
| **features** | 可复用的业务功能实现，为用户带来业务价值 | 登录表单、评论功能、添加购物车 |
| **entities** | 业务实体，项目核心业务对象 | User、Product、Order、Cart |
| **shared** | 可复用功能，与具体业务解耦 | UI 组件库、API 客户端、工具函数 |

---

## 分段（Segments）说明

每个切片内的分段按技术目的组织代码：

| 分段 | 用途 | 内容 |
|-----|------|------|
| **ui** | UI 组件 | React 组件、样式文件 |
| **api** | 后端交互 | API 请求函数、数据获取 |
| **model** | 数据和业务逻辑 | 状态管理、类型定义、业务逻辑 |
| **lib** | 内部工具 | 辅助函数、格式化工具 |
| **config** | 配置 | 常量、环境变量 |

---

## 代码示例

### app 层

```tsx
// app/routes/index.tsx
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import { HomePage } from '@/pages/home';
import { ProfilePage } from '@/pages/profile';

const router = createBrowserRouter([
  { path: '/', element: <HomePage /> },
  { path: '/profile', element: <ProfilePage /> },
]);

export const AppRouter = () => <RouterProvider router={router} />;
```

```tsx
// app/providers/index.tsx
import { Provider } from 'react-redux';
import { store } from '@/app/store';
import { ThemeProvider } from './ThemeProvider';

export const AppProviders = ({ children }: { children: React.ReactNode }) => (
  <Provider store={store}>
    <ThemeProvider>
      {children}
    </ThemeProvider>
  </Provider>
);
```

```tsx
// app/entrypoint.tsx
import { AppProviders } from './providers';
import { AppRouter } from './routes';
import './styles/global.css';

export const App = () => (
  <AppProviders>
    <AppRouter />
  </AppProviders>
);
```

### pages 层

```tsx
// pages/home/ui/HomePage.tsx
import { Header } from '@/widgets/header';
import { ProductList } from '@/widgets/product-list';
import { useUser } from '@/entities/user';

export const HomePage = () => {
  const user = useUser();

  return (
    <div className="home-page">
      <Header />
      <main>
        <h1>Welcome, {user.name}</h1>
        <ProductList />
      </main>
    </div>
  );
};
```

```ts
// pages/home/index.ts
export { HomePage } from './ui/HomePage';
```

### widgets 层

```tsx
// widgets/header/ui/Header.tsx
import { HeaderNav } from './HeaderNav';
import { UserAvatar } from '@/entities/user';
import { useAuth } from '@/features/auth';

export const Header = () => {
  const { user, logout } = useAuth();

  return (
    <header className="header">
      <div className="logo">MyApp</div>
      <HeaderNav />
      <div className="user-section">
        <UserAvatar user={user} />
        <button onClick={logout}>Logout</button>
      </div>
    </header>
  );
};
```

```ts
// widgets/header/index.ts
export { Header } from './ui/Header';
```

### features 层

```tsx
// features/auth/ui/LoginForm.tsx
import { useState } from 'react';
import { Button, Input } from '@/shared/ui';
import { useLoginMutation } from '../api/login';

export const LoginForm = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [login, { isLoading }] = useLoginMutation();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await login({ email, password });
  };

  return (
    <form onSubmit={handleSubmit} className="login-form">
      <Input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
      />
      <Input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      <Button type="submit" loading={isLoading}>
        Login
      </Button>
    </form>
  );
};
```

```ts
// features/auth/api/login.ts
import { api } from '@/shared/api';
import { setCredentials } from '../model/authSlice';

export const useLoginMutation = () => {
  const dispatch = useDispatch();

  const login = async (credentials: LoginCredentials) => {
    const response = await api.post('/auth/login', credentials);
    dispatch(setCredentials(response.data));
    return response.data;
  };

  return [login, { isLoading: false }];
};
```

```ts
// features/auth/model/authSlice.ts
import { createSlice } from '@reduxjs/toolkit';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

const initialState: AuthState = {
  user: null,
  token: null,
  isAuthenticated: false,
};

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setCredentials: (state, action) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      state.isAuthenticated = true;
    },
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
    },
  },
});

export const { setCredentials, logout } = authSlice.actions;
export default authSlice.reducer;
```

```ts
// features/auth/index.ts
export { LoginForm } from './ui/LoginForm';
export { RegisterForm } from './ui/RegisterForm';
export { useAuth } from './model/useAuth';
```

### entities 层

```tsx
// entities/user/ui/UserAvatar.tsx
import { Avatar } from '@/shared/ui';

interface UserAvatarProps {
  user: User;
  size?: 'sm' | 'md' | 'lg';
}

export const UserAvatar = ({ user, size = 'md' }: UserAvatarProps) => {
  return (
    <Avatar
      src={user.avatar}
      alt={user.name}
      size={size}
    />
  );
};
```

```ts
// entities/user/model/types.ts
export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
}

export interface UserState {
  currentUser: User | null;
  isLoading: boolean;
}
```

```ts
// entities/user/model/selectors.ts
import { RootState } from '@/app/store';

export const selectCurrentUser = (state: RootState) => state.user.currentUser;
export const selectIsAuthenticated = (state: RootState) => !!state.user.currentUser;
```

```ts
// entities/user/index.ts
export { UserAvatar, UserName } from './ui';
export { fetchUser } from './api';
export { useUser } from './model/useUser';
export { selectCurrentUser, selectIsAuthenticated } from './model/selectors';
export type { User } from './model/types';
```

### shared 层

```tsx
// shared/ui/Button/Button.tsx
import { ButtonHTMLAttributes, forwardRef } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', loading, children, disabled, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={`btn btn-${variant} btn-${size}`}
        disabled={disabled || loading}
        {...props}
      >
        {loading ? <span className="spinner" /> : children}
      </button>
    );
  }
);
```

```ts
// shared/api/axios.ts
import axios from 'axios';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 响应拦截器
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // 处理未授权
    }
    return Promise.reject(error);
  }
);
```

```ts
// shared/lib/formatDate.ts
export const formatDate = (date: Date | string, format = 'YYYY-MM-DD'): string => {
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');

  return format
    .replace('YYYY', String(year))
    .replace('MM', month)
    .replace('DD', day);
};
```

---

## 与 DDD 的对应关系

| FSD 层级 | DDD 层级 | 说明 |
|---------|---------|------|
| app | 应用层入口 | 应用配置、路由、全局状态 |
| pages | 用户界面层 | 页面组装 |
| widgets | 用户界面层 | 大型 UI 组件 |
| features | 应用层 | 用例编排 |
| entities | 领域层 | 业务实体 |
| shared | 基础设施层 | 可复用基础设施 |

---

## 最佳实践

### 1. 导入规则

```typescript
// ✅ 正确：从下层导入
// features/auth/ui/LoginForm.tsx
import { Button } from '@/shared/ui';
import { UserAvatar } from '@/entities/user';

// ❌ 错误：从上层导入
// entities/user/model/user.ts
import { useAuth } from '@/features/auth'; // 违反导入规则
```

### 2. 公共接口

每个切片通过 `index.ts` 暴露公共接口：

```ts
// features/auth/index.ts
// ✅ 只导出必要的接口
export { LoginForm, RegisterForm } from './ui';
export { useAuth } from './model';

// ❌ 不要导出内部实现
// export { authSlice } from './model/authSlice';
```

### 3. 命名约定

| 类型 | 约定 | 示例 |
|-----|------|------|
| 页面组件 | {Name}Page | `HomePage`, `ProfilePage` |
| Widget 组件 | {Name} | `Header`, `Sidebar` |
| Feature 组件 | {Action}{Target} | `LoginForm`, `AddToCart` |
| Entity 组件 | {Entity}{Part} | `UserAvatar`, `ProductName` |
| API 函数 | {action}{Entity} | `fetchUser`, `createOrder` |
| Slice | {entity}Slice | `userSlice`, `authSlice` |

### 4. 状态管理

- **全局状态**：放在 `app/store/`
- **实体状态**：放在 `entities/{entity}/model/`
- **功能状态**：放在 `features/{feature}/model/`

---

## CLI 工具

使用 FSD CLI 快速创建结构：

```bash
# 安装
npm install -D @feature-sliced/cli

# 创建页面
npx fsd pages home profile settings --segments ui

# 创建功能
npx fsd features auth comments --segments ui api model

# 创建实体
npx fsd entities user product cart --segments ui model api

# 创建共享层
npx fsd shared --segments api config ui lib
```

---

## 参考资料

- [Feature-Sliced Design 官方文档](https://feature-sliced.design/)
- [FSD GitHub](https://github.com/feature-sliced)
- [FSD Examples](https://github.com/feature-sliced/examples)
