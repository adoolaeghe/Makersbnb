# Error Formatting
# ----------------

# Ensure that errors of different kinds (lexer, parser and compiler) are shown
# in a consistent way.

assertErrorFormat = (code, expectedErrorFormat) ->
  throws (-> CoffeeScript.run code), (err) ->
    err.colorful = no
    eq expectedErrorFormat, "#{err}"
    yes

test "lexer errors formatting", ->
  assertErrorFormat '''
    normalObject    = {}
    insideOutObject = }{
  ''',
  '''
    [stdin]:2:19: error: unmatched }
    insideOutObject = }{
                      ^
  '''

test "parser error formatting", ->
  assertErrorFormat '''
    foo in bar or in baz
  ''',
  '''
    [stdin]:1:15: error: unexpected in
    foo in bar or in baz
                  ^^
  '''

test "compiler error formatting", ->
  assertErrorFormat '''
    evil = (foo, eval, bar) ->
  ''',
  '''
    [stdin]:1:14: error: 'eval' can't be assigned
    evil = (foo, eval, bar) ->
                 ^^^^
  '''

test "compiler error formatting with mixed tab and space", ->
  assertErrorFormat """
    \t  if a
    \t  test
  """,
  '''
    [stdin]:1:4: error: unexpected if
    \t  if a
    \t  ^^
  '''


if require?
  os   = require 'os'
  fs   = require 'fs'
  path = require 'path'

  test "patchStackTrace line patching", ->
    err = new Error 'error'
    ok err.stack.match /test[\/\\]error_messages\.coffee:\d+:\d+\b/

  test "patchStackTrace stack prelude consistent with V8", ->
    err = new Error
    ok err.stack.match /^Error\n/ # Notice no colon when no message.

    err = new Error 'error'
    ok err.stack.match /^Error: error\n/

  test "#2849: compilation error in a require()d file", ->
    # Create a temporary file to require().
    tempFile = path.join os.tmpdir(), 'syntax-error.coffee'
    ok not fs.existsSync tempFile
    fs.writeFileSync tempFile, 'foo in bar or in baz'

    try
      assertErrorFormat """
        require '#{tempFile}'
      """,
      """
        #{fs.realpathSync tempFile}:1:15: error: unexpected in
        foo in bar or in baz
                      ^^
      """
    finally
      fs.unlinkSync tempFile

  test "#3890 Error.prepareStackTrace doesn't throw an error if a compiled file is deleted", ->
    # Adapted from https://github.com/atom/coffee-cash/blob/master/spec/coffee-cash-spec.coffee
    filePath = path.join os.tmpdir(), 'PrepareStackTraceTestFile.coffee'
    fs.writeFileSync filePath, "module.exports = -> throw new Error('hello world')"
    throwsAnError = require filePath
    fs.unlinkSync filePath

    try
      throwsAnError()
    catch error

    eq error.message, 'hello world'
    doesNotThrow(-> error.stack)
    notEqual error.stack.toString().indexOf(filePath), -1

  test "#4418 stack traces for compiled files reference the correct line number", ->
    filePath = path.join os.tmpdir(), 'StackTraceLineNumberTestFile.coffee'
    fileContents = """
      testCompiledFileStackTraceLineNumber = ->
        # `a` on the next line is undefined and should throw a ReferenceError
        console.log a if true

      do testCompiledFileStackTraceLineNumber
      """
    fs.writeFileSync filePath, fileContents

    try
      require filePath
    catch error
    fs.unlinkSync filePath

    # Make sure the line number reported is line 3 (the original Coffee source)
    # and not line 6 (the generated JavaScript).
    eq /StackTraceLineNumberTestFile.coffee:(\d)/.exec(error.stack.toString())[1], '3'


test "#4418 stack traces for compiled strings reference the correct line number", ->
  try
    CoffeeScript.run """
      testCompiledStringStackTraceLineNumber = ->
        # `a` on the next line is undefined and should throw a ReferenceError
        console.log a if true

      do testCompiledStringStackTraceLineNumber
      """
  catch error

  # Make sure the line number reported is line 3 (the original Coffee source)
  # and not line 6 (the generated JavaScript).
  eq /at testCompiledStringStackTraceLineNumber.*:(\d):/.exec(error.stack.toString())[1], '3'


