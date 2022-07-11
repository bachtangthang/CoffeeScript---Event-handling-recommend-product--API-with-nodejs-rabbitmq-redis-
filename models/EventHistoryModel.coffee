client                  = require('../db')
{ CRUDModel }           = require("./Model.coffee")
fibrous                 = require("fibrous")

class EventHistoryModel extends CRUDModel
	constructor: (@client, @table, @tablePrimaryKey, @default_columns, @default_sort) ->
		super()

	create: (uid, event, productId, portal_id, callback) ->
		console.log "portal_id inside model: #{portal_id}"
		query = "insert into event_histories (uid, event, productsId, portal_id) values ($1, $2, $3, $4) returning *"
		try
			fibrous.run () =>
				result = @client.sync.query query, [uid, event, "{#{productId}}", portal_id]
				return result
			, (err, rs) ->
					if err?
						console.log err
						callback err, null
					else
						# console.log "inserted row inside model: ", rs.rows[0]
						callback null, rs.rows[0]
		catch err
			return callback err, null

module.exports = { EventHistoryModel }