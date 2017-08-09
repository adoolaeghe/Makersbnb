## Operators and Aliases

Because the `==` operator frequently causes undesirable coercion, is intransitive, and has a different meaning than in other languages, CoffeeScript compiles `==` into `===`, and `!=` into `!==`. In addition, `is` compiles into `===`, and `isnt` into `!==`.

You can use `not` as an alias for `!`.

For logic, `and` compiles to `&&`, and `or` into `||`.

Instead of a newline or semicolon, `then` can be used to separate conditions from expressions, in **while**, **if**/**else**, and **switch**/**when** statements.

As in [YAML](http://yaml.org/), `on` and `yes` are the same as boolean `true`, while `off` and `no` are boolean `false`.

`unless` can be used as the inverse of `if`.

As a shortcut for `this.property`, you can use `@property`.

You can use `in` to test for array presence, and `of` to test for JavaScript object-key presence.

To simplify math expressions, `**` can be used for exponentiation and `//` performs integer division. `%` works just like in JavaScript, while `%%` provides [“dividend dependent modulo”](https://en.wikipedia.org/wiki/Modulo_operation):

```
codeFor('modulo')
```

All together now:

| CoffeeScript | JavaScript |
| --- | --- |
| `is` | `===` |
| `isnt` | `!==` |
| `not` | `!` |
| `and` | `&&` |
| `or` | `||` |
| `true`, `yes`, `on` | `true` |
| `false`, `no`, `off`&emsp; | `false` |
| `@`, `this` | `this` |
| `of` | `in` |
| `in` | _no JS equivalent_ |
| `a ** b` | `Math.pow(a, b)` |
| `a // b` | `Math.floor(a / b)` |
| `a %% b` | `(a % b + b) % b` |

```
codeFor('aliases')
```