test "#1096: unexpected generated tokens", ->
  # Implicit ends
  assertErrorFormat 'a:, b', '''
    [stdin]:1:3: error: unexpected ,
    a:, b
      ^
  '''
  # Explicit ends
  assertErrorFormat '(a:)', '''
    [stdin]:1:4: error: unexpected )
    (a:)
       ^
  '''
  # Unexpected end of file
  assertErrorFormat 'a:', '''
    [stdin]:1:3: error: unexpected end of input
    a:
      ^
  '''
  assertErrorFormat 'a +', '''
    [stdin]:1:4: error: unexpected end of input
    a +
       ^
  '''
  # Unexpected key in implicit object (an implicit object itself is _not_
  # unexpected here)
  assertErrorFormat '''
    for i in [1]:
      1
  ''', '''
    [stdin]:1:10: error: unexpected [
    for i in [1]:
             ^
  '''
  # Unexpected regex
  assertErrorFormat '{/a/i: val}', '''
    [stdin]:1:2: error: unexpected regex
    {/a/i: val}
     ^^^^
  '''
  assertErrorFormat '{///a///i: val}', '''
    [stdin]:1:2: error: unexpected regex
    {///a///i: val}
     ^^^^^^^^
  '''
  assertErrorFormat '{///#{a}///i: val}', '''
    [stdin]:1:2: error: unexpected regex
    {///#{a}///i: val}
     ^^^^^^^^^^^
  '''
  # Unexpected string
  assertErrorFormat 'import foo from "lib-#{version}"', '''
    [stdin]:1:17: error: the name of the module to be imported from must be an uninterpolated string
    import foo from "lib-#{version}"
                    ^^^^^^^^^^^^^^^^
  '''

  # Unexpected number
  assertErrorFormat '"a"0x00Af2', '''
    [stdin]:1:4: error: unexpected number
    "a"0x00Af2
       ^^^^^^^
  '''

test "#1316: unexpected end of interpolation", ->
  assertErrorFormat '''
    "#{+}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{+}"
        ^
  '''
  assertErrorFormat '''
    "#{++}"
  ''', '''
    [stdin]:1:6: error: unexpected end of interpolation
    "#{++}"
         ^
  '''
  assertErrorFormat '''
    "#{-}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{-}"
        ^
  '''
  assertErrorFormat '''
    "#{--}"
  ''', '''
    [stdin]:1:6: error: unexpected end of interpolation
    "#{--}"
         ^
  '''
  assertErrorFormat '''
    "#{~}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{~}"
        ^
  '''
  assertErrorFormat '''
    "#{!}"
  ''', '''
    [stdin]:1:5: error: unexpected end of interpolation
    "#{!}"
        ^
  '''
  assertErrorFormat '''
    "#{not}"
  ''', '''
    [stdin]:1:7: error: unexpected end of interpolation
    "#{not}"
          ^
  '''
  assertErrorFormat '''
    "#{5) + (4}_"
  ''', '''
    [stdin]:1:5: error: unmatched )
    "#{5) + (4}_"
        ^
  '''
  # #2918
  assertErrorFormat '''
    "#{foo.}"
  ''', '''
    [stdin]:1:8: error: unexpected end of interpolation
    "#{foo.}"
           ^
  '''

test "#3325: implicit indentation errors", ->
  assertErrorFormat '''
    i for i in a then i
  ''', '''
    [stdin]:1:14: error: unexpected then
    i for i in a then i
                 ^^^^
  '''

test "explicit indentation errors", ->
  assertErrorFormat '''
    a = b
      c
  ''', '''
    [stdin]:2:1: error: unexpected indentation
      c
    ^^
  '''

test "unclosed strings", ->
  assertErrorFormat '''
    '
  ''', '''
    [stdin]:1:1: error: missing '
    '
    ^
  '''
  assertErrorFormat '''
    "
  ''', '''
    [stdin]:1:1: error: missing "
    "
    ^
  '''
  assertErrorFormat """
    '''
  """, """
    [stdin]:1:1: error: missing '''
    '''
    ^^^
  """
  assertErrorFormat '''
    """
  ''', '''
    [stdin]:1:1: error: missing """
    """
    ^^^
  '''
  assertErrorFormat '''
    "#{"
  ''', '''
    [stdin]:1:4: error: missing "
    "#{"
       ^
  '''
  assertErrorFormat '''
    """#{"
  ''', '''
    [stdin]:1:6: error: missing "
    """#{"
         ^
  '''
  assertErrorFormat '''
    "#{"""
  ''', '''
    [stdin]:1:4: error: missing """
    "#{"""
       ^^^
  '''
  assertErrorFormat '''
    """#{"""
  ''', '''
    [stdin]:1:6: error: missing """
    """#{"""
         ^^^
  '''
  assertErrorFormat '''
    ///#{"""
  ''', '''
    [stdin]:1:6: error: missing """
    ///#{"""
         ^^^
  '''
  assertErrorFormat '''
    "a
      #{foo """
        bar
          #{ +'12 }
        baz
        """} b"
  ''', '''
    [stdin]:4:11: error: missing '
          #{ +'12 }
              ^
  '''
  # https://github.com/jashkenas/coffeescript/issues/3301#issuecomment-31735168
  assertErrorFormat '''
    # Note the double escaping; this would be `"""a\"""` real code.
    """a\\"""
  ''', '''
    [stdin]:2:1: error: missing """
    """a\\"""
    ^^^
  '''

