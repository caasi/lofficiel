{map, flatten, filter, foldr1} = require 'prelude-ls'

# prepare promises
require! fs
require! request
Promise = require 'bluebird'
readdir = Promise.promisify fs.readdir
mkdir   = Promise.promisify fs.mkdir
exists  = (path) ->
  new Promise (resolve) ->
    result <- fs.exists path
    resolve result

# configs
src = 'http://patrimoine.editionsjalou.com/inc/imprime_image.php?pp=pdf&idp='
pre = 'lofficiel-'
ext = '.jpeg'
dirs = do
  "0000":
    start: 1
    end:   1000
  "386000":
    start: 0
    end:   130
for i from 1 to 385
  dirs["#{i}000"] = do
    start: 0
    end:   1000

check-dir = (name) ->
  new Promise (resolve, reject) ->
    base = +name
    path = "./#{name}"
    exists path
      .then (exist) -> mkdir path if not exist
      .then         -> readdir path
      .then (files) ->
        range = dirs[name]
        if files.length isnt range.end - range.start
          tested = for let i from range.start til range.end
            remote-path = "#{src}#{base + i}"
            local-name = "#{pre}#{base + i}#{ext}"
            local-path = "#{path}/#{local-name}"
            if not (local-name in files)
              src: remote-path
              dest: local-path
          resolve filter (isnt undefined), tested
        else
          resolve []

should-end = false
process.on \SIGINT !->
  should-end := true
  console.log "wait for last file to finish..."

console.log 'checking existing files...'
Promise.all([0 to 386] |> map (-> "#{it}000") |> map check-dir)
  .then (pathes) ->
    pathes = flatten pathes
    console.log "files to download: #{pathes.length}"
    #i = 0
    get-image = ->
      return if i is pathes.length or should-end
      path = pathes.shift!
      bytes-saved = 0
      console.log "save to #{path.dest}..."
      request path.src
        .pipe fs.createWriteStream path.dest
        .on \error  !(err) -> throw err
        .on \data   !-> bytes-saved += it.length
        .on \finish !->
          if bytes-saved is 0
            throw new Error 'possibly banned by the server'
          else
            get-image!
    parallel = +process.argv.2 or 1
    for i til parallel
      setTimeout (-> get-image!), i * 500
  .catch console.log

