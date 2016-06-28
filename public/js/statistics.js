"use strict";

$(function() {

  // initialize daterange picker
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
        var fromDate = $("#daterange_from").val();
        var toDate = $("#daterange_to").val();
        var branchID = $("#select_branch").val();

        console.log(branchID);
        console.log(fromDate.constructor.name);
        console.log("heyya");

        // ajax: get stats


      });



        $('#submit').click(function() {

          var fromDate = $("#daterange_from").val();
          var toDate = $("#daterange_to").val();
          var branchID = $("#select_branch").val();

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
            alert(data);
          });

          request.fail(function(xhr, textStatus, errorThrown) {
            alert(textStatus);
          });

        });







})
