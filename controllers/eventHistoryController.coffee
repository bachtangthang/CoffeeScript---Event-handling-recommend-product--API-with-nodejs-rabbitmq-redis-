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


    getMostViewData = (callback) ->
      pipeline = redis.pipeline()
      pipeline.zrevrange(keySameCategory, 0, limit - 1, "WITHSCORES").zrevrange(keyRecentlyView, 0, limit - 1, "WITHSCORES")
      pipeline.exec (err, data) ->
        console.log "err: ", err
        console.log "pipeline.exec results: ", data
        productIdSameCategory = data[0][1].filter (_, i) -> i % 2 == 0
        productViewSameCategory = data[0][1].filter (_, i) -> i % 2 == 1
        productIdRecentlyView = data[1][1].filter (_, i) -> i % 2 == 0
        productViewRecentlyView = data[1][1].filter (_, i) -> i % 2 == 1
        console.log productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView

        callback err, { productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView }
    
    getProductData = ({ productIdSameCategory, productViewSameCategory, productIdRecentlyView, productViewRecentlyView }, callback) ->
      productIdPipeline = redis.pipeline()
      try
        for productId in productIdSameCategory
          console.log " productId: ", productId
          productIdPipeline.hgetall("portal:#{portal_id}:products:#{productId}")
        for productId in productIdRecentlyView
          productIdPipeline.hgetall("portal:#{portal_id}:products:#{productId}")
        length = productIdSameCategory.length
        productIdPipeline.exec (err, products) ->
          console.log "product.length: ", products.length
          console.log "productIdSameCategory.length: ", length
          callback err, { products, length, productViewSameCategory, productViewRecentlyView }

      catch err
        console.log "err in getProductData: ", err
        callback err, null

    combineProductData = ({ products, length, productViewSameCategory, productViewRecentlyView }, callback) ->
      console.log "length: ", length
      console.log products.length
      productInfo = []
      i = 0
      while i < products.length
        productInfo = productInfo.concat(products[i][1])
        i++
      console.log "productInfo:", productInfo
              
      productSameCategory = productInfo.slice(0, length).map (cur, index) ->
        ({ ...cur, view: productViewSameCategory[index] })
      productRecentlyView = productInfo.slice(length).map (cur, index) ->
        ({ ...cur, view: productViewRecentlyView[index] })
      callback(null, { productSameCategory, productRecentlyView })
  
    fibrous.run () ->
      mostViewData = getMostViewData.sync()
      productData = getProductData.sync mostViewData
      data = combineProductData.sync productData
      template = readHtml.sync "./view/portal_#{portal_id}.html"
      return { data, template }
    , (err, result) ->
      if err?
        console.log "err: ", err
        res.json { err }
      else
        console.log result
        htmlSameCategory = buildHtml(
          result.template,
          result.data.productSameCategory,
          "Top product of the same category")

        htmlRecentlyView = buildHtml(
          result.template,
          result.data.productRecentlyView,
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