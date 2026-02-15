# Code Review Skill

Comprehensive technical knowledge for thorough code reviews covering completeness, security, performance, and best practices.

---

## Security Analysis Deep Dive

### OWASP Top 10 Checklist

#### 1. Injection (SQL, NoSQL, Command, LDAP)
```python
# VULNERABLE
query = f"SELECT * FROM users WHERE id = {user_id}"  # SQL injection
os.system(f"ls {user_input}")  # Command injection

# SECURE
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
subprocess.run(["ls", user_input], check=True, shell=False)
```

**Review checks:**
- [ ] All SQL uses parameterized queries or ORM
- [ ] No string concatenation with user input in queries
- [ ] Shell commands use subprocess with shell=False
- [ ] LDAP queries use proper escaping

#### 2. Broken Authentication
```javascript
// VULNERABLE
const token = jwt.sign({ userId }, secret);  // No expiration

// SECURE
const token = jwt.sign({ userId }, secret, {
  expiresIn: '15m',
  issuer: 'your-app',
  audience: 'your-users'
});
```

**Review checks:**
- [ ] Tokens have expiration times
- [ ] Passwords use bcrypt/argon2 with appropriate cost factor
- [ ] Session tokens are regenerated on login
- [ ] Multi-factor authentication for sensitive operations
- [ ] Account lockout after failed attempts

#### 3. Sensitive Data Exposure
```python
# VULNERABLE
logger.info(f"User {user.email} logged in with password {password}")
response = {"user": user.__dict__}  # May include password hash

# SECURE
logger.info(f"User {user.id} logged in")
response = {"user": user.to_safe_dict()}  # Explicit safe fields
```

**Review checks:**
- [ ] Secrets not logged or exposed in errors
- [ ] API responses exclude sensitive fields
- [ ] Data encrypted at rest and in transit
- [ ] Proper data masking in logs

#### 4. XML External Entities (XXE)
```python
# VULNERABLE
from lxml import etree
tree = etree.parse(user_file)  # Allows external entities

# SECURE
parser = etree.XMLParser(resolve_entities=False, no_network=True)
tree = etree.parse(user_file, parser)
```

**Review checks:**
- [ ] XML parsing disables external entities
- [ ] DTD processing disabled
- [ ] Use JSON instead of XML where possible

#### 5. Broken Access Control
```python
# VULNERABLE
@app.route('/documents/<doc_id>')
def get_document(doc_id):
    return Document.query.get(doc_id)  # No ownership check

# SECURE
@app.route('/documents/<doc_id>')
@login_required
def get_document(doc_id):
    doc = Document.query.get_or_404(doc_id)
    if doc.owner_id != current_user.id and not current_user.is_admin:
        abort(403)
    return doc
```

**Review checks:**
- [ ] Authorization checked on every request
- [ ] Direct object references validated against user
- [ ] Role/permission checks at controller level
- [ ] Default deny for new endpoints

#### 6. Security Misconfiguration
```yaml
# VULNERABLE nginx config
server {
    listen 80;
    server_tokens on;  # Exposes version
}

# SECURE
server {
    listen 443 ssl;
    server_tokens off;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
}
```

**Review checks:**
- [ ] Debug mode disabled in production
- [ ] Security headers configured
- [ ] Unnecessary features/endpoints disabled
- [ ] Default credentials changed

#### 7. Cross-Site Scripting (XSS)
```javascript
// VULNERABLE
element.innerHTML = userInput;  // Stored/Reflected XSS
document.write(location.hash);  // DOM-based XSS

// SECURE
element.textContent = userInput;
// Or use DOMPurify
element.innerHTML = DOMPurify.sanitize(userInput);
```

**Review checks:**
- [ ] User input HTML-escaped before rendering
- [ ] CSP headers configured
- [ ] React/Vue auto-escaping not bypassed (dangerouslySetInnerHTML)
- [ ] URL parameters validated before use

#### 8. Insecure Deserialization
```python
# VULNERABLE
data = pickle.loads(user_data)  # Arbitrary code execution

# SECURE
data = json.loads(user_data)  # Only data, no code execution
# Or use safe_load for YAML
data = yaml.safe_load(user_yaml)
```

**Review checks:**
- [ ] No pickle/marshal on untrusted data
- [ ] YAML uses safe_load
- [ ] JSON preferred for serialization
- [ ] Signature verification on serialized data

#### 9. Using Components with Known Vulnerabilities
```bash
# Check for vulnerabilities
npm audit
pip-audit
snyk test
```