test "unclosed heregexes", ->
  assertErrorFormat '''
    ///
  ''', '''
    [stdin]:1:1: error: missing ///
    ///
    ^^^
  '''
  # https://github.com/jashkenas/coffeescript/issues/3301#issuecomment-31735168
  assertErrorFormat '''
    # Note the double escaping; this would be `///a\///` real code.
    ///a\\///
  ''', '''
    [stdin]:2:1: error: missing ///
    ///a\\///
    ^^^
  '''

test "unexpected token after string", ->
  # Parsing error.
  assertErrorFormat '''
    'foo'bar
  ''', '''
    [stdin]:1:6: error: unexpected identifier
    'foo'bar
         ^^^
  '''
  assertErrorFormat '''
    "foo"bar
  ''', '''
    [stdin]:1:6: error: unexpected identifier
    "foo"bar
         ^^^
  '''
  # Lexing error.
  assertErrorFormat '''
    'foo'bar'
  ''', '''
    [stdin]:1:9: error: missing '
    'foo'bar'
            ^
  '''
  assertErrorFormat '''
    "foo"bar"
  ''', '''
    [stdin]:1:9: error: missing "
    "foo"bar"
            ^
  '''

test "#3348: Location data is wrong in interpolations with leading whitespace", ->
  assertErrorFormat '''
    "#{ * }"
  ''', '''
    [stdin]:1:5: error: unexpected *
    "#{ * }"
        ^
  '''

test "octal escapes", ->
  assertErrorFormat '''
    "a\\0\\tb\\\\\\07c"
  ''', '''
    [stdin]:1:10: error: octal escape sequences are not allowed \\07
    "a\\0\\tb\\\\\\07c"
      \  \   \ \ ^\^^
  '''
  assertErrorFormat '''
    "a
      #{b} \\1"
  ''', '''
    [stdin]:2:8: error: octal escape sequences are not allowed \\1
      #{b} \\1"
           ^\^
  '''
  assertErrorFormat '''
    /a\\0\\tb\\\\\\07c/
  ''', '''
    [stdin]:1:10: error: octal escape sequences are not allowed \\07
    /a\\0\\tb\\\\\\07c/
      \  \   \ \ ^\^^
  '''
  assertErrorFormat '''
    /a\\1\\tb\\\\\\07c/
  ''', '''
    [stdin]:1:10: error: octal escape sequences are not allowed \\07
    /a\\1\\tb\\\\\\07c/
      \  \   \ \ ^\^^
  '''
  assertErrorFormat '''
    ///a
      #{b} \\01///
  ''', '''
    [stdin]:2:8: error: octal escape sequences are not allowed \\01
      #{b} \\01///
           ^\^^
  '''

test "#3795: invalid escapes", ->
  assertErrorFormat '''
    "a\\0\\tb\\\\\\x7g"
  ''', '''
    [stdin]:1:10: error: invalid escape sequence \\x7g
    "a\\0\\tb\\\\\\x7g"
      \  \   \ \ ^\^^^
  '''
  assertErrorFormat '''
    "a
      #{b} \\uA02
     c"
  ''', '''
    [stdin]:2:8: error: invalid escape sequence \\uA02
      #{b} \\uA02
           ^\^^^^
  '''
  assertErrorFormat '''
    /a\\u002space/
  ''', '''
    [stdin]:1:3: error: invalid escape sequence \\u002s
    /a\\u002space/
      ^\^^^^^
  '''
  assertErrorFormat '''
    ///a \\u002 0 space///
  ''', '''
    [stdin]:1:6: error: invalid escape sequence \\u002 \n\
    ///a \\u002 0 space///
         ^\^^^^^
  '''
  assertErrorFormat '''
    ///a
      #{b} \\x0
     c///
  ''', '''
    [stdin]:2:8: error: invalid escape sequence \\x0
      #{b} \\x0
           ^\^^
  '''
  assertErrorFormat '''
    /ab\\u/
  ''', '''
    [stdin]:1:4: error: invalid escape sequence \\u
    /ab\\u/
       ^\^
  '''

