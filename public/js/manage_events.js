"use script";


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
