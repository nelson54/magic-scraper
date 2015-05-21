util = require('util');
require("coffee-script/register");
Promise = require("bluebird");
request = Promise.promisify(require("request"));
cheerio = require('cheerio');

influx = require('influx');

Money = require('../money/Money')

client = influx({
  host : 'influxdb.aynraid.com',
  username : 'mtguser',
  password : 'mtgpass',
  database: 'mtg'
})

sets = []

setsPath = 'http://shop.tcgplayer.com/magic'
setPath = "http://magic.tcgplayer.com/db/search_result.asp?Set_Name="

headers = {
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
  "User-Agent": "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36",
  "Referer" : "http://shop.tcgplayer.com/magic",
  "Cookie" : "setting=CD=US&M=1; D_SID=107.5.215.152:0iI8B2ciHplKQgV7Izv6z9qPGjt4VhWIEfht8yypVLs; ASP.NET_SessionId=xxja2nhblmnanra1ohi4z1rk; SearchCriteria=M=1&WantGoldStar=False&WantCertifiedHobbyShop=False&WantDirect=False&WantSellersInCart=False&magic_MinQuantity=4&GameName=Magic&Magic_Language=English; tcgpartner=PK=WWWTCG&M=1; StoreCart_PRODUCTION=CK=5ace322850dc46aeaba4ab7f4186ec16&Ignore=false; TCG_Data=M=1&SearchGameNameID=magic&CustomerClosedTips=4; valid=set=true; __utma=1.1856536970.1432144001.1432144001.1432144001.1; __utmb=1.4.10.1432144001; __utmc=1; __utmz=1.1432144001.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); D_PID=65B66C68-6EC9-3B18-99EC-5F2B8F8D3C20; D_IID=BDF8D6E3-3A26-36C8-98E1-3AC81D1BBC16; D_UID=A273FB21-CFDE-3497-8F38-FEA9E7257A1F; D_HID=neAt4NXDmH/cxIIApJ0PxJ328sm181VQF+iIC7Bby9o; X-Mapping-fjhppofk=CBFD5247BC2C9BE04196BCA8AB195803"
};


properties = [["name", 0], ["set", 1], ["max", 2], ["mid", 3], ["min", 4]]

reduceCurrencies = (cur, list) ->
  if not list.includes(cur)
    list.append(cur)
  return list

currency = (currencies...) ->
  cur = null

  currencies
    .filter((obj) -> !!obj)
    .map((obj) -> obj.getCurrency())
    .reduce(reduceCurrencies, [])

  if currencies.length == 1
    cur = currencies[1]
  else if currencies.lengh == 0
    cur = "NONE"
  else
    cur = "MIXED"
  return cur

isEmpty = (obj) ->
  obj.name || obj.max || obj.min || obj.mid;

fixCurrencies = (obj) ->
  # console.log(obj)
  min = Money.valueOf(obj.min)
  mid = Money.valueOf(obj.mid)
  max = Money.valueOf(obj.max)

  # console.log(min.getValue())

  #obj.currency = currency(min, mid, max)

  obj.min = min.floatValue()
  obj.mid = mid.floatValue()
  obj.max = max.floatValue()

  return obj

rowToObject = ($r) ->
  txt = (i) -> $r.eq(i).text()
  new class then constructor: -> @[prop[0]] = txt(prop[1]) for prop in properties
  #if isEmpty(obj)
  #  console.log(obj.min)
  #return fixCurrencies(obj)
  ###try
    return fixCurrencies(obj)
  catch err
    console.log(err)
    return obj###



request {url: setsPath, headers: headers}
  .then (response) ->
    $ = cheerio.load response[1]
    $("#advancedSearchSets table tr td a.default_9_link")
      .map () -> return $(this).text()
      .get()
  .map (setName) ->
    console.log(setPath + setName)
    request {url:setPath + setName , headers: headers}
      .then (response) ->
        $ = cheerio.load response[1]
        $('div.bodyWrap table')
          .find('tr')
          .map () ->
            $r = $('td > a', this)
            rowToObject($r)
          .get()
      .map (obj) ->
        if(obj.min)
          try
            return fixCurrencies(obj)
          catch
            return null
      .then (cards) ->
        cards.filter((card) ->
          !!card
        )
      .then (cards) ->
        if(cards.length)
          client.writePoints('cards', cards, [], (e) -> );
        cards
      #.then (cards) -> console.log(util.inspect(cards, false, null))

