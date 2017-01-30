local m = {}

local json = require("json")
local importantData
local myData = {}
local lightLogin
local scale0= ((display.actualContentWidth- display.contentWidth)*.5)
local scale0Y= ((display.actualContentHeight- display.contentHeight)*.5)*-1
local barBox
local barText
local connectLis
local webView

-- predeclare
local authorization_code

myData.client_id = nil
myData.client_secret = nil
myData.importantData_file = nil
myData.url_authorization = nil
myData.url_access_token = nil
myData.authorization_response_type = "code"
myData.grant_type_authorization = "authorization_code"
myData.grant_type_refresh = "refresh_token"
myData.redirect_uri = nil
myData.service_name = nil
myData.scope = nil

--string encoder
function string.urlEncode( str )
   if ( str ) then
      str = string.gsub( str, "\n", "\r\n" )
      str = string.gsub( str, "([^%w ])",
         function (c) return string.format( "%%%02X", string.byte(c) ) end )
      str = string.gsub( str, " ", "+" )
   end
   return str
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern,
theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function saveRefreshForLater()
    local file = io.open(system.pathForFile(myData.importantData_file, system.DocumentsDirectory), "w")
    if file then
        file:write( json.encode({refreshToken = importantData["refresh_token"]}) )
        io.close( file )
    end
end

function signInUser(myType)
	local authUrl = nil
  
  if myData.scope then
    authUrl = string.format("%s?redirect_uri=%s&response_type=%s&client_id=%s&scope=%s&approval_prompt=force&access_type=offline&", myData.url_authorization, myData.redirect_uri, myData.authorization_response_type, myData.client_id, myData.scope)
  else
    authUrl = string.format("%s?redirect_uri=%s&response_type=%s&client_id=%s", myData.url_authorization, myData.redirect_uri, myData.authorization_response_type, myData.client_id)
  end
  if (myType == "windows") then
    system.openURL( authUrl )
  else
    webView = native.newWebView( display.contentCenterX, display.actualContentHeight+((display.actualContentHeight-50)*.5), display.actualContentWidth, display.actualContentHeight-40)
    barText = display.newText( "Done", 0, 0, native.systemFontBold, 15 )
    barText.alpha = 0
    barText.anchorX = 0
    barText:setFillColor( 0,0,1 )

    barBox = display.newRect( 0, 0, display.actualContentWidth, 42 )
    barBox.alpha = 0
    barBox:setFillColor( .5 )

    webView.x2, webView.y2 = webView.x, webView.y
    barBox:toFront( )
    barBox.x, barBox.y = webView.x, webView.y-(webView.height*.5)
    barBox.x2, barBox.y2 = barBox.x, barBox.y
    barBox.alpha = 1
    barText:toFront( )
    barText.x, barText.y = 0-scale0+5, webView.y-(webView.height*.5)
    barText.x2, barText.y2 = barText.x, barText.y
    barText.alpha = 1

    transition.to( barBox, {time = 500, y = 0+scale0Y+20} )
    transition.to( barText, {time = 500, y = 0+scale0Y+20} )
    transition.to( webView, {time = 500, y = display.contentCenterY+20} )
    --tap lis
    function barText:tap(  )
      if (webView and webView.x) then
        transition.to( barBox, {time = 500, y = barBox.y2} )
        transition.to( barText, {time = 500, y = barText.y2} )
        transition.to( webView, {time = 500, y = webView.y2, onComplete = function (  )
          if (connectLis) then
            connectLis({error = "user cancelled", isError = "user cancelled"})
          if (webView and webView.x) then
            webView:removeSelf( )
          end
          if (barText and barText.x) then
            barText:removeSelf( )
          end
          if (barBox and barBox.x) then
            barBox:removeSelf( )
          end
          end
        end} )
      end
    end
    barText:addEventListener( "tap", barText )
    --
    webView:request( authUrl )
    webView:addEventListener( "urlRequest", authorizationListener )
  end
end


