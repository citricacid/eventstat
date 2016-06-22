"use strict";

$(function () {

$("#select_branch").click(function() {
  var branchID = $(this).val();

  if (branchID === '0') {
    $("#event_table tr").show();
  } else {
    $("#event_table tr:not(:first)").hide();
    $("#event_table ." + branchID).show();
  }
});

})
