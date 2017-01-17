"use strict";
/* global $ window document */

// reference: http://www.hnldesign.nl/work/code/check-if-element-is-visible/
$.fn.isVisible = function() {
  var rect = this[0].getBoundingClientRect();
  return (
    (rect.height > 0 || rect.width > 0) &&
    rect.bottom >= 0 &&
    rect.right >= 0 &&
    rect.top <= (window.innerHeight || document.documentElement.clientHeight) &&
    rect.left <= (window.innerWidth || document.documentElement.clientWidth)
  );
};

$(function() {
  const showDefinition = function($item, removeAlert) {
    $('.items_list').removeClass('active');
    $item.addClass('active');

    $("#definition_area").val($item.data('definition'));
    $("#definition_id").val($item.data('id'));

    if (removeAlert) {
      $('.alert').hide();
    }

    // If item is not in visible part of list, scroll down to it
    if (!$item.isVisible()) {
      const offset = $item.offset().top;
      $('.items_list').scrollTop(offset);
    }
  };

  $('.items_list').click(function() {
    showDefinition($(this), true);
  });

  $('#toggle_sortable').click(function() {
    const toggleSwitch = $('#sortable').sortable('option', 'disabled');

    $('#save_priority_list').toggle(toggleSwitch);
    $('#sortable').sortable('option', 'disabled', !toggleSwitch);

    if (toggleSwitch) {
      $('#toggle_sortable').removeClass().addClass('btn btn-success');
      $('#status_text')
      .html('Endre rekkefølgen ved å dra elementene opp eller ned')
      .removeClass().addClass('text-info').show();
    } else {
      $('#toggle_sortable').removeClass().addClass('btn btn-info');
      $('#status_text').html('');
    }
  });

  $('#save_priority_list').click(function() {
    const url = $(this).data('post-to');
    const priorityList = {};
    $('.items_list').each(function(index) {
      priorityList[$(this).data('id')] = index;
    });

    $.ajax({
      url: url,
      dataType: "json",
      contentType: "application/json; charset=UTF-8",
      data: JSON.stringify({priority_list: priorityList}),
      type: "POST"
    }).done(function(data) {
      $('#status_text').removeClass().addClass('text-success')
      .html(data.message).show().fadeOut(5000);
    }).fail(function(data, textStatus, xhr) {
      $('#status_text').removeClass().addClass('text-danger')
      .html("Beklager. Teknisk feil: " + xhr).show().fadeOut(10000);
    });
  });

  // initialize page
  const editedItem = $('.items_list').filter("#active");
  if (editedItem.length) {
    showDefinition(editedItem, false);
  } else {
    showDefinition($('.items_list').first(), false);
  }

  $('#sortable').sortable({axis: 'y'});
  $('#toggle_sortable').click();
});
