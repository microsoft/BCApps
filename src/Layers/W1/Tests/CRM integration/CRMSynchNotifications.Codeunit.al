codeunit 139185 "CRM Synch. Notifications"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Notification]
    end;

    var
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        BothRecsChangedErr: Label 'Cannot update a record';
        CRMProductOnModifyErr: Label 'Some Error on before modification of the CRM Product.';
        ItemOnModifyErr: Label 'Some Error on before modification of the Item.';
        UnexpectedNotificationErr: Label 'Unexpected notification: %1';

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]

    [Scope('OnPrem')]
    procedure ContactCardPageShowsNotificationOnFailedSync()
    var
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        ContactCardPage: TestPage "Contact Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Contact] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        Contact.DeleteAll();
        // [GIVEN] Contact "A" coupled to a CRM Contact
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        Contact."Company No." := LibraryUtility.GenerateGUID();
        Contact.Modify();
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Contact "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Contact.RecordId, CRMContact.RecordId, ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Contact Card for "A"
        ContactCardPage.Trap();
        PAGE.Run(PAGE::"Contact Card", Contact);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Customer Card page to trigger refresh
        Assert.IsTrue(ContactCardPage.ShowLog.Enabled(), 'ShowLog action is not enabled.');
        IntegrationSynchJobListPage.Trap();
        ContactCardPage.ShowLog.Invoke();
        IntegrationSynchJobListPage.Close();
        // [THEN] Notification "Err" is not repeated
        VerifyNoNotificationSent();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ContactCardPageShowsNotificationOnFailedSyncByRefresh()
    var
        CRMContact: array[2] of Record "CRM Contact";
        Contact: array[2] of Record Contact;
        ContactCardPage: TestPage "Contact Card";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Contact] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        Contact[1].DeleteAll();
        // [GIVEN] Contacts "A" and "B" coupled to a CRM Contacts
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact[1], CRMContact[1]);
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact[2], CRMContact[2]);
        // [GIVEN] Open Contact Card for "A"
        ContactCardPage.Trap();
        PAGE.Run(PAGE::"Contact Card", Contact[1]);

        // [GIVEN] Synch. Job Error for "A" and "B" contains messages: "ErrA", "ErrB"
        // [GIVEN] CRM Integration records for Contact "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Contact[1].RecordId, CRMContact[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Contact[2].RecordId, CRMContact[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Contact "B" in the Card page
        ContactCardPage.Next();
        ContactCardPage."No.".AssertEquals(Contact[2]."No.");
        // [THEN] Notification "ErrB" shown for Contact "B"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Contact "A" in the Card page
        ContactCardPage.Previous();
        ContactCardPage."No.".AssertEquals(Contact[1]."No.");
        // [THEN] Notification "ErrA" shown for Contact "A"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ContactCardPageShowsSynchJobsForRelatedMapping()
    var
        CRMContact: Record "CRM Contact";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Contact: Record Contact;
        ContactCardPage: TestPage "Contact Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: Text;
    begin
        // [FEATURE] [Contact] [Log] [UI]
        TestInit();
        Contact.DeleteAll();
        // [GIVEN] Contact "A" coupled to CRM Contact
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        Contact."Company No." := LibraryUtility.GenerateGUID(); // to enable CRM actions
        Contact.Modify();

        // [GIVEN] 2 Synch Jobs for "CONTACT" mapping and 1 for "CUSTOMER" mapping
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Contact, '');
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Contact, Msg);
        CRMIntegrationRecord.FindByRecordID(Contact.RecordId);
        CRMIntegrationRecord."Last Synch. Job ID" := JobID[3];
        Clear(CRMIntegrationRecord."Last Synch. CRM Job ID");
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Contact Card page
        ContactCardPage.Trap();
        PAGE.Run(PAGE::"Contact Card", Contact);
        IntegrationSynchJobListPage.Trap();
        Assert.IsTrue(ContactCardPage.ShowLog.Enabled(), 'ShowLog action is not enabled.');
        ContactCardPage.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Contact "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ContactListPageShowsSynchJobsForRelatedMapping()
    var
        CRMContact: Record "CRM Contact";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Contact: Record Contact;
        ContactListPage: TestPage "Contact List";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Contact] [Log] [UI]
        TestInit();
        Contact.DeleteAll();
        // [GIVEN] Contact "A" coupled to CRM Contact
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        // [GIVEN] 2 Synch Jobs for "CUSTOMER" mapping and 1 for "CONTACT" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Contact, Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Contact, Msg[2]);
        CRMIntegrationRecord.FindByRecordID(Contact.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Contact List page
        ContactListPage.Trap();
        PAGE.Run(PAGE::"Contact List", Contact);
        IntegrationSynchJobListPage.Trap();
        ContactListPage.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Contact "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyCardPageShowsNotificationOnFailedSync()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        CurrencyCardPage: TestPage "Currency Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Currency] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        Currency.DeleteAll();
        // [GIVEN] Currency "A" coupled to a CRM Transactioncurrency
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Currency "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Currency.RecordId, CRMTransactioncurrency.RecordId, ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Currency Card for "A"
        CurrencyCardPage.Trap();
        PAGE.Run(PAGE::"Currency Card", Currency);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Currency Card page
        IntegrationSynchJobListPage.Trap();
        CurrencyCardPage.ShowLog.Invoke();
        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Currency "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(ExpectedErrorMsg);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        // [WHEN] Close Integration Synch Job List Page
        // [THEN] Notification: "Err" is not sent
        VerifyNoNotificationSent();
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyCardPageShowsNotificationOnFailedSyncByRefresh()
    var
        CRMTransactioncurrency: array[2] of Record "CRM Transactioncurrency";
        Currency: array[2] of Record Currency;
        CurrencyCardPage: TestPage "Currency Card";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Currency] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        // [GIVEN] Currencies "A" and "B"  coupled to a CRM Transactioncurrencies
        Currency[1].DeleteAll();
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency[1], CRMTransactioncurrency[1]);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency[2], CRMTransactioncurrency[2]);
        Currency[1].FindFirst();
        Currency[2].FindLast();

        // [GIVEN] Open Currency Card for "A"
        CurrencyCardPage.Trap();
        PAGE.Run(PAGE::"Currency Card", Currency[1]);

        // [GIVEN] Synch. Job Error for "A" and "B" contains the messages: "ErrA", "ErrB"
        // [GIVEN] CRM Integration record for Currency "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Currency[1].RecordId, CRMTransactioncurrency[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Currency[2].RecordId, CRMTransactioncurrency[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Currency "B" in the Card page
        CurrencyCardPage.Next();
        CurrencyCardPage.Code.AssertEquals(Currency[2].Code);
        // [THEN] Notification: "ErrB"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Currency "A" in the Card page
        CurrencyCardPage.Previous();
        CurrencyCardPage.Code.AssertEquals(Currency[1].Code);
        // [THEN] Notification: "ErrA"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyListPageShowsSynchJobsForRelatedMapping()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Currency: Record Currency;
        Currencies: TestPage Currencies;
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Currency] [Log] [UI]
        TestInit();
        Currency.DeleteAll();
        // [GIVEN] Currency "A" coupled to CRM Transactioncurrency
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);

        // [GIVEN] 2 Synch Jobs for "CURRENCY" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Currency, Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Currency, Msg[2]);
        CRMIntegrationRecord.FindByRecordID(Currency.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Currencies page
        Currencies.Trap();
        PAGE.Run(PAGE::Currencies, Currency);
        IntegrationSynchJobListPage.Trap();
        Currencies.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Currency "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerCardPageShowsNotificationOnFailedSyncForCoupledRec()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CustomerCardPage: TestPage "Customer Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        Customer.DeleteAll();
        // [GIVEN] Customer "A" coupled to a CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Customer "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMAccount.AccountId, CRMAccount.RecordId, Customer.RecordId, ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Customer Card for "A"
        CustomerCardPage.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Customer Card page to trigger refresh
        IntegrationSynchJobListPage.Trap();
        CustomerCardPage.ShowLog.Invoke();
        IntegrationSynchJobListPage.Close();
        // [THEN] Notification "Err" is not repeated
        VerifyNoNotificationSent();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerCardPageShowsNotificationOnFailedSyncForCoupledRecByRefresh()
    var
        CRMAccount: array[2] of Record "CRM Account";
        Customer: array[2] of Record Customer;
        CustomerCardPage: TestPage "Customer Card";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        Customer[1].DeleteAll();
        // [GIVEN] Customers "A" and "B" coupled to a CRM Accounts
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[1], CRMAccount[1]);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[2], CRMAccount[2]);
        // [GIVEN] Open Customer Card for "A"
        CustomerCardPage.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer[1]);

        // [GIVEN] Synch. Job Error for "A" and "B" contains the messages: "ErrA", "ErrB"
        // [GIVEN] CRM Integration record for Customers "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer[1].RecordId, CRMAccount[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer[2].RecordId, CRMAccount[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Customer "B" in the Card page
        CustomerCardPage.Next();
        CustomerCardPage."No.".AssertEquals(Customer[2]."No.");
        // [THEN] Notification: "ErrB"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Customer "A" in the Card page
        CustomerCardPage.Previous();
        CustomerCardPage."No.".AssertEquals(Customer[1]."No.");
        // [THEN] Notification: "ErrA"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerCardPageShowsNotificationOnFailedSyncForUncoupledRec()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CustomerCardPage: TestPage "Customer Card";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] Notification should be shown on Card page opening, if the record has failed the initial sync.
        TestInit();
        Customer.DeleteAll();
        // [GIVEN] Customer "A" coupled to a CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer.RecordId, CRMAccount.RecordId, ExpectedErrorMsg, CurrentDateTime, false);
        // [GIVEN] CRM Integration record for Customer "A" does not exist
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.Delete();

        // [WHEN] Open Customer Card for "A"
        CustomerCardPage.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerCardPageShowsNoNotificationAfterSuccessfulSync()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CustomerCardPage: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [UI]
        TestInit();
        Customer.DeleteAll();
        // [GIVEN] Customer "A" coupled to a CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] CRM Integration record for Customer "A" marked as successful
        LibraryCRMIntegration.MockSuccessSynchToCRMIntegrationRecord(Customer.RecordId, '');
        // [WHEN] Open Customer Card for "A"
        CustomerCardPage.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);

        // [THEN] The page is open for "A" and there is no notification
        CustomerCardPage."No.".AssertEquals(Customer."No.");
        // as no NotificationHandler assigned
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerCardPageShowsSynchJobsForRelatedMapping()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CustomerCardPage: TestPage "Customer Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Customer] [Log] [UI]
        TestInit();
        Customer.DeleteAll();
        // [GIVEN] Customer "A" coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] 2 related Synch Jobs for "CUSTOMER" mapping and 1 not related
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, Msg[2]);
        // [GIVEN] Existing jobs are not related to "A"
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord."Last Synch. Job ID" := JobID[1];
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[3];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Customer Card page
        CustomerCardPage.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);
        IntegrationSynchJobListPage.Trap();
        CustomerCardPage.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where are 2 jobs for "CUSTOMER"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Next();
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 2 records in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerListPageShowsSynchJobsForRelatedMapping()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CustomerListPage: TestPage "Customer List";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[3] of Text;
        i: Integer;
    begin
        // [FEATURE] [Customer] [Log] [UI]
        TestInit();
        Customer.DeleteAll();
        // [GIVEN] Customer "A" coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] 3 Synch Jobs for "CUSTOMER" mapping not related to Customer "A", 1 job for "CONTACT"
        for i := 1 to 3 do
            Msg[i] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, Msg[1]);
        LibraryCRMIntegration.MockSyncJob(DATABASE::Contact, '');
        Sleep(5);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, Msg[2]);
        Sleep(5);
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, Msg[3]);
        // [GIVEN] Last Synch. Jobs are not defined
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        Clear(CRMIntegrationRecord."Last Synch. CRM Job ID");
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Customer List page
        CustomerListPage.Trap();
        PAGE.Run(PAGE::"Customer List", Customer);
        IntegrationSynchJobListPage.Trap();
        CustomerListPage.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where are 3 jobs for "CUSTOMER", sorted by "Start Date/Time"
        Assert.IsTrue(IntegrationSynchJobListPage.First(), 'there should be first job in the list.');
        IntegrationSynchJobListPage.Next();
        IntegrationSynchJobListPage.Next();
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'there should be three jobs in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CustomerPriceGroupsPageShowsSynchJobsForRelatedMapping()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerPriceGroups: TestPage "Customer Price Groups";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Customer Price Group] [Log] [UI]
        TestInit();
        CustomerPriceGroup.DeleteAll();
        // [GIVEN] Customer Price Group "A" coupled to CRM Pricelevel
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(
          CustomerPriceGroup, CRMPricelevel);

        // [GIVEN] 2 Synch Jobs for "CUSTPRCGRP-PRICE" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Customer Price Group", Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Customer Price Group", Msg[2]);
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Customer Price Groups page
        CustomerPriceGroups.Trap();
        PAGE.Run(PAGE::"Customer Price Groups", CustomerPriceGroup);
        IntegrationSynchJobListPage.Trap();
        CustomerPriceGroups.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Customer Price Group "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemCardPageShowsNotificationOnFailedSync()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        ItemCardPage: TestPage "Item Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Item] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        Item.DeleteAll();
        // [GIVEN] Item "A" coupled to a CRM Product
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Item "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Item.RecordId, CRMProduct.RecordId, ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Item Card for "A"
        ItemCardPage.Trap();
        PAGE.Run(PAGE::"Item Card", Item);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Item Card page
        IntegrationSynchJobListPage.Trap();
        ItemCardPage.ShowLog.Invoke();
        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Item "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(ExpectedErrorMsg);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        // [WHEN] Close Integration Synch Job List Page
        // [THEN] Notification: "Err" is not sent
        VerifyNoNotificationSent();
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemCardPageShowsNotificationOnFailedSyncByRefresh()
    var
        CRMProduct: array[2] of Record "CRM Product";
        Item: array[2] of Record Item;
        ItemCardPage: TestPage "Item Card";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Item] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        Item[1].DeleteAll();
        // [GIVEN] Items "A" and "B" coupled to CRM Products
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[1], CRMProduct[2]);
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[2], CRMProduct[2]);
        // [GIVEN] Open Item Card for "A"
        ItemCardPage.Trap();
        PAGE.Run(PAGE::"Item Card", Item[1]);
        // [GIVEN] Synch. Job Error for "A" and "B" contains the message: "ErrA", "ErrB"
        // [GIVEN] CRM Integration record for Items "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Item[1].RecordId, CRMProduct[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Item[2].RecordId, CRMProduct[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Item "B" in the Card page
        ItemCardPage.Next();
        ItemCardPage."No.".AssertEquals(Item[2]."No.");
        // [THEN] Notification: "ErrB"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Item "A" in the Card page
        ItemCardPage.Previous();
        ItemCardPage."No.".AssertEquals(Item[1]."No.");
        // [THEN] Notification: "ErrA"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemCardPageIsNotShowNotificationOnDeletedFailedSyncToCRM()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        ItemCardPage: TestPage "Item Card";
        SyncJobId: Guid;
    begin
        // [FEATURE] [Item] [UI]
        // [SCENARIO 257616] Notification should not be shown on Card page openning, if item is coupled, has failed the last sync and Integration Synch. Job entry is deleted.
        TestInit();
        Item.DeleteAll();
        // [GIVEN] Item "A" coupled to a CRM Product
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] CRM Integration record for Item "A" marked as failed
        SyncJobId :=
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Item.RecordId, CRMProduct.RecordId, '', CurrentDateTime, false);
        // [GIVEN] Integration Synch. Job entry deleted
        IntegrationSynchJob.Get(SyncJobId);
        IntegrationSynchJob.Delete();

        // [WHEN] Open Item Card for "A"
        ItemCardPage.Trap();
        PAGE.Run(PAGE::"Item Card", Item);

        // [THEN] No error sync notification (no any notification handlers)
        ItemCardPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ItemCardPageIsNotShowNotificationOnDeletedFailedSyncToNAV()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        ItemCardPage: TestPage "Item Card";
        SyncJobId: Guid;
    begin
        // [FEATURE] [Item] [UI]
        // [SCENARIO 257616] Notification should not be shown on Card page openning, if item is coupled, has failed the last sync and Integration Synch. Job entry is deleted.
        TestInit();
        Item.DeleteAll();
        // [GIVEN] Item "A" coupled to a CRM Product
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] CRM Integration record for Item "A" marked as failed
        SyncJobId :=
          LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
            CRMProduct.ProductId, CRMProduct.RecordId, Item.RecordId, '', CurrentDateTime, false);
        // [GIVEN] Integration Synch. Job entry deleted
        IntegrationSynchJob.Get(SyncJobId);
        IntegrationSynchJob.Delete();

        // [WHEN] Open Item Card for "A"
        ItemCardPage.Trap();
        PAGE.Run(PAGE::"Item Card", Item);

        // [THEN] No error sync notification (no any notification handlers)
        ItemCardPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemListPageShowsSynchJobsForRelatedMapping()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        CRMIntegrationRecord: Record "CRM Integration Record";
        ItemListPage: TestPage "Item List";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Item] [Log] [UI]
        TestInit();
        Item.DeleteAll();
        // [GIVEN] Item "A" coupled to a CRM Product
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);

        // [GIVEN] 2 Synch Jobs for "ITEM-PRODUCT" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Item, Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Item, Msg[2]);
        CRMIntegrationRecord.FindByRecordID(Item.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Item List page
        ItemListPage.Trap();
        PAGE.Run(PAGE::"Item List", Item);
        IntegrationSynchJobListPage.Trap();
        ItemListPage.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Item "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResourceCardPageShowsNotificationOnFailedSync()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        ResourceCardPage: TestPage "Resource Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Resource] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        Resource.DeleteAll();
        // [GIVEN] Resource "A" coupled to a CRM Product
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Resource "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Resource.RecordId, CRMProduct.RecordId, ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Resource Card for "A"
        ResourceCardPage.Trap();
        PAGE.Run(PAGE::"Resource Card", Resource);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Resource Card page
        IntegrationSynchJobListPage.Trap();
        ResourceCardPage.ShowLog.Invoke();
        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Resource "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(ExpectedErrorMsg);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        // [WHEN] Close Integration Synch Job List Page
        // [THEN] Notification: "Err" is not sent
        VerifyNoNotificationSent();
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResourceCardPageShowsNotificationOnFailedSyncByRefresh()
    var
        CRMProduct: array[2] of Record "CRM Product";
        Resource: array[2] of Record Resource;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ResourceCardPage: TestPage "Resource Card";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Resource] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        LibraryApplicationArea.EnableJobsSetup();
        // [GIVEN] Resourcea "A" and "B" coupled to CRM Products
        Resource[1].DeleteAll();
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource[1], CRMProduct[1]);
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource[2], CRMProduct[2]);
        // [GIVEN] Open Resource Card for "A"
        ResourceCardPage.Trap();
        PAGE.Run(PAGE::"Resource Card", Resource[1]);

        // [GIVEN] Synch. Job Error for "A" and "B" contains the message: "ErrA", "ErrB"
        // [GIVEN] CRM Integration record for Resources "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Resource[1].RecordId, CRMProduct[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Resource[2].RecordId, CRMProduct[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Resource "B" in the Card page
        ResourceCardPage.Next();
        ResourceCardPage."No.".AssertEquals(Resource[2]."No.");
        // [THEN] Notification: "ErrB"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Resource "A" in the Card page
        ResourceCardPage.Previous();
        ResourceCardPage."No.".AssertEquals(Resource[1]."No.");
        // [THEN] Notification: "ErrA"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ResourceListPageShowsSynchJobsForRelatedMapping()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        CRMIntegrationRecord: Record "CRM Integration Record";
        ResourceListPage: TestPage "Resource List";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Resource] [Log] [UI]
        TestInit();
        Resource.DeleteAll();
        // [GIVEN] Resource "A" coupled to a CRM Product
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);

        // [GIVEN] 2 Synch Jobs for "RESOURCE-PRODUCT" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::Resource, Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::Resource, Msg[2]);
        CRMIntegrationRecord.FindByRecordID(Resource.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Resource List page
        ResourceListPage.Trap();
        PAGE.Run(PAGE::"Resource List", Resource);
        IntegrationSynchJobListPage.Trap();
        ResourceListPage.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Resource "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceCardPageShowsNotificationOnFailedSync()
    var
        CRMInvoice: Record "CRM Invoice";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        SalesInvoiceHeader.DeleteAll();
        // [GIVEN] Sales Invoice "A" coupled to a CRM Invoice
        CreateCoupledSalesInvoiceAndCRMInvoice(SalesInvoiceHeader, CRMInvoice);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Invoice "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          SalesInvoiceHeader.RecordId, CRMInvoice.RecordId, ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Sales Invoice Card for "A"
        PostedSalesInvoicePage.Trap();
        PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvoiceHeader);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Sales Invoice Card page
        IntegrationSynchJobListPage.Trap();
        PostedSalesInvoicePage.ShowLog.Invoke();
        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Sales Invoice "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(ExpectedErrorMsg);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        // [WHEN] Close Integration Synch Job List Page
        // [THEN] Notification: "Err" is not sent
        VerifyNoNotificationSent();
        IntegrationSynchJobListPage.Close();
        PostedSalesInvoicePage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceCardPageShowsNotificationOnFailedSyncByRefresh()
    var
        CRMInvoice: array[2] of Record "CRM Invoice";
        SalesInvoiceHeader: array[2] of Record "Sales Invoice Header";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        SalesInvoiceHeader[1].DeleteAll();
        // [GIVEN] Sales Invoice "A" and "B" coupled to CRM Invoices
        CreateCoupledSalesInvoiceAndCRMInvoice(SalesInvoiceHeader[1], CRMInvoice[1]);
        CreateCoupledSalesInvoiceAndCRMInvoice(SalesInvoiceHeader[2], CRMInvoice[2]);
        // [GIVEN] Open Sales Invoice Card for "A"
        PostedSalesInvoicePage.Trap();
        PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvoiceHeader[1]);
        // [GIVEN] Synch. Job Error for "A" and "B" contains the message: "ErrA", "ErrB".
        // [GIVEN] CRM Integration record for Invoices "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          SalesInvoiceHeader[1].RecordId, CRMInvoice[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          SalesInvoiceHeader[2].RecordId, CRMInvoice[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Sales Invoice "B" in the Card page
        PostedSalesInvoicePage.Next();
        PostedSalesInvoicePage."No.".AssertEquals(SalesInvoiceHeader[2]."No.");
        // [THEN] Notification: "ErrB"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Sales Invoice "A" in the Card page
        PostedSalesInvoicePage.Previous();
        PostedSalesInvoicePage."No.".AssertEquals(SalesInvoiceHeader[1]."No.");
        // [THEN] Notification: "ErrA"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
        PostedSalesInvoicePage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesInvoiceListPageShowsSynchJobsForRelatedMapping()
    var
        CRMInvoice: Record "CRM Invoice";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Sales] [Invoice] [Log] [UI]
        TestInit();
        SalesInvoiceHeader.DeleteAll();
        // [GIVEN] Sales Invoice "A" coupled to a CRM Invoice
        CreateCoupledSalesInvoiceAndCRMInvoice(SalesInvoiceHeader, CRMInvoice);

        // [GIVEN] 2 Synch Jobs for "POSTEDSALESINV-INV" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Sales Invoice Header", Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Sales Invoice Header", Msg[2]);
        CRMIntegrationRecord.FindByRecordID(SalesInvoiceHeader.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Posted Sales Invoices page
        PostedSalesInvoices.OpenView();
        PostedSalesInvoices.GotoRecord(SalesInvoiceHeader);
        IntegrationSynchJobListPage.Trap();
        PostedSalesInvoices.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Sales Invoice "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalespersonCardPageShowsNotificationOnFailedSync()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonPurchaserCardPage: TestPage "Salesperson/Purchaser Card";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        ExpectedErrorMsg: Text;
    begin
        // [FEATURE] [Salesperson] [UI]
        // [SCENARIO] Notification should be shown on Card page openning, if the record is coupled but has failed the last sync.
        TestInit();
        SalespersonPurchaser.DeleteAll();
        // [GIVEN] Salesperson "A" coupled to a CRM Systemuser
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Synch. Job Error for "A" contains the message: "Err"
        // [GIVEN] CRM Integration record for Salesperson "A" marked as failed
        ExpectedErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMSystemuser.SystemUserId, CRMSystemuser.RecordId, SalespersonPurchaser.RecordId,
          ExpectedErrorMsg, CurrentDateTime, false);

        // [WHEN] Open Salesperson/Purchaser Card for "A"
        SalespersonPurchaserCardPage.Trap();
        PAGE.Run(PAGE::"Salesperson/Purchaser Card", SalespersonPurchaser);

        // [THEN] Notification: "Err"
        VerifyNotificationMessage(ExpectedErrorMsg);

        // [WHEN] Run "Synchronization Log" action in Salesperson/Purchaser Card page
        IntegrationSynchJobListPage.Trap();
        SalespersonPurchaserCardPage.ShowLog.Invoke();
        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Salesperson/Purchaser "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(ExpectedErrorMsg);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        // [WHEN] Close Integration Synch Job List Page
        // [THEN] Notification: "Err" is not sent
        VerifyNoNotificationSent();
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalespersonCardPageShowsNotificationOnFailedSyncByRefresh()
    var
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        SalespersonPurchaserCardPage: TestPage "Salesperson/Purchaser Card";
        ExpectedErrorMsg: array[2] of Text;
    begin
        // [FEATURE] [Salesperson] [UI]
        // [SCENARIO] Notification should be shown on Card page refresh, if the record is coupled but has failed the last sync.
        TestInit();
        SalespersonPurchaser[1].DeleteAll();
        // [GIVEN] Salespersons "A" and "B" coupled to CRM Systemusers
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[1], CRMSystemuser[1]);
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[2], CRMSystemuser[2]);
        // [GIEN] Open Salesperson/Purchaser Card for "A"
        SalespersonPurchaserCardPage.Trap();
        PAGE.Run(PAGE::"Salesperson/Purchaser Card", SalespersonPurchaser[1]);
        // [GIVEN] Synch. Job Error for "A" and "B" contains the message: "ErrA", "ErrB"
        // [GIVEN] CRM Integration record for Salesperson "A" and "B" marked as failed
        ExpectedErrorMsg[1] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMSystemuser[1].SystemUserId, CRMSystemuser[1].RecordId,
          SalespersonPurchaser[1].RecordId, ExpectedErrorMsg[1], CurrentDateTime, false);
        ExpectedErrorMsg[2] := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMSystemuser[2].SystemUserId, CRMSystemuser[2].RecordId,
          SalespersonPurchaser[2].RecordId, ExpectedErrorMsg[2], CurrentDateTime, false);

        // [WHEN] Move to Salesperson "B" in the Card page
        SalespersonPurchaserCardPage.Next();
        SalespersonPurchaserCardPage.Code.AssertEquals(SalespersonPurchaser[2].Code);
        // [THEN] Notification: "ErrB"
        VerifyNotificationMessage(ExpectedErrorMsg[2]);

        // [WHEN] Move back to Salesperson "A" in the Card page
        SalespersonPurchaserCardPage.Previous();
        SalespersonPurchaserCardPage.Code.AssertEquals(SalespersonPurchaser[1].Code);
        // [THEN] Notification: "ErrA"
        VerifyNotificationMessage(ExpectedErrorMsg[1]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalespersonListPageShowsSynchJobsForRelatedMapping()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalespersonsPurchasers: TestPage "Salespersons/Purchasers";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Salesperson] [Log] [UI]
        TestInit();
        SalespersonPurchaser.DeleteAll();
        // [GIVEN] Salesperson "A" coupled to a CRM Systemuser
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] 2 Synch Jobs for "SALESPEOPLE" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Salesperson/Purchaser", Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Salesperson/Purchaser", Msg[2]);
        CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Salespersons/Purchasers page
        SalespersonsPurchasers.Trap();
        PAGE.Run(PAGE::"Salespersons/Purchasers", SalespersonPurchaser);
        IntegrationSynchJobListPage.Trap();
        SalespersonsPurchasers.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Salesperson/Purchaser "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UnitsOfMeasurePageShowsSynchJobsForRelatedMapping()
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        UnitOfMeasure: Record "Unit of Measure";
        CRMIntegrationRecord: Record "CRM Integration Record";
        UnitsofMeasure: TestPage "Units of Measure";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        Msg: array[2] of Text;
    begin
        // [FEATURE] [Unit Of Measure] [Log] [UI]
        TestInit();
        UnitOfMeasure.DeleteAll();
        // [GIVEN] Unit Of Measure "A" coupled to a CRM Uomschedule
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(
          UnitOfMeasure, CRMUom, CRMUomschedule);

        // [GIVEN] 2 Synch Jobs for "UNIT OF MEASURE" mapping and 1 for "CUSTOMER" mapping
        Msg[1] := LibraryUtility.GenerateGUID();
        JobID[1] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Unit of Measure", Msg[1]);
        JobID[2] := LibraryCRMIntegration.MockSyncJob(DATABASE::Customer, '');
        Sleep(5); // delay to split jobs by time
        Msg[2] := LibraryUtility.GenerateGUID();
        JobID[3] := LibraryCRMIntegration.MockSyncJob(DATABASE::"Unit of Measure", Msg[2]);
        CRMIntegrationRecord.FindByRecordID(UnitOfMeasure.RecordId);
        Clear(CRMIntegrationRecord."Last Synch. Job ID");
        CRMIntegrationRecord."Last Synch. CRM Job ID" := JobID[1];
        CRMIntegrationRecord.Modify();

        // [WHEN] Run "Synchronization Log" action in Units Of Measure page
        UnitsofMeasure.Trap();
        PAGE.Run(PAGE::"Units of Measure", UnitOfMeasure);
        IntegrationSynchJobListPage.Trap();
        UnitsofMeasure.ShowLog.Invoke();

        // [THEN] "Integration Synch. Job List" page open, where is 1 job related to Unit Of Measure "A"
        IntegrationSynchJobListPage.First();
        IntegrationSynchJobListPage.Message.AssertEquals(Msg[1]);
        Assert.IsFalse(IntegrationSynchJobListPage.Next(), 'There should be 1 record in the list.');
        IntegrationSynchJobListPage.Close();
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SendResultNotificationSendsNotificationEvenForWrongDirection()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ExpectedMessage: Text;
    begin
        // [FEATURE] [UT]
        TestInit();
        ClearCustomerContactBusRel();
        // [GIVEN] Customer is coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Sync job, where "Direction" is 'FromIntegrationTable'
        // [GIVEN] CRM Integration record for Customer "A" marked as failed with error 'Err'
        ExpectedMessage := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMAccount.AccountId, CRMAccount.RecordId, Customer.RecordId, ExpectedMessage, CurrentDateTime, false);

        // [WHEN] SendResultNotification() for Customer
        Assert.IsTrue(CRMIntegrationManagement.SendResultNotification(Customer), 'Should be notification.');

        // [THEN] Notification is shown: 'Err'
        VerifyNotificationMessage(ExpectedMessage);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SendResultNotificationSendsNoNotificationIfSuccessJobIsTheLast()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Failure notification is not shown for bidirectional table if the last job is successful
        TestInit();
        ClearCustomerContactBusRel();
        // [GIVEN] Customer is coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Successful Sync job, where "Direction" is 'ToIntegrationTable'
        LibraryCRMIntegration.MockSuccessSynchToCRMIntegrationRecord(Customer.RecordId, '');
        // [GIVEN] Failed Sync job, where "Direction" is 'FromIntegrationTable'
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMAccount.AccountId, CRMAccount.RecordId, Customer.RecordId, LibraryUtility.GenerateGUID(), CurrentDateTime, false);
        // [GIVEN] "Last Synch. CRM Modified On" is later than "Last Synch. Modified On"
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMIntegrationRecord."Last Synch. Modified On" + 1000;
        CRMIntegrationRecord.Modify();

        // [WHEN] SendResultNotification() for Customer
        Assert.IsFalse(CRMIntegrationManagement.SendResultNotification(Customer), 'Should be no notification.');

        // [THEN] No notification is sent
        // as no NotificationHandler assigned
    end;

    [Test]
    [HandlerFunctions('FailedSyncNotification,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SendResultNotificationSendsFailureNotificationIfFailedJobIsTheLast()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ErrorMsg: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Failure notification is shown for bidirectional table if the last job is failed
        TestInit();
        ClearCustomerContactBusRel();
        // [GIVEN] Customer is coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Successful Sync job, where "Direction" is 'ToIntegrationTable'
        LibraryCRMIntegration.MockSuccessSynchToCRMIntegrationRecord(Customer.RecordId, '');
        // [GIVEN] Failed Sync job, where "Direction" is 'FromIntegrationTable'
        ErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMAccount.AccountId, CRMAccount.RecordId, Customer.RecordId, ErrorMsg, CurrentDateTime, false);
        // [GIVEN] "Last Synch. Modified On" is later than "Last Synch. CRM Modified On"
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMIntegrationRecord."Last Synch. Modified On" - 1000;
        CRMIntegrationRecord.Modify();

        // [WHEN] SendResultNotification() for Customer
        Assert.IsTrue(CRMIntegrationManagement.SendResultNotification(Customer), 'Should be a notification.');

        // [THEN] Failure notification is shown
        VerifyNotificationMessage(ErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncToCRMFailedOnModifyMarkedCRMIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CRMSynchNotifications: Codeunit "CRM Synch. Notifications";
        OldName: Text;
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        OldName := CRMProduct.Name;
        VerifyLastSynchDataIsBlank(Item.RecordId);

        // [GIVEN] Item Description modified to 'D'
        Sleep(200);
        Item.Description := LibraryUtility.GenerateGUID();
        Item.Modify();

        BindSubscription(CRMSynchNotifications); // to throw an error OnBeforeModify CRM Product

        // [WHEN] Sync Item
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, true, false);

        // [THEN] Coupled CRM Product Name is not changed
        CRMProduct.Find();
        CRMProduct.TestField(Name, OldName);

        // [THEN] CRM Integration Record, where "Last Synch. CRM Job ID" is set, "Last Synch. CRM Result" is 'Failure'
        // [THEN] Integration Synch. Job, where "Modified" = 0, "Failed" = 1, Mapping Name = 'ITEM-PRODUCT'
        // [THEN] Error message: 'Error on CRM Product OnModify'
        VerifyFailedToCRMJob(Item, IntegrationTableMapping.Name, CRMProductOnModifyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncFromCRMFailedOnModifyMarkedCRMIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CRMSynchNotifications: Codeunit "CRM Synch. Notifications";
        OldName: Text;
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        OldName := Item.Description;
        VerifyLastSynchDataIsBlank(Item.RecordId);

        // [GIVEN] CRM Product Name modified to 'D'
        CRMProduct.Name := LibraryUtility.GenerateGUID();
        CRMProduct.ModifiedOn := CurrentDateTime + 1000;
        CRMProduct.Modify();

        BindSubscription(CRMSynchNotifications); // to throw an error OnBeforeModify Item

        // [WHEN] Sync Item
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled CRM Product Name is not changed
        Item.Find();
        Item.TestField(Description, OldName);

        // [THEN] CRM Integration Record, where "Last Synch. CRM Job ID" is set, "Last Synch. CRM Result" is 'Failure'
        // [THEN] Integration Synch. Job, where "Modified" = 0, "Failed" = 1, Mapping Name = 'ITEM-PRODUCT'
        // [THEN] Error message: 'Error on Item OnModify'
        VerifyFailedFromCRMJob(Item, IntegrationTableMapping.Name, ItemOnModifyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncToCRMSuccessMarkedCRMIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        VerifyLastSynchDataIsBlank(Item.RecordId);

        // [GIVEN] Item Description modified to 'D'
        Item.Description := LibraryUtility.GenerateGUID();
        Sleep(200);
        Item.Modify();

        // [WHEN] Sync Item
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, true, false);

        // [THEN] Coupled CRM Product Name is set to 'D'
        CRMProduct.Find();
        CRMProduct.TestField(Name, Item.Description);
        // [THEN] CRM Integration Record, where "Last Synch. CRM Job ID" is set, "Last Synch. CRM Result" is 'Success'
        // [THEN] Integration Synch. Job, where Modified = 1, Failed = 0, Mapping Name = 'ITEM-PRODUCT',Direction = ToIntegrationTable
        VerifySuccessfulToCRMJob(Item.RecordId, IntegrationTableMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncFromCRMSuccessMarkedCRMIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        VerifyLastSynchDataIsBlank(Item.RecordId);

        // [GIVEN] CRM Product Name modified to 'D'
        CRMProduct.Name := LibraryUtility.GenerateGUID();
        CRMProduct.ModifiedOn := CurrentDateTime + 1000;
        CRMProduct.Modify();

        // [WHEN] Sync Item
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Item Description is set to 'D'
        Item.Find();
        Item.TestField(Description, CRMProduct.Name);
        // [THEN] CRM Integration Record, where "Last Synch. Job ID" is set, "Last Synch. Result" is 'Success'
        // [THEN] Integration Synch. Job, where Modified = 1, Failed = 0, Mapping Name = 'ITEM-PRODUCT',Direction = FromIntegrationTable
        VerifySuccessfulFromCRMJob(Item.RecordId, IntegrationTableMapping);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncFailedBothRecsChangedMarkedCRMIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] CRM Product Name modified to 'D2'
        CRMProduct.Name := LibraryUtility.GenerateGUID();
        CRMProduct.ModifiedOn := CurrentDateTime + 1000;
        CRMProduct.Modify();
        // [GIVEN] Item Description modified to 'D1'
        Item.Description := LibraryUtility.GenerateGUID();
        Sleep(1000);
        Item.Modify();

        // [WHEN] Sync Item
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, false, false);

        // [THEN] CRM Integration Record, where "Last Synch. CRM Job ID" is set, "Last Synch. CRM Result" is 'Failure'
        // [THEN] Integration Synch. Job, where "Modified" = 0, "Failed" = 1, Mapping Name = 'ITEM-PRODUCT'
        // [THEN] Error message: 'Cannot update bacause both have been changed'
        VerifyFailedToCRMJob(Item, IntegrationTableMapping.Name, BothRecsChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncUnchangedDestRecChangedLaterMarkedCRMIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] CRM Product Name modified to 'D2'
        CRMProduct.Name := LibraryUtility.GenerateGUID();
        CRMProduct.ModifiedOn := CurrentDateTime + 3000;
        CRMProduct.Modify();

        // [WHEN] Sync Item to Product
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, false, false);

        // [THEN] CRM Integration Record, where "Last Synch. CRM Job ID" is <blank>
        // [THEN] Integration Synch. Job, where "Modified" = 0, "Failed" = 0, Unchanged = 1, Mapping Name = 'ITEM-PRODUCT'
        VerifyUnchangedToCRMJob(Item.RecordId, IntegrationTableMapping, IntegrationTableMapping.Direction::ToIntegrationTable);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncUnchangedDestRecChangedLaterMarkedIntegrationRec()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Last Synch. Job] [UT]
        TestInit();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Item Description modified to 'D1'
        Item.Description := LibraryUtility.GenerateGUID();
        Sleep(200);
        Item.Modify();

        // [WHEN] Sync Product to Item
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, false, false);

        // [THEN] CRM Integration Record, where "Last Synch. Job ID" is <blank>
        // [THEN] Integration Synch. Job, where "Modified" = 0, "Failed" = 0, Unchanged = 1, Mapping Name = 'ITEM-PRODUCT'
        VerifyUnchangedToCRMJob(Item.RecordId, IntegrationTableMapping, IntegrationTableMapping.Direction::FromIntegrationTable);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DependentTableIsNotMarkedAsFailed()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvoiceLine: Record "Sales Invoice Line";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        SourceRecordRef: RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Coupled Sales Invoice Line should not get markers regarding the last synch. job.
        TestInit();
        // [GIVEN] Sales Invoice Line is coupled to CRM Sales Invoice Line
        SalesInvoiceLine.Init();
        SalesInvoiceLine.Insert();
        SourceRecordRef.GetTable(SalesInvoiceLine);
        IntegrationTableMapping.SetRange("Table ID", SourceRecordRef.Number);
        IntegrationTableMapping.FindFirst();

        CRMIntegrationRecord.CoupleRecordIdToCRMID(SourceRecordRef.RecordId, CreateGuid());
        // [GIVEN] CRM Integration Record does not have data on last synch. jobs
        VerifyLastSynchDataIsBlank(SourceRecordRef.RecordId);

        // [WHEN] run MarkIntegrationRecordAsFailed() for Sales Invoice Line
        IntegrationRecSynchInvoke.MarkIntegrationRecordAsFailed(
          IntegrationTableMapping, SourceRecordRef, CreateGuid(), TABLECONNECTIONTYPE::CRM);

        // [THEN] CRM Integration Record is not updated
        VerifyLastSynchDataIsBlank(SourceRecordRef.RecordId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetErrorForRecordReturnsLastError()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        DummyEmptyRecID: RecordID;
        Msg: array[3] of Text;
    begin
        // [FEATURE] [UT]
        TestInit();
        // [GIVEN] Currency 'X' could not be synched to CRMTransactioncurrency
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // [GIVEN] Synch Job Error, where Message = 'Err1', Destination RecordID is set
        Msg[1] := LibraryUtility.GenerateGUID();
        IntegrationSynchJob.Get(
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Currency.RecordId, CRMTransactioncurrency.RecordId, Msg[1], CurrentDateTime, false));
        IntegrationSynchJob.GetErrorForRecordID(Currency.RecordId, IntegrationSynchJobErrors);
        Assert.AreEqual(Msg[1], IntegrationSynchJobErrors.Message, '#1');
        // [GIVEN] Synch Job Error, where Message = 'Err2', Destination RecordID is not set
        Msg[2] := LibraryUtility.GenerateGUID();
        IntegrationSynchJob.Get(
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Currency.RecordId, DummyEmptyRecID, Msg[2], CurrentDateTime, false));
        IntegrationSynchJob.GetErrorForRecordID(Currency.RecordId, IntegrationSynchJobErrors);
        Assert.AreEqual(Msg[2], IntegrationSynchJobErrors.Message, '#2');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetErrorForIntRecordReturnsLastError()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        DummyEmptyRecID: RecordID;
        Msg: array[3] of Text;
    begin
        // [FEATURE] [UT]
        TestInit();
        // [GIVEN] Currency 'X' coupled to CRMTransactioncurrency
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // [GIVEN] Synch Job Error, where Message = 'Err1', Destination RecordID is set
        Msg[1] := LibraryUtility.GenerateGUID();
        IntegrationSynchJob.Get(
          LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
            CRMTransactioncurrency.TransactionCurrencyId, CRMTransactioncurrency.RecordId,
            Currency.RecordId, Msg[1], CurrentDateTime, false));
        IntegrationSynchJob.GetErrorForRecordID(CRMTransactioncurrency.RecordId, IntegrationSynchJobErrors);
        Assert.AreEqual(Msg[1], IntegrationSynchJobErrors.Message, '#1');
        // [GIVEN] Synch Job Error, where Message = 'Err2', Destination RecordID is not set
        Msg[2] := LibraryUtility.GenerateGUID();
        IntegrationSynchJob.Get(
          LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
            CRMTransactioncurrency.TransactionCurrencyId, CRMTransactioncurrency.RecordId,
            DummyEmptyRecID, Msg[2], CurrentDateTime, false));
        IntegrationSynchJob.GetErrorForRecordID(CRMTransactioncurrency.RecordId, IntegrationSynchJobErrors);
        Assert.AreEqual(Msg[2], IntegrationSynchJobErrors.Message, '#2');
    end;

    local procedure TestInit()
    var
        RecordLink: Record "Record Link";
        MyNotifications: Record "My Notifications";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        // Enable CRM Integration with Integration Table Mappings
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        ResetDefaultCRMSetupConfiguration();

        RecordLink.DeleteAll();

        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
    end;

    local procedure CreateCoupledAndActiveItemAndProduct(var Item: Record Item; var CRMProduct: Record "CRM Product")
    begin
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);
    end;

    local procedure CreateCoupledSalesInvoiceAndCRMInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var CRMInvoice: Record "CRM Invoice")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert(true);

        CRMInvoice.Init();
        CRMInvoice.InvoiceId := CreateGuid();
        CRMInvoice.Insert();

        CRMIntegrationRecord.CoupleRecordIdToCRMID(SalesInvoiceHeader.RecordId, CRMInvoice.InvoiceId);
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure VerifyFailedToCRMJob(Item: Record Item; IntegrationTableMappingName: Text; ErrorMessage: Text)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(Item.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Job ID");
        CRMIntegrationRecord.TestField(
          "Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Failure);

        VerifyFailedJob(CRMIntegrationRecord."Last Synch. CRM Job ID", Item, IntegrationTableMappingName, ErrorMessage);
    end;

    local procedure VerifyFailedFromCRMJob(Item: Record Item; IntegrationTableMappingName: Text; ErrorMessage: Text)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(Item.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. Job ID");
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::Failure);

        VerifyFailedJob(CRMIntegrationRecord."Last Synch. Job ID", Item, IntegrationTableMappingName, ErrorMessage);
    end;

    local procedure VerifyFailedJob(JobID: Guid; Item: Record Item; IntegrationTableMappingName: Text; ErrorMessage: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        IntegrationSynchJob.Get(JobID);
        IntegrationSynchJob.TestField(Modified, 0);
        IntegrationSynchJob.TestField(Failed, 1);
        IntegrationSynchJob.TestField("Integration Table Mapping Name", IntegrationTableMappingName);

        IntegrationSynchJob.GetErrorForRecordID(Item.RecordId, IntegrationSynchJobErrors);
        Assert.ExpectedMessage(ErrorMessage, IntegrationSynchJobErrors.Message);
    end;

    local procedure VerifyModifiedJob(JobID: Guid; Direction: Option; MappingName: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.Get(JobID);
        IntegrationSynchJob.TestField(Modified, 1);
        IntegrationSynchJob.TestField(Failed, 0);
        IntegrationSynchJob.TestField("Integration Table Mapping Name", MappingName);
        IntegrationSynchJob.TestField("Synch. Direction", Direction);
    end;

    local procedure VerifyUnchangedJob(Direction: Option; MappingName: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.FindLast();
        IntegrationSynchJob.TestField(Failed, 0);
        IntegrationSynchJob.TestField(Modified, 0);
        IntegrationSynchJob.TestField(Unchanged, 1);
        IntegrationSynchJob.TestField("Integration Table Mapping Name", MappingName);
        IntegrationSynchJob.TestField("Synch. Direction", Direction);
    end;

    local procedure VerifyNoNotificationSent()
    begin
        if LibraryVariableStorage.Length() > 0 then
            Error(UnexpectedNotificationErr, LibraryVariableStorage.DequeueText());
    end;

    local procedure VerifyNotificationMessage(ExpectedErrorMsg: Text)
    begin
        // Expect that LibraryVariableStorage contains a message filled by FailedSyncNotification handler
        Assert.ExpectedMessage(ExpectedErrorMsg, LibraryVariableStorage.DequeueText());
    end;

    local procedure VerifySuccessfulFromCRMJob(RecID: RecordID; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        CRMIntegrationRecord.TestField("Last Synch. Job ID");
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);
        CRMIntegrationRecord.TestField("Last Synch. CRM Job ID", '{00000000-0000-0000-0000-000000000000}');
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::" ");
        VerifyModifiedJob(
          CRMIntegrationRecord."Last Synch. Job ID", IntegrationTableMapping.Direction::FromIntegrationTable, IntegrationTableMapping.Name);
    end;

    local procedure VerifySuccessfulToCRMJob(RecID: RecordID; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        CRMIntegrationRecord.TestField("Last Synch. Job ID", '{00000000-0000-0000-0000-000000000000}');
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::" ");
        CRMIntegrationRecord.TestField("Last Synch. CRM Job ID");
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);
        VerifyModifiedJob(
          CRMIntegrationRecord."Last Synch. CRM Job ID", IntegrationTableMapping.Direction::ToIntegrationTable, IntegrationTableMapping.Name);
    end;

    local procedure VerifyUnchangedToCRMJob(RecID: RecordID; IntegrationTableMapping: Record "Integration Table Mapping"; Direction: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        CRMIntegrationRecord.TestField("Last Synch. Job ID", '{00000000-0000-0000-0000-000000000000}');
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::" ");
        CRMIntegrationRecord.TestField("Last Synch. CRM Job ID", '{00000000-0000-0000-0000-000000000000}');
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. Result"::" ");
        VerifyUnchangedJob(Direction, IntegrationTableMapping.Name);
    end;

    local procedure VerifyLastSynchDataIsBlank(RecID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        CRMIntegrationRecord.TestField("Last Synch. Job ID", '{00000000-0000-0000-0000-000000000000}');
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::" ");
        CRMIntegrationRecord.TestField("Last Synch. CRM Job ID", '{00000000-0000-0000-0000-000000000000}');
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. Result"::" ");
    end;

    local procedure ClearCustomerContactBusRel()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.DeleteAll();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure FailedSyncNotification(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Product", 'OnBeforeModifyEvent', '', false, false)]
    local procedure FailOnModifyCRMProduct(var Rec: Record "CRM Product"; var xRec: Record "CRM Product"; RunTrigger: Boolean)
    begin
        Error(CRMProductOnModifyErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnBeforeModifyEvent', '', false, false)]
    local procedure FailOnModifyItem(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    begin
        Error(ItemOnModifyErr);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

