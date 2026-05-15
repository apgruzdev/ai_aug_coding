# PEP 8 Examples — Correct vs Wrong

Code examples extracted verbatim from PEP 8. Organized by the same sections as `pep8.md`. Load this only when you need to **see** a non-obvious case — the rules themselves are in `pep8.md`.

## Indentation

### Continuation lines

```python
# Correct: aligned with opening delimiter.
foo = long_function_name(var_one, var_two,
                         var_three, var_four)

# Correct: hanging indent, +4 spaces, no args on first line.
foo = long_function_name(
    var_one, var_two,
    var_three, var_four)

# Correct: extra indent to distinguish args from body.
def long_function_name(
        var_one, var_two, var_three,
        var_four):
    print(var_one)
```

```python
# Wrong: args on first line forbidden when not vertically aligned.
foo = long_function_name(var_one, var_two,
    var_three, var_four)

# Wrong: continuation indent indistinguishable from body.
def long_function_name(
    var_one, var_two, var_three,
    var_four):
    print(var_one)
```

### Multi-line `if` conditions (PEP 8 takes no position; all three OK)

```python
# Option 1: no extra indentation.
if (this_is_one_thing and
    that_is_another_thing):
    do_something()

# Option 2: add a comment for visual distinction.
if (this_is_one_thing and
    that_is_another_thing):
    # Since both conditions are true, we can frobnicate.
    do_something()

# Option 3: extra indent on continuation.
if (this_is_one_thing
        and that_is_another_thing):
    do_something()
```

### Closing bracket placement (both OK; pick one per file)

```python
# Option 1: aligned with first item.
my_list = [
    1, 2, 3,
    4, 5, 6,
    ]

# Option 2: aligned with start of construct.
my_list = [
    1, 2, 3,
    4, 5, 6,
]
```

---

## Line Break Before/After Binary Operator

```python
# Wrong: operators scattered, far from their operands.
income = (gross_wages +
          taxable_interest +
          (dividends - qualified_dividends) -
          ira_deduction -
          student_loan_interest)
```

```python
# Correct: break before operator (Knuth style).
income = (gross_wages
          + taxable_interest
          + (dividends - qualified_dividends)
          - ira_deduction
          - student_loan_interest)
```

---

## Imports

```python
# Correct: one per line.
import os
import sys

# Correct: multiple names from one module OK.
from subprocess import Popen, PIPE
```

```python
# Wrong: multiple modules on one line.
import sys, os
```

```python
# Absolute imports — preferred.
import mypkg.sibling
from mypkg import sibling
from mypkg.sibling import example

# Explicit relative imports — acceptable inside packages.
from . import sibling
from .sibling import example
```

## Module-Level Dunder Names

```python
"""This is the example module.

This module does stuff.
"""

from __future__ import barry_as_FLUFL

__all__ = ['a', 'b', 'c']
__version__ = '0.1'
__author__ = 'Cardinal Biggles'

import os
import sys
```

---

## Whitespace

### No space inside brackets / before punctuation

```python
# Correct:
spam(ham[1], {eggs: 2})
foo = (0,)
if x == 4: print(x, y); x, y = y, x
dct['key'] = lst[index]
spam(1)
```

```python
# Wrong:
spam( ham[ 1 ], { eggs: 2 } )
bar = (0, )
if x == 4 : print(x , y) ; x , y = y , x
dct ['key'] = lst [index]
spam (1)
```

### Slice colons (act like binary operator — equal space on both sides)

```python
# Correct:
ham[1:9], ham[1:9:3], ham[:9:3], ham[1::3], ham[1:9:]
ham[lower:upper], ham[lower:upper:], ham[lower::step]
ham[lower+offset : upper+offset]
ham[: upper_fn(x) : step_fn(x)]
```

```python
# Wrong:
ham[lower + offset:upper + offset]
ham[1: 9], ham[1 :9], ham[1:9 :3]
ham[lower : : step]
ham[ : upper]
```

### Operator priority — may omit space around higher-priority operator

```python
# Correct:
i = i + 1
submitted += 1
x = x*2 - 1
hypot2 = x*x + y*y
c = (a+b) * (a-b)
```