test "illegal herecomment", ->
  assertErrorFormat '''
    ###
      Regex: /a*/g
    ###
  ''', '''
    [stdin]:2:12: error: block comments cannot contain */
      Regex: /a*/g
               ^^
  '''

test "#1724: regular expressions beginning with *", ->
  assertErrorFormat '''
    /* foo/
  ''', '''
    [stdin]:1:2: error: regular expressions cannot begin with *
    /* foo/
     ^
  '''
  assertErrorFormat '''
    ///
      * foo
    ///
  ''', '''
    [stdin]:2:3: error: regular expressions cannot begin with *
      * foo
      ^
  '''

test "invalid regex flags", ->
  assertErrorFormat '''
    /a/ii
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags ii
    /a/ii
       ^^
  '''
  assertErrorFormat '''
    /a/G
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags G
    /a/G
       ^
  '''
  assertErrorFormat '''
    /a/gimi
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags gimi
    /a/gimi
       ^^^^
  '''
  assertErrorFormat '''
    /a/g_
  ''', '''
    [stdin]:1:4: error: invalid regular expression flags g_
    /a/g_
       ^^
  '''
  assertErrorFormat '''
    ///a///ii
  ''', '''
    [stdin]:1:8: error: invalid regular expression flags ii
    ///a///ii
           ^^
  '''
  doesNotThrow -> CoffeeScript.compile '/a/ymgi'

test "missing `)`, `}`, `]`", ->
  assertErrorFormat '''
    (
  ''', '''
    [stdin]:1:1: error: missing )
    (
    ^
  '''
  assertErrorFormat '''
    {
  ''', '''
    [stdin]:1:1: error: missing }
    {
    ^
  '''
  assertErrorFormat '''
    [
  ''', '''
    [stdin]:1:1: error: missing ]
    [
    ^
  '''
  assertErrorFormat '''
    obj = {a: [1, (2+
  ''', '''
    [stdin]:1:15: error: missing )
    obj = {a: [1, (2+
                  ^
  '''
  assertErrorFormat '''
    "#{
  ''', '''
    [stdin]:1:3: error: missing }
    "#{
      ^
  '''
  assertErrorFormat '''
    """
      foo#{ bar "#{1}"
  ''', '''
    [stdin]:2:7: error: missing }
      foo#{ bar "#{1}"
          ^
  '''

test "unclosed regexes", ->
  assertErrorFormat '''
    /
  ''', '''
    [stdin]:1:1: error: missing / (unclosed regex)
    /
    ^
  '''
  assertErrorFormat '''
    # Note the double escaping; this would be `/a\/` real code.
    /a\\/
  ''', '''
    [stdin]:2:1: error: missing / (unclosed regex)
    /a\\/
    ^
  '''
  assertErrorFormat '''
    /// ^
      a #{""" ""#{if /[/].test "|" then 1 else 0}"" """}
    ///
  ''', '''
    [stdin]:2:18: error: missing / (unclosed regex)
      a #{""" ""#{if /[/].test "|" then 1 else 0}"" """}
                     ^
  '''

test "duplicate function arguments", ->
  assertErrorFormat '''
    (foo, bar, foo) ->
  ''', '''
    [stdin]:1:12: error: multiple parameters named foo
    (foo, bar, foo) ->
               ^^^
  '''
  assertErrorFormat '''
    (@foo, bar, @foo) ->
  ''', '''
    [stdin]:1:13: error: multiple parameters named @foo
    (@foo, bar, @foo) ->
                ^^^^
  '''

