local m = {}
local oauth2 = require( "plugin.googleDrive.oauth2" )
local json = require( "json" )
local clientSecret = ""
local redirectUri =  ""
local storeCall
local clientId
local achievementIcon
--
local googleRequestEndpoint = "https://www.googleapis.com/drive/v3"
local authUrl = "https://accounts.google.com/o/oauth2/auth"
local gpgsScope = "https://www.googleapis.com/auth/drive"
local tokenAuth="https://accounts.google.com/o/oauth2/token"
local fileName = "google drive.json"

m.googleRequestEndpoint = googleRequestEndpoint
--drive variable 
m.get = "GET"
m.put = "PUT"
m.post = "POST"
m.delete = "DELETE" 
m.patch = "PATCH" 
m.isLoginedIn = false
m.haveRefreshToken = false
m.myCode = nil

--version
m.version = "2.0"
--set scope
local appDataOn = true
function m.onlyAppAccess(myBool)
    if (myBool and myBool == true) then
        appDataOn = true
        gpgsScope = "https://www.googleapis.com/auth/drive.appdata"
    else
        gpgsScope = "https://www.googleapis.com/auth/drive"
    end
end

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
--
local function refreshToken(  )
    local file = io.open(system.pathForFile(fileName, system.DocumentsDirectory), "r")
    -- First, check if it's a saved refresh token, so we can authenticate user automatically
    if file then
        --print("OAuth2.connect: Requesting Token using refreshToken")
        local account = json.decode(file:read( "*a" ))
        if (account["refreshToken"]) then
            return true
        else
            return false
        end
    end
end
m.haveRefreshToken = refreshToken()

function m.init( clientIdTemp, clientSecretTemp, redirectUriTemp)
    if (clientIdTemp) then
        clientId = clientIdTemp
    else
        print( "no client id" )
    end
    if (clientSecretTemp) then
        clientSecret = clientSecretTemp
    else
        print( "no client id" )
    end
    if (redirectUriTemp) then
        redirectUri = redirectUriTemp
    else
        print( "no redirect url" )
    end
end
local function didConnect(event)
    if(not event.isError) then
        m.isLoginedIn = true
        storeCall({isError = false, error = nil, response = "you are logined in"})
    else
        storeCall({isError = true, error = "could not login", response = "could not login"})
    end
    m.haveRefreshToken = refreshToken()
    storeCall= nil
end
function m.login( lis )
    if (m.isLoginedIn == false) then
        oauth2.signIn(didConnect, clientId, clientSecret, redirectUri, authUrl, tokenAuth, gpgsScope)
        storeCall = lis
    else
        lis({error = nil, isError=false, response = "already signed in" })
    end
end
function m.request(myUrl, sendType, lis, params, myBody, filename, baseDirectory, contentType, myFileName)
    if (m.isLoginedIn == false) then
        lis({error = "not signed in", isError=true, response = "not signed in" })
    else
        if (filename and baseDirectory and contentType and myFileName) then
            oauth2.requestAndFile(myUrl, sendType, function(event) lis(event) end, nil, params, myBody, filename, baseDirectory, contentType, myFileName)
        else
            oauth2.request(myUrl, sendType, function(event) lis(event) end, nil, params, myBody)
        end
    end
end
function m.download(fileId, acknowledgeAbuse, lis,fileName, baseDirectory)
    if (m.isLoginedIn == false) then
        lis({error = "not signed in", isError=true, response = "not signed in" })
    else
        tempAcknowledgeAbuse = false
        if (acknowledgeAbuse and acknowledgeAbuse == true) then
            tempAcknowledgeAbuse = true
        end
        oauth2.requestAndDownload(googleRequestEndpoint.."/files/"..fileId.."?alt=media", "GET", function(event) lis(event) end, nil, nil ,nil, fileName, baseDirectory)
    end
end
function m.listFilesInAppData( lis )
    if (m.isLoginedIn == false) then
        lis({error = "not signed in", isError=true, response = "not signed in" })
    else
        if (appDataOn== true) then
            m.request("https://www.googleapis.com/drive/v3/files/", "GET", function ( e )
                if (e.isError) then
                    lis({error = "Unable to make request: "..e.response, isError=true, response = "Unable to make request: "..e.response })
                else
                    lis({error = nil, isError=false, response = e.response })
                end
            end, {spaces= "appDataFolder"} )
        else
            lis({error = "You can not use this api because you are not set on the right scope please drive.onlyAppAccess(true)", isError=true, response = "You can use this api because you are not set on the right scope please drive.onlyAppAccess(true)" })
        end
    end