```python
# Wrong:
i=i+1
submitted +=1
x = x * 2 - 1
hypot2 = x * x + y * y
c = (a + b) * (a - b)
```

### One space around `=` for assignment (no alignment padding)

```python
# Correct:
x = 1
y = 2
long_variable = 3
```

```python
# Wrong:
x             = 1
y             = 2
long_variable = 3
```

### Function annotations: spaces around `->`, normal colon rules

```python
# Correct:
def munge(input: AnyStr): ...
def munge() -> PosInt: ...
```

```python
# Wrong:
def munge(input:AnyStr): ...
def munge()->PosInt: ...
```

### Keyword args / default values: spaces depend on annotation

```python
# Correct: no spaces around = for unannotated defaults.
def complex(real, imag=0.0):
    return magic(r=real, i=imag)

# Correct: spaces around = when annotation is present.
def munge(sep: AnyStr = None): ...
def munge(input: AnyStr, sep: AnyStr = None, limit=1000): ...
```

```python
# Wrong: spaces around = for unannotated default.
def complex(real, imag = 0.0):
    return magic(r = real, i = imag)

# Wrong: no spaces around = with annotation.
def munge(input: AnyStr=None): ...
def munge(input: AnyStr, limit = 1000): ...
```

### Compound statements — discouraged

```python
# Correct:
if foo == 'blah':
    do_blah_thing()
do_one()
do_two()
do_three()
```

```python
# Wrong:
if foo == 'blah': do_blah_thing()
do_one(); do_two(); do_three()

# Definitely wrong:
if foo == 'blah': do_blah_thing()
else: do_non_blah_thing()
try: something()
finally: cleanup()
```

---

## Programming Recommendations

### Comparisons to `None`

```python
# Correct:
if foo is None:
if foo is not None:
```

```python
# Wrong:
if not foo is None:    # use `is not`
if foo == None:        # use `is`
```

### Boolean comparisons

```python
# Correct:
if greeting:
```

```python
# Wrong:
if greeting == True:
if greeting is True:   # even worse
```

### Empty sequence checks

```python
# Correct:
if not seq:
if seq:
```

```python
# Wrong:
if len(seq):
if not len(seq):
```

### Type checks

```python
# Correct:
if isinstance(obj, int):
```

```python
# Wrong:
if type(obj) is type(1):
```

### Prefix / suffix checks

```python
# Correct:
if foo.startswith('bar'):
```

```python
# Wrong:
if foo[:3] == 'bar':
```

### Lambda vs def

```python
# Correct:
def f(x): return 2*x
```

```python
# Wrong:
f = lambda x: 2*x      # name shows as '<lambda>' in tracebacks
```

### Narrow the `try` block

```python
# Correct:
try:
    value = collection[key]
except KeyError:
    return key_not_found(key)
else:
    return handle_value(value)
```

```python
# Wrong:
try:
    # Too broad — KeyError raised inside handle_value() would be swallowed.
    return handle_value(collection[key])
except KeyError:
    return key_not_found(key)
```

### Exception handling — common pattern

```python
try:
    import platform_specific_module
except ImportError:
    platform_specific_module = None
```

### Return consistency

```python
# Correct: every path explicit.
def foo(x):
    if x >= 0:
        return math.sqrt(x)
    else:
        return None

def bar(x):
    if x < 0:
        return None
    return math.sqrt(x)
```

```python
# Wrong: one path returns value, other has implicit None.
def foo(x):
    if x >= 0:
        return math.sqrt(x)
    # falls off the end → implicit None

def bar(x):
    if x < 0:
        return        # bare return = implicit None
    return math.sqrt(x)
```

### Context managers — be explicit about non-resource side effects

```python
# Correct: name reveals what __enter__/__exit__ are doing.
with conn.begin_transaction():
    do_stuff_in_transaction(conn)
```

```python
# Wrong: opaque — reader can't tell this is a transaction, not just close().
with conn:
    do_stuff_in_transaction(conn)
```

### `finally` and control flow

```python
# Wrong: `return` in finally silently swallows the ZeroDivisionError.
def foo():
    try:
        1 / 0
    finally:
        return 42
```
