trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerFactory.createAndExecuteHandler(AccountHandler.Class, Account.SObjectType);
}