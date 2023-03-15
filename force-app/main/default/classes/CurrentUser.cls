/* CurrentUser.cls  ************************************************************************************************************************
* Utility class to cache information about the current user on a trigger event.
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
* @author			Sam Howle (2/12/2020)		--sam.howle@xandr.com
* @testClass		CurrentUserTest
* ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
* @lastModified		3/12/2021		--Sam Howle
* @description		Additional attributes to reference running user profiles, and to group Admin-related profiles
***********************************************************************************************************************************************/
public without sharing class CurrentUser {
	// General user information
	public Id userId;
	public String userName;
	public String fullName;
	public Id profileId;
	public Id userRoleId;
	public String userRoleDevName;
	public String profileName;
	public Boolean isExternalUser;
	public Boolean isAdmin;
	public Boolean isGuest;
	public String email;
	public String userType;

	public CurrentUser() {
		Map<Id, Profile> profileMap = Util.getProfileDetails();
		List<String> externalUserProfiles = new List<String>{'Customer Portal User'};

		this.userId = UserInfo.getUserId();
		this.userName = UserInfo.getUserName();
		this.fullName = UserInfo.getName();
		this.profileId = UserInfo.getProfileId();
		this.profileName = (profileMap.containsKey(this.profileId)) ? profileMap.get(profileId).Name : '';
		this.userRoleId = UserInfo.getUserRoleId();
		this.userRoleDevName = Util.getUserRoleIdOrName(userRoleId);
		this.isExternalUser = (externalUserProfiles.contains(profileName)) ? true : false;
		this.isAdmin = (profileName == 'System Administrator') ? true : false;
		this.email = UserInfo.getUserEmail();
		this.isGuest = UserInfo.getUserType() == 'Guest' ? true : false;
		this.userType = UserInfo.getUserType();
	}

}