/**************************************************************************************************

	JSDNuVServer

	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import "JSDNuVServer.h"
#import "xcode-version.h"


@interface JSDNuVServer ()

/** Redefine for readwrite. */
@property (atomic, strong, readwrite) NSTask *serverTask;

/** Tracks when server has startedup or not. */
@property (atomic, assign, readwrite) JSDNuVServerStatus internalStatus;

/** We want to ensure the NSTask is restarted properly. */
@property (atomic, strong, readwrite) dispatch_queue_t serial_queue;

/** And we need a watchdog in case the application crashes. */
@property (atomic, strong, readwrite) NSTask *watchdog;

@end


@implementation JSDNuVServer

@synthesize port = _port;


#pragma mark - Singleton


/*–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*
  + sharedNuVServer
    Implement this class as a singleton.
 *–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––*/
+ (instancetype)sharedNuVServer
{
    static JSDNuVServer *sharedServer = nil;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{ sharedServer = [[self alloc] init]; });

    return sharedServer;
}


#pragma mark - Initialization


/*———————————————————————————————————————————————————————————————————*
 * - init
 *———————————————————————————————————————————————————————————————————*/
- (instancetype)init
{
	if ( (self = [super init]) )
	{
		self.serial_queue = dispatch_queue_create("com.balthisar.ser_q", DISPATCH_QUEUE_SERIAL);
	}

	return self;
}


/*———————————————————————————————————————————————————————————————————*
 * - dealloc
 *———————————————————————————————————————————————————————————————————*/
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Properties


/*———————————————————————————————————————————————————————————————————*
 * + serverVersion
 *———————————————————————————————————————————————————————————————————*/
+ (NSString *)serverVersion
{
	return JAR_VERSION;
}


/*———————————————————————————————————————————————————————————————————*
 * + JREVersion
 *———————————————————————————————————————————————————————————————————*/
+ (NSString *)JREVersion
{
	return JRE_VERSION;
}


/*———————————————————————————————————————————————————————————————————*
 * @property port
 *———————————————————————————————————————————————————————————————————*/
- (NSString *)port
{
	return _port;
}
- (void)setPort:(NSString *)port
{
	if ( [port isEqualToString:_port] ) return;

	_port = [port copy];

	if ( !self.serverTask.running) return;

	/* We've accepted the port change. If the server is running, we will
	   attempt to restart the server, but this may fail if the newly
	   assigned port is already in use. */
	dispatch_async(self.serial_queue, ^{
		[self.serverTask terminate];
		[self.serverTask waitUntilExit];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self serverLaunch];
		});
	});
}


/*———————————————————————————————————————————————————————————————————*
 * @property serverStatus
 *   This is a composite property reflecting the status of the
 *   server.
 *———————————————————————————————————————————————————————————————————*/
+ (NSSet *)keyPathsForValuesAffectingServerStatus
{
	return [NSSet setWithArray:@[
								 @"port",
								 @"serverTask",
								 @"serverTask.running",
								 @"internalStatus"
								 ]];
}
- (JSDNuVServerStatus)serverStatus
{
	/* If there's no server running, then report either:
	   - JSDNuVServerStopped
	   - JSDNuVServerPortUnavailable
	 */
	if ( !self.serverTask || !self.serverTask.running )
	{
		NSSocketPort *check = [[NSSocketPort alloc] initWithTCPPort:[self.port intValue]];
		BOOL available = check != nil;
		[check invalidate];
		check = nil;

		if ( available )
		{
			return JSDNuVServerStopped;
		}
		else
		{
			return JSDNuVServerPortUnavailable;
		}
	}

	return self.internalStatus;
}


#pragma mark - Private Methods


/*———————————————————————————————————————————————————————————————————*
 * - serverLaunch
 *———————————————————————————————————————————————————————————————————*/
