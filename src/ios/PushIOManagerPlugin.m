/**
* Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
* Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

#import <Cordova/CDV.h>
#import <PushIOManager/PushIOManagerAll.h>
#import "NSArray+PIOConvert.h"
#import "NSDictionary+PIOConvert.h"
@interface PushIOManagerPlugin: CDVPlugin<PIODeepLinkDelegate> {
}
@property (nonatomic, strong) NSString* interceptCallbackId;
@end

@implementation PushIOManagerPlugin

- (void)registerUserId:(CDVInvokedUrlCommand*)command {
    NSString* userId = [command.arguments objectAtIndex:0];
    if (userId == (id)[NSNull null]) {
        userId = nil;
    }
    NSLog(@"setting user id %@", userId);
    [[PushIOManager sharedInstance] registerUserID:userId];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

- (void)setLogLevel:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    NSInteger logLevel = [value integerValue];
    [[PushIOManager sharedInstance] setLogLevel:logLevel];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

- (void)registerApp:(CDVInvokedUrlCommand*)command {
    NSError *error = nil;
    [[PushIOManager sharedInstance] registerApp:&error completionHandler:^(NSError *error, NSString *response) {
        [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
    }];
}

- (void)registerForAllRemoteNotificationTypes:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] registerForAllRemoteNotificationTypes:^(NSError *error, NSString *response) {
        [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
    }];
}

- (void)registerForAllRemoteNotificationTypesWithCategories:(CDVInvokedUrlCommand*)command {
    NSArray *categories = [command.arguments objectAtIndex:0];
    if (categories == (id)[NSNull null]) {
        categories = nil;
    }
    [[PushIOManager sharedInstance] registerForAllRemoteNotificationTypesWithCategories:[categories notificationCategoryArray] completionHandler:^(NSError *error, NSString *response) {
        [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
        
    }];
}


- (void)registerForNotificationAuthorizations:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }

    NSInteger authOptions = [value integerValue];
    NSArray *categories = [command.arguments objectAtIndex:1];
    if (categories == (id)[NSNull null]) {
        categories = nil;
    }

    [[PushIOManager sharedInstance] registerForNotificationAuthorizations:authOptions categories:[categories notificationCategoryArray] completionHandler:^(NSError *error, NSString *response) {
        [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
    }];
}


- (void)configure:(CDVInvokedUrlCommand*)command {
    NSString* filename = [command.arguments objectAtIndex:0];
    if (filename == (id)[NSNull null]) {
        filename = nil;
    }

    NSLog(@"configureWithFilename %@", filename);
    [[PushIOManager sharedInstance] configureWithFileName:filename completionHandler:^(NSError *error, NSString *response) {
        [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
    }];
}


- (void)configureAndRegister:(CDVInvokedUrlCommand*)command {
    NSString* filename = [command.arguments objectAtIndex:0];
    if (filename == (id)[NSNull null]) {
        filename = nil;
    }

    NSLog(@"configureWithFilename %@", filename);
    [[PushIOManager sharedInstance] configureWithFileName:filename completionHandler:^(NSError *configError, NSString *response) {
        if(configError != nil) {
            NSLog(@"Unable to configure SDK, reason: %@", configError.description);
            [self sendPluginResultToCallback:command.callbackId withResponse:response andError:configError.description];

            return;
        }
                
        //5. Register with APNS and request for push permissions
        [[PushIOManager sharedInstance] registerForAllRemoteNotificationTypes:^(NSError *error, NSString *deviceToken) {
            if (nil == error) {

                //Configure other SDK APIs here, if needed eg: [[PushIOManager sharedInstance] registerUserID:@"A1B2C3D4"];
                
                //6. Register application with Responsys server. This API is responsible to send registration signal to Responsys server. This API sends all the values configured on SDK to server.
                NSError *regTrackError = nil;
                [[PushIOManager sharedInstance] registerApp:&regTrackError completionHandler:^(NSError *regAppError, NSString *response) {
                    if (nil == regAppError) {
                        NSLog(@"Application registered successfully!");
                    } else {
                        NSLog(@"Unable to register application, reason: %@", regAppError.description);
                    }
                    [self sendPluginResultToCallback:response withResponse:deviceToken andError:regAppError.description];
                }];
                if (nil == regTrackError) {
                    NSLog(@"Registration locally stored successfully.");
                } else {
                    NSLog(@"Unable to store registration, reason: %@", regTrackError.description);
                }
            } else {
                [self sendPluginResultToCallback:command.callbackId withResponse:deviceToken andError:error.description];

            }
        }];
    }];
}

-(void)unregisterApp:(CDVInvokedUrlCommand*)command {

  [[PushIOManager sharedInstance] unregisterApp:nil completionHandler:^(NSError *error, NSString *response) {
    NSLog(@"React unregisterApp %@",(response ?: @"success"));
    [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
  }];
}

-(void)trackEngagement:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
  int metric = [value intValue];
  NSDictionary *properties = [command.arguments objectAtIndex:1];
    if (properties == (id)[NSNull null]) {
        properties = nil;
    }

  [[PushIOManager sharedInstance] trackEngagementMetric:(int)metric withProperties:properties completionHandler:^(NSError *error, NSString *response) {
    NSLog(@"React trackEngagementMetric %@",(response ?: @"success"));
    [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
  }];
}

-(void)resetEngagementContext:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] resetEngagementContext];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}



-(void)setMessageCenterEnabled:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    BOOL isMessageCenterEnable = [value boolValue];
    [[PushIOManager sharedInstance] setMessageCenterEnabled:isMessageCenterEnable];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)isMessageCenterEnabled:(CDVInvokedUrlCommand*)command {
    BOOL isMessageCenterEnable = [[PushIOManager sharedInstance] isMessageCenterEnabled];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isMessageCenterEnable] callbackId:command.callbackId];
}

-(void)fetchMessagesForMessageCenter:(CDVInvokedUrlCommand*)command {
    NSString* messageCenter = [command.arguments objectAtIndex:0];
    if (messageCenter == (id)[NSNull null]) {
        messageCenter = nil;
    }

    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    responseDictionary[@"messageCenter"] = messageCenter;

    [[PushIOManager sharedInstance] fetchMessagesForMessageCenter:messageCenter CompletionHandler:^(NSError *error, NSArray *messages) {
        responseDictionary[@"messages"] = [messages messageDictionary];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:responseDictionary] callbackId:command.callbackId];
    }];
}


-(void)fetchRichContentForMessage:(CDVInvokedUrlCommand*)command {
    NSString* messageID = [command.arguments objectAtIndex:0];
    if (messageID == (id)[NSNull null]) {
        messageID = nil;
    }

  [[PushIOManager sharedInstance] fetchRichContentForMessage:messageID CompletionHandler:^(NSError *error, NSString *messageID, NSString *richContent) {
      NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
      responseDictionary[@"richContent"] = richContent;
      responseDictionary[@"messageID"] = messageID;
      [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:responseDictionary] callbackId:command.callbackId];
  }];
}

-(void)setInAppFetchEnabled:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    BOOL enableInAppMessageFetch = [value boolValue];
    [[PushIOManager sharedInstance] setInAppMessageFetchEnabled:enableInAppMessageFetch];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)getAPIKey:(CDVInvokedUrlCommand*)command {
    NSString *apiKey = [[PushIOManager sharedInstance] getAPIKey];
    [self sendPluginResultToCallback:command.callbackId withResponse:apiKey andError:nil];
}

-(void)getAccountToken:(CDVInvokedUrlCommand*)command {
    NSString *accountToken = [[PushIOManager sharedInstance] getAccountToken];
    [self sendPluginResultToCallback:command.callbackId withResponse:accountToken andError:nil];
}

-(void)getDeviceID:(CDVInvokedUrlCommand*)command {
    NSString *deviceID = [[PushIOManager sharedInstance] getDeviceID];
    [self sendPluginResultToCallback:command.callbackId withResponse:deviceID andError:nil];
}


-(void)getEngagementMaxAge:(CDVInvokedUrlCommand*)command {
  double engagementAge = [[PushIOManager sharedInstance] getEngagementMaxAge];
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:engagementAge] callbackId:command.callbackId];
}

-(void)getEngagementTimeStamp:(CDVInvokedUrlCommand*)command {
  NSString *engagementTimeStamp = [[PushIOManager sharedInstance] getEngagementTimeStamp];
  [self sendPluginResultToCallback:command.callbackId withResponse:engagementTimeStamp andError:nil];
}


-(void)getPreferences:(CDVInvokedUrlCommand*)command {
    NSArray *preference = [[[PushIOManager sharedInstance] getPreferences] preferencesDictionary];
    [self sendPluginResultToCallback:command.callbackId withResponse:[preference JSON] andError:nil];
}

-(void)getPreference:(CDVInvokedUrlCommand*)command {
    NSString* key = [command.arguments objectAtIndex:0];
    if (key == (id)[NSNull null]) {
        key = nil;
    }

    PIOPreference *preference = [[PushIOManager sharedInstance] getPreference:key];
    NSString *prefrenceJSON = [[NSDictionary dictionaryFromPreference:preference] JSON];
    [self sendPluginResultToCallback:command.callbackId withResponse:prefrenceJSON andError:nil];
}


-(void)trackEvent:(CDVInvokedUrlCommand*)command {
    NSString* eventName = [command.arguments objectAtIndex:0];
    NSDictionary *properties = [command.arguments objectAtIndex:1];
    if (eventName == (id)[NSNull null]) {
        [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:@"Eventname can not be null"];
        return;
    }

    if (properties == (id)[NSNull null]) {
        properties = nil;
    }
    [[PushIOManager sharedInstance] trackEvent:eventName properties:properties];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)declarePreference:(CDVInvokedUrlCommand*)command {
    NSString* key = [command.arguments objectAtIndex:0];
    NSString *label = [command.arguments objectAtIndex:1];
    if (key == (id)[NSNull null]) {
        key = nil;
    }
    if (label == (id)[NSNull null]) {
        label = nil;
    }
    id value = [command.arguments objectAtIndex:2];
    if (value == (id)[NSNull null]) {
        value = nil;
    }

    int type = [value intValue];
    NSError *error = nil;
    [[PushIOManager sharedInstance] declarePreference:key label:label type:type error:&error];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:error.description];
}

-(void)setBooleanPreference:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:1];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    NSString *key = [command.arguments objectAtIndex:0];
    if (key == (id)[NSNull null]) {
        key = nil;
    }


  [[PushIOManager sharedInstance] setBoolPreference:[value boolValue] forKey:key];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)setStringPreference:(CDVInvokedUrlCommand*)command {
    NSString *value = [command.arguments objectAtIndex:1];
    NSString *key = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    if (key == (id)[NSNull null]) {
        key = nil;
    }

  [[PushIOManager sharedInstance] setStringPreference:value forKey:key];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)setNumberPreference:(CDVInvokedUrlCommand*)command {
    NSNumber *value = [command.arguments objectAtIndex:1];
    NSString *key = [command.arguments objectAtIndex:0];
    if (key == (id)[NSNull null]) {
        key = nil;
    }
    
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    [[PushIOManager sharedInstance] setNumberPreference:value forKey:key];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];

}

-(void)removePreference:(CDVInvokedUrlCommand*)command {
    NSString *key = [command.arguments objectAtIndex:0];
    if (key == (id)[NSNull null]) {
        key = nil;
    }
    NSError *error = nil;
    [[PushIOManager sharedInstance] removePreference:key error:&error];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:error.description];
}

-(void)clearAllPreferences:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] clearAllPreferences];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];

}

-(void)setBadgeCount:(CDVInvokedUrlCommand*)command {
    NSNumber* badgeCount = [command.arguments objectAtIndex:0];
    if (badgeCount == (id)[NSNull null]) {
        [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:@"Badge Count can't be empty"];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[PushIOManager sharedInstance] setBadgeCount:[badgeCount integerValue] completionHandler:^(NSError *error, NSString *response) {
          [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
        }];
    });
}

-(void)resetBadgeCount:(CDVInvokedUrlCommand*)command {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PushIOManager sharedInstance] resetBadgeCountWithCompletionHandler:^(NSError *error, NSString *response) {
            [self sendPluginResultToCallback:command.callbackId withResponse:response andError:error.description];
        }];
    });
}

-(void)getBadgeCount:(CDVInvokedUrlCommand*)command {
  dispatch_async(dispatch_get_main_queue(), ^{
      NSInteger badgeCount = [[PushIOManager sharedInstance] getBadgeCount];
      [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsNSInteger:badgeCount] callbackId:command.callbackId];
  });
}


-(void)clearInAppMessages:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] clearInAppMessages];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)resetMessageCenter:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] clearMessageCenterMessages];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)trackMessageCenterOpenEngagement:(CDVInvokedUrlCommand*)command {
    NSString *messageId = [command.arguments objectAtIndex:0];
    if (messageId == (id)[NSNull null]) {
        messageId = nil;
    }

  [[PushIOManager sharedInstance] trackMessageCenterOpenEngagement:messageId];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)trackMessageCenterDisplayEngagement:(CDVInvokedUrlCommand*)command {
    NSString *messageId = [command.arguments objectAtIndex:0];
    if (messageId == (id)[NSNull null]) {
        messageId = nil;
    }

  [[PushIOManager sharedInstance] trackMessageCenterDisplayEngagement:messageId];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];

}

-(void)onMessageCenterViewVisible:(CDVInvokedUrlCommand*)command {
  [[PushIOManager sharedInstance] messageCenterViewWillAppear];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];

}

-(void)onMessageCenterViewFinish:(CDVInvokedUrlCommand*)command {
  [[PushIOManager sharedInstance] messageCenterViewWillDisappear];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)clearInteractiveNotificationCategories:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)deleteInteractiveNotificationCategory:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}
-(void)getInteractiveNotificationCategory:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}
-(void)addInteractiveNotificationCategory:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}
-(void)isSDKConfigured:(CDVInvokedUrlCommand*)command {
    BOOL isSDKConfigured = [[PushIOManager sharedInstance] isSDKConfigured];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isSDKConfigured] callbackId:command.callbackId];
}

-(void)setCrashLoggingEnabled:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    BOOL enableCrashLogging = [value boolValue];
    [[PushIOManager sharedInstance] setCrashLoggingEnabled:enableCrashLogging];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)isCrashLoggingEnabled:(CDVInvokedUrlCommand*)command {
    BOOL isCrashLoggingEnabled = [[PushIOManager sharedInstance] isCrashLoggingEnabled];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isCrashLoggingEnabled] callbackId:command.callbackId];
}

-(void)setLoggingEnabled:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    BOOL enable = [value boolValue];
    [[PushIOManager sharedInstance] setLoggingEnabled:enable];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)isLoggingEnabled:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    BOOL enable = [value boolValue];
    [[PushIOManager sharedInstance] setLoggingEnabled:enable];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)getRegisteredUserId:(CDVInvokedUrlCommand*)command {
    NSString *userId = [[PushIOManager sharedInstance] getUserID];
    [self sendPluginResultToCallback:command.callbackId withResponse:userId andError:nil];
}

-(void)unregisterUserId:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] registerUserID:nil];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)frameworkVersion:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:[[PushIOManager sharedInstance] frameworkVersion] andError:nil];
}

-(void)setExternalDeviceTrackingID:(CDVInvokedUrlCommand*)command {
    NSString *externalDeviceTrackingID = [command.arguments objectAtIndex:0];
    if (externalDeviceTrackingID == (id)[NSNull null]) {
        externalDeviceTrackingID = nil;
    }
    [[PushIOManager sharedInstance] setExternalDeviceTrackingID:externalDeviceTrackingID];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)getExternalDeviceTrackingID:(CDVInvokedUrlCommand*)command {
    NSString *externalDeviceTrackingID = [[PushIOManager sharedInstance] externalDeviceTrackingID];
    [self sendPluginResultToCallback:command.callbackId withResponse:externalDeviceTrackingID andError:nil];
}


-(void)setAdvertisingID:(CDVInvokedUrlCommand*)command {
    NSString *advertisingIdentifier = [command.arguments objectAtIndex:0];
    if (advertisingIdentifier == (id)[NSNull null]) {
        advertisingIdentifier = nil;
    }
    [[PushIOManager sharedInstance] setAdvertisingIdentifier:advertisingIdentifier];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)getAdvertisingID:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:[[PushIOManager sharedInstance] advertisingIdentifier] andError:nil];
}


-(void)setExecuteRsysWebUrl:(CDVInvokedUrlCommand*)command {
    NSString *executeRsysWebURL = [command.arguments objectAtIndex:0];
    if (executeRsysWebURL == (id)[NSNull null]) {
        executeRsysWebURL = nil;
    }

    [[PushIOManager sharedInstance] setExecuteRsysWebURL:executeRsysWebURL];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)getExecuteRsysWebUrl:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[[PushIOManager sharedInstance] executeRsysWebURL]] callbackId:command.callbackId];
}

-(void)setConfigType:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    int configType = [value intValue];
    [[PushIOManager sharedInstance] setConfigType:configType];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)configType:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:((int)[[PushIOManager sharedInstance] configType])] callbackId:command.callbackId];
}

-(void)resetAllData:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] resetAllData];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)isResponsysPush:(CDVInvokedUrlCommand*)command {
    NSDictionary *message = [command.arguments objectAtIndex:0];
    if (message == (id)[NSNull null]) {
        message = nil;
    }

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[[PushIOManager sharedInstance] isResponsysPayload:message]] callbackId:command.callbackId];
}

-(void)onGeoRegionEntered:(CDVInvokedUrlCommand*)command {
    NSDictionary *region = [command.arguments objectAtIndex:0];
    if (region == (id)[NSNull null]) {
        region = nil;
    }

    PIOGeoRegion *geoRegion = [region geoRegion];
    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    responseDictionary[@"regionType"] = @"GEOFENCE_ENTRY";
    responseDictionary[@"regionID"] = geoRegion.geofenceId;

    [[PushIOManager sharedInstance] didEnterGeoRegion:[region geoRegion] completionHandler:^(NSError *error, NSString *response) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:responseDictionary] callbackId:command.callbackId];
    }];
}


-(void)onGeoRegionExited:(CDVInvokedUrlCommand*)command {
    NSDictionary *region = [command.arguments objectAtIndex:0];
    if (region == (id)[NSNull null]) {
        region = nil;
    }

    PIOGeoRegion *geoRegion = [region geoRegion];
    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    responseDictionary[@"regionType"] = @"GEOFENCE_EXIT";
    responseDictionary[@"regionID"] = geoRegion.geofenceId;

    [[PushIOManager sharedInstance] didExitGeoRegion:[region geoRegion] completionHandler:^(NSError *error, NSString *response) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:responseDictionary] callbackId:command.callbackId];
    }];
}


-(void)onBeaconRegionEntered:(CDVInvokedUrlCommand*)command {
    NSDictionary *region = [command.arguments objectAtIndex:0];
    if (region == (id)[NSNull null]) {
        region = nil;
    }

    PIOBeaconRegion *beaconRegion = [region beaconRegion];
    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    responseDictionary[@"regionType"] = @"BEACON_ENTRY";
    responseDictionary[@"regionID"] = beaconRegion.beaconId;

    [[PushIOManager sharedInstance] didEnterBeaconRegion:[region beaconRegion] completionHandler:^(NSError *error, NSString *response) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:responseDictionary] callbackId:command.callbackId];
    }];
}
-(void)onBeaconRegionExited:(CDVInvokedUrlCommand*)command {
    NSDictionary *region = [command.arguments objectAtIndex:0];
    if (region == (id)[NSNull null]) {
        region = nil;
    }

    PIOBeaconRegion *beaconRegion = [region beaconRegion];
    NSMutableDictionary *responseDictionary = [NSMutableDictionary dictionary];
    responseDictionary[@"regionType"] = @"BEACON_EXIT";
    responseDictionary[@"regionID"] = beaconRegion.beaconId;

    
    [[PushIOManager sharedInstance] didExitBeaconRegion:[region beaconRegion] completionHandler:^(NSError *error, NSString *response) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:responseDictionary] callbackId:command.callbackId];
    }];
}

-(void)handleMessage:(CDVInvokedUrlCommand*)command {
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}


-(void)getLibVersion:(CDVInvokedUrlCommand*)command {
    NSString *frameworkVersion = [[PushIOManager sharedInstance] frameworkVersion];
    [self sendPluginResultToCallback:command.callbackId withResponse:frameworkVersion andError:nil];
}


- (void)sendPluginResultToCallback:(NSString *)callbackId withResponse:(NSString *)response andError:(NSString *)error  {
    if (error) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error] callbackId:callbackId];
    } else if (response) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:response] callbackId:callbackId];
    } else {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:callbackId];
    }
}

-(void)onDeepLinkReceived:(NSNotification *)notification {
    
    NSMutableDictionary *resolvedURLInfo = [NSMutableDictionary new];
    
    resolvedURLInfo[@"deeplinkURL"] = notification.userInfo[PIOResolvedDeeplinkURL];
    resolvedURLInfo[@"weblinkURL"] = notification.userInfo[PIOResolvedWeblinkURL];
    resolvedURLInfo[@"requestURL"] = notification.userInfo[PIORequestedWebURL];
    resolvedURLInfo[@"isPubwebURLType"] = notification.userInfo[PIORequestedWebURLIsPubWebType];
    NSError *error = notification.userInfo[PIOErrorResolveWebURL];
    resolvedURLInfo[@"error"] = error.description;
    
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resolvedURLInfo options:0 error:&err];
    
    if(err == nil) {
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString *js = [NSString stringWithFormat:@"cordova.fireDocumentEvent('onDeepLinkReceived', %@);", json];
        [self.commandDelegate evalJs:js];
    }
}


-(void)pluginInitialize {
    [super pluginInitialize];
    [PushIOManager sharedInstance].notificationPresentationOptions = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeepLinkReceived:) name:PIORsysWebURLResolvedNotification object:nil];
}

- (void)setInterceptOpenURL:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    
    if (value) {
        self.interceptCallbackId = command.callbackId;
        [[PushIOManager sharedInstance] setDeeplinkDelegate:self];

    } else {
        self.interceptCallbackId = nil;
        [[PushIOManager sharedInstance] setDeeplinkDelegate:nil];

    }

}

- (BOOL)handleOpenURL:(NSURL *)url {
    if (url == nil || self.interceptCallbackId) {
        return NO;
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[url absoluteString]];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.interceptCallbackId];
    
    return YES; //It's intercepted everytime.
}

-(void)setDelayRichPushDisplay:(CDVInvokedUrlCommand*)command {
    id value = [command.arguments objectAtIndex:0];
    if (value == (id)[NSNull null]) {
        value = nil;
    }
    [[PushIOManager sharedInstance] setDelayRichPushDisplay:value];
}

-(void)showRichPushMessage:(CDVInvokedUrlCommand*)command {
    [[PushIOManager sharedInstance] showRichPushMessage];
    [self sendPluginResultToCallback:command.callbackId withResponse:nil andError:nil];
}

-(void)isRichPushDelaySet:(CDVInvokedUrlCommand*)command {
    BOOL isRichPushDelaySet = [[PushIOManager sharedInstance] isRichPushDelaySet];
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isRichPushDelaySet] callbackId:command.callbackId];
}


@end