**Review checks:**
- [ ] Dependencies up to date
- [ ] No known CVEs in dependencies
- [ ] Lock files committed
- [ ] Automated vulnerability scanning in CI

#### 10. Insufficient Logging & Monitoring
```python
# GOOD logging practice
logger.info("Login successful", extra={
    "user_id": user.id,
    "ip": request.remote_addr,
    "user_agent": request.headers.get("User-Agent")
})

logger.warning("Failed login attempt", extra={
    "email": email,  # OK to log since it's the attempt
    "ip": request.remote_addr,
    "reason": "invalid_password"
})
```

**Review checks:**
- [ ] Authentication events logged
- [ ] Authorization failures logged
- [ ] Input validation failures logged
- [ ] Logs don't contain sensitive data
- [ ] Alerting on suspicious patterns

---

## Performance Analysis Patterns

### Time Complexity Issues

| Pattern | Problem | Solution |
|---------|---------|----------|
| Nested loops over same data | O(n²) | Use hash map O(n) |
| Repeated array searches | O(n) per search | Build index first |
| String concatenation in loop | O(n²) for strings | Use StringBuilder/join |
| Recursive without memoization | Exponential | Add memoization |

```python
# O(n²) - SLOW
def find_pairs(arr, target):
    pairs = []
    for i, a in enumerate(arr):
        for j, b in enumerate(arr):
            if i != j and a + b == target:
                pairs.append((a, b))
    return pairs

# O(n) - FAST
def find_pairs(arr, target):
    pairs = []
    seen = set()
    for num in arr:
        complement = target - num
        if complement in seen:
            pairs.append((complement, num))
        seen.add(num)
    return pairs
```

### Database Query Optimization

#### N+1 Query Problem
```python
# N+1 PROBLEM - 1 + N queries
users = User.query.all()
for user in users:
    print(user.posts)  # Each access triggers a query

# FIXED - 1 query with eager loading
users = User.query.options(joinedload(User.posts)).all()
for user in users:
    print(user.posts)  # Already loaded
```

#### Missing Indexes
```sql
-- SLOW: Full table scan
SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';

-- Check with EXPLAIN
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123 AND status = 'pending';

-- ADD INDEX
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

#### Query Optimization Patterns
```sql
-- AVOID: SELECT *
SELECT * FROM users WHERE id = 1;

-- BETTER: Select only needed columns
SELECT id, name, email FROM users WHERE id = 1;

-- AVOID: LIKE with leading wildcard
SELECT * FROM products WHERE name LIKE '%phone%';

-- BETTER: Full-text search or index suffix
CREATE INDEX idx_products_name_reverse ON products(REVERSE(name));
```

### Memory Leak Patterns

```javascript
// LEAK: Event listeners not removed
class Component {
  mount() {
    window.addEventListener('resize', this.handleResize);
  }
  // Missing: unmount() to remove listener
}

// FIXED
class Component {
  mount() {
    this.handleResize = this.handleResize.bind(this);
    window.addEventListener('resize', this.handleResize);
  }
  unmount() {
    window.removeEventListener('resize', this.handleResize);
  }
}

// LEAK: Closures holding references
function createHandler(largeData) {
  return function() {
    // largeData is retained even if not used
    console.log('clicked');
  };
}

// FIXED: Don't capture unnecessary data
function createHandler() {
  return function() {
    console.log('clicked');
  };
}
```

### Async/Await Patterns

```javascript
// SLOW: Sequential when could be parallel
async function loadData() {
  const users = await fetchUsers();       // Wait
  const products = await fetchProducts(); // Then wait
  const orders = await fetchOrders();     // Then wait
  return { users, products, orders };
}

// FAST: Parallel execution
async function loadData() {
  const [users, products, orders] = await Promise.all([
    fetchUsers(),
    fetchProducts(),
    fetchOrders()
  ]);
  return { users, products, orders };
}

// CORRECT: Sequential when dependent
async function processOrder(userId) {
  const user = await fetchUser(userId);        // Need user first
  const cart = await fetchCart(user.cartId);   // Then cart
  const order = await createOrder(user, cart); // Then order
  return order;
}
```

### Caching Opportunities

```python
# NO CACHING - Repeated expensive computation
def get_user_stats(user_id):
    # This hits DB every time
    return compute_expensive_stats(user_id)

# WITH CACHING
from functools import lru_cache

@lru_cache(maxsize=100)
def get_user_stats(user_id):
    return compute_expensive_stats(user_id)