- (JSDNuVServerStatus)serverLaunch
{
	if ( self.serverTask.running || self.serverStatus == JSDNuVServerPortUnavailable)
	{
		return self.serverStatus;
	}

	[self configureTask];
	[self.serverTask launch];
	self.internalStatus = JSDNuVServerStarting;

	/* Configure our watchdog. */
	self.watchdog = [[NSTask alloc] init];
	self.watchdog.launchPath = @"/bin/sh";

	NSString *command = [NSString stringWithFormat:@"while kill -0 %d; do sleep 5; done; kill -9 %d # NuV Watchdog",
						 [[NSProcessInfo processInfo] processIdentifier],
						 self.serverTask.processIdentifier];

	self.watchdog.arguments = @[ @"-c", command];
	[self.watchdog launch];

	return self.serverStatus;
}


/*———————————————————————————————————————————————————————————————————*
 * - serverStop
 *     This simply provides consistency in the API.
 *———————————————————————————————————————————————————————————————————*/
- (void)serverStop
{
	if (self.serverTask.running)
	{
		dispatch_async(self.serial_queue, ^{
			[self.serverTask terminate];
			[self.serverTask waitUntilExit];
		});
	}
}


#pragma mark - Private Methods


/*———————————————————————————————————————————————————————————————————*
 * - configureTask
 *———————————————————————————————————————————————————————————————————*/
- (void)configureTask
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

/*
  The Java executable has a CFBundleIdentifier that Apple doesn't like to have
  duplicated, so we've created two versions unique to Tidy:
  com.balthisar.java-a, and com.balthisar.java-b, so that they will be unique
  on the App Store.
 */
#if defined(TARGET_PRO)
	NSString *jre = [bundle pathForResource:@"javapro"
									 ofType:@""
								inDirectory:@"PlugIns/Java.runtime/Contents/Home/bin"];
#else
	NSString *jre = [bundle pathForResource:@"java"
									 ofType:@""
								inDirectory:@"PlugIns/Java.runtime/Contents/Home/bin"];
#endif

	NSString *jar = [bundle pathForResource:@"vnu"
									 ofType:@"jar"
									inDirectory:@"Java"];


	self.serverTask = [[NSTask alloc] init];
	self.serverTask.launchPath = jre;
	self.serverTask.arguments = @[ @"-cp", jar, @"nu.validator.servlet.Main", self.port ];

	/* Capture output in order to scrape STDERR for startup status. */

	NSPipe *outPipe = [NSPipe pipe];
	NSFileHandle *outHandle = outPipe.fileHandleForReading;

	_serverTask.standardError = outPipe;

	[outHandle waitForDataInBackgroundAndNotify];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receivedData:)
												 name:NSFileHandleDataAvailableNotification
											   object:outHandle];

	/* Termination Block */

	__weak typeof(self) weakSelf = self;
	self.serverTask.terminationHandler = ^(NSTask *aTask)
	{
		__strong typeof(self) strongSelf = weakSelf;
		dispatch_async(dispatch_get_main_queue(), ^{

			[strongSelf.watchdog terminate];

			if ( strongSelf.serverTask.terminationStatus != NSTaskTerminationReasonExit)
			{
				strongSelf.internalStatus = JSDNuVServerExternalStop;
			}
			else
			{
				strongSelf.internalStatus = JSDNuVServerStopped;
			}
		});
	};
}


/*———————————————————————————————————————————————————————————————————*
 * - receivedData:
 *     Essentially, wait until we see that the server is completely
 *     running so that we can update the status.
 *———————————————————————————————————————————————————————————————————*/
- (void)receivedData:(NSNotification *)notification
{
	NSFileHandle *outHandle = [notification object];
	NSData *data = [outHandle availableData];
	if (data.length > 0)
	{
		[outHandle waitForDataInBackgroundAndNotify];
		NSString *have = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSString *want = @"Server:main: Started";
		if ( [have containsString:want] )
		{
			self.internalStatus = JSDNuVServerRunning;
		}
	}}

@end
