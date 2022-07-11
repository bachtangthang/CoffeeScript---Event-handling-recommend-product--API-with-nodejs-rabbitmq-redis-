client                      = require('../db')
async                       = require("async")
fibrous                     = require("fibrous")
{ queriesParser }           = require('../helpers/queriesParser.coffee')

class CRUDModel
	constructor: (@client, @table, @tablePrimaryKey, @default_columns, @default_sort) ->

	create: (payload, callback) =>
		try
			columns             = []
			args                = []
			valueParameter      = []
			Object.keys(payload).forEach (key, index) ->
				columns.push key
				args.push payload[key]
				valueParameter.push "$#{index + 1}"
			columns             = columns.join(', ')
			valueParameter      = valueParameter.join(', ')

			query = "insert into #{@table} ( #{columns} ) values ( #{valueParameter} ) returning *"
			console.log query
			fibrous.run () =>
				result = @client.sync.query query, args
				# console.log result.rows[0]
				return result.rows[0]
			, (err, rs) ->
				if err?
					console.log err
					callback err, null
				else
					console.log rs
					callback null, rs
		catch err
			console.log err
			callback err, null

	update: (id, payload, callback) =>
		try
			args                = []
			parameter           = []
			console.log id
			Object.keys(payload).forEach (key, index) ->
				args.push payload[key]
				parameter.push "#{key} = $#{index + 1}"

			idStr = "#{Object.keys(payload).length + 1}"
			parameter = parameter.join ", "
			query = "Update #{@table} Set #{parameter} Where #{@tablePrimaryKey} = $#{idStr} returning *"

			fibrous.run () =>
				result = @client.sync.query query, [...args, id]
				console.log result.rows[0]
				return result.rows[0]
			, (err, rs) ->
				if err?
					console.log err
					callback err, null
				else
					console.log rs
					callback null, rs
		catch err
			console.log err
			callback err, null

	delete: (id, callback) =>
		try
			fibrous.run () =>
				console.log id
				query = "update #{@table} set status = 3 Where #{@tablePrimaryKey} = $1 returning *"
				result = @client.sync.query query, [id]
				console.log result
				return result.rows[0]
			, (err, rs) ->
				if err?
					console.log err
					calback err, null
				else
					console.log rs
					callback null, rs
		catch err
			console.log err
			callback err, null

	get: (filters, limit, offset, sort_by, sort, columns, callback) =>
		try
			limit = limit || 10
			offset = offset || 0
			sort = sort || "desc"
			sort_by = sort_by || default_sort

			columns = columns || default_columns
			colQuery = columns || default_columns.join(", ")
			sortQuery = "order by #{sort_by} #{sort} "

			pageQuery = "offset #{offset} fetch next  #{limit} rows only"
			{ query, arg } = queriesParser(filters)
			console.log "query: ", query
			console.log "arg: ", arg
			query = if query then "and #{query}" else " "
			queryStr = "Select #{colQuery} From #{@table} Where status != 3 #{query} #{sortQuery} #{pageQuery} "
			console.log "queryStr: ", queryStr

			fibrous.run () =>
				result = @client.sync.query queryStr, arg
				console.log "result: ", result.rows
				return result.rows
			, (err, rs) ->
				if err?
					console.log err
					callback err, null
				else callback null, rs
		catch err
			callback err, null


	getDetail: (id, columns, callback) =>
		columns = columns or @default_columns
		fibrous.run () =>
			result = @client.sync.query "Select #{columns} From #{@table} Where #{@tablePrimaryKey} = $1", [id]
			console.log result.rows[0]
			return result.rows[0]
		, (err, rs) ->
			if err? then callback err, null
			else
				callback null, rs

module.exports =
		CRUDModel: CRUDModel