# CoffeeScript can be used both on the server, as a command-line compiler based
# on Node.js/V8, or to run CoffeeScript directly in the browser. This module
# contains the main entry functions for tokenizing, parsing, and compiling
# source CoffeeScript into JavaScript.

fs            = require 'fs'
vm            = require 'vm'
path          = require 'path'
{Lexer}       = require './lexer'
{parser}      = require './parser'
helpers       = require './helpers'
SourceMap     = require './sourcemap'
# Require `package.json`, which is two levels above this file, as this file is
# evaluated from `lib/coffee-script`.
packageJson   = require '../../package.json'

# The current CoffeeScript version number.
exports.VERSION = packageJson.version

exports.FILE_EXTENSIONS = ['.coffee', '.litcoffee', '.coffee.md']

# Expose helpers for testing.
exports.helpers = helpers

# Function that allows for btoa in both nodejs and the browser.
base64encode = (src) -> switch
  when typeof Buffer is 'function'
    new Buffer(src).toString('base64')
  when typeof btoa is 'function'
    # The contents of a `<script>` block are encoded via UTF-16, so if any extended
    # characters are used in the block, btoa will fail as it maxes out at UTF-8.
    # See https://developer.mozilla.org/en-US/docs/Web/API/WindowBase64/Base64_encoding_and_decoding#The_Unicode_Problem
    # for the gory details, and for the solution implemented here.
    btoa encodeURIComponent(src).replace /%([0-9A-F]{2})/g, (match, p1) ->
      String.fromCharCode '0x' + p1
  else
    throw new Error('Unable to base64 encode inline sourcemap.')

# Function wrapper to add source file information to SyntaxErrors thrown by the
# lexer/parser/compiler.
withPrettyErrors = (fn) ->
  (code, options = {}) ->
    try
      fn.call @, code, options
    catch err
      throw err if typeof code isnt 'string' # Support `CoffeeScript.nodes(tokens)`.
      throw helpers.updateSyntaxError err, code, options.filename

# For each compiled file, save its source in memory in case we need to
# recompile it later. We might need to recompile if the first compilation
# didn’t create a source map (faster) but something went wrong and we need
# a stack trace. Assuming that most of the time, code isn’t throwing
# exceptions, it’s probably more efficient to compile twice only when we
# need a stack trace, rather than always generating a source map even when
# it’s not likely to be used. Save in form of `filename`: `(source)`
sources = {}
# Also save source maps if generated, in form of `filename`: `(source map)`.
sourceMaps = {}

# Compile CoffeeScript code to JavaScript, using the Coffee/Jison compiler.
#
# If `options.sourceMap` is specified, then `options.filename` must also be
# specified. All options that can be passed to `SourceMap#generate` may also
# be passed here.
#
# This returns a javascript string, unless `options.sourceMap` is passed,
# in which case this returns a `{js, v3SourceMap, sourceMap}`
# object, where sourceMap is a sourcemap.coffee#SourceMap object, handy for
# doing programmatic lookups.
exports.compile = compile = withPrettyErrors (code, options) ->
  {merge, extend} = helpers
  options = extend {}, options
  # Always generate a source map if no filename is passed in, since without a
  # a filename we have no way to retrieve this source later in the event that
  # we need to recompile it to get a source map for `prepareStackTrace`.
  generateSourceMap = options.sourceMap or options.inlineMap or not options.filename?
  filename = options.filename or '<anonymous>'

  sources[filename] = code
  map = new SourceMap if generateSourceMap

  tokens = lexer.tokenize code, options

  # Pass a list of referenced variables, so that generated variables won't get
  # the same name.
  options.referencedVars = (
    token[1] for token in tokens when token[0] is 'IDENTIFIER'
  )

  # Check for import or export; if found, force bare mode.
  unless options.bare? and options.bare is yes
    for token in tokens
      if token[0] in ['IMPORT', 'EXPORT']
        options.bare = yes
        break

  fragments = parser.parse(tokens).compileToFragments options

  currentLine = 0
  currentLine += 1 if options.header
  currentLine += 1 if options.shiftLine
  currentColumn = 0
  js = ""
  for fragment in fragments
    # Update the sourcemap with data from each fragment.
    if generateSourceMap
      # Do not include empty, whitespace, or semicolon-only fragments.
      if fragment.locationData and not /^[;\s]*$/.test fragment.code
        map.add(
          [fragment.locationData.first_line, fragment.locationData.first_column]
          [currentLine, currentColumn]
          {noReplace: true})
      newLines = helpers.count fragment.code, "\n"
      currentLine += newLines
      if newLines
        currentColumn = fragment.code.length - (fragment.code.lastIndexOf("\n") + 1)
      else
        currentColumn += fragment.code.length

    # Copy the code from each fragment into the final JavaScript.
    js += fragment.code

  if options.header
    header = "Generated by CoffeeScript #{@VERSION}"
    js = "// #{header}\n#{js}"

  if generateSourceMap
    v3SourceMap = map.generate(options, code)
    sourceMaps[filename] = map

  if options.inlineMap
    encoded = base64encode JSON.stringify v3SourceMap
    sourceMapDataURI = "//# sourceMappingURL=data:application/json;base64,#{encoded}"
    sourceURL = "//# sourceURL=#{options.filename ? 'coffeescript'}"
    js = "#{js}\n#{sourceMapDataURI}\n#{sourceURL}"

  if options.sourceMap
    {
      js
      sourceMap: map
      v3SourceMap: JSON.stringify v3SourceMap, null, 2
    }
  else
    js

