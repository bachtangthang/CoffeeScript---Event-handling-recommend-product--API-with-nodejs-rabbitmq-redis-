{ usersModel }              = require("../models/index.coffee")
{ v4 }                      = require("uuid")
fibrous                     = require("fibrous")

identify = (req, res) ->
	try
		{ demo_uid, portal_id } = req.body

		if Object.keys(demo_uid).length != 0
			console.log "There is Cookies!"
			return res.status(200).json uid: demo_uid
		else
			console.log "There is no cookies"
			uid = v4()
			console.log uid
			
			fibrous.run () ->
				user = usersModel.sync.create uid, portal_id
				console.log "user: ", user
			, (err, rs) ->
				if err?
					console.log err
					res.status(500).json err
				else
					return res.status(200).json uid: uid
	
	catch err
		data =
			success: false
			message: err.message
		console.log data
		return res.status(500).json data

module.exports =
		identify: identify