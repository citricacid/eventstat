"use strict";


$(function() {
  $('li').dblclick(function() {
    const $parentRow = $(this).closest('div.row')
    const type = $(this).parent().data('type');
    const sourceList = $parentRow.find('ul.source');
    const targetList = $parentRow.find('ul.target');

    const isFromSourceList = $(this).parent().hasClass('source');

    // 'exclusive' items can not share space with other items in the targetList
    if ($(this).hasClass('exclusive') && isFromSourceList) {
      sourceList.append(targetList.find('li'));
    } else if (isFromSourceList) {
      sourceList.append(targetList.find('li.exclusive'));
    }

    const destination = isFromSourceList ? targetList : sourceList;
    destination.append($(this));

    updateFormElements()
  })


  const updateFormElements = function() {
    $('ul.target').each(function(i, targetList) {
      let values = $(this).find('li').map(function() {return $(this).attr('value')}).get()//.join('0')
      let name = $(this).data('type')

      $('[name=' + name + ']').val(values)
    })
  }

  $('.list_show').click(function() {
    $(this).closest('div.row').find('.sourcepanel').show()
  })

  $('.list_hide').click(function() {
    $(this).closest('div.row').find('.sourcepanel').hide()
  })


});