# WITH REDIS for distributed caching
def get_user_stats(user_id):
    cache_key = f"user_stats:{user_id}"
    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)

    stats = compute_expensive_stats(user_id)
    redis.setex(cache_key, 3600, json.dumps(stats))  # 1 hour TTL
    return stats
```

---

## Language-Specific Patterns

### JavaScript/TypeScript

```typescript
// TYPE SAFETY
// BAD: any defeats the purpose
function process(data: any) { ... }

// GOOD: Proper typing
interface UserData {
  id: number;
  name: string;
  email: string;
}
function process(data: UserData) { ... }

// ASYNC/AWAIT
// BAD: Mixing callbacks and promises
async function getData() {
  return new Promise((resolve, reject) => {
    fetchData((err, data) => {  // Callback inside promise
      if (err) reject(err);
      else resolve(data);
    });
  });
}

// GOOD: Consistent async/await or promisify
import { promisify } from 'util';
const fetchDataAsync = promisify(fetchData);
async function getData() {
  return await fetchDataAsync();
}

// ERROR HANDLING
// BAD: Swallowing errors
try {
  await riskyOperation();
} catch (e) {
  // Silent failure
}

// GOOD: Proper error handling
try {
  await riskyOperation();
} catch (error) {
  logger.error('Operation failed', { error: error.message, stack: error.stack });
  throw new ApplicationError('Operation failed', { cause: error });
}
```

### Python

```python
# PEP 8 COMPLIANCE
# BAD
def myFunction(x,y): return x+y

# GOOD
def my_function(x: int, y: int) -> int:
    return x + y

# CONTEXT MANAGERS
# BAD: Manual resource management
f = open('file.txt')
data = f.read()
f.close()  # May not run on exception

# GOOD: Context manager
with open('file.txt') as f:
    data = f.read()

# TYPE HINTS
# BAD: No type information
def process_users(users):
    return [u.name for u in users]

# GOOD: Full type hints
from typing import List
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str

def process_users(users: List[User]) -> List[str]:
    return [u.name for u in users]

# PYTHONIC IDIOMS
# BAD
result = []
for item in items:
    if item.active:
        result.append(item.name)

# GOOD
result = [item.name for item in items if item.active]
```

### Go

```go
// ERROR HANDLING
// BAD: Ignoring errors
result, _ := riskyOperation()

// GOOD: Handle all errors
result, err := riskyOperation()
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}

// GOROUTINE SAFETY
// BAD: Race condition
var counter int
for i := 0; i < 100; i++ {
    go func() {
        counter++  // Race condition
    }()
}

// GOOD: Use mutex or atomic
var counter int64
for i := 0; i < 100; i++ {
    go func() {
        atomic.AddInt64(&counter, 1)
    }()
}

// INTERFACE DESIGN
// BAD: Large interface
type Repository interface {
    Create(entity Entity) error
    Read(id string) (Entity, error)
    Update(entity Entity) error
    Delete(id string) error
    List() ([]Entity, error)
    Search(query string) ([]Entity, error)
    // ... 20 more methods
}

// GOOD: Small, focused interfaces
type Reader interface {
    Read(id string) (Entity, error)
}

type Writer interface {
    Create(entity Entity) error
    Update(entity Entity) error
    Delete(id string) error
}
```

### Rust

```rust
// OWNERSHIP
// BAD: Unnecessary clone
fn process(data: Vec<String>) {
    let cloned = data.clone();  // Expensive, often unnecessary
    // ...
}

// GOOD: Borrow when possible
fn process(data: &[String]) {
    // Works with borrowed data
}

// LIFETIME ISSUES
// BAD: Fighting the borrow checker
fn get_first<'a>(list: &'a Vec<String>) -> &'a str {
    &list[0]  // Panic if empty
}

// GOOD: Return Option
fn get_first(list: &[String]) -> Option<&str> {
    list.first().map(|s| s.as_str())
}

// UNSAFE USAGE
// BAD: Unnecessary unsafe
unsafe fn add(a: i32, b: i32) -> i32 {
    a + b  // No unsafe operations
}

// GOOD: Only use unsafe when necessary, document why
/// # Safety
/// Caller must ensure ptr is valid and aligned
unsafe fn dereference(ptr: *const i32) -> i32 {
    *ptr
}
```

### SQL

```sql
-- INJECTION PREVENTION
-- BAD: String concatenation
EXECUTE 'SELECT * FROM users WHERE id = ' || user_input;

-- GOOD: Parameterized query
PREPARE stmt AS SELECT * FROM users WHERE id = $1;
EXECUTE stmt(user_input);

