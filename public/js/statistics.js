"use strict";

var toggleOption = function($this, isDisabled) {
  var $option = $this.find("option[value='none']")
  $option.prop("disabled", isDisabled).prop("hidden", isDisabled)

  if (!isDisabled) {
    $option.prop('selected', true)
  }
};



$(function() {

  var quickpickString = ""
  var isQuickpick = false

  $('.category_selector').change(function() {
    toggleOption($(this), true)
    toggleOption($(this).siblings(), false)
  });


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

    // initialize daterange picker
    $("#daterange_to").daterangepicker(
      {
        singleDatePicker: true,
        showDropdowns: true,
        locale: {
          format: "DD-MM-YYYY",
          firstDay: 1
        }
      });


      $(".period").change(function() {
        isQuickpick = false;
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

        isQuickpick = true;

        $("#daterange_from").val(startOfPeriod);
        $("#daterange_to").val(endOfPeriod);
      });

      // set the quickpicker to current quarter and fire change
      $("#select_year").last().prop("selected", true);
      var date = new Date();
      var dateString = date.getDate() + "-" + (date.getMonth() +1 )+ "-" + date.getFullYear();
      var currentQuarter = moment(dateString, "DD-MM-YYYY").quarter();
      $("#select_quarter").val(currentQuarter).change();

      $("#clear").click(function() {
        $("#stats_table tbody tr").remove();
      });


      $('#submit').click(function() {
        var branchID = $("#branch_selector").val();
        var fromDate = $("#daterange_from").val();
        var toDate = $("#daterange_to").val();
        var categoryID = $("#category_selector").val();
        var subcategoryID = $("#subcategory_selector").val();

        // if the dates were selected via the quickpicker, use their value
        // otherwise construct string for custom period
        var periodString;

        if (isQuickpick) {
          periodString = quickpickString;
        } else {
          periodString = fromDate + "/" + toDate;
        }

        var stats_parameters = {branch_id: branchID, from_date: fromDate,
           to_date: toDate, category_id: categoryID, subcategory_id: subcategoryID};
           
        var request = $.ajax({
          url        : "/api/statistics",
          dataType   : "json",
          contentType: "application/json; charset=UTF-8",
          data       : JSON.stringify(stats_parameters),
          type       : "PUT"
        });


        request.done(function(data, textStatus, xhr) {
          data.results.forEach(result => {
            var tableRow = `
            <tr>
            <td>${periodString}</td>
            <td>${result.branch_name}</td>
            <td>${result.young}</td>
            <td>${result.all}</td>
            <td>${result.no_of_events}</td>
            </tr>
            `;

            $("#stats_table tbody").append(tableRow);
          });
        });

        request.fail(function(xhr, textStatus, errorThrown) {
          alert(textStatus);
        });

      });

    });
