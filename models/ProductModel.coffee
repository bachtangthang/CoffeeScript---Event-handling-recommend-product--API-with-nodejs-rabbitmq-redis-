{ CRUDModel }           		= require("./Model.coffee")
{ deepEqual }           		= require("../helpers/deepEquality.coffee")
fibrous                 		= require("fibrous")
async                   		= require("async")
client = require '../db'

class ProductModel extends CRUDModel
  constructor: (@client, @table, @tablePrimaryKey, @default_columns, @default_sort) ->
    super()

  checkExist: (product_id, callback) =>
    try
      fibrous.run () =>
        query = "select exists(select 1 from #{@table} where product_id = $1)"
        console.log query
        result = @client.sync.query query, [product_id]
        console.log "result: ", result.rows
        return result.rows[0].exists
      , (err, rs) ->
        if err?
          console.log "error: ", err
          callback err, null
        else
          console.log "success result", rs
          callback null, rs
    catch err
      return callback err, null


  upsertMany: (products, callback) =>
    console.log products

    try
      console.time
      query1 = "INSERT INTO #{@table} (product_name, image_url, landing_page_url, category, price, status, created_at, updated_at, product_id, portal_id)
              VALUES "
      query2 = "ON CONFLICT (product_id)
        DO
        UPDATE SET product_name = COALESCE(EXCLUDED.product_name, products.product_name),
        image_url = COALESCE(EXCLUDED.image_url, products.image_url),
        landing_page_url = COALESCE(EXCLUDED.landing_page_url, products.landing_page_url),
        category = COALESCE(EXCLUDED.category, products.category),
        price = COALESCE(EXCLUDED.price, products.price),
        status = COALESCE(EXCLUDED.status, products.status),
        created_at = COALESCE(products.created_at, EXCLUDED.created_at, current_timestamp),
        updated_at = COALESCE(current_timestamp, products.updated_at, current_timestamp),
        portal_id = COALESCE(EXCLUDED.portal_id, products.portal_id)
        RETURNING *"
      count = 0
      args = []
      parameterArr = []


      columns = ["product_name", "image_url", "landing_page_url", "category", "price", "status", "created_at", "updated_at", "product_id", "portal_id"]
      for product in products
        parameter = []
        parameterStr = " "
        for col in columns
          console.log "col -product[col]:", col, product[col]
          args.push product[col]
          count++
          parameter.push "$#{count}"

        parameterStr =  "( #{parameter.join ", "} )"
        # parameterStr = "( #{parameterStr}  ) "
        parameterArr.push parameterStr
        console.log "parameterArr: ", parameterArr

      query3 = parameterArr.join ", "
      query = query1 + query3 + query2
      console.log "query3: #{query3}"
      console.log "query: #{query}"
      console.log "args:", args
      
      fibrous.run () =>
        result = @client.sync.query query, args
        console.log result.rows
        return result.rows
      , (err, rs) ->
        if err?
          console.log err
          callback err, null
        else
          console.log "data.rows: ", rs
          callback null, rs
      console.timeEnd
    catch err
      console.log err
      return callback err, null
 
  upsertManyLoop: (products, callback) =>
    console.log products
    try
      console.time
      createInsertQuery = (product) =>
        query1 = "INSERT INTO #{@table} (product_name, image_url, landing_page_url, category, price, status, created_at, updated_at, product_id, portal_id)
                VALUES "
        query2 = "ON CONFLICT (product_id)
          DO
          UPDATE SET product_name = COALESCE(EXCLUDED.product_name, products.product_name),
          image_url = COALESCE(EXCLUDED.image_url, products.image_url),
          landing_page_url = COALESCE(EXCLUDED.landing_page_url, products.landing_page_url),
          category = COALESCE(EXCLUDED.category, products.category),
          price = COALESCE(EXCLUDED.price, products.price),
          status = COALESCE(EXCLUDED.status, products.status),
          created_at = COALESCE(products.created_at, EXCLUDED.created_at, current_timestamp),
          updated_at = COALESCE(current_timestamp, products.updated_at, current_timestamp),
          portal_id = COALESCE(EXCLUDED.portal_id, products.portal_id)
          RETURNING *"
        columns = ["product_name", "image_url", "landing_page_url", "category", "price", "status", "created_at", "updated_at", "product_id", "portal_id"]
              
        count = 0
        args = []
        parameter = []
        parameterStr = " "
        for col in columns
          console.log "col -product[col]:", col, product[col]
          args.push product[col]
          count++
          parameter.push "$#{count}"
        parameterStr =  "( #{parameter.join ", "} )"
        query = query1 + parameterStr + query2
        console.log "query: ", query
        return { query, args }
      
      async.eachLimit products, 2, (product, doneEach) =>
        { query, args } = createInsertQuery product
        fibrous.run () =>
          result = @client.sync.query query, args
          console.log result.rows
          return result.rows
        , (err, rs) ->
          console.log err
          console.log rs
          callback null, rs
      , (err, result) ->
        if err?
          console.log err
          callback err, null
        else
          console.log "data.rows: ", result
      console.timeEnd
    catch err
      console.log err
      return callback err, null
module.exports =
  ProductModel: ProductModel