-- QUERY OPTIMIZATION
-- BAD: Correlated subquery
SELECT *,
    (SELECT COUNT(*) FROM orders WHERE orders.user_id = users.id) as order_count
FROM users;

-- GOOD: JOIN with aggregation
SELECT users.*, COALESCE(order_counts.count, 0) as order_count
FROM users
LEFT JOIN (
    SELECT user_id, COUNT(*) as count
    FROM orders
    GROUP BY user_id
) order_counts ON users.id = order_counts.user_id;

-- INDEX USAGE
-- Check if indexes are used
EXPLAIN ANALYZE SELECT * FROM orders
WHERE created_at > '2024-01-01' AND status = 'pending';
```

---

## Code Smell Detection

### Common Code Smells

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| Long Method | > 30 lines | Extract methods |
| Large Class | > 500 lines | Split responsibilities |
| Long Parameter List | > 4 params | Use object/builder |
| Duplicate Code | Copy-paste patterns | Extract shared function |
| Feature Envy | Method uses other class's data | Move method |
| Data Clumps | Same groups of parameters | Create class |
| Primitive Obsession | Using primitives for domain concepts | Create value objects |
| Switch Statements | Long switch on type | Use polymorphism |
| Parallel Inheritance | Adding class requires adding to another hierarchy | Merge hierarchies |
| Comments | Excessive comments explaining code | Improve naming/structure |

### Detection Examples

```python
# LONG PARAMETER LIST
# BAD
def create_user(first_name, last_name, email, phone, address, city, country, zip_code, role):
    ...

# GOOD
@dataclass
class UserCreateRequest:
    first_name: str
    last_name: str
    email: str
    phone: str
    address: Address
    role: str

def create_user(request: UserCreateRequest):
    ...

# FEATURE ENVY
# BAD - Order is too interested in Customer's data
class Order:
    def calculate_discount(self):
        if self.customer.loyalty_points > 100:
            if self.customer.membership == 'gold':
                return self.total * 0.2
            return self.total * 0.1
        return 0

# GOOD - Move to Customer or create service
class Customer:
    def get_discount_rate(self) -> float:
        if self.loyalty_points > 100:
            return 0.2 if self.membership == 'gold' else 0.1
        return 0

class Order:
    def calculate_discount(self):
        return self.total * self.customer.get_discount_rate()
```

---

## Review Output Templates

### Summary Template
```markdown
## Code Review Summary

**Overall Assessment:** [Approve / Request Changes / Needs Discussion]

**Quality Score:** X/10

**Key Findings:**
- [Critical issue or highlight]
- [Important observation]
- [Notable pattern]

**Scope Reviewed:**
- Files: X
- Lines changed: Y
```

### Issue Template
```markdown
### [CRITICAL/HIGH/MEDIUM/LOW] - [Issue Title]

**Location:** `file.py:42-50`

**Problem:**
[Description of the issue]

**Current Code:**
```python
vulnerable_code_here()
```

**Suggested Fix:**
```python
secure_code_here()
```

**Why This Matters:**
[Explanation of impact]
```

### Approval Template
```markdown
## Approved

**Reviewed:** All changes in PR #123

**Verified:**
- [x] Security considerations addressed
- [x] Error handling appropriate
- [x] Tests cover critical paths
- [x] Documentation updated

**Notes:**
- [Optional minor suggestions]
```

---

## Review Checklist by Context

### API Endpoint Review
- [ ] Authentication required and validated
- [ ] Authorization checked for resources
- [ ] Input validation on all parameters
- [ ] Rate limiting configured
- [ ] Error responses don't leak information
- [ ] Appropriate HTTP status codes
- [ ] Response schema documented

### Database Migration Review
- [ ] Migration is reversible
- [ ] No data loss scenarios
- [ ] Indexes added for new queries
- [ ] Large table changes are batched
- [ ] Constraints validated
- [ ] Tested with production-size data

### Frontend Component Review
- [ ] Props properly typed
- [ ] Loading/error states handled
- [ ] Accessibility (a11y) considered
- [ ] Memory leaks prevented (cleanup)
- [ ] No XSS vulnerabilities
- [ ] Responsive design tested
- [ ] Performance impact assessed

### Security-Critical Change Review
- [ ] Threat modeling performed
- [ ] All OWASP Top 10 considered
- [ ] Secrets management appropriate
- [ ] Audit logging added
- [ ] Security team consulted
- [ ] Penetration testing planned

---

> **Related Skill:** For fullstack review patterns, see `/home/rodo/.claude/skills/fullstack-development/SKILL.md`
