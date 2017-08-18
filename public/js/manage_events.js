"use strict";

/* global $ moment */

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
  const isValid = !$selector.data('must_validate') || !$selector.find(':selected').hasClass("invalid_option");

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
  let isOK = true;

  // templates do not have attendant inputs, so only check validity if it's present
  if (!$attendantsInput.length) {
    return isOK;
  }

  if ($attendantsInput.data('is_countable')) {
    isOK = parseInt($attendantsInput.val(), 10) >= 0;
  } else {
    $attendantsInput.val(0);
  }

  setValidity($attendantsInput, isOK);
  return isOK;
};

const validateDate = function() {
  let isOK = true;
  const $dateInput = $('#daterange');

  // templates do not have date inputs, so only check validity if date is present
  if ($dateInput.length) {
    isOK = moment($dateInput.val(), 'DD-MM-YYYY', true).isValid();
    setValidity($dateInput, isOK);
  }

  return isOK;
};

// selector handling
const showOrHideDefinitions = function($selector) {
  const definition = $selector.find(":selected").data('definition');
  const $button = $selector.closest('.panel_group').find('.toggleDefinition').first();
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
  } else if ($selector.find('option').length === 2) {
    $selector.find('option').last().prop('selected', true);
  // failing that, fall back to default option
  } else {
    $selector.find('option').first().prop('selected', true);
  }
};

// document ready
$(function() {
  const $ageGroupSelector = $('#age_group_selector');
  const $subcategorySelector = $('#subcategory_selector');
  const $eventTypeSelector = $('#event_type_selector');
  const $branchSelector = $('#branch_selector');
  const $extraCategory = $('#extra_category_panel')
  const $extraCategorySelector = $('#extra_category_selector')

  let validationActive = false; // validation will only be activated after user has tried to submit
  let subcategoryValues = $subcategorySelector.find("option");
  let ageValues = $ageGroupSelector.find("option");

  const updateValidationSchema = function() {
    const regType = $('input:radio[name="registration_type"]:checked').val()

    const validateLibrarySelection = regType === 'library_only' || regType === 'mixed'
    const validateExtraSelection = regType === 'mixed' || regType === 'district_only'

    $extraCategorySelector.data('must_validate', validateExtraSelection)
    $eventTypeSelector.data('must_validate', validateLibrarySelection)
    $subcategorySelector.data('must_validate', validateLibrarySelection)
    $ageGroupSelector.data('must_validate', validateLibrarySelection)
  }


  $("form").submit(function(event) {
    updateValidationSchema();

    validationActive = true;
    let isValid = true;

    isValid = validateSelection($eventTypeSelector) && isValid;
    isValid = validateSelection($branchSelector) && isValid;
    isValid = validateSelection($subcategorySelector) && isValid;
    isValid = validateSelection($ageGroupSelector) && isValid;
    isValid = validateSelection($extraCategorySelector) && isValid;
    isValid = validateAttendants() && isValid;
    isValid = validateDate() && isValid;
    isValid = validateTitle() && isValid;

    return isValid;
  });

  $('.toggleDefinition').click(function() {
    const $panel = $(this).siblings('.panel');
    const $span = $(this).find('span');
    const status = $(this).data('panel-is-open');

    if (status) {
      $span.removeClass('glyphicon-eye-close').addClass('glyphicon-eye-open');
      $(this).data('panel-is-open', false);
      $panel.css('display', 'none');
    } else {
      $span.removeClass('glyphicon-eye-open').addClass('glyphicon-eye-close');
      $(this).data('panel-is-open', true);
      $panel.show();
    }
  });


  $branchSelector.change(function() {
    const hasExtraCategory = $(this).find(':selected').data('has_extra_type') == 1
    $extraCategory.toggle(hasExtraCategory)
    if (!hasExtraCategory) {
      $('input:radio[name="registration_type"][value="library_only"]').prop('checked', true)
    }
  })


  $eventTypeSelector.change(function() {
    showOrHideDefinitions($(this));

    // handle age groups
    const ageGroups = $(this).find(':selected').data('age_groups');
    setVisibleOptions($ageGroupSelector, ageValues, ageGroups);

    // handle subcategories
    const subcategories = $(this).find(':selected').data('subcategories');
    setVisibleOptions($subcategorySelector, subcategoryValues, subcategories);

    // handle counts
    const isCountable = $subcategorySelector.find(":selected").data('is_countable') || false;
    $('#attendants').data('is_countable', isCountable).toggle(isCountable);
    $('#attendants_label').toggle(isCountable);
  });

  $subcategorySelector.change(function() {
    const hasComment = $(this).find(":selected").data('has_comment');
    $('#comment').toggle(hasComment);

    const isCountable = $subcategorySelector.find(":selected").data('is_countable');
    $('#attendants').data('is_countable', isCountable).toggle(isCountable);
    $('#attendants_label').toggle(isCountable);

    showOrHideDefinitions($(this));
  });

  $ageGroupSelector.change(function() {
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
  // methods related to FUBIAK/extra types
  //



  $('input:radio[name="registration_type"]').change(function() {
    const regType = $(this).val() === "district_only"
    $branchSelector.prop('disabled', regType)
    $('#event_type_panel, #subcategory_panel').toggle(!regType)

    if ($(this).val() === "library_only") {
      $('#extra_category_selector').val('0')
    }
  })

  $('#extra_category_selector').change(function() {
    const extraType = $(this).find(':selected').val()
    const regType = $('input:radio[name="registration_type"]:checked').val()

    if (extraType === "0") {
      $('input:radio[name="registration_type"][value="library_only"]').prop('checked', true)
    } else if (regType === "library_only") {
      $('input:radio[name="registration_type"][value="mixed"]').prop('checked', true)
    }
  })


  //
  // initialize form
  //
  $branchSelector.change(); // fire change to toggle selectors
  $eventTypeSelector.change(); // fire change to set up dependent selectors
  showOrHideDefinitions($subcategorySelector);
  showOrHideDefinitions($ageGroupSelector);

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
