"use strict";


var convertFormToHash = function($form) {
  var hash = {}
  var formElements = $form.serializeArray()

  $.each(formElements, function() {
    hash[this.name] = this.value || ''
  })

  return hash
}


var toggleOption = function($this, isDisabled) {
  var $option = $this.find("option[value='none']")
  $option.prop("disabled", isDisabled).prop("hidden", isDisabled)

  if (!isDisabled) {
    $option.prop('selected', true)
  }
};



$(function() {

  // initialize daterange pickers
  $("#daterange_from").daterangepicker(
    {
      singleDatePicker: true,
      showDropdowns: true,
      locale: {
        format: "DD-MM-YYYY",
        firstDay: 1
      }
    });

  $("#daterange_to").daterangepicker(
    {
      singleDatePicker: true,
      showDropdowns: true,
      locale: {
        format: "DD-MM-YYYY",
        firstDay: 1
      }
    });

    // set the quickpicker to current quarter and fire change
    $("#select_year").last().prop("selected", true);
    var date = new Date();
    var dateString = date.getDate() + "-" + (date.getMonth() +1 )+ "-" + date.getFullYear();
    var currentQuarter = moment(dateString, "DD-MM-YYYY").quarter();
    $("#select_quarter").val(currentQuarter).change();

    // reset all menu options
    $('#branch_selector option:first-child').prop('selected', true)
    $('#category_selector option:nth-child(2)').prop('selected', true)
    $('#subcategory_selector option:first-child').prop('selected', true)
    $('#event_maintype_selector option:first-child').prop('selected', true)

    $('.subtype_radio').hide()


    //
    // event handlers
    //

    $('.category_selector').change(function() {
      toggleOption($(this), true)
      toggleOption($(this).siblings(), false)
    });


    $('#event_maintype_selector').change(function() {
      var subtypeName = $(this).find(':selected').data('subtype_name')
      $('.subtype_radio').hide()
      $('#' + subtypeName).show().find('input:radio:first').prop('checked', true)
    })


    $(".period").change(function() {
      var p = $("#daterange_from").val() + "/" + $("#daterange_to").val();
      $('#period_name').val(p)
    });

    // not in use atm, possible remove
    $("#stats_table").on("click", ".fix_row", function() {
      var tr = $(this).parent().parent();
      tr.toggleClass("fixed_row");
      tr.find('span').toggleClass('glyphicon-unchecked glyphicon-check');
    });


    $(".quickpick").change(function() {
      var quarter = parseInt($("#select_quarter").val(), 10);
      var year = parseInt($("#select_year").val(), 10);

      var quickpickString = ''

      var startOfPeriod, endOfPeriod;

      if (quarter === 5) {
        startOfPeriod = moment(new Date(year, 0, 1)).format("DD-MM-YYYY");
        endOfPeriod = moment(new Date(year, 7, 31)).format("DD-MM-YYYY");
        quickpickString = "2. tertial " + year;
      } else if (quarter === 6) {
        startOfPeriod = moment(new Date(year, 0, 1)).format("DD-MM-YYYY");
        endOfPeriod = moment(new Date(year + 1, 0, 1)).subtract(1, 'days').format("DD-MM-YYYY");
        quickpickString = "Totalt " + year;
      } else {
        startOfPeriod = moment(new Date(year, 0, 1)).quarter(quarter).format("DD-MM-YYYY");
        endOfPeriod = moment(new Date(year, 0, 1)).quarter(quarter + 1).subtract(1, 'days').format("DD-MM-YYYY");
        quickpickString = quarter + ". kvartal " + year;
      }

      $('#period_name').val(quickpickString)

      $("#daterange_from").val(startOfPeriod);
      $("#daterange_to").val(endOfPeriod);
    });



    $("#clear").click(function() {
      $("#stats_table tbody tr").remove();
    });


    $('#submit').click(function() {
      var periodString = $('#period_name').val()

      var form = $("#query_form")
      var data = convertFormToHash(form)
      console.log(data)

      var request = $.ajax({
        url        : "/api/statistics",
        dataType   : "json",
        contentType: "application/json; charset=UTF-8",
        data       : JSON.stringify(data),
        type       : "PUT"
      });


      request.done(function(data, textStatus, xhr) {
        var $tbody = $("#stats_table tbody")

        data.results.forEach(result => {
          var tableRow = `
          <tr>
          <td>${periodString}</td>
          <td>${result.branch_name}</td>
          <td>${result.category_name}</td>
          <td>${result.young}</td>
          <td>${result.older}</td>
          <td>${result.all}</td>
          <td>${result.no_of_events}</td>
          <td>${result.maintype}</td>
          <td>${result.subtype}</td>
          </tr>
          `;

          $tbody.append(tableRow);
        });
      });

      request.fail(function(xhr, textStatus, errorThrown) {
        alert(textStatus);
      });

    });

  });