function requestimportantDataLis( event )
	local connectedReturn = {
    	name = "connected",
    	response = event.response,
	}
    if (lightLogin) then
      importantData = json.decode(event.response)
      lightLogin = nil
      pcall(connectLis, connectedReturn)
      return true
    end
    if ( event.isError ) then
    	connectedReturn.isError = true
    	pcall(connectLis, connectedReturn)
      if (webView and webView.x) then
        transition.to( barBox, {time = 500, y = barBox.y2} )
        transition.to( barText, {time = 500, y = barText.y2} )
        transition.to( webView, {time = 500, y = webView.y2, onComplete = function (  )
          connectLis({error = "user cancelled", isError = "user cancelled"})
          if (webView and webView.x) then
            webView:removeSelf( )
          end
          if (barText and barText.x) then
            barText:removeSelf( )
          end
          if (barBox and barBox.x) then
            barBox:removeSelf( )
          end
        end} )
      end
    else
        importantData = json.decode(event.response)
        if (importantData["error"]) then
			   os.remove( system.pathForFile(myData.importantData_file, system.DocumentsDirectory) )
			   signInUser()
			   return
        end
        if(importantData["refresh_token"]) then saveRefreshForLater() end
        connectedReturn.isError = false
        if (webView and webView.x) then
          transition.to( barBox, {time = 500, y = barBox.y2} )
          transition.to( barText, {time = 500, y = barText.y2} )
          transition.to( webView, {time = 500, y = webView.y2, onComplete = function (  )
            if (webView and webView.x) then
              webView:removeSelf( )
            end
            if (barText and barText.x) then
              barText:removeSelf( )
            end
            if (barBox and barBox.x) then
              barBox:removeSelf( )
            end
          end} )
        end
        pcall(connectLis, connectedReturn)
        end
        connectLis = nil
end

function getNewToken(token)
  local params = {}
  params.body = string.format("refresh_token=%s&client_id=%s&client_secret=%s&grant_type=%s", tostring(token), myData.client_id, myData.client_secret, myData.grant_type_refresh)
  network.request( myData.url_access_token, "POST", requestimportantDataLis, params)
end

function requestimportantData(code)
	local params = {}
	params.body = string.format("code=%s&client_id=%s&client_secret=%s&redirect_uri=%s&grant_type=%s", code, myData.client_id, myData.client_secret, myData.redirect_uri, myData.grant_type_authorization)
	network.request( myData.url_access_token, "POST", requestimportantDataLis, params)
end


function redirectLis(request)
	local errors = string.match(request, "GET /??error=([%w_/.=?]+)")
	local code = string.match(request, "GET /??code=([%w--_/.=?]+)")
	if(errors or not code) then
		signInUser()
		return
	else 
		native.cancelWebPopup()
		requestimportantData(code)
	end

end

function authorizationListener( event )
	if event.errorCode then
        native.showAlert( "Error!", event.errorMessage, { "OK" } )
    end

    if event.type then
        if event.type == "loaded" then
        	authorization_code = string.match( event.url, 'code=(.+)' ) -- handle the case where "error=" is returned
        	if authorization_code then
        		local tempTable =authorization_code:split("&")
        		authorization_code = tempTable[1]
        		webView:removeEventListener( "urlRequest", authorizationListener )
        		requestimportantData(authorization_code)
        	end
        end
    end
end

function modParams(url, params)
  local newURL = url .. "?"
  local first_arg = true
  for i, v in pairs(params) do
  	if first_arg == false then
  		newURL = newURL .. "&"
  		newURL = newURL .. i .. "=" .. v
  	else
  		newURL = newURL .. i .. "=" .. v
  		first_arg = false
  	end
  end


  return newURL
end


function m.signIn2 (Lis, clientId, clientSecret, redirectUri, authorizationUrl, accessTokenUrl, scope, serviceName)
  local self = setmetatable( {}, m )
  myData.client_id = clientId
  myData.client_secret = clientSecret
  myData.redirect_uri = redirectUri
  myData.url_authorization = authorizationUrl
  myData.url_access_token = accessTokenUrl
  myData.importantData_file = "google drive.json"
  myData.scope = scope

  connectLis = Lis
  if (lightLogin == nil) then
    local file = io.open(system.pathForFile("google drive.json", system.DocumentsDirectory), "r")
      if file then
          local account = json.decode(file:read( "*a" ))
          io.close( file )
          getNewToken(account["refreshToken"])
          lightLogin = true
      end
  end
end
m.signIn = function(Lis, clientId, clientSecret, redirectUri, authorizationUrl, accessTokenUrl, scope, serviceName)
  local self = setmetatable( {}, m )
  myData.client_id = clientId
  myData.client_secret = clientSecret
  myData.redirect_uri = redirectUri
  myData.url_authorization = authorizationUrl
  myData.url_access_token = accessTokenUrl
  myData.importantData_file = "google drive.json"
  myData.scope = scope
	connectLis = Lis

	local file = io.open(system.pathForFile(myData.importantData_file, system.DocumentsDirectory), "r")
    if file then
        local account = json.decode(file:read( "*a" ))
        io.close( file )
        getNewToken(account["refreshToken"])
    else
    	signInUser("blank")
	end
end
m.signInWindows = function(Lis, clientId, clientSecret, redirectUri, authorizationUrl, accessTokenUrl, scope, serviceName)
  local self = setmetatable( {}, m )
  myData.client_id = clientId
  myData.client_secret = clientSecret
  myData.redirect_uri = redirectUri
  myData.url_authorization = authorizationUrl
  myData.url_access_token = accessTokenUrl
  myData.importantData_file = "google drive.json"
  myData.scope = scope
  connectLis = Lis

  local file = io.open(system.pathForFile(myData.importantData_file, system.DocumentsDirectory), "r")
    if file then
        local account = json.decode(file:read( "*a" ))
        io.close( file )
        getNewToken(account["refreshToken"])
    else
      signInUser("windows")
  end
