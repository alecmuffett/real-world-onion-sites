# Real-World Onion Sites

This is a list of substantial, commercial-or-social-good mainstream websites which provide onion services.

- no sites with an "onion-only" presence
- no sites for tech with less than (arbitrary) 10,000 users
- no nudity, exploitation, drugs, copyright infringement or sketchy-content sites
- the editor reserves all rights to annotate or drop any or all entries as deemed fit
- updated: [see the change history for specifics](https://github.com/alecmuffett/onion-sites-that-dont-suck/commits/master/README.md)
- licensed: cc-by-sa
- author/editor: alec muffett

## Notes

- If both v2 and v3 addresses are provided for a service, the v3 address will be preferred / cited
- The master list of Onion SSL EV Certificates may be viewed at https://crt.sh/?q=%25.onion
- This file (`README.md`) is auto-generated; do not submit changes nor pull-requests for it
  - Please submit an `Issue` for consideration / change requests

### RWOS Status Detector

- :white_check_mark: site up
- :eight_spoked_asterisk: site up, and redirected to another page
- :negative_squared_cross_mark: site up, but could not access the page
- :red_circle: site up, but reported a system error
- :sos: site returned no data, or is down, or curl experienced a transient network error
- :new: site is newly added, no data yet

### Codes & Exit Statuses

Mouse-over the icons for details of HTTP codes, curl exit statuses, and the number of attempts made on each site.

- codes [are from HTTP and are documented elsewhere](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes); RWOS-internal ones include:
  - `901`, `902`, `903` - malformed HTTP response
  - `904` - HTTP status code parse error
  - `910` - connection timeout
- exits [are from Curl and are documented elsewhere](https://curl.haxx.se/libcurl/c/libcurl-errors.html); common ones include:
  - `7` - "curl couldn't connect"
  - `52` - "curl got nothing", received no data from upstream
