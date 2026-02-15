# Fullstack Development Skill

Comprehensive technical knowledge for end-to-end feature development across the entire stack.

---

## Data Flow Architecture

### Database Design
- Design schemas with proper relationships (1:1, 1:N, N:M)
- Use appropriate normalization levels (3NF for transactional, denormalized for analytics)
- Plan for data growth with partitioning strategies
- Implement audit trails for sensitive data

### API Layer
- Follow RESTful conventions (resources, HTTP verbs, status codes)
- Consider GraphQL for complex data fetching requirements
- Version APIs from the start (`/api/v1/`)
- Document with OpenAPI/Swagger

### Frontend State
- Synchronize state with backend truth
- Implement optimistic updates with proper rollback
- Design caching strategy across all layers
- Maintain type safety from database to UI

### Real-time Data Flow
```
[Database] -> [Change Events] -> [Message Queue] -> [WebSocket Server] -> [Client]
                                                          |
                                                    [Presence/Status]
```

---

## Cross-Stack Authentication

### Session-Based Authentication
```typescript
// Backend: Express session setup
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    sameSite: 'strict',
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  },
  store: new RedisStore({ client: redisClient })
}));
```

### JWT Implementation
```typescript
// Token structure
interface TokenPayload {
  userId: string;
  roles: string[];
  permissions: string[];
  iat: number;
  exp: number;
}

// Access token: short-lived (15 min)
// Refresh token: longer-lived (7 days), stored in httpOnly cookie
```

### SSO Integration
- SAML 2.0 for enterprise integrations
- OAuth 2.0 / OpenID Connect for consumer apps
- Handle token exchange and session bridging

### Role-Based Access Control (RBAC)
```typescript
// Permission matrix
const permissions = {
  admin: ['read', 'write', 'delete', 'manage'],
  editor: ['read', 'write'],
  viewer: ['read']
};

// Middleware pattern
const requirePermission = (permission: string) => (req, res, next) => {
  if (!req.user.permissions.includes(permission)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  next();
};
```

### Frontend Route Protection
```typescript
// React Router protection
const ProtectedRoute = ({ children, requiredRole }) => {
  const { user, isLoading } = useAuth();

  if (isLoading) return <LoadingSpinner />;
  if (!user) return <Navigate to="/login" />;
  if (requiredRole && !user.roles.includes(requiredRole)) {
    return <Navigate to="/unauthorized" />;
  }

  return children;
};
```

### Database Row-Level Security
```sql
-- PostgreSQL RLS example
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY documents_access ON documents
  FOR ALL
  USING (
    owner_id = current_user_id()
    OR EXISTS (
      SELECT 1 FROM document_shares
      WHERE document_id = documents.id
      AND user_id = current_user_id()
    )
  );
```

---

## Real-Time Implementation

### WebSocket Server Configuration
```typescript
import { WebSocketServer } from 'ws';
import { verifyToken } from './auth';

const wss = new WebSocketServer({
  server: httpServer,
  verifyClient: async (info, callback) => {
    const token = info.req.headers['sec-websocket-protocol'];
    const user = await verifyToken(token);
    if (user) {
      info.req.user = user;
      callback(true);
    } else {
      callback(false, 401, 'Unauthorized');
    }
  }
});

// Connection handling with heartbeat
wss.on('connection', (ws, req) => {
  ws.isAlive = true;
  ws.userId = req.user.id;

  ws.on('pong', () => { ws.isAlive = true; });
  ws.on('message', (data) => handleMessage(ws, data));
});

// Heartbeat interval
setInterval(() => {
  wss.clients.forEach((ws) => {
    if (!ws.isAlive) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);
```

### Event-Driven Architecture
```typescript
// Event bus pattern
class EventBus {
  private handlers = new Map<string, Set<Function>>();

  subscribe(event: string, handler: Function) {
    if (!this.handlers.has(event)) {
      this.handlers.set(event, new Set());
    }
    this.handlers.get(event).add(handler);
    return () => this.handlers.get(event).delete(handler);
  }

  publish(event: string, payload: any) {
    this.handlers.get(event)?.forEach(handler => handler(payload));
  }
}
```

