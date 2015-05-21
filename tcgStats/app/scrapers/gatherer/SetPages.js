// Generated by CoffeeScript 1.8.0
(function() {
  var Promise, cheerio, findLabel, findValue, flatten, gatherer, headers, mergeAttributes, request, selectFromElement, url;

  require('coffee-script/register');

  Promise = require('bluebird');

  request = Promise.promisify(require('request'));

  cheerio = require('cheerio');

  gatherer = 'http://gatherer.wizards.com';

  url = 'http://gatherer.wizards.com/Pages/Search/Default.aspx?output=compact&set=%5b%22Alara+Reborn%22%5d';

  headers = {};

  selectFromElement = function(selector) {
    return function(el, $) {
      return $(el).find(selector).first().html().trim();
    };
  };

  findLabel = selectFromElement('div.label');

  findValue = selectFromElement('div.value');

  flatten = function(links) {
    return [].concat.apply([], links);
  };

  mergeAttributes = function(obj, merge) {
    obj[merge.label] = merge.value;
    return obj;
  };

  request({
    'url': url,
    'headers': headers
  }).then(function(response) {
    return response[1];
  }).then(function(markup) {
    return cheerio.load(markup);
  }).then(function($) {
    return $('.paging a').map(function(i, el) {
      return $(el).attr('href');
    }).get();
  }).then(function(list) {
    return list.filter(function(link, i, links) {
      return links.indexOf(link) === i;
    });
  }).map(function(url) {
    return request(gatherer + url);
  }).map(function(response) {
    return response[1];
  }).map(function(markup) {
    return cheerio.load(markup);
  }).map(function($) {
    return $('table.compact .cardItem .name a').map(function(i, el) {
      return $(el).attr('href');
    }).get();
  }).then(function(links) {
    return flatten(links);
  }).map(function(link) {
    return request(link.replace('..', gatherer + '/Pages'));
  }).map(function(response) {
    return response[1];
  }).map(function(markup) {
    return cheerio.load(markup);
  }).map(function($) {
    return $('div.row').map(function(i, el) {
      var label, value;
      label = findLabel(el, $);
      value = findValue(el, $);
      return {
        'label': label,
        'value': value
      };
    }).get();
  }).map(function(cardData) {
    return cardData.map(function(attribute) {
      if (attribute.label === 'Artist:' && attribute.value) {
        attribute.value = cheerio.load(attribute.value)('a').text();
      }
      return attribute;
    });
  }).map(function(cardData) {
    return cardData.map(function(attribute) {
      var $;
      if (attribute.label === 'Mana Cost:' && attribute.value) {
        $ = cheerio.load(attribute.value);
        attribute.value = $('img').map(function(i, el) {
          return $(el).attr('alt');
        }).get();
      }
      return attribute;
    });
  }).map(function(cardData) {
    return cardData.map(function(attribute) {
      attribute.label = attribute.label.replace(/\s/g, '').replace(/:/g, '').replace(/<b>P\/T<\/b>/g, 'PT');
      return attribute;
    });
  }).map(function(cardData) {
    return cardData.reduce(mergeAttributes, {});
  }).map(function(cardData) {
    console.log('card-data: ' + JSON.stringify(cardData));
    return cardData;
  });

}).call(this);