# Tokenize a string of CoffeeScript code, and return the array of tokens.
exports.tokens = withPrettyErrors (code, options) ->
  lexer.tokenize code, options

# Parse a string of CoffeeScript code or an array of lexed tokens, and
# return the AST. You can then compile it by calling `.compile()` on the root,
# or traverse it by using `.traverseChildren()` with a callback.
exports.nodes = withPrettyErrors (source, options) ->
  if typeof source is 'string'
    parser.parse lexer.tokenize source, options
  else
    parser.parse source

# Compile and execute a string of CoffeeScript (on the server), correctly
# setting `__filename`, `__dirname`, and relative `require()`.
exports.run = (code, options = {}) ->
  mainModule = require.main

  # Set the filename.
  mainModule.filename = process.argv[1] =
    if options.filename then fs.realpathSync(options.filename) else '<anonymous>'

  # Clear the module cache.
  mainModule.moduleCache and= {}

  # Assign paths for node_modules loading
  dir = if options.filename?
    path.dirname fs.realpathSync options.filename
  else
    fs.realpathSync '.'
  mainModule.paths = require('module')._nodeModulePaths dir

  # Compile.
  if not helpers.isCoffee(mainModule.filename) or require.extensions
    answer = compile code, options
    code = answer.js ? answer

  mainModule._compile code, mainModule.filename

# Compile and evaluate a string of CoffeeScript (in a Node.js-like environment).
# The CoffeeScript REPL uses this to run the input.
exports.eval = (code, options = {}) ->
  return unless code = code.trim()
  createContext = vm.Script.createContext ? vm.createContext

  isContext = vm.isContext ? (ctx) ->
    options.sandbox instanceof createContext().constructor

  if createContext
    if options.sandbox?
      if isContext options.sandbox
        sandbox = options.sandbox
      else
        sandbox = createContext()
        sandbox[k] = v for own k, v of options.sandbox
      sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox
    else
      sandbox = global
    sandbox.__filename = options.filename || 'eval'
    sandbox.__dirname  = path.dirname sandbox.__filename
    # define module/require only if they chose not to specify their own
    unless sandbox isnt global or sandbox.module or sandbox.require
      Module = require 'module'
      sandbox.module  = _module  = new Module(options.modulename || 'eval')
      sandbox.require = _require = (path) ->  Module._load path, _module, true
      _module.filename = sandbox.__filename
      for r in Object.getOwnPropertyNames require when r not in ['paths', 'arguments', 'caller']
        _require[r] = require[r]
      # use the same hack node currently uses for their own REPL
      _require.paths = _module.paths = Module._nodeModulePaths process.cwd()
      _require.resolve = (request) -> Module._resolveFilename request, _module
  o = {}
  o[k] = v for own k, v of options
  o.bare = on # ensure return value
  js = compile code, o
  if sandbox is global
    vm.runInThisContext js
  else
    vm.runInContext js, sandbox

exports.register = -> require './register'

# Throw error with deprecation warning when depending upon implicit `require.extensions` registration
if require.extensions
  for ext in @FILE_EXTENSIONS then do (ext) ->
    require.extensions[ext] ?= ->
      throw new Error """
      Use CoffeeScript.register() or require the coffee-script/register module to require #{ext} files.
      """

exports._compileFile = (filename, sourceMap = no, inlineMap = no) ->
  raw = fs.readFileSync filename, 'utf8'
  # Strip the Unicode byte order mark, if this file begins with one.
  stripped = if raw.charCodeAt(0) is 0xFEFF then raw.substring 1 else raw

  try
    answer = compile stripped, {
      filename, sourceMap, inlineMap
      sourceFiles: [filename]
      literate: helpers.isLiterate filename
    }
  catch err
    # As the filename and code of a dynamically loaded file will be different
    # from the original file compiled with CoffeeScript.run, add that
    # information to error so it can be pretty-printed later.
    throw helpers.updateSyntaxError err, stripped, filename

  answer

