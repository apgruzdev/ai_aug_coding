# Examples — `python-features`

Working code samples for PEP 257, 634, and 654. All examples are adapted from the source PEPs and have been verified to be syntactically correct under the relevant Python version. Read the section matching the feature you're writing.

---

## Docstrings (PEP 257)

### One-line docstring — imperative mood

```python
def kos_root():
    """Return the pathname of the KOS root directory."""
    global _kos_root
    if _kos_root:
        return _kos_root
    ...
```

Closing quote on the same line. No blank lines around it. Imperative (`Return ...`, not `Returns ...`). Don't restate the signature.

### Don't do this — signature reiteration

```python
def function(a, b):
    """function(a, b) -> list"""        # BAD — restates signature
```

The preferred form names the effect and return type:

```python
def function(a, b):
    """Do X and return a list."""
```

### Multi-line function docstring

```python
def complex(real=0.0, imag=0.0):
    """Form a complex number.

    Keyword arguments:
    real -- the real part (default 0.0)
    imag -- the imaginary part (default 0.0)
    """
    if imag == 0.0 and real == 0.0:
        return complex_zero
    ...
```

Summary line, blank line, body. Closing `"""` on its own line.

### Class with docstring and constructor docstring

```python
class Vehicle:
    """Represent a vehicle with a position and heading.

    Public methods:
        move(distance) -- advance along the current heading
        turn(degrees)  -- rotate the heading clockwise

    Instance variables:
        position -- (x, y) tuple
        heading  -- degrees clockwise from north
    """

    def __init__(self, position=(0, 0), heading=0):
        """Initialize position to (0, 0) and heading to 0 by default."""
        self.position = position
        self.heading = heading
```

Insert a blank line after the class docstring (between it and the first method).

### Override vs extend in a subclass docstring

```python
class Bicycle(Vehicle):
    """A vehicle with a maximum safe speed of 30 km/h.

    Overrides move() to enforce the speed limit. Extends turn()
    to also lean into the corner.
    """

    def move(self, distance):
        """Override: cap requested distance at the maximum safe speed."""
        ...

    def turn(self, degrees):
        """Extend: lean into the turn, then update heading."""
        super().turn(degrees)
        ...
```

Use **override** when the subclass method does not call `super()`; **extend** when it does.

### Script docstring (usable as `--help` output)

```python
"""Sync a local directory with a remote SFTP target.

Usage: sync_remote.py [-v] [-n] LOCAL_DIR USER@HOST:REMOTE_DIR

Options:
    -v   verbose: print every file transferred
    -n   dry-run: print what would happen but don't transfer

Environment:
    SYNC_REMOTE_KEY  path to the SSH private key (default ~/.ssh/id_rsa)
"""
```

---

## Pattern Matching (PEP 634, examples from PEP 636)

### Literal patterns and wildcard

```python
def http_error(status):
    match status:
        case 400:
            return "Bad request"
        case 401 | 403 | 404:           # OR pattern combining literals
            return "Not allowed"
        case 418:
            return "I'm a teapot"
        case _:                          # wildcard — must be last
            return "Something's wrong with the Internet"
```

`401 | 403 | 404` is an OR pattern. `_` matches anything and binds nothing.

### Capture patterns and tuple destructuring

```python
# point is an (x, y) tuple
match point:
    case (0, 0):
        print("Origin")
    case (0, y):                         # literal + capture
        print(f"Y={y}")
    case (x, 0):
        print(f"X={x}")
    case (x, y):
        print(f"X={x}, Y={y}")
    case _:
        raise ValueError("Not a point")
```

Cases are tried top-to-bottom; the **first** match wins.

### Sequence patterns with star

```python
match command.split():
    case ["quit"]:
        quit_game()
    case ["go", direction]:
        current_room = current_room.neighbor(direction)
    case ["drop", *objects]:             # capture rest into a list
        for obj in objects:
            character.drop(obj, current_room)
    case _:
        print(f"Sorry, I couldn't understand {command!r}")
```

`[a, b, *rest]` and `(a, b, *rest)` are equivalent. **`str`, `bytes`, `bytearray` do NOT match sequence patterns** even though they are sequences.

### OR pattern + AS pattern (binding an OR result)

```python
match command.split():
    case ["go", ("north" | "south" | "east" | "west") as direction]:
        current_room = current_room.neighbor(direction)
```

The `as` binds the value matched by the OR to `direction`. All OR alternatives must bind the same set of names; only the last alternative may be irrefutable.

### Guards

```python
match command.split():
    case ["go", direction] if direction in current_room.exits:
        current_room = current_room.neighbor(direction)
    case ["go", _]:
        print("Sorry, you can't go that way")
```

Guard runs only after the pattern succeeds, but **may run with partially bound variables** if the guard itself fails — don't depend on those bindings.

### Class patterns — keyword args

```python
match event.get():
    case Click(position=(x, y)):
        handle_click_at(x, y)
    case KeyPress(key_name="Q") | Quit():
        game.quit()
    case KeyPress(key_name="up arrow"):
        game.go_north()
    case KeyPress():                     # any KeyPress not matched above
        pass
    case other_event:
        raise ValueError(f"Unrecognized event: {other_event}")
```

