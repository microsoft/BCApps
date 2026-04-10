codeunit 132502 "Purch. Document Posting Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryPurchase: Codeunit "Library - Purchase";
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        CheckPurchLineMsg: Label 'Check purchase document line.';

        // Expected error messages (from code unit 90).
        PurchRcptHeaderConflictErr: Label 'Cannot post the purchase receipt because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Receiving No.';
        ReturnShptHeaderConflictErr: Label 'Cannot post the return shipment because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Return Shipment No.';
        PurchInvHeaderConflictErr: Label 'Cannot post the purchase invoice because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';
        SetupBlockedErr: Label 'Setup is blocked in %1 for %2 %3 and %4 %5.', Comment = '%1 - General/VAT Posting Setup, %2 %3 %4 %5 - posting groups.';

    [Test]
    [Scope('OnPrem')]
    procedure T001_PostingDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        PurchInvoicePage: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in G/L Setup
        Initialize();
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchHeader.TestField("Posting Date", WorkDate());

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message", PostingDateNotAllowedErr);
        // [THEN] Call Stack contains '"Purch.-Post"(CodeUnit 90).CheckAndUpdate '
        Assert.ExpectedMessage('"Purch.-Post"(CodeUnit 90).CheckAndUpdate ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Purchase Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Header");
        TempErrorMessage.TestField("Context Field Number", PurchHeader.FieldNo("Posting Date"));
        // [THEN] "Source" is 'G/L Setup', "Field Name" is 'Allow Posting From'
        GeneralLedgerSetup.Get();
        TempErrorMessage.TestField("Record ID", GeneralLedgerSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Ledger Setup");
        TempErrorMessage.TestField("Field Number", GeneralLedgerSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        GeneralLedgerSetupPage.Trap();
        LibraryErrorMessage.DrillDownOnSource();
        // [THEN] opens "General Ledger Setup" page.
        GeneralLedgerSetupPage."Allow Posting To".AssertEquals(WorkDate() - 1);
        GeneralLedgerSetupPage.Close();

        // [WHEN] DrillDown on "Description"
        PurchInvoicePage.Trap();
        LibraryErrorMessage.DrillDownOnContext();
        // [THEN] opens "Purchase Invoice" page.
        PurchInvoicePage."Posting Date".AssertEquals(WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_PostingDateIsInNotAllowedPeriodInUserSetup()
    var
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        PurchInvoicePage: TestPage "Purchase Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in User Setup.
        Initialize();
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "User Setup"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting To" := WorkDate() - 1;
        UserSetup.Modify();
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);
        PurchHeader.TestField("Posting Date", WorkDate());

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message", PostingDateNotAllowedErr);
        // [THEN] Call Stack contains '"Purch.-Post"(CodeUnit 90).CheckAndUpdate '
        Assert.ExpectedMessage('"Purch.-Post"(CodeUnit 90).CheckAndUpdate ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Purchase Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", PurchHeader.FieldNo("Posting Date"));
        // [THEN]  "Source" is 'User Setup',  "Field Name" is 'Allow Posting From'
        TempErrorMessage.TestField("Record ID", UserSetup.RecordId);
        TempErrorMessage.TestField("Field Number", UserSetup.FieldNo("Allow Posting From"));
        // [WHEN] DrillDown on "Source"
        UserSetupPage.Trap();
        LibraryErrorMessage.DrillDownOnSource();
        // [THEN] opens "User Setup" page.
        UserSetupPage."Allow Posting To".AssertEquals(WorkDate() - 1);
        UserSetupPage.Close();

        // [WHEN] DrillDown on "Description"
        PurchInvoicePage.Trap();
        LibraryErrorMessage.DrillDownOnContext();
        // [THEN] opens "Purchase Invoice" page.
        PurchInvoicePage."Posting Date".AssertEquals(WorkDate());

        // TearDown
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T011_GenPostingSetupIsBlocked()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] Posting of document, where "General Posting Setup" is blocked
        Initialize();
        UnblockAllSetups();

        // [GIVEN] Invoice '1001', where "Gen. Bus. Posting Group" is 'GB',"Gen. Bus. Posting Group" is 'GP'
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        // [GIVEN] General Posting Setup for 'GB' and 'GP' is blocked
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Blocked := true;
        GeneralPostingSetup.Modify();

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Setup is blocked in general posting setup for GB and GP."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message",
            StrSubstNo(
                SetupBlockedErr, GeneralPostingSetup.TableCaption(),
                GeneralPostingSetup.FieldCaption("Gen. Bus. Posting Group"), GeneralPostingSetup."Gen. Bus. Posting Group",
                GeneralPostingSetup.FieldCaption("Gen. Prod. Posting Group"), GeneralPostingSetup."Gen. Prod. Posting Group"));
        // [THEN] Call Stack contains '"Purch.-Post"(CodeUnit 90).CheckBlockedPostingGroups '
        Assert.ExpectedMessage('"Purch.-Post"(CodeUnit 90).CheckBlockedPostingGroups ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Purchase Line: Invoice, 1001, 10000', "Field Name" is 'Gen. Prod. Posting Group',
        TempErrorMessage.TestField("Context Record ID", PurchaseLine.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Line");
        TempErrorMessage.TestField("Context Field Number", PurchaseLine.FieldNo("Gen. Prod. Posting Group"));
        // [THEN] "Source" is 'General Posting Setup', "Field Name" is 'Blocked'
        TempErrorMessage.TestField("Record ID", GeneralPostingSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Posting Setup");
        TempErrorMessage.TestField("Field Number", GeneralPostingSetup.FieldNo(Blocked));
        UnblockAllSetups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T012_VATPostingSetupIsBlocked()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] Posting of document, where "VAT Posting Setup" is blocked
        Initialize();
        UnblockAllSetups();

        // [GIVEN] Invoice '1001', where "VAT Bus. Posting Group" is 'VB',"VAT Bus. Posting Group" is 'VP'
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        // [GIVEN] VAT Posting Setup for 'VB' and 'VP' is blocked
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VATPostingSetup.Blocked := true;
        VATPostingSetup.Modify();

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Setup is blocked in VAT posting setup for VB and VP."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message",
            StrSubstNo(
                SetupBlockedErr, VATPostingSetup.TableCaption(),
                VATPostingSetup.FieldCaption("VAT Bus. Posting Group"), VATPostingSetup."VAT Bus. Posting Group",
                VATPostingSetup.FieldCaption("VAT Prod. Posting Group"), VATPostingSetup."VAT Prod. Posting Group"));
        // [THEN] Call Stack contains '"Purch.-Post"(CodeUnit 90).CheckBlockedPostingGroups '
        Assert.ExpectedMessage('"Purch.-Post"(CodeUnit 90).CheckBlockedPostingGroups ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Purchase Line: Invoice, 1001, 10000', "Field Name" is 'VAT Prod. Posting Group',
        TempErrorMessage.TestField("Context Record ID", PurchaseLine.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Line");
        TempErrorMessage.TestField("Context Field Number", PurchaseLine.FieldNo("VAT Prod. Posting Group"));
        // [THEN] "Source" is 'VAT Posting Setup', "Field Name" is 'Blocked'
        TempErrorMessage.TestField("Record ID", VATPostingSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"VAT Posting Setup");
        TempErrorMessage.TestField("Field Number", VATPostingSetup.FieldNo(Blocked));
        UnblockAllSetups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T013_TwoLinesWithBlockedPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: array[2] of Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        TempErrorMessage: Record "Error Message" temporary;
        Vendor: Record Vendor;
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        InstructionMgt: Codeunit "Instruction Mgt.";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // [SCENARIO] Posting of document with 2 lines, where "VAT Posting Setup" and "Gen. Posting Setup" are blocked
        Initialize();
        UnblockAllSetups();
        // [GIVEN] Enabled posting setup notification
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(PostingSetupManagement.GetPostingSetupNotificationID());

        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] G/L Account 'AV', where VAT Prod Posting Group 'V-NEW', thais not used in setup
        LibraryERM.CreateGLAccount(GLAccount[1]);
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", Vendor."Gen. Bus. Posting Group");
        GeneralPostingSetup.FindFirst();
        GLAccount[1]."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GLAccount[1]."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        GLAccount[1].Modify();
        // [GIVEN] G/L Account 'AG', where Gen. Prod Posting Group 'G-NEW', thais not used in setup
        LibraryERM.CreateGLAccount(GLAccount[2]);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
        GLAccount[2]."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount[2]."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount[2].Modify();

        // [GIVEN] Order '1001', with two lines:
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        // [GIVEN] 1st line for G/L Account 'AV', where VAT Prod Posting Group 'V-NEW'
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine[1], PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount[1]."No.", 1);
        // [GIVEN] 2nd line for G/L Account 'AG', where Gen. Prod Posting Group 'G-NEW'
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine[2], PurchaseHeader, "Purchase Line Type"::"G/L Account", GLAccount[2]."No.", 1);

        // [WHEN] Post Order '1001'
        LibraryErrorMessage.TrapErrorMessages();
        PurchHeaderToPost(PurchaseHeader);
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] "Error Message" page is open, where are two errors:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] 1st line, where "Context" is 'Purchase Line: Order, 1001, 10000', "Field Name" is 'VAT Prod. Posting Group',
        Assert.IsTrue(TempErrorMessage.FindFirst(), 'must be the 1st error line');
        TempErrorMessage.TestField("Context Record ID", PurchaseLine[1].RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Line");
        TempErrorMessage.TestField("Context Field Number", PurchaseLine[1].FieldNo("VAT Prod. Posting Group"));
        // [THEN] "Source" is 'VAT Posting Setup', "Field Name" is 'Blocked'
        VATPostingSetup.Get(PurchaseLine[1]."VAT Bus. Posting Group", PurchaseLine[1]."VAT Prod. Posting Group");
        TempErrorMessage.TestField("Record ID", VATPostingSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"VAT Posting Setup");
        TempErrorMessage.TestField("Field Number", VATPostingSetup.FieldNo(Blocked));
        TempErrorMessage.TestField("Additional Information", CheckPurchLineMsg);
        TempErrorMessage.TestField("Support Url", GetLink(ForwardLinkMgt.GetHelpCodeForFinanceSetupVAT()));
        // [THEN] 2nd line, where "Context" is 'Purchase Line: Order, 1001, 20000', "Field Name" is 'Gen. Prod. Posting Group',
        Assert.IsTrue(TempErrorMessage.Next() = 1, 'must be the 2nd error line');
        TempErrorMessage.TestField("Context Record ID", PurchaseLine[2].RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Purchase Line");
        TempErrorMessage.TestField("Context Field Number", PurchaseLine[2].FieldNo("Gen. Prod. Posting Group"));
        // [THEN] "Source" is General Posting Setup', "Field Name" is 'Blocked', "Support Link" is 'FinancePostingGroups'
        GeneralPostingSetup.Get(PurchaseLine[2]."Gen. Bus. Posting Group", PurchaseLine[2]."Gen. Prod. Posting Group");
        TempErrorMessage.TestField("Record ID", GeneralPostingSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Posting Setup");
        TempErrorMessage.TestField("Field Number", GeneralPostingSetup.FieldNo(Blocked));
        TempErrorMessage.TestField("Additional Information", CheckPurchLineMsg);
        TempErrorMessage.TestField("Support Url", GetLink(ForwardLinkMgt.GetHelpCodeForFinancePostingGroups()));
        UnblockAllSetups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T900_PreviewWithOneLoggedAndOneDirectError()
    var
        PurchHeader: Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: one logged and one directly thrown error.
        Initialize();

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [WHEN] Preview Posting of Purchase Order '1002'
        asserterror PreviewPurchDocument(PurchHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] Second line, where Description is 'There is nothing to post', Context is 'Purchase Header: Order, 1002'
        TempErrorMessage.FindLast();
        TempErrorMessage.TestField("Message", DocumentErrorsMgt.GetNothingToPostErrorMsg());
        TempErrorMessage.TestField("Context Record ID", PurchHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T940_BatchPostingWithOneLoggedAndOneDirectError()
    var
        PurchHeader: array[3] of Record "Purchase Header";
        TempErrorMessage: Record "Error Message" temporary;
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        VendorNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting]
        // [SCENARIO] Batch posting of two documents (in current session) opens "Error Messages" page that contains two lines per document.
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019, and nothing to post
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchHeader(PurchHeader[1], PurchHeader[1]."Document Type"::Order, VendorNo);
        PurchHeaderToPost(PurchHeader[1]);
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[2], VendorNo);

        // [WHEN] Post both documents as a batch
        LibraryErrorMessage.TrapErrorMessages();
        PurchHeader[3].SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader[3], 2, '');

        // [THEN] Opened page "Error Messages" with 3 lines:
        // [THEN] 2 lines for Order '1002' and 1 line for Invoice '1003'
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 3);
        // [THEN] The first error for Order '1002' is 'Posting Date is not within your range of allowed posting dates.'
        Clear(RegisterID);
        TempErrorMessage.Get(1);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage."Message");
        Assert.AreEqual(PurchHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 1st error');
        // [THEN] The second error for Order '1002' is 'There is nothing to post'
        TempErrorMessage.Get(2);
        Assert.ExpectedMessage(DocumentErrorsMgt.GetNothingToPostErrorMsg(), TempErrorMessage."Message");
        Assert.AreEqual(PurchHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 2nd error');
        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        TempErrorMessage.Get(3);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage."Message");
        Assert.AreEqual(PurchHeader[2].RecordId, TempErrorMessage."Context Record ID", 'Context for 3rd error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T950_BatchPostingWithOneLoggedAndOneDirectErrorBackground()
    var
        PurchHeader: array[3] of Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        PurchBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of two documents (in background) verifies "Error Messages" that contains zero lines because we don't subscribe to the error message handler
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[1], VendorNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchHeader[2], VendorNo);

        // [WHEN] Post both documents as a batch
        JobQueueEntry.DeleteAll();
        PurchHeader[3].SetRange("Buy-from Vendor No.", VendorNo);
        PurchBatchPostMgt.RunWithUI(PurchHeader[3], 2, '');
        JobQueueEntry.FindSet();
        repeat
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
        until JobQueueEntry.Next() = 0;

        // [THEN] "Error Message" table contains 2 lines:
        // [THEN] 2 lines for Invoice '1002' and 1 line for Invoice '1003'
        // [THEN] The first error for Invoice '1002' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", PurchHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 0);

        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        ErrorMessage.SetRange("Context Record ID", PurchHeader[2].RecordId);
        Assert.RecordCount(ErrorMessage, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReceivingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting purchase invoice when the reserved Receiving No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate());
        PurchSetup.Get();
        PurchSetup."Receipt on Invoice" := true;
        PurchSetup.Modify();
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Purchase invoice where we create a Purch. Rcpt. Header record and the next Receiving No. already exists.
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);

        // Use No. Series from purchases setup.
        PurchHeader."Receiving No. Series" := PurchSetup."Posted Receipt Nos.";
        LibraryUtility.GetNoSeriesLine(PurchHeader."Receiving No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        PurchRcptHeader.SetCurrentKey("No.");
        PurchRcptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(PurchRcptHeader."No.");

        // Sanity check.
        Assert.AreEqual(PurchRcptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting purchase invoice.
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", PurchHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField("Message", StrSubstNo(PurchRcptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Purchase Header field Receiving No. is blank.
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual('', PurchHeader."Receiving No.", 'Receiving No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReturnShipmentNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        PurchHeader: Record "Purchase Header";
        ReturnShptHeader: Record "Return Shipment Header";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting purchase return order when the reserved Return Shipment No. is already existing.
        // This can occur when a user manually changes the Last No. Used of a No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate());
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Purchase return order where we create a Return Shipment Header record and the next Return Shipment No. already exists.
        LibraryPurchase.CreatePurchaseReturnOrder(PurchHeader);
        PurchHeader.Ship := true;

        // Use No. Series from purchases setup.
        PurchSetup.Get();
        PurchHeader."Return Shipment No. Series" := PurchSetup."Posted Return Shpt. Nos.";
        LibraryUtility.GetNoSeriesLine(PurchHeader."Return Shipment No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        ReturnShptHeader.SetCurrentKey("No.");
        ReturnShptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(ReturnShptHeader."No.");

        // Sanity check.
        Assert.AreEqual(ReturnShptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting purchase return order.
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", PurchHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField("Message", StrSubstNo(ReturnShptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Purchase Header field Return Shipment No. is blank.
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual('', PurchHeader."Return Shipment No.", 'Return Shipment No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PostingInvoicePostingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting purchase invoice when the reserved Posting No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate());
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Purchase invoice where we create a Purch. Inv. Header record and the next Posting No. already exists.
        LibraryPurchase.CreatePurchaseInvoice(PurchHeader);

        // Use No. Series from purchases setup.
        PurchSetup.Get();
        PurchHeader."Posting No. Series" := PurchSetup."Posted Invoice Nos.";
        LibraryUtility.GetNoSeriesLine(PurchHeader."Posting No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        PurchInvHeader.SetCurrentKey("No.");
        PurchInvHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(PurchInvHeader."No.");

        // Sanity check.
        Assert.AreEqual(PurchInvHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting purchase order.
        PurchHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", PurchHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField("Message", StrSubstNo(PurchInvHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Purchase Header field Posting No. is blank.
        PurchHeader.Get(PurchHeader."Document Type", PurchHeader."No.");
        Assert.AreEqual('', PurchHeader."Posting No.", 'Posting No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DropShipmentSalesDimErrorContext()
    var
        DimensionValue: Record "Dimension Value";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [Drop Shipment] [Dimensions]
        // [SCENARIO 426608] Dimension error context points to sales line when posting drop shipment purchase order
        Initialize();

        // [GIVEN] Create dimension "D" with value "DV"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Sales Order with Drop Shipment True and Sales Line for item "I" and mandatory dimension "D"
        CreateSalesOrderWithPurchasingCode(
            SalesLine, DimensionValue, LibrarySales.CreateCustomerNo(), CreatePurchasingCodeWithDropShipment(), LibraryPurchase.CreateVendorNo());

        // [GIVEN] Run Carry Out Action Msg. - Req. batch job.
        CarryOutActionMsgOnReqWkshForDropShipment(SalesLine);

        // [GIVEN] Get created puchase order
        GetPurchHeader(PurchaseHeader, SalesLine."No.");

        // [GIVEN] Clear sales line dimension to cause error
        SalesLine.Find();
        SalesLine.Validate("Dimension Set ID", 0);
        SalesLine.Modify();

        // [WHEN] Post receive for purchase order
        LibraryErrorMessage.TrapErrorMessages();
        PurchaseHeader.Receive := true;
        PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post");

        // [THEN] Dimension error has context of sales line
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        TempErrorMessage.TestField("Context Record ID", SalesLine.RecordId);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Purch. Document Posting Errors");
        LibraryErrorMessage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Purch. Document Posting Errors");

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Purch. Document Posting Errors");
    end;

    local procedure GetLink(LinkCode: code[30]): Text[250];
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        if NamedForwardLink.Get(LinkCode) then
            exit(NamedForwardLink.Link);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesLine: Record "Sales Line"; DimensionValue: Record "Dimension Value"; CustomerNo: Code[20]; PurchasingCode: Code[10]; VendorNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        Item.Modify(true);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", "Default Dimension Value Posting Type"::"Code Mandatory");
        DefaultDimension.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchasingCodeWithDropShipment(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CarryOutActionMsgOnReqWkshForDropShipment(SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        CreateReqWkshTemplateName(RequisitionWkshName, ReqWkshTemplate);
        GetDropShipmentOnReqWksht(SalesLine, RequisitionLine, RequisitionWkshName.Name, ReqWkshTemplate.Name);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure GetDropShipmentOnReqWksht(var SalesLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Code[10]; ReqWkshTemplate: Code[10])
    var
        RetrieveDimensionsFrom: array[2] of Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate, RequisitionWkshName);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
    end;

    local procedure CreateReqWkshTemplateName(var RequisitionWkshName: Record "Requisition Wksh. Name"; var ReqWkshTemplate: Record "Req. Wksh. Template")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure GetPurchHeader(var PurchHeader: Record "Purchase Header"; No: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", No);
        PurchLine.FindFirst();
        PurchHeader.Get(PurchLine."Document Type"::Order, PurchLine."Document No.");
    end;

    local procedure PreviewPurchDocument(PurchHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchHeaderToPost(PurchHeader);
        LibraryErrorMessage.TrapErrorMessages();
        PurchPostYesNo.Preview(PurchHeader);
    end;

    local procedure PurchHeaderToPost(var PurchHeader: Record "Purchase Header")
    begin
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchHeader.Modify();
        Commit();
    end;

    local procedure UnblockAllSetups()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GeneralPostingSetup.ModifyAll(Blocked, false);
        VATPostingSetup.ModifyAll(Blocked, false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

