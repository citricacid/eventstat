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

// document ready
$(function() {
  const adjustView = function($button, removeAlert) {
    $('.my_button').removeClass('active');
    $button.addClass('active');

    $("#definition_area").val($button.data('definition'));
    $("#id_input").val($button.data('id'));

    if (removeAlert) {
      $('.alert').remove();
    }

    if (!$button.isVisible()) {
      let offset = $button.offset().top;
      $('.list-group').scrollTop(offset);
    }
  };

  // button handler
  $('.my_button').click(function() {
    adjustView($(this), true);
  });

  // initializing page
  let editedItem = $('.my_button').filter("#active");
  let foo = editedItem.length > 0 ? editedItem : $('.my_button').first();

  adjustView(foo, false);
});
