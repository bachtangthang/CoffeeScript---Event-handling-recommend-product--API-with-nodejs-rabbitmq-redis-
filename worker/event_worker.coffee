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
				pipeline = redis.pipeline()
				payload = JSON.parse msg.content.toString()
				console.log "payload: ", payload
				{ __uid, event, portal_id, products } = payload

				for product in products
					console.log product.product_Id
					func1 = (callback) ->
						productModel.checkExist product.product_Id, (err, rs) ->
							callback null, rs
					
					func2 = (rs, callback) ->
						if rs?
							console.log "exists: ", rs[0].exists
							pipeline.zincrby "portal:#{portal_id}:user:#{__uid}:mostview", 1, product.product_Id
							category = xoa_dau product.category
							pipeline.zincrby "portal:#{portal_id}:category:#{category}:mostview", 1, product.product_Id

							if rs[0].exists == false
								productModel.create product, (err, rs) ->
									callback null, rs
							else
								pipeline.sadd "portal:#{portal_id}:user:#{__uid}", product.product_Id
								callback null, null

					
					func3 = (insertedProduct, callback) ->
						if insertedProduct != null
							console.log "insertedProduct: ", insertedProduct
							pipeline.sadd "portal:#{portal_id}:user:#{__uid}", insertedProduct.product_id
							for key, value of insertedProduct
								console.log "key: ", key
								console.log "value: ", value
								pipeline.hset "portal:#{portal_id}:products:#{insertedProduct.product_id}", key, value

							insertedEvent = eventHistoryModel.sync.create __uid, event, insertedProduct.product_id, portal_id
							callback null, insertedEvent
						else
							callback null, null

					async.waterfall [func1, func2, func3], (err, rs) ->
						pipeline.exec (err, result) ->
							console.log "pipeline.exec result: ", result


				# for product in products
				# 	console.log product.product_Id
				# 	fibrous.run () ->
				# 		rs = productModel.sync.checkExist product.product_Id
				# 		return rs
				# 	, (err, rs) ->
				# 		if err?
				# 			console.log err
				# 		else
				# 			console.log "exist: ", rs[0].exists
				# 			pipeline.zincrby "portal:#{portal_id}:user:#{__uid}:mostview", 1, product.product_Id
				# 			category = xoa_dau product.category
				# 			pipeline.zincrby "portal:#{portal_id}:category:#{category}:mostview", 1, product.product_Id

				# 			if rs[0].exists == false
				# 				fibrous.run () ->
				# 					insertedProducts = productModel.sync.create product
				# 					return insertedProducts
				# 				, (err, rs) ->
				# 					if err? then console.log err
				# 					else
				# 						console.log "insertedProducts: ", rs
				# 						pipeline.sadd "portal:#{portal_id}:user:#{__uid}", rs.product_id
				# 						for key, value in rs
				# 							console.log "key: ", key
				# 							console.log "value: ", value
				# 							pipeline.hset "portal:#{portal_id}:products:#{rs.product_id}", key, value
										
				# 						fibrous.run () ->
				# 							console.log eventHistoryModel.create
				# 							insertedEvent = eventHistoryModel.sync.create __uid, event, rs.product_id, portal_id
				# 							return insertedEvent
				# 						, (err, rs) ->
				# 							if err? then console.log err
				# 							else console.log "insertedEvent: ", rs
				# 			else
				# 				pipeline.sadd "portal:#{portal_id}:user:#{__uid}", product.product_Id
				# 			pipeline.exec (err, result) ->
				# 				console.log "pipeline.exec result: ", result
			catch err
				console.log err

			try
				channel.ack(msg)
			catch e
				console.log "RabbitMQ error", e
		, { noAck: false }
		
    