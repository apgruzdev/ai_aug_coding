# Python Typing — Worked Examples

Reference companion to `SKILL.md`. Examples are grouped by PEP. Each block is self-contained and uses modern (Python ≥ 3.12) syntax unless explicitly contrasted with legacy.

---

## PEP 585 — Built-in collections as generics

```python
# Modern (3.9+):
def find(haystack: dict[str, list[int]]) -> int: ...

users: list[User] = []
counts: dict[str, int] = {}
point: tuple[float, float] = (0.0, 0.0)
labels: set[str] = set()
exact_triple: tuple[int, str, bool] = (1, "x", True)
arbitrary_ints: tuple[int, ...] = (1, 2, 3, 4)
empty_tuple: tuple[()] = ()

# Abstract types from collections.abc (NOT typing):
from collections.abc import Iterable, Iterator, Mapping, Callable, Awaitable

def total(values: Iterable[int]) -> int:
    return sum(values)

def index_of[T](haystack: Iterable[T], needle: T) -> int | None: ...
```

```python
# Legacy (pre-3.9) — avoid in new code:
from typing import Dict, List, Tuple, Set
def find(haystack: Dict[str, List[int]]) -> int: ...
```

Parameterized generics preserve their type info at runtime (`list[str].__origin__ is list`, `list[str].__args__ == (str,)`), but `isinstance(obj, list[str])` raises `TypeError` — use `isinstance(obj, list)` and narrow further if needed.

---

## PEP 604 — Union with `|`

```python
# Modern (3.10+):
def parse(value: int | str | None) -> float | str: ...

x: int | None = None
items: list[int | str] = [1, "two", 3]
mapping: dict[str, int | float] = {"a": 1, "b": 2.5}

# Optional[T] is just T | None:
def get_user(uid: int) -> User | None: ...

# isinstance works:
if isinstance(value, int | str):
    ...

# But parameterized generics inside | still fail at runtime in isinstance:
# isinstance(x, list[int] | dict[str, int])  # TypeError
```

```python
# Legacy:
from typing import Union, Optional
def parse(value: Union[int, str, None]) -> Union[float, str]: ...
def get_user(uid: int) -> Optional[User]: ...
```

Order doesn't matter for equality: `int | str == str | int == Union[int, str]`.

---

## PEP 526 — Variable annotations

### Module / local

```python
# With initial value:
primes: list[int] = []
captain: str = 'Picard'

# Without initial value — declares the type for the checker; reading raises NameError:
some_number: int
if 2 + 2 == 4:
    some_number = 4

# Annotating a local forces it to be local for the whole function:
def f() -> None:
    a: int           # checker sees `a` as int and as "possibly unbound"
    print(a)         # UnboundLocalError at runtime; checker flags use-before-assignment
```

### Class and instance variables

```python
from typing import ClassVar

class Starship:
    captain: str = 'Picard'                 # instance attribute, with default
    damage: int                             # instance attribute, set in __init__
    stats: ClassVar[dict[str, int]] = {}    # truly class-level (shared)

    def __init__(self, damage: int, captain: str | None = None) -> None:
        self.damage = damage
        if captain is not None:
            self.captain = captain

    def hit(self) -> None:
        Starship.stats['hits'] = Starship.stats.get('hits', 0) + 1
```

`enterprise.stats = {}` would be flagged by a checker (assigning to a `ClassVar` via an instance). `Starship.stats = {}` is fine.

### Style

```python
# YES
x: int
y: int = 0
class P:
    coords: tuple[int, int]
    label: str = '<unknown>'

# NO
x:int             # missing space after :
x : int           # extra space before :
x: int=0          # missing spaces around =
```

### What you cannot do

```python
x, y: int               # SyntaxError — no tuple-unpacking annotations
x: int = y = 1          # disallowed — no chained-assignment annotations
for i: int in range(5): # disallowed — no for-target annotations
    ...
with open(p) as f: int: # disallowed — no with-target annotations
    ...
def g():
    global x: int       # SyntaxError
```

Annotate ahead instead:

```python
x: int
y: int
x, y = pair  # OK

i: int
for i in range(5):
    ...
```

---

## PEP 695 — Modern generics (Python 3.12+)

### Generic functions

```python
from collections.abc import Sequence

# T is scoped to this function; no module-level TypeVar needed
def first[T](items: Sequence[T]) -> T:
    return items[0]

def pair[A, B](a: A, b: B) -> tuple[A, B]:
    return (a, b)
```

