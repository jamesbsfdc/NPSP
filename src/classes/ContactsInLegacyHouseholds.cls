/*
    Copyright (c) 2021 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @description Domain class for Contacts that use the legacy Household__c object in NPSP.
* These Contact can use either One-To-One Accounts or the Individual "Bucket" Account. In old
* documentation they are referred to as "Individual Contacts". They are also referred to this
* way in Household Settings.
*/
public inherited sharing class ContactsInLegacyHouseholds extends fflib_SObjects {

    private Map<Id, Contact> oldMap;
    private final String RECORD_TYPE_ID = 'RecordTypeId';
    @TestVisible
    private HouseholdSettings settings {
        get {
            if (settings == null) {
                settings = new HouseholdSettings();
            }
            return settings;
        }
        set;
    }

    public ContactsInLegacyHouseholds(List<Contact> records) {
        this(records, null);
    }

    public ContactsInLegacyHouseholds(List<Contact> records, Map<Id, Contact> oldMap) {
        super(records, Contact.SObjectType);
        this.oldMap = oldMap != null ?
                new Map<Id, Contact>(oldMap) : new Map<Id, Contact>();
    }

    public void onAfterInsert() {
        if (allContactsGetHouseholds()) {
            insertHouseholdsForContactsThatDoNotHaveOne();
        }
        if (allIndividualContactsGetHouseholds()) {
            insertHouseholdsForContactsInIndividualAccounts();
        }
    }

    public void onAfterUpdate() {
        insertHouseholds();
        fireRollups();
        updateHouseholdNames();
        deleteEmptyHouseholds();
    }

    private void deleteEmptyHouseholds() {
        Households oldHouseholds = new Households(new Set<Id>(oldHouseholdIds()));
        oldHouseholds.deleteEmptyHouseholds();
    }

    public void onAfterDelete() {
        Households oldHouseholds = new Households(householdIds());
        oldHouseholds.deleteEmptyHouseholds();
        oldHouseholds.updateHouseholdNameAndMemberCount();
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private static Integer numberOfTimesUpdateHouseholdNamesHasRun = 0;
    private void updateHouseholdNames() {
        List<Id> householdsNeedingNameAndMemberCountRefresh = getHouseholdsWithMembershipOrNamingFieldChanges();
        if (householdsNeedingNameAndMemberCountRefresh.size() > 0 && numberOfTimesUpdateHouseholdNamesHasRun < 2) {
            Households households =
                    new Households(new Set<Id>(householdsNeedingNameAndMemberCountRefresh));
            households.updateHouseholdNameAndMemberCount();
            numberOfTimesUpdateHouseholdNamesHasRun++;
        }
    }

    private List<Id> getHouseholdsWithMembershipOrNamingFieldChanges() {
        List<Id> householdsNeedingNamesUpdated = new List<Id>();
        householdsNeedingNamesUpdated.addAll(
                householdIdsWithMembershipChanges());
        householdsNeedingNamesUpdated.addAll(householdsWithNamingFieldChanges());
        return householdsNeedingNamesUpdated;
    }

    private Set<Id> householdIdsWithMembershipChanges() {
        Set<Id> ids = new Set<Id>();
        for (Contact con : contactsThatChangedHouseholds()) {
            ids.add(householdIdFor(con));
            ids.add(oldHouseholdIdFor(con));
        }
        return ids;
    }

    private void fireRollups() {
        Households households = new Households(householdIdsWithMembershipChanges());
        households.calculateLegacyHouseholdRollups();
    }

    private void insertHouseholds() {
        List<Contact> contactsThatDoNotHaveAHousehold =
                (List<Contact>) contactsWithoutHouseholds().getRecords();
        List<Contact> contactsNeedingHouseholds = new List<Contact>();
        if (settings.isAllProcessor()) {
            contactsNeedingHouseholds.addAll(contactsThatDoNotHaveAHousehold);
        }
        if (settings.isAllIndividualsProcessor()) {
            contactsNeedingHouseholds.addAll(
                    getContactsInIndividualAccounts(
                            contactsThatDoNotHaveAHousehold));
        }
        insertHouseholdsForContacts(contactsNeedingHouseholds, false);
    }

    private List<Contact> contactsThatChangedHouseholds() {
        List<Contact> contactsThatChangedHouseholds = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdChangedFor(con)) {
                contactsThatChangedHouseholds.add(con);
            }
        }
        return contactsThatChangedHouseholds;
    }

    private fflib_SObjects contactsWithoutHouseholds() {
        return selectByFieldValue(Contact.npo02__Household__c, null);
    }

    private List<Contact> getContactsInIndividualAccounts(List<Contact> contacts) {
        Map<Id, Account> contactAccountMap = getContactAccountMap(contacts);
        List<Contact> contactsInIndividualAccounts = new List<Contact>();
        for (Contact con : contacts) {
            if (hasAccount(con)) {
                Account acc = contactAccountMap.get(con.AccountId);
                if (isIndividualAccount(acc)) {
                    contactsInIndividualAccounts.add(con);
                }
            } else {
                contactsInIndividualAccounts.add(con);
            }
        }
        return contactsInIndividualAccounts;
    }

    private Boolean hasAccount(Contact con) {
        return con.AccountId != null;
    }

    private Boolean isIndividualAccount(Account acc) {
        return acc.npe01__SYSTEMIsIndividual__c == true;
    }

    private Id oldHouseholdIdFor(Contact con) {
        return oldVersionOf(con).npo02__Household__c;
    }

    private Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    private Set<Id> householdIds() {
        Set<Id> householdIds = getIdFieldValues(Contact.npo02__Household__c);
        householdIds.remove(null);
        return new Set<Id>(householdIds);
    }

    private List<Id> oldHouseholdIds() {
        List<Id> oldHouseholdIds = new List<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (conWasInAHousehold(con)) {
                oldHouseholdIds.add(oldHouseholdIdFor(con));
            }
        }
        return oldHouseholdIds;
    }

    private Boolean conWasInAHousehold(Contact con) {
        return oldHouseholdIdFor(con) != null;
    }

    private void insertHouseholdsForContactsInIndividualAccounts() {
        List<SObject> contactsThatDoNotHaveAHouseholdRecord =
                contactsWithoutHouseholds().getRecords();
        if (contactsThatDoNotHaveAHouseholdRecord.size() > 0) {
            insertHouseholdsForContacts(
                    getContactsInIndividualAccounts(
                            contactsThatDoNotHaveAHouseholdRecord),
                    true);
        }
    }

    private Boolean allIndividualContactsGetHouseholds() {
        return settings.isAllIndividualsProcessor();
    }

    private Boolean allContactsGetHouseholds() {
        return settings.isAllProcessor();
    }

    private void insertHouseholdsForContactsThatDoNotHaveOne() {
        List<Contact> householdInserts = contactsWithoutHouseholds().getRecords();
        if (householdInserts.size() > 0) {
            insertHouseholdsForContacts(householdInserts, true);
        }
    }

    private Map<Id, Account> getContactAccountMap(List<Contact> contacts) {
        List<Id> accountIds = getAccountIds(contacts);
        Map<Id, Account> contactAccountMap = new Map<Id, Account>([
                SELECT Id, npe01__SYSTEMIsIndividual__c, Name
                FROM Account
                WHERE Id IN :accountIds
        ]);
        return contactAccountMap;
    }

    private List<Id> getAccountIds(List<Contact> contacts) {
        List<Id> accountIds = new List<Id>();
        for (Contact con : contacts) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }
        return accountIds;
    }

    /*******************************************************************************************************
    * @description Creates a new Household Object for each contact, unless excluded by recordType
    * @param contacts List of Contacts
    * @param isInsertTrigger Whether called from the afterInsert trigger (vs. afterUpdate trigger) on Contacts
    * @return void
    ********************************************************************************************************/
    private void insertHouseholdsForContacts(List<Contact> contacts, Boolean isInsertTrigger) {
        List<npo02__Household__c> householdInserts = getHouseholdsForInsert(contacts);
        if (householdInserts.size() > 0) {
            Database.SaveResult[] householdSaveResults = insertHouseholds(householdInserts);
            putHouseholdIdOntoContacts(contacts, householdSaveResults);
            if (isInsertTrigger) {
                updateNamesAfterHouseholdInsert(householdSaveResults);
            }
        }
    }

    private Database.SaveResult[] insertHouseholds(
            List<npo02__Household__c> householdInserts) {
        Database.SaveResult[] householdSaveResults =
                UTIL_DMLService.insertRecords(householdInserts, false);
        return householdSaveResults;
    }

    private void putHouseholdIdOntoContacts(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId =
                processHouseholdSaveResults(contacts, householdSaveResults);
        update contactsToBeUpdatedWithHouseholdId;
    }

    private void updateNamesAfterHouseholdInsert(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = getHouseholdIdsNeedingNamesUpdatedFromSaveResult(lsr);
        if (!householdIdsNeedingNamesUpdated.isEmpty()) {
            Households households = new Households(new Set<Id>
                    (householdIdsNeedingNamesUpdated));
            households.updateHouseholdNameAndMemberCount();
        }
    }

    private List<Id> getHouseholdIdsNeedingNamesUpdatedFromSaveResult(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = new List<Id>();
        for (Database.SaveResult sr : lsr) {
            if (sr.isSuccess()) {
                householdIdsNeedingNamesUpdated.add(sr.getID());
            }
        }
        return householdIdsNeedingNamesUpdated;
    }

    private List<npo02__Household__c> getHouseholdsForInsert(List<Contact> contacts) {
        List<npo02__household__c> households = new List<npo02__household__c>();
        for (Contact con : contacts) {
            if (shouldExcludeForNewHHAccount(con)) {
                households.add(getHouseholdForInsertFromContact(con));
            }
        }
        return households;
    }

    private npo02__Household__c getHouseholdForInsertFromContact(Contact con) {
        npo02__household__c household =
                new npo02__household__c(Name = getDefaultHouseholdName(con));
        syncPrimaryAddressBlock(household, con);
        return household;
    }

    private void syncPrimaryAddressBlock(npo02__Household__c household, Contact con) {
        household.npo02__MailingStreet__c = con.MailingStreet;
        household.npo02__MailingCity__c = con.MailingCity;
        household.npo02__MailingState__c = con.MailingState;
        household.npo02__MailingPostalCode__c = con.MailingPostalCode;
        household.npo02__MailingCountry__c = con.MailingCountry;
        household.npo02__HouseholdPhone__c = con.HomePhone;
        household.npo02__HouseholdEmail__c = con.Email;
    }

    private String getDefaultHouseholdName(Contact con) {
        String hName = con.LastName;
        return hName += ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    private Boolean shouldExcludeForNewHHAccount(Contact con) {
        return !isRecordTypesOnContacts()
                || !settings.contactRecordTypesToExclude().contains(recordTypeIdFor(con));
    }

    private List<Contact> processHouseholdSaveResults(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact con : contacts) {
            if (shouldExcludeForNewHHAccount(con)) {
                Database.SaveResult saveResult = householdSaveResults[i];
                if (saveResult.isSuccess() == true) {
                    //write the new Household Ids to the Contacts
                    Contact cloneContact = con.Clone(true, false);
                    cloneContact.npo02__household__c = saveResult.getId();
                    contactsToBeUpdatedWithHouseholdId.add(cloneContact);
                } else {
                    Database.Error err = saveResult.getErrors()[0];
                    con.addError(err.getMessage());
                }
                i += 1;
            }
        }
        return contactsToBeUpdatedWithHouseholdId;
    }

    private Id recordTypeIdFor(Contact con) {
        return (Id) con.get(RECORD_TYPE_ID);
    }

    private Boolean isRecordTypesOnContacts() {
        return Schema.sObjectType.Contact.fields.getMap().get(RECORD_TYPE_ID) != null;
    }

    private Boolean hasHousehold(Contact con) {
        return householdIdFor(con) != null;
    }

    private List<Id> householdsWithNamingFieldChanges() {
        List<Id> householdsWithNamingFieldChanges = new List<Id>();
        for (Contact con : (List<Contact>) contactsInHouseholds()) {
            if (isHouseholdNamingFieldsChanged(con)) {
                householdsWithNamingFieldChanges.add(householdIdFor(con));
            }
        }
        return householdsWithNamingFieldChanges;
    }

    private List<Contact> contactsInHouseholds() {
        List<Contact> contacts = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (hasHousehold(con)) {
                contacts.add(con);
            }
        }
        return contacts;
    }

    private Boolean isHouseholdNamingFieldsChanged(Contact con) {
        return namingExclusionsChangedFor(con) || namingFieldChangedFor(con);
    }

    private Boolean namingFieldChangedFor(Contact con) {
        for (String fieldName : fieldsUsedForHouseholdNaming()) {
            if (isFieldChanged(con, fieldName)) {
                return true;
            }
        }
        return false;
    }

    private Set<String> householdNamingFields;
    private Set<String> fieldsUsedForHouseholdNaming() {
        if (householdNamingFields == null) {
            householdNamingFields = new HouseholdNamingService()
                    .getHouseholdNamingContactFields();
        }
        return householdNamingFields;
    }

    private Boolean isFieldChanged(Contact con, String fieldName) {
        // make sure to use case sensitive comparison
        String strName = getNewFieldValue(con, fieldName);
        String strNameOld = getOldFieldValue(con, fieldName);
        Boolean isChanged = !strName.equals(strNameOld);
        return isChanged;
    }

    private Boolean namingExclusionsChangedFor(Contact con) {
        HouseholdNamingExclusionsString exclusions =
                new HouseholdNamingExclusionsString(namingExclusionsFor(con));
        return exclusions.isNotEqualTo(namingExclusionsFor(oldVersionOf(con)));
    }

    private Boolean householdChangedFor(Contact con) {
        return householdIdFor(con) != oldHouseholdIdFor(con);
    }

    private String getOldFieldValue(Contact con, String fieldName) {
        String strNameOld = String.valueOf(oldVersionOf(con).get(fieldName));
        return strNameOld == null ? '' : strNameOld;
    }

    private String getNewFieldValue(Contact con, String fieldName) {
        String strName = String.valueOf(con.get(fieldName));
        return strName == null ? '' : strName;
    }

    private String namingExclusionsFor(Contact con) {
        return con.npo02__Naming_Exclusions__c;
    }
}