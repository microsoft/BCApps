namespace Microsoft.CRM.Outlook;
using Microsoft.CRM.Contact;

codeunit 130481 "Contact Sync Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        ExpectedMessageText: Text;
        ActualMessageText: Text;
        MessageHandlerCalled: Boolean;
        ContactsSyncedMsg: Label '%1 contacts have been synchronized successfully.', Comment = '%1 = Number of synced contacts';

    [Test]
    [HandlerFunctions('SyncSuccessMessageHandler')]
    procedure TestProcessBidirectionalSync_SyncToBCWithValidContacts()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Process bidirectional sync with valid contacts to sync to Business Central
        Initialize();

        // [GIVEN] A temporary sync queue with contacts to sync to BC
        CreateSampleSyncQueueForBC(TempSyncQueue, 3);
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";
        ExpectedMessageText := StrSubstNo(ContactsSyncedMsg, 3);

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] The message handler should have been called
        AssertIsTrue(MessageHandlerCalled, 'Message handler should have been called');

        // [THEN] Contacts should be processed
        TempSyncQueue.Reset();
        TempSyncQueue.SetRange("Sync Status", TempSyncQueue."Sync Status"::Processed);
        AssertAreEqual(3, TempSyncQueue.Count(), 'All 3 contacts should be processed');
    end;

    [Test]
    procedure TestProcessBidirectionalSync_SuppressedUI_SyncToBCWithValidContacts()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Process bidirectional sync with UI suppressed - no message handlers needed
        Initialize();

        // [GIVEN] A temporary sync queue with contacts to sync to BC
        CreateSampleSyncQueueForBC(TempSyncQueue, 3);
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";

        // [GIVEN] UI is suppressed
        ContactSyncProcessor.SetSuppressUI(true);

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] Contacts should be processed without UI prompts
        TempSyncQueue.Reset();
        TempSyncQueue.SetRange("Sync Status", TempSyncQueue."Sync Status"::Processed);
        AssertAreEqual(3, TempSyncQueue.Count(), 'All 3 contacts should be processed');
    end;

    [Test]
    procedure TestProcessBidirectionalSync_SuppressedUI_EmptyQueue()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Process bidirectional sync with an empty queue and UI suppressed
        Initialize();

        // [GIVEN] An empty temporary sync queue
        TempSyncQueue.DeleteAll();
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";

        // [GIVEN] UI is suppressed
        ContactSyncProcessor.SetSuppressUI(true);

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] No contacts should be in the queue
        AssertAreEqual(0, TempSyncQueue.Count(), 'Queue should be empty');
    end;

    [Test]
    [HandlerFunctions('NoContactsMessageHandler')]
    procedure TestProcessBidirectionalSync_EmptyQueue()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Process bidirectional sync with an empty queue
        Initialize();

        // [GIVEN] An empty temporary sync queue
        TempSyncQueue.DeleteAll();
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] No contacts should be in the queue
        AssertAreEqual(0, TempSyncQueue.Count(), 'Queue should be empty');
    end;

    [Test]
    procedure TestProcessBidirectionalSync_SuppressedUI_SyncToM365OnlyDirection()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Process sync with BC to M365 direction only - BC contacts should not be processed
        Initialize();

        // [GIVEN] A temporary sync queue with contacts marked for BC sync
        CreateSampleSyncQueueForBC(TempSyncQueue, 2);
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Sync from BC to M365"; // Only M365 direction

        // [GIVEN] UI is suppressed
        ContactSyncProcessor.SetSuppressUI(true);

        // [WHEN] ProcessBidirectionalSync is called with M365 only direction
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] Contacts should remain pending as they are marked for BC sync but direction is M365 only
        TempSyncQueue.Reset();
        TempSyncQueue.SetRange("Sync Status", TempSyncQueue."Sync Status"::Pending);
        AssertAreEqual(2, TempSyncQueue.Count(), 'Contacts should remain pending');
    end;

    [Test]
    procedure TestProcessBidirectionalSync_SuppressedUI_DuplicateEmailSkipped()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        Contact: Record Contact;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Contacts with duplicate email addresses should be skipped
        Initialize();

        // [GIVEN] An existing contact in BC with the same email
        CreateSampleBCContact(Contact, 'duplicate@test.com');

        // [GIVEN] A sync queue entry with the same email
        CreateSingleSyncQueueEntry(TempSyncQueue, 'duplicate@test.com', 'To BC');
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";

        // [GIVEN] UI is suppressed
        ContactSyncProcessor.SetSuppressUI(true);

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] The contact should have error status (duplicate)
        TempSyncQueue.Reset();
        TempSyncQueue.SetRange("Sync Status", TempSyncQueue."Sync Status"::Error);
        AssertAreEqual(1, TempSyncQueue.Count(), 'Duplicate contact should have error status');

        // Cleanup
        Contact.Delete(true);
    end;

    [Test]
    procedure TestProcessBidirectionalSync_SuppressedUI_MixedDirections()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
        EntryNo: Integer;
    begin
        // [SCENARIO] Process sync with mixed direction contacts in Full Sync mode
        Initialize();

        // [GIVEN] A sync queue with contacts for both directions
        EntryNo := 1;

        // Add contacts to sync to BC
        AddSyncQueueEntry(TempSyncQueue, EntryNo, 'John', 'Doe', 'john.doe@test.com', 'To BC');
        EntryNo += 1;
        AddSyncQueueEntry(TempSyncQueue, EntryNo, 'Jane', 'Smith', 'jane.smith@test.com', 'To BC');
        EntryNo += 1;

        // Add contacts to sync to M365 (these won't actually sync without real API)
        AddSyncQueueEntry(TempSyncQueue, EntryNo, 'Bob', 'Wilson', 'bob.wilson@test.com', 'To M365');

        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";

        // [GIVEN] UI is suppressed
        ContactSyncProcessor.SetSuppressUI(true);

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] BC contacts should be processed
        TempSyncQueue.Reset();
        TempSyncQueue.SetRange("Sync Direction", TempSyncQueue."Sync Direction"::"To BC");
        TempSyncQueue.SetRange("Sync Status", TempSyncQueue."Sync Status"::Processed);
        AssertAreEqual(2, TempSyncQueue.Count(), '2 BC contacts should be processed');
    end;

    [Test]
    procedure TestProcessBidirectionalSync_SuppressedUI_LargeBatch()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
        AccessToken: SecretText;
        FolderId: Text;
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Process sync with more than batch size (20) contacts
        Initialize();

        // [GIVEN] A sync queue with 25 contacts to sync to BC (exceeds batch size of 20)
        CreateSampleSyncQueueForBC(TempSyncQueue, 25);
        FolderId := 'TestFolder123';
        SyncDirection := SyncDirection::"Full Sync";

        // [GIVEN] UI is suppressed
        ContactSyncProcessor.SetSuppressUI(true);

        // [WHEN] ProcessBidirectionalSync is called
        ContactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, AccessToken, FolderId, SyncDirection);

        // [THEN] All 25 contacts should be processed
        TempSyncQueue.Reset();
        TempSyncQueue.SetRange("Sync Status", TempSyncQueue."Sync Status"::Processed);
        AssertAreEqual(25, TempSyncQueue.Count(), 'All 25 contacts should be processed');
    end;

    [Test]
    procedure TestSetSuppressUI()
    var
        ContactSyncProcessor: Codeunit "Contact Sync Processor";
    begin
        // [SCENARIO] Test SetSuppressUI and IsSuppressUI methods
        Initialize();

        // [GIVEN] A new Contact Sync Processor instance
        // [WHEN] Initially created
        // [THEN] SuppressUI should be false
        AssertIsFalse(ContactSyncProcessor.IsSuppressUI(), 'SuppressUI should be false by default');

        // [WHEN] SetSuppressUI is called with true
        ContactSyncProcessor.SetSuppressUI(true);

        // [THEN] IsSuppressUI should return true
        AssertIsTrue(ContactSyncProcessor.IsSuppressUI(), 'SuppressUI should be true after setting');

        // [WHEN] SetSuppressUI is called with false
        ContactSyncProcessor.SetSuppressUI(false);

        // [THEN] IsSuppressUI should return false
        AssertIsFalse(ContactSyncProcessor.IsSuppressUI(), 'SuppressUI should be false after resetting');
    end;

    [Test]
    procedure TestSyncQueueCopyFromO365Contact()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        O365Contact: Record "Outlook Contacts";
    begin
        // [SCENARIO] Test copying data from O365 Contact to Sync Queue
        Initialize();

        // [GIVEN] An O365 Contact with sample data
        CreateSampleO365Contact(O365Contact);

        // [WHEN] CopyFromO365Contact is called
        TempSyncQueue.Init();
        TempSyncQueue."Entry No." := 1;
        TempSyncQueue.CopyFromO365Contact(O365Contact, TempSyncQueue."Sync Direction"::"To BC");
        TempSyncQueue.Insert(false);

        // [THEN] All fields should be copied correctly
        AssertAreEqual('Test Display', TempSyncQueue."Display Name", 'Display Name should match');
        AssertAreEqual('TestFirst', TempSyncQueue."Given Name", 'Given Name should match');
        AssertAreEqual('TestLast', TempSyncQueue.Surname, 'Surname should match');
        AssertAreEqual('test@example.com', TempSyncQueue."Email Address", 'Email should match');
        AssertAreEqual('Manager', TempSyncQueue."Job Title", 'Job Title should match');
        AssertAreEqual('Test Company', TempSyncQueue."Company Name", 'Company Name should match');
        AssertAreEqual(TempSyncQueue."Sync Direction"::"To BC", TempSyncQueue."Sync Direction", 'Direction should be To BC');
        AssertAreEqual(TempSyncQueue."Sync Status"::Pending, TempSyncQueue."Sync Status", 'Status should be Pending');

        // Cleanup
        O365Contact.Delete();
    end;

    [Test]
    procedure TestSyncQueueCopyFromBCContact()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        Contact: Record Contact;
    begin
        // [SCENARIO] Test copying data from BC Contact to Sync Queue
        Initialize();

        // [GIVEN] A BC Contact with sample data
        CreateSampleBCContact(Contact, 'bccontact@example.com');

        // [WHEN] CopyFromBCContact is called
        TempSyncQueue.Init();
        TempSyncQueue."Entry No." := 1;
        TempSyncQueue.CopyFromBCContact(Contact, TempSyncQueue."Sync Direction"::"To M365");
        TempSyncQueue.Insert(false);

        // [THEN] All fields should be copied correctly
        AssertAreEqual(Contact."No.", TempSyncQueue."BC Contact No.", 'BC Contact No. should match');
        AssertAreEqual(Contact.Name, TempSyncQueue."Display Name", 'Display Name should match');
        AssertAreEqual(Contact."First Name", TempSyncQueue."Given Name", 'Given Name should match');
        AssertAreEqual(Contact.Surname, TempSyncQueue.Surname, 'Surname should match');
        AssertAreEqual(Contact."E-Mail", TempSyncQueue."Email Address", 'Email should match');
        AssertAreEqual(TempSyncQueue."Sync Direction"::"To M365", TempSyncQueue."Sync Direction", 'Direction should be To M365');
        AssertAreEqual(TempSyncQueue."Sync Status"::Pending, TempSyncQueue."Sync Status", 'Status should be Pending');

        // Cleanup
        Contact.Delete(true);
    end;

    [Test]
    procedure TestContactSyncFolderTable()
    var
        TempFolder: Record "Contact Sync Folder" temporary;
    begin
        // [SCENARIO] Test Contact Sync Folder table operations
        Initialize();

        // [GIVEN] Sample folder data
        // [WHEN] Folders are inserted
        TempFolder.Init();
        TempFolder."Entry No." := 1;
        TempFolder."Folder ID" := 'folder-id-123';
        TempFolder."Display Name" := 'Business Central Contacts';
        TempFolder."Parent Id" := 'parent-id-456';
        TempFolder.Insert(false);

        TempFolder.Init();
        TempFolder."Entry No." := 2;
        TempFolder."Folder ID" := 'folder-id-789';
        TempFolder."Display Name" := 'Personal Contacts';
        TempFolder."Parent Id" := 'parent-id-456';
        TempFolder.Insert(false);

        // [THEN] Folders should be retrievable
        AssertAreEqual(2, TempFolder.Count(), 'Should have 2 folders');

        TempFolder.Get(1);
        AssertAreEqual('Business Central Contacts', TempFolder."Display Name", 'First folder name should match');

        TempFolder.Get(2);
        AssertAreEqual('Personal Contacts', TempFolder."Display Name", 'Second folder name should match');
    end;

    [Test]
    procedure TestContactSyncDirectionEnum()
    var
        SyncDirection: Enum "ContactSyncDirection";
    begin
        // [SCENARIO] Test Contact Sync Direction enum values
        Initialize();

        // [GIVEN] ContactSyncDirection enum
        // [WHEN] Accessing enum values
        // [THEN] Values should be correct
        SyncDirection := SyncDirection::"Sync from BC to M365";
        AssertAreEqual(0, SyncDirection.AsInteger(), 'Sync from BC to M365 should be 0');

        SyncDirection := SyncDirection::"Full Sync";
        AssertAreEqual(1, SyncDirection.AsInteger(), 'Full Sync should be 1');
    end;

    [Test]
    procedure TestO365ContactTableOperations()
    var
        O365Contact: Record "Outlook Contacts";
    begin
        // [SCENARIO] Test O365 Contact table CRUD operations
        Initialize();

        // [GIVEN] Sample O365 Contact data
        // [WHEN] Contact is inserted
        CreateSampleO365Contact(O365Contact);

        // [THEN] Contact should exist
        AssertIsTrue(O365Contact.Get(O365Contact."Outlook Id"), 'Contact should be retrievable by Outlook Id');

        // [WHEN] Contact is modified
        O365Contact."Display Name" := 'Updated Display Name';
        O365Contact.Modify(false);

        // [THEN] Changes should persist
        O365Contact.Get(O365Contact."Outlook Id");
        AssertAreEqual('Updated Display Name', O365Contact."Display Name", 'Display Name should be updated');

        // [WHEN] Contact is deleted
        O365Contact.Delete();

        // [THEN] Contact should not exist
        AssertIsFalse(O365Contact.Get(O365Contact."Outlook Id"), 'Contact should be deleted');
    end;

    [Test]
    procedure TestSyncQueueWithAddressFields()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        EntryNo: Integer;
    begin
        // [SCENARIO] Test sync queue with complete address fields
        Initialize();

        // [GIVEN] A sync queue entry with all address fields populated
        EntryNo := 1;
        TempSyncQueue.Init();
        TempSyncQueue."Entry No." := EntryNo;
        TempSyncQueue."Given Name" := 'Address';
        TempSyncQueue.Surname := 'Test';
        TempSyncQueue."Display Name" := 'Address Test';
        TempSyncQueue."Email Address" := 'address.test@example.com';
        TempSyncQueue.Address := '123 Main Street, Suite 400';
        TempSyncQueue.City := 'Seattle';
        TempSyncQueue.County := 'King County';
        TempSyncQueue."Post Code" := '98101';
        TempSyncQueue."Country/Region Code" := 'US';
        TempSyncQueue."Sync Direction" := TempSyncQueue."Sync Direction"::"To BC";
        TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Pending;
        TempSyncQueue.Insert(false);

        // [THEN] All address fields should be stored correctly
        TempSyncQueue.Get(EntryNo);
        AssertAreEqual('123 Main Street, Suite 400', TempSyncQueue.Address, 'Address should match');
        AssertAreEqual('Seattle', TempSyncQueue.City, 'City should match');
        AssertAreEqual('King County', TempSyncQueue.County, 'County should match');
        AssertAreEqual('98101', TempSyncQueue."Post Code", 'Post Code should match');
        AssertAreEqual('US', TempSyncQueue."Country/Region Code", 'Country/Region Code should match');
    end;

    [Test]
    procedure TestSyncQueueWithPhoneFields()
    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        EntryNo: Integer;
    begin
        // [SCENARIO] Test sync queue with all phone fields populated
        Initialize();

        // [GIVEN] A sync queue entry with all phone fields
        EntryNo := 1;
        TempSyncQueue.Init();
        TempSyncQueue."Entry No." := EntryNo;
        TempSyncQueue."Given Name" := 'Phone';
        TempSyncQueue.Surname := 'Test';
        TempSyncQueue."Display Name" := 'Phone Test';
        TempSyncQueue."Email Address" := 'phone.test@example.com';
        TempSyncQueue."Business Phone" := '+1-555-0100';
        TempSyncQueue."Mobile Phone" := '+1-555-0101';
        TempSyncQueue."Home Phone" := '+1-555-0102';
        TempSyncQueue."Sync Direction" := TempSyncQueue."Sync Direction"::"To M365";
        TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Pending;
        TempSyncQueue.Insert(false);

        // [THEN] All phone fields should be stored correctly
        TempSyncQueue.Get(EntryNo);
        AssertAreEqual('+1-555-0100', TempSyncQueue."Business Phone", 'Business Phone should match');
        AssertAreEqual('+1-555-0101', TempSyncQueue."Mobile Phone", 'Mobile Phone should match');
        AssertAreEqual('+1-555-0102', TempSyncQueue."Home Phone", 'Home Phone should match');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        MessageHandlerCalled := false;
        ExpectedMessageText := '';
        ActualMessageText := '';

        IsInitialized := true;
    end;

    local procedure CreateSampleSyncQueueForBC(var TempSyncQueue: Record "Contact Sync Queue" temporary; Count: Integer)
    var
        i: Integer;
    begin
        TempSyncQueue.DeleteAll();

        for i := 1 to Count do
            AddSyncQueueEntry(
                TempSyncQueue,
                i,
                'FirstName' + Format(i),
                'LastName' + Format(i),
                'contact' + Format(i) + '@test.com',
                'To BC'
            );
    end;

    local procedure CreateSingleSyncQueueEntry(var TempSyncQueue: Record "Contact Sync Queue" temporary; Email: Text; Direction: Text)
    begin
        TempSyncQueue.DeleteAll();
        AddSyncQueueEntry(TempSyncQueue, 1, 'Test', 'User', Email, Direction);
    end;

    local procedure AddSyncQueueEntry(var TempSyncQueue: Record "Contact Sync Queue" temporary; EntryNo: Integer; GivenName: Text; Surname: Text; Email: Text; Direction: Text)
    begin
        TempSyncQueue.Init();
        TempSyncQueue."Entry No." := EntryNo;
        TempSyncQueue."Given Name" := CopyStr(GivenName, 1, MaxStrLen(TempSyncQueue."Given Name"));
        TempSyncQueue.Surname := CopyStr(Surname, 1, MaxStrLen(TempSyncQueue.Surname));
        TempSyncQueue."Display Name" := CopyStr(GivenName + ' ' + Surname, 1, MaxStrLen(TempSyncQueue."Display Name"));
        TempSyncQueue."Email Address" := CopyStr(Email, 1, MaxStrLen(TempSyncQueue."Email Address"));
        TempSyncQueue."Job Title" := 'Software Developer';
        TempSyncQueue."Company Name" := 'Contoso Ltd.';
        TempSyncQueue."Mobile Phone" := '+1-555-0100';
        TempSyncQueue."Business Phone" := '+1-555-0101';
        TempSyncQueue.Address := '123 Main Street';
        TempSyncQueue.City := 'Seattle';
        TempSyncQueue.County := 'WA';
        TempSyncQueue."Post Code" := '98101';
        TempSyncQueue."Country/Region Code" := 'US';
        TempSyncQueue.Initials := CopyStr(CopyStr(GivenName, 1, 1) + CopyStr(Surname, 1, 1), 1, MaxStrLen(TempSyncQueue.Initials));
        TempSyncQueue."Sync Status" := TempSyncQueue."Sync Status"::Pending;

        if Direction = 'To BC' then
            TempSyncQueue."Sync Direction" := TempSyncQueue."Sync Direction"::"To BC"
        else
            TempSyncQueue."Sync Direction" := TempSyncQueue."Sync Direction"::"To M365";

        TempSyncQueue.Insert(false);
    end;

    local procedure CreateSampleO365Contact(var O365Contact: Record "Outlook Contacts")
    begin
        O365Contact.Init();
        O365Contact."Outlook Id" := 'outlook-id-' + Format(Random(9999));
        O365Contact."Display Name" := 'Test Display';
        O365Contact."Given Name" := 'TestFirst';
        O365Contact.Surname := 'TestLast';
        O365Contact."Email Address" := 'test@example.com';
        O365Contact."Job Title" := 'Manager';
        O365Contact."Company Name" := 'Test Company';
        O365Contact."Mobile Phone" := '+1-555-1234';
        O365Contact."Business Phone" := '+1-555-5678';
        O365Contact.Address := '456 Test Ave';
        O365Contact.City := 'Redmond';
        O365Contact.County := 'WA';
        O365Contact."Post Code" := '98052';
        O365Contact."Country/Region Code" := 'US';
        O365Contact."Middle Name" := 'M';
        O365Contact.Initials := 'TT';
        O365Contact."Created DateTime" := CurrentDateTime();
        O365Contact."Last Modified DateTime" := CurrentDateTime();
        O365Contact.Insert(false);
    end;

    local procedure CreateSampleBCContact(var Contact: Record Contact; Email: Text)
    begin
        Contact.Init();
        Contact."No." := '';
        Contact.Type := Contact.Type::Person;
        Contact.Name := 'BC Test Contact';
        Contact."First Name" := 'BCFirst';
        Contact.Surname := 'BCLast';
        Contact."E-Mail" := CopyStr(Email, 1, MaxStrLen(Contact."E-Mail"));
        Contact."Job Title" := 'Developer';
        Contact."Company Name" := 'BC Company';
        Contact."Mobile Phone No." := '+1-555-9999';
        Contact."Phone No." := '+1-555-8888';
        Contact.Address := '789 BC Street';
        Contact.City := 'Bellevue';
        Contact.County := 'WA';
        Contact."Post Code" := '98004';
        Contact."Country/Region Code" := 'US';
        Contact."Middle Name" := 'C';
        Contact.Initials := 'BC';
        Contact.Insert(true);
    end;

    // Assert helper procedures - replace external Assert codeunit
    local procedure AssertIsTrue(Condition: Boolean; ErrorMessage: Text)
    begin
        if not Condition then
            Error(ErrorMessage);
    end;

    local procedure AssertIsFalse(Condition: Boolean; ErrorMessage: Text)
    begin
        if Condition then
            Error(ErrorMessage);
    end;

    local procedure AssertAreEqual(Expected: Variant; Actual: Variant; ErrorMessage: Text)
    begin
        if Format(Expected) <> Format(Actual) then
            Error('Expected: %1, Actual: %2. %3', Expected, Actual, ErrorMessage);
    end;

    [MessageHandler]
    procedure SyncSuccessMessageHandler(Message: Text[1024])
    begin
        MessageHandlerCalled := true;
        ActualMessageText := Message;
        // Accept the message - in tests we just verify it was called
    end;

    [MessageHandler]
    procedure NoContactsMessageHandler(Message: Text[1024])
    begin
        MessageHandlerCalled := true;
        ActualMessageText := Message;
        // Accept the message for no contacts synced scenario
    end;
}
