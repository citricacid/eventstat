"use strict";

$(function() {

  var quickpickString = "";

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





      $("#daterange_to").change(function() {
        quickpickString = "";
      });


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
          endOfPeriod = moment(new Date(year + 1, 0, 1)).subtract(1, 'days').format("DD-MM-YYYY");
          quickpickString = "Totalt " + year;
        } else {
          startOfPeriod = moment(new Date(year, 0, 1)).quarter(quarter).format("DD-MM-YYYY");
          endOfPeriod = moment(new Date(year, 0, 1)).quarter(quarter + 1).subtract(1, 'days').format("DD-MM-YYYY");
          quickpickString = quarter + ". kvartal " + year;
        }

        $("#daterange_from").val(startOfPeriod);
        $("#daterange_to").val(endOfPeriod);
      });

      // set the quickpicker to current values and fire change
      var date = new Date();
      var dateString = date.getDate() + "-" + (date.getMonth() +1 )+ "-" + date.getFullYear();
      var currentQuarter = moment(dateString, "DD-MM-YYYY").quarter();
      $("#select_quarter").val(currentQuarter).change();


      $("#clear").click(function() {
        $("#stats_table tbody tr").remove();
      });


      $('#submit').click(function() {
        var branchID = $("#select_branch").val();
        var fromDate = $("#daterange_from").val();
        var toDate = $("#daterange_to").val();

        // if the dates were selected via the quickpicker, use their value
        // otherwise construct string for custom period
        var periodString;
        if (quickpickString === "") {
          periodString = fromDate + "/" + toDate;
        } else {
          periodString = quickpickString;
        }


        var stats_parameters = {branch_id: branchID, from_date: fromDate, to_date: toDate};
        stats_parameters = JSON.stringify(stats_parameters);

        var request = $.ajax({
          url        : "/api/statistics",
          dataType   : "json",
          contentType: "application/json; charset=UTF-8",
          data       : stats_parameters,
          type       : "PUT"
        });

        request.done(function(data, textStatus, xhr) {
          var tableRow = `
          <tr>
          <td>${periodString}</td>
          <td>${data.branch_name}</td>
          <td>${data.young}</td>
          <td>${data.all}</td>
          <td>${data.no_of_events}</td>
          </tr>
          `;

          $("#stats_table tbody").append(tableRow);
        });

        request.fail(function(xhr, textStatus, errorThrown) {
          alert(textStatus);
        });

      });

    });
