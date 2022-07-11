client                  = require("../db")
{ CRUDModel }           = require("./Model")
fibrous                 = require("fibrous")

class UsersModel extends CRUDModel
	constructor: (@client, @table, @tablePrimaryKey, @default_columns, @default_sort) ->
			super()
	
	create: (uid, portal_id, callback) =>
		query = "insert into users (uid, portal_id) values ($1, $2) returning *"
		console.log query
		try
			fibrous.run () =>
				result = @client.sync.query query, [uid, portal_id]
				console.log result.rows[0]
				return result.rows[0]
			, (err, rs) ->
				if err? then callback err, rs
				else callback null, rs
		catch err
			return callback err, null

module.exports = { UsersModel }