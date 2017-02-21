"use strict";
/* global $ */

function storageAvailable(type) {
  try {
    const storage = window[type];
    const x = '__storage_test__';
    storage.setItem(x, x);
    storage.removeItem(x);
    return true;
  }
  catch(e) {
    return false;
  }
}

function submitSettings() {
  if (storageAvailable) {
    const defaultBranch = localStorage.getItem('defaultBranch') || '';
    const defaultPerPage = localStorage.getItem('defaultPerPage') || '10';
    const data = {defaultBranch: defaultBranch, defaultPerPage: defaultPerPage};

    $.ajax({
      url: "/api/settings",
      dataType: "json",
      contentType: "application/json; charset=UTF-8",
      data: JSON.stringify(data),
      type: "PUT"
    });
  }
}

$(function() {
  $("#save_settings").click(function() {
    if (storageAvailable('localStorage')) {
      localStorage.setItem('defaultBranch', $('#settings_branch').val());
      localStorage.setItem('defaultPerPage', $('input[name=settings_per_page]:checked').val());

      submitSettings();
    }
    else {
      alert('Beklager. Nettleseren støtter ikke lokal lagring.')
    }
  })

  // initialize page
  const defaultBranch = localStorage.getItem('defaultBranch') || '';
  const defaultPerPage = localStorage.getItem('defaultPerPage') || '10';

  $('#settings_branch').val(defaultBranch);
  $('input[name=settings_per_page]').val([defaultPerPage]);

  // set active class for navbar
  let activeNavigation;

  switch (location.pathname) {
    case '/': activeNavigation = '.nav-brand'; break;
    case '/info': activeNavigation = '.nav-info'; break;
    case '/view_events': activeNavigation = '.nav-view_events'; break;
    case '/manage_events': activeNavigation = '.nav-manage_events'; break;
    case '/api/event': activeNavigation = '.nav-manage_events'; break;
    case '/view_statistics': activeNavigation = '.nav-statistics'; break;
    case '/login': activeNavigation = '.nav-login'; break;
    case '/schema': activeNavigation = '.nav-admin, .nav-schema'; break;
    case '/manage_categories': activeNavigation = '.nav-admin, .nav-catdef'; break;
    case '/manage_event_types': activeNavigation = '.nav-admin, .nav-typedef'; break;
    case '/manage_age_groups': activeNavigation = '.nav-admin, .nav-agedef'; break;
    default:
  }

  $(activeNavigation).addClass('active');
})
