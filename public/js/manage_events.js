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
    hash[this.name] = this.value || '';
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


  var showOrHideDefinitions = function($button, definition) {
    var $panel = $button.siblings('.panel');
    var status = $button.data('panel-is-open')

    var showPanel = true
    var showButton = true

    if (definition === '' || definition === undefined) {
      showButton = false
      showPanel = false
    } else {
      $panel.find('.panel-body').html(definition)
      showPanel = status ? true : false;
    }

    $button.toggle(showButton)
    $panel.toggle(showPanel)
  }


  // event handlers

  $("form").submit(function() {
    //e.preventDefault();

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

    return isOK;
  });


  $('.toggleDefinition').click(function() {
    var $panel = $(this).siblings('.panel');
    var $span = $(this).find('span');
    var status = $(this).data('panel-is-open');

    if (!status) {
      $span.removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close')
      $(this).data('panel-is-open', true);
      $panel.show();
    } else {
      $span.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open');
      $(this).data('panel-is-open', false);
      $panel.hide();
    }
  });


  $('#event_type_selector').change(function() {
    // handle definitions
    var def = $("#event_type_selector :selected").data('definition')
    var $button = $(this).siblings('button');
    showOrHideDefinitions($button, def)

    // handle age groups
    var ageGroups = $(this).find(':selected').data('age_groups')
    var $ageGroupSelector = $('#age_group_selector')

    if (!ageGroups || (ageGroups && ageGroups.length == 0)) {
      $ageGroupSelector.find('option').show();
    } else {
      $ageGroupSelector.find('option').hide();
      ageGroups.forEach(function(id) {
        $("#age_group_selector option[value=" + id + "]").show()
      })
    }

    if ($ageGroupSelector.find(':selected').is(':hidden')) {
      $ageGroupSelector.find(':visible').first().prop("selected", true);
    }

    // handle subcategories
    var subcategories = $(this).find(':selected').data('subcategories')
    var $subcategorySelector = $('#subcategory_selector')

    if (!subcategories) {
      $subcategorySelector.find('option').hide();
    } else if (subcategories.length == 0) {
      $subcategorySelector.find('option').show();
    } else {
      $subcategorySelector.find('option').hide();
      subcategories.forEach(function(id) {
        $("#subcategory_selector option[value=" + id + "]").show()
      })
    }

    if ($subcategorySelector.find(':selected').is(':hidden')) {
      $subcategorySelector.find(':visible').first().prop("selected", true);
    }

  })


  $('#subcategory_selector').change(function() {
    var def = $("#subcategory_selector :selected").data('definition')
    var $button = $(this).siblings('button');
    showOrHideDefinitions($button, def)
  })


  var xsubmitData = function() {
    var eventData = convertFormToHash($('#event-form'))
    var data = {event_data: eventData}

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


  // initialize

  $('.toggleDefinition').hide()

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

  })
