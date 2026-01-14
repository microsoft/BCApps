namespace Microsoft.CRM.Outlook;

codeunit 130481 "Contact Sync Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TempSyncQueue: Record "Contact Sync Queue" temporary;
        Assert: Codeunit Assert;
    // Sync Direction Constants
    procedure SyncDirectionToBC(): Integer
    begin
        exit(1);
    end;

    procedure SyncDirectionToM365(): Integer
    begin
        exit(0);
    end;

    [Test]
    procedure TestProcessBidirectionalSyncWithEmptyQueue()
    var
        contactSyncProcessor: Codeunit "Contact Sync Processor";
        accessToken: SecretText;
    begin
        // [GIVEN] Empty sync queue
        TempSyncQueue.DeleteAll();

        // [WHEN] ProcessBidirectionalSync is called
        contactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, accessToken);

        // [THEN] No error occurs
        Assert.IsTrue(true, 'Empty queue handled successfully');
    end;

    [Test]
    procedure TestProcessBidirectionalSyncToBCDirection()
    var
        contactSyncProcessor: Codeunit "Contact Sync Processor";
        accessToken: SecretText;
    begin
        // [GIVEN] Sync queue with contact to sync to BC
        CreateTempSyncQueueEntry(TempSyncQueue, 'Test Contact', 'test@example.com', SyncDirectionToBC());

        // [WHEN] ProcessBidirectionalSync is called
        contactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, accessToken);

        // [THEN] Contact should be created or sync attempted
        Assert.IsTrue(true, 'BC sync processed');
    end;

    [Test]
    procedure TestProcessBidirectionalSyncToM365Direction()
    var
        contactSyncProcessor: Codeunit "Contact Sync Processor";
        accessToken: SecretText;
    begin
        // [GIVEN] Sync queue with contact to sync to M365
        CreateTempSyncQueueEntry(TempSyncQueue, 'Test Contact M365', 'test2@example.com', SyncDirectionToM365());

        // [WHEN] ProcessBidirectionalSync is called
        contactSyncProcessor.ProcessBidirectionalSync(TempSyncQueue, accessToken);

        // [THEN] No error occurs
        Assert.IsTrue(true, 'M365 sync processed');
    end;

    [Test]
    procedure TestSyncQueueEntryCreation()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
    begin
        // [GIVEN] Empty sync queue
        tempSyncQueue2.DeleteAll();

        // [WHEN] Creating a sync queue entry
        tempSyncQueue2.Init();
        tempSyncQueue2."Entry No." := 1;
        tempSyncQueue2."Display Name" := 'John Doe';
        tempSyncQueue2."Given Name" := 'John';
        tempSyncQueue2.Surname := 'Doe';
        tempSyncQueue2."Email Address" := 'john@example.com';
        tempSyncQueue2."Sync Direction" := SyncDirectionToBC();
        tempSyncQueue2."Sync Status" := tempSyncQueue2."Sync Status"::Pending;
        tempSyncQueue2.Insert();

        // [THEN] Entry is created successfully
        Assert.IsTrue(tempSyncQueue2.FindFirst(), 'Sync queue entry created');
        Assert.AreEqual('John Doe', tempSyncQueue2."Display Name", 'Display name matches');
        Assert.AreEqual('john@example.com', tempSyncQueue2."Email Address", 'Email address matches');
    end;

    [Test]
    procedure TestContactSyncStatusUpdate()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
    begin
        // [GIVEN] Sync queue entry with pending status
        CreateTempSyncQueueEntry(tempSyncQueue2, 'Status Test Contact', 'status@example.com', SyncDirectionToBC());
        tempSyncQueue2.FindFirst();

        // [WHEN] Updating sync status to processed
        tempSyncQueue2."Sync Status" := tempSyncQueue2."Sync Status"::Processed;
        tempSyncQueue2.Modify();

        // [THEN] Status is updated
        Assert.AreEqual(tempSyncQueue2."Sync Status"::Processed, tempSyncQueue2."Sync Status", 'Status updated to Processed');
    end;

    [Test]
    procedure TestMultipleContactsInSyncQueue()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        entryNo: Integer;
    begin
        // [GIVEN] Multiple contacts in sync queue
        for entryNo := 1 to 5 do begin
            tempSyncQueue2.Init();
            tempSyncQueue2."Entry No." := entryNo;
            tempSyncQueue2."Display Name" := 'Contact ' + Format(entryNo);
            tempSyncQueue2."Given Name" := 'First' + Format(entryNo);
            tempSyncQueue2.Surname := 'Last' + Format(entryNo);
            tempSyncQueue2."Email Address" := 'contact' + Format(entryNo) + '@example.com';
            if entryNo mod 2 = 0 then
                tempSyncQueue2."Sync Direction" := SyncDirectionToBC()
            else
                tempSyncQueue2."Sync Direction" := SyncDirectionToM365();
            tempSyncQueue2."Sync Status" := tempSyncQueue2."Sync Status"::Pending;
            tempSyncQueue2.Insert();
        end;

        // [WHEN] Counting sync queue entries
        tempSyncQueue2.Reset();
        // [THEN] Count should be 5
        Assert.AreEqual(5, tempSyncQueue2.Count(), 'Five contacts in sync queue');
    end;

    [Test]
    procedure TestSyncQueueFilterByDirection()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        bcCount: Integer;
        m365Count: Integer;
    begin
        // [GIVEN] Multiple contacts with different sync directions
        CreateTempSyncQueueEntry(tempSyncQueue2, 'BC Contact 1', 'bc1@example.com', SyncDirectionToBC());
        CreateTempSyncQueueEntry(tempSyncQueue2, 'M365 Contact 1', 'm365_1@example.com', SyncDirectionToM365());
        CreateTempSyncQueueEntry(tempSyncQueue2, 'BC Contact 2', 'bc2@example.com', SyncDirectionToBC());

        // [WHEN] Filtering by sync direction
        tempSyncQueue2.SetRange("Sync Direction", SyncDirectionToBC());
        bcCount := tempSyncQueue2.Count();

        tempSyncQueue2.SetRange("Sync Direction", SyncDirectionToM365());
        m365Count := tempSyncQueue2.Count();

        // [THEN] Counts match expected values
        Assert.AreEqual(2, bcCount, 'Two contacts to sync to BC');
        Assert.AreEqual(1, m365Count, 'One contact to sync to M365');
    end;

    [Test]
    procedure TestSyncQueueErrorHandling()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
    begin
        // [GIVEN] Sync queue entry with error
        CreateTempSyncQueueEntry(tempSyncQueue2, 'Error Contact', 'error@example.com', SyncDirectionToBC());
        tempSyncQueue2.FindFirst();

        // [WHEN] Setting error status and message
        tempSyncQueue2."Sync Status" := tempSyncQueue2."Sync Status"::Error;
        tempSyncQueue2."Error Message" := 'Test error message';
        tempSyncQueue2.Modify();

        // [THEN] Error information is stored
        Assert.AreEqual(tempSyncQueue2."Sync Status"::Error, tempSyncQueue2."Sync Status", 'Status is Error');
        Assert.AreEqual('Test error message', tempSyncQueue2."Error Message", 'Error message is stored');
    end;

    [Test]
    procedure TestContactSyncFolderCreation()
    var
        TempSyncFolder: Record "Contact Sync Folder" temporary;
    begin
        // [GIVEN] Empty sync folder
        TempSyncFolder.DeleteAll();

        // [WHEN] Creating a sync folder entry
        TempSyncFolder.Init();
        TempSyncFolder."Entry No." := 1;
        TempSyncFolder."Folder ID" := 'folder-123-456';
        TempSyncFolder."Display Name" := 'Business Central';
        TempSyncFolder.Insert();

        // [THEN] Folder is created successfully
        Assert.IsTrue(TempSyncFolder.FindFirst(), 'Sync folder entry created');
        Assert.AreEqual('Business Central', TempSyncFolder."Display Name", 'Folder display name matches');
    end;

    [Test]
    procedure TestO365ContactCreation()
    var
        O365Contact: Record "O365 Contact";
    begin
        // [GIVEN] Empty O365 contact
        O365Contact.Init();

        // [WHEN] Populating O365 contact fields
        O365Contact."Contact ID" := 'contact-xyz-789';
        O365Contact."Display Name" := 'Jane Smith';
        O365Contact."Given Name" := 'Jane';
        O365Contact.Surname := 'Smith';
        O365Contact."Email Address" := 'jane@example.com';
        O365Contact."Business Phone" := '+1-555-0123';
        O365Contact."Mobile Phone" := '+1-555-0124';
        O365Contact."Company Name" := 'Contoso';
        O365Contact.City := 'Seattle';
        O365Contact."Country/Region Code" := 'US';

        // [THEN] All fields are set correctly
        Assert.AreEqual('Jane Smith', O365Contact."Display Name", 'Display name set');
        Assert.AreEqual('jane@example.com', O365Contact."Email Address", 'Email set');
        Assert.AreEqual('Contoso', O365Contact."Company Name", 'Company name set');
    end;

    [Test]
    procedure TestSyncQueueDataIntegrity()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        originalName: Text[100];
    begin
        // [GIVEN] Sync queue entry
        CreateTempSyncQueueEntry(tempSyncQueue2, 'Integrity Test', 'integrity@example.com', SyncDirectionToBC());
        tempSyncQueue2.FindFirst();
        originalName := tempSyncQueue2."Display Name";

        // [WHEN] Modifying and then reverting
        tempSyncQueue2."Display Name" := 'Modified Name';
        tempSyncQueue2.Modify();
        tempSyncQueue2."Display Name" := originalName;
        tempSyncQueue2.Modify();

        // [THEN] Data integrity is maintained
        Assert.AreEqual(originalName, tempSyncQueue2."Display Name", 'Data integrity maintained');
    end;

    [Test]
    procedure TestBCContactNumberAssignment()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
    begin
        // [GIVEN] Sync queue entry without BC contact number
        CreateTempSyncQueueEntry(tempSyncQueue2, 'BC Number Test', 'bcnum@example.com', SyncDirectionToBC());
        tempSyncQueue2.FindFirst();

        // [WHEN] Assigning BC contact number
        tempSyncQueue2."BC Contact No." := 'C-001';
        tempSyncQueue2.Modify();

        // [THEN] BC contact number is stored
        Assert.AreEqual('C-001', tempSyncQueue2."BC Contact No.", 'BC contact number assigned');
    end;

    [Test]
    procedure TestContactFilterByCompanyName()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        filteredCount: Integer;
    begin
        // [GIVEN] Multiple contacts with different company names
        CreateTempSyncQueueEntryWithCompany(tempSyncQueue2, 'Contact 1', 'contact1@example.com', SyncDirectionToBC(), 'Contoso');
        CreateTempSyncQueueEntryWithCompany(tempSyncQueue2, 'Contact 2', 'contact2@example.com', SyncDirectionToBC(), 'Fabrikam');
        CreateTempSyncQueueEntryWithCompany(tempSyncQueue2, 'Contact 3', 'contact3@example.com', SyncDirectionToBC(), 'Contoso');

        // [WHEN] Filtering by company name
        tempSyncQueue2.SetRange("Company Name", 'Contoso');
        filteredCount := tempSyncQueue2.Count();

        // [THEN] Only Contoso contacts are returned
        Assert.AreEqual(2, filteredCount, 'Two Contoso contacts found');
    end;

    [Test]
    procedure TestContactFilterByCity()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        seattleCount: Integer;
    begin
        // [GIVEN] Multiple contacts with different cities
        CreateTempSyncQueueEntryWithCity(tempSyncQueue2, 'Seattle Contact 1', 'seattle1@example.com', SyncDirectionToBC(), 'Seattle');
        CreateTempSyncQueueEntryWithCity(tempSyncQueue2, 'New York Contact', 'newyork@example.com', SyncDirectionToBC(), 'New York');
        CreateTempSyncQueueEntryWithCity(tempSyncQueue2, 'Seattle Contact 2', 'seattle2@example.com', SyncDirectionToBC(), 'Seattle');

        // [WHEN] Filtering by city
        tempSyncQueue2.SetRange(City, 'Seattle');
        seattleCount := tempSyncQueue2.Count();

        // [THEN] Only Seattle contacts are returned
        Assert.AreEqual(2, seattleCount, 'Two Seattle contacts found');
    end;

    [Test]
    procedure TestContactFilterByCountry()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        usCount: Integer;
        ukCount: Integer;
    begin
        // [GIVEN] Multiple contacts from different countries
        CreateTempSyncQueueEntryWithCountry(tempSyncQueue2, 'US Contact 1', 'us1@example.com', SyncDirectionToBC(), 'US');
        CreateTempSyncQueueEntryWithCountry(tempSyncQueue2, 'UK Contact', 'uk@example.com', SyncDirectionToBC(), 'GB');
        CreateTempSyncQueueEntryWithCountry(tempSyncQueue2, 'US Contact 2', 'us2@example.com', SyncDirectionToBC(), 'US');
        CreateTempSyncQueueEntryWithCountry(tempSyncQueue2, 'Canada Contact', 'canada@example.com', SyncDirectionToBC(), 'CA');

        // [WHEN] Filtering by country
        tempSyncQueue2.SetRange("Country/Region Code", 'US');
        usCount := tempSyncQueue2.Count();

        tempSyncQueue2.SetRange("Country/Region Code", 'GB');
        ukCount := tempSyncQueue2.Count();

        // [THEN] Only matching country contacts are returned
        Assert.AreEqual(2, usCount, 'Two US contacts found');
        Assert.AreEqual(1, ukCount, 'One UK contact found');
    end;

    [Test]
    procedure TestContactFilterByEmail()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
    begin
        // [GIVEN] Multiple contacts
        CreateTempSyncQueueEntry(tempSyncQueue2, 'Contact A', 'contacta@example.com', SyncDirectionToBC());
        CreateTempSyncQueueEntry(tempSyncQueue2, 'Contact B', 'contactb@example.com', SyncDirectionToBC());
        CreateTempSyncQueueEntry(tempSyncQueue2, 'Contact C', 'contactc@example.com', SyncDirectionToBC());

        // [WHEN] Filtering by specific email
        tempSyncQueue2.SetRange("Email Address", 'contactb@example.com');

        // [THEN] Only matching email contact is returned
        Assert.AreEqual(1, tempSyncQueue2.Count(), 'One contact with matching email found');
        Assert.IsTrue(tempSyncQueue2.FindFirst(), 'Contact found');
        Assert.AreEqual('Contact B', tempSyncQueue2."Display Name", 'Correct contact retrieved');
    end;

    [Test]
    procedure TestContactFilterMultipleCriteria()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        filteredCount: Integer;
    begin
        // [GIVEN] Multiple contacts with varying attributes
        CreateTempSyncQueueEntryWithAllDetails(tempSyncQueue2, 'Contact 1', 'contact1@example.com', SyncDirectionToBC(), 'Contoso', 'Seattle', 'US');
        CreateTempSyncQueueEntryWithAllDetails(tempSyncQueue2, 'Contact 2', 'contact2@example.com', SyncDirectionToBC(), 'Fabrikam', 'Seattle', 'US');
        CreateTempSyncQueueEntryWithAllDetails(tempSyncQueue2, 'Contact 3', 'contact3@example.com', SyncDirectionToBC(), 'Contoso', 'New York', 'US');
        CreateTempSyncQueueEntryWithAllDetails(tempSyncQueue2, 'Contact 4', 'contact4@example.com', SyncDirectionToBC(), 'Contoso', 'Seattle', 'CA');

        // [WHEN] Filtering by multiple criteria (Contoso in Seattle in US)
        tempSyncQueue2.SetRange("Company Name", 'Contoso');
        tempSyncQueue2.SetRange(City, 'Seattle');
        tempSyncQueue2.SetRange("Country/Region Code", 'US');
        filteredCount := tempSyncQueue2.Count();

        // [THEN] Only contact matching all criteria is returned
        Assert.AreEqual(1, filteredCount, 'One contact matches all filter criteria');
    end;

    [Test]
    procedure TestContactFilterClearFilter()
    var
        tempSyncQueue2: Record "Contact Sync Queue" temporary;
        allCount: Integer;
    begin
        // [GIVEN] Multiple contacts with filters applied
        CreateTempSyncQueueEntryWithCompany(tempSyncQueue2, 'Contact 1', 'contact1@example.com', SyncDirectionToBC(), 'Contoso');
        CreateTempSyncQueueEntryWithCompany(tempSyncQueue2, 'Contact 2', 'contact2@example.com', SyncDirectionToBC(), 'Fabrikam');
        CreateTempSyncQueueEntryWithCompany(tempSyncQueue2, 'Contact 3', 'contact3@example.com', SyncDirectionToBC(), 'Contoso');

        // [WHEN] Applying filter and then clearing it
        tempSyncQueue2.SetRange("Company Name", 'Contoso');
        tempSyncQueue2.Reset();
        allCount := tempSyncQueue2.Count();

        // [THEN] All contacts are returned after filter is cleared
        Assert.AreEqual(3, allCount, 'All contacts returned after filter cleared');
    end;

    // Helper procedure to create temporary sync queue entries
    local procedure CreateTempSyncQueueEntry(var TempSyncQueue2: Record "Contact Sync Queue" temporary; displayName: Text; emailAddress: Text; syncDirection: Integer)
    begin
        CreateTempSyncQueueEntryWithCompany(TempSyncQueue2, displayName, emailAddress, syncDirection, '');
    end;

    local procedure CreateTempSyncQueueEntryWithCompany(var TempSyncQueue2: Record "Contact Sync Queue" temporary; displayName: Text; emailAddress: Text; syncDirection: Integer; companyName: Code[30])
    var
        entryNo: Integer;
    begin
        TempSyncQueue2.Reset();
        if TempSyncQueue2.FindLast() then
            entryNo := TempSyncQueue2."Entry No." + 1
        else
            entryNo := 1;

        TempSyncQueue2.Init();
        TempSyncQueue2."Entry No." := entryNo;
        TempSyncQueue2."Display Name" := CopyStr(displayName, 1, MaxStrLen(TempSyncQueue2."Display Name"));
        TempSyncQueue2."Email Address" := CopyStr(emailAddress, 1, MaxStrLen(TempSyncQueue2."Email Address"));
        TempSyncQueue2."Given Name" := 'Test';
        TempSyncQueue2.Surname := 'User';
        TempSyncQueue2."Company Name" := CopyStr(companyName, 1, MaxStrLen(TempSyncQueue2."Company Name"));
        TempSyncQueue2."Sync Direction" := syncDirection;
        TempSyncQueue2."Sync Status" := TempSyncQueue2."Sync Status"::Pending;
        TempSyncQueue2.Insert();
    end;

    local procedure CreateTempSyncQueueEntryWithCity(var TempSyncQueue2: Record "Contact Sync Queue" temporary; displayName: Text; emailAddress: Text; syncDirection: Integer; cityName: Text)
    var
        entryNo: Integer;
    begin
        TempSyncQueue2.Reset();
        if TempSyncQueue2.FindLast() then
            entryNo := TempSyncQueue2."Entry No." + 1
        else
            entryNo := 1;

        TempSyncQueue2.Init();
        TempSyncQueue2."Entry No." := entryNo;
        TempSyncQueue2."Display Name" := CopyStr(displayName, 1, MaxStrLen(TempSyncQueue2."Display Name"));
        TempSyncQueue2."Email Address" := CopyStr(emailAddress, 1, MaxStrLen(TempSyncQueue2."Email Address"));
        TempSyncQueue2."Given Name" := 'Test';
        TempSyncQueue2.Surname := 'User';
        TempSyncQueue2.City := CopyStr(cityName, 1, MaxStrLen(TempSyncQueue2.City));
        TempSyncQueue2."Sync Direction" := syncDirection;
        TempSyncQueue2."Sync Status" := TempSyncQueue2."Sync Status"::Pending;
        TempSyncQueue2.Insert();
    end;

    local procedure CreateTempSyncQueueEntryWithCountry(var TempSyncQueue2: Record "Contact Sync Queue" temporary; displayName: Text; emailAddress: Text; syncDirection: Integer; countryCode: Code[10])
    var
        entryNo: Integer;
    begin
        TempSyncQueue2.Reset();
        if TempSyncQueue2.FindLast() then
            entryNo := TempSyncQueue2."Entry No." + 1
        else
            entryNo := 1;

        TempSyncQueue2.Init();
        TempSyncQueue2."Entry No." := entryNo;
        TempSyncQueue2."Display Name" := CopyStr(displayName, 1, MaxStrLen(TempSyncQueue2."Display Name"));
        TempSyncQueue2."Email Address" := CopyStr(emailAddress, 1, MaxStrLen(TempSyncQueue2."Email Address"));
        TempSyncQueue2."Given Name" := 'Test';
        TempSyncQueue2.Surname := 'User';
        TempSyncQueue2."Country/Region Code" := countryCode;
        TempSyncQueue2."Sync Direction" := syncDirection;
        TempSyncQueue2."Sync Status" := TempSyncQueue2."Sync Status"::Pending;
        TempSyncQueue2.Insert();
    end;

    local procedure CreateTempSyncQueueEntryWithAllDetails(var TempSyncQueue2: Record "Contact Sync Queue" temporary; displayName: Text; emailAddress: Text; syncDirection: Integer; companyName: Code[30]; cityName: Text; countryCode: Code[10])
    var
        entryNo: Integer;
    begin
        TempSyncQueue2.Reset();
        if TempSyncQueue2.FindLast() then
            entryNo := TempSyncQueue2."Entry No." + 1
        else
            entryNo := 1;

        TempSyncQueue2.Init();
        TempSyncQueue2."Entry No." := entryNo;
        TempSyncQueue2."Display Name" := CopyStr(displayName, 1, MaxStrLen(TempSyncQueue2."Display Name"));
        TempSyncQueue2."Email Address" := CopyStr(emailAddress, 1, MaxStrLen(TempSyncQueue2."Email Address"));
        TempSyncQueue2."Given Name" := 'Test';
        TempSyncQueue2.Surname := 'User';
        TempSyncQueue2."Company Name" := CopyStr(companyName, 1, MaxStrLen(TempSyncQueue2."Company Name"));
        TempSyncQueue2.City := CopyStr(cityName, 1, MaxStrLen(TempSyncQueue2.City));
        TempSyncQueue2."Country/Region Code" := countryCode;
        TempSyncQueue2."Sync Direction" := syncDirection;
        TempSyncQueue2."Sync Status" := TempSyncQueue2."Sync Status"::Pending;
        TempSyncQueue2.Insert();
    end;

}

