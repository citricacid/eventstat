"use strict";


$(function () {

  $('input[name="daterange"]').daterangepicker(
    {
      singleDatePicker: true,
      showDropdowns: true,
      locale: {
        format: 'DD-MM-YYYY',
        firstDay: 1
      }
    });


    $("#event-form").on("submit", function(e) {
      e.preventDefault();

      // validate title
      var len = $("#title").val().trim().length;



    });



    $("#btn_add").click(function() {
      var selected = $("#select_category :selected");
      var category_id = selected.val();
      var category = selected.text();

      if (selected.is(":disabled")) {
        return;
      }

      selected.prop("disabled", true);
      $("#select_category :enabled").first().prop("selected", true);

      var inputRow = `
      <div class="row" id="${category_id}">
        <div class="form-group col-xs-7 col-sm-5 col-md-6 col-lg-3">
          <label for="count">Antall ${category}:</label>
          <div class="row">
            <div class="form-group col-xs-7 col-sm-7 col-md-6 col-lg-5">
              <input type="number" class="form-control" name="counts[][${category_id}]">
            </div>
            <button type="button" class="btn btn-dafault btn_remove" data-id="${category_id}">
              <span class="glyphicon glyphicon-minus"></span>
            </button>
          </div>
        </div>
      </div>
      `;

      $("#categories").append(inputRow);
    });



    $("#categories").on("click", ".btn_remove", function() {
      var categoryID = $(this).data("id");

      $("#select_category option[value=" + categoryID + "]").prop("disabled", false);
      $('#' + categoryID).remove();

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
