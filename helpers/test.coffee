# async = require "async"
# async.parallel [
#   (callback) ->
#     setTimeout ->
#       console.log 'Task One'
#       callback null, 1
#       return
#     , 200
#     return
#   (callback) ->
#     setTimeout ->
#       console.log 'Task Two'
#       callback null, 2
#       return
#     , 100
#     return
# ]


Redis                       = require("ioredis")
redis                       = new Redis 6379
fibrous = require "fibrous"
async = require "async"

pipeline = redis.pipeline()
productIdPipeline = redis.pipeline()

portal_id = 1
# __uid = "68f5b35e-b5d8-4bae-b1ad-039cb6e3b1f3"
# category = "phu_kien_dien_thoai"
# limit = 3

# keySameCategory = "portal:#{portal_id}:category:#{category}:mostview"
# keyRecentlyView = "portal:#{portal_id}:user:#{__uid}:mostview"

{ readHtml, buildHtml }     = require("../helpers/doT.coffee")

# func1 = (callback) ->
#   pipeline.zrevrange(keySameCategory, 0, limit - 1, "WITHSCORES").zrevrange(keyRecentlyView, 0, limit - 1, "WITHSCORES")
#   pipeline.exec (err, res) ->
#     console.log res
#     callback null, res

# func2 = (rs, callback) ->
#   console.log "rs: ", rs
#   productIdSameCategory = rs[0][1].filter (_, i) -> i % 2 == 0
#   productViewSameCategory = rs[0][1].filter (_, i) -> i % 2 == 1
#   productIdRecentlyView = rs[1][1].filter (_, i) -> i % 2 == 0
#   productViewRecentlyView = rs[1][1].filter (_, i) -> i % 2 == 1
#   console.log productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView

#   callback null, productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView

# func3 = (productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView, callback) ->
#   console.log "productIdSameCategory: ", productIdSameCategory
#   for productId in productIdSameCategory
#     console.log "portal:#{portal_id}:products:#{productId}"
#     productIdPipeline.hgetall("portal:#{portal_id}:products:#{productId}")
#   for productId in productIdRecentlyView
#     productIdPipeline.hgetall("portal:#{portal_id}:products:#{productId}")

#   productIdPipeline.exec (err, rs) ->
#     console.log "rs: ", rs[1][1]
#     callback(null, rs)

# async.waterfall [func1, func2, func3], (err, results) -> console.log results

readHtml "../view/portal_#{portal_id}.html", (err, rs) -> console.log "rs: ", rs
# console.log "template: ", template