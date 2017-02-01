"use strict";
/* global $ */

$(function() {
  $("#branch_selector").change(function() {
    var branchID = $(this).val();
    window.location.href = "/view_events?page_number=1&branch_id=" + branchID;
  });
});
