"use strict";


$(function () {

  // helper functions
  var addInput = function (cid, label, attendants) {
    var inputRow = `
    <div class="row" id="${cid}">
    <div class="form-group col-xs-7 col-sm-5 col-md-6 col-lg-3">
    <label for="count">Antall ${label}:</label>
    <div class="row">
    <div class="form-group col-xs-7 col-sm-7 col-md-6 col-lg-5">
    <input type="number" class="form-control" name="counts[][${cid}]" value="${attendants}">
    </div>
    <button type="button" class="btn btn-dafault btn_remove" data-id="${cid}">
    <span class="glyphicon glyphicon-minus"></span>
    </button>
    </div>
    </div>
    </div>
    `;

    $("#categories").append(inputRow);
  };


  var editOption = function(cid, isDisabled) {
    $("#select_category option[value=" + cid + "]").prop("disabled", isDisabled);
    $("#select_category option[value=" + cid + "]").prop("hidden", isDisabled);
  };


  // initialize daterange picker
  $("input[name='daterange']").daterangepicker(
    {
      singleDatePicker: true,
      showDropdowns: true,
      locale: {
        format: "DD-MM-YYYY",
        firstDay: 1
      }
    });

    // add inputs for existing values (edit mode)
    $(".counts").each(function() {
      var cid = $(this).data("category_id");
      var label = $(this).data("label");
      var attendants = $(this).data("attendants");

      addInput(cid, label, attendants);
      editOption(cid, true);
    });

    $("#select_category :enabled").first().prop("selected", true);


    // event handlers
    $("#event-form").on("submit", function(e) {
      e.preventDefault();

      var isOK = true;

      // validate title
      var len = $("#title").val().trim().length;
      if (len > 1 && len < 100) {
        $("#title").removeClass("invalid").addClass("valid");
      } else {
        $("#title").removeClass("valid").addClass("invalid");
        isOK = false;
      }

      // ensure branch is selected
      if ($("#select_branch :selected").val() === "") {
        $("#select_branch").removeClass("valid").addClass("invalid");
        isOK = false;
      } else {
        $("#select_branch").removeClass("invalid").addClass("valid");
      }

      // ensure genre is selected
      if ($("#select_genre :selected").val() === "") {
        $("#select_genre").removeClass("valid").addClass("invalid");
        isOK = false;
      } else {
        $("#select_genre").removeClass("invalid").addClass("valid");
      }


      // ensure valid counts are added
      var counts = $("#categories input");
      $("#ta-alert").remove();

      if (counts.size() === 0) {
        var alarm = `
        <div class="alert alert-danger" id="ta-alert">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        Du må legge til minst én aldersgruppe.
        </div>
        `;
        $("#categories").append(alarm);

        isOK = false;
      }

      counts.each(function(index, input) {
        var attendants = $(this).val();

        if (attendants > 0 && attendants <= 2147483647) {
          $(this).removeClass("invalid").addClass("valid");
        } else {
          $(this).removeClass("valid").addClass("invalid");
          isOK = false;
        }
      });
      // daterange?


      if (isOK) {
        document.formz.submit();
      }

    });


    $("#btn_add").click(function() {
      var selected = $("#select_category :selected");
      var cid = selected.val();
      var label = selected.text();

      if (selected.is(":disabled")) {
        return;
      }

      editOption(cid, true);

      $("#select_category :enabled").first().prop("selected", true);
      $("#ta-alert").remove();

      addInput(cid, label, 0);
    });



    $("#categories").on("click", ".btn_remove", function() {
      var categoryID = $(this).data("id");

      editOption(categoryID, false);
      $("#" + categoryID).remove();

      if ($("#select_category :enabled").size() === 1) {
        $("#select_category :enabled").prop("selected", true);
      }
    });



    $('#submit').click(function() {

      var date = $("#daterange").val();
      var genre_id = $("#select_genre").val();
      var branch_id = $("#select_branch").val();
      var desc = $("#event_desc").val();
      var category_id = $("#select_category").val();
      var count = $("#count").val();

      var event_data = {date: date, genre_id: genre_id, branch_id: branch_id, desc: desc, category_id: category_id, count: count};
      event_data = JSON.stringify(event_data);

      var request = $.ajax({
        url        : "/api/events",
        dataType   : "json",
        contentType: "application/json; charset=UTF-8",
        data       : event_data,
        type       : "PUT"
      });

      request.done(function(data, textStatus, xhr) {
        alert(textStatus);
      });

      request.fail(function(xhr, textStatus, errorThrown) {
        alert(textStatus);
      });

    });


    $('#cancel').click(function() {
      alert("avbryter");
    });


  })
