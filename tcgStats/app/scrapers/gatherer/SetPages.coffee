require('coffee-script/register');
Promise = require('bluebird');
request = Promise.promisify(require('request'));
cheerio = require('cheerio');

gatherer = 'http://gatherer.wizards.com'
url = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&set=%5b%22Alara+Reborn%22%5d';
headers = {};

selectFromElement = (selector) -> (el, $) ->
  $(el).find(selector).first().html().trim()
findLabel = selectFromElement 'div.label'
findValue = selectFromElement 'div.value'

flatten = (links) -> [].concat.apply([], links)

mergeAttributes = (obj, merge) ->
  obj[merge.label] = merge.value
  obj


request {'url':url, 'headers': headers}
  .then (response) -> response[1]
  .then (markup) -> cheerio.load(markup)
  .then ($) -> $('.paging a').map((i,el) ->
      return $(el).attr('href')
    ).get()
  .then (list) -> list.filter((link, i, links) -> links.indexOf(link) == i)
  .map (url) -> request(gatherer+url)
  .map (response) -> response[1]
  .map (markup) -> cheerio.load(markup)
  .map ($) -> $('table.compact .cardItem .name a').map((i,el) ->
    return $(el).attr('href')
  ).get()
  .then (links) -> flatten(links)
  .map (link) -> request(link.replace('..', gatherer + '/Pages'))
  .map (response) -> response[1]
  .map (markup) -> cheerio.load(markup)
  .map ($) -> $('div.row').map((i,el) ->
    label = findLabel el, $
    value = findValue el, $
    {'label': label, 'value': value}
  ).get()
  .map (cardData) -> cardData.map( (attribute) ->
    if attribute.label is 'Artist:' and attribute.value
      attribute.value = cheerio.load(attribute.value)('a').text()
    attribute
  )
  .map (cardData) -> cardData.map( (attribute) ->
    if attribute.label is 'Mana Cost:' and attribute.value
      $ = cheerio.load(attribute.value)
      attribute.value = $('img').map( (i, el) -> $(el).attr('alt')) .get()
    attribute
  )
  .map (cardData) -> cardData.map( (attribute) ->
    attribute.label = attribute.label.replace(/\s/g, '').replace(/:/g, '').replace(/<b>P\/T<\/b>/g, 'PT')
    attribute
  )
  .map (cardData) -> cardData.reduce(mergeAttributes, {})
  .map (cardData) ->
    console.log 'card-data: ' + JSON.stringify(cardData)
    cardData