end
function m.codeConevert(lis,clientId, clientSecret, redirectUri, authorizationUrl, accessTokenUrl, scope, myCode )
  myData.client_id = clientId
  myData.client_secret = clientSecret
  myData.redirect_uri = redirectUri
  myData.url_authorization = authorizationUrl
  myData.url_access_token = accessTokenUrl
  myData.importantData_file = "google drive.json"
  myData.scope = scope
  requestimportantData(myCode)
end
function m.request (url, method, Lis, tokenQualifier, requestParameters, myBody)
	local actualURL = nil
	local apiResponse = {
    	name = "apiResponse",
	}
	if(not importantData) then
		apiResponse.isError = true
		apiResponse.response = "There is no token."
		pcall(Lis, apiResponse)
	else
		local params = {}
		local headers = {}
      headers["Content-Type"] = "application/json"
			headers["Authorization"] = "Bearer " .. importantData["access_token"]
			params.headers = headers
      params.body =  json.encode(myBody)
		if requestParameters then
			actualURL = modParams(url, requestParameters)
			if tokenQualifier then
				actualURL = actualURL .. "&" .. tokenQualifier .. "=" .. importantData["access_token"]
			end
		else
			actualURL = url
			if tokenQualifier then
				actualURL = actualURL .. "?" .. tokenQualifier .. "=" .. importantData["access_token"]
			end
		end
		network.request(actualURL, method, function(event) 
			apiResponse.isError = event.isError
			apiResponse.response = event.response
			pcall(Lis, apiResponse)
		end,  params)
	end
end
function m.requestAndFile (url, method, Lis, tokenQualifier, requestParameters, myBody, filename, baseDirectory,contentType, myFileName)
  local actualURL = nil
  local apiResponse = {
      name = "apiResponse",
  }
  if(not importantData) then
    apiResponse.isError = true
    apiResponse.response = "There is no token."
    pcall(Lis, apiResponse)
  else
    local MultipartFormData = require("plugin.googleDrive.class_MultipartFormData")
    local multipart = MultipartFormData.new()
    multipart:addHeader("Authorization", "Bearer " .. importantData["access_token"])
    local myMethod = method
    if (method == "PATCH") then
      myMethod = "POST"
      multipart:addHeader("X-HTTP-Method-Override", "PATCH")
    end
    if (myBody) then
      for k,v in pairs( myBody ) do
        multipart:addField(k,v)
      end
    end
    multipart:addFile(myFileName, system.pathForFile( filename, baseDirectory ), contentType, filename)
    local params = {}
    params.body = multipart:getBody() -- Must call getBody() first!
    params.headers = multipart:getHeaders() -- Headers not valid until getBody() is called.

      --params.headers = headers
      --myBody.filename = filename
      --myBody.baseDirectory = baseDirectory
      --params.body =  json.encode(myBody)
    if requestParameters then
      actualURL = modParams(url, requestParameters)
      if tokenQualifier then
        actualURL = actualURL .. "&" .. tokenQualifier .. "=" .. importantData["access_token"]
      end
    else
      actualURL = url
      if tokenQualifier then
        actualURL = actualURL .. "?" .. tokenQualifier .. "=" .. importantData["access_token"]
      end
    end
    network.request(actualURL, myMethod, function(event) 
      apiResponse.isError = event.isError
      apiResponse.response = event.response
      pcall(Lis, apiResponse)
    end,  params)
  end
end
function m.requestAndDownload(url, method, Lis, tokenQualifier, requestParameters, myBody, filename, baseDirectory)
  local actualURL = nil
  local apiResponse = {
      name = "apiResponse",
  }
  if(not importantData) then
    apiResponse.isError = true
    apiResponse.response = "There is no token."
    pcall(Lis, apiResponse)
  else
    print(filename)
    local params = {}
    local headers = {}
      headers["Authorization"] = "Bearer " .. importantData["access_token"]
      params.headers = headers
      params.body =  json.encode(myBody)
    if requestParameters then
      actualURL = modParams(url, requestParameters)
      if tokenQualifier then
        actualURL = actualURL .. "&" .. tokenQualifier .. "=" .. importantData["access_token"]
      end
    else
      actualURL = url
      if tokenQualifier then
        actualURL = actualURL .. "?" .. tokenQualifier .. "=" .. importantData["access_token"]
      end
    end
    network.download(actualURL, method, function(event) 
      apiResponse.isError = event.isError
      apiResponse.response = event.response
      pcall(Lis, apiResponse)
    end,  params, filename,baseDirectory)
  end
end

return m