test "reserved words", ->
  assertErrorFormat '''
    case
  ''', '''
    [stdin]:1:1: error: reserved word 'case'
    case
    ^^^^
  '''
  assertErrorFormat '''
    case = 1
  ''', '''
    [stdin]:1:1: error: reserved word 'case'
    case = 1
    ^^^^
  '''
  assertErrorFormat '''
    for = 1
  ''', '''
    [stdin]:1:1: error: keyword 'for' can't be assigned
    for = 1
    ^^^
  '''
  assertErrorFormat '''
    unless = 1
  ''', '''
    [stdin]:1:1: error: keyword 'unless' can't be assigned
    unless = 1
    ^^^^^^
  '''
  assertErrorFormat '''
    for += 1
  ''', '''
    [stdin]:1:1: error: keyword 'for' can't be assigned
    for += 1
    ^^^
  '''
  assertErrorFormat '''
    for &&= 1
  ''', '''
    [stdin]:1:1: error: keyword 'for' can't be assigned
    for &&= 1
    ^^^
  '''
  # Make sure token look-behind doesn't go out of range.
  assertErrorFormat '''
    &&= 1
  ''', '''
    [stdin]:1:1: error: unexpected &&=
    &&= 1
    ^^^
  '''
  # #2306: Show unaliased name in error messages.
  assertErrorFormat '''
    on = 1
  ''', '''
    [stdin]:1:1: error: keyword 'on' can't be assigned
    on = 1
    ^^
  '''

test "strict mode errors", ->
  assertErrorFormat '''
    eval = 1
  ''', '''
    [stdin]:1:1: error: 'eval' can't be assigned
    eval = 1
    ^^^^
  '''
  assertErrorFormat '''
    class eval
  ''', '''
    [stdin]:1:7: error: 'eval' can't be assigned
    class eval
          ^^^^
  '''
  assertErrorFormat '''
    arguments++
  ''', '''
    [stdin]:1:1: error: 'arguments' can't be assigned
    arguments++
    ^^^^^^^^^
  '''
  assertErrorFormat '''
    --arguments
  ''', '''
    [stdin]:1:3: error: 'arguments' can't be assigned
    --arguments
      ^^^^^^^^^
  '''

test "invalid numbers", ->
  assertErrorFormat '''
    0X0
  ''', '''
    [stdin]:1:2: error: radix prefix in '0X0' must be lowercase
    0X0
     ^
  '''
  assertErrorFormat '''
    10E0
  ''', '''
    [stdin]:1:3: error: exponential notation in '10E0' must be indicated with a lowercase 'e'
    10E0
      ^
  '''
  assertErrorFormat '''
    018
  ''', '''
    [stdin]:1:1: error: decimal literal '018' must not be prefixed with '0'
    018
    ^^^
  '''
  assertErrorFormat '''
    010
  ''', '''
    [stdin]:1:1: error: octal literal '010' must be prefixed with '0o'
    010
    ^^^
'''

test "unexpected object keys", ->
  assertErrorFormat '''
    {[[]]}
  ''', '''
    [stdin]:1:2: error: unexpected [
    {[[]]}
     ^
  '''
  assertErrorFormat '''
    {[[]]: 1}
  ''', '''
    [stdin]:1:2: error: unexpected [
    {[[]]: 1}
     ^
  '''
  assertErrorFormat '''
    [[]]: 1
  ''', '''
    [stdin]:1:1: error: unexpected [
    [[]]: 1
    ^
  '''
  assertErrorFormat '''
    {(a + "b")}
  ''', '''
    [stdin]:1:2: error: unexpected (
    {(a + "b")}
     ^
  '''
  assertErrorFormat '''
    {(a + "b"): 1}
  ''', '''
    [stdin]:1:2: error: unexpected (
    {(a + "b"): 1}
     ^
  '''
  assertErrorFormat '''
    (a + "b"): 1
  ''', '''
    [stdin]:1:1: error: unexpected (
    (a + "b"): 1
    ^
  '''
  assertErrorFormat '''
    a: 1, [[]]: 2
  ''', '''
    [stdin]:1:7: error: unexpected [
    a: 1, [[]]: 2
          ^
  '''
  assertErrorFormat '''
    {a: 1, [[]]: 2}
  ''', '''
    [stdin]:1:8: error: unexpected [
    {a: 1, [[]]: 2}
           ^
  '''

test "invalid object keys", ->
  assertErrorFormat '''
    @a: 1
  ''', '''
    [stdin]:1:1: error: invalid object key
    @a: 1
    ^^
  '''
  assertErrorFormat '''
    f
      @a: 1
  ''', '''
    [stdin]:2:3: error: invalid object key
      @a: 1
      ^^
  '''
  assertErrorFormat '''
    {a=2}
  ''', '''
    [stdin]:1:3: error: unexpected =
    {a=2}
      ^
  '''

test "invalid destructuring default target", ->
  assertErrorFormat '''
    {'a' = 2} = obj
  ''', '''
    [stdin]:1:6: error: unexpected =
    {'a' = 2} = obj
         ^
  '''

