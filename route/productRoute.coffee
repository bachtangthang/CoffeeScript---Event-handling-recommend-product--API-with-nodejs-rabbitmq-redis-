express                 = require "express"
router                  = express.Router()
productController      = require("../controllers/productController.coffee")

# router.get "/mostViewProductByUser", productController.mostViewProductByUser
# router.get "/mostViewProductByCategory", productController.mostViewProductByCategory
# router.get "/getTopMostViewProductByCategory", productController.getTopMostViewProductByCategory

router.get '/getDetail/:id', productController.getDetail #ok

router.put '/:id', productController.updateProductById #ok
#ok
router.delete '/:id', productController.deleteProductById #ok

router.post '/upsertMany', productController.upsertMany #ok
# router.post '/getHtmlTopViewProductByCategory', productController.getHtmlTopViewProductByCategory
# router.post '/getHtmlViewedProduct', productController.getHtmlViewedProduct
# router.post '/', productController.createProduct

router.get '/', productController.getAll #ok
router.post '/upsertManyLoop', productController.upsertManyLoop
#router.get '/:id', productController.getProductFromRedis
#ok
module.exports = router
