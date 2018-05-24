/**************************************************************************************************

	JSDNuVServer

	Copyright © 2018 by Jim Derry. All rights reserved.

 **************************************************************************************************/

#import <Foundation/Foundation.h>

/* Operate a local instance of the W3C NuV server. */
@interface JSDNuVServer : NSObject


/** Type of the server's current status. */
typedef NS_OPTIONS(NSUInteger, JSDNuVServerStatus) {
	JSDNuVServerStopped = 0,
	JSDNuVServerExternalStop,
	JSDNuVServerPortUnavailable,
	JSDNuVServerStarting,
	JSDNuVServerRunning
};


/** Singleton accessor for this class. */
+ (instancetype)sharedNuVServer;


/**
 *  Returns the version number of the built-in server.
 */
+ (NSString *)serverVersion;


/**
 *  The local port to use for the server. If the server is already running on a different port,
 *  then it will be restarted on the newly assigned port, if the port is available. Specifying
 *  an unavailable port while the server is running will stop the server.
 */
@property (atomic, copy, readwrite) NSString *port;


/**
 *  The status of the server.
 */
@property (atomic, assign, readonly) JSDNuVServerStatus serverStatus;


/**
 *  A reference to the server task.
 */
@property (atomic, strong, readonly) NSTask *serverTask;


/**
 *  Starts the server. If the intention is to restart the server, use serverStop first.
 */
- (JSDNuVServerStatus)serverLaunch;

/**
 *  Stops the server.
 */
- (void)serverStop;


@end
