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
      window.Intercom('update');
    }
  }

  var sync_status_interval;
  var init_sync_status_checker = function() {
    var sync_run_at = $("#sync-run-at")[0];
    if (sync_run_at) {
      sync_status_interval = setInterval(function() {
        $.getJSON("/user/sync_status").done(function(response) {
          if (response.run_at) {
            $(sync_run_at).html(response.run_at);
          } else {
            clearInterval(sync_status_interval);
            Turbolinks.visit("/", { action: "replace" })
          }
        }).fail(function() {
          $(sync_run_at).html("<span class=\"label tiny red\">Error getting status</span>");
        });
      }, 5000);
    } else {
      clearInterval(sync_status_interval);
    }
  };

  document.addEventListener("turbolinks:render", function() {
    refresh_intercom();
  });

  document.addEventListener("turbolinks:load", function() {
    init_sync_status_checker();
  });
})();

$(document).ready(function() {
  $(document.body).on("click", "button[type=submit]", function(e) {
    $(e.target).parent("form").addClass("loading");
  });

  $(document.body).on("click", ".spinner-on-click", function(e) {
    $(e.target).addClass("loading");
  });
})
