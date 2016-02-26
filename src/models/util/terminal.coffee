spawn = require('child_process').spawn
stripAnsi = require 'strip-ansi'
ks = require 'kefir-storage'

# current pty stream
ptyStream = null
logName = 'terminal:output'

model = {}

# returns pseudo terminal instance depending on the OS
# in windows return only standard child_process.spawn
# in linux/osx return pty in order to capture sudo prompts
# note windows: redirects stderr.data to stdout.data for a unified interface
model._createPTY = (command, options) ->
  options = {} if ! options
  options.cwd = process.cwd() if ! options.cwd
  options.env = process.env if ! options.env

  sh = 'sh'
  shFlag = '-c'

  #@todo fix colored output
  if process.platform != 'win32' && !process.env.EINOPF_PTY_FORCE_CHILD
    pty = require 'pty.js' # windows should not even install this
    return pty.spawn sh, [shFlag, command], options

  if process.platform == 'win32'
    sh = process.env.comspec || 'cmd'
    shFlag = '/d /s /c'
    options.windowsVerbatimArguments = true

  return spawn sh, [shFlag, command], options

model.createPTYStream = (cmd, options, callback) ->
  return callback new Error 'No command specified' if ! cmd
  error = null

  ks.log 'terminal:output', {text: 'running cmd: ' + cmd}

  ptyStream = model._createPTY cmd, options
  ptyStream.stdout.on 'data', (val) ->
    opts = {text: model.formatTerminalOutput(val)}

    # when pty match for sudo password input
    if ptyStream.pty && (opts.text.match /(\[sudo\] password|Password:)/ )
      opts.input = true
      opts.secret = true
    ks.log 'terminal:output', opts

  # use stdin and stderr when not in pty mode
  if !ptyStream.pty
    ptyStream.stdin.on 'data', (val) ->
      ks.log 'terminal:output', {text: model.formatTerminalOutput(val), input: true, secret: true}
    ptyStream.stderr.on 'data', (val) ->
      ks.log 'terminal:output', {text: model.formatTerminalOutput(val), error: true}

  ptyStream.on 'error', (err) ->
    return false if err.code == "EIO" # ignore EIO error -> just means terminal was stopped
    error = err
    ks.log 'terminal:output', {text: err.toString()}
  ptyStream.on 'close', () -> # when child_process.* fails on spawning then exit will not be emitted
    ptyStream.emit 'exit', 1 if error && ptyStream && !ptyStream.pty
  ptyStream.on 'exit', (code) ->
    ptyStream = null # reset terminal instance
    return callback error || new Error 'Error: command failed' if code != 0
    ks.log 'terminal:output', {text: 'done cmd: ' + cmd}
    return callback null, true

# removes ansi escape sequences and ending new line
model.formatTerminalOutput = (output) ->
  return stripAnsi(output.toString()).replace(/(\r\n|\n)$/g, '')

model.killPty = () ->
  ptyStream.kill() if ptyStream

model.getPTYStream = () ->
  return ptyStream || null

model.writeIntoPTY = (input) ->
  return false if ! ptyStream || !ptyStream.stdin

  ptyStream.stdin.write input + '\n'
  return true

module.exports = model