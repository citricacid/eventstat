"use strict";


$(function() {
  $('.item').dblclick(function() {
    const type = $(this).parent().data('type');
    const sourceList =  $('ul.' + type + '.source');
    const targetList =  $('ul.' + type + '.target');

    const isFromSourceList = $(this).parent().hasClass('source');

    // 'exclusive' items can not share space with other items in the targetList
    if ($(this).hasClass('exclusive') && isFromSourceList) {
      sourceList.append(targetList.find('li'));
    } else if (isFromSourceList) {
      sourceList.append(targetList.find('li.exclusive'));
    }

    const destination = isFromSourceList ? targetList : sourceList;
    destination.append($(this));
  })

});
