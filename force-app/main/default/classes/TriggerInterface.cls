/* TriggerInterface.cls   *************************************************************************************************************************
* Interface containing methods used by TriggerFactory framework. Trigger handlers must implement these to enforce best practices and bulkification.
* @originalAuthor	Tony Scott		https://meltedwires.com/2013/06/05/trigger-pattern-for-tidy-streamlined-bulkified-triggers-revisited/
* @implementedBy	Sam Howle
****************************************************************************************************************************************************/
public interface TriggerInterface {

	/**
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache any reference data
	 * into maps prior to execution of the trigger. All SOQL queries, maps, lists, sets that are needed
	 * for individual BEFORE trigger event methods below must be constructed here.
	 */
	void bulkBefore();

	/**
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache any reference data
	 * into maps prior to execution of the trigger. All SOQL queries, maps, lists, sets that are needed
	 * for individual AFTER trigger event methods below must be constructed here.
	 */
	void bulkAfter();

	/**
	 * This method is called iteratively for each record to be inserted during the BEFORE trigger event.
	 * Never execute any SOQL/SOSL in this method because they would be executed repeatedly for each individual
	 * record in the Trigger.new list. Any changes to records will be recorded immediately since the record has
	 * not yet been saved to the database. SObject must be cast to respective type.
	 */
	void beforeInsert(SObject so);

	/**
	 * This method is called iteratively for each record to be updated during the BEFORE trigger event. Same considerations
	 * as before insert, but this will include both the old and new SObject records.
	 */
	void beforeUpdate(SObject oldSo, SObject so);

	/**
	 * This method is called iteratively for each record to be deleted during the BEFORE trigger event. Same considerations
	 * as methods above except this will only include the old SObject record.
	 */
	void beforeDelete(SObject oldSo);

	/**
	 * This method is called iteratively for each record inserted during an AFTER trigger event. This method is mostly
	 * used for data validations (to allow all other triggers/PB/flows to process), and also when records on related objects need
	 * to be inserted/updated/deleted. The record is 'read only' by this point.
	 */
	void afterInsert(SObject so);

	/**
	 * This method is called iteratively for each record updated during the AFTER trigger event. Record is Read Only.
	 * See notes above.
	 */
	void afterUpdate(SObject oldSo, SObject so);

	/**
	 * This method is called iteratively for each record deleted during the AFTER trigger event. Record is Read Only.
	 * See notes above.
	 */
	void afterDelete(SObject oldSo);

	/**
	 * This method is called iteratively for each record undeleted during the AFTER trigger event. Record is Read Only.
	 * See notes above.
	 */
	void afterUndelete(SObject so);

	/**
	 * This method is called once all records have been processed by the respective trigger event method above. andFinally
	 * is executed one time after the Before Trigger, and another time after the After Trigger. Use this method to accomplish
	 * any final operations such as inserting/updating/deleting records on related objects, make API callouts, send alerts, etc.
	 */
	void andFinally();
}