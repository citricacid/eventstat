'use strict';

$(function() {
  $('#branch_selector').change(function() {
    const selectedID = $(this).val();
    if (selectedID == '0') {
      $('.templaterow').show();
    } else {
      $('.templaterow').hide();
      $('.branch-' + selectedID).show();
    }
  })
})
