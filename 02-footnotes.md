----
# Footnotes

- At the moment where an organisation runs 2+ onion addresses for
  closely related services that do not reflect distinct languages /
  national interests, I am posting a link to an index of their
  onions. Examples: Riseup, Systemli, TorProject, ...
- The master list of Onion SSL EV Certificates may be viewed at
  https://crt.sh/?q=\.onion

### RWOS Status Detector

- :white_check_mark: site up
- :eight_spoked_asterisk: site up, and redirected to another page
- :no_entry_sign: site up, but could not access the page
- :stop_sign: site up, but reported a system error
- :sos: site returned no data, or is down, or curl experienced a transient or permanent network error; may also reflect a problem with the RWOS server connection
- :question: same as :sos: but curl specifically mentioned inability to fetch an onion descriptor
- :exclamation: same as :sos: but curl specifically mentioned inability to connect to the server
- :alarm_clock: same as :sos: but curl specifically mentioned connection timeout as an issue
- :timer_clock: same as :sos: but curl specifically mentioned ttl expiry as an issue
- :key: same as :sos: but curl specifically mentioned SSL certificates as an issue
- :new: site is newly added, no data yet

You can also see the [history of updates](https://github.com/alecmuffett/real-world-onion-sites/commits/master/README.md).

### Codes & Exit Statuses

Mouse-over the icons for details of HTTP codes, curl exit statuses,
and the number of attempts made on each site.

- codes [are from HTTP and are documented elsewhere](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes); RWOS-internal ones include:
  - `901` - malformed HTTP response
  - `902` - malformed HTTP response
  - `903` - malformed HTTP response, commonly including (e.g.) invalid HTTPS certificate
  - `904` - HTTP status code parse error
  - `910` - connection timeout
- exits [are from Curl and are documented elsewhere](https://curl.haxx.se/libcurl/c/libcurl-errors.html); common ones include:
  - `7` - "curl couldn't connect"
  - `52` - "curl got nothing", received no data from upstream

### TLS Security

Due to the fundamental protocol differences between `HTTP` and
`HTTPS`, it is not wise to consider HTTP-over-Onion to be "as secure
as HTTPS"; web browsers **do** and **must** treat HTTPS requests in
ways that are fundamentally different to HTTP, e.g.:

- with respect to cookie handling, or
- where the trusted connection terminates, or
- how to deal with loading embedded insecure content, or
- whether to permit access to camera and microphone devices (WebRTC)

...and the necessity of broad adherence to web standards would make it
harmful to attempt to optimise just one browser (e.g. Tor Browser) to
elevate HTTP-over-Onion to the same levels of trust as HTTPS-over-TCP,
let alone HTTPS-over-Onion.  Doubtless some browsers will *attempt* to
implement "better-than-default trust and security via HTTP over
onions", but this behaviour will not be **standard**, cannot be
**relied upon** by clients/users, and will therefore be **risky**.

**tl;dr** - HTTP-over-Onion should not be considered as secure as
HTTPS-over-Onion, and attempting to force it thusly will create a
future compatibility mess for the ecosystem of onion-capable browsers.

### Feedback

[The issues page](https://github.com/alecmuffett/real-world-onion-sites/issues)
is the fastest and most effective way to submit a suggestion; if you
lack a Github account, try messaging `@alecmuffett` on Twitter.

----
[Back to Top](#real-world-onion-sites)
