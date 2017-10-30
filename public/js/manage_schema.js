"use strict";



$(function() {

  $('#subcategory_selector').change(function() {
  const selected = $(this).find(':selected')
    $('#name').val(selected.text())
    $.each(selected.data(), function(name, value) {$('[name="' + name + '"]').val(value)})


  })



})
