"use strict";
/* global $ */

$(function() {
  const activateFilter = function() {
    const per_page = 'per_page=' + $('input[name=per_page]:checked').val()
    const sort_by = 'sort_by=' + $('input[name=sort_by]:checked').val()
    const audience = 'audience=' + $('input[name=audience]:checked').val()
    const month = 'month=' +$("#month_selector").val()
    const branch = 'branch=' +$("#branch_selector").val()
    const show_filters = 'show_filters=' + $('#filter_switch').is(':checked')

    const link = '/view_events?page_number=1&' + per_page + '&' + sort_by + '&'
    + audience + '&' + branch + '&' + month + '&' + show_filters;

    window.location.href = link;
  }

  $("#filter_switch").change(function() {
    $("#filter_bar").toggle(this.checked);
  })

  $("#branch_selector, #month_selector, .filter_radio").change(function() {
    activateFilter();
  });



});