# Instantiate a Lexer for our use here.
lexer = new Lexer

# The real Lexer produces a generic stream of tokens. This object provides a
# thin wrapper around it, compatible with the Jison API. We can then pass it
# directly as a "Jison lexer".
parser.lexer =
  lex: ->
    token = parser.tokens[@pos++]
    if token
      [tag, @yytext, @yylloc] = token
      parser.errorToken = token.origin or token
      @yylineno = @yylloc.first_line
    else
      tag = ''

    tag
  setInput: (tokens) ->
    parser.tokens = tokens
    @pos = 0
  upcomingInput: ->
    ""
# Make all the AST nodes visible to the parser.
parser.yy = require './nodes'

# Override Jison's default error handling function.
parser.yy.parseError = (message, {token}) ->
  # Disregard Jison's message, it contains redundant line number information.
  # Disregard the token, we take its value directly from the lexer in case
  # the error is caused by a generated token which might refer to its origin.
  {errorToken, tokens} = parser
  [errorTag, errorText, errorLoc] = errorToken

  errorText = switch
    when errorToken is tokens[tokens.length - 1]
      'end of input'
    when errorTag in ['INDENT', 'OUTDENT']
      'indentation'
    when errorTag in ['IDENTIFIER', 'NUMBER', 'INFINITY', 'STRING', 'STRING_START', 'REGEX', 'REGEX_START']
      errorTag.replace(/_START$/, '').toLowerCase()
    else
      helpers.nameWhitespaceCharacter errorText

  # The second argument has a `loc` property, which should have the location
  # data for this token. Unfortunately, Jison seems to send an outdated `loc`
  # (from the previous token), so we take the location information directly
  # from the lexer.
  helpers.throwSyntaxError "unexpected #{errorText}", errorLoc

# Based on http://v8.googlecode.com/svn/branches/bleeding_edge/src/messages.js
# Modified to handle sourceMap
formatSourcePosition = (frame, getSourceMapping) ->
  filename = undefined
  fileLocation = ''

  if frame.isNative()
    fileLocation = "native"
  else
    if frame.isEval()
      filename = frame.getScriptNameOrSourceURL()
      fileLocation = "#{frame.getEvalOrigin()}, " unless filename
    else
      filename = frame.getFileName()

    filename or= "<anonymous>"

    line = frame.getLineNumber()
    column = frame.getColumnNumber()

    # Check for a sourceMap position
    source = getSourceMapping filename, line, column
    fileLocation =
      if source
        "#{filename}:#{source[0]}:#{source[1]}"
      else
        "#{filename}:#{line}:#{column}"

  functionName = frame.getFunctionName()
  isConstructor = frame.isConstructor()
  isMethodCall = not (frame.isToplevel() or isConstructor)

  if isMethodCall
    methodName = frame.getMethodName()
    typeName = frame.getTypeName()

    if functionName
      tp = as = ''
      if typeName and functionName.indexOf typeName
        tp = "#{typeName}."
      if methodName and functionName.indexOf(".#{methodName}") isnt functionName.length - methodName.length - 1
        as = " [as #{methodName}]"

      "#{tp}#{functionName}#{as} (#{fileLocation})"
    else
      "#{typeName}.#{methodName or '<anonymous>'} (#{fileLocation})"
  else if isConstructor
    "new #{functionName or '<anonymous>'} (#{fileLocation})"
  else if functionName
    "#{functionName} (#{fileLocation})"
  else
    fileLocation

getSourceMap = (filename) ->
  if sourceMaps[filename]?
    sourceMaps[filename]
  # CoffeeScript compiled in a browser may get compiled with `options.filename`
  # of `<anonymous>`, but the browser may request the stack trace with the
  # filename of the script file.
  else if sourceMaps['<anonymous>']?
    sourceMaps['<anonymous>']
  else if sources[filename]?
    answer = compile sources[filename],
      filename: filename
      sourceMap: yes
      literate: helpers.isLiterate filename
    answer.sourceMap
  else
    null

# Based on [michaelficarra/CoffeeScriptRedux](http://goo.gl/ZTx1p)
# NodeJS / V8 have no support for transforming positions in stack traces using
# sourceMap, so we must monkey-patch Error to display CoffeeScript source
# positions.
Error.prepareStackTrace = (err, stack) ->
  getSourceMapping = (filename, line, column) ->
    sourceMap = getSourceMap filename
    answer = sourceMap.sourceLocation [line - 1, column - 1] if sourceMap?
    if answer? then [answer[0] + 1, answer[1] + 1] else null

  frames = for frame in stack
    break if frame.getFunction() is exports.run
    "    at #{formatSourcePosition frame, getSourceMapping}"

  "#{err.toString()}\n#{frames.join '\n'}\n"
