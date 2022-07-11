{ EventHistoryModel }       = require("./EventHistoryModel.coffee")
{ ProductModel }            = require("./ProductModel.coffee")
{ UsersModel }              = require("./UsersModel.coffee")
client  									= require("../db.coffee")

productModel = new ProductModel(client, "products", "id", ["id", "product_name"], "id")

usersModel = new UsersModel(client, "users", "uid", ["uid", "created_at", "updated_at"], "uid")

eventHistoryModel = new EventHistoryModel(client, "event_histories", "uid", ["event", "uid", "productsid"], "uid")

module.exports =
	productModel: productModel
	usersModel: usersModel
	eventHistoryModel: eventHistoryModel

