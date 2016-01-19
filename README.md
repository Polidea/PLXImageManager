# PLXImageManager

[![CI Status](https://img.shields.io/travis/Polidea/PLXImageManager.svg?style=flat)](https://travis-ci.org/Polidea/PLXImageManager)
[![Version](https://img.shields.io/cocoapods/v/PLXImageManager.svg?style=flat)](http://cocoapods.org/pods/PLXImageManager)
[![License](https://img.shields.io/cocoapods/l/PLXImageManager.svg?style=flat)](http://cocoapods.org/pods/PLXImageManager)
[![Platform](https://img.shields.io/cocoapods/p/PLXImageManager.svg?style=flat)](http://cocoapods.org/pods/PLXImageManager)

Image manager/downloader for iOS

## Usage

### Creation
```objective-c
PLXURLImageProvider * provider = [PLXURLImageProvider new];
PLXImageManager * manager = [[PLXImageManager alloc] initWithProvider:provider];
```

The *provider* is responsible for retrieving a image if it is not available in cache. The standard PLXURLImageProvider is provided as convenience. It takes a URL and simply downloads up to 5 images at once. By implementing the *PLXImageManagerProvider* protocol yourself, you can adapt the manager to fit your needs.
	
### Requesting images
```objective-c
[manager imageForIdentifier:@”http://placehold.it/350/00aa00/ffffff” 
                placeholder:[UIImage imageNamed:@”placeholder” 
	               callback:^(UIImage *image, BOOL isPlaceholder) {
	//consume the image here
}];
```
### Canceling requests
The -imageForIdentifier:placeholder:callback: method returns a PLXImageManagerRequestToken that can be used to cancel requests for images. 


This is important in scenarios like scrolling a UITableView, when cells can disappear before the download finishes. Canceling those will spare network usage, and reduce the time for the right image to appear.


```objective-c
PLXImageManagerRequestToken * token = nil;

//get token
token = [manager imageForIdentifier:@”http://placehold.it/350/00aa00/ffffff”
                        placeholder:[UIImage imageNamed:@”placeholder”
                           callback:^(UIImage *image, BOOL isPlaceholder) {
	//consume the image here
}];

//cancel the download
[token cancel];
```

A convenience method is provided to store (and retrieve) a token on any NSObject subclass.


```objective-c
//storing a token
[aObject plx_storeToken:token];

//retrieving a token
token = [aObject plx_retrieveToken];
``` 

### Caching
PLXImageManager makes use of a combination of memory and file based caches. Refer to the documentation for the memoryCacheCountLimit and fileCacheTotalSizeLimit properties for details.

### Example

The included example project demonstrates:

* instantiating PLXImageManager
* requesting images using the convenience category on UIImageView

To run it, clone the repo, and run `pod install` from the Example directory first. 

## Requirements

iOS 7+

## Installation

PLXImageManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PLXImageManager"
```

## Author

Antoni Kedracki, antoni.kedracki@polidea.com

You can read more about the internal workings of PLImageManager [here](http://www.polidea.com/en/Blog,141,Implementing_a_high_performance_image_manager_for_iOS).

## License

PLXImageManager is available under the BSD license. See the LICENSE file for more info.

Copyright (c) 2013 Polidea. This software is licensed under the BSD License.