### Presence System
```typescript
interface PresenceState {
  userId: string;
  status: 'online' | 'away' | 'busy' | 'offline';
  lastSeen: Date;
  activeRoom?: string;
}

// Track presence with Redis
const updatePresence = async (userId: string, status: string) => {
  await redis.hset(`presence:${userId}`, {
    status,
    lastSeen: Date.now()
  });
  await redis.expire(`presence:${userId}`, 300); // 5 min TTL

  // Broadcast to subscribers
  pubsub.publish('presence-update', { userId, status });
};
```

### Conflict Resolution Strategies
- **Last-Write-Wins (LWW)**: Simple, good for low-conflict scenarios
- **Operational Transformation (OT)**: For collaborative editing
- **CRDTs**: For distributed systems needing eventual consistency
- **Application-Level Merge**: Custom logic based on domain rules

---

## Testing Strategy

### Unit Tests (Business Logic)
```typescript
// Backend: Test service layer
describe('OrderService', () => {
  it('should calculate total with tax', () => {
    const items = [{ price: 100, quantity: 2 }];
    const total = orderService.calculateTotal(items, 0.08);
    expect(total).toBe(216); // 200 + 16 tax
  });
});

// Frontend: Test utility functions
describe('formatCurrency', () => {
  it('should format USD correctly', () => {
    expect(formatCurrency(1234.56, 'USD')).toBe('$1,234.56');
  });
});
```

### Integration Tests
```typescript
// API endpoint tests
describe('POST /api/orders', () => {
  it('should create order and return 201', async () => {
    const response = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${testToken}`)
      .send({ items: [{ productId: 1, quantity: 2 }] });

    expect(response.status).toBe(201);
    expect(response.body.orderId).toBeDefined();
  });
});
```

### Component Tests
```typescript
// React Testing Library
describe('OrderForm', () => {
  it('should submit form with valid data', async () => {
    const onSubmit = jest.fn();
    render(<OrderForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText('Quantity'), '5');
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    expect(onSubmit).toHaveBeenCalledWith({ quantity: 5 });
  });
});
```

### End-to-End Tests
```typescript
// Playwright E2E
test('complete checkout flow', async ({ page }) => {
  await page.goto('/products');
  await page.click('[data-testid="add-to-cart-1"]');
  await page.click('[data-testid="checkout-button"]');

  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="card"]', '4242424242424242');
  await page.click('[data-testid="pay-button"]');

  await expect(page.locator('.order-confirmation')).toBeVisible();
});
```

### Performance Tests
```typescript
// k6 load testing
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% under 500ms
    http_req_failed: ['rate<0.01'],   // <1% errors
  },
};

