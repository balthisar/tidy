/**************************************************************************************************

	JSDNuValidator

	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDNuValidator.h"
#import "JSDNuVMessage.h"
#import "JSDNuValidatorDelegate.h"


@interface JSDNuValidator ()

/* Re-expose as read-write. */

@property (nonatomic, readwrite, strong, nullable) NSArray<JSDNuVMessage*> *messages;
@property (nonatomic, readwrite, strong, nullable) NSString *validatorConnectionErrorText;
@property (nonatomic, readwrite, assign) BOOL inProgress;


/* Internal properties. */

@property (nonatomic, readwrite, strong) NSTimer *throttleTimer;
@property (nonatomic, readwrite, assign) BOOL didRequestUpdate;
@property (nonatomic, readwrite, assign) BOOL validatorConnectionError;

@end


@implementation JSDNuValidator

@synthesize data = _data;
@synthesize dataIsXML = _dataIsXML;
@synthesize userAgent = _userAgent;
@synthesize url = _url;
@synthesize throttleTime = _throttleTime;
@synthesize autoUpdate = _autoUpdate;
@synthesize didRequestUpdate = _didRequestUpdate;

#pragma mark - Initialization


/*———————————————————————————————————————————————————————————————————*
 * - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
	if ( (self = [super init] ) )
	{
		self.autoUpdate = NO;
		self.validatorConnectionError = NO;
		self.throttleTime = 0.0f;
		self.didRequestUpdate = NO;
	}

	return self;
}


#pragma mark - Properties


/*———————————————————————————————————————————————————————————————————*
 * @property data
 *———————————————————————————————————————————————————————————————————*/
- (NSData *)data
{
	return _data;
}

- (void)setData:(NSData *)data
{
	if ( ![_data isEqualToData:data] )
	{
		_data = data;
		self.didRequestUpdate = YES;
	}
}


/*———————————————————————————————————————————————————————————————————*
 * @property dataIsXML
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)dataIsXML
{
	return _dataIsXML;
}

- (void)setDataIsXML:(BOOL)dataIsXML
{
	if ( _dataIsXML != dataIsXML)
	{
		_dataIsXML = dataIsXML;
		self.didRequestUpdate = YES;
	}
}


/*———————————————————————————————————————————————————————————————————*
 * @property userAgent
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)userAgent
{
	if (!_userAgent)
	{
		return @"JSDNuValidator/1.0 (https://www.balthisar.com)";
	}
	else
	{
		return _userAgent;
	}
}

- (void)setUserAgent:(NSString *)userAgent
{
	_userAgent = userAgent;
	self.didRequestUpdate = YES;
}


/*———————————————————————————————————————————————————————————————————*
 * @property url
 *———————————————————————————————————————————————————————————————————*/
- (NSURL *)url
{
	return _url;
}

- (void)setUrl:(NSURL *)url
{
	_url = url;
	[self performValidation];
	[self activateThrottleTimer];
}


/*———————————————————————————————————————————————————————————————————*
 * @property urlString
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingUrlString
{
	return [NSSet setWithArray:@[ @"url" ]];
}

- (NSString *)urlString
{
	return [self.url absoluteString];
}

- (void)setUrlString:(NSString *)urlString
{
	self.url = [NSURL URLWithString:urlString];
}


/*———————————————————————————————————————————————————————————————————*
 * @property throttleTime
 *———————————————————————————————————————————————————————————————————*/
- (float)throttleTime
{
	return _throttleTime;
}

- (void)setThrottleTime:(float)throttleTime
{
	_throttleTime = throttleTime < 1.0f ? 1.0f : throttleTime;
	self.didRequestUpdate = YES;
}


/*———————————————————————————————————————————————————————————————————*
 * @property autoUpdate
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)autoUpdate
{
	return _autoUpdate;
}

- (void)setAutoUpdate:(BOOL)autoUpdate
{
	if ( autoUpdate == _autoUpdate ) return;

	_autoUpdate = autoUpdate;
	self.didRequestUpdate = YES;
}


#pragma mark - Internal Properties


/*———————————————————————————————————————————————————————————————————*
 * @property didRequestUpdate
 *———————————————————————————————————————————————————————————————————*/
- (BOOL)didRequestUpdate
{
	return _didRequestUpdate;
}

