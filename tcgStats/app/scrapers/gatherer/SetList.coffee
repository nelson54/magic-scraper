require("coffee-script/register");
Promise = require("bluebird");
request = Promise.promisify(require("request"));
cheerio = require('cheerio');

url = "http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&set=%5b%22Alara+Reborn%22%5d";
headers = {};

partialSelectFromElement = (selector) -> (el, $) ->
  $(el).find(selector).first().html().trim()
findLabel = partialSelectFromElement 'div.label'
findValue = partialSelectFromElement 'div.value'

request {'url':url, 'headers': headers}
.then (response) -> response[1]
.then (markup) -> cheerio.load(markup)
.then ($) ->
  console.log($('table.compact .cardItem .name a').length)
  $
.then ($) -> $('table.compact .cardItem .name a').map((i,el) ->
    console.log($(el).attr('href'))
    return $(el).attr('href')
  ).get()
.then (links) -> console.log('links: ' + links.join(', '))
#.done -> process.exit(0);