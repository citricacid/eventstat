"use strict";

/* global $ */

let validationActive = false; // validation will only be activated after user has tried to submit

//
// helper functions
//

// form validation
const setValidity = function($element, isValid) {
  if (isValid) {
    $element.removeClass("invalid").addClass("valid");
  } else {
    $element.removeClass("valid").addClass("invalid");
  }
};

const validateSelection = function($selector) {
  const isValid = !$selector.find(':selected').hasClass("invalid_option");

  setValidity($selector, isValid);
  return isValid;
};

const validateTitle = function() {
  const $title = $('#name');
  const len = $title.val().trim().length;
  const isOK = len > 1 && len < 100;

  setValidity($title, isOK);
  return isOK;
};

const validateAttendants = function() {
  const $attendantsInput = $('#attendants');
  const isOK = parseInt($attendantsInput.val(), 10) >= 0;

  setValidity($attendantsInput, isOK);
  return isOK;
};

// selector handling
const showOrHideDefinitions = function($selector) {
  const definition = $selector.find(":selected").data('definition');
  const $button = $selector.siblings('button');
  const isOpen = $button.data('panel-is-open');
  const $panel = $button.siblings('.panel');
  $panel.find('.panel-body').html(definition);

  const hasDefinition = !(definition === '' || definition === undefined);

  $button.toggle(hasDefinition);
  $panel.toggle(isOpen && hasDefinition);
};

const setVisibleOptions = function($selector, visibleValues) {
  if (!visibleValues) {
    $selector.find('option').hide();
  } else if (visibleValues.length > 0) {
    $selector.find('option').hide();
    visibleValues.forEach(function(id) {
      $($selector).find("option[value=" + id + "]").show();
    });
  } else { // check: is this really the desired outcome?
    $selector.find('option').show();
  }
};

const determineSelectedOption = function($selector) {
  const $selected = $selector.find(':selected');
  const visibleOptions = $selector.find(':visible');

  if (visibleOptions.length === 1) {
    visibleOptions.prop("selected", true);
  } else if ($selected.is(':hidden')) {
    $selector.find('.invalid_option').prop("selected", true);
  }
};

// document ready
$(function() {
  $("form").submit(function() {
    validationActive = true;
    let isOK = true;

    if (!validateSelection($('#event_type_selector'))) {
      isOK = false;
    }

    if (!validateSelection($('#branch_selector'))) {
      isOK = false;
    }

    if (!validateSelection($('#subcategory_selector'))) {
      isOK = false;
    }

    if (!validateTitle()) {
      isOK = false;
    }

    if (!validateAttendants()) {
      isOK = false;
    }

    // daterange?

    return isOK;
  });



  $('.toggleDefinition').click(function() {
    const $panel = $(this).siblings('.panel');
    const $span = $(this).find('span');
    const status = $(this).data('panel-is-open');

    if (status) {
      $span.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open');
      $(this).data('panel-is-open', false);
      $panel.hide();
    } else {
      $span.removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close');
      $(this).data('panel-is-open', true);
      $panel.show();
    }
  });


  $('#event_type_selector').change(function() {
    showOrHideDefinitions($("#event_type_selector"));

    // handle age groups
    const ageGroups = $(this).find(':selected').data('age_groups');
    const $ageGroupSelector = $('#age_group_selector');

    setVisibleOptions($ageGroupSelector, ageGroups);
    determineSelectedOption($ageGroupSelector);

    // handle subcategories
    const subcategories = $(this).find(':selected').data('subcategories');
    const $subcategorySelector = $('#subcategory_selector');

    setVisibleOptions($subcategorySelector, subcategories);
    determineSelectedOption($subcategorySelector);
  });


  $('#subcategory_selector').change(function() {
    showOrHideDefinitions($("#subcategory_selector"));
  });

  // remove raised invalid flag upon proper selection/input
  $('select').change(function() {
    if (validationActive) {
      validateSelection($(this));
    }
  });

  $('#name').keyup(function() {
    if (validationActive) {
      validateTitle();
    }
  });

  $('#attendants').keyup(function() {
    if (validationActive) {
      validateAttendants();
    }
  });

  //
  // initialize form
  //

  $('#event_type_selector').change(); // fire change to set up dependent selectors
  showOrHideDefinitions($("#subcategory_selector"));

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
});
