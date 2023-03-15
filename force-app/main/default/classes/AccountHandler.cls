/* AccountHandler.cls  ************************************************************************************************************************
* AccountTrigger handler. Calls AccountHelper for supporting methods. See TriggerFactory + TriggerInterface classes for details
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
* @author			Jagan Gorre
* @testClass		AccountTriggerTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
* @lastModified		2/26/2020		Jagan
* @description		Initial version.
* 3/26/2020   Hema M - Added populateSudokuValues method as per SFDC-2833
***********************************************************************************************************************************************/
public without sharing class AccountHandler implements TriggerInterface {

	/* Sam Howle 2/20/2020
	* Storing Record Type IDs in static variables to reference instead of repeatedly calling AccountUtils methods
	*/
	public static Map<String,String> recordTypeMap = new Map<String, String>();
	public static Id FinancialRectypeId;
	public static Id brandRtId;
	public static Id consoleMemberRtId;
	public static Id nonConsoleMemberRtId;
	public static Set<Id> memberRtIds = new Set<Id>();
	public static Id BUSINESS_SUPPORT_USER_ID;
	public static Set<Id> commercialLeaderIdSet = new Set<Id>();
	public static Map<String,Map<String,String>> ownerMap = new Map<String,Map<String,String>>();
	private static Map<Id, OpportunityLineItem> oppProductMap = new Map<Id, OpportunityLineItem>();
	private static Map<Id,Account> accountDetailMap = new Map<Id,Account>();
	private static Map<String, Schema.SObjectField> accountObjectFields;
	private static Set<Id> accIdsToUpdateCSPContacts = new Set<Id>();
	private static Set<Id> accIdsToCreateIRs = new Set<Id>();
	private static Set<Id> accIdsForGDPRProcess = new Set<Id>();
	private static List<Integration_Request__c> intReqList = new List<Integration_Request__c>();
	private static Set<Id> oppIdsToCreateAssets = new Set<Id>();
	private static Map<Id,Id> oppIdToAccIdMap = new Map<Id,Id>();
	private static Set<Id> accIdsToCreateContactRelations = new Set<Id>();
	private static Set<Id> accIdsToUpdateMemberOwner = new Set<Id>();
	private static Map<Id,Account> parentAccountCreditLimitMap = new Map<Id,Account>();
	private static Set<Id> accToAddCampaignMembers = new Set<Id>();
	private static List<Id> terminatedAccountIdSet = new List<Id>();

	// Store info about current user
	public static CurrentUser currUser = new CurrentUser();

	static {
		recordTypeMap = Util.getRecordTypeMap(Account.sObjectType);
		accountObjectFields = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
		FinancialRectypeId = recordTypeMap.get('Customer_Account');
		consoleMemberRtId = recordTypeMap.get('Console_Member');
		nonConsoleMemberRtId = recordTypeMap.get('Non_Console_Member');
		brandRtId = recordTypeMap.get('Brand');
		memberRtIds.add(consoleMemberRtId);
		memberRtIds.add(nonConsoleMemberRtId);
		BUSINESS_SUPPORT_USER_ID = AccountHelper.getBusinessSupportUserId();
	}

	/* All queries needed for Before Trigger go here; Build maps, lists, sets to reference in helper
	 */
	public void bulkBefore() {
		Set<Id> parentIdSetToCopyDataFrom = new Set<Id>();
		if (Trigger.isInsert) {
			Set<Id> ownerIds = new Set<Id>();
			Set<Id> oppIds = new Set<Id>();

			for (Sobject sobj : Trigger.New) {
				Account acc = (Account) sobj;
				if ((acc.RecordTypeId == FinancialRectypeId || acc.RecordTypeId == brandRtId) && !currUser.isSalesOps) {
					ownerIds.add(acc.ownerid);
				}
				if (memberRtIds.contains(acc.RecordTypeId)) {
					parentIdSetToCopyDataFrom.add(acc.ParentId);
					if (acc.Opportunity__c != null)
						oppIds.add(acc.Opportunity__c );
				}
			}
			if (!ownerIds.isEmpty()) {
				commercialLeaderIdSet = AccountHelper.getCommercialLeaderSet();
				ownerMap = AccountHelper.getOwnershipMap(ownerIds);
			}
			if (!oppIds.IsEmpty()) {
				oppProductMap = AccountHelper.getOpportunityProduct(oppIds);
			}
		}

		if (Trigger.isUpdate) {
			for (Sobject sobj : Trigger.New) {
				Account acc = (Account) sobj;
				if (memberRtIds.contains(acc.RecordTypeId) && (acc.Copy_from_Account_Seller__c || acc.Copy_from_Account__c)) {
					parentIdSetToCopyDataFrom.add(acc.ParentId);
				}
			}
		}
		if (!parentIdSetToCopyDataFrom.isEmpty()) {
			accountDetailMap = AccountHelper.fetchAccountDetailsByIds(parentIdSetToCopyDataFrom);
		}

	}

	/* All queries needed for After Trigger go here; Build maps, lists, sets to reference in helper
	 */
	public void bulkAfter() {
		if (Trigger.isInsert) {
			// For new Console Member accounts, build a map of parent Customer Account records for related updates
			parentAccountCreditLimitMap = AccountHelper.buildParentCreditLimitMap(Trigger.new, consoleMemberRtId);
		}
	}

	public void beforeInsert(SObject so) {
		Account acc = (Account)so;
		if (acc.RecordTypeId == FinancialRectypeId || acc.RecordTypeId == brandRtId) {
			// business support logic if account is created by revOps
			if (currUser.isSalesOps && BUSINESS_SUPPORT_USER_ID != null) {
				acc.ownerid = BUSINESS_SUPPORT_USER_ID;
			} else {
				acc.Senior_Account_Owner__c = ownerMap.get(acc.ownerId).get('SeniorAccountOwner');
				acc.Commercial_Leader__c = ownerMap.get(acc.ownerId).get('CommercialLeader');
			}
			acc = AccountHelper.addCountryNameforAgreement(acc);
		}
		else if (memberRtIds.contains(acc.RecordTypeId)) {
			if (accountDetailMap.containsKey(acc.ParentId)) {
				acc = AccountHelper.copyAccountDataFromParent(acc, accountDetailMap.get(acc.ParentId));
				acc = AccountHelper.copySellerDataFromParent(acc, accountDetailMap.get(acc.ParentId));
				acc = AccountHelper.copyAddressDataFromParent(acc, accountDetailMap.get(acc.ParentId));
				if (oppProductMap.containsKey(acc.Opportunity__c))
					acc = AccountHelper.populateSudokuValues(acc, accountDetailMap.get(acc.ParentId),oppProductMap.get(acc.Opportunity__c));
			}
			AccountHelper.populateInforAddressData(acc, null);
		}
		if (acc.AppNexus_Member_ID__c != null) {
			acc.Date_Seller_Address_Changed__c = system.now();
			acc.Date_Invoice_Address_Changed__c = system.now();
		}

	}

	/*
	 * Field updates on these records
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
		Account acc = (Account)so;
		Account oldAcc = (Account)oldSo;
		if (acc.RecordTypeId == FinancialRectypeId || acc.RecordTypeId == brandRtId) {
			acc =AccountHelper.addCountryNameforAgreement(acc);
		}
		//Logic only for Member accounts
		if (memberRtIds.contains(acc.RecordTypeId)) {
			AccountHelper.populateParentDetails(acc, oldAcc);
		}


	}

	public void beforeDelete(SObject oldSo) {}

	public void afterInsert(SObject so) {
		Account acc = (Account)so;

	}

	/*
	 * Data validations; build list of related records to process; external callouts
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		Account acc = (Account)so;
		Account oldAcc = (Account)oldSo;

		// Example Record Type Check
		if (acc.RecordTypeId == FinancialRectypeId && Util.isChanged(oldAcc,acc,'Status__c')) {
			terminatedAccountIdSet.add(acc.Id);
		}
	}

	public void afterDelete(SObject oldSo) {}

	public void afterUndelete(SObject so) {}

	/* Evaluated once following the BEFORE trigger and once following the AFTER trigger. Used to
	 * execute the processing of related records and/or external callouts
	 */
	public void andFinally() {

		if (Trigger.isAfter) {
			if (Trigger.isInsert) {
			}
			if (Trigger.isUpdate) {

			}
		}
	}
}