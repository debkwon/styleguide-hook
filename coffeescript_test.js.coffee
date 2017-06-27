window.getQueryVariable = (variable) ->
  query = window.location.search.substring(1)
  vars = query.split("&")
  i = 0
  while i < vars.length
    pair = vars[i].split("=")
    return decodeURIComponent(pair[1]) if decodeURIComponent(pair[0]) == variable
    i++
  return




