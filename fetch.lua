--[[

    Fetch for Playdate
        A wrapper to simplify HTTP requests

    SETUP
        Make sure you call HTTP.update()
        in your playdate.update handler

    PARAMS
        HTTP.fetch(url, [options], callback, [reason])
            - url: string of the full URL (including http:// or https://)
            - options: (optional) table with additional options for the request
            - callback: function that is called with (response, error)
            - reason: (optional) string that is shown in the network access popup

        The response table contains:
            { ok: boolean, status: number, statusText: string, body: string, headers: table }

        The options table can contain the following (all optional):
            - method: string of the HTTP verb to use
            - headers: string or table to set the request headers
            - body: string of the data to send with the request

    BASIC EXAMPLE
        HTTP.fetch("http://example.com", function(res, err)
            if not err and res.ok then
                print(res.body)
            end
        end)

    ADVANCED EXAMPLE
        HTTP.fetch("https://example.com/auth", {
            method: "POST",
            headers = { ["Content-Type"] = "application/json" },
            body = json.encode({ username = "crankles", password = "*****" })
        }, function(res)
            local token = res.headers["Authorization"]
            -- ...
        end)

]] --

local function noop() end

local function parseURL(url)
    local scheme, host, port, path = url:match("^([a-zA-Z][a-zA-Z0-9+.-]*)://([^/:]+):?(%d*)(/?.*)$")
    return scheme, host, tonumber(port), path
end

local statusText <const> = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [102] = "Processing",
    [103] = "Early Hints",

    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [207] = "Multi-Status",
    [208] = "Already Reported",
    [226] = "IM Used",

    -- 3xx resolved internally

    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Timeout",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Content Too Large",
    [414] = "URI Too Long",
    [415] = "Unsupported Media Type",
    [416] = "Range Not Satisfiable",
    [417] = "Expectation Failed",
    [418] = "I'm a teapot",
    [421] = "Misdirected Request",
    [422] = "Unprocessable Content",
    [423] = "Locked",
    [424] = "Failed Dependency",
    [425] = "Too Early",
    [426] = "Upgrade Required",
    [428] = "Precondition Required",
    [429] = "Too Many Requests",
    [431] = "Request Header Fields Too Large",
    [451] = "Unavailable For Legal Reasons",

    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Timeout",
    [505] = "HTTP Version Not Supported",
    [506] = "Variant Also Negotiates",
    [507] = "Insufficient Storage",
    [508] = "Loop Detected",
    [510] = "Not Extended",
    [511] = "Network Authentication Required",
}

local function runTask(task, callback)
    local conn = playdate.network.http.new(task.host, task.port, task.ssl, task.reason)
    if not conn then
        callback(nil, "Permission denied")
        return
    end

    conn:setConnectTimeout(5)

    local status, headers
    conn:setHeadersReadCallback(function()
        status = conn:getResponseStatus()
        headers = conn:getResponseHeaders()
    end)

    local buffer = {}
    conn:setRequestCallback(function()
        local bytes = conn:getBytesAvailable()
        if bytes > 0 then
            buffer[#buffer + 1] = conn:read(bytes)
        end
    end)

    conn:setRequestCompleteCallback(function()
        local err = conn:getError()
        if err then
            callback(nil, err)
        else
            callback({
                ok = status >= 200 and status < 300,
                status = status,
                statusText = statusText[status] or "Unknown Status",
                headers = headers,
                body = table.concat(buffer, ""),
            })
        end
    end)

    local ok, err = conn:query(task.method, task.path, task.headers, task.body)
    if not ok then
        callback(nil, err)
    end
end

HTTP = { isLoading = false }

local queue = {}
function HTTP.update()
    if #queue == 0 or HTTP.isLoading then return end
    local task = table.remove(queue, 1)
    HTTP.isLoading = true
    runTask(task, function(res, err)
        HTTP.isLoading = false
        task.onComplete(res, err)
    end)
end

function HTTP.fetch(url, options, onComplete, reason)
    HTTP.scheduled = true
    if type(options) == 'function' then
        options, onComplete, reason = {}, options, onComplete
    end

    local scheme, host, port, path = parseURL(url)
    queue[#queue + 1] = {
        host = host,
        port = port or (scheme == "https" and 443 or 80),
        ssl = scheme == "https",
        path = path ~= "" and path or "/",
        method = options.method or "GET",
        headers = options.headers,
        body = options.body,
        reason = reason,
        onComplete = onComplete or noop
    }
end
