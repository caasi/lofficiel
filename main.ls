_ = require 'prelude-ls'
require! fs
require! request

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
  to-download = {}
  base = +name
  path = "./#{name}"
  fs.mkdirSync path if not fs.existsSync path
  files = fs.readdirSync path
  range = dirs[name]
  if files.length isnt range.end - range.start
    for let i from range.start til range.end
      remote-path = "#{src}#{base + i}"
      local-path = "#{path}/#{pre}#{base + i}#{ext}"
      if not fs.existsSync local-path
        to-download[remote-path] = local-path
  to-download

console.log 'checking existing files...'
files = [0 to 386] |> _.map (-> "#{it}000") |> _.map check-dir |> _.fold (<<<), {}

keys = Object.keys files
console.log "files to download: #{keys.length}"

should-end = false
j = 0
:get-next-image let
  return if j is keys.length or should-end
  k = keys[j]
  v = files[k]
  console.log v
  request k
    .pipe fs.createWriteStream v
    .on \finish ->
      j := j + 1
      get-next-image!

process.on \SIGINT !->
  should-end := true
  console.log "waiting for last file to finish..."