`Click(position=(x, y))` only matches when `isinstance(subject, Click)` AND `subject.position` matches `(x, y)`. Attributes not mentioned in the pattern are ignored.

### Class patterns — positional via `__match_args__`

```python
from dataclasses import dataclass

@dataclass
class Click:
    position: tuple
    button: Button
# Dataclass auto-generates __match_args__ = ("position", "button")

match event.get():
    case Click((x, y)):                  # (x, y) matches position (first arg)
        handle_click_at(x, y)
    case Click((x, y), button=Button.LEFT):
        handle_left_click_at(x, y)
```

For a non-dataclass class, set `__match_args__` manually:

```python
class Click:
    __match_args__ = ("position", "button")
    def __init__(self, pos, btn):
        self.position = pos
        self.button = btn
```

### Mapping patterns

```python
for action in actions:
    match action:
        case {"text": message, "color": c}:
            ui.set_text_color(c)
            ui.display(message)
        case {"sleep": duration}:
            ui.wait(duration)
        case {"sound": url, "format": "ogg"}:
            ui.play(url)
        case {"sound": _, "format": _}:
            warning("Unsupported audio format")
```

Extra keys in the subject are ignored — `{"text": "x", "color": "red", "style": "bold"}` matches the first case. Use `**rest` to capture additional keys. Keys must be literal or value patterns; values can be any pattern.

### Validating types with builtin class patterns

```python
match action:
    case {"text": str(message), "color": str(c)}:
        ui.set_text_color(c)
        ui.display(message)
    case {"sleep": float(duration)}:
        ui.wait(duration)
```

`str(message)` is a class pattern: `isinstance(action["text"], str)` AND bind to `message`. Works for the special builtins (`bool`, `bytearray`, `bytes`, `dict`, `float`, `frozenset`, `int`, `list`, `set`, `str`, `tuple`) which accept one positional that matches the whole subject.

### Value patterns — enums and constants

```python
from enum import Enum

class Color(Enum):
    RED = 0
    GREEN = 1
    BLUE = 2

match color:
    case Color.RED:                      # value pattern (dotted)
        print("I see red!")
    case Color.GREEN:
        print("Grass is green")
    case Color.BLUE:
        print("I'm feeling the blues")
```

**Use a dotted name** (`Color.RED`) for constants. A bare `case RED:` would be a *capture* pattern that always succeeds and shadows `RED`.

### Nested patterns

```python
match points:
    case []:
        print("No points")
    case [Point(0, 0)]:
        print("The origin")
    case [Point(x, y)]:
        print(f"Single point {x}, {y}")
    case [Point(0, y1), Point(0, y2)]:
        print(f"Two on the Y axis at {y1}, {y2}")
    case _:
        print("Something else")
```

Patterns nest arbitrarily.

---

## Exception Groups and `except*` (PEP 654)

### Creating and raising a group

```python
raise ExceptionGroup(
    "issues",
    [ValueError("bad value"), TypeError("bad type")],
)
```

Two positional-only args: a message and a sequence of exceptions. The constructor of `ExceptionGroup` raises `TypeError` if any wrapped item isn't an `Exception` subclass; use `BaseExceptionGroup` to wrap `BaseException` (e.g. `KeyboardInterrupt`).

### Basic `except*` — multiple clauses, one group

```python
try:
    raise ExceptionGroup(
        "msg",
        [ValueError("a"), TypeError("b"), TypeError("c"), KeyError("e")],
    )
except* ValueError as e:
    print(f"got some ValueErrors: {e!r}")
except* TypeError as e:
    print(f"got some TypeErrors: {e!r}")
# KeyError("e") was not matched → propagates as ExceptionGroup("msg", [KeyError("e")])
```

Output:
```
got some ValueErrors: ExceptionGroup('msg', [ValueError('a')])
got some TypeErrors: ExceptionGroup('msg', [TypeError('b'), TypeError('c')])
# then: ExceptionGroup('msg', [KeyError('e')]) propagates
```

Each `except*` clause runs **at most once**, receiving a **group** containing all matching leaves. Unmatched leaves propagate as a residual group.

### Recursive matching across nested groups

```python
try:
    raise ExceptionGroup(
        "eg",
        [
            ValueError("a"),
            TypeError("b"),
            ExceptionGroup("nested", [TypeError("c"), KeyError("d")]),
        ],
    )
except* TypeError as e1:
    print(f"e1 = {e1!r}")
except* Exception as e2:
    print(f"e2 = {e2!r}")
```

Output:
```
e1 = ExceptionGroup('eg', [TypeError('b'), ExceptionGroup('nested', [TypeError('c')])])
e2 = ExceptionGroup('eg', [ValueError('a'), ExceptionGroup('nested', [KeyError('d')])])
```

The nested structure is preserved in the matched subgroup.

### Naked exception wrapping

