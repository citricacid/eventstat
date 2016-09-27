"use strict";

/* global $ */

//
// form helper functions
//
const clear = function(form) {
  form.find(':input').not(':button, :submit, :reset, :checkbox, :radio').val('');
  form.find(':checkbox, :radio').prop('checked', false);
};

const populate = function(form, data) {
  $.each(data, function(name, val) {
    const formElement = form.find('[name="' + name + '"]');
    const type = formElement.prop('type');
    switch (type) {
      case 'checkbox':
        formElement.prop('checked', val);
        break;
      case 'radio':
        formElement.filter('[value="' + val + '"]').prop('checked', 'checked');
        break;
      default:
        formElement.val(val);
    }
  });
};

const convertFormToHash = function($form) {
  const hash = {};
  const formElements = $form.serializeArray();

  $.each(formElements, function() {
    hash[this.name] = this.value || '';
  });

  return hash;
};



$(function() {
  // helper functions

  // new name? hide or show option
  const editOption = function(ageGroupID, isDisabled) {
    $("#age_group_selector option[value=" + ageGroupID + "]").prop("disabled", isDisabled);
    $("#age_group_selector option[value=" + ageGroupID + "]").prop("hidden", isDisabled);
  };

  const showOrHideDefinitions = function($button, definition) {
    const $panel = $button.siblings('.panel');
    const status = $button.data('panel-is-open');

    let showPanel = status;
    let showButton = true;

    if (definition === '' || definition === undefined) {
      showButton = false;
      showPanel = false;
    } else {
      $panel.find('.panel-body').html(definition);
      // showPanel = status;
    }

    $button.toggle(showButton);
    $panel.toggle(showPanel);
  };

  //
  // event handlers
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

  $("form").submit(function() {
    // e.preventDefault();

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

    // validate title
    const $title = $('#name');
    const len = $title.val().trim().length;

    if (len > 1 && len < 100) {
      setValidity($title, true);
    } else {
      setValidity($title, false);
      isOK = false;
    }

    // validate attendants
    const $attendantsInput = $('#attendants');

    if (parseInt($attendantsInput.val(), 10) >= 0) {
      setValidity($attendantsInput, true);
    } else {
      setValidity($attendantsInput, false);
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

  // possible todo: refactor the age group and subcategory handling
  $('#event_type_selector').change(function() {
    // handle definitions
    const def = $("#event_type_selector :selected").data('definition');
    const $button = $(this).siblings('button');
    showOrHideDefinitions($button, def);

    // handle age groups
    const ageGroups = $(this).find(':selected').data('age_groups');
    const $ageGroupSelector = $('#age_group_selector');

    if (!ageGroups || (ageGroups && ageGroups.length === 0)) {
      $ageGroupSelector.find('option').show();
    } else {
      $ageGroupSelector.find('option').hide();
      ageGroups.forEach(function(id) {
        $("#age_group_selector option[value=" + id + "]").show();
      });
    }

    if ($ageGroupSelector.find(':selected').is(':hidden')) {
      $ageGroupSelector.find(':visible').first().prop("selected", true);
    }

    // handle subcategories
    const subcategories = $(this).find(':selected').data('subcategories');
    const $subcategorySelector = $('#subcategory_selector');

    if (!subcategories) {
      $subcategorySelector.find('option').hide();
    } else if (subcategories.length === 0) {
      $subcategorySelector.find('option').show();
    } else {
      $subcategorySelector.find('option').hide();
      subcategories.forEach(function(id) {
        $("#subcategory_selector option[value=" + id + "]").show();
      });
    }

    // if the user selected a category and then changed the event type, then reset
    // the category selector if the option is no longer applicable
    const $selected = $subcategorySelector.find(':selected');
    if ($selected.is(':hidden')) {
      $subcategorySelector.find('.invalid_option').prop("selected", true);
    }
  });


  $('#subcategory_selector').change(function() {
    const def = $("#subcategory_selector :selected").data('definition');
    const $button = $(this).siblings('button');
    showOrHideDefinitions($button, def);
  });

  // will remove raised invalid flag upon proper selection
  $('select').change(function() {
    validateSelection($(this));
  });

  //
  // initialize form
  //

  $('.toggleDefinition').hide();

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