end
function m.updateFileInAppData( fileId,filename, dir, contentType,lis )
    if (m.isLoginedIn == false) then
        lis({error = "not signed in", isError=true, response = "not signed in" })
    else
        if (appDataOn== true) then
            m.request("https://www.googleapis.com/upload/drive/v3/files/"..fileId, "PATCH", function ( ev )
                if (ev.isError) then
                    lis({error = "Unable to make request: "..ev.response, isError=true, response = "Unable to make request: "..ev.response })
                else
                    lis({error = nil, isError=false, response = ev.response })
                end
            end, {fileId= fileId, uploadType= "multipart"}, {name = fileName}, fileName, myDir, contentType, fileName )
        else
            lis({error = "You can not use this api because you are not set on the right scope please drive.onlyAppAccess(true)", isError=true, response = "You can use this api because you are not set on the right scope please drive.onlyAppAccess(true)" })
        end
    end
end
--[[was not work just use drive.download
function m.downloadInAppData(fileId, fileName, baseDirectory, contentType,lis)
    if (m.isLoginedIn == false) then
        lis({error = "not signed in", isError=true, response = "not signed in" })
    else
        tempAcknowledgeAbuse = false
        if (acknowledgeAbuse and acknowledgeAbuse == true) then
            tempAcknowledgeAbuse = true
        end
        oauth2.requestAndDownload(googleRequestEndpoint.."/files/"..fileId.."/export", "GET", function(event) lis(event) end, nil, {mimeType = "application/vnd.google-apps.folder"}, nil,fileName, baseDirectory)
    end
end
]]--
function m.createFileInAppData( filename, dir, contentType, lis )
    local myDir = dir
    if (myDir== nil) then
        myDir = system.ResourceDirectory
    end
    if (m.isLoginedIn == false) then
        lis({error = "not signed in", isError=true, response = "not signed in" })
    else
        if (appDataOn== true) then
            --this creates a file id for us to upload to, this is a work around
            local fileName = filename
            m.request("https://www.googleapis.com/upload/drive/v3/files", "POST", function ( e )
                if (e.isError) then
                    lis({error = "Unable to make request: "..e.response, isError=true, response = "Unable to make request: "..e.response })
                else
                    local tempTable = json.decode(e.response)
                    if (tempTable.id) then
                        local fileId = tempTable.id
                        local fileName = filename
                        m.request("https://www.googleapis.com/upload/drive/v3/files/"..fileId, "PATCH", function ( ev )
                            if (ev.isError) then
                                lis({error = "Unable to make request: "..ev.response, isError=true, response = "Unable to make request: "..ev.response })
                            else
                                lis({error = nil, isError=false, response = ev.response })
                            end
                        end, {fileId= fileId, uploadType= "multipart"}, {name = fileName}, fileName, myDir, contentType, fileName )
                    else
                        lis({error = "Unable to make request: "..e.response, isError=true, response = "Unable to make request: "..e.response })
                    end
                end
            end, {uploadType= "multipart"}, {name = fileName,mimeType = "application/vnd.google-apps.folder", parents={"appDataFolder"}},"config.json", myDir, contentType, fileName )
        else
            lis({error = "You can not use this api because you are not set on the right scope please drive.onlyAppAccess(true)", isError=true, response = "You can use this api because you are not set on the right scope please drive.onlyAppAccess(true)" })
        end
    end
end
function m.signOut( lis )
    if (m.isLoginedIn == false) then
       lis({error= nil, isError = false, response = "already signed out"})
    else
        local result, reason = os.remove( system.pathForFile( fileName, system.DocumentsDirectory ) )

        if result then
            lis({error= false, isError = false, response = "removed file and signed out"})
        else
            lis({error= nil,response = "could not remove refresh token but logged out", isError = false})
        end 
        m.isLoginedIn = false
        m.haveRefreshToken = refreshToken()
    end
end

return m