test "#4070: lone expansion", ->
  assertErrorFormat '''
    [...] = a
  ''', '''
    [stdin]:1:2: error: Destructuring assignment has no target
    [...] = a
     ^^^
  '''
  assertErrorFormat '''
    [ ..., ] = a
  ''', '''
    [stdin]:1:3: error: Destructuring assignment has no target
    [ ..., ] = a
      ^^^
  '''

test "#3926: implicit object in parameter list", ->
  assertErrorFormat '''
    (a: b) ->
  ''', '''
    [stdin]:1:3: error: unexpected :
    (a: b) ->
      ^
  '''
  assertErrorFormat '''
    (one, two, {three, four: five}, key: value) ->
  ''', '''
    [stdin]:1:36: error: unexpected :
    (one, two, {three, four: five}, key: value) ->
                                       ^
  '''

test "#4130: unassignable in destructured param", ->
  assertErrorFormat '''
    fun = ({
      @param : null
    }) ->
      console.log "Oh hello!"
  ''', '''
    [stdin]:2:12: error: keyword 'null' can't be assigned
      @param : null
               ^^^^
  '''
  assertErrorFormat '''
    ({a: null}) ->
  ''', '''
    [stdin]:1:6: error: keyword 'null' can't be assigned
    ({a: null}) ->
         ^^^^
  '''
  assertErrorFormat '''
    ({a: 1}) ->
  ''', '''
    [stdin]:1:6: error: '1' can't be assigned
    ({a: 1}) ->
         ^
  '''
  assertErrorFormat '''
    ({1}) ->
  ''', '''
    [stdin]:1:3: error: '1' can't be assigned
    ({1}) ->
      ^
  '''
  assertErrorFormat '''
    ({a: true = 1}) ->
  ''', '''
    [stdin]:1:6: error: keyword 'true' can't be assigned
    ({a: true = 1}) ->
         ^^^^
  '''

test "`yield` outside of a function", ->
  assertErrorFormat '''
    yield 1
  ''', '''
    [stdin]:1:1: error: yield can only occur inside functions
    yield 1
    ^^^^^^^
  '''
  assertErrorFormat '''
    yield return
  ''', '''
    [stdin]:1:1: error: yield can only occur inside functions
    yield return
    ^^^^^^^^^^^^
  '''

test "#4097: `yield return` as an expression", ->
  assertErrorFormat '''
    -> (yield return)
  ''', '''
    [stdin]:1:5: error: cannot use a pure statement in an expression
    -> (yield return)
        ^^^^^^^^^^^^
  '''

test "`&&=` and `||=` with a space in-between", ->
  assertErrorFormat '''
    a = 0
    a && = 1
  ''', '''
    [stdin]:2:6: error: unexpected =
    a && = 1
         ^
  '''
  assertErrorFormat '''
    a = 0
    a and = 1
  ''', '''
    [stdin]:2:7: error: unexpected =
    a and = 1
          ^
  '''
  assertErrorFormat '''
    a = 0
    a || = 1
  ''', '''
    [stdin]:2:6: error: unexpected =
    a || = 1
         ^
  '''
  assertErrorFormat '''
    a = 0
    a or = 1
  ''', '''
    [stdin]:2:6: error: unexpected =
    a or = 1
         ^
  '''

test "anonymous functions cannot be exported", ->
  assertErrorFormat '''
    export ->
      console.log 'hello, world!'
  ''', '''
    [stdin]:1:8: error: unexpected ->
    export ->
           ^^
  '''

test "anonymous classes cannot be exported", ->
  assertErrorFormat '''
    export class
      constructor: ->
        console.log 'hello, world!'
  ''', '''
    [stdin]:1:8: error: anonymous classes cannot be exported
    export class
           ^^^^^
  '''

test "unless enclosed by curly braces, only * can be aliased", ->
  assertErrorFormat '''
    import foo as bar from 'lib'
  ''', '''
    [stdin]:1:12: error: unexpected as
    import foo as bar from 'lib'
               ^^
  '''

test "unwrapped imports must follow constrained syntax", ->
  assertErrorFormat '''
    import foo, bar from 'lib'
  ''', '''
    [stdin]:1:13: error: unexpected identifier
    import foo, bar from 'lib'
                ^^^
  '''
  assertErrorFormat '''
    import foo, bar, baz from 'lib'
  ''', '''
    [stdin]:1:13: error: unexpected identifier
    import foo, bar, baz from 'lib'
                ^^^
  '''
  assertErrorFormat '''
    import foo, bar as baz from 'lib'
  ''', '''
    [stdin]:1:13: error: unexpected identifier
    import foo, bar as baz from 'lib'
                ^^^
  '''

