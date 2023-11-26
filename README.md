# Bugsnag Event Extractor

## Overview

This Ruby CLI tool is designed to extract event data from the Bugsnag API and
output it in a CSV format. It's useful for analyzing and archiving Bugsnag
events for projects and organizations. The script handles pagination and rate
limiting, ensuring all desired data is fetched efficiently and reliably.

## Requirements

- Ruby
- Bundler

## Installation
1. **Clone or download this repository:**
   ```bash
   git clone https://github.com/cbartlett/bugsnag-extract
   ```
2. **Navigate to the script's directory:**
   ```bash
   cd bugsnag-extract
   ```

## Usage

Several command-line options are available for specifying details like the
Bugsnag authentication token, organization name, project name, and error ID.

### Command-Line Options:

- `-tTOKEN` or `--token=TOKEN`: **Required.** Your Bugsnag authentication token.
- `-oORG` or `--organization=ORG`: Bugsnag organization name. If omitted, the first organization accessible to the token will be used.
- `-pPROJECT` or `--project=PROJECT`: Bugsnag project name within the specified organization. If omitted, the first project in the organization will be used.
- `-eERROR_ID` or `--error-id=ERROR_ID`: **Required.** The error ID for which events are to be fetched.

### Example:
```bash
./script.rb -t YOUR_BUGSNAG_TOKEN -e YOUR_ERROR_ID
```

The script will output the events data in CSV format to standard output.
Redirect the output to a file if you want to save it.

### Handling Rate Limits:

The script includes logic to handle Bugsnag API's rate limiting. If the rate
limit is exceeded, the script will pause for a brief period before retrying the
request.

## Contributing

Contributions to this project are welcome. Please ensure that your code adheres
to the existing style and that all tests pass.

## License

Released under the terms of the MIT license.
