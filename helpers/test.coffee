fibrous = require "fibrous"
fetch = require "node-fetch"

obj =
	{
		product_name: "thịt chó 1",
		image_url: "url",
		landing_page_url: "landing_page_url",
		category: "thit cho",
		price: 10000,
		status: 1,
		product_id: "1000",
		portal_id: 1
	}

mainArr = []
i = 0
while i < 100
	mainArr.push obj
	i++

console.log "mainArr: ", mainArr

fibrous.run () ->
	response = fetch "http://localhost:5000/products/upsertMany", {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify(mainArr)
	}
	return response
, (err, response) ->
	if err? then console.log err
	else console.log response