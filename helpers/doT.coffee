dot = require('dot')
fs = require('fs')
{ productsTest } = require('../data')

readHtml = (path, callback) ->
	fs.readFile path, "utf-8", (err, data) ->
		if err?
			console.log err
			callback err, null
		else
			# console.log "data in doT", data
			callback null, data
	

buildHtml = (html, products, title) ->
	try
		dotP = dot.template(html)
		final = dotP(
			title: title
			products: products)
		return final
	catch err
		console.log err
	return

module.exports =
    readHtml: readHtml
    buildHtml: buildHtml