# Fetch for Playdate

A wrapper to simplify HTTP requests

## The Basics

```lua
-- make sure you call HTTP.update()
-- in your playdate.update handler

HTTP.fetch("http://example.com", function(res, err)
    if not err and res.ok then
        print(res.body)
    end
end)
```

## More Details

1. Add `import "fetch.lua"` somewhere in your `main.lua` file
2. Call `HTTP.update()` in your `playdate.update` handler
3. Use `HTTP.fetch()` from anywhere in your code!

### HTTP.fetch(url, onComplete, \[reason\])

Schedules a basic GET request to the provided URL.

- `url` is a _string_ containing the full URL, including `http://` or `https://`
- `onComplete` is a _function_ that is called when the request is completed
- `reason` (optional) is a _string_ that the system shows in the network access popup

### onComplete(response, error)

Called when the request is completed.

- `response` is a _table_ containing the following fields:
  - `ok` a _boolean_ indicating that the request completed successfully (a `2xx` status code)
  - `status` a _number_ containing the status code
  - `body` a _string_ containing the contents of the response
- `err` is a _string_ containing the error message if `response` is `nil`

## Error Handling

A note on error handling, or, why you need to deal with both `err` and `response.ok`:

- `err` is set when something went wrong with the connection or request itself, for example when the user did not grant network permissions, or the request timed out.
- `response.ok` is `true` when the server responded with a `200` status code. If it's `false`, the server _did_ reply, but returned an error to you, for example a `404 Not Found` or `500 Server Error`.
