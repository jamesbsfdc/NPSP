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
* @description Household Name value object in NPSP.
*/
public inherited sharing class HouseholdName {

    private Contacts contacts;
    private HH_INaming service;

    public HouseholdName(Contacts contacts) {
        this(contacts, null);
    }
    
    public HouseholdName(Contacts contacts, HH_INaming service) {
        this.contacts = contacts;
        this.service = service == null ? defaultHH_INamingImplementation() : service;
    }

    private HH_INamingImpl defaultHH_INamingImplementation() {
        return new HH_INamingImpl();
    }

    /*******************************************************************************************************
    * @description returns the Household Name for the list of Contacts
    * @return String
    */
    public String value() {
        return service.getHouseholdName(getContactsForHouseholdNameGeneration());
    }

    private List<Contact> getContactsForHouseholdNameGeneration() {
        List<Contact> contactsForHouseholdNameGeneration = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (contactShouldBeUsedForHouseholdNameGeneration(con)) {
                contactsForHouseholdNameGeneration.add(con);
            }
        }
        return contactsForHouseholdNameGeneration;
    }

    private Boolean contactShouldBeUsedForHouseholdNameGeneration(Contact con) {
        return con.npo02__Naming_Exclusions__c == null
                || !con.npo02__Naming_Exclusions__c.contains('Name');
    }

    /*******************************************************************************************************
    * @description returns the Informal Greeting for the list of Contacts
    * @return String
    */
    public String asInformalGreeting() {
        return service.getHouseholdInformalGreeting(getContactsForInformalName());
    }

    private List<Contact> getContactsForInformalName() {
        List<Contact> listCon = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (isIncludedInInformalGreeting(con)) {
                listCon.add(con);
            }
        }
        return listCon;
    }

    private Boolean isIncludedInInformalGreeting(Contact con) {
        return con.npo02__Naming_Exclusions__c == null
                || !con.npo02__Naming_Exclusions__c.contains('Informal_Greeting__c');
    }

    /*******************************************************************************************************
    * @description returns the Formal Greeting for the list of Contacts
    * @return String
    */
    public String asFormalGreeting() {
        return service.getHouseholdFormalGreeting(getContactsForFormalName());
    }

    private List<Contact> getContactsForFormalName() {
        List<Contact> contactsForFormalName = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (isIncludedInFormalGreeting(con)) {
                contactsForFormalName.add(con);
            }
        }
        return contactsForFormalName;
    }

    private Boolean isIncludedInFormalGreeting(Contact con) {
        return con.npo02__Naming_Exclusions__c == null
                || !con.npo02__Naming_Exclusions__c.contains('Formal_Greeting__c');
    }

}