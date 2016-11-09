(function(win, doc) {

  function parentForm(elem) {
    var parent = elem.parentNode;
    if(parent && parent.tagName != 'FORM') {
      parent = parentForm(parent);
    }
    return parent;
  }

  function setAccessToken(form, access_token) {
    var fb_token_input = doc.createElement("input");
    fb_token_input.setAttribute('type','hidden');
    fb_token_input.setAttribute('name', 'access_token');
    fb_token_input.setAttribute('value', access_token);
    form.appendChild(fb_token_input);
  }

  function statusChangeCallback(response) {
    if (response.status === 'connected') {
      var form = parentForm(doc.getElementById('fblogin'));
      setAccessToken(form, response.authResponse.accessToken);
      form.submit();
    }
  }

  win.facebook_authenticator = {

    init: function(app_id) {

      win.fbAsyncInit = function() {
        FB.init({
          appId      : app_id,
          cookie     : true,
          xfbml      : true,
          version    : 'v2.2'
        });

        FB.Event.subscribe('auth.login', function(response) {
          statusChangeCallback(response);
        });
      };

      var js, id = 'facebook-jssdk';
      var fjs = doc.getElementsByTagName('script')[0];
      if (doc.getElementById(id)) return;
      js = doc.createElement('script'); js.id = id;
      js.src = "//connect.facebook.net/en_US/sdk.js";
      fjs.parentNode.insertBefore(js, fjs);
    }

  };

})(this, document);


