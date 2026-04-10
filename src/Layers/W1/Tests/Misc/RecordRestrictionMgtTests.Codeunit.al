codeunit 134320 "Record Restriction Mgt. Tests"
{
    Permissions = TableData "Approval Entry" = i;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Record Restriction]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RestrictionErr: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerRestrictionAdded()
    var
        Customer: Record Customer;
        RestrictedRecord: Record "Restricted Record";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Customer record.
        // [WHEN] The add restriction function is invoked.
        // [THEN] A restriction record is added.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // Exercise.
        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');

        // Verify.
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);

        Assert.RecordCount(RestrictedRecord, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerSalesPostRestriction()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Customer record.
        // [WHEN] The check event is raised for sales document posting.
        // [THEN] An error is thrown.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');

        // Exercise.
        Commit();
        asserterror SalesHeader.OnCheckSalesPostRestrictions();

        // Verify.
        Assert.ExpectedError(StrSubstNo(RestrictionErr, Format(Customer.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesHeaderSalesPostRestriction()
    var
        SalesHeader: Record "Sales Header";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Sales Header record.
        // [WHEN] The check event is raised for sales document posting.
        // [THEN] An error is thrown.

        // Setup.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        RecordRestrictionMgt.RestrictRecordUsage(SalesHeader, '');

        // Exercise.
        Commit();
        asserterror SalesHeader.OnCheckSalesPostRestrictions();

        // Verify.
        Assert.ExpectedError(StrSubstNo(RestrictionErr, Format(SalesHeader.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseHeaderPurchPostRestriction()
    var
        PurchaseHeader: Record "Purchase Header";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Purchase Header record.
        // [WHEN] The check event is raised for purchase document posting.
        // [THEN] An error is thrown.

        // Setup.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        RecordRestrictionMgt.RestrictRecordUsage(PurchaseHeader, '');

        // Exercise.
        Commit();
        asserterror PurchaseHeader.OnCheckPurchasePostRestrictions();

        // Verify.
        Assert.ExpectedError(StrSubstNo(RestrictionErr, Format(PurchaseHeader.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerGenJnlLinePostRestriction()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Customer record.
        // [WHEN] The check event is raised for gen. jnl. posting.
        // [THEN] An error is thrown.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, '', LibraryRandom.RandDec(100, 2));
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine."Bal. Account No." := Customer."No.";
        GenJournalLine.Modify();

        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');

        // Exercise.
        Commit();
        asserterror GenJournalLine.OnCheckGenJournalLinePostRestrictions();

        // Verify.
        Assert.ExpectedError(StrSubstNo(RestrictionErr, Format(Customer.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlLineGenJournalPostRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a General Journal Line record.
        // [WHEN] The check event is raised for gen. jnl. posting.
        // [THEN] An error is thrown.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, '');

        // Exercise.
        Commit();
        asserterror GenJournalLine.OnCheckGenJournalLinePostRestrictions();

        // Verify.
        Assert.ExpectedError(StrSubstNo(RestrictionErr, Format(GenJournalLine.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGenJnlBatchGenJournalPostRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a General Journal Batch record.
        // [WHEN] The check event is raised for gen. jnl. posting.
        // [THEN] An error is thrown.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalBatch, '');

        // Exercise.
        Commit();
        asserterror GenJournalLine.OnCheckGenJournalLinePostRestrictions();

        // Verify.
        Assert.ExpectedError(StrSubstNo(RestrictionErr, Format(GenJournalBatch.RecordId, 0, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerRestrictionRemoved()
    var
        Customer: Record Customer;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is removed for a Customer record.
        // [WHEN] The add restriction function is invoked.
        // [WHEN] The allow usage function is invoked.
        // [THEN] The restriction record is removed.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');

        // Exercise.
        RecordRestrictionMgt.AllowRecordUsage(Customer);

        // Verify.
        VerifyRestrictionRecordNotExists(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNavigateToRestrictedRecord()
    var
        RestrictedRecord: Record "Restricted Record";
        Customer: Record Customer;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        RestrictedRecords: TestPage "Restricted Records";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO] A restriction is introduced for a Customer record.
        // [WHEN] The Restricted Records page is opened.
        // [WHEN] Show Record is invoked.
        // [THEN] The corresponding page is opened.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        CustomerCard.Trap();
        RestrictedRecords.OpenView();
        RestrictedRecords.GotoRecord(RestrictedRecord);
        RestrictedRecords.Record.Invoke();

        // Verify.
        CustomerCard."No.".AssertEquals(Customer."No.");
        CreateApprovalEntry(Customer);

        // Exercise.
        Customer.Delete();
        RestrictedRecords.Record.Invoke();

        // Verify.
        VerifyApprovalEntryNotExists(Customer);
        asserterror RestrictedRecord.Get();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteRemovesRestrictionsForGenJnlLine()
    var
        RestrictedRecord: Record "Restricted Record";
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Gen Jnl Line record.
        // [WHEN] The record is deleted.
        // [THEN] The restriction is removed.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, '');
        CreateApprovalEntry(GenJournalLine);
        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        GenJournalLine.Delete();

        // Verify.
        VerifyApprovalEntryNotExists(GenJournalLine);
        asserterror RestrictedRecord.Get();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteRemovesRestrictionsForGenJnlBatch()
    var
        RestrictedRecord: Record "Restricted Record";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Gen Jnl Batch record.
        // [WHEN] The record is deleted.
        // [THEN] The restriction is removed.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalBatch, '');
        CreateApprovalEntry(GenJournalBatch);
        RestrictedRecord.SetRange("Record ID", GenJournalBatch.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        GenJournalBatch.Delete();

        // Verify.
        VerifyApprovalEntryNotExists(GenJournalBatch);
        asserterror RestrictedRecord.Get();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteRemovesRestrictionsForSalesHeader()
    var
        RestrictedRecord: Record "Restricted Record";
        SalesHeader: Record "Sales Header";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Sales Header record.
        // [WHEN] The record is deleted.
        // [THEN] The restriction is removed.

        // Setup.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        RecordRestrictionMgt.RestrictRecordUsage(SalesHeader, '');
        RestrictedRecord.SetRange("Record ID", SalesHeader.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        SalesHeader.Delete();

        // Verify.
        asserterror RestrictedRecord.Get();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteRemovesRestrictionsForPurchHeader()
    var
        RestrictedRecord: Record "Restricted Record";
        PurchaseHeader: Record "Purchase Header";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Purchase Header record.
        // [WHEN] The record is deleted.
        // [THEN] The restriction is removed.

        // Setup.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        RecordRestrictionMgt.RestrictRecordUsage(PurchaseHeader, '');
        RestrictedRecord.SetRange("Record ID", PurchaseHeader.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        PurchaseHeader.Delete();

        // Verify.
        asserterror RestrictedRecord.Get();
        Assert.AssertRecordNotFound();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenameUpdatesRestrictionsForGenJnlLine()
    var
        RestrictedRecord: Record "Restricted Record";
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Gen Jnl Line record.
        // [WHEN] The record is renamed.
        // [THEN] The restriction is updated.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, '');
        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        GenJournalLine.Rename(GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name", GenJournalLine."Line No." + 10000);

        // Verify.
        RestrictedRecord.Get(RestrictedRecord.ID);
        RestrictedRecord.TestField("Record ID", GenJournalLine.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRenameUpdatesRestrictionsForGenJnlBatch()
    var
        RestrictedRecord: Record "Restricted Record";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is introduced for a Gen Jnl Batch record.
        // [WHEN] The record is renamed.
        // [THEN] The restriction is updated.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalBatch, '');
        RestrictedRecord.SetRange("Record ID", GenJournalBatch.RecordId);
        RestrictedRecord.FindFirst();

        // Exercise.
        GenJournalBatch.Rename(GenJournalBatch."Journal Template Name", GenJournalBatch."Journal Template Name");

        // Verify.
        RestrictedRecord.Get(RestrictedRecord.ID);
        RestrictedRecord.TestField("Record ID", GenJournalBatch.RecordId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTempGenJnlLineGenJournalNoRestriction()
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [SCENARIO] A restriction is not introduced for a temporary General Journal Line record.
        // [WHEN] The restriction subscriber is invoked.
        // [THEN] No restriction is added.

        // Setup.
        Initialize();
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        TempGenJournalLine := GenJournalLine;
        TempGenJournalLine.Insert();
        GenJournalLine.Delete();

        // Exercise.
        RecordRestrictionMgt.RestrictGenJournalLineAfterInsert(TempGenJournalLine, false);

        // Verify.
        VerifyRestrictionRecordNotExists(TempGenJournalLine);

        // Exercise.
        RecordRestrictionMgt.RestrictGenJournalLineAfterModify(TempGenJournalLine, TempGenJournalLine, false);

        // Verify.
        VerifyRestrictionRecordNotExists(TempGenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBufferGenJnlLineGenJournalNoRestriction()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        GeneralJournal: TestPage "General Journal";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] A restriction is not introduced for a buffer General Journal Line record.
        // [GIVEN] Journal line for customer without a document type
        // [WHEN] The restriction subscriber is invoked.
        // [THEN] No restriction is added.

        Initialize();
        GenJournalTemplate.DeleteAll();

        // Setup
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.GeneralJournalLineApprovalWorkflowCode());

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandDec(100, 2));

        // Exercise
        Commit();

        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        GLPostingPreview.Trap();
        GeneralJournal.GotoRecord(GenJournalLine);
        GeneralJournal.Preview.Invoke();
        GLPostingPreview.Close();

        asserterror Error(''); // Rollback previewing inconsistencies

        // Verify
        VerifyRestrictionRecordExists(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotInsertRestrictionRecordForTempRecord()
    var
        TempCustomer: Record Customer temporary;
        RestrictedRecord: Record "Restricted Record";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        "Count": Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223228] COD1550.RestrictRecordUsage do not add new restriction record when passed temporary record
        LibrarySales.CreateCustomer(TempCustomer);

        Count := RestrictedRecord.Count();

        RecordRestrictionMgt.RestrictRecordUsage(TempCustomer, '');

        Assert.RecordCount(RestrictedRecord, Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyRestrictionRecordForTempRecord()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        RestrictedRecord: Record "Restricted Record";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        SavedDetails: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223228] COD1550.RestrictRecordUsage do not add modify restriction record when passed temporary record copied from existing one
        LibrarySales.CreateCustomer(Customer);

        RecordRestrictionMgt.RestrictRecordUsage(
          Customer, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(RestrictedRecord.Details) + 1, 0));
        RestrictedRecord.SetRange("Record ID", Customer.RecordId);
        RestrictedRecord.FindFirst();
        SavedDetails := RestrictedRecord.Details;

        TempCustomer := Customer;
        TempCustomer.Insert();

        RecordRestrictionMgt.RestrictRecordUsage(
          TempCustomer, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(RestrictedRecord.Details) + 1, 0));

        RestrictedRecord.Find();
        RestrictedRecord.TestField(Details, SavedDetails);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempCustomerWithRestriction()
    var
        Customer: Record Customer;
        TempCustomer: Record Customer temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Customer] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary customer copied from existing one
        LibrarySales.CreateCustomer(Customer);

        RecordRestrictionMgt.RestrictRecordUsage(Customer, '');

        CopyCustomerToTemp(Customer, TempCustomer);
        CreateApprovalEntry(Customer);

        TempCustomer.Delete();

        VerifyRestrictionRecordExists(Customer);
        VerifyApprovalEntryExists(Customer);

        Customer.Delete();

        VerifyRestrictionRecordNotExists(Customer);
        VerifyApprovalEntryNotExists(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempVendorWithRestriction()
    var
        Vendor: Record Vendor;
        TempVendor: Record Vendor temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Vendor] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary vendor copied from existing one
        LibraryPurchase.CreateVendor(Vendor);

        RecordRestrictionMgt.RestrictRecordUsage(Vendor, '');

        CopyVendorToTemp(Vendor, TempVendor);
        CreateApprovalEntry(Vendor);

        TempVendor.Delete();

        VerifyRestrictionRecordExists(Vendor);
        VerifyApprovalEntryExists(Vendor);

        Vendor.Delete();

        VerifyRestrictionRecordNotExists(Vendor);
        VerifyApprovalEntryNotExists(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempItemWithRestriction()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Item] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary item copied from existing one
        LibraryInventory.CreateItem(Item);

        RecordRestrictionMgt.RestrictRecordUsage(Item, '');

        CopyItemToTemp(Item, TempItem);
        CreateApprovalEntry(Item);

        TempItem.Delete();

        VerifyRestrictionRecordExists(Item);
        VerifyApprovalEntryExists(Item);

        Item.Delete();

        VerifyRestrictionRecordNotExists(Item);
        VerifyApprovalEntryNotExists(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempSalesHeaderWithRestriction()
    var
        SalesHeader: Record "Sales Header";
        TempSalesHeader: Record "Sales Header" temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary sales header copied from existing one
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();

        RecordRestrictionMgt.RestrictRecordUsage(SalesHeader, '');

        CopySalesHeaderToTemp(SalesHeader, TempSalesHeader);
        CreateApprovalEntry(SalesHeader);

        TempSalesHeader.Delete();

        VerifyRestrictionRecordExists(SalesHeader);
        VerifyApprovalEntryExists(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempPurchaseHeaderWithRestriction()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseHeader: Record "Purchase Header" temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary purchase header copied from existing one
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Insert();

        RecordRestrictionMgt.RestrictRecordUsage(PurchaseHeader, '');

        CopyPurchaseHeaderToTemp(PurchaseHeader, TempPurchaseHeader);
        CreateApprovalEntry(PurchaseHeader);

        TempPurchaseHeader.Delete();

        VerifyRestrictionRecordExists(PurchaseHeader);
        VerifyApprovalEntryExists(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempGenJournalLineWithRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Journal] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary gen. journal line copied from existing one
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(10));

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, '');

        CopyGenJournalLineToTemp(GenJournalLine, TempGenJournalLine);
        CreateApprovalEntry(GenJournalLine);

        TempGenJournalLine.Delete();

        VerifyRestrictionRecordExists(GenJournalLine);
        VerifyApprovalEntryExists(GenJournalLine);

        GenJournalLine.Delete();

        VerifyRestrictionRecordNotExists(GenJournalLine);
        VerifyApprovalEntryNotExists(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteTempGenJournalBatchWithRestriction()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TempGenJournalBatch: Record "Gen. Journal Batch" temporary;
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Journal] [UT]
        // [SCENARIO 223228] Restriction record and approval entry are not deleted on deleting temporary gen. journal batch copied from existing one
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        RecordRestrictionMgt.RestrictRecordUsage(GenJournalBatch, '');

        CopyGenJournalBatchToTemp(GenJournalBatch, TempGenJournalBatch);
        CreateApprovalEntry(GenJournalBatch);

        TempGenJournalBatch.Delete();

        VerifyRestrictionRecordExists(GenJournalBatch);
        VerifyApprovalEntryExists(GenJournalBatch);

        GenJournalBatch.Delete();

        VerifyRestrictionRecordNotExists(GenJournalBatch);
        VerifyApprovalEntryNotExists(GenJournalBatch);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Record Restriction Mgt. Tests");

        LibraryWorkflow.DisableAllWorkflows();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CopyCustomerToTemp(Customer: Record Customer; var TempCustomer: Record Customer temporary)
    begin
        TempCustomer := Customer;
        TempCustomer.Insert();
    end;

    local procedure CopyVendorToTemp(Vendor: Record Vendor; var TempVendor: Record Vendor temporary)
    begin
        TempVendor := Vendor;
        TempVendor.Insert();
    end;

    local procedure CopyItemToTemp(Item: Record Item; var TempItem: Record Item temporary)
    begin
        TempItem := Item;
        TempItem.Insert();
    end;

    local procedure CopySalesHeaderToTemp(SalesHeader: Record "Sales Header"; var TempSalesHeader: Record "Sales Header" temporary)
    begin
        CreateApprovalEntry(SalesHeader);

        TempSalesHeader := SalesHeader;
        TempSalesHeader.Insert();
    end;

    local procedure CopyPurchaseHeaderToTemp(PurchaseHeader: Record "Purchase Header"; var TempPurchaseHeader: Record "Purchase Header" temporary)
    begin
        TempPurchaseHeader := PurchaseHeader;
        TempPurchaseHeader.Insert();
    end;

    local procedure CopyGenJournalLineToTemp(GenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        TempGenJournalLine := GenJournalLine;
        TempGenJournalLine.Insert();
    end;

    local procedure CopyGenJournalBatchToTemp(GenJournalBatch: Record "Gen. Journal Batch"; var TempGenJournalBatch: Record "Gen. Journal Batch" temporary)
    begin
        TempGenJournalBatch := GenJournalBatch;
        TempGenJournalBatch.Insert();
    end;

    local procedure CreateApprovalEntry(RecVar: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);

        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := RecRef.Number;
        ApprovalEntry."Record ID to Approve" := RecRef.RecordId;
        ApprovalEntry.Insert();
        ApprovalEntry.SetRecFilter();
    end;

    local procedure VerifyRestrictionRecordExists(RecVar: Variant)
    var
        RestrictedRecord: Record "Restricted Record";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        RestrictedRecord.SetRange("Record ID", RecRef.RecordId);
        Assert.RecordIsNotEmpty(RestrictedRecord);
    end;

    local procedure VerifyRestrictionRecordNotExists(RecVar: Variant)
    var
        RestrictedRecord: Record "Restricted Record";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        RestrictedRecord.SetRange("Record ID", RecRef.RecordId);
        Assert.RecordIsEmpty(RestrictedRecord);
    end;

    local procedure VerifyApprovalEntryExists(RecVar: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);

        ApprovalEntry.Init();
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);

        Assert.RecordIsNotEmpty(ApprovalEntry);
    end;

    local procedure VerifyApprovalEntryNotExists(RecVar: Variant)
    var
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);

        ApprovalEntry.Init();
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);

        Assert.RecordIsEmpty(ApprovalEntry);
    end;
}

