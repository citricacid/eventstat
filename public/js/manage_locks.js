"use strict";
/* global $ */

$(function() {
  const activateFilter = function() {
    $('.table-loading-inner').css("padding-top", ($('#event_table').offset().top + 100) + 'px');
    $('#progressbar').show();
    //const sort_by = 'sort_by=' + $('input[name=sort_by]:checked').val()
    //const sort_order = 'sort_order=' + $('input[name=sort_order]:checked').val()
    const to_date = 'to_date=' +$("#daterange_to").val()
    const branch = 'branch_id=' +$("#branch_selector").val()

    const link = '/manage_locks?' + branch + '&' + to_date;
    window.location.href = link;
  }

  $('#daterange_to').on('apply.daterangepicker', function(ev, picker) {
    activateFilter();
  });

  $('#branch_selector').change(function() {
    activateFilter();
  })

})
