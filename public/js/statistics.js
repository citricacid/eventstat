"use strict";
/* global $ moment */

let tables;

const convertFormToHash = function($form) {
  const hash = {};
  const formElements = $form.serializeArray();

  $.each(formElements, function() {
    if (hash[this.name]) {
      const thisValue = this.value || '';
      hash[this.name] = [].concat(hash[this.name], thisValue)
    } else {
    hash[this.name] = this.value || '';
    }
  });

  return hash;
};

const toggleOption = function($this, isDisabled) {
  const $option = $this.find("option[value='none']");
  $option.prop("disabled", isDisabled).prop("hidden", isDisabled);

  if (!isDisabled) {
    $option.prop('selected', true);
  }
};

const setVisibleOptions = function($selector, data) {
  if (data === undefined) {
    $selector.find('option').show();
  } else {
    $selector.find('option:gt(2)').hide();
    data.forEach(function(id) {
      $selector.find("option[value=" + id + "]").show();
    });
  }

  if ($selector.find(':selected').is(':hidden')) {
    $selector.find(':visible:nth-child(2)').prop("selected", true);
  }
};

const resetCategories = function() {
  $('#category_selector').find('option:nth-child(2)').prop('selected', true);
  $('#subcategory_selector').find('option:first-child').prop('selected', true);
};

// refactor?!
const resetAgeGroups = function() {
  $('#age_group_selector').find('option:nth-child(2)').prop('selected', true);
  $('#age_category_selector').find('option:first-child').prop('selected', true);
};