test "cannot export * without a module to export from", ->
  assertErrorFormat '''
    export *
  ''', '''
    [stdin]:1:9: error: unexpected end of input
    export *
            ^
  '''

test "imports and exports must be top-level", ->
  assertErrorFormat '''
    if foo
      import { bar } from 'lib'
  ''', '''
    [stdin]:2:3: error: import statements must be at top-level scope
      import { bar } from 'lib'
      ^^^^^^^^^^^^^^^^^^^^^^^^^
  '''
  assertErrorFormat '''
    foo = ->
      export { bar }
  ''', '''
    [stdin]:2:3: error: export statements must be at top-level scope
      export { bar }
      ^^^^^^^^^^^^^^
  '''

test "cannot import the same member more than once", ->
  assertErrorFormat '''
    import { foo, foo } from 'lib'
  ''', '''
    [stdin]:1:15: error: 'foo' has already been declared
    import { foo, foo } from 'lib'
                  ^^^
  '''
  assertErrorFormat '''
    import { foo, bar, foo } from 'lib'
  ''', '''
    [stdin]:1:20: error: 'foo' has already been declared
    import { foo, bar, foo } from 'lib'
                       ^^^
  '''
  assertErrorFormat '''
    import { foo, bar as foo } from 'lib'
  ''', '''
    [stdin]:1:15: error: 'foo' has already been declared
    import { foo, bar as foo } from 'lib'
                  ^^^^^^^^^^
  '''
  assertErrorFormat '''
    import foo, { foo } from 'lib'
  ''', '''
    [stdin]:1:15: error: 'foo' has already been declared
    import foo, { foo } from 'lib'
                  ^^^
  '''
  assertErrorFormat '''
    import foo, { bar as foo } from 'lib'
  ''', '''
    [stdin]:1:15: error: 'foo' has already been declared
    import foo, { bar as foo } from 'lib'
                  ^^^^^^^^^^
  '''
  assertErrorFormat '''
    import foo from 'libA'
    import foo from 'libB'
  ''', '''
    [stdin]:2:8: error: 'foo' has already been declared
    import foo from 'libB'
           ^^^
  '''
  assertErrorFormat '''
    import * as foo from 'libA'
    import { foo } from 'libB'
  ''', '''
    [stdin]:2:10: error: 'foo' has already been declared
    import { foo } from 'libB'
             ^^^
  '''

test "imported members cannot be reassigned", ->
  assertErrorFormat '''
    import { foo } from 'lib'
    foo = 'bar'
  ''', '''
    [stdin]:2:1: error: 'foo' is read-only
    foo = 'bar'
    ^^^
  '''
  assertErrorFormat '''
    import { foo } from 'lib'
    export default foo = 'bar'
  ''', '''
    [stdin]:2:16: error: 'foo' is read-only
    export default foo = 'bar'
                   ^^^
  '''
  assertErrorFormat '''
    import { foo } from 'lib'
    export foo = 'bar'
  ''', '''
    [stdin]:2:8: error: 'foo' is read-only
    export foo = 'bar'
           ^^^
  '''

test "CoffeeScript keywords cannot be used as unaliased names in import lists", ->
  assertErrorFormat """
    import { unless, baz as bar } from 'lib'
    bar.barMethod()
  """, '''
    [stdin]:1:10: error: unexpected unless
    import { unless, baz as bar } from 'lib'
             ^^^^^^
  '''

test "CoffeeScript keywords cannot be used as local names in import list aliases", ->
  assertErrorFormat """
    import { bar as unless, baz as bar } from 'lib'
    bar.barMethod()
  """, '''
    [stdin]:1:17: error: unexpected unless
    import { bar as unless, baz as bar } from 'lib'
                    ^^^^^^
  '''

test "indexes are not supported in for-from loops", ->
  assertErrorFormat "x for x, i from [1, 2, 3]", '''
    [stdin]:1:10: error: cannot use index with for-from
    x for x, i from [1, 2, 3]
             ^
  '''

test "own is not supported in for-from loops", ->
  assertErrorFormat "x for own x from [1, 2, 3]", '''
    [stdin]:1:7: error: cannot use own with for-from
    x for own x from [1, 2, 3]
          ^^^
    '''

