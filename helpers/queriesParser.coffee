descending              = "desc"
ascending               = "asc"

EqualTo                 = "="
GreaterThan             = ">"
GreaterThanOrEqualTo    = ">="
LessThanOrEqualTo       = "<="
NotEqualTo              = "<>"
LessThan                = "<"

All                     = "all"
And                     = "and"
Any                     = "any"

Between                 = "between"
Exists                  = "exists"

In                      = "in"
Like                    = "like"
Not                     = "not"
Or                      = "or"
Some                    = "some"

queriesParser = (filters) ->
	orQueries = []
	arg = []
	indexOfArg = 1
	for orFilters in filters
		console.log "orFilters: ", orFilters
		andQueries = []
		for andFilter in orFilters
			console.log "andFilter: ", andFilter
			switch andFilter.operator
				when "EqualTo"
					andQueries.push "#{andFilter.column} #{EqualTo} $#{indexOfArg} "
					arg.push andFilter.value
					indexOfArg++
				when "GreaterThan"
					andQueries.push "#{andFilter.column} #{GreaterThan} $#{indexOfArg} "
					arg.push andFilter.value
					console.log andQueries, arg
					indexOfArg++
				when "GreaterThanOrEqualTo"
					andQueries.push "#{andFilter.column} #{GreaterThanOrEqualTo} $#{indexOfArg} "
					arg.push andFilter.value
					indexOfArg++
				when "LessThanOrEqualTo"
					andQueries.push "#{andFilter.column} #{LessThanOrEqualTo} $#{indexOfArg} "
					arg.push andFilter.value
					console.log "andQueries: ", andQueries
					console.log "arg: ", arg
					indexOfArg++
				when "NotEqualTo"
					andQueries.push "#{andFilter.column} #{NotEqualTo} $#{indexOfArg} "
					arg.push andFilter.value
					indexOfArg++
				when "LessThan"
					andQueries.push "#{andFilter.column} #{LessThan} $#{indexOfArg} "
					arg.push andFilter.value
					indexOfArg++
				when "Like"
					andQueries.push "#{andFilter.column} #{Like} $#{indexOfArg} "
					arg.push "%#{andFilter.value}%"
					indexOfArg++
				else
					break
		console.log(andQueries)
		orQueries.push " ( #{andQueries.join(" and ")} ) "
	console.log("orQueries", orQueries)
	console.log "arg: ", arg
	query = orQueries.join " or "
	console.log { query, arg }
	return { query, arg }

module.exports = queriesParser: queriesParser