::  Test url +https://api.twitter.com/1.1/account/verify_credentials.json
:: 
::::  /hoon/twitter/com/sec
  ::
/+    oauth1
!:
::::
  ::
|_  {bal/(bale keys:oauth1) tok/token:oauth1}
::  aut is a "standard oauth1" core, which implements the 
::  most common handling of oauth1 semantics. see lib/oauth1 for more details.
++  aut  (~(standard oauth1 bal tok) . |=(tok/token:oauth1 +>(tok tok)))
++  out
  %+  out-adding-header:aut
    token-request='https://api.twitter.com/oauth/request_token'
  oauth-dialog='https://api.twitter.com/oauth/authorize'
::
++  res  res-handle-request-token:aut
++  bak  bak-save-token:aut
::
++  in
  %-  in-token-exchange:aut
  exchange-url='https://api.twitter.com/oauth/access_token'
::
:: ++  wyp  ~
--