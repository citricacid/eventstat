"use strict";


//
// form helper functions
//
var clear = function(form) {
  form.find(':input').not(':button, :submit, :reset, :checkbox, :radio').val('')
  form.find(':checkbox, :radio').prop('checked', false)
}

var populate = function(form, data) {
  $.each(data, function(name, val){
    var formElement = form.find('[name="' + name + '"]')
    var type = formElement.prop('type')
    switch(type){
      case 'checkbox':
      formElement.prop('checked', val)
      break
      case 'radio':
      formElement.filter('[value="'+ val +'"]').prop('checked', 'checked')
      break
      default:
      formElement.val(val)
    }
  })
}

var convertFormToHash = function($form) {
  var hash = {}
  var formElements = $form.serializeArray()

  $.each(formElements, function() {
    hash[this.name] = this.value || ''
  })

  return hash
}



$(function () {

  // helper functions

    //<input type="number" class="form-control" name="counts[][${age_group_id}]" value="${attendants}">
  var addInput = function (age_group_id, label, attendants) {
    var inputRow = `
    <div class="row" id="${age_group_id}">
    <div class="form-group col-xs-7 col-sm-5 col-md-6 col-lg-3">
    <label for="count">Antall ${label}:</label>
    <div class="row">
    <div class="form-group col-xs-7 col-sm-7 col-md-6 col-lg-5">
    <input type="number" class="form-control" name="${age_group_id}" value="${attendants}">
    </div>
    <button type="button" class="btn btn-dafault btn_remove" data-id="${age_group_id}">
    <span class="glyphicon glyphicon-minus"></span>
    </button>
    </div>
    </div>
    </div>
    `;

    $("#counts").append(inputRow);
  };

  // new name? hide or show option
  var editOption = function(age_group_id, isDisabled) {
    $("#age_group_selector option[value=" + age_group_id + "]").prop("disabled", isDisabled);
    $("#age_group_selector option[value=" + age_group_id + "]").prop("hidden", isDisabled);
  };


  // initialize daterange picker
  $("input[name='date']").daterangepicker(
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
      var age_group_id = $(this).data("age_group_id");
      var label = $(this).data("label");
      var attendants = $(this).data("attendants");

      addInput(age_group_id, label, attendants);
      editOption(age_group_id, true);
    });

    $("#age_group_selector :enabled").first().prop("selected", true);
    $('#hide_definition').hide()
    $('#definition_panel').hide();


    var def = $("#subcategory_selector :selected").data('definition')

    if (def === '' || def === undefined) {
      $('#show_definition').hide()
    }
    //$('#definition_div').html($('#show_definition'))
    //$('#show_definition').clone().appendTo('#definition_div')

    // event handlers

    $("#submit_button").click(function(e) {
      e.preventDefault();

      var isOK = true;

      // validate title
      var len = $("#name").val().trim().length;
      if (len > 1 && len < 100) {
        $("#name").removeClass("invalid").addClass("valid");
      } else {
        $("#name").removeClass("valid").addClass("invalid");
        isOK = false;
      }

      // ensure branch is selected
      if ($("#branch_selector").val() === "") {
        $("#branch_selector").removeClass("valid").addClass("invalid");
        isOK = false;
      } else {
        $("#branch_selector").removeClass("invalid").addClass("valid");
      }

      // ensure subcategory is selected
      if ($("#subcategory_selector :selected").val() === "") {
        $("#subcategory_selector").removeClass("valid").addClass("invalid");
        isOK = false;
      } else {
        $("#subcategory_selector").removeClass("invalid").addClass("valid");
      }

      // ensure valid counts are added
      var counts = $("#counts input");
      $("#ta-alert").remove();

      if (counts.size() === 0) {
        var alarm = `
        <div class="alert alert-danger" id="ta-alert">
        <a href="#" class="close" data-dismiss="alert" aria-label="close">&times;</a>
        Du må legge til minst én aldersgruppe.
        </div>
        `;
        $("#counts").append(alarm);

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
        submitData();
      }

    });


    $("#btn_add").click(function() {
      var selected = $("#age_group_selector :selected");
      var age_group_id = selected.val();
      var label = selected.text();

      if (selected.is(":disabled")) {
        return;
      }

      editOption(age_group_id, true);

      $("#age_group_selector :enabled").first().prop("selected", true);
      $("#ta-alert").remove();

      addInput(age_group_id, label, 0);
    });



    $("#counts").on("click", ".btn_remove", function() {
      var categoryID = $(this).data("id")

      editOption(categoryID, false)
      $("#" + categoryID).remove()

      if ($("#age_group_selector :enabled").size() === 1) {
        $("#age_group_selector :enabled").prop("selected", true)
      }
    });

    $('#show_definition').click(function() {
      $('#show_definition').hide()
      $('#hide_definition').show()

      var def = $("#subcategory_selector :selected").data('definition')
      $('.panel-body', '#definition_panel').html(def)
      $('#definition_panel').show()
    });


    $('#hide_definition').click(function() {
      $('#hide_definition').hide()
      $('#show_definition').show()

      $('#definition_panel').hide()
    });


    $('#subcategory_selector').change(function() {
      var def = $("#subcategory_selector :selected").data('definition')
      $('.panel-body', '#definition_panel').html(def)

      var showPanel = true

      if (def === '' || def === undefined) {
        $('#show_definition').hide()
        showPanel = false
      } else {
        if ($('#hide_definition').is(':hidden')) {
            $('#show_definition').show()
            showPanel = false
        }
      }

      $('#definition_panel').toggle(showPanel)
    })


    var submitData = function() {
      var eventData = convertFormToHash($('#event-form'))
      var countData = convertFormToHash($('#count-form'))

      var data = {event_data: eventData, count_data: countData}

      var request = $.ajax({
        url        : "/api/event",
        dataType   : "json",
        contentType: "application/json; charset=UTF-8",
        data       : JSON.stringify(data),
        type       : "POST",
        cache      : false
      });


      request.done(function(response) {
        window.location.href = response.redirect;
      });

      request.fail(function(xhr, textStatus, errorThrown) {
        alert(textStatus)
      });

    };

  })
