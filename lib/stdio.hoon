::  Standard input/output functions.
::
::  These are all asynchronous computations, which means they produce a
::  form:(async A) for some type A.  You can always tell what they
::  produce by checking their first three lines.
::
::  Functions with the word "raw" in their name are for internal use
::  only because they carry a high salmonella risk.  More specifcally,
::  improper use of them may result in side effects that the tapp
::  runtime doesn't know about and can't undo in case the transaction
::  fails.
::
/-  tapp-sur=tapp
/+  async
|*  [poke-data=mold out-peer-data=mold]
=/  tapp-sur  (tapp-sur poke-data out-peer-data)
=,  card=card:tapp-sur
=,  sign=sign:tapp-sur
=,  contract=contract:tapp-sur
=+  (async sign card contract)
|%
::
::  Raw power
::
++  send-raw-card
  |=  =card
  =/  m  (async ,~)
  ^-  form:m
  |=  =async-input
  [[card]~ ~ ~ %done ~]
::
::  Add or remove a contract
::
++  set-raw-contract
  |=  [add=? =contract]
  =/  m  (async ,~)
  ^-  form:m
  |=  async-input
  [~ ~ (silt [add contract]~) %done ~]
::
::  Send effect on current bone
::
++  send-effect
  |=  =card
  =/  m  (async ,~)
  ^-  form:m
  ;<  =bone  bind:m
    |=  =async-input
    [~ ~ ~ %done ost.bowl.async-input]
  (send-effect-on-bone bone card)
::
::  Send effect on particular bone
::
++  send-effect-on-bone
  |=  [=bone =card]
  =/  m  (async ,~)
  ^-  form:m
  |=  async-input
  [~ [bone card]~ ~ %done ~]
::
::    ----
::
::  HTTP requests
::
++  send-hiss
  |=  =hiss:eyre
  =/  m  (async ,~)
  ^-  form:m
  ;<  ~  bind:m  (send-raw-card %hiss / ~ %httr %hiss hiss)
  (set-raw-contract & %hiss ~)
::
::  Wait until we get an HTTP response
::
++  take-sigh-raw
  =/  m  (async ,httr:eyre)
  ^-  form:m
  |=  =async-input
  :^  ~  ~  ~
  ?~  in.async-input
    [%wait ~]
  ?.  ?=(%sigh -.sign.u.in.async-input)
    [%fail %expected-sigh >got=-.sign.u.in.async-input< ~]
  [%done httr.sign.u.in.async-input]
::
::  Wait until we get an HTTP response and unset contract
::
++  take-sigh
  =/  m  (async ,httr:eyre)
  ^-  form:m
  ;<  =httr:eyre  bind:m  take-sigh-raw
  ;<  ~           bind:m  (set-raw-contract | %hiss ~)
  (pure:m httr)
::
::  Extract body from raw httr
::
++  extract-httr-body
  |=  =httr:eyre
  =/  m  (async ,cord)
  ^-  form:m
  ?.  =(2 (div p.httr 100))
    (async-fail %httr-error >p.httr< >+.httr< ~)
  ?~  r.httr
    (async-fail %expected-httr-body >httr< ~)
  (pure:m q.u.r.httr)
::
::  Parse cord to json
::
++  parse-json
  |=  =cord
  =/  m  (async ,json)
  ^-  form:m
  =/  json=(unit json)  (de-json:html cord)
  ?~  json
    (async-fail %json-parse-error ~)
  (pure:m u.json)
::
::  Fetch json at given url
::
++  fetch-json
  |=  url=tape
  =/  m  (async ,json)
  ^-  form:m
  =/  =hiss:eyre
    :*  purl=(scan url auri:de-purl:html)
        meth=%get
        math=~
        body=~
    ==
  ;<  ~           bind:m  (send-hiss hiss)
  ;<  =httr:eyre  bind:m  take-sigh
  ;<  =cord       bind:m  (extract-httr-body httr)
  (parse-json cord)