Legacy equivalent (still valid for older Python):

```python
from typing import TypeVar
T = TypeVar('T')

def first(items: Sequence[T]) -> T:
    return items[0]
```

### Generic classes

```python
class Box[T]:
    def __init__(self, value: T) -> None:
        self.value = value

    def get(self) -> T:
        return self.value

class Pair[K, V]:
    def __init__(self, key: K, value: V) -> None:
        self.key = key
        self.value = value
```

`class Box[T](Generic[T])` is a **runtime error** — `Generic` is implied.

### Bounded type parameters

```python
from collections.abc import Sized

def longer[T: Sized](a: T, b: T) -> T:
    return a if len(a) >= len(b) else b

# Bound can be a quoted forward reference:
class Tree[T: "Comparable"]: ...
```

### Constrained type parameters

```python
# T must be exactly str or exactly bytes — no other types, no subclass leakage
def concat[S: (str, bytes)](x: S, y: S) -> S:
    return x + y

concat("a", "b")        # OK, S=str
concat(b"a", b"b")      # OK, S=bytes
# concat("a", b"b")     # type error
```

### Variadic and ParamSpec

```python
from collections.abc import Callable

class Tensor[*Shape]: ...                  # variadic generic (PEP 646)

def trace[**P, R](fn: Callable[P, R]) -> Callable[P, R]:
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        print(f"calling {fn.__name__}")
        return fn(*args, **kwargs)
    return wrapper
```

### Type aliases via `type` statement

```python
type Vector[T] = list[tuple[T, T]]
type IntOrStr = int | str

# Recursive — RHS is lazily evaluated, no quotes needed
type JSON = None | bool | int | float | str | list[JSON] | dict[str, JSON]
type RecursiveList[T] = T | list[RecursiveList[T]]
```

Legacy:

```python
from typing import TypeAlias, TypeVar
T = TypeVar('T')
Vector: TypeAlias = list[tuple[T, T]]
```

### Variance is inferred

```python
# No need to declare covariant=True / contravariant=True.
# The checker infers variance from how T appears in the class body.
class ReadOnlyBox[T]:           # inferred covariant — T only in return positions
    def __init__(self, value: T) -> None:
        self._value = value
    def get(self) -> T:
        return self._value

class Sink[T]:                  # inferred contravariant — T only in argument positions
    def push(self, value: T) -> None: ...

class MutableBox[T]:            # inferred invariant — T in both positions
    def get(self) -> T: ...
    def set(self, value: T) -> None: ...
```

---

## PEP 544 — Protocols (structural typing)

### Basic protocol

```python
from typing import Protocol
from collections.abc import Iterable

class SupportsClose(Protocol):
    def close(self) -> None: ...

class Resource:                 # no `SupportsClose` base — structurally matches
    def close(self) -> None:
        self.file.close()

def close_all(items: Iterable[SupportsClose]) -> None:
    for item in items:
        item.close()

close_all([open('a.txt'), Resource()])  # OK
```

### Protocol attributes (PEP 526 syntax in the body)

```python
class HasName(Protocol):
    name: str                    # protocol attribute (read-write by default)
    value: int = 0               # with default

class Point:
    def __init__(self, name: str) -> None:
        self.name = name
        self.value = 42
```

Attributes assigned only via `self.foo` inside a method body are NOT protocol members. For a read-only attribute, use a `@property`.

### Generic protocols (PEP 695 style)

```python
class Comparable[T](Protocol):
    def __lt__(self, other: T) -> bool: ...

def minimum[T: Comparable[T]](items: Iterable[T]) -> T:
    it = iter(items)
    result = next(it)
    for item in it:
        if item < result:
            result = item
    return result
```

### Callback protocols

For callables that `Callable[[...], ...]` cannot express (keyword args, overloads, variadics):

```python
class Combiner(Protocol):
    def __call__(self, *vals: bytes, maxlen: int | None = None) -> list[bytes]: ...

def good_cb(*vals: bytes, maxlen: int | None = None) -> list[bytes]: ...
def bad_cb(*vals: bytes, maxitems: int | None) -> list[bytes]: ...

f: Combiner = good_cb  # OK
# f = bad_cb           # error — kwarg name differs
```

### Self-types in protocols

```python
from typing import Self    # 3.11+

class Copyable(Protocol):
    def copy(self) -> Self: ...

class Document:
    def copy(self) -> "Document":
        ...
        return Document()

d: Copyable = Document()  # OK
```

### `@runtime_checkable`

