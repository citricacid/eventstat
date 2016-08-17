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


    // fire selector...
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


      // daterange?

      if (isOK) {
        //submitData();
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


    $('#event_type_selector').change(function() {
      var ageGroups = $(this).find(':selected').data('age_groups')
      var $ageGroupSelector = $('#age_group_selector')

      if (ageGroups.length == 0) {
        $ageGroupSelector.find('option').show();
      } else {
        $ageGroupSelector.find('option').hide();
        ageGroups.forEach(function(id) {
          $("#age_group_selector option[value=" + id + "]").show()
        })
      }

      $ageGroupSelector.find(':visible').first().prop("selected", true);

      //
      var subcategories = $(this).find(':selected').data('subcategories')
      var $subcategorySelector = $('#subcategory_selector')

      if (subcategories.length == 0) {
        $subcategorySelector.find('option').hide();
      } else {
        $subcategorySelector.find('option').hide();
        subcategories.forEach(function(id) {
          $("#subcategory_selector option[value=" + id + "]").show()
        })
      }

      $subcategorySelector.find(':visible').first().prop("selected", true);


    })

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
      var data = {event_data: eventData}
      //var countData = convertFormToHash($('#count-form'))
      //var data = {event_data: eventData, count_data: countData}

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
