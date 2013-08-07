query = undefined
tab = undefined
rev = 0.11
activeTab = undefined
window.onload = ->

  # Add responsive media queries
  queries = [
    context: "mobile"
    match: ->
      window.responsive = "mobile"
  ,
    context: "desktop"
    match: ->
      window.responsive = "desktop"
  ]
  MQ.init queries

  # Add filters
  filters = new Filters()
  data = locache.get("blueGuideData")
  #data = null
  filters.draw "#filters", "#showFilters"

  # Get data if we need to
  if data? and data.rev? and data.rev is rev
    query = new JsonQuery("body", data)
  else
    `googleQuery = new GoogleSpreadsheetsQuery(filters, function(data) {
      locache.set("blueGuideData", data);
      query = new JsonQuery("body", data);
    });`
    googleQuery.get "select *"

  params = 
    id: "map"
    updateSelector: "body"
    draw: true
    resultsSelector: "#results"
    showPopup: window.responsive isnt "mobile"
    startLat: 38.659777730712534
    startLng: -105.8203125
    startZoom: 7
    geosearch:
      provider: "Google"
      settings:
        zoomLevel: 13 
    locate: {html: ich.locateBtn()}   
    layerUrl: "http://a.tiles.mapbox.com/v3/albatrossdigital.map-i5m0mag7/{z}/{x}/{y}.png"
    fields: filters.displayFields
    tabs: filters.tabs
  #if window.responsive isnt "mobile" or 1 is 1 

  # Add map
  map = new Map params

  # Add binds
  $("body").bind "queryUpdate", ->
    updateMarkers()
    activate()

  map.map.on "geosearch_showlocation", (e) ->
    locationUpdated(new L.LatLng(e.Location.Y, e.Location.X), e.Location.Label)
 
  map.map.on "locationfound", (e) ->
    locationUpdated(e.latlng, "your location")

  map.map.on "dragend", ->
    if !map.lastBounds? or !query.withinBounds(map.map.getCenter(), map.markerBounds(map.lastBounds, 1))
      updateMarkers()

  map.map.on "zoomend", ->
    updateMarkers map.pagerStart

  # Click event for "Show Locate" btn
  $("#showLocate").bind "click", ->
    $(this).toggleClass "active"
    $("body").toggleClass "locate-active"


  #$('.left-sidebar').bind "click", ->
  #  $('body').addClass "left-sidebar-big"
  #  resizeMap()

  # Called when markers are updated
  updateMarkers = (pagerStart) ->
    $('#show-markers').addClass "icon-spin"
    data = query.active(map.markerBounds(map.map.getBounds()))
    if map.forceZoom? and data.length < map.options.pagerSize*.8 and map.forceZoom < 4
      newZoom = map.map.getZoom()-1
      map.map.setZoom newZoom
      map.forceZoom = parseInt(map.forceZoom) + 1
    else 
      map.drawMarkers data, pagerStart
      $('#show-markers').addClass "icon-spin"
      $("#tabs a:eq(0)").addClass("active") if !activeTab?

  activate = ->
    $("body")
      .addClass("left-sidebar-active")
      .removeClass("overlay-active")
    resizeMap()

  locationUpdated = (latlng, locationType) ->
    map.locationType = locationType
    map.addMarker(latlng)
    map.updateLocation latlng
    map.forceZoom = 1
    query.fillActive()
    updateMarkers undefined
    activate()
    
    
  resizeMap = ->
    window.setTimeout ->
      map.map.invalidateSize animate: true
    , 500

  return