- (void)setDidRequestUpdate:(BOOL)didRequestUpdate
{
	_didRequestUpdate = didRequestUpdate;

	[self activateThrottleTimer];
}


#pragma mark - Instance Methods


/*———————————————————————————————————————————————————————————————————*
 * Performs the validations on demand. Would be used to manually
 * refresh the validator data, and is call by performRefresh when
 * the timer allows it.
 *———————————————————————————————————————————————————————————————————*/
- (void)performValidation
{
	self.inProgress = YES;
	self.validatorConnectionError = NO;

	NSString *contentType = [NSString stringWithFormat:@"text/%@; charset=utf-8", self.dataIsXML ? @"xml" : @"html" ];
	NSURL *url = [NSURL URLWithString:[self.urlString stringByAppendingPathComponent:@"?out=json"]];

	AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:self.data];
	[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)self.data.length] forHTTPHeaderField:@"Content-Length"];
	[request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[request setTimeoutInterval:10];

	[[manager dataTaskWithRequest:request
				   uploadProgress:^(NSProgress * _Nonnull uploadProgress) {}
				 downloadProgress:^(NSProgress * _Nonnull downloadProgress) {}
				completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
	  {
		  if (!error)
		  {
			  if ([responseObject isKindOfClass:[NSDictionary class]])
			  {
				  self.validatorConnectionErrorText = nil;
				  self.messages = [JSDNuVMessage messageArrayFromResponseObject:responseObject];
			  }
		  }
		  else
		  {
			  NSMutableArray *errorMessages = [[NSMutableArray alloc] init];
			  NSString *string = nil;

			  [errorMessages addObject:error.localizedDescription];

			  if ( ( string = error.userInfo[@"NSErrorFailingURLKey"] ) )
				  [errorMessages addObject:string];

			  self.validatorConnectionErrorText = [errorMessages componentsJoinedByString:@"\n"];
			  self.validatorConnectionError = YES;
			  self.messages = nil;
		  }

		  self.inProgress = NO;
		  self.didRequestUpdate = NO;

		  if (self.delegate && [self.delegate respondsToSelector:@selector(validationComplete:)])
		  {
			  [[self delegate] validationComplete:self];
		  }

	  }] resume];
}


#pragma mark - Instance Methods (Private)


/*———————————————————————————————————————————————————————————————————*
 * Setup a reload throttle timer so that we don't spam the web
 * service providing validation.
 *———————————————————————————————————————————————————————————————————*/
- (void)activateThrottleTimer
{
	self.throttleTimer = nil;
	if ( self.autoUpdate )
	{
		[NSTimer scheduledTimerWithTimeInterval:self.throttleTime target:self selector:@selector(hitThrottleTimer) userInfo:nil repeats:YES];
	}
}

- (void)hitThrottleTimer
{
	if ( self.didRequestUpdate && !self.inProgress && !self.validatorConnectionError )
	{
		[self performValidation];
	}
}


#pragma mark - KVO


/* Simplify observeValueForKeyPath:… using a context. */
static void *dataBindingContext = (void *)@"data";

/*———————————————————————————————————————————————————————————————————*
 * bind:toObject:withKeyPath:options
 *   We override this so that when data is bound, we can detect when
 *   the underlying data is actually changed. Reaction to this is in
 *   observeValueForKeyPath:ofObject:change:context
 *———————————————————————————————————————————————————————————————————*/
- (void)bind:(NSString *)binding
	toObject:(id)observableObject
 withKeyPath:(NSString *)keyPath
	 options:(NSDictionary *)options
{
	if ([binding isEqualToString:@"data"])
	{
		[observableObject addObserver:self
						   forKeyPath:keyPath
							  options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
							  context:dataBindingContext];

		_data = [observableObject valueForKey:keyPath];
	}
	else
	{
		[super bind:binding toObject:observableObject withKeyPath:keyPath options:options];
	}
}


/*———————————————————————————————————————————————————————————————————*
 * observeValueForKeyPath:ofObject:change:context
 *   If the data property was set via bindings, then let's make sure
 *   that we stay apprised of changes to it.
 *———————————————————————————————————————————————————————————————————*/
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	if ( context == dataBindingContext )
	{
		_data = [object valueForKey:keyPath];
		self.didRequestUpdate = YES;
	}
}


@end
