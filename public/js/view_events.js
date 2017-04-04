"use strict";
/* global $ */

$(function() {
  const generate_parameters = function(pageNumber) {
    const per_page = 'per_page=' + $('input[name=per_page]:checked').val()
    //const sort_by = 'sort_by=' + $('input[name=sort_by]:checked').val()
    //const sort_order = 'sort_order=' + $('input[name=sort_order]:checked').val()
    const sort_by = 'sort_by=' + $('#sort_selector').find(':selected').data('sort_by')
    const sort_order = 'sort_order=' + $('#sort_selector').find(':selected').data('sort_order')
    const audience = 'audience=' + $('input[name=audience]:checked').val()
    const month = 'month=' +$("#month_selector").val()
    const year = 'year=' +$("#year_selector").val()
    const branch = 'branch=' +$("#branch_selector").val()
    const show_filters = 'show_filters=' + $('#filter_switch').is(':checked')
    const show_marked = 'show_marked=' + $('input[name=show_marked]:checked').val()
    const search = 'search=' + $('#search_box').val();
    const page_number = '?page_number=' + pageNumber || $('#page_number').html() || '1';

    return page_number + '&' + per_page + '&' + sort_by + '&' + sort_order
    + '&' + audience + '&' + branch + '&' + month + '&' + year + '&' + show_filters
    + '&' + show_marked + '&' + search;
  }

  const getResults = function(pageNumber) {
    // todo: fail...
    $('#loadbar').show();
    //$('.table-loading-inner').css("padding-top", "300px");
    $.get('/ajax/search' + generate_parameters(pageNumber), function(data) {
      $("#event_table").find("tbody").html(data.tablerows);
      $('#page_navigation').html(data.page_links)
      $('#loadbar').hide();
    })
  }

  const activateFilter = function() {
    window.location.href = '/view_events' + generate_parameters();
  }

  function showProgressBar() {
    const html = " <div class='table-loading-overlay' id='loadbar'>"
    + " <div class='table-loading-inner'>"
    + "<div class=\"col-xs-4 col-xs-offset-4\">"
    + "<div class=\"progress\"> "
    + "<div class=\"progress-bar progress-bar-striped progress-bar-streit active\" role=\"progressbar\" aria-valuenow=\"100\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: 100%\">"
    + "        <span class=\"sr-only\">Vennligst vent...</span>"
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

  $('#search_box').keyup(function() {
    // if text.len > 2...
    getResults('1');
  })

  $("#filter_switch").change(function() {
    $("#filter_bar").toggle(this.checked);
  })

  $("#branch_selector, #month_selector, #sort_selector, .filter_radio").change(function() {
    getResults('1');
  });

  $('#clear_search').click(function() {
    $('#search_box').val('');
    getResults('1');
  })


  $('body').on('click', '.page-link', function(){
    getResults($(this).data('page'));
  })

  //
  // init page
  //
  $.ajaxSetup({
    dataType: 'json',
    contentType: 'application/json; charset=UTF-8',
    cache: true
  })

  getResults();
});
