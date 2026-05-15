# PEP 20 — The Zen of Python (with brief commentary)

Source: https://peps.python.org/pep-0020/. Type `import this` in any Python REPL.

```
Beautiful is better than ugly.
Explicit is better than implicit.
Simple is better than complex.
Complex is better than complicated.
Flat is better than nested.
Sparse is better than dense.
Readability counts.
Special cases aren't special enough to break the rules.
Although practicality beats purity.
Errors should never pass silently.
Unless explicitly silenced.
In the face of ambiguity, refuse the temptation to guess.
There should be one-- and preferably only one --obvious way to do it.
Although that way may not be obvious at first unless you're Dutch.
Now is better than never.
Although never is often better than *right* now.
If the implementation is hard to explain, it's a bad idea.
If the implementation is easy to explain, it may be a good idea.
Namespaces are one honking great idea -- let's do more of those!
```

## Engineering translations

- **Explicit > implicit.** Named kwargs over positional. Explicit `return None`. No magic.
- **Flat > nested.** Three levels of indentation is the soft limit; four is a smell. Use guard clauses and early returns.
- **Errors never pass silently.** No bare `except:`. No `except Exception: pass` without a comment.
- **Refuse to guess.** Ambiguous input → raise. Don't paper over with a default that hides the problem.
- **One obvious way.** Reach for the standard idiom (list comp, `with`, f-string, dataclass) before exotic alternatives.
- **Readability counts.** Code is read 10–100× more than it is written. Optimize for the next reader.
- **Practicality beats purity.** But the bar for invoking this clause is high — default to purity.
- **Hard to explain → bad idea.** If you can't sketch it on a whiteboard in two minutes, the design is wrong.
- **Namespaces.** Use modules and packages. Don't dump everything into `utils.py`. Don't `import *`.
