/* Util.cls   **************************************************************************************************************************
* Description: Universal utility class available for all Apex code. Includes reusable methods to be called by Apex classes to generate
* to generate reusable and efficiently cached data. Currently includes methods to build RecordType maps, Profile Id/Name Map, and other
* widely used utility methods. Currently used by...
* ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
* @author			Sam Howle		--sam.howle@xandr.com
* @testClass		UtilTest
****************************************************************************************************************************************/

public without sharing class Util {

	// Record types cache
	private static Map<Schema.SObjectType, Map<String, String>> rtypesCache;

	// Profile & Role Maps
	private static Map<Id, Profile> profileDetails = new Map<Id, Profile>();
	private static Map<String, Id> profileIdMap = new Map<String, Id>();
	private static Map<String, String> userRoleMap = new Map<String, String>();

	// Cached map of SObjectField information by object; Improves performance if called multiple times
	private static Map<String, List<Schema.SObjectField>> sObjFieldMap;

	private static List<Organization> thisOrg = new List<Organization>();

	// ContentWorkspaces (File Library) -- Library Name to ContentWorkspaceId
	private static Map<String, String> fileLibraryMap = new Map<String, String>();
	private static List<Contact> placeHolderContact;
	public static Map<String, String> productMap = new Map<String, String>();

	static {
		placeHolderContact = new List<Contact>();
		rtypesCache = new Map<Schema.SObjectType, Map<String, String>>(); // cache record type maps for multiple calls
		sObjFieldMap = new Map<String, List<Schema.SObjectField>>();
		profileDetails 	   = new Map<Id, Profile>();
		profileIdMap 	   = new Map<String, Id>();
	}

	/* Returns a map of active RecordType IDs for a given SObjectType
	 * keyed by each RecordType's unique DeveloperName; Can be used across all objects
	 */
	public static Map<String, String> getRecordTypeMap(Schema.SObjectType token) {
		// Check if already have a result; If null, build Map. If true, return cached results
		Map<String, String> recordTypeMap = rtypesCache.get(token);
		if (recordTypeMap == null) {
			recordTypeMap = new Map<String, String>();
			rtypesCache.put(token, recordTypeMap);
		} else {
			return recordTypeMap;
		}

		// Get the Object's Describe Result; Loop through record type infos to build map for that object
		Schema.DescribeSObjectResult sObj = token.getDescribe();
		 for (Schema.RecordTypeInfo rtInfo : sObj.getRecordTypeInfosByDeveloperName().values()) {
			if (rtInfo.isActive()) {
				recordTypeMap.put(rtInfo.getDeveloperName(), rtInfo.getRecordTypeId());
				recordTypeMap.put(rtInfo.getRecordTypeId(), rtInfo.getDeveloperName());
			}
		}
		return recordTypeMap;
	}

	/* Get ContentWorkspace Id or Name values for a File Library; Caches results from initial query to re-use
	 * If the Library Name is provided the ContentWorkspaceId is returned; If Id is provided then the Library Name is returned
	 */
	public static String getLibraryIdOrName(String libraryNameOrId) {
		if (fileLibraryMap.isEmpty()) {
			for (ContentWorkspace cw : [SELECT Id, Name FROM ContentWorkspace]) {
				fileLibraryMap.put(cw.Name, cw.Id);
				fileLibraryMap.put(cw.Id, cw.Name);
			}
		}
		return fileLibraryMap.containsKey(libraryNameOrId) ? fileLibraryMap.get(libraryNameOrId) : '';
	}

	/*
	 * Gets the Id of the standard price book. If a test is running, it uses the Test method, otherwised SQOL us used.
	 */
	public static Id stdPriceBookId;
	public static Id getStdPriceBookId() {
		if (stdPriceBookId != null) {
			stdPriceBookId = stdPriceBookId;
		} else if (Test.isRunningTest()) {
			stdPriceBookId = Test.getStandardPricebookId();
		} else {
			stdPriceBookId = [SELECT Id FROM Pricebook2 WHERE isStandard = True AND IsActive = True].Id;
		}
		return stdPriceBookId;
	}

	// Returns Product2Id if given the Product2.Name, and returns Product2.Name if given the Product2Id
	public static String getProductNameOrId(String productIdOrName) {
		if (productMap.isEmpty()) {
			for (Product2 prd : [SELECT Id, Name FROM Product2 WHERE IsActive = true ORDER BY Name ASC]) {
				productMap.put(prd.Name, prd.Id);
				productMap.put(prd.Id, prd.Name);
			}
		}
		return productMap.containsKey(productIdOrName) ? productMap.get(productIdOrName) : '';
	}

	/* isChangedNotNull = Determines if a field changed to a non-null value during an update
	 * One constructors to check a single field, and another to check multiple (will return true as long as one as a non-null change)
	 */
	public static Boolean isChangedNotNull(SObject oldSo, SObject so, List<String> fieldNames) {
		for (String fName : fieldNames) {
			if (isChangedNotNull(oldSo, so, fName)) {
				return true;
			}
		}
		return false;
	}

	public static Boolean isChangedNotNull(SObject oldSo, SObject so, String fieldName) {
		return so.get(fieldName) != oldSo.get(fieldName) && so.get(fieldName) != null;
	}

	/* isChanged = Determines if a field value changed during an update, even if it's now null
	 * Multiple constructors to reference a single field, a list of field names, or fields in a Field Set
	 */
	public static Boolean isChanged(SObject oldSo, SObject so, String objName, String fieldSetName) {
		return isChanged(oldSo, so, getFieldSetList(objName, fieldSetName));
	}

	public static Boolean isChanged(SObject oldSo, SObject so, List<String> fieldNames) {
		for (String fName : fieldNames) {
			if (isChanged(oldSo, so, fName)) {
				return true;
			}
		}
		return false;
	}

	public static Boolean isChanged(SObject oldSo, SObject so, String fieldName) {
		return oldSo.get(fieldName) != so.get(fieldName);
	}

	/* Checks to see if Email Deliverability is enabled for the environment
	 * Used to prevent errors when sending emails FROM Apex in sandboxes, or while running tests
	 */
	@TestVisible
	public static Boolean checkEmailDeliverability() {
		Boolean emailsEnabled = true;
		try {
			Messaging.reserveSingleEmailCapacity(1);
			Messaging.reserveMassEmailCapacity(1);
		} catch (System.NoAccessException e) {
			emailsEnabled = false;
		}
		return emailsEnabled;
	}

	/*
	 * Returns a reusable map of Profile Id to the corresponding records. This could be used for more complex
	 * logic to reference profiles based on License, UserType, SSO, etc. Add Profile fields to query as needed.
	 */
	public static Map<Id, Profile> getProfileDetails() {
		if (!profileDetails.isEmpty()) {
			return profileDetails;
		} else {
			profileDetails = new Map<Id, Profile>([SELECT Id, Name, UserType, UserLicenseId FROM Profile]);
			// Store simplified map of just Profile Name to Profile Id. This is more commonly used to get ID FROM Profile Name
			for (Profile p : profileDetails.values()) {
				profileIdMap.put(p.Name, p.Id);
			}
			return profileDetails;
		}
	}

	public static Map<String, Id> getProfileIdMap() {
		if (!profileIdMap.isEmpty()) {
			return profileIdMap;
		} else {
			getProfileDetails();
			return profileIdMap;
		}
	}

	/*
	 * Returns UserRole Id if UserRole DeveloperName provided, and returns DeveloperName if UserRoleId provided
	 * Map is cached and re-usable within same transaction without additional queries
	 */
	public static String getUserRoleIdOrName(String roleIdOrName) {
		if (userRoleMap.isEmpty()) {
			for (UserRole ur : [SELECT Id, DeveloperName FROM UserRole]) {
				userRoleMap.put(ur.Id, ur.DeveloperName);
				userRoleMap.put(ur.DeveloperName, ur.Id);
			}
		}
		return (userRoleMap.containsKey(roleIdOrName)) ? userRoleMap.get(roleIdOrName) : '';
	}

	public static Exception_Logs__c createDebugLog(String apexClass, String debugMsg, Boolean insertRecord) {
		CurrentUser currUser = new CurrentUser();
		Exception_Logs__c debugLog = new Exception_Logs__c(
			Type__c = 'Debug Log',
			ApexClass__c = apexClass,
			Details__c = debugMsg
		);
		// In rare situations the running user is a system user that's not visible, so need to check to avoid null reference errors
		if (currUser != null) {
			debugLog.User__c = currUser.userId;
			debugLog.UserProfile__c = currUser.profileName;
			debugLog.UserRole__c = currUser.userRoleDevName;
		}
		if (insertRecord) {
			insert debugLog;
		}
		return debugLog;
	}

	public static Exception_Logs__c createExceptionLog(Exception ex, String apexClass, String detailMessage, Boolean insertRecord) {
		CurrentUser currUser = new CurrentUser();
		Exception_Logs__c exLog = new Exception_Logs__c(Type__c = ex.getTypeName(),
			//Message__c = ex.getMessage(),
			LineNumber__c = ex.getLineNumber(),
			Cause__c = String.valueOf(ex.getCause()),
			StackTrace__c = ex.getStackTraceString(),
			ApexClass__c = apexClass,
			Details__c = detailMessage
		);
		if(ex.getMessage().length() > 255) {
			exLog.Long_Message__c = ex.getMessage() ;
		} else {
			exLog.Message__c = ex.getMessage();
		}
		// In rare situations the running user is a system user that's not visible, so need to check to avoid null reference errors
		if (currUser != null) {
			exLog.User__c = currUser.userId;
			exLog.UserProfile__c = currUser.profileName;
			exLog.UserRole__c = currUser.userRoleDevName;
		}
		if (insertRecord) {
			insert exLog;
		}
		return exLog;
	}

	public static Boolean isSandbox() {
		if (thisOrg.isEmpty()) {
			thisOrg = [SELECT Id, isSandbox FROM Organization LIMIT 1];
		}
		return thisOrg[0].isSandbox;
	}

	/* Get list of Picklist values based on Object ane Field API names
	 * Can also modify to include getLabel(), isActive(), and isDefaultValue() for each picklist entry
	 */
	public static List<String> getPicklistValues(String objectName, String fieldName) {
		List<String> picklistValues = new List<String>();
		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
		for (Schema.PicklistEntry ple : fieldMap.get(fieldName).getDescribe().getPickListValues()) {
			picklistValues.add(ple.getValue());
		}
		return picklistValues;
	}

	/* Returns a list of Field API names based on a Field Set
	 * Could also be modified to include field label / field type / isRequired
	 */
	public static List<String> getFieldSetList(String sObjName, String fieldSetName) {
		// Use Schema methods to get Field Set based on Object API name and Field Set name
		DescribeSObjectResult describeObj = ((SObject)Type.forName('Schema', sObjName).newInstance()).getSObjectType().getDescribe();
		List<Schema.FieldSetMember> fieldSetMemberList = describeObj.FieldSets.getMap().get(fieldSetName).getFields();

		// Loop through FieldSetMembers to create list of strings (Field API Names)
		List<String> fieldList = new List<String>();
		for (Schema.FieldSetMember fsm : fieldSetMemberList) {
			fieldList.add(fsm.getFieldPath());
		}
		return fieldList;
	}

	/* Return a list of Field Names for a given object;
	   Option to filter to return Custom Fields only; Default will return all fields
	*/
	public static Set<String> getAllFields(String sObjName) {
		return getAllFields(sObjName, false);
	}

	public static Set<String> getAllFields(String sObjName, Boolean customOnly) {
		// Check if this Object's field list has already been built; If not, then build list, otherwise return cached results
		List<Schema.SObjectField> sObjFieldList = sObjFieldMap.get(sObjName);

		if (sObjFieldList == null) {
			// Use Apex Type methods for maximum performance
			sObjFieldList = ((SObject)Type.forName('Schema', sObjName).newInstance()).getSObjectType().getDescribe().fields.getMap().values();
			sObjFieldMap.put(sObjName, sObjFieldList);
		}

		// Build list of fields to return
		Set<String> fieldsToReturn = new Set<String>();
		for (Schema.SObjectField sField : sObjFieldList) {
			Schema.DescribeFieldResult describeField = sField.getDescribe();
			// NOTE: Can expand method to only return fields accessible to the running user --> describeField.isAccessible()
			if (!customOnly || describeField.isCustom()) {
				fieldsToReturn.add(describeField.getName());
			}
		}
		return fieldsToReturn;
	}

	/* SKH
	*	create method for sending emails FROM apex that use Xandr template branding; HTML formatting; Use for batch class / exception alerts
	*/
	public static Map<Id,Sobject> getRecords(String fieldList, String objectName, String whereCond) {
		return new Map<Id,SObject>(database.query('SELECT '+fieldList+' FROM '+objectName+(!String.isBlank(whereCond)?whereCond:'')));
	}

	/*
	 * Retruns a place holder contact so you can send a classic email template without connecting it to anything
	*/
	public static List<Contact> getPlaceHolderContact() {
		if (placeHolderContact.isEmpty()) {
			placeHolderContact = [SELECT Id FROM Contact WHERE FirstName = 'CSP' AND LastName = 'Dummy' LIMIT 1];
		}
		return placeHolderContact;
	}

}