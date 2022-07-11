express                     = require('express')
router                      = express.Router()
userController              = require('../controllers/userController.coffee')

router.post '/identify', userController.identify #ok
module.exports = router

