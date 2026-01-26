codeunit 135098 "OCR Master Data Sync Tests"
{
    // PRECONDITION: The tests will require Mock services to be started using the following enlistment command
    //   Start-AMCMockService -Configuration release -Secure

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [OCR Master Data Sync]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        OCRMasterDataSyncEvents: Codeunit "OCR Master Data Sync Events";
        TaskDisabled: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestServiceEnablingCreatesSyncJob()
    begin
        // initialize
        Initialize(false, true, true);

        // verify
        CheckJobQueueEntry(false);
        EnableService();
        CheckJobQueueEntry(true);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestServiceDisablingDeletesSyncJob()
    begin
        // initialize
        Initialize(true, true, false);

        // verify
        CheckJobQueueEntry(true);
        DisableService();
        CheckJobQueueEntry(false);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSyncEnablingCreatesSyncJob()
    begin
        // initialize
        Initialize(true, false, true);

        // verify
        CheckJobQueueEntry(false);
        EnableMasterDataSync();
        CheckJobQueueEntry(true);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSyncDisablingDeletesSyncJob()
    begin
        // initialize
        Initialize(true, true, false);

        // verify
        CheckJobQueueEntry(true);
        DisableMasterDataSync();
        CheckJobQueueEntry(false);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestVendorCreationCreatesSyncJob()
    var
        Vendor: Record Vendor;
    begin
        // initialize
        Initialize(true, true, true);

        // verify
        CheckJobQueueEntry(false);
        CreateVendor(Vendor);
        CheckJobQueueEntry(true);

        // cleanup
        DeleteVendor(Vendor);
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestVendorModificationCreatesSyncJob()
    var
        Vendor: Record Vendor;
    begin
        // initialize
        Initialize(true, true, false);
        CreateVendor(Vendor);
        DeleteJobQueueEntry();

        // verify
        CheckJobQueueEntry(false);
        ModifyVendor(Vendor);
        CheckJobQueueEntry(true);

        // cleanup
        DeleteVendor(Vendor);
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestVendorDeletionCreatesSyncJob()
    var
        Vendor: Record Vendor;
    begin
        // initialize
        Initialize(true, true, false);
        CreateVendor(Vendor);
        DeleteJobQueueEntry();

        // verify
        CheckJobQueueEntry(false);
        DeleteVendor(Vendor);
        CheckJobQueueEntry(true);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestVendorBankAccountCreationCreatesSyncJob()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // initialize
        Initialize(true, true, false);
        CreateVendor(Vendor);
        DeleteJobQueueEntry();

        // verify
        CheckJobQueueEntry(false);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        CheckJobQueueEntry(true);

        // cleanup
        DeleteVendorBankAccount(VendorBankAccount);
        DeleteVendor(Vendor);
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestVendorBankAccountModificationCreatesSyncJob()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // initialize
        Initialize(true, true, false);
        CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        DeleteJobQueueEntry();

        // verify
        CheckJobQueueEntry(false);
        ModifyVendorBankAccountNumber(VendorBankAccount);
        CheckJobQueueEntry(true);

        // cleanup
        DeleteVendorBankAccount(VendorBankAccount);
        DeleteVendor(Vendor);
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestVendorBankAccountDeletionCreatesSyncJob()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // initialize
        Initialize(true, true, false);
        CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        DeleteJobQueueEntry();

        // verify
        CheckJobQueueEntry(false);
        DeleteVendorBankAccount(VendorBankAccount);
        CheckJobQueueEntry(true);

        // cleanup
        DeleteVendor(Vendor);
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSyncRequestContainsVendorNumber()
    var
        Vendor: Record Vendor;
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
    begin
        // initialize
        Initialize(true, true, false);
        CreateVendor(Vendor);
        DeleteJobQueueEntry();
        OCRMasterDataSyncEvents.EnableValidation();
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo('<SupplierNumber>%1</SupplierNumber>', Vendor."No."));
        OCRMasterDataSyncEvents.EnqueueVariable('');

        // verify
        Assert.IsTrue(ReadSoftOCRMasterDataSync.SyncMasterData(false, true), 'Expecting sync success.');
        OCRMasterDataSyncEvents.AssertEmptyQueue();

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSyncRequestContainsAccountNumber()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        LastSyncTime: DateTime;
    begin
        // initialize
        Initialize(true, true, false);
        LastSyncTime := CurrentDateTime();
        SetLastSyncTime(LastSyncTime);
        Sleep(100);
        CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        ModifyVendorBankAccountNumber(VendorBankAccount);
        DeleteJobQueueEntry();
        OCRMasterDataSyncEvents.EnableValidation();
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo('<SupplierNumber>%1</SupplierNumber>', Vendor."No."));
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo(
            '<BankNumber>%1</BankNumber><AccountNumber>%2</AccountNumber>',
            VendorBankAccount."Bank Branch No.", VendorBankAccount."Bank Account No."));

        // verify
        Assert.IsTrue(ReadSoftOCRMasterDataSync.SyncMasterData(false, true), 'Expecting sync success.');
        OCRMasterDataSyncEvents.AssertEmptyQueue();

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSyncRequestContainsERSAccountNumber()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        LastSyncTime: DateTime;
    begin
        // initialize
        Initialize(true, true, false);
        LastSyncTime := CurrentDateTime();
        SetLastSyncTime(LastSyncTime);
        Sleep(100);
        CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        ModifyVendorBankESRAccountNumber(VendorBankAccount);
        DeleteJobQueueEntry();
        OCRMasterDataSyncEvents.EnableValidation();
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo('<SupplierNumber>%1</SupplierNumber>', Vendor."No."));
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo(
            '<BankNumber>%1</BankNumber><AccountNumber>%2</AccountNumber>',
            VendorBankAccount."Bank Branch No.", VendorBankAccount."ESR Account No."));

        // verify
        Assert.IsTrue(ReadSoftOCRMasterDataSync.SyncMasterData(false, true), 'Expecting sync success.');
        OCRMasterDataSyncEvents.AssertEmptyQueue();

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSyncRequestContainsSWIFTAndIBAN()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        LastSyncTime: DateTime;
    begin
        // initialize
        Initialize(true, true, false);
        LastSyncTime := CurrentDateTime();
        SetLastSyncTime(LastSyncTime);
        Sleep(100);
        CreateVendor(Vendor);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        ModifyVendorBankAccountSWIFT(VendorBankAccount);
        ModifyVendorBankAccountIBAN(VendorBankAccount);
        DeleteJobQueueEntry();
        OCRMasterDataSyncEvents.EnableValidation();
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo('<SupplierNumber>%1</SupplierNumber>', Vendor."No."));
        OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo(
            '<BankNumberType>bic</BankNumberType><BankNumber>%1</BankNumber>' +
            '<AccountNumberType>iban</AccountNumberType><AccountNumber>%2</AccountNumber>',
            VendorBankAccount."SWIFT Code", VendorBankAccount.IBAN));

        // verify
        Assert.IsTrue(ReadSoftOCRMasterDataSync.SyncMasterData(false, true), 'Expecting sync success.');
        OCRMasterDataSyncEvents.AssertEmptyQueue();

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSyncInPortions()
    var
        Vendor: Array[3] of Record Vendor;
        VendorBankAccount: Array[3] of Record "Vendor Bank Account";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        LastSyncTime: DateTime;
        I: Integer;
    begin
        // initialize
        Initialize(true, true, false);
        LastSyncTime := CurrentDateTime();
        SetLastSyncTime(LastSyncTime);
        Sleep(100);
        for I := 1 to 3 do begin
            CreateVendor(Vendor[I]);
            CreateVendorBankAccount(VendorBankAccount[I], Vendor[I]."No.");
            ModifyVendorBankESRAccountNumber(VendorBankAccount[I]);
        end;
        DeleteJobQueueEntry();
        OCRMasterDataSyncEvents.SetPortionSize(1);
        OCRMasterDataSyncEvents.EnableValidation();
        for I := 1 to 3 do
            OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo('<SupplierNumber>%1</SupplierNumber>', Vendor[I]."No."));
        for I := 1 to 3 do
            OCRMasterDataSyncEvents.EnqueueVariable(StrSubstNo(
                '<BankNumber>%1</BankNumber><AccountNumber>%2</AccountNumber>',
                VendorBankAccount[I]."Bank Branch No.", VendorBankAccount[I]."ESR Account No."));

        // verify
        Assert.IsTrue(ReadSoftOCRMasterDataSync.SyncMasterData(false, true), 'Expecting sync success.');
        OCRMasterDataSyncEvents.AssertEmptyQueue();

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestSuccessSyncUpdatesLastSyncTime()
    var
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        TestSyncTime: DateTime;
    begin
        // initialize
        Initialize(true, true, true);
        TestSyncTime := 0DT;
        SetLastSyncTime(TestSyncTime);

        // verify
        CheckLastSyncTimeEquals(TestSyncTime);
        Assert.IsTrue(ReadSoftOCRMasterDataSync.SyncMasterData(false, true), 'Expecting sync success.');
        CheckLastSyncTimeDiffers(TestSyncTime);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestErrorInSyncResponseLeavesLastSyncTimeUnchanged()
    begin
        TestSyncFailureLeavesLastSyncTimeUnchanged(
          '/rso_error', 'Synchronization failed. Code: 400, Message: Every supplier must have a supplier number. The supplier with name ''acfsdfv'' has no number.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestNoSyncResponseLeavesLastSyncTimeUnchanged()
    begin
        TestSyncFailureLeavesLastSyncTimeUnchanged(
          '/rso_timeout', 'A call to System.Net.HttpWebRequest.GetResponse failed with this message: The remote server returned an error: (408) Request Time-out. Synchronization failed.');
    end;

    local procedure TestSyncFailureLeavesLastSyncTimeUnchanged(FailureUrlToken: Text; ExpectedError: Text)
    var
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        TestSyncTime: DateTime;
    begin
        // initialize
        Initialize(true, true, true);
        TestSyncTime := 0DT;
        SetLastSyncTime(TestSyncTime);
        SetServiceUrl(FailureUrlToken);

        // verify
        CheckLastSyncTimeEquals(TestSyncTime);
        asserterror ReadSoftOCRMasterDataSync.SyncMasterData(false, true);
        Assert.ExpectedError(ExpectedError);
        CheckLastSyncTimeEquals(TestSyncTime);

        // cleanup
        DeleteSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestNewSyncJobNotCreatedIfAnotherSyncJobReady()
    var
        Vendor: Record Vendor;
    begin
        // initialize
        Initialize(true, true, false);

        // verify
        CheckJobQueueEntryCount(1);
        CreateVendor(Vendor);
        CheckJobQueueEntryCount(1);

        // cleanup
        DeleteSetup();
    end;

    local procedure Initialize(ServiceEnabled: Boolean; SyncEnabled: Boolean; DeleteSyncJob: Boolean)
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DummySecret: Text;
    begin
        DisableTask();
        OCRMasterDataSyncEvents.SetPortionSize(0);
        OCRMasterDataSyncEvents.DisableValidation();
        OCRMasterDataSyncEvents.ClearQueue();

        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);
        OCRServiceSetup.Init();
        OCRServiceSetup.Insert(true);

        OCRServiceSetup."User Name" := 'cronus.admin';
        DummySecret := '#Ey^VDI$B$53.8';
        OCRServiceSetup.SavePassword(OCRServiceSetup."Password Key", DummySecret);
        DummySecret := '2e9dfdaf60ee4569a2444a1fc3d16685';
        OCRServiceSetup.SavePassword(OCRServiceSetup."Authorization Key", DummySecret);

        OCRServiceSetup."Service URL" := 'https://localhost:8080/OCR';
        OCRServiceSetup."Default OCR Doc. Template" := 'BLANK';

        OCRServiceSetup.Validate("Master Data Sync Enabled", SyncEnabled);
        OCRServiceSetup.Modify();
        OCRServiceSetup.Validate(Enabled, ServiceEnabled);

        OCRServiceSetup.Modify();

        if DeleteSyncJob then
            DeleteJobQueueEntry();
    end;

    local procedure DisableTask()
    begin
        if TaskDisabled then
            exit;
        BindSubscription(OCRMasterDataSyncEvents);
        TaskDisabled := true;
    end;

    local procedure DeleteSetup()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        if OCRServiceSetup.Get() then
            OCRServiceSetup.Delete(true);
    end;

    local procedure EnableService()
    begin
        SetEnabled(true);
    end;

    local procedure DisableService()
    begin
        SetEnabled(false);
    end;

    local procedure EnableMasterDataSync()
    begin
        SetSyncEnabled(true);
    end;

    local procedure DisableMasterDataSync()
    begin
        SetSyncEnabled(false);
    end;

    local procedure SetEnabled(Enabled: Boolean)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        OCRServiceSetup.Validate(Enabled, Enabled);
        OCRServiceSetup.Modify();
    end;

    local procedure SetSyncEnabled(SyncEnabled: Boolean)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        OCRServiceSetup.Validate("Master Data Sync Enabled", SyncEnabled);
        OCRServiceSetup.Modify();
    end;

    local procedure SetServiceUrl(Uri: Text)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        OCRServiceSetup.Validate("Service URL", CopyStr(OCRServiceSetup."Service URL" + Uri, 1, MaxStrLen(OCRServiceSetup."Service URL")));
        OCRServiceSetup.Modify();
    end;

    local procedure SetLastSyncTime(LastSyncTime: DateTime)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        OCRServiceSetup.Validate("Master Data Last Sync", LastSyncTime);
        OCRServiceSetup.Modify();
    end;

    local procedure CheckLastSyncTimeEquals(TestSyncTime: DateTime)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        Assert.IsTrue(OCRServiceSetup."Master Data Last Sync" = TestSyncTime, 'Last Sync Time is not empty.')
    end;

    local procedure CheckLastSyncTimeDiffers(TestSyncTime: DateTime)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Get();
        Assert.IsTrue(OCRServiceSetup."Master Data Last Sync" <> TestSyncTime, 'Last Sync Time is empty.')
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
    end;

    local procedure ModifyVendor(var Vendor: Record Vendor)
    begin
        Vendor.Validate(Address, CopyStr(Format(CreateGuid()), 2, MaxStrLen(Vendor.Address)));
        Vendor.Modify(true);
    end;

    local procedure DeleteVendor(var Vendor: Record Vendor)
    begin
        Vendor.Delete(true);
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
    end;

    local procedure ModifyVendorBankAccountNumber(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount.Validate("Bank Branch No.", CopyStr(Format(CreateGuid()), 2, MaxStrLen(VendorBankAccount."Bank Branch No.")));
        VendorBankAccount.Validate("Bank Account No.", CopyStr(Format(CreateGuid()), 2, MaxStrLen(VendorBankAccount."Bank Account No.")));
        VendorBankAccount.Modify(true);
    end;

    local procedure ModifyVendorBankESRAccountNumber(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount.Validate("Bank Branch No.", CopyStr(Format(CreateGuid()), 2, MaxStrLen(VendorBankAccount."Bank Branch No.")));
        VendorBankAccount."ESR Account No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(VendorBankAccount."ESR Account No."));
        VendorBankAccount.Modify();
    end;

    local procedure ModifyVendorBankAccountSWIFT(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount."SWIFT Code" := CopyStr(Format(CreateGuid()), 2, MaxStrLen(VendorBankAccount."SWIFT Code"));
        VendorBankAccount.Modify();
    end;

    local procedure ModifyVendorBankAccountIBAN(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount.IBAN := CopyStr(Format(CreateGuid()), 2, MaxStrLen(VendorBankAccount.IBAN));
        VendorBankAccount.Modify();
    end;

    local procedure DeleteVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount.Delete(true);
    end;

    local procedure GetJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"OCR - Sync Master Data");
        if JobQueueEntry.FindFirst() then;
    end;

    local procedure CheckJobQueueEntry(Exists: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        GetJobQueueEntry(JobQueueEntry);
        if Exists then
            Assert.IsTrue(JobQueueEntry.FindFirst(), 'Sync Job is not created.')
        else
            Assert.IsFalse(JobQueueEntry.FindFirst(), 'Sync Job is not deleted.')
    end;

    local procedure CheckJobQueueEntryCount(ExpectedCount: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        GetJobQueueEntry(JobQueueEntry);
        Assert.AreEqual(ExpectedCount, JobQueueEntry.Count, 'Wrong count of Sync Jobs.')
    end;

    local procedure DeleteJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        while JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"OCR - Sync Master Data") do
            JobQueueEntry.Cancel();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConsentConfirmYes(var CustConsentConfirmation: TestPage "Cust. Consent Confirmation")
    begin
        CustConsentConfirmation.Accept.Invoke();
    end;
}
