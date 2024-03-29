// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

var bindFacebookEvents, initializeFacebookSDK, loadFacebookSDK, restoreFacebookRoot, saveFacebookRoot;

$(function() {
  if ($(".dev-label")[0]) { return; }
  loadFacebookSDK();
  if (!window.fbEventsBound) {
    return bindFacebookEvents();
  }
});

bindFacebookEvents = function() {
  $(document).on('turbolinks:request-start', saveFacebookRoot).on('turbolinks:load', restoreFacebookRoot).on('turbolinks:load', function() {
    return typeof FB !== "undefined" && FB !== null ? FB.XFBML.parse() : void 0;
  });
  return this.fbEventsBound = true;
};

saveFacebookRoot = function() {
  if ($('#fb-root').length) {
    return this.fbRoot = $('#fb-root').detach();
  }
};

restoreFacebookRoot = function() {
  if (this.fbRoot != null) {
    if ($('#fb-root').length) {
      return $('#fb-root').replaceWith(this.fbRoot);
    } else {
      return $('body').append(this.fbRoot);
    }
  }
};

loadFacebookSDK = function() {
  window.fbAsyncInit = initializeFacebookSDK;
  return $.getScript("//connect.facebook.net/en_GB/sdk.js");
};

initializeFacebookSDK = function() {
  return FB.init({
    appId: '1750822528518163',
    status: true,
    cookie: true,
    xfbml: true,
    version: 'v2.8'
  });
};

(function() {
  var refresh_intercom = function() {
    if (window.Intercom) {
      // window.Intercom('update');
    }
  }

  var auto_refresh_interval;
  clearInterval(auto_refresh_interval);
  auto_refresh_interval = setInterval(function() {
    var invite_needed_el = $(document.body).find("#invite-needed");
    if (invite_needed_el[0]) {
      Turbolinks.visit("/invites/invite_needed", { action: "replace" });
    }
  }, 45000);

  var sync_status_interval;
  var init_sync_status_checker = function() {
    var sync_run_at = $("#sync-run-at");
    if (sync_run_at[0]) {
      var json_path = sync_run_at.data("json-path");
      clearInterval(sync_status_interval);
      sync_status_interval = setInterval(function() {
        $.getJSON(json_path).done(function(response) {
          if (response.run_at) {
            sync_run_at.html(response.run_at);
          } else {
            clearInterval(sync_status_interval);
            Turbolinks.visit(window.location.pathname, { action: "replace" });
          }
        }).fail(function() {
          sync_run_at.html("<span class=\"label tiny red\">Error getting status</span>");
        });
      }, 5000);
    } else {
      clearInterval(sync_status_interval);
    }
  };

  var load_upcoming_events = function() {
    var events_div = $(".upcoming_events");
    var partial_path = events_div.data("partial-path");
    if (events_div[0] && partial_path) {
      events_div.html("<br><div class=\"ui active inverted dimmer\"><div class=\"ui small text loader\">Loading</div></div><br>")
      $.get(partial_path).done(function(response) {
        events_div.html(response);
      });
    }
  };

  document.addEventListener("turbolinks:render", function() {
    refresh_intercom();
  });


  var page_load_ajax_setup_delay;
  document.addEventListener("turbolinks:visit", function() {
    clearInterval(page_load_ajax_setup_delay);
  });

  document.addEventListener("turbolinks:load", function() {
    page_load_ajax_setup_delay = setTimeout(function() {
      init_sync_status_checker();
      load_upcoming_events();
    }, 1500);

    $('.admin-user-search').search({
      apiSettings: {
        url: '/admin/users/search?q={query}',
        method: 'POST'
      },
      fields: {
        results:     'users',
        description: 'email',
        image:       'image_url',
        price:       'id',
        title:       'google_name',
        url:         'admin_path'
      },
      minCharacters: 1,
      selectFirstResult: true
    });

    $('.ui.accordion').accordion();
  });
})();

$(document).ready(function() {
  $(document.body).on("click", "button[type=submit]", function(e) {
    $(e.target).parent("form").addClass("loading");
  });

  $(document.body).on("click", ".spinner-on-click", function(e) {
    $(e.target).addClass("loading");
  });

  // $(document.body).on("click", ".spinner-on-click", function(e) {
  //   var spinner_element = $(e.target).closest("button") || $(e.target).closest("a");
  //   spinner_element.addClass("loading");
  // });
})
