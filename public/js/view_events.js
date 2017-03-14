"use strict";
/* global $ */

$(function() {
  const activateFilter = function() {
    const per_page = 'per_page=' + $('input[name=per_page]:checked').val()
    const sort_by = 'sort_by=' + $('input[name=sort_by]:checked').val()
    const sort_order = 'sort_order=' + $('input[name=sort_order]:checked').val()
    const audience = 'audience=' + $('input[name=audience]:checked').val()
    const month = 'month=' +$("#month_selector").val()
    const branch = 'branch=' +$("#branch_selector").val()
    const show_filters = 'show_filters=' + $('#filter_switch').is(':checked')
    const show_marked = 'show_marked=' + $('input[name=show_marked]:checked').val()

    const link = '/view_events?page_number=1&' + per_page + '&' + sort_by + '&'
    + sort_order + '&' + audience + '&' + branch + '&' + month + '&' + show_filters + '&' + show_marked;

    window.location.href = link;
  }

  function showProgressBar() {
    const html = " <div class='table-loading-overlay'>"
    + " <div class='table-loading-inner'>"
    + "<div class=\"col-xs-4 col-xs-offset-4\">"
    + "<div class=\"progress\"> "
    + "<div class=\"progress-bar progress-bar-striped progress-bar-streit active\" role=\"progressbar\" aria-valuenow=\"100\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: 100%\">"
    + "        <span class=\"sr-only\">Loading...</span>"
    + "    </div>"
    + "    </div>"
    + " </div>"
    + " </div>"
    + " </div>";

    $('#mytable').prepend(html);
    // $('.table-loading-overlay').css('height', ($('#mytable').height() / 2) + 'px');
    //$('.table-loading-overlay').css('height', $('#mytable').height() + 'px');
    $('.table-loading-inner').css('padding-top', '300' + 'px');
  }

  $("#filter_switch").change(function() {
    $("#filter_bar").toggle(this.checked);
  })

  $("#branch_selector, #month_selector, .filter_radio").change(function() {
    showProgressBar();
    activateFilter();
  });

  $('.page-link').click(function() {
    showProgressBar();
  })
});
