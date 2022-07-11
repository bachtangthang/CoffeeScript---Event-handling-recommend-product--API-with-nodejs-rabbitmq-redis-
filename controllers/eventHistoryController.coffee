{ eventHistoryModel } 			= require("../models/index.coffee")
amqp                        = require "amqplib/callback_api"

RABBIT_URL                  = process.env.RABBIT_URL

RABBIT_QUEUE_NAME           = "event"
table                       = "event_histores"

Redis                       = require("ioredis")
redis                       = new Redis 6379
{ xoa_dau }                 = require("../helpers/xoadau.coffee")
{ readHtml, buildHtml }     = require("../helpers/doT.coffee")
fibrous                     = require("fibrous")
async                       = require("async")

channel = undefined

amqp.connect RABBIT_URL, (error0, connection) ->
  if error0
    throw error0
  connection.createChannel((error1, ch) ->
    if error1
      throw error1
    ch.assertQueue RABBIT_QUEUE_NAME, durable: false
    channel = ch
    return
  )
  return

events = (req, res) ->
  try
    { __uid, event, products, portal_id, limit } = req.body
    { category } = products[0]
    channel.sendToQueue RABBIT_QUEUE_NAME, Buffer.from(JSON.stringify(req.body))
    category = xoa_dau(category)

    keySameCategory = "portal:#{portal_id}:category:#{category}:mostview"
    keyRecentlyView = "portal:#{portal_id}:user:#{__uid}:mostview"
    #pipeline for retriving products
    pipeline = redis.pipeline()
    productIdPipeline = redis.pipeline()

    func1 = (callback) ->
      pipeline.zrevrange(keySameCategory, 0, limit - 1, "WITHSCORES").zrevrange(keyRecentlyView, 0, limit - 1, "WITHSCORES")
      pipeline.exec (err, res) ->
        callback null, res
    
    func2 = (rs, callback) ->
      console.log "rs: ", rs
      productIdSameCategory = rs[0][1].filter (_, i) -> i % 2 == 0
      productViewSameCategory = rs[0][1].filter (_, i) -> i % 2 == 1
      productIdRecentlyView = rs[1][1].filter (_, i) -> i % 2 == 0
      productViewRecentlyView = rs[1][1].filter (_, i) -> i % 2 == 1
      console.log productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView

      callback null, productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView
    
    func3 = (productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView, callback) ->
      try
        for productId in productIdSameCategory
          productIdPipeline.hgetall("portal:#{portal_id}:products:#{productId}")
        for productId in productIdRecentlyView
          productIdPipeline.hgetall("portal:#{portal_id}:products:#{productId}")

        productIdPipeline.exec (err, rs) ->
          console.log "rs: ", rs[0][1]
          callback(null, rs, productIdSameCategory.length, productViewSameCategory, productViewRecentlyView)
      catch err
        console.log err

    func4 = (productInfoResult, length, productViewSameCategory, productViewRecentlyView, callback) ->
      console.log productInfoResult
      productInfo = []
      i = 0
      while i < productInfoResult.length
        productInfo = productInfo.concat(productInfoResult[i][1])
        i++
      console.log "productInfo:", productInfo
              
      productSameCategory = productInfo.slice(0, length).map (cur, index) ->
        ({ ...cur, view: productViewSameCategory[index] })
      productRecentlyView = productInfo.slice(length).map (cur, index) ->
        ({ ...cur, view: productViewRecentlyView[index] })
      callback(null, { productSameCategory, productRecentlyView })

    async.waterfall [func1, func2, func3, func4], (err, result) ->
      console.log "productSameCategory: ", result.productSameCategory
      console.log "productRecentlyView: ", result.productRecentlyView
      fibrous.run () ->
        template = readHtml.sync "./view/portal_#{portal_id}.html"
        return template
      , (err, rs) ->
          console.log rs
          htmlSameCategory = buildHtml(
            rs,
            result.productSameCategory,
            "Top product of the same category")

          htmlRecentlyView = buildHtml(
            rs,
            result.productRecentlyView,
            "Recently view product")
        
          console.log "html Same category:  #{htmlSameCategory}"
          console.log "html recently view: #{htmlRecentlyView}"

          res.json { htmlSameCategory, htmlRecentlyView }
      
  catch err
    data =
      success: false,
      message: err.message
    console.log err.message
    return res.status(500).json data

module.exports = events: events