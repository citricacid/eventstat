"use strict";

/* global $ moment */

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

const validateDate = function() {
  const $dateInput = $('#daterange');
  const isOK = moment($dateInput.val()).isValid();

  setValidity($dateInput, isOK);
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




const setVisibleOptions = function($selector, allOptions, visibleValues) {
  const selectedValue = $selector.find(':selected').first().val();

  if (!visibleValues) {
    $selector.find('option').not('.invalid_option').detach();
  } else if (visibleValues.length > 0) {
    $selector.find('option').not('.invalid_option').detach();
    visibleValues.forEach(function(id) {
      $selector.append(allOptions.filter("option[value=" + id + "]"));
    });
  } else {
    $selector.find('option').detach();
    $selector.append(allOptions);
  }

  const reselectOption = $selector.find('option[value=' + selectedValue + ']');

  // is previously selected option viable?
  if (reselectOption.length === 1 && !reselectOption.hasClass('invalid_option')) {
    reselectOption.prop('selected', 'true');
  // if not, check if there is only one viable
  } else if ($selector.find('option').length === 2 ) {
    $selector.find('option').last().prop('selected', true);
  // failing that, fall back to original option
  } else {
    $selector.find('option').first().prop('selected', true);
  }

};

// no longer needed?!
const determineSelectedOption = function($selector) {
  const $selected = $selector.find(':selected').first();
  const visibleOptions = $selector.find(':visible');

  if (visibleOptions.length === 1) {
    visibleOptions.prop("selected", true);
  } else if ($selected.css('display') === 'none') {
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

    if (!validateAttendants()) {
      isOK = false;
    }

    if (!validateDate) {
      isOK = false;
    }

    if (isOK && !validateTitle()) {
      const branchName = $('#branch_selector option:selected').text();
      const dateString = $('#daterange').val();

      $('#name').val(branchName + ' ' + dateString);
    }

    if (!validateTitle()) {
      isOK = false;
    }

    return isOK;
  });


  $('.toggleDefinition').click(function() {
    const $panel = $(this).siblings('.panel');
    const $span = $(this).find('span');
    const status = $(this).data('panel-is-open');

    if (status) {
      $span.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open');
      $(this).data('panel-is-open', false);
      $panel.css('display','none');
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

    setVisibleOptions($ageGroupSelector, ageValues, ageGroups);
    //determineSelectedOption($ageGroupSelector);

    // handle subcategories
    const subcategories = $(this).find(':selected').data('subcategories');
    const $subcategorySelector = $('#subcategory_selector');

    setVisibleOptions($subcategorySelector, subcategoryValues, subcategories);
    //determineSelectedOption($subcategorySelector);
  });


  $('#subcategory_selector').change(function() {
    const hasComment = $(this).find(":selected").data('has_comment');
    $('#comment').toggle(hasComment);

    showOrHideDefinitions($(this));
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

  let subcategoryValues = $('#subcategory_selector').find("option")
  let ageValues = $('#age_group_selector').find("option")

  $('#event_type_selector').change(); // fire change to set up dependent selectors
  showOrHideDefinitions($("#subcategory_selector"));
  // $('#subcategory_selector').change();
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
