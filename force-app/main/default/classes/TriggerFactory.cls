/* TriggerFactory.cls   *************************************************************************************************************************
* Used to instantiate and execute Trigger Handler classes associated with sObjects
* See TriggerInterface class for more detailed comments
*
* @originalAuthor	Tony Scott		https://meltedwires.com/2013/06/05/trigger-pattern-for-tidy-streamlined-bulkified-triggers-revisited/
* @implementedBy	Sam Howle
****************************************************************************************************************************************************/
public without sharing class TriggerFactory {

	/** Public static method to create and execute a trigger handler
	 *
	 * Arguments:	Type t - Type of handler to instatiate
	 *
	 * Throws a TriggerException if no handler has been found.
	 */
	public static void createAndExecuteHandler(Type t, Schema.SObjectType objectType) {
		// Handler class to instatiate for the object being processed
		TriggerInterface handler = getHandler(t);

		// Make sure we have a handler registered, new handlers must be registered in the getHandler method.
		if (handler == null) {
			throw new TriggerException('No Trigger Handler found named: ' + t.getName());
		}
		String objectName = objectType.getDescribe().getName();
		//if (!String.isBlank(objectName) && isActive(objectName)) {
		if (!String.isBlank(objectName)) {
			// Execute the handler to fulfill the trigger
			execute(handler, objectName);
		}
	}

	/**
	 * private static method to control the execution of the handler
	 *
	 * Arguments:	TriggerInterface handler - A Trigger Handler class to execute
	 */
	private static void execute(TriggerInterface handler, String objectName) {
		// Before Trigger
		if (Trigger.isBefore) {

			// Call the bulk before to handle any caching of data and enable bulkification
			handler.bulkBefore();

			// Iterate through the records to be deleted passing them to the handler.
			if (Trigger.isDelete) {
				for (SObject oldSo : Trigger.old) {
					handler.beforeDelete(oldSo);
				}
			}
			// Iterate through the records to be inserted passing them to the handler.
			else if (Trigger.isInsert) {
				for (SObject so : Trigger.new) {
					handler.beforeInsert(so);
				}
			}
			// Iterate through the records to be updated passing them to the handler.
			else if (Trigger.isUpdate) {
				for (SObject oldSo : Trigger.old) {
					handler.beforeUpdate(oldSo, Trigger.newMap.get(oldSo.Id));
				}
			}
		}
		else if (Trigger.isAfter) {
			// Call the bulk after to handle any caching of data to enable bulkification
			handler.bulkAfter();

			// Iterate through the records deleted passing them to the handler.
			if (Trigger.isDelete) {
				for (SObject oldSo : Trigger.old) {
					handler.afterDelete(oldSo);
				}
			}
			// Iterate through the records inserted passing them to the handler.
			else if (Trigger.isInsert) {
				for (SObject so : Trigger.new) {
					handler.afterInsert(so);
				}
			}
			// Iterate through the records updated passing them to the handler.
			else if (Trigger.isUpdate) {
				for (SObject oldSo : Trigger.old) {
					handler.afterUpdate(oldSo, Trigger.newMap.get(oldSo.Id));
				}
			}
			// Iterate through the records being undeleted (removed from recycle bin)
			else if (Trigger.isUndelete) {
				for (SObject so : Trigger.new) {
					handler.afterUndelete(so);
				}
			}
		}
		// Perform any post processing; Once following Before Trigger, once following After Trigger
		handler.andFinally();
	}

	/**
	 * Get the named Handler class based on the Apex Type passed from the Trigger
	 *
	 * Arguments:	Apex Type:			Apex Class to use as Trigger Handler
	 * Returns:		TriggerInterface:	Trigger handler cast to custom interface
	 */
	private static TriggerInterface getHandler(Type handlerType) {
		// Instantiate the type
		Object handlerObj = handlerType.newInstance();

		// if its not an instance of TriggerInterface return null
		if (!(handlerObj instanceOf TriggerInterface)) {
			return null;
		} else {
			return (TriggerInterface)handlerObj;
		}
	}

	/** Check if the Trigger should be active based on custom metadata
	 *
	 * Arguments:	Object Name
	 * Returns:		Boolean
	 */
	// static Boolean isActive(String objectName) {
	// 	Map<String,Circuit_Breaker__mdt> breakerMap = new Map<String,Circuit_Breaker__mdt>();
	// 	Map<String,Circuit_Breaker__mdt> userOrProfileMap = new Map<String,Circuit_Breaker__mdt>();

	// 	for (Circuit_Breaker__mdt cb: [SELECT id,Object_API_Name__c,Apex_Trigger__c,Master_Switch__c,Type__c,User_Profile_Id__c FROM Circuit_Breaker__mdt]) {
	// 		if (cb.Type__c == 'Global') {
	// 			breakerMap.put(cb.Object_API_Name__c,cb);
	// 		} else {
	// 			userOrProfileMap.put(cb.Object_API_Name__c,cb);
	// 		}
	// 	}

	// 	String currentUserId = UserInfo.getUserId();
	// 	String currentUserProfileId = UserInfo.getProfileId();

	// 	if (!userOrProfileMap.isEmpty()) {
	// 		if (userOrProfileMap.containsKey(currentUserId)) {
	// 			return userOrProfileMap.get(currentUserId).Master_Switch__c ? userOrProfileMap.get(currentUserId).Apex_Trigger__c:false;
	// 		}
	// 		else if (userOrProfileMap.containsKey(currentUserProfileId)) {
	// 			return userOrProfileMap.get(currentUserProfileId).Master_Switch__c ? userOrProfileMap.get(currentUserProfileId).Apex_Trigger__c:false;
	// 		}
	// 	}
	// 	return breakerMap.get('All').Master_Switch__c ? (breakerMap.get(objectName).Master_Switch__c ? (breakerMap.get(objectName).Apex_Trigger__c) : false) : false;
	// }

	public class TriggerException extends Exception {}
}