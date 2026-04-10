codeunit 132501 "Sales Document Posting Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        PostingDateNotAllowedErr: Label 'Posting Date is not within your range of allowed posting dates.';
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        IsInitialized: Boolean;
        CheckSalesLineMsg: Label 'Check sales document line.';

        // Expected error messages (from code unit 80).
        SalesReturnRcptHeaderConflictErr: Label 'Cannot post the sales return because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Return Receipt No.';
        SalesShptHeaderConflictErr: Label 'Cannot post the sales shipment because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Shipping No.';
        SalesInvHeaderConflictErr: Label 'Cannot post the sales invoice because its ID, %1, is already assigned to a record. Update the number series and try again.', Comment = '%1 = Posting No.';
        SetupBlockedErr: Label 'Setup is blocked in %1 for %2 %3 and %4 %5.', Comment = '%1 - General/VAT Posting Setup, %2 %3 %4 %5 - posting groups.';
        CampaignNoErr: Label 'Camaign No. must be not gerenate error on update.';

    [Test]
    [Scope('OnPrem')]
    procedure T001_PostingDateIsInNotAllowedPeriodInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        GeneralLedgerSetupPage: TestPage "General Ledger Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in G/L Setup
        Initialize();
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("Posting Date", WorkDate());

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message", PostingDateNotAllowedErr);
        // [THEN] Call Stack contains '"Sales-Post"(CodeUnit 80).CheckAndUpdate '
        Assert.ExpectedMessage('"Sales-Post"(CodeUnit 80).CheckAndUpdate ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Header");
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("Posting Date"));
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
        SalesInvoicePage.Trap();
        LibraryErrorMessage.DrillDownOnContext();
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."Posting Date".AssertEquals(WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T002_PostingDateIsInNotAllowedPeriodInUserSetup()
    var
        SalesHeader: Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        UserSetup: Record "User Setup";
        UserSetupPage: TestPage "User Setup";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [SCENARIO] Posting of document, where "Posting Date" is out of the allowed period, set in User Setup.
        Initialize();
        // [GIVEN] "Allow Posting To" is 31.12.2018 in "User Setup"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup."Allow Posting To" := WorkDate() - 1;
        UserSetup.Modify();
        // [GIVEN] Invoice '1001', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.TestField("Posting Date", WorkDate());

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where is one error:
        // [THEN] "Posting Date is not within your range of allowed posting dates."
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 1);
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField("Message", PostingDateNotAllowedErr);
        // [THEN] Call Stack contains '"Sales-Post"(CodeUnit 80).CheckAndUpdate '
        Assert.ExpectedMessage('"Sales-Post"(CodeUnit 80).CheckAndUpdate ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Sales Header: Invoice, 1001', "Field Name" is 'Posting Date',
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
        TempErrorMessage.TestField("Context Field Number", SalesHeader.FieldNo("Posting Date"));
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
        SalesInvoicePage.Trap();
        LibraryErrorMessage.DrillDownOnContext();
        // [THEN] opens "Sales Invoice" page.
        SalesInvoicePage."Posting Date".AssertEquals(WorkDate());

        // TearDown
        UserSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T011_GenPostingSetupIsBlocked()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] Posting of document, where "General Posting Setup" is blocked
        Initialize();
        UnblockAllSetups();

        // [GIVEN] Invoice '1001', where "Gen. Bus. Posting Group" is 'GB',"Gen. Bus. Posting Group" is 'GP'
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        // [GIVEN] General Posting Setup for 'GB' and 'GP' is blocked
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Blocked := true;
        GeneralPostingSetup.Modify();

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

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
        // [THEN] Call Stack contains '"Sales-Post"(CodeUnit 80).CheckBlockedPostingGroups '
        Assert.ExpectedMessage('"Sales-Post"(CodeUnit 80).CheckBlockedPostingGroups ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Sales Line: Invoice, 1001, 10000', "Field Name" is 'Gen. Prod. Posting Group',
        TempErrorMessage.TestField("Context Record ID", SalesLine.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Line");
        TempErrorMessage.TestField("Context Field Number", SalesLine.FieldNo("Gen. Prod. Posting Group"));
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
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [SCENARIO] Posting of document, where "VAT Posting Setup" is blocked
        Initialize();
        UnblockAllSetups();

        // [GIVEN] Invoice '1001', where "VAT Bus. Posting Group" is 'VB',"VAT Bus. Posting Group" is 'VP'
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        // [GIVEN] VAT Posting Setup for 'VB' and 'VP' is blocked
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.Blocked := true;
        VATPostingSetup.Modify();

        // [WHEN] Post Invoice '1001'
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

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
        // [THEN] Call Stack contains '"Sales-Post"(CodeUnit 80).CheckBlockedPostingGroups '
        Assert.ExpectedMessage('"Sales-Post"(CodeUnit 80).CheckBlockedPostingGroups ', TempErrorMessage.GetErrorCallStack());
        // [THEN] "Context" is 'Sales Line: Invoice, 1001, 10000', "Field Name" is 'VAT Prod. Posting Group',
        TempErrorMessage.TestField("Context Record ID", SalesLine.RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Line");
        TempErrorMessage.TestField("Context Field Number", SalesLine.FieldNo("VAT Prod. Posting Group"));
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
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        Customer: Record Customer;
        TempErrorMessage: Record "Error Message" temporary;
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        InstructionMgt: Codeunit "Instruction Mgt.";
        PostingSetupManagement: Codeunit PostingSetupManagement;
    begin
        // [SCENARIO] Posting of document with 2 lines, where "VAT Posting Setup" and "Gen. Posting Setup" are blocked
        Initialize();
        UnblockAllSetups();
        // [GIVEN] Enabled posting setup notification
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(PostingSetupManagement.GetPostingSetupNotificationID());

        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] G/L Account 'AV', where VAT Prod Posting Group 'V-NEW', that is not used in setup
        LibraryERM.CreateGLAccount(GLAccount[1]);
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        GeneralPostingSetup.FindFirst();
        GLAccount[1]."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GLAccount[1]."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        GLAccount[1].Modify();
        // [GIVEN] G/L Account 'AG', where Gen. Prod Posting Group 'G-NEW', that is not used in setup
        LibraryERM.CreateGLAccount(GLAccount[2]);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
        GLAccount[2]."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount[2]."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount[2].Modify();

        // [GIVEN] Order '1001', with two lines:
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // [GIVEN] 1st line for G/L Account 'AV', where VAT Prod Posting Group 'V-NEW'
        LibrarySales.CreateSalesLine(
            SalesLine[1], SalesHeader, "Sales Line Type"::"G/L Account", GLAccount[1]."No.", 1);
        // [GIVEN] 2nd line for G/L Account 'AG', where Gen. Prod Posting Group 'G-NEW'
        LibrarySales.CreateSalesLine(
            SalesLine[2], SalesHeader, "Sales Line Type"::"G/L Account", GLAccount[2]."No.", 1);

        // [WHEN] Post Order '1001'
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeaderToPost(SalesHeader);
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] "Error Message" page is open, where are two errors:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] 1st line, where "Context" is 'Sales Line: Order, 1001, 10000', "Field Name" is 'VAT Prod. Posting Group',
        Assert.IsTrue(TempErrorMessage.FindFirst(), 'must be the 1st error line');
        TempErrorMessage.TestField("Context Record ID", SalesLine[1].RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Line");
        TempErrorMessage.TestField("Context Field Number", SalesLine[1].FieldNo("VAT Prod. Posting Group"));
        // [THEN] "Source" is 'VAT Posting Setup', "Field Name" is 'Blocked'
        VATPostingSetup.Get(SalesLine[1]."VAT Bus. Posting Group", SalesLine[1]."VAT Prod. Posting Group");
        TempErrorMessage.TestField("Record ID", VATPostingSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"VAT Posting Setup");
        TempErrorMessage.TestField("Field Number", VATPostingSetup.FieldNo(Blocked));
        TempErrorMessage.TestField("Additional Information", CheckSalesLineMsg);
        TempErrorMessage.TestField("Support Url", GetLink(ForwardLinkMgt.GetHelpCodeForFinanceSetupVAT()));
        // [THEN] 2nd line, where "Context" is 'Sales Line: Order, 1001, 20000', "Field Name" is 'Gen. Prod. Posting Group',
        Assert.IsTrue(TempErrorMessage.Next() = 1, 'must be the 2nd error line');
        TempErrorMessage.TestField("Context Record ID", SalesLine[2].RecordId);
        TempErrorMessage.TestField("Context Table Number", DATABASE::"Sales Line");
        TempErrorMessage.TestField("Context Field Number", SalesLine[2].FieldNo("Gen. Prod. Posting Group"));
        // [THEN] "Source" is General Posting Setup', "Field Name" is 'Blocked', "Support Link" is 'FinancePostingGroups'
        GeneralPostingSetup.Get(SalesLine[2]."Gen. Bus. Posting Group", SalesLine[2]."Gen. Prod. Posting Group");
        TempErrorMessage.TestField("Record ID", GeneralPostingSetup.RecordId);
        TempErrorMessage.TestField("Table Number", DATABASE::"General Posting Setup");
        TempErrorMessage.TestField("Field Number", GeneralPostingSetup.FieldNo(Blocked));
        TempErrorMessage.TestField("Additional Information", CheckSalesLineMsg);
        TempErrorMessage.TestField("Support Url", GetLink(ForwardLinkMgt.GetHelpCodeForFinancePostingGroups()));
        UnblockAllSetups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T900_PreviewWithOneLoggedAndOneDirectError()
    var
        TempErrorMessage: Record "Error Message" temporary;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Preview]
        // [SCENARIO] Failed posting preview opens "Error Messages" page that contains two lines: one logged and one directly thrown error.
        Initialize();

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Preview posting of Order '1002'
        asserterror PreviewSalesDocument(SalesHeader);

        // [THEN] Error message is <blank>
        Assert.ExpectedError('');
        // [THEN] Opened page "Error Messages" with two lines:
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Assert.RecordCount(TempErrorMessage, 2);
        // [THEN] Second line, where Description is 'There is nothing to post', Context is 'Sales Header: Order, 1002'
        TempErrorMessage.FindLast();
        TempErrorMessage.TestField("Message", DocumentErrorsMgt.GetNothingToPostErrorMsg());
        TempErrorMessage.TestField("Context Record ID", SalesHeader.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T940_BatchPostingWithOneLoggedAndOneDirectError()
    var
        SalesHeader: array[3] of Record "Sales Header";
        TempErrorMessage: Record "Error Message" temporary;
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        CustomerNo: Code[20];
        RegisterID: Guid;
    begin
        // [FEATURE] [Batch Posting]
        // [SCENARIO] Batch posting of two documents (in the current session) opens "Error Messages" page that contains two lines per document.
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Order '1002', where "Posting Date" is 01.01.2019, and nothing to post
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader[1], SalesHeader[1]."Document Type"::Order, CustomerNo);
        SalesHeaderToPost(SalesHeader[1]);
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);

        // [WHEN] Post both documents as a batch
        LibraryErrorMessage.TrapErrorMessages();
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');

        // [THEN] Opened page "Error Messages" with 3 lines:
        // [THEN] 2 lines for Order '1002' and 1 line for Invoice '1003'
        LibraryErrorMessage.GetErrorMessages(TempErrorMessage);
        Clear(RegisterID);
        TempErrorMessage.SetRange("Register ID", RegisterID);
        Assert.RecordCount(TempErrorMessage, 3);
        // [THEN] The first error for Order '1002' is 'Posting Date is not within your range of allowed posting dates.'

        TempErrorMessage.Get(1);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage."Message");
        Assert.AreEqual(SalesHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 1st error');
        // [THEN] The second error for Order '1002' is 'There is nothing to post'
        TempErrorMessage.Get(2);
        Assert.ExpectedMessage(DocumentErrorsMgt.GetNothingToPostErrorMsg(), TempErrorMessage."Message");
        Assert.AreEqual(SalesHeader[1].RecordId, TempErrorMessage."Context Record ID", 'Context for 2nd error');
        // [THEN] The Error for Invoice '1003' is 'Posting Date is not within your range of allowed posting dates.'
        TempErrorMessage.Get(3);
        Assert.ExpectedMessage(PostingDateNotAllowedErr, TempErrorMessage."Message");
        Assert.AreEqual(SalesHeader[2].RecordId, TempErrorMessage."Context Record ID", 'Context for 3rd error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T950_BatchPostingWithOneLoggedAndOneDirectErrorBackground()
    var
        SalesHeader: array[3] of Record "Sales Header";
        ErrorMessage: Record "Error Message";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of two documents (in background) verifies "Error Messages" that contains zero lines as we do not subscribe to the error handler mgt.
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[1], CustomerNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();
        // [GIVEN] Invoice '1003', where "Posting Date" is 01.01.2019
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[2], CustomerNo);

        // [WHEN] Post both documents as a batch via Job Queue
        JobQueueEntry.DeleteAll();
        SalesHeader[3].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[3], 2, '');
        JobQueueEntry.FindSet();
        repeat
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
            JobQueueEntry.Modify();
            asserterror LibraryJobQueue.RunJobQueueDispatcher(JobQueueEntry);
            LibraryJobQueue.RunJobQueueErrorHandler(JobQueueEntry);
        until JobQueueEntry.Next() = 0;

        // [THEN] "Error Message" table contains 0 lines:
        ErrorMessage.SetRange("Context Record ID", SalesHeader[1].RecordId);
        Assert.RecordCount(ErrorMessage, 0);
        ErrorMessage.SetRange("Context Record ID", SalesHeader[2].RecordId);
        Assert.RecordCount(ErrorMessage, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure BatchPostingWithErrorsShowJobQueueErrorsBackground()
    var
        SalesHeader: array[2] of Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryDimension: Codeunit "Library - Dimension";
        JobQueueEntries: TestPage "Job Queue Entries";
        ErrorMessages: TestPage "Error Messages";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Batch Posting] [Job Queue]
        // [SCENARIO] Batch posting of document (in background) verifies "Error Messages" page that contains one lines for Job Queue Entry (last error only)
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] "Allow Posting To" is 31.12.2018 in "General Ledger Setup"
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);
        // [GIVEN] Invoice '1002', where "Posting Date" is 01.01.2019, and no mandatory dimension
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader[1], CustomerNo);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension.Modify();

        // [WHEN] Post both documents as a batch via Job Queue
        JobQueueEntry.DeleteAll();
        SalesHeader[2].SetRange("Sell-to Customer No.", CustomerNo);
        SalesBatchPostMgt.RunWithUI(SalesHeader[2], 2, '');
        JobQueueEntry.SetRange("Record ID to Process", SalesHeader[1].RecordId);
        JobQueueEntry.FindFirst();
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader[1].RecordId, true);
        JobQueueEntry.FindFirst();

        // [THEN] "Error Message" page contains 2 lines:
        JobQueueEntries.OpenView();
        JobQueueEntries.GoToRecord(JobQueueEntry);
        ErrorMessages.Trap();
        JobQueueEntries.ShowError.Invoke();
        ErrorMessages.First();
        Assert.IsSubstring(ErrorMessages.Description.Value, PostingDateNotAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReturnReceiptNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        SalesHeader: Record "Sales Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting sales credit memo when the reserved Return Receipt No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate());
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Sales credit memo where we create a Return Receipt Header record and the next Return Recipt No. already exists.
        LibrarySales.CreateSalesCreditMemo(SalesHeader);

        // Use No. Series from sales setup.
        SalesSetup.Get();
        SalesHeader."Return Receipt No. Series" := SalesSetup."Posted Return Receipt Nos.";
        LibraryUtility.GetNoSeriesLine(SalesHeader."Return Receipt No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        ReturnRcptHeader.SetCurrentKey("No.");
        ReturnRcptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(ReturnRcptHeader."No.");

        // Sanity check.
        Assert.AreEqual(ReturnRcptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting sales credit memo.
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField("Message", StrSubstNo(SalesReturnRcptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Sales Header field Return Receipt No. is blank.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual('', SalesHeader."Return Receipt No.", 'Return Receipt No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingShippingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting sales invoice when the reserved Shipping No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate());
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Sales invoice where we create a Sales Shipment Header record and the next Shipping No. already exists.
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Use No. Series from sales setup.
        SalesSetup.Get();
        SalesHeader."Shipping No. Series" := SalesSetup."Posted Shipment Nos.";
        LibraryUtility.GetNoSeriesLine(SalesHeader."Shipping No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        SalesShptHeader.SetCurrentKey("No.");
        SalesShptHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(SalesShptHeader."No.");

        // Sanity check.
        Assert.AreEqual(SalesShptHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting sales invoice.
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField("Message", StrSubstNo(SalesShptHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Sales Header field Return Shipping No. is blank.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual('', SalesHeader."Shipping No.", 'Shipping No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPostingNoConflictErrorHandling()
    var
        ErrorMessage: Record "Error Message";
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeriesLine: Record "No. Series Line";
        LastNoUsed: Text;
        OriginalNoSeriesLine: Record "No. Series Line";
    begin
        // [SCENARIO] Should properly handle posting sales invoice when the reserved Posting No. is already existing.
        // This can occur when a user manually changes the Last No. Used of the No Series Line such that the next number
        // to use has already been used.
        Initialize();
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate());
        LibraryErrorMessage.TrapErrorMessages();

        // [GIVEN] Sales invoice where we create a Sales Invoice Header record and the next Posting No. already exists.
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // Use No. Series from sales setup.
        SalesSetup.Get();
        SalesHeader."Posting No. Series" := SalesSetup."Posted Invoice Nos.";
        LibraryUtility.GetNoSeriesLine(SalesHeader."Posting No. Series", NoSeriesLine);

        // Store original values for tear down.
        OriginalNoSeriesLine.TransferFields(NoSeriesLine, false);

        SalesInvHeader.SetCurrentKey("No.");
        SalesInvHeader.FindFirst();
        LastNoUsed := LibraryUtility.DecStr(SalesInvHeader."No.");

        // Sanity check.
        Assert.AreEqual(SalesInvHeader."No.", IncStr(LastNoUsed), 'DecStr gave incorrect result.');

        NoSeriesLine."Starting No." := LastNoUsed;
        NoSeriesLine."Last No. Used" := LastNoUsed;
        NoSeriesLine."Ending No." := IncStr(IncStr(LastNoUsed));
        NoSeriesLine."Warning No." := NoSeriesLine."Ending No.";
        NoSeriesLine.Modify();

        // [WHEN] Posting sales invoice.
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");

        // [THEN] An error is thrown.
        ErrorMessage.SetRange("Context Record ID", SalesHeader.RecordId);
        Assert.RecordCount(ErrorMessage, 1);
        ErrorMessage.FindFirst();
        ErrorMessage.TestField("Message", StrSubstNo(SalesInvHeaderConflictErr, IncStr(LastNoUsed)));

        // [THEN] The Sales Header field Return Posting No. is blank.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual('', SalesHeader."Posting No.", 'Posting No. was not blank.');

        // TearDown: Reset No Series. Line.
        NoSeriesLine.TransferFields(OriginalNoSeriesLine, false);
        NoSeriesLine.Modify();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    procedure VerifyPostShipmentForSpecialOrdersWithReservationsAndOneNonInventoryItem()
    var
        NonInventoryItem, Item : Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 464478] Verify Post Shipment for Special Order with Reservation Entries and one Non Inventory Item
        Initialize();

        // [GIVEN] Crate two Items, which one is Non Inventory
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Order with Purchasing Code and release document
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, NonInventoryItem."No.", Item."No.", 2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Requisition Lines
        FindSalesLine(SalesLine, SalesHeader);
        GetSalesOrder(ReqWkshName, SalesLine);

        // [GIVEN] Update Vendor on Requisition Lines
        UpdateVendorOnRequisitionLine(RequisitionLine, ReqWkshName, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Order from Requisition Worksheet
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Find Created Purchase Document
        PurchaseHeader.SetRange("Buy-from Vendor No.", RequisitionLine."Vendor No.");
        PurchaseHeader.FindFirst();

        // [GIVEN] Reserve items on Purchase Order
        ReservePurchaseLines(PurchaseHeader."No.");

        // [WHEN] Release and Post Receive on Purchase Order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Post Shipment on Sales Order without errors
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    procedure VerifyPostShipmentForSpecialOrdersWithReservationsAndOneServiceItem()
    var
        ServiceItem, Item : Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 464478] Verify Post Shipment for Special Order with Reservation Entries and one Service Item
        Initialize();

        // [GIVEN] Crate two Items, which one is Service
        LibraryInventory.CreateServiceTypeItem(ServiceItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Order with Purchasing Code and release document
        CreateSalesOrderWithPurchasingCodeSpecialOrder(SalesHeader, ServiceItem."No.", Item."No.", 2);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Requisition Lines
        FindSalesLine(SalesLine, SalesHeader);
        GetSalesOrder(ReqWkshName, SalesLine);

        // [GIVEN] Update Vendor on Requisition Lines
        UpdateVendorOnRequisitionLine(RequisitionLine, ReqWkshName, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Order from Requisition Worksheet
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Find Created Purchase Document
        PurchaseHeader.SetRange("Buy-from Vendor No.", RequisitionLine."Vendor No.");
        PurchaseHeader.FindFirst();

        // [GIVEN] Reserve items on Purchase Order
        ReservePurchaseLines(PurchaseHeader."No.");

        // [WHEN] Release and Post Receive on Purchase Order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Post Shipment on Sales Order without errors
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SalesOrderShouldNotThrowErrorWhenCampaignNoIsUpdated()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Campaign: Record Campaign;
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCINARIO 527088] Line & Invoice Discounts disappears once you re-open Sales Order to add a Campaign no.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Cretae a Sales Order.
        LibrarySales.CreateSalesOrder(SalesHeader);

        // [GIVEN] Cretae Sales Line for the Sales Order.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [GIVEN] Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Reoprn Ssales Docuement.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [GIVEN] Create a Campaign.
        LibraryMarketing.CreateCampaign(Campaign);

        // [GIVEN] Open Sales Order to put Campaign No.
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Campaign No.".SetValue(Campaign."No.");

        // [THEN] Verify Campaign No. is udpated.
        Assert.AreEqual(
            Campaign."No.",
            SalesOrder."Campaign No.".Value(),
            CampaignNoErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Document Posting Errors");
        LibraryErrorMessage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Document Posting Errors");

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Document Posting Errors");
    end;

    local procedure GetLink(LinkCode: code[30]): Text[250];
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        if NamedForwardLink.Get(LinkCode) then
            exit(NamedForwardLink.Link);
    end;

    local procedure PreviewSalesDocument(SalesHeader: Record "Sales Header")
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesHeaderToPost(SalesHeader);
        LibraryErrorMessage.TrapErrorMessages();
        SalesPostYesNo.Preview(SalesHeader);
    end;

    local procedure SalesHeaderToPost(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader.Modify();
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

    local procedure ReservePurchaseLines(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", No);
        PurchaseOrder.PurchLines.First();
        PurchaseOrder.PurchLines.Reserve.Invoke();
        PurchaseOrder.PurchLines.Next();
        PurchaseOrder.PurchLines.Reserve.Invoke();
    end;

    local procedure UpdateVendorOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name"; VendorNo: Code[20])
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.FindSet();
        repeat
            RequisitionLine.Validate("Vendor No.", VendorNo);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure GetSalesOrder(var RequisitionWkshName: Record "Requisition Wksh. Name"; SalesLine: Record "Sales Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
    begin
        ReqWkshTemplate.SetRange(Type, RequisitionWkshName."Template Type"::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Commit();
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
        RunGetSalesOrders(SalesLine, RequisitionLine);
    end;

    local procedure RunGetSalesOrders(SalesLine: Record "Sales Line"; RequisitionLine: Record "Requisition Line")
    var
        GetSalesOrders: Report "Get Sales Orders";
        RetrieveDimensions: Option Item,"Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        Clear(GetSalesOrders);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(RetrieveDimensions::Item);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 1);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.RunModal();
    end;

    local procedure CreateSalesOrderWithPurchasingCodeSpecialOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        Purchasing: Record Purchasing;
    begin
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, ItemNo, ItemNo2, Quantity, Purchasing.Code);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; PurchasingCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo2, Quantity);
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            SalesLine.Validate("Purchasing Code", PurchasingCode);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure CreatePurchasingCodeWithSpecialOrder(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;
}