test "tagged template literals must be called by an identifier", ->
  assertErrorFormat "1''", '''
    [stdin]:1:1: error: literal is not a function
    1''
    ^
  '''
  assertErrorFormat '1""', '''
    [stdin]:1:1: error: literal is not a function
    1""
    ^
  '''
  assertErrorFormat "1'b'", '''
    [stdin]:1:1: error: literal is not a function
    1'b'
    ^
  '''
  assertErrorFormat '1"b"', '''
    [stdin]:1:1: error: literal is not a function
    1"b"
    ^
  '''
  assertErrorFormat "1'''b'''", """
    [stdin]:1:1: error: literal is not a function
    1'''b'''
    ^
  """
  assertErrorFormat '1"""b"""', '''
    [stdin]:1:1: error: literal is not a function
    1"""b"""
    ^
  '''
  assertErrorFormat '1"#{b}"', '''
    [stdin]:1:1: error: literal is not a function
    1"#{b}"
    ^
  '''
  assertErrorFormat '1"""#{b}"""', '''
    [stdin]:1:1: error: literal is not a function
    1"""#{b}"""
    ^
  '''

test "can't use pattern matches for loop indices", ->
  assertErrorFormat 'a for b, {c} in d', '''
    [stdin]:1:10: error: index cannot be a pattern matching expression
    a for b, {c} in d
             ^^^
  '''

test "#4248: Unicode code point escapes", ->
  assertErrorFormat '''
    "a
      #{b} \\u{G02}
     c"
  ''', '''
    [stdin]:2:8: error: invalid escape sequence \\u{G02}
      #{b} \\u{G02}
           ^\^^^^^^
  '''
  assertErrorFormat '''
    /a\\u{}b/
  ''', '''
    [stdin]:1:3: error: invalid escape sequence \\u{}
    /a\\u{}b/
      ^\^^^
  '''
  assertErrorFormat '''
    ///a \\u{01abc///
  ''', '''
    [stdin]:1:6: error: invalid escape sequence \\u{01abc
    ///a \\u{01abc///
         ^\^^^^^^^
  '''

  assertErrorFormat '''
    /\\u{123} \\u{110000}/
  ''', '''
    [stdin]:1:10: error: unicode code point escapes greater than \\u{10ffff} are not allowed
    /\\u{123} \\u{110000}/
      \       ^\^^^^^^^^^
  '''

  assertErrorFormat '''
    ///abc\\\\\\u{123456}///u
  ''', '''
    [stdin]:1:9: error: unicode code point escapes greater than \\u{10ffff} are not allowed
    ///abc\\\\\\u{123456}///u
           \ \^\^^^^^^^^^
  '''

  assertErrorFormat '''
    """
      \\u{123}
      a
        \\u{00110000}
      #{ 'b' }
    """
  ''', '''
    [stdin]:4:5: error: unicode code point escapes greater than \\u{10ffff} are not allowed
        \\u{00110000}
        ^\^^^^^^^^^^^
  '''

  assertErrorFormat '''
    '\\u{a}\\u{1111110000}'
  ''', '''
    [stdin]:1:7: error: unicode code point escapes greater than \\u{10ffff} are not allowed
    '\\u{a}\\u{1111110000}'
      \    ^\^^^^^^^^^^^^^
  '''

test "#4283: error message for implicit call", ->
  assertErrorFormat '''
    console.log {search, users, contacts users_to_display}
  ''', '''
    [stdin]:1:29: error: unexpected implicit function call
    console.log {search, users, contacts users_to_display}
                                ^^^^^^^^
  '''

test "#3199: error message for call indented non-object", ->
  assertErrorFormat '''
    fn = ->
    fn
      1
  ''', '''
    [stdin]:3:1: error: unexpected indentation
      1
    ^^
  '''

test "#3199: error message for call indented comprehension", ->
  assertErrorFormat '''
    fn = ->
    fn
      x for x in [1, 2, 3]
  ''', '''
    [stdin]:3:1: error: unexpected indentation
      x for x in [1, 2, 3]
    ^^
  '''

test "#3199: error message for return indented non-object", ->
  assertErrorFormat '''
    return
      1
  ''', '''
    [stdin]:2:3: error: unexpected number
      1
      ^
  '''

test "#3199: error message for return indented comprehension", ->
  assertErrorFormat '''
    return
      x for x in [1, 2, 3]
  ''', '''
    [stdin]:2:3: error: unexpected identifier
      x for x in [1, 2, 3]
      ^
  '''
