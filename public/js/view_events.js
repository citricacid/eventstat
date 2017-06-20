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
    $('#loading_spinner').show();
    $.get('/ajax/search' + generate_parameters(pageNumber), function(data) {
      $("#event_table").find("tbody").html(data.tablerows);
      $('#page_navigation').html(data.page_links)
    }).fail(function() {
      alert('Beklager. Kan ikke utføre søket.')
    }).always(function() {
      $('#loading_spinner').hide();
    })
  }

  const activateFilter = function() {
    window.location.href = '/view_events' + generate_parameters();
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