```python
try:
    raise BlockingIOError                # naked, not a group
except* OSError as e:
    print(repr(e))
# prints: ExceptionGroup('', [BlockingIOError()])
```

When the body of `try` raises a non-group exception that matches an `except*` clause, it is **auto-wrapped** in an `ExceptionGroup('', [...])` so the bound `e` is always a group. But if no clause matches, the naked exception propagates **unwrapped**.

### `split()` and `subgroup()`

```python
eg = ExceptionGroup(
    "one",
    [
        TypeError(1),
        ExceptionGroup("two", [TypeError(2), ValueError(3)]),
        ExceptionGroup("three", [OSError(4)]),
    ],
)

type_errors, other_errors = eg.split(TypeError)
# type_errors  → ExceptionGroup('one', [TypeError(1), ExceptionGroup('two', [TypeError(2)])])
# other_errors → ExceptionGroup('one', [ExceptionGroup('two', [ValueError(3)]),
#                                        ExceptionGroup('three', [OSError(4)])])

just_types = eg.subgroup(lambda e: isinstance(e, TypeError))
# same shape as type_errors above, or None if no match.
```

Both accept an exception type, a tuple of types, or a predicate. `split` returns `(matching, rest)` — either side may be `None` if trivial. `subgroup` returns only the matching part (or `None`).

### Practical pattern — log and ignore one error class, reraise rest

```python
import errno

try:
    low_level_os_operation()
except* OSError as errors:
    exc = errors.subgroup(lambda e: e.errno != errno.EPIPE)
    if exc is not None:
        raise exc from None
```

Strips `EPIPE` errors from the group, reraises whatever remains. `from None` suppresses chaining.

### Reraise vs `raise e` — different traceback semantics

```python
try:
    raise ExceptionGroup("eg", [ValueError(1), TypeError(2)])
except* ValueError as e:
    raise                                # naked reraise — original metadata
except* TypeError as e:
    raise e                              # explicit — adds current frame to traceback
```

Naked `raise` reraises the matched subgroup with original `__traceback__`, `__cause__`, `__context__`. `raise e` is treated as a new raise — the current frame is added to the traceback, and it ends up *combined* with any reraised/unhandled subgroups at the end of the `try` statement.

### Raising a new exception from `except*`

```python
try:
    raise TypeError("bad type")
except* TypeError as e:
    raise ValueError("bad value") from e
```

The new exception is chained (`__cause__` is set) and ends up in an outer `ExceptionGroup` when the `try` statement completes. Exceptions raised in one `except*` clause are **not** caught by later `except*` clauses of the same `try`.

### Subclassing — override `derive` and `__new__`

```python
class MyExceptionGroup(ExceptionGroup):
    def __new__(cls, message, excs, errcode):
        obj = super().__new__(cls, message, excs)
        obj.errcode = errcode
        return obj

    def derive(self, excs):
        # Called by split() and subgroup() when they need a new instance.
        return MyExceptionGroup(self.message, excs, self.errcode)

eg = MyExceptionGroup("eg", [TypeError(1), ValueError(2)], 42)
match, rest = eg.split(ValueError)
# match.errcode == 42, rest.errcode == 42
```

Override `__new__` (not `__init__`) because `BaseExceptionGroup.__new__` inspects its arguments and has a different signature from your subclass. `derive` doesn't need to copy `__cause__`/`__context__`/`__traceback__` — `split`/`subgroup` do that.

### Forbidden combinations

Each of the following is rejected by Python — three at parse time, one at runtime. Each snippet is shown in its own block to keep the bad syntax isolated.

**1. Mixing `except:` and `except*:` in the same `try` — SyntaxError:**

```text
try:
    ...
except ValueError:
    pass
except* CancelledError:    # SyntaxError
    pass
```

**2. Catching group types directly with `except*` — runtime error (ambiguous, since `except*` itself wraps in a group):**

```text
try:
    ...
except* ExceptionGroup:                  # runtime error
    pass

try:
    ...
except* (TypeError, ExceptionGroup):     # runtime error
    pass
```

**3. Empty `except*:` with no exception type — SyntaxError:**

```text
try:
    ...
except*:                                 # SyntaxError
    pass
```

**4. `continue`, `break`, or `return` inside an `except*` block — SyntaxError:**

```text
for x in xs:
    try:
        ...
    except* ValueError:
        continue                         # SyntaxError
```

To handle the group as a whole, wrap the `try`/`except*` in a regular `try`/`except ExceptionGroup`.

### Traversing leaf exceptions with full tracebacks

```python
def leaf_generator(exc, tbs=None):
    if tbs is None:
        tbs = []
    tbs.append(exc.__traceback__)
    if isinstance(exc, BaseExceptionGroup):
        for e in exc.exceptions:
            yield from leaf_generator(e, tbs)
    else:
        yield exc, tbs                       # full chain of tracebacks
    tbs.pop()
```

The `tbs` list is **reused across iterations** — copy it if you store leaf records beyond the current iteration. Each leaf's complete traceback is the concatenation of `tbs` from root to leaf.
