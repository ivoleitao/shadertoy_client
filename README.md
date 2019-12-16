# shadertoy_client
A [Shadertoy API](https://github.com/ivoleitao/shadertoy_api) HTTP client implementation

[![Pub Package](https://img.shields.io/pub/v/shadertoy_client.svg?style=flat-square)](https://pub.dartlang.org/packages/shadertoy_client)
[![Build Status](https://github.com/ivoleitao/shadertoy_api/workflows/build/badge.svg)](https://github.com/ivoleitao/shadertoy_client/actions)
[![Coverage Status](https://codecov.io/gh/ivoleitao/shadertoy_client/graph/badge.svg)](https://codecov.io/gh/ivoleitao/shadertoy_client)
[![Package Documentation](https://img.shields.io/badge/doc-shadertoy_client-blue.svg)](https://www.dartdocs.org/documentation/shadertoy_client/latest)
[![GitHub License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Introduction

This package implements the client API's defined in the [shadertoy_api](https://pub.dev/packages/shadertoy_api) package providing a number of operations over the [Shadertoy](https://www.shadertoy.com) REST and Site APIs 

## Capabilities

**REST API**

* `Find shader` by id
* `Find shaders` from a list of id's
* `Query shaders by term`, tags and sort them by *name*, *likes*, *views*, *neweness* and by *hotness* (proportional to popularity and inversly propostional to lifetime). All the query results are paginated.
* `Find all shader ids`
* `Find shaders ids by term`, tags and sort them by *name*, *likes*, *views*, *neweness* and by *hotness* (proportional to popularity and inversly propostional to lifetime). All the query results are paginated.

**Site API**

All the REST API features plus the following:
* `Login`
* `Logout`
* `Find user` by id
* `Find shaders by user id`
* `Query shaders by user id`, tags and sort them by *name*, *likes*, *views*, *neweness* and by *hotness* (proportional to popularity and inversly propotional to lifetime). All the query results are paginated as well.
* `Find comments` by shader id
* `Find playlist` by id.
* `Query shaders by playlist id`. All the query results are paginated.
* `Query shader ids by playlist id`. All the query results are paginated. 
* `Download preview`, i.e. the the shader thumbnails
* `Download media`, any other media provided by the Shadertoy website

## Getting Started

Add this to your `pubspec.yaml` (or create it):

```dart
dependencies:
    shadertoy_client: ^1.0.0-dev.3
```

Run the following command to install dependencies:

```dart
pub install
```

Optionally use the following command to run the tests:

```dart
pub run test
```

Finnaly, to start developing import the library:

```dart
import 'package:shadertoy_client/shadertoy_client.dart';
```

## Usage

You can use this library with the following building blocks:
* [`ShadertoyWSClient`](https://github.com/ivoleitao/shadertoy_client/blob/develop/lib/src/ws/ws_client.dart)
* [`ShadertoySiteClient`](https://github.com/ivoleitao/shadertoy_client/blob/develop/lib/src/site/site_client.dart)
* [`ShadertoyHybridClient`](https://github.com/ivoleitao/shadertoy_client/blob/develop/lib/src/hybrid/hybrid_client.dart)

### ShadertoyWSClient

### ShadertoySiteClient

### ShadertoyHybridClient

## Contributing

This a unofficial [Shadertoy](https://www.shadertoy.com) client library. It is developed by best effort, in the motto of "Scratch your own itch!", meaning APIs that are meaningful for the author use cases.

If you would like to contribute with other parts of the API, feel free to make a [Github pull request](https://github.com/ivoleitao/shadertoy_client/pulls) as I'm always looking for contributions for:
* Tests
* Documentation
* New APIs


## Features and Bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://github.com/ivoleitao/shadertoy_client/issues/new

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details