program = require 'commander'
fbp = require 'fbp'
path = require 'path'
fs = require 'fs'
library = require './library'

readGraph = (filepath, callback) ->
  ext = path.extname filepath
  fs.readFile filepath, { encoding: 'utf-8' }, (err, contents) =>
    return callback err if err
    try
      if ext == '.fbp'
        graph = fbp.parse contents
      else
        graph = JSON.parse contents
      return callback null, graph
    catch e
      return callback e

# Generating Heroku/foreman Profile definiton
# from a FBP graph definition
exports.generate = generate = (graph, options) ->
  libOptions =
    configfile: options.library
  libOptions.configfile = path.join(process.cwd(), 'package.json') if not libOptions.configfile

  lib = new library.Library libOptions

  lines = []
  for name, proc of graph.processes
    continue if name in options.ignore
    component = proc.component
    cmd = lib.componentCommand component, name
    lines.push "#{name}: #{cmd}"

  includes = options.include.join '\n'
  out = lines.join '\n'
  return "#{out}\n#{includes}"


exports.parse = parse = (args) ->
  addInclude = (include, list) ->
    list.push include
    return list

  addIgnore = (ignore, list) ->
    list.push ignore
    return list

  graph = null
  program
    .arguments('<graph.fbp/.json>')
    .option('--library <FILE.json>', 'Use FILE.json as the library definition', String, 'package.json')
    .option('--ignore [NODE]', 'Do not generate output for NODE. Can be specified multiple times.', addIgnore, [])
    .option('--include [DATA]', 'Include DATA as-is in generated file. Can be specified multiple times.', addInclude, [])
    .action (gr, env) ->
      graph = gr
    .parse args

  program.graphfile = graph
  return program

exports.main = main = () ->
  options = parse process.argv

  if not options.graphfile
    console.error 'ERROR: No graph file specified'
    program.help()
    process.exit()

  readGraph options.graphfile, (err, graph) ->
    throw err if err
    out = generate graph, options
    # TODO: support writing directly to Procfile?
    console.log out

