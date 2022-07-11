express                     = require('express')
router                      = express.Router()
eventHistoryController      = require('../controllers/eventHistoryController')

router.post '/events', eventHistoryController.events
module.exports = router
