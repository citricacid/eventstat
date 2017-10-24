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

  // TODO: fix this with 'must-validate' instead!
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

//
// selector updaters
//
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
  const $districtCategory = $('#district_category_panel')
  const $districtCategorySelector = $('#district_category_selector')

  let validationActive = false; // validation will only be activated after user has tried to submit
  let subcategoryValues = $subcategorySelector.find("option");
  let ageValues = $ageGroupSelector.find("option");


  const updateValidationSchema = function() {
    const hasDistrictCategory = $branchSelector.find(':selected').data('has_district_category')
    $districtCategorySelector.data('must_validate', hasDistrictCategory)

    if (!hasDistrictCategory) {
        $districtCategorySelector.find('option').first().prop('selected', true)
    }
  }

  $("form").submit(function(event) {
    updateValidationSchema();

    validationActive = true;
    let isValid = true;

    isValid = validateSelection($eventTypeSelector) && isValid;
    isValid = validateSelection($branchSelector) && isValid;
    isValid = validateSelection($subcategorySelector) && isValid;
    isValid = validateSelection($ageGroupSelector) && isValid;
    isValid = validateSelection($districtCategorySelector) && isValid;
    isValid = validateAttendants() && isValid;
    isValid = validateDate() && isValid;
    isValid = validateTitle() && isValid;

    return isValid;
  });

  //
  // Event handlers
  //

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
    const hasDistrictCategory = $(this).find(':selected').data('has_district_category') == 1
    $districtCategory.toggle(hasDistrictCategory)

    const selectedSubcategoryID = $subcategorySelector.find(':selected').val()
    $eventTypeSelector.change()
  })


  $eventTypeSelector.change(function() {
    // handle subcategories
    const districtSubs = $districtCategorySelector.find(':selected').data('district_subcategories')
    const subcategories = districtSubs === undefined || districtSubs.length == 0 ?
      $(this).find(':selected').data('subcategories') : districtSubs

    setVisibleOptions($subcategorySelector, subcategoryValues, subcategories);

    // handle counts
    const isCountable = $subcategorySelector.find(":selected").data('is_countable') || false;
    $('#attendants').data('is_countable', isCountable).toggle(isCountable);
    $('#attendants_label').toggle(isCountable);


    // handle age groups
    const ageGroups = $(this).find(':selected').data('age_groups');
    setVisibleOptions($ageGroupSelector, ageValues, ageGroups);

    showOrHideDefinitions($(this));
  });

  $districtCategorySelector.change(function() {
    const districtSubcategories = $(this).find(':selected').data('district_subcategories');
    if (districtSubcategories.length > 0) {
      setVisibleOptions($subcategorySelector, subcategoryValues, districtSubcategories);
    } else {
      $eventTypeSelector.change();
    }
  })


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
