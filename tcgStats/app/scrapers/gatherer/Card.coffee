require("coffee-script/register");
Promise = require("bluebird");
request = Promise.promisify(require("request"));
cheerio = require('cheerio');

url = "http://gatherer.wizards.com/Pages/Card/Details.aspx?multiverseid=179538";
headers = {};

partialSelectFromElement = (selector) -> (el, $) ->
  $(el).find(selector).first().html().trim()
findLabel = partialSelectFromElement 'div.label'
findValue = partialSelectFromElement 'div.value'

request {'url':url, 'headers': headers}
.then (response) -> response[1]
.then (markup) -> cheerio.load(markup)
.then ($) -> $('div.row').map((i,el) ->
  label = findLabel el, $
  value = findValue el, $
  {'label': label, 'value': value}
).get()
.then (cardData) -> console.log 'card-data: ' + cardData.map(JSON.stringify).join(', ')
.done -> process.exit(0);