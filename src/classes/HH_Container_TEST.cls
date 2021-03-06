/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Households
* @group-content ../../ApexDocContent/Households.htm
* @description Apex test class for all Apex code used in HH_Container_LCTRL
*/
@isTest
private class HH_Container_TEST {

    private static Account hhA;
    private static npo02__Household__c hhO;
    private static Contact conA;
    private static Contact conO;
    
    /*********************************************************************************************************
    * @description initializes test data of a Household Account and a Household Object
    */
    private static void initTestData() { 
        
        // create a Household Account and contact and address object
        hhA = new Account(Name = 'test_hh', npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE);
        insert hhA;
        conA = new Contact(FirstName='cA', LastName='conA', AccountId=hhA.Id, MailingCity='conA city', MailingCountry='United States');
        insert conA;
        Address__c addr = new Address__c(Household_Account__c=hhA.Id, Default_Address__c=false, 
            MailingCity__c='addr city', MailingCountry__c='United States');
        insert addr;

        // create a 1:1 account, Household Object and contact
        Account acc = new Account(Name = 'one2one', npe01__SYSTEM_AccountType__c = CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
        insert acc;
        hhO = new npo02__Household__c(Name = 'test_hh', npo02__MailingCity__c ='conO city', npo02__MailingCountry__c ='United States');
        insert hhO;
        conO = new Contact(FirstName='cO', LastName='conO', AccountId=acc.Id, npo02__Household__c=hhO.Id, MailingCity='conO city', MailingCountry='United States');
        insert conO;
    }

    /*********************************************************************************************************
    * @description Tests getHH() and getContacts()
    */
    public static testMethod void testGetHHGetContacts() { 
        
        initTestData();

        Test.startTest();

        system.assertNotEquals(null, HH_Container_LCTRL.getHH(hhA.Id));
        system.assertNotEquals(null, HH_Container_LCTRL.getHH(hhO.Id));
        system.assertNotEquals(null, HH_Container_LCTRL.getContacts(hhA.Id));
        system.assertNotEquals(null, HH_Container_LCTRL.getContacts(hhO.Id));
                
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Tests getAddresses()
    */
    public static testMethod void testGetAddresses() { 
        
        initTestData();

        Test.startTest();
        
        list<Address__c> listAddrA = HH_Container_LCTRL.getAddresses(hhA.Id, null);
        system.assertEquals(2, listAddrA.size());

        list<Address__c> listAddrO = HH_Container_LCTRL.getAddresses(hhO.Id, null);
        system.assertEquals(1, listAddrO.size());
                
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Tests packageLabels()
    */
    public static testMethod void testPackageLabels() { 
        HH_Container_LCTRL.packageLabels();
    }
        
    /*********************************************************************************************************
    * @description Tests upsertContacts()
    */
    public static testMethod void testUpsertContacts() { 
        initTestData();

        conA.FirstName = 'upserted';
        conO.FirstName = 'upserted';
        Contact con = new Contact(FirstName='inserted', LastName='test_hh');
        list<Contact> listCon = new list<Contact>{conA, conO, con};

        Test.startTest();
                    
        HH_Container_LCTRL.upsertContacts(listCon);
        listCon = [select FirstName from Contact order by FirstName desc];
        system.assertEquals(3, listCon.size());
        system.assertEquals('upserted', listCon[0].FirstName);
        system.assertEquals('upserted', listCon[1].FirstName);
        system.assertEquals('inserted', listCon[2].FirstName);

        Test.stopTest();
        
    }

    /*********************************************************************************************************
    * @description Tests updateHousehold()
    */
    public static testMethod void testUpdateHousehold() { 
        initTestData();

        Test.startTest();

        hhA.Name = 'updated';            
        HH_Container_LCTRL.updateHousehold(hhA);
        hhA = [select Name from Account where Id = :hhA.Id];
        system.assertEquals('updated', hhA.Name);

        hhO.Name = 'updated';            
        HH_Container_LCTRL.updateHousehold(hhO);
        hhO = [select Name from npo02__Household__c where Id = :hhO.Id];
        system.assertEquals('updated', hhO.Name);

        Test.stopTest();        
    }

    /*********************************************************************************************************
    * @description Tests mergeHouseholds()
    */
    public static testMethod void testMergeHouseholds() { 
        initTestData();
        Account hhA2 = new Account(Name = 'test_hh2', npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE);
        Account hhA3 = new Account(Name = 'test_hh3', npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE);
        list<Account> listAcc = new list<Account>{hhA2, hhA3};
        insert listAcc;
 
        Test.startTest();

        HH_Container_LCTRL.mergeHouseholds(hhA, listAcc);
        system.assertEquals(0, [select count() from Account where Id in :listAcc]);
        
        Test.stopTest();        
    }

    /*********************************************************************************************************
    @description
        Add new Contacts into the Household where:
            - The only Contact from another Household has the same Address
            - The only Contact from another Household has different Address
    verify:
        Only one default Address exists for the Household.
        Other Households are merged with the Household.
    **********************************************************************************************************/ 
    private static testMethod void saveShouldResultInOneDefaultAddressWhenContactsAreAddedToTheHousehold() {
        Integer accountSize = 3;
        Account[] accounts = buildAccounts(accountSize);
        insert accounts;

        Address__c[] addresses = buildAddresses(accounts);
        //One Account has the same address as the Household
        addresses[1].MailingStreet__c = addresses[0].MailingStreet__c;
        insert addresses;

        Integer contactsPerAccount = 1;
        insert buildContacts(accounts, contactsPerAccount);

        //Refresh the Household data from database
        accounts[0] = (Account) HH_Container_LCTRL.getHH(accounts[0].Id);

        Map<Id, Contact[]> contactsByHh = getContactsByHousehold();
        System.assertEquals(accountSize, contactsByHh.size());

        Contact[] hhContacts = contactsByHh.get(accounts[0].Id);
        for (Integer i = 1; i < accountSize; i++) {
            Contact newContact = contactsByHh.get(accounts[i].Id)[0];

            newContact.AccountId = accounts[0].Id;

            //Copy the Address to Contact the same way as it being done from Manage Household.
            //No other update, such as Household Naming, is done since it does not impact this test.
            copyAddressToContact(addresses[0], newContact);
            
            hhContacts.add(newContact);
        }

        Contact[] hhContactsToRemove = new Contact[0];
        Account[] accountsToMerge = new Account[] { accounts[1], accounts[2] };

        Test.startTest();
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        HH_Container_LCTRL.saveHouseholdPage(accounts[0], hhContacts, hhContactsToRemove, accountsToMerge);
        Test.stopTest();

        Account[] actualAccounts = getAccounts();
        System.assertEquals(1, actualAccounts.size(), actualAccounts);
        System.assertEquals(accounts[0].Id, actualAccounts[0].Id);

        Address__c[] actualAddresses = getAddresses();
        System.assertEquals(2, actualAddresses.size(), actualAddresses);

        Address__c defaultAddress = null;
        for (Address__c addr : actualAddresses) {
            Boolean isDefault = addr.Id == addresses[0].Id;
            System.assertEquals(isDefault, addr.Default_Address__c, addr); 

            if (isDefault) {
                defaultAddress = addr;
            }
        }

        System.assertNotEquals(null, defaultAddress); 

        contactsByHh = getContactsByHousehold();
        System.assertEquals(1, contactsByHh.size()); 
        Contact[] actualContacts = contactsByHh.get(accounts[0].Id);
        System.assertEquals(hhContacts.size(), actualContacts.size(), actualContacts); 

        for (Contact c : actualContacts) {
            System.assertEquals(defaultAddress.Id, c.Current_Address__c);
        }     
    }

    /*********************************************************************************************************
    @description
        Add a new Contact into the Household and remove a Contact from the Household.
    verify:
        The new Contact is added to the Household.
        A new Household and an Address are created for the Removed Contact.
        No Household is merged.
    **********************************************************************************************************/ 
    private static testMethod void saveShouldAddRemovedContactToNewHousehold() {
        Integer accountSize = 2;
        Account[] accounts = buildAccounts(accountSize);
        insert accounts;

        Address__c[] addresses = buildAddresses(accounts);
        insert addresses;

        Integer contactsPerAccount = 2;
        insert buildContacts(accounts, contactsPerAccount);

        //Refresh the Household data from database
        accounts[0] = (Account) HH_Container_LCTRL.getHH(accounts[0].Id);

        Map<Id, Contact[]> contactsByHh = getContactsByHousehold();
        System.assertEquals(accountSize, contactsByHh.size());

        Contact[] hhContacts = new Contact[] { contactsByHh.get(accounts[0].Id)[0] };

        Contact newContact = contactsByHh.get(accounts[1].Id)[0];
        newContact.AccountId = accounts[0].Id;
        copyAddressToContact(addresses[0], newContact);        
        hhContacts.add(newContact);

        Contact removedContact = contactsByHh.get(accounts[0].Id)[1];
        removedContact.AccountId = null;

        Contact[] hhContactsToRemove = new Contact[] { removedContact };
        Account[] accountsToMerge = new Account[0];

        Test.startTest();
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        HH_Container_LCTRL.saveHouseholdPage(accounts[0], hhContacts, hhContactsToRemove, accountsToMerge);
        Test.stopTest();

        //Verify a new Account and an Address have been created for the removed Contact
        Integer actualAccountSize = accountSize + 1;
        Account[] actualAccounts = getAccounts();
        System.assertEquals(actualAccountSize, actualAccounts.size(), actualAccounts);

        Address__c[] actualAddresses = getAddresses();
        System.assertEquals(actualAccountSize, actualAddresses.size(), actualAddresses);
        
        contactsByHh = getContactsByHousehold();
        System.assertEquals(actualAccountSize, contactsByHh.size(), contactsByHh); 

        for (Account acc : actualAccounts) {
            Address__c[] accountAddresses = new Address__c[0];
            for (Address__c addr : actualAddresses) {
                if (addr.Household_Account__c == acc.Id) {
                    accountAddresses.add(addr);
                }
            }

            System.assertEquals(1, accountAddresses.size(), accountAddresses);

            Contact[] contacts = contactsByHh.get(acc.Id);
            Integer expectedContactSize = acc.Id == accounts[0].Id ? 2 : 1;

            System.assertNotEquals(null, contacts);
            System.assertEquals(expectedContactSize, contacts.size());

            for (Contact c : contacts) {
                if (acc.Id == accounts[0].Id) {
                    System.assert(c.Id == hhContacts[0].Id || c.Id == hhContacts[1].Id);
                } else if (acc.Id != accounts[1].Id) {
                    System.assertEquals(removedContact.Id, c.Id);
                }
                
                System.assertEquals(accountAddresses[0].Id, c.Current_Address__c);
            }     
        } 
    }    
    
    /*********************************************************************************************************
    * @description Tests getHHNamesGreetings()
    */
    public static testMethod void testGetHHNamesGreetings() { 
        initTestData();
        list<Contact> listCon = new list<Contact>{conA, conO};
 
        Test.startTest();

        hhA = (Account)HH_Container_LCTRL.getHHNamesGreetings(hhA, listCon);
        system.assertEquals('conA and conO Household', hhA.Name);
        system.assertEquals('cA conA and cO conO', hhA.npo02__Formal_Greeting__c );
        system.assertEquals('cA and cO', hhA.npo02__Informal_Greeting__c );
        
        Test.stopTest();        
    }
    
    /*********************************************************************************************************
    * @description Tests addContactAddresses()
    */
    public static testMethod void testAddContactAddresses() { 
        
        initTestData();

        Test.startTest();
        
        list<Address__c> listAddrA = HH_Container_LCTRL.getAddresses(hhA.Id, null);
        // conA city, addr city
        system.assertEquals(2, listAddrA.size());

        list<Contact> listCon = new list<Contact>();
        for (integer i = 0; i < 5; i++) {
            Contact con = new Contact(FirstName='c'+i, LastName='con'+i, AccountId=hhA.Id, MailingCity='con' + i + ' city', MailingCountry='United States');
            listCon.add(con);
        }
        Contact conADup = new Contact(FirstName='cA', LastName='conA', AccountId=hhA.Id, MailingCity='conA city', MailingCountry='United States');
        listCon.add(conADup);       

        list<Address__c> listAddr = HH_Container_LCTRL.addContactAddresses(listCon, listAddrA);
        system.assertEquals(7, listAddr.size());
        
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Tests getSalutations()
    */
    public static testMethod void testGetSalutations() { 
        list<HH_Container_LCTRL.SelectOption> listSO = HH_Container_LCTRL.getSalutations();
        system.assert(listSO.size() > 0);
    }
    
    /*********************************************************************************************************
    * @description Tests HH_AutoCompleteDataProvider_LCTRL
    */
    public static testMethod void testAutoCompleteDataProvider() { 
        
        initTestData();

        Test.startTest();
        Test.setFixedSearchResults(new List<Id>{ conA.Id, conO.Id });
        
        list<HH_AutoCompleteDataProvider_LCTRL.ProviderResult> listPR = HH_AutoCompleteDataProvider_LCTRL.queryObjects('con', null);
        system.assertEquals(2, listPR.size());

       	list<Contact> listCon = new list<Contact>();
        listCon.add(conA);
        listCon.add(conO);
        listPR = HH_AutoCompleteDataProvider_LCTRL.queryObjects('con', listCon);
        system.assertEquals(0, listPR.size());
        
        Test.stopTest();
    }

    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Builds Accounts with Household Account Type
    * @param size Number of Accounts to build
    * @return Account[] List of Accounts
    **********************************************************************************************************/
    private static Account[] buildAccounts(Integer size) {
        Account[] accounts = new Account[0];

        for (Integer i = 0; i < size; i++) {
            accounts.add(new Account(
                Name = 'TestManageHousehold' + i,
                npe01__SYSTEM_AccountType__c = CAO_Constants.HH_ACCOUNT_TYPE
            ));
        }

        return accounts;
    }

    /*********************************************************************************************************
    * @description Builds a default Address for each Account
    * @param accounts List of Accounts to associate Addresses with
    * @return Address__c[] List of Addresses
    **********************************************************************************************************/
    private static Address__c[] buildAddresses(Account[] accounts) {
        Address__c[] addresses = new Address__c[0];

        for (Integer i = 0, size = accounts.size(); i < size; i++) {
            addresses.add(new Address__c(
                Household_Account__c = accounts[i].Id,
                Default_Address__c = true,
                MailingStreet__c = i + ' Main St',
                MailingCity__c = 'New York',
                MailingCountry__c = 'United States'
            ));
        }

        return addresses;
    }

    /*********************************************************************************************************
    * @description Builds specified number of Contacts for Accounts
    * @param accounts List of Accounts to build Contacts for
    * @param sizePerAccount Number of Contacts per Account
    * @return Contact[] List of Contacts
    **********************************************************************************************************/
    private static Contact[] buildContacts(Account[] accounts, Integer sizePerAccount) {
        Contact[] contacts = new Contact[0];

        for (Account acc : accounts) {
            for (Integer i = 0; i < sizePerAccount; i++) {
                contacts.add(new Contact(
                    LastName = acc.Name + i, 
                    AccountId = acc.Id
                ));
            }
        }

        return contacts;
    }

    /*********************************************************************************************************
    * @description Populates Contact's Mailing Address from the source Address
    * @param addr Address
    * @param c Contact
    * @return void
    **********************************************************************************************************/
    private static void copyAddressToContact(Address__c addr, Contact c) {
        c.MailingStreet = addr.MailingStreet__c;
        c.MailingCity = addr.MailingCity__c;
        c.MailingState = addr.MailingState__c;
        c.MailingPostalCode = addr.MailingPostalCode__c;
        c.MailingCountry = addr.MailingCountry__c;
    }

    /*********************************************************************************************************
    * @description Retrieves Contacts and maps Contacts to a Household
    * @return Map<Id, Contact[]> Map of Contacts by a Household
    **********************************************************************************************************/
    private static Map<Id, Contact[]> getContactsByHousehold() {
        Map<Id, Contact[]> contactsByHh = new Map<Id, Contact[]>();

        for (Contact c : getContacts()) {
            if (!contactsByHh.containsKey(c.AccountId)) {
                contactsByHh.put(c.AccountId, new Contact[0]);
            }

            contactsByHh.get(c.AccountId).add(c);
        }

        return contactsByHh;
    }

    /*********************************************************************************************************
    * @description Retrieves all Contacts with fields relevant for the Manage Household page
    * @return Contact[] List of all Contacts
    **********************************************************************************************************/
    private static Contact[] getContacts() {
        return Database.query(HH_Container_LCTRL.getContactSelectQueryWithFls());     
    }

    /*********************************************************************************************************
    * @description Retrieves all Addresses from database
    * @return Address__c[] List of all Addresses
    **********************************************************************************************************/
    private static Address__c[] getAddresses() {
        return [
            SELECT Default_Address__c, Household_Account__c, Address_Type__c,
                MailingStreet__c, MailingCity__c, MailingState__c,
                MailingPostalCode__c, MailingCountry__c
            FROM Address__c
        ];
    }

    /*********************************************************************************************************
    * @description Retrieves all Account from database
    * @return Account[] List of all Accounts
    **********************************************************************************************************/
    private static Account[] getAccounts() {
        return [
            SELECT Name, BillingStreet, BillingCity, 
                BillingState, BillingPostalCode, BillingCountry
            FROM Account
        ];
    }
}