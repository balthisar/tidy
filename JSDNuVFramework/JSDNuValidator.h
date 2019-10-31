//
//  JSDNuValidator.h
//  JSDNuVFramework
//
//  Copyright © 2018-2019 by Jim Derry. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JSDNuVMessage;

/**
 *  Submits a given HTML/XML document for validation to the specified Nu HTML Checker service,
 *  and builds a data structure given the response. Although the validation URL is specified,
 *  we’re assuming a validator that uses the W3C Nu API.
 */
@interface JSDNuValidator : NSObject


#pragma mark - Properties


/** Delegate for instances of this class, per <JSDNuValidatorDelegate>.
 */
@property (nonatomic, readwrite, assign, nullable) id delegate;


/** The NSData to validate. When Setting this property or if the backed data changes
 *  and autoUpdate is enabled, the validator will be polled the next time the throttleTime
 *  expires.
 */
@property (nonatomic, readwrite, strong, nullable) NSData *data;


/** Indicates that the document is XML instead of HTML. When setting this property, the
 *  throttleTime will reset without polling the validator. This allows an opportunity
 *  to set multiple properties without abusing the server.
 */
@property (nonatomic, readwrite, assign) BOOL dataIsXML;


/** User-agent we will use when making API requests to the validator. When setting this
 *  property, the throttleTime will reset without polling the validator. This allows an
 *  opportunity to set multiple properties without abusing the server.
 */
@property (nonatomic, readwrite, strong, nullable) NSString *userAgent;


/** URL to use when making API requests to the validator. When setting this property, the
 *  throttleTime will reset without polling the validator. This allows an opportunity
 *  to set multiple properties without abusing the server.
 */
@property (nonatomic, readwrite, strong, nullable) NSURL *url;


/** The `url` property, presented as a string in order to simplify NSUserDefaults bindings.
 */
@property (nonatomic, readwrite, assign, nullable) NSString *urlString;


/** When set to a value other than 0.0f, performValidation will take place automatically.
 *  When setting this property, the throttleTime will reset without polling the validator.
 *  This allows an opportunity to set multiple properties without abusing the server.
 */
@property (nonatomic, readwrite, assign) float throttleTime;


/** When yes, the validator will be polled automatically according to the throttleTime value.
 *  When setting this property, the throttleTime will reset without polling the validator.
 *  This allows an opportunity to set multiple properties without abusing the server.
 */
@property (nonatomic, readwrite, assign) BOOL autoUpdate;


/** An array of JSDValidatorMessage indicating the validator response. */
@property (nonatomic, readonly, strong, nullable) NSArray<JSDNuVMessage*> *messages;


/** Indicates that an error occurred during the last connection attempt. If any validation
 *  attempt results in an error, further automatic updates will be prevented until a manual
 *  `performValidation` is successful.
 */
@property (nonatomic, readonly, assign) BOOL validatorConnectionError;

/** A localized error message, or nil. */
@property (nonatomic, readonly, strong, nullable) NSString *validatorConnectionErrorText;


/** An observable property that indicates that validation is in progress. */
@property (nonatomic, readonly, assign) BOOL inProgress;


#pragma mark - Instance Methods


/** Submits the validation request to the server and then awaits the response. Its use
 *  is not subject to the throttle time, however it will reset the throttleTime. When
 *  this message is received, inProgress will be set until a response is received or an
 *  error occurs. Repeated receipt of this message during inProgress will be ignored.
 */
- (void)performValidation;


@end