export default function () {
  const res = http.get('https://api.example.com/products');
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
```

---

## Architecture Decisions

### Monorepo vs Polyrepo

| Factor | Monorepo | Polyrepo |
|--------|----------|----------|
| Code sharing | Easy | Requires publishing packages |
| CI/CD complexity | Single pipeline, selective builds | Multiple pipelines |
| Team coordination | Easier visibility | More autonomy |
| Tooling | Turborepo, Nx, Lerna | Standard Git |
| Best for | Related services, shared types | Independent teams |

### Shared Code Organization (Monorepo)
```
packages/
├── shared/
│   ├── types/          # TypeScript interfaces
│   ├── validation/     # Zod/Yup schemas
│   ├── utils/          # Common utilities
│   └── config/         # Shared configuration
├── api/
│   └── src/
├── web/
│   └── src/
└── mobile/
    └── src/
```

### API Gateway vs BFF

**API Gateway**: Single entry point, routing, auth
```
[Client] -> [API Gateway] -> [Service A]
                          -> [Service B]
```

**Backend for Frontend (BFF)**: Tailored APIs per client type
```
[Web Client] -> [Web BFF] -> [Services]
[Mobile]     -> [Mobile BFF] -> [Services]
```

### Microservices vs Monolith Decision Tree
1. Team size < 10? Consider monolith first
2. Need independent deployment? Microservices
3. Different scaling requirements? Microservices
4. Complex domain boundaries? Microservices
5. Limited DevOps capacity? Monolith

---

## Performance Optimization

### Database Query Optimization
```sql
-- Use EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123;

-- Add appropriate indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Composite index for common query patterns
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

### API Response Time
- Use database connection pooling
- Implement response caching (Redis)
- Enable gzip compression
- Use pagination for large datasets
- Return only needed fields (sparse fieldsets)

### Frontend Bundle Optimization
```javascript
// Dynamic imports for code splitting
const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

// Tree shaking - import only what you need
import { debounce } from 'lodash-es'; // Not: import _ from 'lodash'

// Analyze bundle
// npx webpack-bundle-analyzer stats.json
```

### Image and Asset Optimization
- Use modern formats (WebP, AVIF)
- Implement responsive images with srcset
- Lazy load below-the-fold images
- Use CDN for static assets
- Enable browser caching with proper headers

### Lazy Loading Implementation
```typescript
// React lazy loading
const HeavyComponent = lazy(() => import('./HeavyComponent'));

// Intersection Observer for data fetching
const useIntersectionObserver = (ref, callback) => {
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          callback();
          observer.disconnect();
        }
      },
      { threshold: 0.1 }
    );

    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [ref, callback]);
};
```

### Server-Side Rendering (SSR) Decisions
| Scenario | Recommendation |
|----------|----------------|
| SEO-critical pages | SSR or Static |
| User dashboards | Client-side |
| Marketing pages | Static generation |
| Real-time data | Client-side + hydration |
| Auth-protected | Client-side |

### Cache Invalidation Patterns
```typescript
// Cache-aside pattern
const getUser = async (userId: string) => {
  const cached = await cache.get(`user:${userId}`);
  if (cached) return JSON.parse(cached);

  const user = await db.users.findById(userId);
  await cache.setex(`user:${userId}`, 3600, JSON.stringify(user));
  return user;
};

// Write-through invalidation
const updateUser = async (userId: string, data: UserData) => {
  const user = await db.users.update(userId, data);
  await cache.del(`user:${userId}`);
  return user;
};
```

---

## Deployment Pipeline

### Infrastructure as Code
```yaml
# Terraform example
resource "aws_ecs_service" "api" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }
}
```

### CI/CD Pipeline Configuration
```yaml
# GitHub Actions example
name: Deploy
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: task-def.json
          service: api-service
          cluster: production
```

### Database Migration Automation
```typescript
// Prisma migration workflow
// 1. Create migration: npx prisma migrate dev --name add_user_roles
// 2. Apply in CI: npx prisma migrate deploy

// Migration safety checks
// - Always make additive changes first
// - Never drop columns in production without deprecation period
// - Use transactions for data migrations
```

### Feature Flag Implementation
```typescript
interface FeatureFlags {
  newCheckoutFlow: boolean;
  experimentalSearch: boolean;
  darkMode: boolean;
}

const useFeatureFlag = (flag: keyof FeatureFlags): boolean => {
  const { flags } = useContext(FeatureFlagContext);
  return flags[flag] ?? false;
};

// Usage
const CheckoutButton = () => {
  const useNewFlow = useFeatureFlag('newCheckoutFlow');
  return useNewFlow ? <NewCheckout /> : <LegacyCheckout />;
};
```

### Blue-Green Deployment
```
[Load Balancer]
      |
      v
[Blue (Current)] ← Active traffic
[Green (New)]    ← Staged, tested
      |
      v
[Switch traffic to Green]
[Keep Blue as rollback]
```

### Rollback Procedures
1. **Automated rollback**: If health checks fail, revert automatically
2. **Database rollback**: Keep migrations reversible
3. **Feature flag rollback**: Disable flags remotely
4. **Version rollback**: Deploy previous container image

### Monitoring Integration
```typescript
// OpenTelemetry setup
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  serviceName: 'api-service',
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();

// Custom metrics
import { metrics } from '@opentelemetry/api';
const meter = metrics.getMeter('api');
const requestCounter = meter.createCounter('http_requests_total');

app.use((req, res, next) => {
  requestCounter.add(1, { method: req.method, path: req.path });
  next();
});
```

---

## Technology Selection Matrix

### Frontend Framework
| Factor | React | Vue | Svelte | Next.js |
|--------|-------|-----|--------|---------|
| Learning curve | Medium | Low | Low | Medium |
| Ecosystem | Excellent | Good | Growing | Excellent |
| Performance | Good | Good | Excellent | Good |
| SSR support | Manual | Nuxt | SvelteKit | Built-in |
| Best for | Large apps | Progressive adoption | Performance-critical | Full-stack |

### Backend Language
| Factor | Node.js | Python | Go | Rust |
|--------|---------|--------|----|----|
| Performance | Good | Medium | Excellent | Excellent |
| Ecosystem | Excellent | Excellent | Good | Growing |
| Learning curve | Low | Low | Medium | High |
| Async model | Event loop | Async/await | Goroutines | Async/await |
| Best for | Real-time | ML/Data | High concurrency | Systems |

### Database Technology
| Type | Options | Best For |
|------|---------|----------|
| Relational | PostgreSQL, MySQL | Structured data, ACID |
| Document | MongoDB, CouchDB | Flexible schema, JSON |
| Key-Value | Redis, DynamoDB | Caching, sessions |
| Graph | Neo4j, Neptune | Relationships |
| Time-Series | TimescaleDB, InfluxDB | Metrics, IoT |

---

## Integration Patterns

### API Client Generation
```typescript
// OpenAPI Generator
// npx openapi-generator-cli generate -i api.yaml -g typescript-fetch -o ./client

// Type-safe client usage
import { OrdersApi, Configuration } from './client';

const api = new OrdersApi(new Configuration({
  basePath: process.env.API_URL,
  accessToken: () => getAccessToken(),
}));

const orders = await api.getOrders({ status: 'pending' });
```

### Error Boundary Implementation
```typescript
class ErrorBoundary extends Component<Props, State> {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    errorReportingService.captureException(error, { extra: errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

### Loading State Management
```typescript
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

const useAsyncData = <T>(fetcher: () => Promise<T>): AsyncState<T> => {
  const [state, setState] = useState<AsyncState<T>>({ status: 'idle' });

  useEffect(() => {
    setState({ status: 'loading' });
    fetcher()
      .then(data => setState({ status: 'success', data }))
      .catch(error => setState({ status: 'error', error }));
  }, [fetcher]);

  return state;
};
```

### Optimistic Update Handling
```typescript
const useOptimisticUpdate = <T>(
  mutationFn: (data: T) => Promise<T>,
  onSuccess: (data: T) => void,
  onError: (error: Error, rollback: T) => void
) => {
  const [isLoading, setIsLoading] = useState(false);

  const mutate = async (newData: T, previousData: T) => {
    setIsLoading(true);
    onSuccess(newData); // Optimistic update

    try {
      const result = await mutationFn(newData);
      onSuccess(result); // Confirm with server data
    } catch (error) {
      onError(error as Error, previousData); // Rollback
    } finally {
      setIsLoading(false);
    }
  };

  return { mutate, isLoading };
};
```

### Offline Capability
```typescript
// Service Worker for offline support
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      if (response) return response;

      return fetch(event.request).then((networkResponse) => {
        if (networkResponse.ok) {
          const clone = networkResponse.clone();
          caches.open('v1').then((cache) => {
            cache.put(event.request, clone);
          });
        }
        return networkResponse;
      }).catch(() => caches.match('/offline.html'));
    })
  );
});
```

---

> **Related Skill:** For AI-powered features in fullstack apps, see `/home/rodo/.claude/skills/prompt-engineering/SKILL.md`
