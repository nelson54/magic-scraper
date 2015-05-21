rgx = /^([A-z\$]{1,3})[\s]?((\d{1,3}(\,\d{3})*|(\d+))(\.\d{2}))?$/

Money = (currency, value) ->

  getCurrency = () ->
    currency

  getValue = () ->
    value

  intValue = () ->
    parseInt(value)

  floatValue = () ->
    parseFloat(value)

  toString = () ->
    if currency && value
      "#{currency} #{value}"

  return {
    getCurrency,
    getValue,
    intValue,
    floatValue,
    toString
  }


Money.valueOf = (string) ->
  if not string.match(rgx)
    return null

  m = rgx.exec(string)

  if m.length >= 3
    return Money(m[1], m[2])

module.exports = Money