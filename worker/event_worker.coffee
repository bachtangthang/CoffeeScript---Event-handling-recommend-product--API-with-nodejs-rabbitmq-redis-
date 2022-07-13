amqp                    = require "amqplib/callback_api"
require("dotenv").config { path: "../.env" }
RABBIT_URL              = process.env.RABBIT_URL
EVENT_QUEUE_NAME        = process.env.EVENT_QUEUE_NAME
Redis                   = require "ioredis"
redis                   = new Redis 6379
{ productModel }        = require "../models/index"
{ eventHistoryModel }   = require "../models/index"
{ xoa_dau }             = require "../helpers/xoadau"
fibrous                 = require "fibrous"
async                   = require "async"

amqp.connect RABBIT_URL, (error0, connection) ->
	connection.createChannel (err, channel) ->
		channel.assertQueue EVENT_QUEUE_NAME, { durable: false }
		console.log "Waiting for event in #{EVENT_QUEUE_NAME} queue"

		channel.consume EVENT_QUEUE_NAME, (msg) ->
			try
				payload = JSON.parse msg.content.toString()
				console.log "payload: ", payload
				{ __uid, event, portal_id, products } = payload
				# pipeline = redis.pipeline()


				saveProduct = (exists, product, callback) ->
					pipeline = redis.pipeline()

					fibrous.run () ->
						if exists?
							console.log "exists: ", exists
							pipeline.zincrby "portal:#{portal_id}:user:#{__uid}:mostview", 1, product.product_Id
							category = xoa_dau product.category
							pipeline.zincrby "portal:#{portal_id}:category:#{category}:mostview", 1, product.product_Id

							if exists == false
								console.log "product inside savePorduct: ", product
								insertedProduct = productModel.sync.create product
								return insertedProduct
							else
								pipeline.sadd "portal:#{portal_id}:user:#{__uid}", product.product_Id
								return null
						else
							return  null
					, (err, insertedProduct) ->
						console.log err
						console.log "insertedProduct: ", insertedProduct
						pipeline.exec (err, result) ->
								console.log err
								console.log result
						callback err, insertedProduct


				saveEvent = (insertedProduct, callback) ->
					pipeline = redis.pipeline()

					fibrous.run () ->
						console.log "insertedProduct inside saveEvent: ", insertedProduct
						if insertedProduct != null
							pipeline.sadd "portal:#{portal_id}:user:#{__uid}", insertedProduct.product_id
							for key, value of insertedProduct
								console.log "key: ", key
								console.log "value: ", value
								pipeline.hset "portal:#{portal_id}:products:#{insertedProduct.product_id}", key, value

							insertedEvent = eventHistoryModel.sync.create __uid, event, insertedProduct.product_id, portal_id
							return insertedEvent
						else return false
					, (err, insertedEvent) ->
						console.log err,
						console.log insertedEvent
						pipeline.exec (err, result) ->
							console.log err
							console.log result
						callback err, insertedEvent
				
				# doneEach = (err, rs) ->
				# 	if err?
				# 		console.log "err in done: ", err
				# 	else
				# 		console.log "done: ", rs

				async.eachLimit products, 2, (product, doneEach) ->
					console.log product.product_Id
					fibrous.run () ->
						exists = productModel.sync.checkExist product.product_Id
						insertedProduct = saveProduct.sync exists, product
						result = saveEvent.sync insertedProduct
						return result

					, (err, rs) ->
						console.log "err in eachLimit: ", err
						console.log "rs in eachLimit: ", rs
						doneEach(null)
				,	(err, result) ->
					console.log err
					console.log result
				
			catch err
				console.log err

			try
				channel.ack(msg)
			catch e
				console.log "RabbitMQ error", e
		, { noAck: false }
		