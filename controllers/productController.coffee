{ productModel }            = require("../models/index.coffee")
amqp                        = require "amqplib/callback_api"

RABBIT_URL                  = process.env.RABBIT_URL

RABBIT_QUEUE_NAME           = "product"
DEFAULT_COLUMNS             = "id,product_name"

Redis                       = require("ioredis")
redis                       = new Redis 6379
{ xoa_dau }                 = require("../helpers/xoadau.coffee")
fibrous                     = require("fibrous")
async                       = require("async")
fs                          = require("fs")

channel = undefined
connection = undefined

amqp.connect RABBIT_URL, (error0, connection) ->
  throw error0 if error0
  channel = connection.createChannel (error1, ch) ->
    throw error1 if error1
    ch.assertQueue RABBIT_QUEUE_NAME, { durable: false }


getDetail = (req, res) ->
  try
    { id }          = req.params
    { columns }     = req.query
    fibrous.run () ->
      result = productModel.sync.getDetail id, columns
      return result
    , (err, rs) ->
      if err?
        console.log "error: ", err
        res.status(500).json err
      else
        console.log "success result", rs
        res.status(200).json rs
        
  catch err
    data  =
      success: false
      message: err.message
    res.status(500).json data

updateProductById = (req, res) ->
  try
    { id } = req.params
    payload = req.body
    fibrous.run () ->
      product = productModel.sync.update id, payload
      console.log product
      return product
    , (err, rs) ->
        if err? then res.status(500).json err
        else
          { product_id }  = rs
          if rs != null
            channel.sendToQueue RABBIT_QUEUE_NAME, Buffer.from JSON.stringify(product_id)
          res.status(200).json rs
  catch err
    data =
      success: false
      message: err.message
    res.status(500).json data

deleteProductById = (req, res) ->
  try
    { id } = req.params
    console.log id
    fibrous.run () ->
      console.log "123"
      product  = productModel.sync.delete id
      console.log product
      return product
    , (err, rs) ->
      if err? then res.status(500).json err
      else
        res.status(200).json rs
  catch err
    data =
      success: false
      message: err.message
    res.status(500).json data

# getProductFromRedis = (req, res) ->
#   try
#     { id }          = req.params
#     { columns }     = req.query
#     colums = colums || DEFAULT_COLUMNS
#     columns = columns.split ","
#     if redis.hget("products:#{id}", "product_id") != null
#       product = redis.hgetall("products:#{id}")
#       console.log product
#       res.status(200).json(product)
#     else
#       product = productModel.sync.getDetail id, columns
#       console.log product[0]
#       channel.sendToQueue RABBIT_QUEUE_NAME, Buffer.from(JSON.stringify(id))
#       res.status(200).json(product[0])
#   catch err
#     data    =
#       success: false
#       message: err.message
#     res.status(500).json data

upsertMany = (req, res) ->
  try
    console.time "test"
    fibrous.run () ->
      upsertedProducts = productModel.sync.upsertMany(req.body)
      return upsertedProducts
    , (err, rs) ->
      if err?
        console.log err
        res.status(500).json err
      else
        console.log "rs: ", rs
        console.timeEnd "test"
        res.status(200).json rs
  catch err
    data =
      success: false
      message: err.message
    res.status(500).json data

upsertManyLoop = (req, res) ->
  try
    console.time "test"
    fibrous.run () ->
      upsertedProducts = productModel.sync.upsertManyLoop(req.body)
      return upsertedProducts
    , (err, rs) ->
      if err?
        console.log err
        res.status(500).json err
      else
        console.log "rs: ", rs
        console.timeEnd "test"
        res.status(200).json rs
  catch err
    data =
      success: false
      message: err.message
    res.status(500).json data

getAll = (req, res) ->
  try
    { filters, limit, page, sort_by, sort, columns } = req.query
    offset = ( page - 1 ) * limit
    console.log offset
    filter = JSON.parse filters
    console.log filters

    fibrous.run () ->
      allProducts = productModel.sync.get filter, limit, offset, sort_by, sort, columns
      return allProducts
    , (err, rs) ->
      if err?
        res.status(500).json err
      else
        console.log "success result", rs
        res.status(200).json rs
  catch err
    data  =
      success: false
      message: err.message
    console.log err.message
    res.status(500).json data

module.exports =
    getAll: getAll
    getDetail: getDetail
    # createProduct: createProduct
    updateProductById: updateProductById
    deleteProductById: deleteProductById
    upsertMany: upsertMany
    upsertManyLoop: upsertManyLoop
    # getProductFromRedis: getProductFromRedis