::
::    ----
::
::  Time is what keeps everything from happening at once
::
++  get-time
  =/  m  (async ,@da)
  ^-  form:m
  |=  =async-input
  [~ ~ ~ %done now.bowl.async-input]
::
::  Set a timer
::
++  send-wait
  |=  at=@da
  =/  m  (async ,~)
  ^-  form:m
  ;<  ~  bind:m  (send-raw-card %wait /note/(scot %da at) at)
  (set-raw-contract & %wait at)
::
::  Wait until we get a wake event
::
++  take-wake-raw
  =/  m  (async ,@da)
  ^-  form:m
  |=  =async-input
  :^  ~  ~  ~
  ?~  in.async-input
    [%wait ~]
  ?.  ?=(%wake -.sign.u.in.async-input)
    [%fail %expected-wake >got=-.sign.u.in.async-input< ~]
  ?~  wire.u.in.async-input
    [%fail %expected-wake-time ~]
  =/  at=(unit @da)  (slaw %da i.wire.u.in.async-input)
  ?~  at
    [%fail %expected-wake-time-da >wire< ~]
  [%done u.at]
::
::  Wait until we get a wake event and unset contract
::
++  take-wake
  =/  m  (async ,~)
  ^-  form:m
  ;<  at=@da  bind:m  take-wake-raw
  (set-raw-contract | %wait at)
::
::  Wait until time
::
++  wait
  |=  until=@da
  =/  m  (async ,~)
  ^-  form:m
  ;<  ~  bind:m  (send-wait until)
  take-wake
::
::  Wait until time then start new computation
::
++  wait-effect
  |=  until=@da
  =/  m  (async ,~)
  ^-  form:m
  (send-effect %wait /effect/(scot %da until) until)
::
::  Cancel computation if not done by time
::
++  set-timeout
  |*  computation-result=mold
  =/  m  (async ,computation-result)
  |=  [when=@da computation=form:m]
  ^-  form:m
  ;<  ~  bind:m  (send-wait when)
  |=  =async-input
  =*  loop  $
  ?:  ?&  ?=([~ * %wake *] in.async-input)
          =(/(scot %da when) wire.u.in.async-input)
      ==
    [~ ~ (silt [| %wait when]~) %fail %async-timeout ~]
  =/  c-res  (computation async-input)
  ?.  ?=(%cont -.next.c-res)
    c-res
  c-res(self.next ..loop(computation self.next.c-res))
::
::    ----
::
::  Apps
::
++  poke-app
  |=  [[her=ship app=term] =poke-data]
  =/  m  (async ,~)
  ^-  form:m
  (send-effect %poke / [her app] poke-data)
::
++  peer-app
  |=  [[her=ship app=term] =path]
  =/  m  (async ,~)
  ^-  form:m
  =/  =wire  (weld /(scot %p her)/[app] path)
  (send-effect %peer wire [her app] path)
::
++  pull-app
  |=  [[her=ship app=term] =path]
  =/  m  (async ,~)
  ^-  form:m
  =/  =wire  (weld /(scot %p her)/[app] path)
  (send-effect %pull wire [her app] ~)
::
::    ----
::
::  Handle subscriptions
::
::  Get bones at particular path; for internal use only
::
++  get-bones-on-path
  |=  =the=path
  =/  m  (async ,(list bone))
  ^-  form:m
  |=  =async-input
  :^  ~  ~  ~
  :-  %done
  %+  murn  ~(tap by sup.bowl.async-input)
  |=  [ost=bone her=ship =sub=path]
  ^-  (unit bone)
  ?.  =(the-path sub-path)
    ~
  `ost
::
::  Give a result to subscribers on particular path
::
++  give-result
  |=  [=path =out-peer-data]
  =/  m  (async ,~)
  ^-  form:m
  ;<  bones=(list bone)  bind:m  (get-bones-on-path path)
  |-  ^-  form:m
  =*  loop  $
  ?~  bones
    (pure:m ~)
  ;<  ~  bind:m  (send-effect-on-bone i.bones %diff out-peer-data)
  loop(bones t.bones)
--