// document ready
$(function() {
  //
  // event handlers
  //

  $('.category_selector, .target_audience_selector').change(function() {
    toggleOption($(this), true);
    toggleOption($(this).siblings(), false);
  });

  $('#event_maintype_selector').change(function() {
    // set
    const subtypeName = $(this).find(':selected').data('subtype_name');
    $('.subtype_radio').hide();
    $('#' + subtypeName).show().find('input:radio:first').prop('checked', true);

    // fire change
    $('input[name=subtype_id]:checked').change();
  });

  // handle radio buttons
  $('input[name=subtype_id]').change(function() {
    const categories = $(this).data('categories') ||
    $('#event_maintype_selector').find(':selected').data('categories');

    setVisibleOptions($('#category_selector'), categories);

    const subcategories = $(this).data('subcategories') ||
    $('#event_maintype_selector').find(':selected').data('subcategories');

    setVisibleOptions($('#subcategory_selector'), subcategories);
  });

  $(".period").change(function() {
    const periodString = $("#daterange_from").val() + "/" + $("#daterange_to").val();
    $('#period_label').val(periodString);
  });

  $(".quickpick").change(function() {
    let quarter = parseInt($("#select_quarter").val(), 10);
    let year = parseInt($("#select_year").val(), 10);

    let quickpickString = '';
    let startOfPeriod, endOfPeriod;

    if (quarter === 5) {
      startOfPeriod = moment(new Date(year, 0, 1)).format("DD-MM-YYYY");
      endOfPeriod = moment(new Date(year, 7, 31)).format("DD-MM-YYYY");
      quickpickString = "2. tertial " + year;
    } else if (quarter === 6) {
      startOfPeriod = moment(new Date(year, 0, 1)).format("DD-MM-YYYY");
      endOfPeriod = moment(new Date(year + 1, 0, 1))
      .subtract(1, 'days')
      .format("DD-MM-YYYY");

      quickpickString = "Totalt " + year;
    } else {
      startOfPeriod = moment(new Date(year, 0, 1))
      .quarter(quarter)
      .format("DD-MM-YYYY");
      endOfPeriod = moment(new Date(year, 0, 1)).quarter(quarter + 1)
      .subtract(1, 'days')
      .format("DD-MM-YYYY");

      quickpickString = quarter + ". kvartal " + year;
    }

    $('#period_label').val(quickpickString);

    $("#daterange_from").val(startOfPeriod);
    $("#daterange_to").val(endOfPeriod);
  });

  $("#clear").click(function() {
    $("#stats_table").find("tbody tr").remove();
  });

  $("#toggle_empty_rows").change(function() {
    $(".empty_row").toggle(!this.checked);
    //tables.update({formats: ['xls']}); // refreshes table export
    tables.reset();
  })

  //
  // Submit parameters and process results
  //
  $('#submit').click(function() {
    // method to get default headers
    const periodString = $('#period_label').val();

    const form = $("#query_form");
    const data = convertFormToHash(form);

    const request = $.ajax({
      url: "/api/statistics",
      dataType: "json",
      contentType: "application/json; charset=UTF-8",
      data: JSON.stringify(data), // $form.serializeArray()
      type: "PUT"
    });


    request.done(function(data, textStatus, xhr) {
      // set new headers
      const newHeaders = []

      data.headers.forEach(header => {
        newHeaders.push($('<th />',
        {text: header.label, 'data-is-accumulative': header.is_countable, 'data-id': header.id
        }))
      })

      const oldHeaders = $('thead').html()
      $('thead').find('tr').html(newHeaders)

      // if header structure has changed, clear table
      if ($('thead').html() !== oldHeaders) {
        $("#stats_table").find("tbody tr").remove();
      }

      // populate table with results
      const countableKeys = findCountableKeys(newHeaders);
      const $tbody = $("#stats_table").find("tbody");

      data.results.forEach(result => {
        let removeButton = $('<button/>', {
          type: 'button',
          text: ' ',
          html: "<span class='glyphicon glyphicon-remove'></span>",
          class: "btn btn-xs btn-danger",
          click: function() {
            $(this).closest('tr').remove();
            processSummationRow($("#stats_table"));
          }
        });

        // rows which countable values are zero across the board will be hideable by class
        let tableRow = $('<tr />');;
        const sumOfAllCountable = countableKeys.reduce((total, key) => total += parseInt(result[key], 10), 0);

        if (sumOfAllCountable == 0) {
          tableRow.addClass('empty_row tableexport-ignore');
        }

        $.each(result, function(i, obj) {
          tableRow.append($('<td/>', {text: obj}))
        });

        tableRow.append($('<td/>', {html: removeButton}))
        $tbody.append(tableRow);
      });

      processSummationRow($("#stats_table"));

      $(".empty_row").toggle(!$("#toggle_empty_rows").is(':checked'));

      tables.reset();
      //tables.update({formats: ['xls']}); // refreshes table export
    });


    request.fail(function(xhr, textStatus, errorThrown) {
      alert(textStatus + ': ' + errorThrown);
    });
  });


  function findCountableKeys(headers) {
    const keys = []
    $('#stats_table th').each(function(index) {
      if ($(this).data('is-accumulative')) {
        keys.push($(this).data('id'))
      }
    });

    return keys;
  }


  function processSummationRow($table) {
    $table.find('.summation_row').remove();
    const $tbody = $table.find("tbody");

    // generate new empty row
    let $row = $('<tr/>', {class: 'summation_row'});
    for (let i = 0; i < $('#stats_table th').length; i++) {
      $row.append($('<td/>'));
    }

    // sum all accumulative columns and add to row
    $('#stats_table th').each(function(index) {
      if ($(this).data('is-accumulative')) {
        let sum = 0;

        $('tr td:nth-child(' + (index + 1) + ')').each(function() {
          sum += parseInt($(this).html(), 10);
        });

        $row.find('td:nth-child(' + (index + 1) + ')').html(sum);
      }
    });

    // finishing touch to row and add to table
    $row.find('td:nth-child(1)').html('Akkumulert');
    $tbody.append($row);
  }

  //
  // initialize page
  //

  // initialize daterange pickers
  $("#daterange_from").daterangepicker({
    singleDatePicker: true,
    showDropdowns: true,
    locale: {
      format: "DD-MM-YYYY",
      firstDay: 1
    }
  });

  $("#daterange_to").daterangepicker({
    singleDatePicker: true,
    showDropdowns: true,
    locale: {
      format: "DD-MM-YYYY",
      firstDay: 1
    }
  });

  // set the quickpicker to current quarter and fire change
  $("#select_year").children().last().prop("selected", true);
  const date = new Date();
  const dateString = date.getDate() + "-" + (date.getMonth() + 1) + "-" + date.getFullYear();
  const currentQuarter = moment(dateString, "DD-MM-YYYY").quarter();
  $("#select_quarter").val(currentQuarter).change();

  $('#event_maintype_selector').change();

  // reset selectors
  resetCategories();
  $('#category_selector').change();
  resetAgeGroups();

  // set parameters for tableExport plugin
  /* default filename if "id" attribute is set and undefined */
  // $.fn.tableExport.defaultFileName = "myDownload";


  $.fn.tableExport.xlsx.buttonContent = '-> excel'
  $.fn.tableExport.xls.buttonContent = '-> excel'
  TableExport.prototype.charset = "charset=utf-8";
  /* Excel Binary spreadsheet (.xls) */

  TableExport.prototype.xlsx = {
    defaultClass: "xlsx",
    buttonContent: "helledussen",
    mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    fileExtension: ".xlsx"
};

  let settings = {
    bootstrap: false, position: 'top', emptyCSS: ".tableexport-empty", formats: ['xlsx']
  }
  tables = $("#stats_table").tableExport(settings);


});
