# shadertoy_client
A [Shadertoy API](https://github.com/ivoleitao/shadertoy_api) HTTP client implementation

[![Pub Package](https://img.shields.io/pub/v/shadertoy_client.svg?style=flat-square)](https://pub.dartlang.org/packages/shadertoy_client)
[![Build Status](https://github.com/ivoleitao/shadertoy_api/workflows/build/badge.svg)](https://github.com/ivoleitao/shadertoy_client/actions)
[![Coverage Status](https://codecov.io/gh/ivoleitao/shadertoy_client/graph/badge.svg)](https://codecov.io/gh/ivoleitao/shadertoy_client)
[![Package Documentation](https://img.shields.io/badge/doc-shadertoy_client-blue.svg)](https://www.dartdocs.org/documentation/shadertoy_client/latest)
[![GitHub License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Introduction

This package implements the client API's defined in the [shadertoy_api](https://pub.dev/packages/shadertoy_api) package providing access to the [Shadertoy](https://www.shadertoy.com) REST and Site APIs. 

## Capabilities

This package provides a number of operations through two types of clients:

**REST APIs**

* `Find shader` by id
* `Find shaders` from a list of id's
* `Query shaders by term`, tags and sort them by *name*, *likes*, *views*, *neweness* and by *hotness* (proportional to popularity and inversly propostional to lifetime). All the query results are paginated.
* `Find all shader ids`
* `Find shaders ids by term`, tags and sort them by *name*, *likes*, *views*, *neweness* and by *hotness* (proportional to popularity and inversly propostional to lifetime). All the query results are paginated.

**Site APIs**

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

Finaly, to start developing import the library:

```dart
import 'package:shadertoy_client/shadertoy_client.dart';
```

## Usage

You can use this library with one of the following classes:
* [`ShadertoyWSClient`](https://github.com/ivoleitao/shadertoy_client/blob/develop/lib/src/ws/ws_client.dart), for the REST API. This client can only provide shaders made available with the `public+api` privacy settings
* [`ShadertoySiteClient`](https://github.com/ivoleitao/shadertoy_client/blob/develop/lib/src/site/site_client.dart) for the Site API. This client provides all the shaders currently available in the [Shadertoy](https://www.shadertoy.com) website
* [`ShadertoyHybridClient`](https://github.com/ivoleitao/shadertoy_client/blob/develop/lib/src/hybrid/hybrid_client.dart), which allows the user to constrain the requests to shaders with `public+api` privacy settings while complementing the base REST API with some additional operations only available in the Site API.

### ShadertoyWSClient

> Note: replace `apiKey` with the API key obtained in your user [apps](https://www.shadertoy.com/myapps) page

#### Query a shader by id

```dart
    var apiKey = '<apiKey>';
    var client = ShadertoyWSClient.build(apiKey);
    var fsr = await client.findShaderById('3lsSzf');
    if (fsr.ok) {
        print('${fsr?.shader?.info?.id}');
        print('\tName: ${fsr?.shader?.info?.name}');
        print('\tUserName: ${fsr?.shader?.info?.userId}');
        print('\tDate: ${fsr?.shader?.info?.date}');
        print('\tDescription: ${fsr?.shader?.info?.description}');
        print('\tViews: ${fsr?.shader?.info?.views}');
        print('\tLikes: ${fsr?.shader?.info?.likes}');
        print('\tPublish Status: ${fsr?.shader?.info?.publishStatus.toString().split('.').last}');
        print('\tTags: ${fsr?.shader?.info?.tags?.join(',')}');
        print('\tFlags: ${fsr?.shader?.info?.flags}');
        print('\tLiked: ${fsr?.shader?.info?.hasLiked}');
        print('\tRender Passes: ${fsr?.shader?.renderPasses?.length}');
        fsr?.shader?.renderPasses?.forEach((rp) => print('\t\t${rp?.name} has ${rp?.inputs?.length} input(s) and ${rp?.outputs?.length} output(s)'));
    } else {
        print('Error: ${fsr.error.message}');
    }
```

Output:

```
3lsSzf
	Name: Happy Jumping
	UserName: iq
	Date: 2019-07-25 00:49:38.000
	Description: A happy and blobby creature jumping. It gets off-model very often, but it looks good enough. Making of and related math/shader/art explanations (6 hours long): [url]https://www.youtube.com/watch?v=Cfe5UQ-1L9Q[/url]. 
	Views: 40436
	Likes: 358
	Publish Status: public_api
	Tags: procedural,3d,raymarching,sdf,animation
	Flags: 0
	Liked: false
	Render Passes: 1
		Image has 0 input(s) and 1 output(s)
```

#### Query shaders by `term`: 

```dart
    var apiKey = '<apiKey>';
    var client = ShadertoyWSClient.build(apiKey);
    var fsr = await ws.findShaders(term: 'elevated');
    if (fsr.ok) {
        print('${fsr.total} shader id(s) found');
        response?.shaders?.forEach((sh) {
            print('${sh?.shader?.info?.name}');
        });
    } else {
        print('Error: ${fsr.error.message}');
    }
```

and the output, with the returned shader id's matching the `term`:

```
10 shader id(s) found
MdX3Rr 
MdBGzG 
lslBz7 
MtK3Wc 
XlXGzS 
XdKGW1 
ltd3Wl 
4sdXD4 
MsfcR8 
XltSWH 
```

### ShadertoySiteClient

> Note: replace `user` and `password`, with the user credentials, where aplicable

#### Find a shader by id using a anonymous site client 

```dart
  var client = ShadertoySiteClient.build();

  var fsr = await ws.findShaderById('3lsSzf');
  if (fsr.ok) {
    print('${fsr?.shader?.info?.id}');
    print('\tName: ${fsr?.shader?.info?.name}');
    print('\tUserName: ${fsr?.shader?.info?.userId}');
    print('\tDate: ${fsr?.shader?.info?.date}');
    print('\tDescription: ${fsr?.shader?.info?.description}');
    print('\tViews: ${fsr?.shader?.info?.views}');
    print('\tLikes: ${fsr?.shader?.info?.likes}');
    print('\tPublish Status: ${fsr?.shader?.info?.publishStatus.toString().split('.').last}');
    print('\tTags: ${fsr?.shader?.info?.tags?.join(',')}');
    print('\tFlags: ${fsr?.shader?.info?.flags}');
    print('\tLiked: ${fsr?.shader?.info?.hasLiked}');
    print('\tRender Passes: ${fsr?.shader?.renderPasses?.length}');
    sr?.shader?.renderPasses?.forEach((rp) => print('\t\t${rp?.name} has ${rp?.inputs?.length} input(s) and ${rp?.outputs?.length} output(s)'));
  } else {
    print('Error: ${fsr.error.message}');
  }

```

Output:

```
3lsSzf
	Name: Happy Jumping
	UserName: iq
	Date: 2019-07-25 00:49:38.000
	Description: A happy and blobby creature jumping. It gets off-model very often, but it looks good enough. Making of and related math/shader/art explanations (6 hours long): [url]https://www.youtube.com/watch?v=Cfe5UQ-1L9Q[/url]. 
	Views: 40700
	Likes: 358
	Publish Status: public_api
	Tags: procedural,3d,raymarching,sdf,animation
	Flags: 0
	Liked: false
	Render Passes: 1
		Image has 0 input(s) and 1 output(s)
```

#### Anonymous usage of the site client versus logged in usage 

```dart

  var client =
      ShadertoySiteClient.build(user: '<user>', password: '<password>');

  print('Anonymous');
  var fsr = await client.findShaderById('3lsSzf');
  print('${fsr?.shader?.info?.id}');
  print('\tName: ${fsr?.shader?.info?.name}');
  print('\tLiked: ${fsr?.shader?.info?.hasLiked}');

  await site.login();

  print('Logged In');
  site.cookies.forEach((c) => print('${c.name}=${c.value}'));
  fsr = await client.findShaderById('3lsSzf');
  print('${fsr?.shader?.info?.id}');
  print('\tName: ${fsr?.shader?.info?.name}');
  print('\tLiked: ${fsr?.shader?.info?.hasLiked}');
```

Notice that the liked flag flips from `false` to `true` after the login

```
Anonymous
3lsSzf
        Name: Happy Jumping
        Liked: false
Logged In
sdtd=ed42bec0ab3f881fa7f180f1346dd6f9
3lsSzf
        Name: Happy Jumping
        Liked: true
```

#### Find shader comments

```dart
  var client = ShadertoySiteClient.build();

  var fcr = await client.findCommentsByShaderId('MdX3Rr');
  if (fcr.ok) {
    print('${fcr?.total} comment(s)');
  } else {
    print('Error: ${fcr.error.message}');
  }
```

Output:

```
30 comment(s)
```

#### Find a user by id

```dart
  var client = ShadertoySiteClient.build();

  var fur = await client.findUserById('iq');
  if (fur.ok) {
    print('${fur?.user?.id}');
    print('Name: ${fur?.user?.picture}');
    print('Member Since: ${fur?.user?.memberSince}');
    print('Shaders: ${fur?.user?.shaders}');
    print('Comments: ${fur?.user?.comments}');
    print('About:');
    print('${fur?.user?.about}');
  } else {
    print('Error: ${fur.error.message}');
  }
```

Output:

```
iq
Name: /media/users/iq/profile.png
Member Since: 2013-01-11 00:00:00.000
Shaders: 451
Comments: 4864
About:


*[url]http://www.iquilezles.org[/url]
*[url]https://www.patreon.com/inigoquilez[/url]
*[url]https://www.youtube.com/c/InigoQuilez[/url]
*[url]https://www.facebook.com/inigo.quilez.art[/url]
*[url]https://twitter.com/iquilezles[/url]
```

#### Find playlist by id

```dart
  var client = ShadertoySiteClient.build();

  var fpr = await client.findPlaylistById('week');
  if (fcr.ok) {
    print('${fpr?.playlist?.name}');
    print('${fpr?.playlist?.count} shader id(s)');
    fpr.playlist?.shaders?.forEach((shader) => print('$shader'));
  } else {
    print('Error: ${fpr.error.message}');
  }
```

Output:

```
Shaders of the Week
339 shader id(s)
ttXGWH
ttlGR4
tsKXR3
WtsGzB
WtfGWn
3ddGzn
...
```

### ShadertoyHybridClient

> Note: replace `apiKey` with the API key obtained in your user [apps](https://www.shadertoy.com/myapps) page

#### Find shader by `term` and obtain the shader comments

```dart
  var client = ShadertoyHybridClient.build(apiKey: apiKey);
  var fsr = await client.findShaders(term: 'Happy Jumping');

  if (fsr.ok) {
    if (fsr.shaders.isNotEmpty) {
      var fsc = await client.findCommentsByShaderId(fsr?.shaders?.first?.shader?.info?.id);
      if (fsc.ok) {
        print('Found ${fsc.comments.length} comments');
      } else {
        print('Error retrieving shader comments');
      }
    } else {
      print('Shader not found');
    }
  } else {
    print('Error: ${fsr.error.message}');
  }
```

Output:

```
3lsSzf
        Name: Happy Jumping
Found 62 comments
```

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