{
  app
  get_user_active_dates
  get_install_active_dates
} = require 'libs/server_common'

require! {
  'chrome-web-store-item-property'
  semver
}

moment = require 'moment-timezone'

app.get '/ping', (ctx) ->>
  ctx.body = 'hi'
  return

appid_to_time_checked = {}
appid_to_last_version = {}

app.get '/app_version', (ctx) ->>
  ctx.type = 'json'
  {appid, userid, installid} = ctx.request.query
  if not appid?
    ctx.body = {response: 'error', error: 'need appid'}
    return
  if not (appid == 'obghclocpdgcekcognpkblghkedcpdgd' or appid == 'bleifeoekkfhicamkpadfoclfhfmmina' or appid == 'alpaieokpbmkipilneofoclhpikonged')
    ctx.body = {response: 'error', error: 'appid is not habitlab'}
    return
  time_checked = appid_to_time_checked[appid] ? 0
  current_time = Date.now()
  if userid?
    current_date = moment().tz("America/Los_Angeles").format('YYYYMMDD')
    [user_active_dates, db] = await get_user_active_dates()
    user_active_dates.findOne({_id: current_date + '_' + userid}).then (logged_user_active_date) ->
      if not logged_user_active_date?
        user_active_dates.insert({_id: current_date + '_' + userid, day: current_date, user: userid})
    if installid?
      [install_active_dates, db2] = await get_install_active_dates()
      install_active_dates.findOne({_id: current_date + '_' + installid}).then (logged_install_active_date) ->
        if not logged_install_active_date?
          install_active_dates.insert({_id: current_date + '_' + installid, day: current_date, user: userid, install: installid})
  if time_checked + 1000*60*20 > current_time # within the past 20 minutes
    ctx.body = {response: 'success', version: appid_to_last_version[appid]}
    return
  appid_to_time_checked[appid] = Date.now()
  app_info = await chrome-web-store-item-property(appid)
  version = app_info?version
  if not version
    console.error 'got empty version in app_version'
    ctx.body = {response: 'success', version: appid_to_last_version[appid]}
    return
  if not semver.valid(version)
    console.error 'got invalid version in app_version'
    ctx.body = {response: 'success', version: appid_to_last_version[appid]}
    return
  appid_to_last_version[appid] = version
  ctx.body = {response: 'success', version: appid_to_last_version[appid]}
  return

app.get '/my_ip_address', (ctx) ->>
  #ctx.body = ctx.request.ip
  ctx.body = ctx.request.ip_address_fixed
  return

app.get '/echo', (ctx) ->>
  ctx.body = JSON.stringify ctx.request.query
  return

app.get '/log_error', (ctx) ->>
  console.error 'an error should be logged'
  ctx.body = 'hi'
  return

app.get '/throw_error', (ctx) ->>
  throw new Error('stuff is broken')
  ctx.body = 'hi'
  return

require('libs/globals').add_globals(module.exports)