Only when you really need `isinstance`:

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class SupportsClose(Protocol):
    def close(self) -> None: ...

assert isinstance(open('a.txt'), SupportsClose)
```

Caveat: `isinstance` only checks for attribute presence, not signatures. Data attributes set after `__init__` may not be visible to `isinstance` until they exist.

### Modules as protocol implementations

```python
# default_config.py
timeout = 100
one_flag = True

# main.py
import default_config
from typing import Protocol

class Options(Protocol):
    timeout: int
    one_flag: bool

def setup(options: Options) -> None: ...
setup(default_config)  # OK — module satisfies the protocol structurally
```

---

## PEP 484 — Remaining essentials

### `Any`, `object`, `Never`

```python
from typing import Any, Never

def log(value: Any) -> None: ...      # accept and produce anything
def inspect(value: object) -> None: ...  # accept anything but can only call object's methods

def crash(msg: str) -> Never:         # function never returns normally
    raise RuntimeError(msg)
```

### `Literal`

```python
from typing import Literal

def open_mode(mode: Literal["r", "w", "a"]) -> None: ...

open_mode("r")    # OK
# open_mode("x")  # type error
```

### `Final`

```python
from typing import Final

MAX_RETRIES: Final = 3
API_URL: Final[str] = "https://example.com"

class Config:
    name: Final[str] = "default"
```

### `cast`

```python
from typing import cast

def find_first_str(items: list[object]) -> str:
    idx = next(i for i, x in enumerate(items) if isinstance(x, str))
    return cast(str, items[idx])      # checker now trusts the type
```

### `NewType`

```python
from typing import NewType

UserId = NewType('UserId', int)

def get_user(uid: UserId) -> User: ...

get_user(UserId(42))   # OK
# get_user(42)         # type error — bare int is not a UserId
total: int = UserId(5) + 1   # OK — UserId is a subtype of int
```

### `TYPE_CHECKING`

Break import cycles and avoid runtime cost for typing-only imports:

```python
from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from expensive_module import ExpensiveClass

def process(value: ExpensiveClass) -> None: ...
```

### `@overload`

```python
from typing import overload

@overload
def get(key: str) -> str: ...
@overload
def get(key: str, default: T) -> str | T: ...

def get(key, default=None):           # actual implementation, not annotated
    ...
```

In `.pyi` stubs the actual implementation is omitted; in regular modules it must follow the overload stubs.

### Generators and coroutines

```python
from collections.abc import Generator, Iterator, AsyncIterator

def count(n: int) -> Iterator[int]:           # generator that only yields
    for i in range(n):
        yield i

def echo() -> Generator[int, float, str]:     # yield int, receive float via send(), return str
    res = yield 0
    while res:
        res = yield round(res)
    return "done"

async def fetch(url: str) -> str: ...         # annotate the awaited value, not Coroutine[...]

async def stream() -> AsyncIterator[bytes]:
    yield b"chunk"
```

### Stub file (`.pyi`)

```python
# mylib.pyi
from collections.abc import Iterable

BUFFER_SIZE: int

class Client:
    host: str
    port: int
    def __init__(self, host: str, port: int = ...) -> None: ...
    def send(self, data: bytes) -> int: ...
    def stream(self) -> Iterable[bytes]: ...
```

---

## Migration cheat-sheet (legacy → modern)

| Legacy                              | Modern                          |
| ----------------------------------- | ------------------------------- |
| `List[int]`                         | `list[int]`                     |
| `Dict[str, int]`                    | `dict[str, int]`                |
| `Tuple[int, ...]`                   | `tuple[int, ...]`               |
| `Tuple[int, str]`                   | `tuple[int, str]`               |
| `Set[str]`                          | `set[str]`                      |
| `FrozenSet[int]`                    | `frozenset[int]`                |
| `Type[User]`                        | `type[User]`                    |
| `typing.Iterable[int]`              | `collections.abc.Iterable[int]` |
| `typing.Callable[[int], str]`       | `collections.abc.Callable[[int], str]` |
| `Optional[int]`                     | `int \| None`                   |
| `Union[int, str]`                   | `int \| str`                    |
| `T = TypeVar('T'); def f(x: T) -> T` | `def f[T](x: T) -> T`          |
| `class C(Generic[T])`               | `class C[T]:`                   |
| `Foo: TypeAlias = list[int]`        | `type Foo = list[int]`          |

When in doubt, run `pyupgrade --py312-plus` or equivalent to mechanically convert.
