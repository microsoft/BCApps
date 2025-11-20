codeunit 136302 "Job Consumption Purchase"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Job]
        Initialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        LocationReceiveYesPutAwayNoBinsNo: Record Location;
        LocationReceiveYesPutAwayNoBinsYes: Record Location;
        LocationReceiveYesPutAwayYesBinsNo: Record Location;
        LocationReceiveYesPutAwayYesBinsYes: Record Location;
        LocationDirectedPutAwayAndPick: Record Location;
        LocationReceiveNoPutAwayYesBinsNo: Record Location;
        LocationReceiveNoPutAwayYesBinsYes: Record Location;
        LibraryErrorMessage: Codeunit "Library - Error Message";
        LibraryJob: Codeunit "Library - Job";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CodeMandatoryDimensionErr: Label 'The dimensions used in Order %1, line no. %2 are invalid (Error: Select a %3 for the %4 %5 for Project %6.).', Comment = '%1=Field value,%2=Field value,%3=Field value,%4=Field name,%5=Field name,%6=Field name';
        SameCodeOrNoCodeDimensionErr: Label 'The dimensions used in Order %1, line no. %2 are invalid (Error: The %3 must be %4 for %5 %6 for %7 %8. Currently it''s %9.', Comment = '%1=Field value,%2=Field value, %3 = "Dimension value code" caption, %4 = expected "Dimension value code" value, %5 = "Dimension code" caption, %6 = "Dimension Code" value, %7 = Table caption (Vendor), %8 = Table value (XYZ), %9 = current "Dimension value code" value';
        BlankLbl: Label 'blank';
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTemplates: Codeunit "Library - Templates";
        Initialized: Boolean;
        WrongDimJobLedgerEntryErr: Label 'Wrong Dim on Project Ledger entry %1! Expected ID: %2, Actual ID: %3.';
        FieldErr: Label '%1 must be equal  %2 in %3.';
        ValueMustMatchErr: Label '%1 must equal to %2.';
        EmptyValueErr: Label '%1 is empty in %2';
        WrongTotalCostAmtErr: Label 'Total cost amount must  be 0 in Posted Purchase Receipt %1.', Comment = '%1 = Document No. (e.g. "Total cost amount must be 0 in Posted Purchase Receipt 107031").';
        JobPlanningLineQuantityErr: Label 'The Project Planning Line Quantity should not change.';
        MustNotBeChangedErr: Label '%1 must not be changed', Comment = '%1 = Field caption';

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateOnJobLedgerEntry()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify Document Date on Job Ledger Entry.

        // [GIVEN] Create Purchase Invoice with Job.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, CreateItem());

        // [WHEN] Post the Purhcase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Document Date on Job Ledger Entry.
        VerifyDocumentDateOnJobLedgerEntry(JobTask."Job No.", DocumentNo, PurchaseHeader."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineWithFullQuantity()
    var
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify Quantity on Job Planning Line when Purchase Order posted with full Quantity.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        PreparePurchHeaderWithJobPlanningNo(Quantity, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineWithPartialQuantity()
    var
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify Quantity on Job Planning Line when Purchase Order posted with partial Quantity.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        PreparePurchHeaderWithJobPlanningNo(Quantity, Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreparePurchHeaderWithRemainingQty()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
        QtyToReceive: Decimal;
    begin
        // [SCENARIO] Verify Quantity on Job Planning Line when Purchase Order posted with Remaining Quantity.

        // [GIVEN] Create Purchase Order with Job Planning Line No. and update Quantity To Receive on Purchase Line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        QtyToReceive := Quantity / 2;
        PreparePurchHeaderAndJobPlanningLine(PurchaseHeader, JobPlanningLine, Quantity, QtyToReceive);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        UpdatePurchLineQtyToReceive(PurchaseHeader, Quantity - QtyToReceive);

        // [WHEN] Post Purchase Order with Remaining Quantity.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Quantity on Job Planning Line.
        VerifyQuantityOnJobPlanningLine(JobPlanningLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineOnPurchaseOrderPartialQtyToInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify Quantity on Job Planning Line when Purchase Order after updating Qty. to Invoice posted with partial Quantity.

        // [GIVEN] Create Purchase Order with Job Planning Line No. and update Quantity To Invoice on Purchase Line.
        Initialize();
        Quantity := CreatePurchaseOrderWithUpdatedQuantities(PurchaseHeader, JobPlanningLine);

        // [WHEN] Post Purchase Order with updated Qty. to Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Quantity on Job Planning Line.
        VerifyQuantityOnJobPlanningLine(JobPlanningLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineOnPurchaseOrderFullQtyToInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // [SCENARIO] Verify Quantity on Job Planning Line when Purchase Order after updating Qty. to Invoice posted with full Quantity.

        // [GIVEN] Create Purchase Order with Job Planning Line No. and update Quantity To Invoice on Purchase Line.
        Initialize();
        Quantity := CreatePurchaseOrderWithUpdatedQuantities(PurchaseHeader, JobPlanningLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // [WHEN] Post Purchase Order with updated Qty. to Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Quantity on Job Planning Line.
        VerifyQuantityOnJobPlanningLine(JobPlanningLine, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobRemainingQtyOnPurchaseLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
        RemainingQty: Decimal;
    begin
        // [SCENARIO] Verify Job Remaining Qty. on Purchase Line when Job Planning Line No. is updated.

        // [GIVEN] Prepare Purchase Order with Job Planning Line No.
        Initialize();
        RemainingQty := LibraryRandom.RandDec(3, 2);
        Quantity := RemainingQty + LibraryRandom.RandDec(7, 2);
        PreparePurchHeaderAndJobPlanningLine(PurchaseHeader, JobPlanningLine, Quantity, Quantity - RemainingQty);
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        CreateJobPlanningLine(JobPlanningLine2, JobTask,
          JobPlanningLine.Type::Item, JobPlanningLine."No.", LibraryRandom.RandDecInRange(11, 20, 2), true);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);

        // [WHEN] Update Job Planning Line No.
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine2."Line No.");
        PurchaseLine.Modify(true);

        // [THEN] Verify Job Remaining Qty. on Purchase Line.
        PurchaseLine.TestField("Job Remaining Qty.", JobPlanningLine2."Remaining Qty." - PurchaseLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobOnPurchaseInvoiceLine()
    var
        OrderPurchaseHeader: Record "Purchase Header";
        InvoicePurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        // [SCENARIO] Test integration of Jobs with Get Receipt Lines. Check that the information related to Job is copied to Purchase Invoice Line
        // [SCENARIO] after creation of Invoice Lines by using the Get Receipt Lines function for a Purchase Order with Job attached to it. Test
        // [SCENARIO] modification of Job related fields is not allowed after receipt.
        // [SCENARIO] Check Job Planning Line, Job Ledger Entry, G/L Entry, Value Entry created after posting of Purchase Invoice.

        // [GIVEN] Create a Purchase Order with Job selected on the Purchase Lines and post it as Receive.
        Initialize();

        CreatePurchaseOrderForJobTask(OrderPurchaseHeader);
        GetPurchaseLines(OrderPurchaseHeader, PurchaseLine);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);
        LibraryPurchase.PostPurchaseDocument(OrderPurchaseHeader, true, false);

        // [THEN] Check that job info for received order cannot be modified.
        VerifyModifyPurchaseDocJobInfo(OrderPurchaseHeader);
        VerifyJobInfoOnPurchRcptLines(TempPurchaseLine);
        VerifyItemLedger(TempPurchaseLine);

        // [WHEN] Create a Purchase Invoice by using the Get Receipt Line function for the Purchase Receipt created earlier.
        CreateInvoiceWithGetReceipt(OrderPurchaseHeader."No.", InvoicePurchaseHeader);

        // Saving the purchase invoice lines
        GetPurchaseLines(InvoicePurchaseHeader, PurchaseLine);
        TempPurchaseLine.DeleteAll();
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);

        // [THEN] Check that the information related to Job is copied to Purchase Invoice Line after creation of Invoice Lines by using
        // [THEN] the Get Receipt Lines function for a Purchase Order with Job attached to it. Check that the modification of job related fields is
        // [THEN] not allowed after receive.
        VerifyJobInfoOnPurchInvoice(OrderPurchaseHeader, InvoicePurchaseHeader);
        VerifyModifyPurchaseDocJobInfo(InvoicePurchaseHeader);

        // [WHEN] Post the Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(InvoicePurchaseHeader, false, true);

        // [THEN] Check the entries created after Posting of Purchase Invoice.
        LibraryJob.VerifyPurchaseDocPostingForJob(TempPurchaseLine);

        VerifyGLEntry(TempPurchaseLine);
        VerifyValueEntries(TempPurchaseLine)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderBlankJobTask()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test that the application generates an error message on posting Purchase Order with Job specified and blank Job Task No.

        // [GIVEN] Create a Purchase Order with Job selected on the Purchase Lines and blank Job Task No.
        Initialize();

        CreatePurchaseOrderForJobTask(PurchaseHeader);
        // remove job task no.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Job Task No.", '');
        PurchaseLine.Modify(true);

        // [WHEN] Post the Purchase Order as Receive.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Check error message on posting Purchase order with Job specified and blank Job Task No.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Job Task No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWithPostedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test Job Planning Line and Job Ledger Entry created after posting of Purchase Order with Job attached on it.

        // [GIVEN] Create a Purchase Order with Job selected on the Purchase Lines. Save Purchase Line in temporary table.
        Initialize();
        CreatePurchaseOrderForJobTask(PurchaseHeader);

        // Save purchase lines.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);

        // [WHEN] Post the Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check the entries created after Posting of Purchase Order.
        LibraryJob.VerifyPurchaseDocPostingForJob(TempPurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobFieldsCopiedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test Job Unit Price and Job Line Discount Amount are automatically filled in.

        // [GIVEN]
        Initialize();

        // [WHEN] Create a Purchase Order with Job selected on the Purchase Lines.
        CreatePurchaseOrderForJobTask(PurchaseHeader);

        // [THEN] Check that the Job Unit Price and Job Line Discount Amount are automatically filled in.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        VerifyJobInfo(PurchaseLine)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DimensionCodeMandatory()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test dimensions on the Purchase Order are transferred correctly to Job Ledger Entry for Code Mandatory.

        DimensionValuePosting(DefaultDimension."Value Posting"::"Code Mandatory");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DimensionSameCode()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test dimensions on the Purchase Order are transferred correctly to Job Ledger Entry for Same Code.

        DimensionValuePosting(DefaultDimension."Value Posting"::"Same Code");
    end;

    local procedure DimensionValuePosting(ValuePosting: Enum "Default Dimension value Posting Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Job: Record Job;
        HeaderDimSetID: Integer;
        DocumentNo: Code[20];
    begin
        // [GIVEN] Create a Purchase Order with Job having dimension with Value Posting selected on the Purchase Lines.
        Initialize();
        CreatePurchaseOrderForJobTask(PurchaseHeader);
        DocumentNo := PurchaseHeader."No.";
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        Job.Get(PurchaseLine."Job No.");
        CreateDefaultDimForJob(Job."No.", ValuePosting);
        HeaderDimSetID := PurchaseHeader."Dimension Set ID";
        repeat
            SetupDocumentDimPurchaseLine(PurchaseLine)
        until PurchaseLine.Next() = 0;

        // [WHEN] Post the Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check that dimensions on the Purchase Order are transferred correctly to Job Ledger Entry.
        VerifyJobLedgerEntryDim(DocumentNo, HeaderDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DimensionCodeMandatoryError()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ExpectedError: Text;
    begin
        // [SCENARIO] The error if dimension value has not been specified on Purchase Line having Job with 'Code Mandatory'.
        // [GIVEN] Create a Purchase Order with Job having dimension with Value Posting 'Code Mandatory' selected on the Purchase Lines.
        PostOrderWithDimValuePostingError(
          DefaultDimension."Value Posting"::"Code Mandatory", PurchaseHeader, PurchaseLine, DefaultDimension);

        // [WHEN] Post the Purchase Order
        Assert.IsFalse(PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post"), 'Posting should fail');

        // [THEN] Check that the application generates an error if dimensions are not selected correctly on Purchase Line.
        ExpectedError :=
          StrSubstNo(
            CodeMandatoryDimensionErr, PurchaseHeader."No.", PurchaseLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"),
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code", PurchaseLine."Job No.");
        VerifyDimensionErrorMessage(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DimensionSameCodeError()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        Job: Record Job;
        ExpectedError: Text;
    begin
        // [SCENARIO] The error if dimension on Purchase Line are different from those on Job for 'Same Code'.
        // [GIVEN] Create a Purchase Order with Job having dimension with Value Posting 'Same Code' selected on the Purchase Lines.
        PostOrderWithDimValuePostingError(
          DefaultDimension."Value Posting"::"Same Code", PurchaseHeader, PurchaseLine, DefaultDimension);

        // [WHEN] Post the Purchase Order
        Assert.IsFalse(PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post"), 'Posting should fail');

        // [THEN] Check that the application generates an error if dimensions are not selected correctly on Purchase Line.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseLine."Dimension Set ID");
        ExpectedError :=
          StrSubstNo(
            SameCodeOrNoCodeDimensionErr, PurchaseHeader."No.", PurchaseLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), DefaultDimension."Dimension Value Code",
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            Job.TableCaption(), PurchaseLine."Job No.",
            DimensionSetEntry."Dimension Value Code");
        VerifyDimensionErrorMessage(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure DimensionNoCodeError()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        Job: Record Job;
        ExpectedError: Text;
    begin
        // [SCENARIO] The error if dimension value has been specified on Purchase Line having Job with 'No Code'.
        // [GIVEN] Create a Purchase Order with Job having dimension with Value Posting 'No Code' selected on the Purchase Lines.
        PostOrderWithDimValuePostingError(
          DefaultDimension."Value Posting"::"No Code", PurchaseHeader, PurchaseLine, DefaultDimension);

        // [WHEN] Post the Purchase Order
        Assert.IsFalse(PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post"), 'Posting should fail');

        // [THEN] Check that the application generates an error if dimensions are not selected correctly on Purchase Line.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PurchaseLine."Dimension Set ID");
        ExpectedError :=
          StrSubstNo(
            SameCodeOrNoCodeDimensionErr, PurchaseHeader."No.", PurchaseLine."Line No.",
            DefaultDimension.FieldCaption("Dimension Value Code"), BlankLbl,
            DefaultDimension.FieldCaption("Dimension Code"), DefaultDimension."Dimension Code",
            Job.TableCaption(), PurchaseLine."Job No.",
            DimensionSetEntry."Dimension Value Code");

        VerifyDimensionErrorMessage(ExpectedError);
    end;

    local procedure PostOrderWithDimValuePostingError(ValuePosting: Enum "Default Dimension value Posting Type"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var DefaultDimension: Record "Default Dimension")
    var
        Job: Record Job;
    begin
        Initialize();
        CreatePurchaseOrderForJobTask(PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        Job.Get(PurchaseLine."Job No.");
        CreateDefaultDimForJob(Job."No.", ValuePosting);

        repeat
            SetupDocumentDimLineError(PurchaseLine, DefaultDimension)
        until PurchaseLine.Next() = 0;
        PurchaseLine.FindFirst();

        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := true;
        PurchaseHeader.Modify();
        Commit();
        LibraryErrorMessage.TrapErrorMessages();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveAndInvoicePurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and then Invoice separately.
        // [SCENARIO] Check G/L Entry, Value Entry, Job Ledger Entry, Job Planning Line created.

        // [GIVEN] Create a Purchase Order with Job selected on the Purchase Lines. Save Purchase Line in temporary table.
        Initialize();
        CreatePurchaseOrderForJobTask(PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);

        // [WHEN] Post the Purchase Order as Receive and then post again as Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Check the entries created after Posting of Purchase Order.
        VerifyGLEntry(TempPurchaseLine);

        VerifyValueEntries(TempPurchaseLine);
        LibraryJob.VerifyPurchaseDocPostingForJob(TempPurchaseLine)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMixedPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchaseLine: Record "Purchase Line";
    begin
        // [GIVEN] Create a Purchase Order with Job selected on the Purchase Lines. Add Purchase Lines without Job.
        Initialize();
        CreatePurchaseOrderForJobTask(PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);

        // [WHEN] Post the Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Check the entries created after Posting of Purchase Order.
        VerifyJobInfoOnPurchRcptLines(TempPurchaseLine);
        VerifyItemLedger(TempPurchaseLine);
        VerifyGLEntry(TempPurchaseLine);

        VerifyValueEntries(TempPurchaseLine);
        LibraryJob.VerifyPurchaseDocPostingForJob(TempPurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseOrderForLCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with local currency on both Purchase Order and
        // [SCENARIO] Job. Check Receipt Lines, Item Ledger Entry, Value Entry, Job Ledger Entry, Job Planning Line created.

        PostJobPurchaseOrder('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseOrderForLCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with foreign currency on Purchase Order.
        // [SCENARIO] Check Receipt Lines, Item Ledger Entry, G/L Entry, Value Entry, Job Ledger Entry, Job Planning Line created.

        PostJobPurchaseOrder('', FindFCY());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseOrderForFCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with foreign currency on Job.
        // [SCENARIO] Check Receipt Lines, Item Ledger Entry, Value Entry, Job Ledger Entry, Job Planning Line created.

        PostJobPurchaseOrder(FindFCY(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseOrderForFCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with foreign currency on both Purchase Order and
        // [SCENARIO] Job. Check Receipt Lines, Item Ledger Entry, Value Entry, Job Ledger Entry, Job Planning Line created.

        PostJobPurchaseOrder(FindFCY(), FindFCY());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseOrderWithLCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with local currency on Purchase Order
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeGLAccount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseOrderWithLCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with foreign currency on Purchase Order.
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeGLAccount('', FindFCY());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseOrderWithrFCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with foreign currency on Job.
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeGLAccount(FindFCY(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseOrderWithFCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Order as Receive and Invoice with foreign currency on Purchase Order and
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeGLAccount(FindFCY(), FindFCY());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYItemPurchaseOrderWithLCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Item Purchase Order as Receive and Invoice with local currency on Purchase Order
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeItem('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYItemPurchaseOrderWithLCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Item Purchase Order as Receive and Invoice with foreign currency on Purchase Order.
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeItem('', FindFCY());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYItemPurchaseOrderWithrFCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Item Purchase Order as Receive and Invoice with foreign currency on Job.
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeItem(FindFCY(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYItemPurchaseOrderWithFCYJob()
    begin
        // [SCENARIO] Test integration of Jobs with posting of Item Purchase Order as Receive and Invoice with foreign currency on Purchase Order and
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values
        PostJobPurchaseOrderWithTypeItem(FindFCY(), FindFCY());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure LCYJobLedgerEntryPopulatesTotalCostFromDirectUnitCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Job Ledger Entry] [Item Tracking]
        // [SCENARIO 363373] Posting LCY Job Purchase Order with Serial Tracking populates Total Cost on Job Ledger Entry equal to Direct Unit Cost of appropriate Purchase Line
        Initialize();

        // [GIVEN] Item with Serial Tracking Code
        CreateSerialTrackedItem(Item);

        // [GIVEN] Job Purchase Order with Unit Cost (LCY) = "X"
        CreateJobPurchaseOrderWithTracking(PurchaseHeader, PurchaseLine, Item."No.", '');

        // [WHEN] Post Purchase Order as Receive and Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Job Ledger Entries were created, each with Total Cost = Total Cost (LCY) = "X"
        VerifyTotalCostAndPriceOnJobLedgerEntry(Item."No.", PurchaseLine."Unit Cost", PurchaseLine."Unit Cost (LCY)", PurchaseLine."Unit Price (LCY)", PurchaseLine."Unit Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure FCYJobLedgerEntryPopulatesTotalCostFromDirectUnitCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Job Ledger Entry] [Item Tracking] [FCY]
        // [SCENARIO 363373] Posting FCY Job Purchase Order with Serial Tracking populates Total Cost on Job Ledger Entry equal to Direct Unit Cost of appropriate Purchase Line
        Initialize();

        // [GIVEN] Item with Serial Tracking Code
        CreateSerialTrackedItem(Item);

        // [GIVEN] Job Purchase Order with Unit Cost = "X"
        CreateJobPurchaseOrderWithTracking(PurchaseHeader, PurchaseLine, Item."No.", FindFCY());

        // [WHEN] Post Purchase Order as Receive and Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Job Ledger Entries were created, each with Total Cost = "X"
        VerifyTotalCostAndPriceOnJobLedgerEntry(Item."No.", PurchaseLine."Unit Cost", PurchaseLine."Unit Cost (LCY)", PurchaseLine."Job Unit Price", PurchaseLine."Job Unit Price (LCY)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithItemReserveAsAlways()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        InventorySetup: Record "Inventory Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify GL Entry after posting a Purchase Order with Job.

        Initialize();
        // [GIVEN] Inventory Setup, where "Automatic Cost Adjustment" is 'Always'
        InventorySetup.Get();
        UpdateAutomaticCostPosting(true, InventorySetup."Automatic Cost Adjustment"::Always);
        CreatePurchaseDocument(PurchaseHeader, CreateVendorWithSetup(VATPostingSetup));
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [WHEN] Post Purchase Order as Receive and Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify GL Entry.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        GLEntry.SetFilter(Amount, '>0');
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Purchase);
        VerifyGLEntryAmountInclVAT(GLEntry, PurchInvHeader."Amount Including VAT");
        VerifyJobOnGLEntry(PurchaseLine."Job No.", DocumentNo, GLEntry."Document Type"::Invoice);

        // Tear Down.
        UpdateAdjustmentAccounts(
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithItemReserveAsAlways()
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        InventorySetup: Record "Inventory Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify GL Entry after posting a Purchase Credit Memo using function Return Shimpment on Credit Memo.

        // Setup.
        Initialize();
        InventorySetup.Get();
        PurchasesPayablesSetup.Get();
        UpdateAutomaticCostPosting(true, InventorySetup."Automatic Cost Adjustment"::Always);
        UpdateReturnShipmentOnCreditMemo(false);
        CreatePurchaseDocument(PurchaseHeader, CreateVendorWithSetup(VATPostingSetup));
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader);
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [WHEN] Post Purchase Credit Memo.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify GL Entry.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT");
        GLEntry.SetFilter(Amount, '>0');
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Document Type"::"Credit Memo");
        VerifyGLEntryAmountInclVAT(GLEntry, PurchCrMemoHdr."Amount Including VAT");
        VerifyJobOnGLEntry(PurchaseLine."Job No.", DocumentNo, GLEntry."Document Type"::"Credit Memo");

        // Tear Down.
        UpdateAdjustmentAccounts(
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceUsingGetReceiptLine()
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify GL Entry after posting a Purchase Invoice create through Get Receipt Line function.

        // [GIVEN]
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, CreateVendorWithSetup(VATPostingSetup));
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        GetReceiptLineOnPurchaseInvoice(PurchaseHeader, PurchaseHeader."No.");

        // [WHEN] Post Purchase Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify GL Entry.
        // [THEN] Verification of Item Charge Assignment Purchase has done in ItemChargeAssignmentHandler.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        GLEntry.SetFilter(Amount, '>0');
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Purchase);
        VerifyGLEntryAmountInclVAT(GLEntry, PurchInvHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobOrderReservationWithResourceShouldFail()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify the error message while reserving the Item from Job Order to Purchase Order when Type is Resource on Job Planning Line.

        // [GIVEN] Create Purchase Order and Job Plan. Update Job Planning Line with Type Resource.
        Initialize();
        CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.Modify(true);

        // [WHEN] Reserve Item from Job Planning Line.
        asserterror OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify error message.
        Assert.ExpectedTestFieldError(JobPlanningLine.FieldCaption(Type), Format(JobPlanningLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobOrderReservationWithoutPlanningDate()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify the error message while reserving the Item from Job Order to Purchase Order when Planning Date is blank on Job Planning Line.

        // [GIVEN] Create Purchase Order and Job Plan. Update Job Planning Line with blank Planning Date.
        Initialize();
        CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        UpdatePlanningDateOnJobPlanninglLine(JobPlanningLine, 0D);

        // [WHEN] Reserve Item from Job Planning Line.
        asserterror OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify error message.
        Assert.ExpectedTestFieldError(JobPlanningLine.FieldCaption("Planning Date"), '');
    end;

    [Test]
    [HandlerFunctions('NoQuantityOnReservePageHandler')]
    [Scope('OnPrem')]
    procedure JobOrderReservationWithEarlierPlanningDate()
    begin
        // [SCENARIO] Verify reservation lines when Planning Date is earlier than Expected Receipt Date on Job Planning Line.
        Initialize();
        JobOrderReservationWithPlanningDate(CreateItem(), LibraryRandom.RandDec(10, 2), -1);  // Use Random for Quantity and take -1 as SignFactor.

        // [THEN] Verify Reservation Line. Verification done in 'NoQuantityOnReservePageHandler'.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure JobOrderReservationWithLaterPlanningDate()
    var
        ItemNumber: Code[20];
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        // [SCENARIO] Verify reservation lines when Planning Date is later than Expected Receipt Date on Job Planning Line.
        Initialize();
        ItemNumber := CreateItem();  // Assign Item No. in global variable.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.
        QuantityOnJobPlanningLine := OriginalQuantity;  // Assign in global variable.
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        JobOrderReservationWithPlanningDate(ItemNumber, OriginalQuantity, 1);  // Take 1 as SignFactor.

        // [THEN] Verify Reservation Line. Verification done in 'ReservationPageHandler'.
    end;

    local procedure JobOrderReservationWithPlanningDate(ItemNo: Code[20]; Quantity: Decimal; SignFactor: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        ExpectedReceiptDate: Date;
    begin
        // [GIVEN] Create Purchase Order and Job Plan. Update Job Planning Line with Planning Date.
        ExpectedReceiptDate := CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, ItemNo, Quantity);
        UpdatePlanningDateOnJobPlanninglLine(
          JobPlanningLine, CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(5)) + 'D>', ExpectedReceiptDate));  // Use Random to calculate Planning Date earlier than Expected Receipt Date.

        // [WHEN] Reserve Item from Job Planning Line.
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
    end;

    [Test]
    [HandlerFunctions('NoQuantityOnReservePageHandler')]
    [Scope('OnPrem')]
    procedure JobOrderReservationWithNegativeQuantity()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify reservation lines when Quantity is negative on Job Planning Line.

        // [GIVEN] Create Purchase Order and Job Plan. Update Job Planning Line with Random negative Quantity.
        Initialize();
        CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        UpdateJobPlanningLineQuantity(JobPlanningLine, -LibraryRandom.RandInt(10));

        // [WHEN] Reserve Item from Job Planning Line.
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify Reservation Line. Verification done in 'NoQuantityOnReservePageHandler'.
    end;

    [Test]
    [HandlerFunctions('NoQuantityOnReservePageHandler')]
    [Scope('OnPrem')]
    procedure JobOrderReservationWithWrongLocation()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify reservation lines when Location is different on Job Planning Line from Purchase Order.

        // [GIVEN] Create Purchase Order and Job Plan. Update Job Planning Line with new Location.
        Initialize();
        CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        JobPlanningLine.Validate("Location Code", FindLocation());
        JobPlanningLine.Modify(true);

        // [WHEN] Reserve Item from Job Planning Line.
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify Reservation Line. Verification done in 'NoQuantityOnReservePageHandler'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseInvoiceWithLCYJob()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        GLEntry: Record "G/L Entry";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PurchaseOrderCurrency: Code[10];
    begin
        // [SCENARIO] Test integration of Jobs with posting of Purchase Invoice with foreign currency on Purchase Order.
        // [SCENARIO] Verifying "G/L Entry","Job Ledger Entry" values and compare then
        Initialize();
        // [GIVEN] created Job with local currency
        PurchaseOrderCurrency := FindFCY();
        CreateJobWithCurrecy(JobTask, '');
        // [GIVEN] created Purchase Invoice with foreign currency
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice, Vendor."No.", PurchaseHeader);
        PurchaseHeader.Validate("Currency Code", PurchaseOrderCurrency);
        PurchaseHeader.Modify(true);
        // [GIVEN] created Purchase Invoice with GL Account
        CreateGLPurchaseLine(PurchaseHeader);
        // [GIVEN] update Purchase Invoice Lines with Job info
        AttachJobTaskToPurchaseDoc(JobTask, PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Verify Job Ledger Entry Amount and G/L Entry Amount should be the same
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobTask."Job No.");
        GLEntry.SetRange("G/L Account No.", PurchaseLine."No.");
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        Assert.AreEqual(JobLedgerEntry."Total Cost (LCY)", GLEntry.Amount, 'Job Ledger Entry Total Cost and G/L Entry Amount should be equal');
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReserveItemFromJobOrderToPurchaseOrder()
    var
        JobPlanningLine: Record "Job Planning Line";
        ItemNumber: Code[20];
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        // [SCENARIO] Verify Reserved Quantity on Reservation window when reserve Item from Purchase Order to Job Order.

        // [GIVEN] Create Purchase Order and Job Plan.
        Initialize();
        ItemNumber := CreateItem();  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.
        CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, ItemNumber, OriginalQuantity);
        QuantityOnJobPlanningLine := OriginalQuantity;  // Assign in global variable.
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);

        // [WHEN] Reserve Item from Job Planning Line.
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify Reservation Line. Verification done in 'ReserveFromCurrentLineHandler'.
    end;

    local procedure CreatePurchaseOrderAndJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; Quantity: Decimal) ExpectedReceiptDate: Date
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader, ItemNo, Quantity);
        ExpectedReceiptDate := PurchaseHeader."Expected Receipt Date";
        CreateJobAndJobPlanningLine(JobPlanningLine, ItemNo, Quantity);
    end;

    local procedure CreatePurchaseOrderWithExpectedReceiptDate(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseHeader.Validate("Expected Receipt Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Update Receipt Date earlier than WORKDATE. Use Random to calculate Date.
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithUpdatedQuantities(var PurchaseHeader: Record "Purchase Header"; var JobPlanningLine: Record "Job Planning Line") Quantity: Decimal
    var
        QtyToReceive: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        QtyToReceive := Quantity / LibraryRandom.RandIntInRange(4, 6);
        UpdatePurchLineWithQtyToReceiveAndInvoice(
          JobPlanningLine, PurchaseHeader, Quantity, QtyToReceive, QtyToReceive / LibraryRandom.RandIntInRange(2, 4));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithJob()
    var
        GLAccount: Record "G/L Account";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify Job Ledger Entry after posting a Purchase Credit Memo with Job.

        // [GIVEN]
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::"G/L Account", GLAccount."No.");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);

        // [WHEN] Post Purchase Credit Memo as Receive and Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN]
        VerifyJobLedgerEntry(PurchaseLine, DocumentNo, -PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialPurchaseReturnOrderWithCopyDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify Job Ledger Entry after posting the partial Purchase Return Order when Lines are created from the Copy Document function.

        // [GIVEN] Create and post Purchase Order, Create Purchase Return Order from Copy Document and post it partially.
        Initialize();
        PurchaseOrderWithJobTask(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader);
        InvokeCopyPurchaseDocument(PurchaseHeader, DocumentNo);
        GetAndUpdatePurchaseLines(PurchaseHeader, PurchaseLine);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Post Purchase Return Order for remaining Quantity.
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."Vendor Cr. Memo No." + '_2';
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN]
        VerifyJobLedgerEntry(PurchaseLine, DocumentNo, -PurchaseLine."Return Qty. to Ship");
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,DemandOverviewPageHandler')]
    [Scope('OnPrem')]
    procedure DemandOverviewForJobPlanningLines()
    var
        JobPlanningLine: Record "Job Planning Line";
        ItemNumber: Code[20];
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        // [SCENARIO] Verify the Demand Overview Page for Reserved Quantity for Job Planning Lines.

        // [GIVEN] Create Purchase Order and Job Plan. Open Reservation page and Reserve Item from Job Planning Line in handler 'ReserveFromCurrentLineHandler'.
        Initialize();
        ItemNumber := CreateItem();  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.
        CreatePurchaseOrderAndJobPlanningLine(JobPlanningLine, ItemNumber, OriginalQuantity);
        QuantityOnJobPlanningLine := OriginalQuantity;  // Assign in global variable.
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        LibraryVariableStorage.Enqueue(ItemNumber);

        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [WHEN] Open Demand Overview page from Job Planning Line.
        OpenDemandOverviewPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify Reserved Quantity for Supply and Demand on the Demand Overview page. Verification done in 'DemandOverviewPageHandler'.
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReservationBetweenJobAndProductionOrder()
    var
        JobPlanningLine: Record "Job Planning Line";
        ProductionOrder: Record "Production Order";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        ItemNumber: Code[20];
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        // [SCENARIO] Verify Reserved Quantity for an existing reservation between Jobs and Production Order can be modified and be reserved again.

        // [GIVEN] Create Production Order and Job Plan. Open Reservation page and Reserve Item from Job Planning Line in handler 'ReserveFromCurrentLineHandler'.
        Initialize();
        ItemNumber := CreateItem();  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandDec(100, 2);  // Assign Random Quantity in global variable.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNumber, OriginalQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        CreateJobAndJobPlanningLine(JobPlanningLine, ItemNumber, OriginalQuantity);
        UpdateJobPlanningLineQuantity(JobPlanningLine, JobPlanningLine.Quantity / 2);  // Reduce Quantity by half.
        QuantityOnJobPlanningLine := JobPlanningLine.Quantity;  // Assign in global variable.
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");

        // [WHEN] Update Quantity on Job Planning Line with Random value and again reserve it.
        UpdateJobPlanningLineQuantity(JobPlanningLine, JobPlanningLine.Quantity + JobPlanningLine.Quantity);
        QuantityOnJobPlanningLine := JobPlanningLine.Quantity;  // Assign in global variable.
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [THEN] Verify Reservation Line for updated Reserved Quantity. Verification done in 'ReserveFromCurrentLineHandler'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenReservationWindowWithUsageLinkDisabledShouldFail()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify that it is not possible to open Reservation window if Usage Link is not enabled in the Job Planning Line.

        // [GIVEN] Create Job and Job Planning Line. By default Usage Link is False on Job Planning Line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);

        // [WHEN] Modify the Reserve option on line to open the reservation window.
        asserterror JobPlanningLine.Validate(Reserve, JobPlanningLine.Reserve::Optional);

        // [THEN] Verify error message.
        Assert.ExpectedTestFieldError(JobPlanningLine.FieldCaption("Usage Link"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveFieldOnJobPlanningLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify the value of Reserve field on the Job Planning Line.

        // [GIVEN]
        Initialize();

        // [WHEN] Create Job Planning Line.
        CreateJobAndJobPlanningLine(JobPlanningLine, CreateItemWithReserveOption(Item.Reserve::Optional), LibraryRandom.RandDec(100, 2));  // Use Random for Quantity.

        // [THEN] Verify Reserve field on Job Planning line.
        JobPlanningLine.TestField(Reserve, Item.Reserve);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ReservationFromPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ItemNumber: Code[20];
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        // [SCENARIO] Verify Reservation Line and Purchase line after Reservation with Purchase Order as supply and Job Planning Line as demand.

        // [GIVEN] Create Purchase Order and Job Plan. Modify Quantity on Job planning Line.Initialize();
        Initialize();
        ItemNumber := CreateItemWithReserveOption(Item.Reserve::Optional);  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.
        CreatePurchaseSupplyAndJobDemandWithUpdatedQuantity(PurchaseHeader, ItemNumber, OriginalQuantity);
        QuantityOnJobPlanningLine := OriginalQuantity / 2;  // Assign in global variable.
        LibraryVariableStorage.Enqueue(false);
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        // Reserve Item from Purchase Order.
        OpenReservationPageFromPurchaseOrder(PurchaseHeader."No.");

        // [THEN] Verify Reservation Line. Verification done in 'PurchaseOrderReserveFromCurrentLineHandler' and Verify Purchase Line for Reserved Quantity.
        VerifyPurchaseLine(PurchaseHeader, QuantityOnJobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderReserveFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNumber: Code[20];
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        // [SCENARIO] Verify Reservation Line and Purchase line after cancelled the Reservation when Purchase Order as supply and Job Planning Line as demand.

        // [GIVEN] Create Purchase Order and Job Plan. Modify Quantity on Job planning Line. Reserve Item from Purchase Order.
        Initialize();
        ItemNumber := CreateItemWithReserveOption(Item.Reserve::Optional);  // Assign in global variable.
        OriginalQuantity := LibraryRandom.RandDec(10, 2);  // Assign Random Quantity in global variable.

        CreatePurchaseSupplyAndJobDemandWithUpdatedQuantity(PurchaseHeader, ItemNumber, OriginalQuantity);
        QuantityOnJobPlanningLine := OriginalQuantity / 2;  // Assign in global variable.
        LibraryVariableStorage.Enqueue(false);
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        OpenReservationPageFromPurchaseOrder(PurchaseHeader."No.");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryVariableStorage.Enqueue(true);
        EnqueueVariables(ItemNumber, QuantityOnJobPlanningLine, OriginalQuantity);
        // [WHEN] Cancel Reservation from Purchase Order.
        OpenReservationPageFromPurchaseOrder(PurchaseHeader."No.");

        // [THEN] Verify Reservation Line. Verification done in 'PurchaseOrderReserveFromCurrentLineHandler'.
        VerifyPurchaseLine(PurchaseHeader, 0);  // After cancel the Reservation, Reserved Quantity must be zero.
    end;

    local procedure CreatePurchaseSupplyAndJobDemandWithUpdatedQuantity(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader, ItemNo, Quantity);
        CreateJobAndJobPlanningLine(JobPlanningLine, ItemNo, Quantity);
        UpdateJobPlanningLineQuantity(JobPlanningLine, Quantity / 2);  // Reduce Quantity by half.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RelationBetweenUsageLinkAndReserveOnJob()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify relationship between usage Link and Reserve.

        // [GIVEN] Create and modify Item for Reserve field. Create Job Planning Line.
        Initialize();
        CreateJobAndJobPlanningLine(JobPlanningLine, CreateItemWithReserveOption(Item.Reserve::Optional), LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.

        // [WHEN] Modify Usage Link on Job Planning line.
        JobPlanningLine.Validate("Usage Link", false);
        JobPlanningLine.Modify(true);

        // [THEN] Verify Reserve field on Job Planning line is changed to Never.
        JobPlanningLine.TestField(Reserve, Item.Reserve::Never);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UsageLinkErrorWhileChangeReserveField()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Verify error message when change the value of Reserve field on Job Planning Line while Usage Link is unchecked.

        // [GIVEN] Create and modify Item for Reserve field. Create and modify Job Planning Line.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Item, CreateItemWithReserveOption(Item.Reserve::Optional),
          LibraryRandom.RandDec(10, 2), false);  // Use Random for Quantity.

        // [WHEN] Modify Reserve field on Job Planning line.
        asserterror JobPlanningLine.Validate(Reserve, JobPlanningLine.Reserve::Optional);

        // [THEN] Verify error message.
        Assert.ExpectedTestFieldError(JobPlanningLine.FieldCaption("Usage Link"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderAsShip()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Check Item Ledger Entries and Value Entries generated against Item Ledger Entry after posting Purchase Return order As Ship with Job No.

        // [GIVEN] Create and post Purchase Order, Create Purchase Return Order from Copy Document.
        Initialize();
        PurchaseOrderWithJobTask(PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader);
        InvokeCopyPurchaseDocument(PurchaseHeader, DocumentNo);

        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);

        // [WHEN] Post Purchase Return Order with Ship Option.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Item Ledger Entries and corresponding Value Entries.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", DocumentNo,
          PurchaseLine."Job No.", PurchaseLine.Quantity, 0, 0, PurchaseLine."Line Amount");
        VerifyValueEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", ItemLedgerEntry."Document Type"::"Purchase Return Shipment",
          PurchaseLine."No.", DocumentNo, PurchaseLine."Job No.", PurchaseLine.Amount, 0);

        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", DocumentNo,
          PurchaseLine."Job No.", -PurchaseLine.Quantity, 0, 0, -PurchaseLine."Line Amount");
        VerifyValueEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", PurchaseLine."No.",
          DocumentNo, PurchaseLine."Job No.", -PurchaseLine.Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseReturnOrderAsShipAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ShipmentNo: Code[20];
        CreditMemoNo: Code[20];
    begin
        // [SCENARIO] Check Item Ledger Entries and Value Entries generated against Item Ledger Entry after posting Purchase Return order As Ship and then as Invoice with Job No.

        // [GIVEN] Create and post Purchase Order, Create Purchase Return Order from Copy Document and post it as Shipped.
        Initialize();
        PurchaseOrderWithJobTask(PurchaseHeader);
        ShipmentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader);
        InvokeCopyPurchaseDocument(PurchaseHeader, ShipmentNo);

        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        ShipmentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Purchase Return Order with Ship Option.

        // [WHEN] Again Post Purchase Return Order with Invoice Option.
        CreditMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify Item Ledger Entries and corresponding Value Entries.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ShipmentNo, PurchaseLine."Job No.",
          PurchaseLine.Quantity, PurchaseLine.Quantity, PurchaseLine.Amount, 0);
        VerifyValueEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", ItemLedgerEntry."Document Type"::"Purchase Return Shipment",
          PurchaseLine."No.", ShipmentNo, PurchaseLine."Job No.", PurchaseLine.Amount, 0);
        VerifyValueEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", ItemLedgerEntry."Document Type"::"Purchase Credit Memo", PurchaseLine."No.",
          CreditMemoNo, PurchaseLine."Job No.", -PurchaseLine.Amount, PurchaseLine.Amount);

        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ShipmentNo,
          PurchaseLine."Job No.", -PurchaseLine.Quantity, -PurchaseLine.Quantity, -PurchaseLine.Amount, 0);
        VerifyValueEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Return Shipment", PurchaseLine."No.",
          ShipmentNo, PurchaseLine."Job No.", -PurchaseLine.Amount, 0);
        VerifyValueEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Credit Memo", PurchaseLine."No.",
          CreditMemoNo, PurchaseLine."Job No.", PurchaseLine.Amount, -PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentPurchaseOrderWithJob()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] Job No. in GL Entry after Posting Prepayment Invoice for Purchase Order.

        // [GIVEN] Create Job and Job Task, Create Purchase Order, update Prepayment Account in General Posting Setup.
        Initialize();
        CreatePurchaseOrderWithPrepaymentAndJob(PurchaseHeader, PurchaseLine, GeneralPostingSetup, JobTask, GLAccountNo);
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Prepayment No. Series");  // Store Prepayment Invoice No.

        // [WHEN] Post Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify Job No. in GL Entry after posting Prepayment Invoice.
        VerifyJobNoInGLEntry(DocumentNo, PurchaseHeader."Document Type"::Invoice, GLAccountNo, JobTask."Job No.");

        // Tear Down: Roll back updated Prepayment Account.
        UpdatePurchasePrepaymentAccount(PurchaseLine, GeneralPostingSetup."Purch. Prepayments Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithPrepaymentAndJob()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO] Job No. in GL Entries after Posting Prepayment Invoice and then Posting Purchase Order.

        // [GIVEN] Create Job and Job Task, Create Purchase Order, update Prepayment Account in General Posting Setup and Post Prepayment Invoice.
        Initialize();
        CreatePurchaseOrderWithPrepaymentAndJob(PurchaseHeader, PurchaseLine, GeneralPostingSetup, JobTask, GLAccountNo);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);

        // [WHEN]
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Job No. in GL Entries after posting Purchase Order.
        VerifyJobNoInGLEntry(DocumentNo, PurchaseHeader."Document Type"::Invoice, GeneralPostingSetup."Purch. Account", JobTask."Job No.");
        VerifyJobNoInGLEntry(DocumentNo, PurchaseHeader."Document Type"::Invoice, GLAccountNo, JobTask."Job No.");

        // Tear Down: Roll back updated Prepayment Account.
        UpdatePurchasePrepaymentAccount(PurchaseLine, GeneralPostingSetup."Purch. Prepayments Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostedPurchaseOrderWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
        ExpectedQuantity: Decimal;
        ActualQuantity: Decimal;
    begin
        // [SCENARIO] Partial Posting of Purchase Order with Job carries correct Quantities in Job Ledger Entries.

        // [GIVEN] Create Purchase Order and update Quantity to Receive and Quantity to Invoice on all Purchase Lines.
        Initialize();
        CreatePurchaseOrderForJobTask(PurchaseHeader);
        UpdatePurchaseLineQuantities(PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);
        ExpectedQuantity := CalculatePurchaseLineQuantityToInvoice(TempPurchaseLine);

        // [WHEN] Post Purchase Order with Partial Quantities.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify that Correct Quantities present in Job Ledger Entries.
        ActualQuantity := CalculateJobLedgerEntryQuantity(DocumentNo, PurchaseLine."Job No.");
        Assert.AreEqual(
          ExpectedQuantity, ActualQuantity,
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption(Quantity), ExpectedQuantity, JobLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceivePurchaseOrderTwiceWithJob()
    var
        GLAccount: Record "G/L Account";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
        ExpectedQuantity: Decimal;
        ActualQuantity: Decimal;
    begin
        // [SCENARIO] Multiple partial postings of Purchase Order with Job carries correct Quantity in Job Ledger Entries.

        // [GIVEN] Create Purchase Order, update Quantity to Invoice and Post Purchase Order as Receive, again update Quantity to Invoice and Post Purchase Order as Receive.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::"G/L Account", GLAccount."No.");
        PostPartialPurchaseOrder(PurchaseLine, PurchaseHeader);
        ExpectedQuantity := PurchaseLine."Qty. to Receive";

        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostPartialPurchaseOrder(PurchaseLine, PurchaseHeader);
        ExpectedQuantity := ExpectedQuantity + PurchaseLine."Qty. to Receive";

        // [WHEN] Post Purchase Order as Invoice.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify that Correct Quantity updated in Job Ledger Entries after multiple postings.
        ActualQuantity := CalculateJobLedgerEntryQuantity(DocumentNo, PurchaseLine."Job No.");
        Assert.AreEqual(
          ExpectedQuantity, ActualQuantity,
          StrSubstNo(FieldErr, PurchaseLine.FieldCaption(Quantity), ExpectedQuantity, JobLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJobPurchaseOrderAsReceiveAndUpdateItemUOM()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyPerUnitOfMeasure: Decimal;
    begin
        // [SCENARIO] "Qty. Per Unit of Measure" on Purchase Line does not get updated after updation of "Qty. per Unit of Measure" in Item Unit of Measure after Receiving the Job Purchase Order.

        // [GIVEN] Create Job Purchase Order with Different Unit of Measure than Base Unit of Measure and Post as Receive.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, CreateItemWithMultipleUOM());
        UpdatePurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        QtyPerUnitOfMeasure := 1 + LibraryRandom.RandInt(3);  // Using Random for Qty Per Unit Of Measure more than one.

        // [WHEN] Update Quantity Per Unit Of Measure in Item Unit of Measure and check Quantity Per Unit of Measure does not get updated on Purchase Line.
        UpdateItemUnitOfMeasure(PurchaseLine, QtyPerUnitOfMeasure);
        asserterror PurchaseLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);

        // [THEN] Verify error raised on testfield of Quantity Per Unit of Measure.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Qty. per Unit of Measure"), Format(QtyPerUnitOfMeasure));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJobPurchaseOrderAsInvoiceAfterUpdateItemUOM()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Invoicing the Purchase Order with Job carries correct Quantity and Unit Cost in Job Ledger Entry where "Qty. per Unit of Measure" is different on Item Unit of Measure.

        // [GIVEN] Create Job Purchase Order with Different Unit of Measure than Base Unit of Measure and Post as Receive. Update Quantity Per Unit Of Measure in Item Unit of Measure.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, CreateItemWithMultipleUOM());
        UpdatePurchaseLine(PurchaseLine, PurchaseHeader);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        UpdateItemUnitOfMeasure(PurchaseLine, 1 + LibraryRandom.RandInt(3));  // Using Random for Qty Per Unit Of Measure more than one.

        // [WHEN] Invoice the Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify Job Ledger Entry and GL Entry.
        PurchaseLine."Unit of Measure Code" := GetBaseUnitOfMeasureCode(PurchaseLine."No.");
        VerifyJobLedgerEntry(PurchaseLine, DocumentNo, PurchaseLine.Quantity);
        VerifyGLEntry(TempPurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveOnJobPlanningLineWithUsageLinkChecked()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO] Reserve field on Job Planning Line is updated from Job when Usage Link is checked and Item has Reserve as Optional and Job has Always.

        // [GIVEN] Create Job with Reserve as Always.
        Initialize();
        CreateJobWithReserveOption(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Create Job Planning Line with Item which has Reserve as Optional and Usage Link.
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2), true);  // Use Random for Quantity.

        // [THEN] Verify Reserve field on Job Planning line.
        JobPlanningLine.TestField(Reserve, Job.Reserve);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithJob()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Ledger Entry Type and Ledger Entry No. after posting a Purchase Order with Job.

        // [GIVEN] Create Purcahse Order for a GL Account with Job.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::"G/L Account", GLAccount."No.");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);

        // [WHEN]
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Ledger Entry Type and Ledger Entry No. in Job Ledger Entry after Posting Purchase Order with Job.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        FindGLEntry(GLEntry, DocumentNo, PurchaseLine."Document Type"::Invoice);
        JobLedgerEntry.TestField("Ledger Entry Type", JobLedgerEntry."Ledger Entry Type"::"G/L Account");
        JobLedgerEntry.TestField("Ledger Entry No.", GLEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPurchaseOrderErrorWhenJobStatusPlanning()
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Error Message while posting Purchase Order with Job when Job has Status Planning.

        // [GIVEN] Create Purchase Order with Job, Update Status as Planning on Job.
        Initialize();
        LibraryERM.FindGLAccount(GLAccount);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::"G/L Account", GLAccount."No.");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        UpdateJobStatus(Job, PurchaseLine."Job No.");

        // [WHEN] Post Purchase Order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify Error Message while posting Purchase Order.
        Assert.ExpectedTestFieldError(Job.FieldCaption(Status), Format(Job.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCurrencyOnPurchaseOrderLine()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO] correct Job Currency Code and Job Currency Factor populated on Purchase Line created with Job having Currency code.

        // [GIVEN] Find a Currency and update it on Job Card.
        Initialize();
        CurrencyCode := FindFCY();
        CreateJobWithJobTask(JobTask);
        UpdateCurrencyOnJob(JobTask."Job No.", CurrencyCode);

        // [WHEN] Create Purchase Order with Job.
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, CreateItem());

        // [THEN] Verify that Job Currency Code and Job Currency Factor updated correctly on Purchase Line.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.TestField("Job Currency Code", CurrencyCode);
        PurchaseLine.TestField("Job Currency Factor", CalculateCurrencyFactor(CurrencyCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateJobCurrencyAfterReceivingPurchaseOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        TotalCost: Decimal;
    begin
        // [SCENARIO] Total Cost and Total Cost LCY after Receiving Purchase Order with Job having currency attached and Invoice it after removing Currency Code from Job.
        // [545709] Purchase Order neeeds to be open to validate "Job Task No." in line when changing the currency code on the job.

        // [GIVEN] Attach Currency on Job, Create Purchase Order with Job, Update General Posting Setup, Post Purchase Order as Receive and Remove Currency from Job.
        Initialize();
        CurrencyCode := FindFCY();
        CreateJobWithJobTask(JobTask);
        UpdateCurrencyOnJob(JobTask."Job No.", CurrencyCode);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, CreateItem());
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        TotalCost := Round(PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateAdjustmentAccounts(
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", LibraryERM.CreateGLAccountNo());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Purchase Order as Receive.
        Commit();

        // [WHEN] Update the Currency Code as Blank on Job.
        asserterror UpdateCurrencyOnJob(JobTask."Job No.", '');

        // [THEN] Verify error message: "Status must be equal to Open...".
        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption(Status), Format(PurchaseHeader.Status::Open));

        // [GIVEN] Reopen Purchase Order.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [GIVEN] Update the Currency Code as Blank on Job.
        UpdateCurrencyOnJob(JobTask."Job No.", '');

        // [WHEN] Post the Purchase Order as Invoice now.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Verify Amount in Job Ledger Entries.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobTask."Job No.");
        JobLedgerEntry.TestField("Total Cost (LCY)", TotalCost);
        JobLedgerEntry.TestField("Total Cost", TotalCost);

        // 4. Tear Down:
        UpdateAdjustmentAccounts(
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", GeneralPostingSetup."Inventory Adjmt. Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoWithNegativeQuantities()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderCreditMemo: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 378571] Job Ledger Entry with negative quantity in credit memo lines should be created after posting credit memo.
        Initialize();

        // [GIVEN] Create purchase order and purchase line with filled "Job No." and "Job Task No." fields.
        PurchaseOrderWithJobTask(PurchaseHeader);

        // [GIVEN] Post purchase order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Purchase Header for purchase credit memo.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderCreditMemo, PurchaseHeaderCreditMemo."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeaderCreditMemo.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeaderCreditMemo.Modify(true);

        // [GIVEN] Copy Purchase Lines in purchase credit memo from posted invoice.
        InvokeCopyPurchaseDocument(PurchaseHeaderCreditMemo, DocumentNo);

        // [GIVEN] Add Purchase Line in credit memo with negative quantity.
        AddPurchaseLineWithNegativeQuantity(PurchaseLine, PurchaseHeaderCreditMemo);

        // [WHEN] Post credit memo.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCreditMemo, true, true);

        // [THEN] Job Ledger Entry Lines with negative quantity should be created.
        VerifyLastJobLedgerEntryLine(PurchaseLine, DocumentNo, -PurchaseLine."Return Qty. to Ship (Base)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderItemCostChange()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PlanningLineDirectUnitCostBeforeJobs: Decimal;
        PlanningLineDirectUnitCostAfterJobs: Decimal;
    begin
        // [FEATURE] [Update Job Item Cost]
        // [SCENARIO] Update Job Item Cost job updates Planning Line "Posted Total Cost" after setting a different Item Cost in Purchase Order

        // [GIVEN] Create an Item, a Job, a Job Task, a Job Planning Line, a Purchase Header and a Purchase Line.
        // [GIVEN] In Purchase Line make sure that the "Direct Unit Cost" is different form Item's Unit Cost.
        Initialize();

        // Create Item
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(1, 1000, 2));
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);

        CreateJobTaskWithApplyUsageLink(JobTask);

        // Create JobPlanningLine:
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable",
          JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(10));
        JobPlanningLine.Modify(true);

        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeBlank(),
          LibraryRandom.RandDecInRange(10, 20, 2), JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        // Create PurchaseHeader
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // Create PurchaseLine
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, LibraryJob.Job2PurchaseConsumableType(JobPlanningLine.Type),
          Item."No.", LibraryRandom.RandInt(10));

        PurchaseLine.Validate(Description, LibraryUtility.GenerateGUID());
        PurchaseLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
        // give a different unit cost:
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase and then run Adjust Cost - Item Entries and Update Job Item Cost jobs.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        PlanningLineDirectUnitCostBeforeJobs := JobPlanningLine."Posted Total Cost";

        // Run the first job: AdjustCostItemEntries. Item."Unit Cost" should be updated after this
        // since unit cost is changed in PurchaseLine above:
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Run the second job: RunUpdateJobItemCost. PlanningLine."Direct Unit Cost" should be updated:
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        PlanningLineDirectUnitCostAfterJobs := JobPlanningLine."Posted Total Cost";

        // [THEN] Ensure that the Planning Line's Direct Unit Cost has changed after running jobs
        Assert.AreNotEqual(
          PlanningLineDirectUnitCostBeforeJobs,
          PlanningLineDirectUnitCostAfterJobs,
          'PlanningLine."Direct Unit Cost" must be changed after running AdjustCostItemEntries and UpdateJobItemCost');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillInJobNoInPurchaseLineWhenReservationEntryExists()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] an error message pops up when fill in Job No. and Job Task No. in Purchase Order Line when Reservation Entry exists.

        Initialize();
        // [GIVEN] Create Item, create Job No. and Job Task No. and Job Planning Line. Calculate Plan and Carry Out Action Message for Requisition Worksheet.
        CreateItemWithVendorNo(Item, Item."Reordering Policy"::Order); // Any policy is ok.
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Item, Item."No.", LibraryRandom.RandInt(10), true); // Use Random for Quantity.
        CalculatePlanAndCarryOutActionMessageForRequisitionWorksheet(Item, Item."No.");

        // [WHEN] Fill in Job No. and Job Task No. in Purchase Order Line.
        asserterror GetPurchaseLineAndFillJobNo(PurchaseLine, Item."No.", JobTask."Job No.");

        // [THEN] Verify error message is correct.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Job No."), '''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoPurchReceiptWithJob()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO] Verify that Source Type/No is filled in ILEs and VEs when undoing purchase receipt.

        // [GIVEN] Receved Purchase Order with Job.
        Initialize();
        CreateItemWithVendorNo(Item, Item."Reordering Policy"::Order);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, Item."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo Purchase Receipt.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        UndoPurchRcpt(PurchaseLine);
        // [THEN] There are no Item Ledger or Value entries with empty Source Type/Source No.
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindLast();
        VerifyUndoLedgerEntrySource(
          ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchRcptLine."Document No.", PurchRcptLine."Line No.",
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoPurchReturnWithJob()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // [FEATURE] [Undo Shipment]
        // [SCENARIO] Fields "Source Type/No" and "Unit of Measure Code" should be filled in ILE and VE created by Undo of a Return Order.

        // [GIVEN] Shipped Purchase Return Order with Job.
        Initialize();
        CreateItemWithVendorNo(Item, Item."Reordering Policy"::Order);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, Item."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo Purchase Return.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        UndoPurchReturn(Item."No.");
        // [THEN] There are no Item Ledger or Value entries with empty Source Type/Source No.
        ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::Item);
        ReturnShipmentLine.SetRange("No.", Item."No.");
        ReturnShipmentLine.FindLast();
        VerifyUndoLedgerEntrySource(
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", ReturnShipmentLine."Document No.", ReturnShipmentLine."Line No.",
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."Buy-from Vendor No.");
        // [THEN] Unit of measure code is filled in all item ledger entries
        VerifyItemLedgerEntryUnitOfMeasure(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferSourceValuesUT()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemJnlLine: Record "Item Journal Line";
        UndoPostingMgt: Codeunit "Undo Posting Management";
    begin
        // [FEATURE] [Undo Posting Management]
        // [SCENARIO] Verify that Source values are tranferred to Item Journal Line from ILE/VE when function TransferSourceValues called.

        // [GIVEN] Existing Item Ledger Entry and correspondent Value Entry with source values.
        Initialize();
        MockUpILE(ItemLedgEntry);
        MockUpVE(ItemLedgEntry."Entry No.", ValueEntry);

        // [WHEN] Call TransferSourceValues.
        UndoPostingMgt.TransferSourceValues(ItemJnlLine, ItemLedgEntry."Entry No.");

        // [THEN] Values are transferred correctly.
        VerifyTransferredSource(ItemJnlLine, ItemLedgEntry, ValueEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseInvoiceWithLCYJobPricesInclVAT()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 120877] Verify Total Unit Cost/(LCY) in Job LE when Purch. Doc. Price Incl. VAT = TRUE, Job - LCY/Incoice - LCY
        // [GIVEN] Job/Job Task with no Currency defined
        Initialize();
        CreateJobWithJobTask(JobTask);
        // [GIVEN] Purchase Invoice (LCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, JobTask, '', 1, TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated without including VAT Amount
        VerifyJobLedgerEntryTotalCostValues(DocumentNo, JobTask."Job No.", TotalUnitCost, TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseInvoiceWithFCYJobPricesInclVAT()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 120877] Verify Total Unit Cost/(LCY) in Job LE when Purch. Doc. Price Incl. VAT = TRUE,  Job - LCY/Incoice - FCY
        // [GIVEN] Job/Job Task with no Currency defined
        Initialize();
        CreateJobWithJobTask(JobTask);
        // [GIVEN] Purchase Invoice (FCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, JobTask, FindFCY(), 1, TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated without including VAT Amount
        VerifyJobLedgerEntryTotalCostValues(DocumentNo, JobTask."Job No.", TotalUnitCost, TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseInvoiceWithFCYJobPricesInclVAT()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 120877] Verify Total Unit Cost/(LCY) in Job LE when Purch. Doc. Price Incl. VAT = TRUE,  Job - FCY/Incoice - FCY
        // [GIVEN] Job/Job Task with Currency defined
        Initialize();
        CreateJobWithCurrecy(JobTask, FindFCY());
        // [GIVEN] Purchase Order (FCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, JobTask, FindFCY(), 1, TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated without including VAT Amount
        VerifyJobLedgerEntryTotalCostValues(DocumentNo, JobTask."Job No.", TotalUnitCost, TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseInvoiceWithLCYJobPricesInclVAT()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 120877] Verify Total Unit Cost/(LCY) in Job LE when Purch. Doc. Price Incl. VAT = TRUE,  Job - FCY/Incoice - LCY
        // [GIVEN] Job/Job Task with Currency defined
        Initialize();
        CreateJobWithCurrecy(JobTask, FindFCY());
        // [GIVEN] Purchase Order (LCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, JobTask, '', 1, TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated without including VAT Amount
        VerifyJobLedgerEntryTotalCostValues(DocumentNo, JobTask."Job No.", TotalUnitCost, TotalUnitCostLCY);
    end;

    [Test]
    [HandlerFunctions('PageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithoutReturnShipmentAndPreventNegativeInventory()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Prevent Negative Inventory]
        // [SCENARIO 363738] Post negative Item Ledger Entry for Credit Memo with Job when "Return Shipment on Credit Memo" = No and "Prevent Negative Inventory" = yes

        Initialize();
        PurchasesPayablesSetup.Get();
        // [GIVEN] "Return Shipment on Credit Memo" = No
        UpdateReturnShipmentOnCreditMemo(false);
        // [GIVEN] Posted Purchase Invoice with Job and Item with option "Prevent Negative Inventory" = Yes
        PostPurchOrderWithItemPreventNegativeInventory(PurchHeader, PurchLine);
        // [GIVEN] Purchase Credit Memo with line copied from Posted Purchase Invoice
        CreatePurchaseHeader(PurchHeader."Document Type"::"Credit Memo", PurchHeader."Buy-from Vendor No.", PurchHeader);
        PurchHeader.GetPstdDocLinesToReverse();

        // [WHEN] Post Purchase Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Negative Purchase Credit Memo Item Ledger Entry posted
        VerifyPurcCrMemoItemLedgerEntry(PurchLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseCrMemoWithLCYJobPrices()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 364512] Verify negative Total Unit Cost/(LCY) in Job Ledger Entry when Posting Purch. Cr. Memo with LCY and Job with LCY
        // [GIVEN] Job/Job Task with no Currency defined

        Initialize();
        CreateJobWithJobTask(JobTask);
        // [GIVEN] Purchase Credit Memo (LCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", JobTask, '',
          1 / LibraryRandom.RandIntInRange(3, 5), TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated with negative amount
        VerifyJobLedgerEntryTotalCostValues(
          DocumentNo, JobTask."Job No.",
          -TotalUnitCost,
          -TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchaseCrMemoWithFCYJobPrices()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 364512] Verify negative Total Unit Cost/(LCY) in Job Ledger Entry when Posting Purch. Cr. Memo with FCY and Job with LCY
        // [GIVEN] Job/Job Task with no Currency defined
        Initialize();
        CreateJobWithJobTask(JobTask);
        // [GIVEN] Purchase Credit Memo (FCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", JobTask, FindFCY(),
          1 / LibraryRandom.RandIntInRange(3, 5), TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated with negative amount
        VerifyJobLedgerEntryTotalCostValues(
          DocumentNo, JobTask."Job No.",
          -TotalUnitCost,
          -TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseCrMemoWithFCYJobPrices()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 364512] Verify negative Total Unit Cost/(LCY) in Job Ledger Entry when Posting Purch. Cr. Memo with FCY and Job with FCY
        // [GIVEN] Job/Job Task with Currency defined
        Initialize();
        CreateJobWithCurrecy(JobTask, FindFCY());
        // [GIVEN] Purchase Credit Memo (FCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", JobTask, FindFCY(),
          1 / LibraryRandom.RandIntInRange(3, 5), TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated with negative amount
        VerifyJobLedgerEntryTotalCostValues(
          DocumentNo, JobTask."Job No.",
          -TotalUnitCost,
          -TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchaseCrMemoWithLCYJobPrices()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TotalUnitCost: Decimal;
        TotalUnitCostLCY: Decimal;
    begin
        // [SCENARIO 364512] Verify negative Total Unit Cost/(LCY) in Job Ledger Entry when Posting Purch. Cr. Memo with LCY and Job with FCY
        // [GIVEN] Job/Job Task with Currency defined
        Initialize();
        CreateJobWithCurrecy(JobTask, FindFCY());
        // [GIVEN] Purchase Credit Memo (LCY) with G/L Account line and Job/Job Task defined
        CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", JobTask, '',
          1 / LibraryRandom.RandIntInRange(3, 5), TotalUnitCostLCY, TotalUnitCost);
        // [WHEN] User Posts Purchase Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Job Ledger Entries Total Unit Cost/(LCY) are calculated with negative amount
        VerifyJobLedgerEntryTotalCostValues(
          DocumentNo, JobTask."Job No.",
          -TotalUnitCost,
          -TotalUnitCostLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UndoPurchReceiptWithJobReversesCostAmount()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        PostedPurchRcptNo: Code[20];
        PurchRcptToRevertNo: Code[20];
        CostAmount: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 371776] Cost amount is reversed after udoing purchase receipt with linked job

        Initialize();
        // [GIVEN] Item "I" valued by average cost
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Post purchase receipt "P1" for item "I" with linked job, cost amount = "X"
        CreateJobWithJobTask(JobTask);
        CreateJobPurchaseOrderWithItem(PurchaseHeader, PurchaseLine, JobTask, Item."No.");
        CostAmount := PurchaseLine."Line Amount";
        Qty := PurchaseLine.Quantity;
        PostedPurchRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post purchase receipt "P2" for the same item "I" with linked job, but with different cost amount
        PurchaseHeader."No." := '';
        CreateJobPurchaseOrderWithItem(PurchaseHeader, PurchaseLine, JobTask, Item."No.");
        PurchRcptToRevertNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Run cost adjustment for item "I" to update cost amount in job consumption entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Undo purchase receipt "P2"
        // [WHEN] Run cost adjustment for item "I"
        UndoPurchReciptAndAdjustCostItemEntries(PurchaseLine, Item);

        // [THEN] Cost amount in purchase receipt "P2" is fully reversed
        // [THEN] Cost amount in job consumption linked to purchase receipt "P1" is "-X"
        VerifyItemLedgerEntry(
          ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", Item."No.",
          ValueEntry."Document Type"::"Purchase Receipt", PostedPurchRcptNo,
          JobTask."Job No.", -Qty, 0, 0, -CostAmount);
        VerifyValueEntryReversedAmount(ValueEntry."Document Type"::"Purchase Receipt", PurchRcptToRevertNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchReceiptWithJobAndSNTrackingReversesCostAmount()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        PostedPurchRcptNo: Code[20];
        PurchRcptToRevertNo: Code[20];
        CostAmount: Decimal;
    begin
        // [FEATURE] [Undo Receipt] [Item Tracking]
        // [SCENARIO 371776] Cost amount is reversed after udoing purchase receipt with linked job and item SN tracking

        Initialize();
        // [GIVEN] Item "I" valued by average cost tracked by serial number
        CreateSerialTrackedItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Post purchase receipt "P1" for item "I" with linked job and serial number tracking
        CreateJobWithJobTask(JobTask);
        CreateJobPurchaseOrderWithItem(PurchaseHeader, PurchaseLine, JobTask, Item."No.");
        PurchaseLine.OpenItemTrackingLines();
        CostAmount := PurchaseLine."Direct Unit Cost";
        PostedPurchRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post purchase receipt "P2" for the same item "I" with linked job, but with different cost amount
        PurchaseHeader."No." := '';
        CreateJobPurchaseOrderWithItem(PurchaseHeader, PurchaseLine, JobTask, Item."No.");
        PurchaseLine.OpenItemTrackingLines();
        PurchRcptToRevertNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Run cost adjustment for item "I"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Undo purchase receipt "P2"
        // [WHEN] Run cost adjustment for item "I"
        UndoPurchReciptAndAdjustCostItemEntries(PurchaseLine, Item);

        // [THEN] Cost amount in purchase receipt "P2" is fully reversed
        // [THEN] Cost amount in job consumption linked to purchase receipt "P1" is "-X"
        VerifyItemLedgerEntry(
          ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", Item."No.",
          ValueEntry."Document Type"::"Purchase Receipt", PostedPurchRcptNo,
          JobTask."Job No.", -1, 0, 0, -CostAmount);
        VerifyValueEntryReversedAmount(ValueEntry."Document Type"::"Purchase Receipt", PurchRcptToRevertNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostTwiceWithJobPurchReceipt()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PostedPurchRcptNo: Code[20];
        ItemJnlDocNo: Code[20];
    begin
        // [FEATURE] [Adjust Cost - Item Entries] [Item Application]
        // [SCENARIO 375119] Positive Adjustment is cost adjusted when applied to negative adjustment of Job Purchase.

        Initialize();
        // [GIVEN] Item valued by average cost
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Receive Job Purchase Order
        CreateJobWithJobTask(JobTask);
        CreateJobPurchaseOrderWithItem(PurchaseHeader, PurchaseLine, JobTask, Item."No.");
        PostedPurchRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post Positive Adjustment applied to negative adjustment posted by Purchase Order
        ItemJnlDocNo := PostAppliedPosAdjustment(PurchaseLine, PostedPurchRcptNo);

        // [GIVEN] Run cost adjustment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Change Direct Unit Cost in Purchase Line, Invoice Purchase Order
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + 0.01);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run cost adjustment
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Positive Adjustment is adjusted as well.
        VerifyItemLedgerEntry(
          ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.", Item."No.",
          ValueEntry."Document Type"::" ", ItemJnlDocNo, '', PurchaseLine.Quantity,
          PurchaseLine.Quantity, PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPricesOnPurchRcptLineWhenPostingPartially()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase Receipt]
        // [SCENARIO 375061] Job Prices should be recalculated according to "Qty. to Receive" on Purchase Receipt Line

        Initialize();
        // [GIVEN] Purchase Order with Job Task attached, Quantity = "A", "Qty. to Receive" = "A" / 2, "Job Line Amount" = "X", "Job Total Price" = "Y"
        CreatePurchOrderWithJobTaskAndPartialQtyToReceive(PurchHeader, PurchLine);

        // [WHEN] Post both purchase receipts
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] Purchase Receipt Line posted with "Job Line Amount" = "X" / 2, "Job Total Price" = "Y" / 2
        VerifyJobTotalPricesOnPurchRcptLines(PurchLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobConsumptionOnValueEntryWithSameDocAndDiffItem()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        ValueEntry: Record "Value Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        DocNo: Code[20];
    begin
        // [FEATURE] [Rounding]
        // [SCENARIO 375691] Job Consumption calculation should not consider Value Entries with the same "Document No." but different "Item No."

        Initialize();
        // [GIVEN] Job with Job Task "X"
        CreateJobWithJobTask(JobTask);
        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Value Entry with type = "Rounding", Item = "A" and Job Task = "X"
        MockRoundingValueEntry(ValueEntry, JobTask, DocNo);

        // [GIVEN] Job Planning Line with Job Task = "X", Item = "B" and "Unit Cost" = 100
        CreateJobPlanningLineWithDocNo(JobPlanningLine, JobTask, DocNo, Abs(ValueEntry."Invoiced Quantity"));

        // [GIVEN] Job Journal Line for Job Planning Line
        CreateJobJournalLineWithDocNo(JobJournalLine, JobPlanningLine);

        // [WHEN] Post Job Journal Line
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Job Ledger Entry created with Job Task = "X", Item = "B" and "Unit Cost" = 100
        FindJobLedgerEntry(JobLedgEntry, DocNo, JobTask."Job No.");
        JobLedgEntry.TestField("Total Cost (LCY)", JobJournalLine."Total Cost (LCY)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostUsageWithoutLinkToJobPlanningLineWithTracking()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 380046] Usage from Job Journal Line is automatically link to match Job Planning Line if tracking exists for this line

        Initialize();

        // [GIVEN] Job "X" with "Apply Usage Link"
        CreateItemWithVendorNo(Item, Item."Reordering Policy"::"Lot-for-Lot");
        CreateJobTaskWithApplyUsageLink(JobTask);

        // [GIVEN] Job Planning Line with Item "Y", Quantity = 100
        CreateJobPlanningLine(
          JobPlanningLine, JobTask, JobPlanningLine.Type::Item, Item."No.", LibraryRandom.RandInt(10), true);
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(50, 100));
        JobPlanningLine.Modify(true);

        // [GIVEN] Calculated Plan for Job Planning Line. Reservation Entry for Job "X", Item "Y" and Quantity = -100 is generated.
        CalculatePlanAndCarryOutActionMessageForRequisitionWorksheet(Item, Item."No.");

        // [GIVEN] Posted Purchase Order generated from Plan
        FindAndPostPurchHeader(Item."No.");

        // [GIVEN] Positive adjustment of Item "Y". Quantity = 10
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        PostPositiveAdjustment(Item."No.", Quantity);

        // [GIVEN] Job Journal Line with Job "X", Item "Y" and Quantity = 10
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), JobJournalLine.Type::Item, JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);

        // [WHEN] Post Job Journal Line
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] "Qty. Posted" in Job Planning line created with Job "X", Item "Y" is 10
        JobPlanningLine.Find();
        JobPlanningLine.TestField("Qty. Posted", Quantity);

        // [THEN] Reservation Entry for Job "X", Item "Y" has Quantity = -90
        VerifyJobPlanningTrackingReservationEntry(JobTask."Job No.", Item."No.", JobPlanningLine."Qty. Posted" - JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure RestoreDimensionFromJobOnClearJobTaskNo()
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        ShortcutDimension1Code: Code[20];
        DimSetID: Integer;
    begin
        // [SCENARIO 380045] Restore dimensions from Job No. when Job Task No. without dimension is cleared in Purchase Line.
        // [FEATURE] [Job] [Dimensions] [UT]

        Initialize();

        // [GIVEN] Create Job "JOB" with Job Task "JT"
        // [GIVEN] Assign global dimension "DIM1" for "JOB", but not to "JT"
        CreateJobWithGlobalDimension(JobTask);

        // [GIVEN] Create Purchase Order "PO" with one Purchase Line
        // [GIVEN] Assign "JOB" to Purchase Line
        // [GIVEN] "DIM1" is now assigned to Purchase Line
        // [GIVEN] PurchaseLine."Dimension Set ID" "DS1" is now updated
        CreatePurchaseDocumentWithMarkedGlobalDim(JobTask, PurchaseLine, ShortcutDimension1Code, DimSetID);

        // [GIVEN] Validate PurchaseLine."Job Task No." with a "JT" with no dimensions
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);

        // [WHEN] Validate PurchaseLine."Job Task No." with blank value
        PurchaseLine.Validate("Job Task No.", '');
        PurchaseLine.Modify(true);

        // [THEN] PurchaseLine."Shortcut Dimension 1 Code" is restored back to "DIM1"
        // [THEN] PurchaseLine."Dimension Set ID" is restored back to "DS1"
        PurchaseLine.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        PurchaseLine.TestField("Dimension Set ID", DimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure DimensionShortcutNotClearedWhenJobTaskSelected()
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        ShortcutDimension1Code: Code[20];
    begin
        // [SCENARIO 380045] When Job Task is validated a Shortcut Dimension Code is not overwritten by a blank value
        // [FEATURE] [Job] [Dimensions] [UT]

        Initialize();

        // [GIVEN] Create Job "JOB" with Job Task "JT"
        // [GIVEN] Assign global dimension "DIM1" for "JOB", but not to "JT"
        CreateJobWithGlobalDimension(JobTask);

        // [GIVEN] Create Purchase Order "PO" with one Purchase Line
        // [GIVEN] Assign "JOB" to Purchase Line
        // [GIVEN] "DIM1" is now assigned to Purchase Line
        CreatePurchaseDocumentWithMarkedDimShortcuts(JobTask, PurchaseLine, ShortcutDimension1Code);

        // [WHEN] Validate PurchaseLine."Job Task No." with "JT" with no dimensions
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);

        // [THEN] PurchaseLine."Shortcut Dimension 1 Code" is not changed and equal to "DIM1"
        PurchaseLine.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithJobAndVATGroups()
    var
        PurchaseHeader: Record "Purchase Header";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroupArray: array[6] of Record "VAT Product Posting Group";
        VATPostingSetupArray: array[6] of Record "VAT Posting Setup";
        JobTask: Record "Job Task";
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
        PostedDocumentNo: Code[20];
        GLAccountNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO 380416] Job Ledger Entry is pointing to a correct General Ledger Entry when Purchase Invoice has been posted with GL Accounts with various VAT Production Posting Groups.

        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateGenPostingGroups(GenProdPostingGroupCode, GenBusPostingGroupCode);
        CreateVATPostingGroupsArray(VATBusPostingGroup, VATProdPostingGroupArray, VATPostingSetupArray);
        GLAccountNo := SetupGLAccount(VATPostingSetupArray[1], GenBusPostingGroupCode, GenProdPostingGroupCode);
        ItemNo := LibraryInventory.CreateItemNoWithPostingSetup(GenProdPostingGroupCode, VATProdPostingGroupArray[1].Code);
        VendorNo := SetupVendorWithVATPostingGroup(VATBusPostingGroup.Code, GenProdPostingGroupCode);

        // [GIVEN] Job with Job Task "JT".
        // [GIVEN] Created Purchase Invoice, where are 8 G/L Account/Item lines have various VAT Prod. Posting Group and "JT"
        CreatePurchaseInvoiceWithJobsWithVATGroups(
          PurchaseHeader, JobTask, VATProdPostingGroupArray, VATBusPostingGroup.Code, VendorNo, GLAccountNo, ItemNo);

        // [WHEN] Post the Purchase Invoice.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted Job Ledger Entries, where "Ledger Entry Type" is "G/L Account", are mapped 1-to-1 and 1-to-many to G/L Entries by "Ledger Entry No.".
        // [THEN] Posted Job Ledger Entries, where "Ledger Entry Type" is "Item", are mapped 1-to-1 to Item Ledger Entries by "Ledger Entry No.".
        VerifyJobLedgerEntriesWithGL(PostedDocumentNo, JobTask."Job No.", GLAccountNo, PurchaseHeader."Document Type");
        VerifyJobLedgerEntriesWithItemLedger(PostedDocumentNo, JobTask."Job No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeOrderWithJobIsPostedWithItemAcquisition()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO 380652] Purchase Order with negative quantity and job is posted together with a paired entry of item acquisition. The Order is fully applied to this acquisition.
        Initialize();

        // [GIVEN] Negative inventory is disallowed.
        // [GIVEN] Purchase Order for negative quantity with Job No. and Job Task No. selected.
        LibraryInventory.SetPreventNegativeInventory(true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseDocumentWithLocationAndJob(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Location.Code, -1);

        // [WHEN] Post the Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The Purchase Order is successfully posted.
        // [THEN] Item Ledger Entry with "Negative Adjmt." type and positive quantity with the Job No. (acquisition) is created.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", DocumentNo,
          PurchaseLine."Job No.", -PurchaseLine.Quantity, 0, 0, -PurchaseLine."Line Amount");
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", DocumentNo,
          PurchaseLine."Job No.", PurchaseLine.Quantity, 0, 0, PurchaseLine."Line Amount");

        // [THEN] The Order is fully applied to the acquisition.
        VerifyItemApplicationEntry(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveReturnOrderWithJobIsPostedWithItemAcquisition()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase Return Order]
        // [SCENARIO 380652] Purchase Return Order with positive quantity and job is posted together with a paired entry of item acquisition. The Return Order is fully applied to this acquisition.
        Initialize();

        // [GIVEN] Negative inventory is disallowed.
        // [GIVEN] Purchase Return Order for positive quantity with Job No. and Job Task No. selected.
        LibraryInventory.SetPreventNegativeInventory(true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseDocumentWithLocationAndJob(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Location.Code, 1);

        // [WHEN] Post the Return Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The Return Order is successfully posted.
        // [THEN] Item Ledger Entry with "Negative Adjmt." type and positive quantity with the Job No. (acquisition) is created.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", DocumentNo,
          PurchaseLine."Job No.", PurchaseLine.Quantity, 0, 0, PurchaseLine."Line Amount");
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", DocumentNo,
          PurchaseLine."Job No.", -PurchaseLine.Quantity, 0, 0, -PurchaseLine."Line Amount");

        // [THEN] The Return is fully applied to the acquisition.
        VerifyItemApplicationEntry(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeReturnOrderWithJobIsPostedWithItemWriteOff()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase Return Order]
        // [SCENARIO 380652] Purchase Return Order with negative quantity and job is posted together with a paired entry of item write-off. The write-off is fully applied to this Return.
        Initialize();

        // [GIVEN] Negative inventory is disallowed.
        // [GIVEN] Purchase Return Order for negative quantity with Job No. and Job Task No. selected.
        LibraryInventory.SetPreventNegativeInventory(true);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseDocumentWithLocationAndJob(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Location.Code, -1);

        // [WHEN] Post the Return Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The Return Order is successfully posted.
        // [THEN] Item Ledger Entry with "Negative Adjmt." type and negative quantity with the Job No. (write-off) is created.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", DocumentNo,
          PurchaseLine."Job No.", PurchaseLine.Quantity, 0, 0, PurchaseLine."Line Amount");
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."No.",
          ItemLedgerEntry."Document Type"::"Purchase Return Shipment", DocumentNo,
          PurchaseLine."Job No.", -PurchaseLine.Quantity, 0, 0, -PurchaseLine."Line Amount");

        // [THEN] The write-off is fully applied to the Return.
        VerifyItemApplicationEntry(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenNothingToCorrect()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReceiptNo: Code[20];
        PurchaseReceiptLineNo: Integer;
    begin
        // [SCENARIO 264638] If there is nothing to correct, proper error message must appear

        Initialize();

        // [GIVEN] Purchase Receipt Line that was Undone
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseReceiptLineNo := FindPurchRcptLineNo(PurchaseReceiptNo);
        UndoPurchRcptLine(PurchaseReceiptNo, PurchaseReceiptLineNo);

        // [WHEN] Undo Purchase Receipt Line
        asserterror UndoPurchRcptLine(PurchaseReceiptNo, PurchaseReceiptLineNo);

        // [THEN] Error message informs user that there is nothing to Undo
        Assert.ExpectedError('There is no lines with quantity to process.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPurchOrderInvPostForServiceItemWithJob()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        QtyOriginal: Decimal;
        QtyToInvoice: Decimal;
    begin
        // [FEATURE] [Partial Posting] [Item]
        // [SCENARIO 298490] Purchase Order with Item.Type = Service can be posted partialy as Invoice
        Initialize();

        // [GIVEN] Item with Type = Service
        // [GIVEN] Job with JobTask
        LibraryInventory.CreateServiceTypeItem(Item);
        CreateJobTaskWithApplyUsageLink(JobTask);

        // [GIVEN] Purchase Order with Item and Job and JobTask
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, Item."No.");

        // [WHEN] Purchase Order posted partially: Quantity = 30, Qty. to Receive = 30, Qty. to Invoice = 10
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        QtyOriginal := LibraryRandom.RandDecInRange(30, 100, 2);
        QtyToInvoice := Round(QtyOriginal / LibraryRandom.RandInt(5));
        PurchaseLine.Validate(Quantity, QtyOriginal);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "Qty. to Invoice" left to post = 20
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.TestField("Qty. to Invoice", QtyOriginal - QtyToInvoice);

        // [WHEN] Post remaining Qty. to Invoice
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Order fully posted and invoiced
        VerifyItemLedgEntriesInvoiced(Item."No.", PurchaseLine.Amount);
    end;

    [Test]
    procedure UndoPurchaseReceiptWithNegativeQuantityAndJob()
    var
        Vendor: Record Vendor;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
        UnitCost: Decimal;
        Sign: Integer;
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 408885] Undoing purchase receipt with negative quantity and job.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Purchase order with job, quantity = -1, unit cost = 10 LCY.
        LibraryPurchase.CreateVendor(Vendor);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, Vendor."No.", PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), -Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);

        // [GIVEN] Post a receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo the receipt.
        UndoPurchRcpt(PurchaseLine);

        // [THEN] The receipt is undone.
        // [THEN] Four item entries have been posted in total (negative receipt, undone receipt, positive job consumption, undone job consumption).
        ItemLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        Assert.RecordCount(ItemLedgerEntry, 4);

        // [THEN] Check quantity = 1 and -1, cost amount (actual) = 10 and -10.
        ItemLedgerEntry.SetAutoCalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        ItemLedgerEntry.FindSet();
        repeat
            Sign := GetILEAmountSign(ItemLedgerEntry);
            ItemLedgerEntry.TestField("Completely Invoiced", true);
            ItemLedgerEntry.TestField("Invoiced Quantity", Qty * Sign);
            ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
            ItemLedgerEntry.TestField("Cost Amount (Actual)", Qty * UnitCost * Sign);
        until ItemLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure PurchaseInvoiceWithTwoGLAccLinesWithDiffDimAndSameJobTask()
    var
        PurchaseHeader: Record "Purchase Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Dimension] [G/L Account]
        // [SCENARIO 417215] Post purchase invoice with two lines having the same G/L Account linked to the same job but different dimensions
        Initialize();

        // [GIVEN] Purchase invoice with two lines having the same G/L Account and job but different dimensions
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithGLAccDimAndJob(PurchaseHeader, JobTask, GLAccountNo);
        CreatePurchaseLineWithGLAccDimAndJob(PurchaseHeader, JobTask, GLAccountNo);

        // [THEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are two job ledger entries, each is linked to the correspondent G/L Entry by dim
        VerifyTwoJobLedgerEntriesLinkedToDiffGLEntriesByDims(JobTask, DocumentNo, GLAccountNo);
    end;

    [Test]
    procedure PurchCreditMemoWithJobViaGetReturnShipmentLine()
    var
        JobTask: Record "Job Task";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderReturn: Record "Purchase Header";
        PurchaseLineReturn: Record "Purchase Line";
        PurchaseHeaderCrMemo: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReturnShipmentNo: Code[20];
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Credit Memo] [Get Return Shipment Lines]
        // [SCENARIO 419395] Correct value entries on posting purchase credit memo with job created using "Get Return Shipment Lines".
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Item, job with job task.
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Purchase order with the job, quantity = 1, unit cost = 10.
        // [GIVEN] Post the order as Receive and Invoice.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderOrder, PurchaseLineOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.",
          Item."No.", Qty, '', WorkDate());
        PurchaseLineOrder.Validate("Direct Unit Cost", UnitCost);
        PurchaseLineOrder.Modify(true);
        AttachJobToPurchaseDocument(JobTask, PurchaseHeaderOrder, 0);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, true);

        // [GIVEN] Purchase return order with the job, quantity = 1.
        // [GIVEN] Post the return order as Ship.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderReturn, PurchaseLineReturn, PurchaseHeaderReturn."Document Type"::"Return Order", Vendor."No.",
          Item."No.", Qty, '', WorkDate());
        AttachJobToPurchaseDocument(JobTask, PurchaseHeaderReturn, 0);
        ReturnShipmentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderReturn, true, false);

        // [GIVEN] Create purchase credit memo with the job using "Get Return Shipment Lines".
        CreatePurchaseCreditMemoViaGetReturnShipmentLines(PurchaseHeaderCrMemo, PurchaseHeaderReturn);

        // [WHEN] Post the purchase credit memo.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, true);

        // [THEN] Two item entries for the return shipment are created:
        // [THEN] An entry of "Purchase" type, Quantity = -1, Invoiced Quantity = -1, "Cost Amount (Actual)" = -10.
        // [THEN] An entry of "Negative Adjmt." type, Quantity = 1, Invoiced Quantity = 1, "Cost Amount (Actual)" = 10.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", ItemLedgerEntry."Document Type"::"Purchase Return Shipment",
          ReturnShipmentNo, JobTask."Job No.", -Qty, -Qty, Round(-Qty * UnitCost, LibraryERM.GetAmountRoundingPrecision()), 0);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Item."No.", ItemLedgerEntry."Document Type"::"Purchase Return Shipment",
          ReturnShipmentNo, JobTask."Job No.", Qty, Qty, Round(Qty * UnitCost, LibraryERM.GetAmountRoundingPrecision()), 0);
    end;

    [Test]
    procedure CopyingJobPlanningLineFromPurchaseOrder()
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewPurchaseHeader: Record "Purchase Header";
        NewPurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 437187] Copy Job No., Job Task No., and Job Planning Line No. from one purchase order to another.
        Initialize();

        CreateJobAndJobPlanningLine(JobPlanningLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          JobPlanningLine."No.", LibraryRandom.RandInt(10), '', WorkDate());
        PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchHeader(
          NewPurchaseHeader, NewPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.CopyPurchaseDocument(
          NewPurchaseHeader, "Purchase Document Type From"::Order, PurchaseHeader."No.", true, false);

        NewPurchaseLine.SetRange("No.", PurchaseLine."No.");
        LibraryPurchase.FindFirstPurchLine(NewPurchaseLine, NewPurchaseHeader);
        NewPurchaseLine.TestField("Job No.", PurchaseLine."Job No.");
        NewPurchaseLine.TestField("Job Task No.", PurchaseLine."Job Task No.");
        NewPurchaseLine.TestField("Job Line Type", PurchaseLine."Job Line Type");
        NewPurchaseLine.TestField("Job Planning Line No.", PurchaseLine."Job Planning Line No.");
    end;

    [Test]
    procedure AppliesToEntryEmptyOnItemTrackingForPurchLineWithJob()
    var
        JobTask: Record "Job Task";
        Item: Record Item;
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderReturn: Record "Purchase Header";
        PurchaseLineReturn: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 438528] Applies-to Entry No. must be blank on item tracking line for purchase return order with job.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        CreateJobWithJobTask(JobTask);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create and post a purchase order linked to a job for lot-tracked item.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderOrder, PurchaseLineOrder, PurchaseHeaderOrder."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());
        PurchaseLineOrder.Validate("Job No.", JobTask."Job No.");
        PurchaseLineOrder.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLineOrder.Modify(true);
        LibraryItemTracking.CreatePurchOrderItemTracking(
          ReservationEntry, PurchaseLineOrder, '', LotNo, PurchaseLineOrder.Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [WHEN] Create a purchase return via "Get Document Lines to Reverse" function.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderReturn, PurchaseHeaderReturn."Document Type"::"Return Order", PurchaseHeaderOrder."Buy-from Vendor No.");
        CopyPostedPurchaseReceiptLines(PurchaseHeaderReturn);

        // [THEN] "Applies-to Item Entry" is not populated on item tracking line for the purchase return.
        // [THEN] This is because the original item entry for purchase is already applied to the job consumption.
        PurchaseLineReturn.SetRange("No.", Item."No.");
        LibraryPurchase.FindFirstPurchLine(PurchaseLineReturn, PurchaseHeaderReturn);
        ReservationEntry.Reset();
        ReservationEntry.SetSourceFilter(
          Database::"Purchase Line", PurchaseLineReturn."Document Type".AsInteger(), PurchaseLineReturn."Document No.",
          PurchaseLineReturn."Line No.", false);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Appl.-to Item Entry", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ConfirmHandler')]
    procedure UndoPostedReturnShipmentWithJobAndItemTracking()
    var
        JobTask: Record "Job Task";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        LotNo: Code[50];
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Undo Return Shipment] [Item Tracking]
        // [SCENARIO 451592] Stan can undo posted return shipment with job and item tracking.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Job and job task.
        LibraryItemTracking.CreateLotItem(Item);
        CreateJobWithJobTask(JobTask);
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create purchase order, assign lot number = "L", select Job No., receive and invoice.
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, Vendor."No.", PurchaseHeader);
        CreatePurchaseLineWithJob(PurchaseLine, PurchaseHeader, JobTask, Item."No.", Qty, UnitCost);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create purchase return order, select lot "L" and Job No.
        // [GIVEN] Ship the purchase return.
        CreatePurchaseHeader(PurchaseHeader."Document Type"::"Return Order", Vendor."No.", PurchaseHeader);
        CreatePurchaseLineWithJob(PurchaseLine, PurchaseHeader, JobTask, Item."No.", Qty, UnitCost);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Undo the posted return shipment.
        UndoPurchReturn(Item."No.");

        // [THEN] The shipment has been successfully undone.
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentLine.SetFilter(Quantity, '<0');
        ReturnShipmentLine.FindLast();

        // [THEN] Check item entries generated by Undo procedure:
        // [THEN] Job No. is filled in,
        // [THEN] Lot No. = "L",
        // [THEN] the item entry for job consumption (entry type = "negative adjmt.") is applied to the item entry for purchase.
        ItemLedgerEntry[1].SetRange(Positive, true);
        FindItemLedgEntry(
          ItemLedgerEntry[1], Item."No.", ItemLedgerEntry[1]."Entry Type"::Purchase,
          ItemLedgerEntry[1]."Document Type"::"Purchase Return Shipment", ReturnShipmentLine."Document No.");
        ItemLedgerEntry[1].TestField("Job No.", JobTask."Job No.");
        ItemLedgerEntry[1].TestField("Lot No.", LotNo);

        ItemLedgerEntry[2].SetRange(Positive, false);
        FindItemLedgEntry(
          ItemLedgerEntry[2], Item."No.", ItemLedgerEntry[2]."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry[2]."Document Type"::"Purchase Return Shipment", ReturnShipmentLine."Document No.");
        ItemLedgerEntry[2].TestField("Job No.", JobTask."Job No.");
        ItemLedgerEntry[2].TestField("Lot No.", LotNo);

        ItemApplicationEntry.GetOutboundEntriesAppliedToTheInboundEntry(ItemLedgerEntry[1]."Entry No.");
        ItemApplicationEntry.TestField("Item Ledger Entry No.", ItemLedgerEntry[2]."Entry No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReceiptWhenPurchaseLineWithJobPlanningLineItemWithoutJobPlanningLineNo()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 454686] Purchase lines are not being tracked properly for Job Usage link, to the proper Job Line Type on the Job
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X"
        CreateJobAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Purchase Order with Item "X", wiht Job Planning line and without "Job Planning Line No." on Purchase Line
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        PurchLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchLine.Validate("Job Line Type", JobPlanningLine."Line Type"::Budget);
        PurchLine.Modify(true);

        // [WHEN] Post Purchase Receipt
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] Posting Purchase Receipt is interrupted with Expected Empty Error
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure PurchaseOrderReceiptWhenPurchaseLineWithoutJobPlanningLineItemWithoutJobLineType()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 454686] Purchase lines are not being tracked properly for Job Usage link, to the proper Job Line Type on the Job
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X"
        CreateJobAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Purchase Order with Item "X", Job ("Job Planning Line No." is not defined to make strict link to Job)
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        PurchLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchLine.Modify(true);

        // [WHEN] Post Purchase Order
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [THEN] Posting Purchase Receipt is interrupted with Expected Empty Error
        Assert.ExpectedError('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobPlanningLineQuantityShouldNotChangeWhenPartialReceiveOrInvoice()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLine2: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        Quantity: Decimal;
        QtyToReceiveOrInvoice: Decimal;
    begin
        // [SCENARIO 461139] Job Planning Line Quantity changes after Posting Purchase Order as partially Received and partially Invoiced with multiple postings using Job Usage Link functionality
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X"
        Quantity := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateJobAndJobPlanningLine(JobPlanningLine, CreateItem(), Quantity);

        // [GIVEN] Purchase Order with Item "X", wiht Job Planning line and without "Job Planning Line No." on Purchase Line
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        PurchLine.Validate(Quantity, Quantity);
        PurchLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        QtyToReceiveOrInvoice := Round(Quantity / LibraryRandom.RandIntInRange(4, 6));
        PurchLine.Validate("Qty. to Receive", QtyToReceiveOrInvoice);
        PurchLine.Modify(true);

        // [GIVEN] Post 1st Purchase Receipt
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [GIVEN] Post 2nd Purchase Receipt
        PurchLine2.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        PurchLine2.Validate("Qty. to Receive", QtyToReceiveOrInvoice);
        PurchLine2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [WHEN] Post Purchase Invoice with Partial Quantity
        PurchLine2.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        QtyToReceiveOrInvoice += LibraryRandom.RandInt(10);
        PurchLine2.Validate("Qty. to Invoice", QtyToReceiveOrInvoice);
        PurchLine2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // [VERIFY] Verify: Job Planning Line Quantity not changed
        Assert.AreEqual(JobPlanningLine.Quantity, Quantity, JobPlanningLineQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTotalCostOnJobLedgerEntriesAfterPostingPurchaseInvoice()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
        TotalCost: Decimal;
    begin
        // [SCENARIO 467052] Total Cost (LCY) in Job Ledger Entries doesn't take into account the rounding amount defined in General Ledger Setup
        Initialize();

        // [GIVEN] Create Job, Job Task, and attach Currency on Job
        CreateJobWithJobTask(JobTask);
        UpdateCurrencyOnJob(JobTask."Job No.", FindFCY());

        // [GIVEN] Create Purchase Invoice with Job
        CreatePurchaseDocumentWithJobTask(
            PurchaseHeader,
            JobTask,
            PurchaseHeader."Document Type"::Invoice,
            PurchaseLine.Type::Item,
            CreateItem());

        // [THEN] Update Purchase Line Item Direct Unit Cost and calculate Total Cost expected
        UpdatePurchaseLineDirectUnitCost(PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        TotalCost := Round(PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity);

        // [WHEN] Post the Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [VERIFY] Verify: "Total Cost (LCY)" in Job Ledger Entries.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobTask."Job No.");
        Assert.AreEqual(
            TotalCost,
            JobLedgerEntry."Total Cost (LCY)",
            StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Cost (LCY)"), TotalCost));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseOrderPostWhenPurchaseLineItemIsWithJobLineTypeAndWhenJobPlanningLineNoIsBlank()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 464044] Purchase with Job, Job Task, and Job Line Type specified generates "Usage will not be linked to the job planning line because the Job Planning Line No. field is empty". Also, it nets qty against & links to existing Planning Line
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and Item "X"
        CreateJobAndJobPlanningLine(JobPlanningLine, CreateItem(), LibraryRandom.RandIntInRange(10, 20));


        // [GIVEN] Purchase Order with Item "X", Job ("Job Planning Line No." is not defined to make strict link to Job)
        CreatePurchaseDocument(PurchLine, PurchHeader."Document Type"::Order, JobPlanningLine."No.");
        PurchLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchLine.Validate("Job Line Type", PurchLine."Job Line Type"::Budget);
        PurchLine.Modify(true);

        // [WHEN] Post Purchase Order
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [VERIFY] Verify: Job Ledger Entry created after posting Purchase Order
        VerifyJobLedgerEntry(PurchLine, DocumentNo, PurchLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBudgetTotalCostOnJobTaskAfterPostingPurchaseInvoiceWithLinkedJobPlanningLine()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        DocumentNo: Code[20];
        No: Code[20];
    begin
        // [SCENARIO 473670] Incorrect clearing of Budget Total Cost field when posting a Purchase Invoice linked to a Job Planning Line with New Sales Pricing Feature applied in Feature Management
        Initialize();

        // [GIVEN] Job with Planning Line - "Usage Link" and G/L Account "X"
        LibraryTemplates.EnableTemplatesFeature();
        No := LibraryERM.CreateGLAccountWithPurchSetup();
        CreateJobAndJobPlanningLineWithGLAccount(JobPlanningLine, JobTask, No, 1);
        JobPlanningLine.Validate("Unit Cost", 10);
        JobPlanningLine.Modify(true);

        // [GIVEN] Purchase Invoice with G/L Account "X", Job ("Job Planning Line No." is defined to make link to Job)
        CreatePurchaseDocumentWithGLAccountLinkToJobPlanningLine(
            PurchLine,
            JobPlanningLine,
            PurchHeader."Document Type"::Invoice,
            JobPlanningLine."No.");

        // [WHEN] Post Purchase Order
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Get Job Task and Calculate Budget (Total Cost)
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobTask.CalcFields("Schedule (Total Cost)");

        // [VERIFY] Verify: Job Task Budget (Total Cost) updated after posting Purchase Invoice
        Assert.AreEqual(
            PurchLine.Quantity * JobPlanningLine."Unit Cost",
            JobTask."Schedule (Total Cost)",
            StrSubstNo(ValueMustMatchErr, JobTask.FieldCaption("Schedule (Total Cost)"), PurchLine.Quantity * JobPlanningLine."Unit Cost"));
    end;

    [Test]
    procedure ValueEntryOfSourceTypeCustomerEqualsCustomerNoOfProject()
    var
        JobTask: Record "Job Task";
        Job: Record Job;
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO 551633] Source No. field is populated with Customer No of Project when Source Type is Customer.
        Initialize();

        // [GIVEN] Create a Job with Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Get a Project.
        Job.Get(JobTask."Job No.");

        // [GIVEN] Create an Item .
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Purchase invoice.
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice, Vendor."No.", PurchaseHeader);
        CreatePurchaseLineWithJob(
            PurchaseLine, PurchaseHeader,
            JobTask, Item."No.",
            LibraryRandom.RandInt(0), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Purchase Invoice is Posted.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Value Entry is Retrieved.
        GetValueEntry(PurchInvHeader."No.", ValueEntry);

        // [THEN] Verify Value Entry line of Source Type Customer is equals to Customer No of Project.
        Assert.AreEqual(
            Job."Bill-to Customer No.",
            ValueEntry."Source No.",
            StrSubstNo(
                FieldErr, ValueEntry.FieldCaption("Source No."),
                Job."Bill-to Customer No.", ValueEntry.TableCaption()));
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayNo_BinsNo_ReceiveAndInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = false, "Bin Mandatory" = false, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order with Job. Then Invoice the Purchase Order.
        // [SCENARIO 545709] Cannot change "Job No." and "Job Task No." after Warehouse Receipt is created.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayNoBinsNo);

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayNoBinsNo.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        Commit();

        // [GIVEN] Create 2nd Job Task for Job.
        Job.Get(PurchaseLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Change "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job Task No.")));

        // [GIVEN] Create 2nd Job with Task.
        CreateJobWithJobTask(JobTask);

        // [WHEN] Change "Job No." and "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job No.", JobTask."Job No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job No.")));

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", '');
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayNo_BinsNo_ReceiveAndUndo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = false, "Bin Mandatory" = false, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order with Job. Then Undo the Purchase Receipt.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayNoBinsNo);

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayNoBinsNo.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [WHEN] Undo Purchase Receipt.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        UndoPurchRcpt(PurchaseLine);

        // [THEN] There are no Item Ledger or Value entries with empty Source Type/Source No.
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.SetLoadFields("Buy-from Vendor No.");
        PurchRcptLine.FindLast();
        VerifyUndoLedgerEntrySource(
          ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchRcptLine."Document No.", PurchRcptLine."Line No.",
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."Buy-from Vendor No.");
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayNo_BinsYes_ReceiveAndInvoice()
    var
        Bin: Record Bin;
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = false, "Bin Mandatory" = true, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order with Job. Then Invoice the Purchase Order.
        // [SCENARIO 545709] Cannot change "Job No." and "Job Task No." after Warehouse Receipt is created.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayNoBinsYes);

        // [GIVEN] Receipt Bin is set for the location.
        Bin.Get(LocationReceiveYesPutAwayNoBinsYes.Code, LocationReceiveYesPutAwayNoBinsYes."Receipt Bin Code");

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayNoBinsYes.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        Commit();

        // [GIVEN] Create 2nd Job Task for Job.
        Job.Get(PurchaseLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Change "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job Task No.")));

        // [GIVEN] Create 2nd Job with Task.
        CreateJobWithJobTask(JobTask);

        // [WHEN] Change "Job No." and "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job No.", JobTask."Job No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job No.")));

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");

        // [THEN] Warehouse Entries for Receipt and Job Consumption are posted.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"P. Order");
        WarehouseEntry.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", PurchaseLine."Line No.");
        Assert.RecordCount(WarehouseEntry, 2);

        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.TestField(Quantity, PurchaseLine.Quantity);

        WarehouseEntry.Next();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.TestField(Quantity, -PurchaseLine.Quantity);

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayNo_BinsYes_ReceiveAndUndo()
    var
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = false, "Bin Mandatory" = true, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order with Job. Then Undo the Purchase Receipt.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayNoBinsYes);

        // [GIVEN] Receipt Bin is set for the location.
        Bin.Get(LocationReceiveYesPutAwayNoBinsYes.Code, LocationReceiveYesPutAwayNoBinsYes."Receipt Bin Code");

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayNoBinsYes.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [WHEN] Undo Purchase Receipt.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        UndoPurchRcpt(PurchaseLine);

        // [THEN] There are no Item Ledger or Value entries with empty Source Type/Source No.
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.SetLoadFields("Buy-from Vendor No.");
        PurchRcptLine.FindLast();
        VerifyUndoLedgerEntrySource(
          ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchRcptLine."Document No.", PurchRcptLine."Line No.",
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."Buy-from Vendor No.");

        // [THEN] Warehouse Entries for Receipt and Job Consumption are undone.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"P. Order");
        WarehouseEntry.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", PurchaseLine."Line No.");
        Assert.RecordCount(WarehouseEntry, 4);

        WarehouseEntry.SetRange("Item No.", PurchaseLine."No.");
        WarehouseEntry.SetRange("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.CalcSums(Quantity);
        WarehouseEntry.TestField(Quantity, 0);
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayYes_BinsNo_OnlyLineWithJob_ReceiveAndInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = true, "Bin Mandatory" = false, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order that has one line with Job.
        // [SCENARIO 545709] Ensure that Warehouse Put-away not created, as Receipt is auto-completed for the line with Job.
        // [SCENARIO 545709] Ensure that "Create Put-away" action from Posted Warehouse Receipt still skips the line with Job.
        // [SCENARIO 545709] Then Invoice the Purchase Order for line with Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayYesBinsNo);

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayYesBinsNo.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");

        // [THEN] Ensure that Warehouse Put-away is not created.
        Assert.AreEqual(false, LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No."), 'Warehouse Put-away is created for the line with Job.');

        // [WHEN] Create Put-away from the posted warehouse receipt.
        FindPostedWhseReceiptLine(PostedWhseReceiptLine, PurchaseLine);
        asserterror CreatePutAwayFromPostedWhseRcpt(WarehouseActivityLine, PostedWhseReceiptLine);

        // [THEN] Error: There is nothing to handle.
        Assert.ExpectedError('There is nothing to handle.');

        // [THEN] Ensure that Warehouse Put-away is still not created.
        Assert.AreEqual(false, LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No."), 'Warehouse Put-away is created for the line with Job.');

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", '');
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayYes_BinsNo_MixtureOfLines_ReceiveAndInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineWithoutJob: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = true, "Bin Mandatory" = false, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order that has two lines: 1st with Job, 2nd without Job for another Item.
        // [SCENARIO 545709] Cannot change "Job No." and "Job Task No." after Warehouse Receipt is created.
        // [SCENARIO 545709] Ensure that Warehouse Put-away is created only for the line without Job.
        // [SCENARIO 545709] Ensure that "Create Put-away" action from Posted Warehouse Receipt still skips the line with Job.
        // [SCENARIO 545709] Then Invoice the Purchase Order for line with Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayYesBinsNo);

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayYesBinsNo.Code, 1);

        // [GIVEN] Create Purchase Order line for another Item and without Job.
        LibraryPurchase.CreatePurchaseLine(PurchaseLineWithoutJob, PurchaseHeader, PurchaseLineWithoutJob.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        PurchaseLineWithoutJob.Validate("Location Code", LocationReceiveYesPutAwayYesBinsNo.Code);
        PurchaseLineWithoutJob.Modify(true);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        Commit();

        // [GIVEN] Create 2nd Job Task for Job.
        Job.Get(PurchaseLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Change "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job Task No.")));

        // [GIVEN] Create 2nd Job with Task.
        CreateJobWithJobTask(JobTask);

        // [WHEN] Change "Job No." and "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job No.", JobTask."Job No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job No.")));

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");

        // [THEN] Ensure that Warehouse Put-away is created only for the line without Job.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", PurchaseLineWithoutJob."No.");

        // [GIVEN] Delete existing Warehouse Put-away.
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLineWithoutJob."Line No.");
        WarehouseActivityHeader.Find();
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Create Put-away from the posted warehouse receipt.
        FindPostedWhseReceiptLine(PostedWhseReceiptLine, PurchaseLineWithoutJob);
        CreatePutAwayFromPostedWhseRcpt(WarehouseActivityLine, PostedWhseReceiptLine);

        // [THEN] Ensure that Warehouse Put-away is still created only for the line without Job.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", PurchaseLineWithoutJob."No.");

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", '');
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayYes_BinsNo_OnlyLineWithJob_ReceiveAndUndo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = true, "Bin Mandatory" = false, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order that has one line with Job.
        // [SCENARIO 545709] Then Undo the Purchase Receipt.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayYesBinsNo);

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayYesBinsNo.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [WHEN] Undo Purchase Receipt.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        UndoPurchRcpt(PurchaseLine);

        // [THEN] There are no Item Ledger or Value entries with empty Source Type/Source No.
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.SetLoadFields("Buy-from Vendor No.");
        PurchRcptLine.FindLast();
        VerifyUndoLedgerEntrySource(
          ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchRcptLine."Document No.", PurchRcptLine."Line No.",
          ItemLedgerEntry."Entry Type"::Purchase, PurchaseLine."Buy-from Vendor No.");
    end;

    [Test]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveYes_PutAwayYes_BinsYes_MixtureOfLines_ReceiveAndInvoice()
    var
        Bin: Record Bin;
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineWithoutJob: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = true, "Require Put-away" = true, "Bin Mandatory" = true, "Directed Put-away and Pick" = false.
        // [SCENARIO 545709] Receive Purchase Order that has two lines: 1st with Job, 2nd without Job for another Item.
        // [SCENARIO 545709] Cannot change "Job No." and "Job Task No." after Warehouse Receipt is created.
        // [SCENARIO 545709] Ensure that Warehouse Put-away is created only for the line without Job.
        // [SCENARIO 545709] Ensure that "Create Put-away" action from Posted Warehouse Receipt still skips the line with Job.
        // [SCENARIO 545709] Then Invoice the Purchase Order for line with Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveYesPutAwayYesBinsYes);

        // [GIVEN] Receipt Bin is set for the location.
        Bin.Get(LocationReceiveYesPutAwayYesBinsYes.Code, LocationReceiveYesPutAwayYesBinsYes."Receipt Bin Code");

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveYesPutAwayYesBinsYes.Code, 1);

        // [GIVEN] Create Purchase Order line for another Item and without Job.
        LibraryPurchase.CreatePurchaseLine(PurchaseLineWithoutJob, PurchaseHeader, PurchaseLineWithoutJob.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        PurchaseLineWithoutJob.Validate("Location Code", LocationReceiveYesPutAwayYesBinsYes.Code);
        PurchaseLineWithoutJob.Modify(true);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        Commit();

        // [GIVEN] Create 2nd Job Task for Job.
        Job.Get(PurchaseLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Change "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job Task No.")));

        // [GIVEN] Create 2nd Job with Task.
        CreateJobWithJobTask(JobTask);

        // [WHEN] Change "Job No." and "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job No.", JobTask."Job No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job No.")));

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");

        // [THEN] Warehouse Entries for Receipt and Job Consumption are posted.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"P. Order");
        WarehouseEntry.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", PurchaseLine."Line No.");
        Assert.RecordCount(WarehouseEntry, 2);

        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.TestField(Quantity, PurchaseLine.Quantity);

        WarehouseEntry.Next();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.TestField(Quantity, -PurchaseLine.Quantity);

        // [THEN] Ensure that Warehouse Put-away is created only for the line without Job.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.SetRange("Item No.", PurchaseLineWithoutJob."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [GIVEN] Delete existing Warehouse Put-away.
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLineWithoutJob."Line No.");
        WarehouseActivityHeader.Find();
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Create Put-away from the posted warehouse receipt.
        FindPostedWhseReceiptLine(PostedWhseReceiptLine, PurchaseLineWithoutJob);
        CreatePutAwayFromPostedWhseRcpt(WarehouseActivityLine, PostedWhseReceiptLine);

        // [THEN] Ensure that Warehouse Put-away is still created only for the line without Job.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.SetRange("Item No.", PurchaseLineWithoutJob."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler2')]
    procedure SupportWarehousePurchaseOrderForJob_DirectedPutAwayAndPick_MixtureOfLines_ReceiveAndInvoice()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineWithoutJob: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        LotNo: array[2] of Code[50];
        LotQuantity: array[2] of Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] [Item Tracking] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Directed Put-away and Pick" = true.
        // [SCENARIO 545709] Receive Purchase Order that has two lines: 1st with Job and Lot Item Tracking (two lots), 2nd without Job for another Item.
        // [SCENARIO 545709] Ensure that Warehouse Put-away is created only for the line without Job.
        // [SCENARIO 545709] Ensure that "Create Put-away" action from Posted Warehouse Receipt still skips the line with Job.
        // [SCENARIO 545709] Then Invoice the Purchase Order for line with Job.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationDirectedPutAwayAndPick);

        // [GIVEN] Create Item with Lot tracking.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Receipt Bin is set for the location.
        Bin.Get(LocationDirectedPutAwayAndPick.Code, LocationDirectedPutAwayAndPick."Receipt Bin Code");

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", LocationDirectedPutAwayAndPick.Code, 1);

        // [GIVEN] Create Purchase Order line for another Item and without Job.
        LibraryPurchase.CreatePurchaseLine(PurchaseLineWithoutJob, PurchaseHeader, PurchaseLineWithoutJob.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        PurchaseLineWithoutJob.Validate("Location Code", LocationDirectedPutAwayAndPick.Code);
        PurchaseLineWithoutJob.Modify(true);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Set Lot No. for the Item with Job in Warehouse Receipt line. Handled in ItemTrackingLinesModalPageHandler2.
        LotNo[1] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LotQuantity[1] := LibraryRandom.RandDecInDecimalRange(1, 3, 2);
        LibraryVariableStorage.Enqueue(LotQuantity[1]);

        LotNo[2] := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LotQuantity[2] := PurchaseLine.Quantity - LotQuantity[1];
        LibraryVariableStorage.Enqueue(LotQuantity[2]);

        WarehouseReceiptLine.SetRange("Source Type", Database::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseReceiptLine.SetRange("Source Line No.", PurchaseLine."Line No.");
        WarehouseReceiptLine.FindFirst();

        WarehouseReceiptLine.OpenItemTrackingLines();

        // [WHEN] Post the Warehouse Receipt for Purchase Order.
        PostWarehouseReceipt(PurchaseHeader."No.", PurchaseLine."No.");

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -LotQuantity[1]);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");
        ItemLedgerEntry.TestField("Lot No.", LotNo[1]);

        ItemLedgerEntry.Next();
        ItemLedgerEntry.TestField(Quantity, -LotQuantity[2]);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");
        ItemLedgerEntry.TestField("Lot No.", LotNo[2]);

        // [THEN] Warehouse Entries for Receipt and Job Consumption are posted.
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"P. Order");
        WarehouseEntry.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseEntry.SetRange("Source Line No.", PurchaseLine."Line No.");
        Assert.RecordCount(WarehouseEntry, 4);

        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.TestField(Quantity, LotQuantity[1]);
        WarehouseEntry.TestField("Lot No.", LotNo[1]);

        WarehouseEntry.Next();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.TestField(Quantity, -LotQuantity[1]);
        WarehouseEntry.TestField("Lot No.", LotNo[1]);

        WarehouseEntry.Next();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.TestField(Quantity, LotQuantity[2]);
        WarehouseEntry.TestField("Lot No.", LotNo[2]);

        WarehouseEntry.Next();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.TestField(Quantity, -LotQuantity[2]);
        WarehouseEntry.TestField("Lot No.", LotNo[2]);

        // [THEN] Ensure that Warehouse Put-away is created only for the line without Job.
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.SetRange("Item No.", PurchaseLineWithoutJob."No.");
        Assert.RecordCount(WarehouseActivityLine, 2);

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, LotQuantity[1]);
        JobLedgerEntry.TestField("Bin Code", Bin.Code);
        JobLedgerEntry.TestField("Lot No.", LotNo[1]);

        JobLedgerEntry.Next();
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, LotQuantity[2]);
        JobLedgerEntry.TestField("Bin Code", Bin.Code);
        JobLedgerEntry.TestField("Lot No.", LotNo[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveNo_PutAwayYes_BinsNo_ReceiveAndInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = false, "Require Put-away" = true, "Bin Mandatory" = false.
        // [SCENARIO 545709] Receive Purchase Order with Job via Inventory Put-away. Then Invoice the Purchase Order.
        // [SCENARIO 545709] Cannot change "Job No." and "Job Task No." after Inventory Put-away is created.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveNoPutAwayYesBinsNo);

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', LocationReceiveNoPutAwayYesBinsNo.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Inventory Put-away from Purchase Order.
        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();

        // [GIVEN] Create 2nd Job Task for Job.
        Job.Get(PurchaseLine."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [WHEN] Change "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job Task No.")));

        // [GIVEN] Create 2nd Job with Task.
        CreateJobWithJobTask(JobTask);

        // [WHEN] Change "Job No." and "Job Task No." on Purchase Line.
        asserterror PurchaseLine.Validate("Job No.", JobTask."Job No.");

        // [THEN] Error: Quantity must not be changed when active Warehouse Activity Line exists.
        Assert.ExpectedError(StrSubstNo(MustNotBeChangedErr, PurchaseLine.FieldCaption("Job No.")));

        // [WHEN] Post the Inventory Put-away for Purchase Order.
        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No.");
        WarehouseActivityHeader.Find();
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", FindPurchaseReceiptNo(PurchaseLine));
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");

        // [WHEN] Post the Purchase Invoice.
        PurchaseHeader.GetBySystemId(PurchaseHeader.SystemId);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateInvtPutAwayRequestPageHandler')]
    procedure SupportWarehousePurchaseOrderForJob_ReceiveNo_PutAwayYes_BinsYes_ReceiveAndInvoice()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
        LotNo: Code[50];
        PurchaseReceiptNo: Code[20];
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO 545709] Location with "Require Receive" = false, "Require Put-away" = true, "Bin Mandatory" = true.
        // [SCENARIO 545709] Receive and Invoice Purchase Order with Job and Lot Item Tracking via Inventory Put-away.
        Initialize();

        // [GIVEN] Set Warehouse Employee for the location.
        CreateDefaultWarehouseEmployee(LocationReceiveNoPutAwayYesBinsYes);

        // [GIVEN] Create Item with Lot tracking.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Bin for receiving.
        LibraryWarehouse.CreateBin(Bin, LocationReceiveNoPutAwayYesBinsYes.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Create Job with Purchase Order with Job.
        CreatePurchaseDocumentWithLocationAndJob(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", LocationReceiveNoPutAwayYesBinsYes.Code, 1);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Inventory Put-away from Purchase Order.
        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();

        // [WHEN] Receive and Invoice the Inventory Put-away for Purchase Order.
        LotNo := LibraryUtility.GenerateGUID();

        LibraryWarehouse.FindWhseActivityBySourceDoc(WarehouseActivityHeader, Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No.");
        WarehouseActivityHeader.Find();
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Item Ledger Entry for Job Consumption is posted.
        PurchaseReceiptNo := FindPurchaseReceiptNo(PurchaseLine);
        FindItemLedgEntry(
          ItemLedgerEntry, PurchaseLine."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgerEntry."Document Type"::"Purchase Receipt", PurchaseReceiptNo);
        ItemLedgerEntry.TestField(Quantity, -PurchaseLine.Quantity);
        ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
        ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.");
        ItemLedgerEntry.TestField("Lot No.", LotNo);

        // [THEN] Warehouse Entries for Receipt and Job Consumption are posted.
        WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::"Posted Rcpt.");
        WarehouseEntry.SetRange("Reference No.", PurchaseReceiptNo);
        Assert.RecordCount(WarehouseEntry, 2);

        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Positive Adjmt.");
        WarehouseEntry.TestField(Quantity, PurchaseLine.Quantity);
        WarehouseEntry.TestField("Lot No.", LotNo);

        WarehouseEntry.Next();
        WarehouseEntry.TestField("Item No.", PurchaseLine."No.");
        WarehouseEntry.TestField("Location Code", PurchaseLine."Location Code");
        WarehouseEntry.TestField("Bin Code", Bin.Code);
        WarehouseEntry.TestField("Entry Type", WarehouseEntry."Entry Type"::"Negative Adjmt.");
        WarehouseEntry.TestField(Quantity, -PurchaseLine.Quantity);
        WarehouseEntry.TestField("Lot No.", LotNo);

        // [THEN] Job Ledger Entry for Job Usage is posted.
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.FindFirst();
        FindJobLedgerEntry(JobLedgerEntry, PurchInvHeader."No.", PurchaseLine."Job No.");
        JobLedgerEntry.TestField("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        JobLedgerEntry.TestField(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField("Location Code", PurchaseLine."Location Code");
        JobLedgerEntry.TestField(Quantity, PurchaseLine.Quantity);
        JobLedgerEntry.TestField("Bin Code", Bin.Code);
        JobLedgerEntry.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderReserveFromCurrentLineHandler2')]
    procedure PurchaseLineNotReservedWhenItemTypeNonInventoryOrService()
    var
        Item: array[3] of Record Item;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        i: Integer;
        Quantity: Decimal;
    begin
        // [SCENARIO 563482] Verify that it is not possible to reserve a sales line when the item type is Non-Inventory or Service.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Inventory, Non Inventory & Service type item.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateNonInventoryTypeItem(Item[2]);
        LibraryInventory.CreateServiceTypeItem(Item[3]);

        // [GIVEN] Create Job and Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Set the Work Date to be later than the Purchase Document date.
        WorkDate := WorkDate() + 1;

        for i := 1 to LibraryRandom.RandIntInRange(3, 3) do begin
            // [GIVEN] Create a job planning line for Inventory, Non-Inventory, and Service type items.
            CreateJobPlanningLine(
                JobPlanningLine, JobTask, JobPlanningLine.Type::Item, Item[i]."No.", Quantity, true);
            JobPlanningLine.Validate(Reserve, JobPlanningLine.Reserve::Optional);
            JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
            JobPlanningLine.Modify(true);

            // [GIVEN] Create a purchase line for Inventory, Non-Inventory, and Service type items.
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item[i]."No.", Quantity);

            Commit();
            // [GIVEN] Open Purchase Order Page
            PurchaseOrder.OpenEdit();
            PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
            PurchaseOrder.PurchLines.Filter.SetFilter("No.", Item[i]."No.");

            // [WHEN] Item type Inventory
            if Item[i].IsInventoriableType() then
                PurchaseOrder.PurchLines.Reserve.Invoke()
            else
                asserterror PurchaseOrder.PurchLines.Reserve.Invoke();
            PurchaseOrder.Close();
        end;

        // [GIVEN] Post the Purchase Document
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Remaining Quantity on Item Ledger Entry.
        VerifyItemLedgerEntry(Item[1], Quantity); // Item Type Inventory.
        VerifyItemLedgerEntry(Item[2], 0); // Item Type Non Inventory.
        VerifyItemLedgerEntry(Item[3], 0); // Item Type Service.
    end;

    local procedure Initialize()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        PurchasePrice: Record "Purchase Price";
        SalesPrice: Record "Sales Price";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Consumption Purchase");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        WarehouseEmployee.DeleteAll();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Consumption Purchase");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.UpdateGenProdPostingSetup();
        // Removing special prices
        PurchasePrice.DeleteAll(true);
        SalesPrice.DeleteAll(true);
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        CreateLocationsWithWarehousing();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Consumption Purchase");
    end;

    local procedure CreateLocationsWithWarehousing()
    var
        Bin: Record "Bin";
    begin
        // Location with "Require Receive" = true, "Require Put-away" = false, "Bin Mandatory" = false.
        LibraryWarehouse.CreateLocationWMS(LocationReceiveYesPutAwayNoBinsNo, false, false, false, true, false);

        // Location with "Require Receive" = true, "Require Put-away" = false, "Bin Mandatory" = true.
        LibraryWarehouse.CreateLocationWMS(LocationReceiveYesPutAwayNoBinsYes, true, false, false, true, false);
        // Create Bin for the location. Set as Receipt Bin.
        LibraryWarehouse.CreateBin(Bin, LocationReceiveYesPutAwayNoBinsYes.Code, LibraryUtility.GenerateGUID(), '', '');
        LocationReceiveYesPutAwayNoBinsYes."Receipt Bin Code" := Bin.Code;
        LocationReceiveYesPutAwayNoBinsYes.Modify(true);

        // Location with "Require Receive" = true, "Require Put-away" = true, "Bin Mandatory" = false.
        LibraryWarehouse.CreateLocationWMS(LocationReceiveYesPutAwayYesBinsNo, false, true, false, true, false);

        // Location with "Require Receive" = true, "Require Put-away" = true, "Bin Mandatory" = true.
        LibraryWarehouse.CreateLocationWMS(LocationReceiveYesPutAwayYesBinsYes, true, true, false, true, false);
        // Create Bin for the location. Set as Receipt Bin.
        LibraryWarehouse.CreateBin(Bin, LocationReceiveYesPutAwayYesBinsYes.Code, LibraryUtility.GenerateGUID(), '', '');
        LocationReceiveYesPutAwayYesBinsYes."Receipt Bin Code" := Bin.Code;
        LocationReceiveYesPutAwayYesBinsYes.Modify(true);

        // Location with "Directed Put-away and Pick" = true.
        LibraryWarehouse.CreateFullWMSLocation(LocationDirectedPutAwayAndPick, 1);

        // Location with "Require Receive" = false, "Require Put-away" = true, "Bin Mandatory" = false.
        LibraryWarehouse.CreateLocationWMS(LocationReceiveNoPutAwayYesBinsNo, false, true, false, false, false);

        // Location with "Require Receive" = false, "Require Put-away" = true, "Bin Mandatory" = true.
        LibraryWarehouse.CreateLocationWMS(LocationReceiveNoPutAwayYesBinsYes, true, true, false, false, false);
    end;

    local procedure PostJobPurchaseOrder(JobCurrency: Code[10]; PurchaseOrderCurrency: Code[10])
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        // 1. Setup: Create a Purchase Order with Job selected on the Purchase Lines. Setup Currency on Job and Purchase Order as per
        // parameter passed. Save Purchase Line in temporary table.
        Initialize();
        CreateJobWithCurrecy(JobTask, JobCurrency);
        CreatePurchaseOrderWithCurrency(PurchaseHeader, PurchaseOrderCurrency);
        CreatePurchaseLines(PurchaseHeader);
        AttachJobTaskToPurchaseDoc(JobTask, PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryJob.CopyPurchaseLines(PurchaseLine, TempPurchaseLine);

        // 2. Exercise: Post the Purchase Order as Receive and Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Check the entries created after Posting of Purchase Order.
        VerifyJobInfoOnPurchRcptLines(TempPurchaseLine);
        VerifyItemLedger(TempPurchaseLine);
        VerifyValueEntries(TempPurchaseLine);
        LibraryJob.VerifyPurchaseDocPostingForJob(TempPurchaseLine)
    end;

    local procedure PostJobPurchaseOrderWithTypeGLAccount(JobCurrency: Code[10]; PurchaseOrderCurrency: Code[10])
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        JobLedgerEntryTotalCostLCY: Decimal;
        GLEntryTotalCostLCY: Decimal;
        TotalCost: Decimal;
        UnitCostLCY: Decimal;
    begin
        // 1. Setup: Create a Purchase Order with Job
        Initialize();
        CreateJobWithCurrecy(JobTask, JobCurrency);
        CreatePurchaseOrderWithCurrency(PurchaseHeader, PurchaseOrderCurrency);
        CreateGLPurchaseLine(PurchaseHeader);
        AttachJobTaskToPurchaseDoc(JobTask, PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        CalculatePurchaseLineAmountValue(PurchaseLine, JobCurrency, JobLedgerEntryTotalCostLCY, TotalCost);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        GLEntryTotalCostLCY := CalculatePurchaseLineAmountValueGL(PurchaseLine, PurchaseHeader."Currency Factor");
        UnitCostLCY := PurchaseLine."Unit Cost (LCY)";

        // 2. Exercise: Post the Purchase Order as Receive and Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Check the GL Entry amount with JobLedger "Total Cost (LCY)"
        VerifyJobLedgerEntryValue(DocumentNo, JobTask."Job No.", JobLedgerEntryTotalCostLCY, UnitCostLCY);
        VerifyGLEntryValue(DocumentNo, GLEntryTotalCostLCY, PurchaseLine."No.");
    end;

    local procedure PostJobPurchaseOrderWithTypeItem(JobCurrency: Code[10]; PurchaseOrderCurrency: Code[10])
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        DocumentNo: Code[20];
        JobLedgerEntryTotalCostLCY: Decimal;
        GLEntryTotalCostLCY: Decimal;
        TotalCost: Decimal;
        UnitCostLCY: Decimal;
    begin
        // 1. Setup: Create a Purchase Order with Job
        Initialize();
        CreateJobWithCurrecy(JobTask, JobCurrency);
        CreatePurchaseOrderWithCurrency(PurchaseHeader, PurchaseOrderCurrency);
        CreateItemPurchaseLine(PurchaseHeader);
        AttachJobTaskToPurchaseDoc(JobTask, PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        CalculatePurchaseLineAmountValue(PurchaseLine, PurchaseOrderCurrency, JobLedgerEntryTotalCostLCY, TotalCost);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        GLEntryTotalCostLCY := CalculatePurchaseLineAmountValueGL(PurchaseLine, PurchaseHeader."Currency Factor");
        UnitCostLCY := PurchaseLine."Unit Cost (LCY)";
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // 2. Exercise: Post the Purchase Order as Receive and Invoice.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Check the GL Entry amount with JobLedger "Total Cost (LCY)"
        VerifyJobLedgerEntryValue(DocumentNo, JobTask."Job No.", JobLedgerEntryTotalCostLCY, UnitCostLCY);
        VerifyGLEntryValue(DocumentNo, GLEntryTotalCostLCY, GeneralPostingSetup."Purch. Account");
    end;

    local procedure PreparePurchHeaderWithJobPlanningNo(Quantity: Decimal; QtyToReceive: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Purchase Order with Job Planning Line No. and update Quantity To Receive on Purchase Line.
        PreparePurchHeaderAndJobPlanningLine(PurchaseHeader, JobPlanningLine, Quantity, QtyToReceive);

        // 2. Exercise: Post Purchase Order with partial Quantity.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 3. Verify: Verify Quantity on Job Planning Line.
        VerifyQuantityOnJobPlanningLine(JobPlanningLine, Quantity);
    end;

    local procedure PreparePurchHeaderAndJobPlanningLine(var PurchaseHeader: Record "Purchase Header"; var JobPlanningLine: Record "Job Planning Line"; Quantity: Decimal; QtyToReceive: Decimal)
    var
        Item: Record Item;
        JobTask: Record "Job Task";
    begin
        CreatePurchaseOrderWithExpectedReceiptDate(PurchaseHeader, LibraryInventory.CreateItem(Item), Quantity);
        CreateJobAndJobPlanningLine(JobPlanningLine, Item."No.", Quantity);
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        AttachJobToPurchaseDocument(JobTask, PurchaseHeader, JobPlanningLine."Line No.");
        UpdatePurchLineQtyToReceive(PurchaseHeader, QtyToReceive);
    end;

    local procedure CalculateCurrencyFactor(CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure CalculateJobLedgerEntryQuantity(DocumentNo: Code[20]; JobNo: Code[20]) Quantity: Decimal
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        repeat
            Quantity += JobLedgerEntry.Quantity;
        until JobLedgerEntry.Next() = 0;
    end;

    local procedure CalculatePurchaseLineQuantityToInvoice(var TempPurchaseLine: Record "Purchase Line" temporary) Quantity: Decimal
    begin
        TempPurchaseLine.FindSet();
        repeat
            Quantity += TempPurchaseLine."Qty. to Invoice";
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var Item: Record Item; StartDate: Date; EndDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure CalculatePlanAndCarryOutActionMessageForRequisitionWorksheet(Item: Record Item; ItemNo: Code[20])
    begin
        CalculatePlanForRequisitionWorksheet(Item, WorkDate(), WorkDate());
        AcceptAndCarryOutActionMessageForRequisitionWorksheet(ItemNo);
    end;

    local procedure CreateItemWithMultipleUOM(): Code[20]
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        exit(Item."No.");
    end;

    local procedure CreateJobTaskWithApplyUsageLink(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobAndJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(JobPlanningLine, JobTask, JobPlanningLine.Type::Item, ItemNo, Quantity, true);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; ConsumableType: Enum "Job Planning Line Type"; ItemNo: Code[20];
                                                                                                                                           Quantity: Decimal;
                                                                                                                                           UsageLink: Boolean)
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, ConsumableType, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Validate("Usage Link", UsageLink);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithDocNo(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; DocNo: Code[20]; NewQuantity: Decimal)
    begin
        CreateJobPlanningLine(JobPlanningLine, JobTask,
          JobPlanningLine.Type::Item, CreateItem(), NewQuantity, true);
        JobPlanningLine.Validate("Document No.", DocNo);
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobJournalLineWithDocNo(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        LibraryJob.CreateJobJournalLineForPlan(JobPlanningLine, LibraryJob.UsageLineTypeBoth(), 1, JobJournalLine);
        JobJournalLine.Validate("Document No.", JobPlanningLine."Document No.");
        JobJournalLine.Modify(true);
        // Disable "No. Series" in order to post Job Journal Line with specific "Document No."
        JobJnlBatch.Get(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name");
        JobJnlBatch.Validate("No. Series", '');
        JobJnlBatch.Modify(true);
    end;

    local procedure CreateJobWithGlobalDimension(var JobTask: Record "Job Task")
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Job, JobTask."Job No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateDefaultDimForJob(JobNo: Code[20]; ValuePosting: Enum "Default Dimension value Posting Type")
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindFirst();

        if ValuePosting = DefaultDimension."Value Posting"::"No Code" then
            LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, JobNo, Dimension.Code, '')
        else
            LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Job, JobNo, Dimension.Code, DimensionValue.Code);

        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateInvoiceWithGetReceipt(PurchaseOrderNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // Create a new Purchase Invoice - Purchase Header. Create Purchase Invoice Lines by Get Receipt Lines function for the Purchase
        // Receipt created earlier.
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.FindFirst();

        CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.", PurchaseHeader);

        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // Remove the header.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.FindFirst();
        PurchaseLine.Delete(true);
    end;

    local procedure CreatePurchaseOrderForJobTask(var PurchaseHeader: Record "Purchase Header")
    var
        JobTask: Record "Job Task";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, Vendor."No.", PurchaseHeader);
        CreatePurchaseLines(PurchaseHeader);

        AttachJobTaskToPurchaseDoc(JobTask, PurchaseHeader);
    end;

    local procedure CreatePurchaseDocumentWithJobTask(var PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
    begin
        // Take Random Quantity.
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseHeader(DocumentType, Vendor."No.", PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDecInDecimalRange(5, 10, 2));
        AttachJobToPurchaseDocument(JobTask, PurchaseHeader, 0);
    end;

    local procedure CreatePurchaseDocumentWithMarkedGlobalDim(var JobTask: Record "Job Task"; var PurchaseLine: Record "Purchase Line"; var ShortcutDimension1Code: Code[20]; var DimSetID: Integer)
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Modify(true);
        ShortcutDimension1Code := PurchaseLine."Shortcut Dimension 1 Code";
        DimSetID := PurchaseLine."Dimension Set ID";
    end;

    local procedure CreatePurchaseDocumentWithMarkedDimShortcuts(var JobTask: Record "Job Task"; var PurchaseLine: Record "Purchase Line"; var ShortcutDimension1Code: Code[20])
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Modify(true);
        ShortcutDimension1Code := PurchaseLine."Shortcut Dimension 1 Code";
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        // Create Purchase Line with Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");  // Input random Vendor Cr. Memo No.
        PurchaseHeader.Validate("Document Date", CalcDate(StrSubstNo('<-%1D>', LibraryRandom.RandInt(10)), WorkDate()));
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLineWithReserveItemAndUpdateAdjustmentAccount(PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithReserveOption(Item.Reserve::Always),
          LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        UpdateAdjustmentAccounts(
          PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group",
          CreateGLAccountWithVAT(GeneralPostingSetup, VATPostingSetup));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Used Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeaderWithGLAccountLineAttachedToJobTask(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; JobTask: Record "Job Task";
                                                                                                                                      CurrencyCode: Code[10];
                                                                                                                                      Factor: Decimal; var TotalCostLCY: Decimal; var TotalCost: Decimal)
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        Job: Record Job;
    begin
        Job.Get(JobTask."Job No.");
        Vendor.Get(CreateVendorWithSetup(VATPostingSetup));
        CreatePurchaseHeader(DocType, Vendor."No.", PurchaseHeader);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(
            VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Qty. to Invoice", Round(PurchaseLine.Quantity * Factor, 1));
        PurchaseLine.Modify(true);
        AttachJobToPurchaseDocument(JobTask, PurchaseHeader, 0);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        CalculatePurchaseLineAmountValue(PurchaseLine, Job."Currency Code", TotalCostLCY, TotalCost);
    end;

    local procedure CreatePurchOrderWithJobTaskAndPartialQtyToReceive(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        CreatePurchaseHeader(PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), PurchHeader);
        CreateItemPurchaseLine(PurchHeader);
        AttachJobTaskToPurchaseDoc(JobTask, PurchHeader);
        UpdatePurchaseLineQuantities(PurchHeader);
        GetPurchaseLines(PurchHeader, PurchLine);
        PurchLine.Validate("Job Unit Price", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, VendorNo, PurchaseHeader);
        CreatePurchaseLineWithReserveItemAndUpdateAdjustmentAccount(PurchaseHeader);
        AttachJobToPurchaseDocument(JobTask, PurchaseHeader, 0);
    end;

    local procedure CreatePurchaseDocumentWithLocationAndJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; SignFactor: Integer)
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        if ItemNo = '' then
            ItemNo := CreateItem();
        CreatePurchaseDocumentWithJobTask(
          PurchaseHeader, JobTask, DocumentType, PurchaseLine.Type::Item, ItemNo);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate(Quantity, SignFactor * PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithPrepayment(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, VendorNo, PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));  // Take Random Value.
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        AttachJobToPurchaseDocument(JobTask, PurchaseHeader, 0);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    local procedure CreatePurchaseOrderWithPrepaymentAndJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var GeneralPostingSetup: Record "General Posting Setup"; var JobTask: Record "Job Task"; var GLAccountNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);
        GLAccountNo := CreateGLAccountWithVAT(GeneralPostingSetup, VATPostingSetup);
        CreatePurchaseOrderWithPrepayment(
          PurchaseLine, JobTask, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdatePurchasePrepaymentAccount(PurchaseLine, GLAccountNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure CreateJobPurchaseOrderWithItem(var PurchHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task"; ItemNo: Code[20])
    begin
        CreatePurchaseHeader(PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), PurchHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        AttachJobToPurchaseDocument(JobTask, PurchHeader, 0);
        PurchaseLine.Find(); // return line with "Job No." attached
    end;

    local procedure CreatePurchaseLineWithGLAccDimAndJob(PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task"; GLAccountNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        PurchaseLine.Validate(
            "Dimension Set ID",
            LibraryDimension.CreateDimSet(PurchaseLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithJob(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchOrderWithItemPreventNegativeInventory(var PurchHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Prevent Negative Inventory", Item."Prevent Negative Inventory"::Yes);
        Item.Modify(true);

        CreateJobPurchaseOrderWithItem(PurchHeader, PurchaseLine, JobTask, Item."No.");
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure CreateGLAccountWithVAT(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        exit(LibraryInventory.CreateItem(Item));
    end;

    local procedure CreateItemWithReserveOption(Reserve: Enum "Reserve Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Reserve);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateSerialTrackedItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
    end;

    local procedure CreateJobPurchaseOrderWithTracking(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; CurrencyCode: Code[10])
    var
        JobTask: Record "Job Task";
        Vendor: Record Vendor;
    begin
        CreateJobWithCurrecy(JobTask, CurrencyCode);

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(9));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(99, 2));
        PurchaseLine.Modify(true);
        PurchaseLine.OpenItemTrackingLines();

        AttachJobTaskToPurchaseDoc(JobTask, PurchaseHeader);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CalculatePurchaseLineAmountValue(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; var TotalCostLCY: Decimal; var TotalCost: Decimal)
    var
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        PurchaseHeader: Record "Purchase Header";
        JobTotalCostLCY: Decimal;
        JobTotalCost2: Decimal;
        JobUnitCost: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        PurchaseLine.FindSet();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        repeat
            if CurrencyCode <> '' then begin
                Currency.Get(CurrencyCode);
                AmountRoundingPrecision := Currency."Amount Rounding Precision";
                JobUnitCost := Round(
                    CurrencyExchRate.ExchangeAmtLCYToFCY(
                      PurchaseHeader."Posting Date",
                      CurrencyCode,
                      PurchaseLine."Unit Cost (LCY)",
                      CurrencyExchRate.ExchangeRate(PurchaseHeader."Posting Date", CurrencyCode)),
                    Currency."Unit-Amount Rounding Precision");
            end else begin
                AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
                JobUnitCost := PurchaseLine."Unit Cost (LCY)"
            end;
            JobTotalCostLCY :=
              PurchaseLine."Qty. to Invoice" * Round(PurchaseLine."Unit Cost (LCY)", LibraryERM.GetUnitAmountRoundingPrecision());
            TotalCostLCY += Round(JobTotalCostLCY, AmountRoundingPrecision);
            TotalCost += Round(JobUnitCost * PurchaseLine."Qty. to Invoice", AmountRoundingPrecision);

            if (PurchaseLine."Currency Code" <> '') and (CurrencyCode = '') then begin
                Currency.Get(PurchaseLine."Currency Code");
                JobTotalCost2 += Round(CurrencyExchRate.ExchangeAmtFCYToLCY(
                                    PurchaseHeader."Posting Date",
                                    PurchaseHeader."Currency Code",
                                    Round(PurchaseLine."Unit Cost" * PurchaseLine."Qty. to Invoice", Currency."Amount Rounding Precision"),
                                    PurchaseHeader."Currency Factor"),
                                Currency."Amount Rounding Precision");

            end;
        until PurchaseLine.Next() = 0;

        if (PurchaseHeader."Currency Code" <> '') and (CurrencyCode = '') then begin
            TotalCostLCY := JobTotalCost2;
            TotalCost := JobTotalCost2;
        end;
    end;

    local procedure CalculatePurchaseLineAmountValueGL(var PurchaseLine: Record "Purchase Line"; CurrencyFactor: Decimal) Total: Decimal
    begin
        PurchaseLine.FindSet();
        repeat
            if CurrencyFactor <> 0 then
                Total += Round(PurchaseLine."Line Amount" / CurrencyFactor, LibraryERM.GetAmountRoundingPrecision())
            else
                Total += Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", LibraryERM.GetAmountRoundingPrecision());
        until PurchaseLine.Next() = 0;
    end;

    local procedure CreateJobWithReserveOption(var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate(Reserve, Job.Reserve::Always);
        Job.Modify(true);
    end;

    local procedure CreateJobWithCurrecy(var JobTask: Record "Job Task"; JobCurrency: Code[10])
    begin
        CreateJobWithJobTask(JobTask);
        UpdateCurrencyOnJob(JobTask."Job No.", JobCurrency);
    end;

    local procedure CreatePurchaseOrderWithCurrency(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, Vendor."No.", PurchaseHeader);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Create Purchase Lines in multiple of 4 of each Job Line Type as blank, Budget, Billable, Both Budget and
        // Billable and Type as Item and G/L Account.
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        for Counter := 1 to 4 do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
            PurchaseLine.Validate(Description, Format(LibraryUtility.GenerateGUID()));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100) / 10);
            PurchaseLine.Modify(true);
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithVAT(GeneralPostingSetup, VATPostingSetup),
              LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100) / 10);
            // PurchaseLine.VALIDATE(Description,FORMAT(LibraryUtility.GenerateGUID()));
            PurchaseLine.Validate(Description, PurchaseLine."No.");
            PurchaseLine.Modify(true)
        end;
    end;

    local procedure CreateGLPurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithVAT(GeneralPostingSetup, VATPostingSetup), LibraryRandom.RandDec(15, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(15, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemPurchaseLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(), LibraryRandom.RandDec(15, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(15, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithSetup(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        FindVATPostingSetup(VATPostingSetup);
        exit(CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateGenPostingGroups(var GenProdPostingGroupCode: Code[20]; var GenBusPostingGroupCode: Code[20])
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        GenBusPostingGroupCode := GenBusPostingGroup.Code;
        GenProdPostingGroupCode := GenProdPostingGroup.Code;
    end;

    local procedure CreateVATPostingGroupsArray(var VATBusPostingGroup: Record "VAT Business Posting Group"; var VATProdPostingGroupArray: array[6] of Record "VAT Product Posting Group"; var VATPostingSetupArray: array[6] of Record "VAT Posting Setup")
    var
        CurrentGroupNo: Integer;
        VATRate: Integer;
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        for CurrentGroupNo := 1 to ArrayLen(VATProdPostingGroupArray) do begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroupArray[CurrentGroupNo]);
            LibraryERM.CreateVATPostingSetup(
              VATPostingSetupArray[CurrentGroupNo], VATBusPostingGroup.Code,
              VATProdPostingGroupArray[CurrentGroupNo].Code);
            VATRate := LibraryRandom.RandIntInRange(5, 50);
            if CurrentGroupNo in [3, 4] then
                VATRate := 0;
            VATPostingSetupArray[CurrentGroupNo].Validate("VAT %", VATRate);
            VATPostingSetupArray[CurrentGroupNo].Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetupArray[CurrentGroupNo].Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetupArray[CurrentGroupNo].Validate(
              "VAT Identifier",
              CopyStr(
                LibraryERM.CreateRandomVATIdentifierAndGetCode(), 1, MaxStrLen(VATPostingSetupArray[CurrentGroupNo]."VAT Identifier")));
            VATPostingSetupArray[CurrentGroupNo].Modify(true);
        end;
    end;

    local procedure CreatePurchaseInvoiceWithJobsWithVATGroups(var PurchaseHeader: Record "Purchase Header"; var JobTask: Record "Job Task"; VATProdPostingGroupArray: array[6] of Record "VAT Product Posting Group"; VATBusPostingGroupCode: Code[20]; VendorNo: Code[20]; GLAccountNo: Code[20]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::Item, ItemNo, VATBusPostingGroupCode, VATProdPostingGroupArray[1].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account", GLAccountNo, VATBusPostingGroupCode, VATProdPostingGroupArray[2].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::Item, ItemNo, VATBusPostingGroupCode, VATProdPostingGroupArray[3].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::Item, ItemNo, VATBusPostingGroupCode, VATProdPostingGroupArray[3].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account", GLAccountNo, VATBusPostingGroupCode, VATProdPostingGroupArray[4].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account", GLAccountNo, VATBusPostingGroupCode, VATProdPostingGroupArray[5].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account", GLAccountNo, VATBusPostingGroupCode, VATProdPostingGroupArray[6].Code);
        CreatePurchLineWithJobsAndVATPostingGroups(
          PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account", GLAccountNo, VATBusPostingGroupCode, VATProdPostingGroupArray[6].Code);
    end;

    local procedure CreatePurchLineWithJobsAndVATPostingGroups(PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task"; LineType: enum "Purchase Line Type"; CodeNo: Code[20];
                                                                                                                                                   VATBusPostingGroupCode: Code[20];
                                                                                                                                                   VATProdPostingGroupCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        LineAmount: Decimal;
    begin
        LineAmount := LibraryRandom.RandDecInRange(100, 500, 2);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, CodeNo, LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Validate("Direct Unit Cost", LineAmount);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::"Both Budget and Billable");
        PurchaseLine.Validate("Job Unit Price", LineAmount);
        PurchaseLine.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseCreditMemoViaGetReturnShipmentLines(var PurchaseHeaderCrMemo: Record "Purchase Header"; PurchaseHeaderReturn: Record "Purchase Header")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderCrMemo, PurchaseHeaderCrMemo."Document Type"::"Credit Memo", PurchaseHeaderReturn."Buy-from Vendor No.");
        ReturnShipmentLine.SetRange("Return Order No.", PurchaseHeaderReturn."No.");
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeaderCrMemo);
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
    end;

    local procedure SetupGLAccount(VATPostingSetup: Record "VAT Posting Setup"; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure SetupVendorWithVATPostingGroup(VATBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroupCode));
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, Vendor."Gen. Bus. Posting Group", GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetReceiptLineOnPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; OrderNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // Create a new Purchase Invoice - Purchase Header. Create Purchase Invoice Lines by Get Receipt Lines function for the Purchase Receipt created earlier.
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst();

        CreatePurchaseHeader(PurchaseHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.", PurchaseHeader);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandDec(10, 2));  // Used Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Used Random value for Direct Unit Cost.
        PurchaseLine.Validate("VAT Prod. Posting Group", PurchRcptLine."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    local procedure AttachJobToPurchaseDocument(JobTask: Record "Job Task"; PurchaseHeader: Record "Purchase Header"; JobPlanningLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLineNo);
        PurchaseLine.Modify(true);
    end;

    local procedure AttachJobTaskToPurchaseDoc(JobTask: Record "Job Task"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        repeat
            Counter += 1;
            PurchaseLine.Validate("Job No.", JobTask."Job No.");
            PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
            PurchaseLine.Validate("Job Line Type", Counter mod 4); // Remainder of division by 4 ensures selection of each Job Line Type.
            PurchaseLine.Modify(true)
        until PurchaseLine.Next() = 0;
    end;

    local procedure AcceptAndCarryOutActionMessageForRequisitionWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure SetupDocumentDimPurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        DefaultDimension: Record "Default Dimension";
        DimSetEntry: Record "Dimension Set Entry";
        LibraryDimension: Codeunit "Library - Dimension";
        DimSetID: Integer;
    begin
        FindDefaultDim(DefaultDimension, PurchaseLine."Job No.");
        DimSetID := PurchaseLine."Dimension Set ID";

        FilterDocumentDim(DimSetEntry, DimSetID, DefaultDimension);

        if DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"Same Code" then
            // Setup dimension value code same as Default Dimension.
            if not DimSetEntry.FindFirst() then begin
                DimSetID :=
                  LibraryDimension.CreateDimSet(DimSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end else begin
                DimSetID := LibraryDimension.EditDimSet(DimSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end;

        if DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"Code Mandatory"
        then
            // Setup a dimension.
            if not DimSetEntry.FindFirst() then begin
                DimSetID :=
                  LibraryDimension.CreateDimSet(DimSetID, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end;

        if DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"No Code" then
            // Delete dimension.
            if DimSetEntry.FindFirst() then begin
                DimSetID := LibraryDimension.DeleteDimSet(DimSetID, DefaultDimension."Dimension Code");
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end;
    end;

    local procedure SetupDocumentDimLineError(PurchaseLine: Record "Purchase Line"; var DefaultDimension: Record "Default Dimension")
    var
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        LibraryDimension: Codeunit "Library - Dimension";
        DimSetID: Integer;
    begin
        FindDefaultDim(DefaultDimension, PurchaseLine."Job No.");
        DimSetID := PurchaseLine."Dimension Set ID";

        FilterDocumentDim(DimSetEntry, DimSetID, DefaultDimension);

        if DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"Same Code" then begin
            // Setup dimension value code different from that for Default Dimension to generate error.
            LibraryDimension.FindDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
            DimensionValue.SetFilter(Code, '<>%1', DefaultDimension."Dimension Value Code");
            DimensionValue.FindFirst();
            if not DimSetEntry.FindFirst() then begin
                DimSetID := LibraryDimension.CreateDimSet(DimSetID, DefaultDimension."Dimension Code", DimensionValue.Code);
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end else begin
                DimSetID := LibraryDimension.EditDimSet(DimSetID, DefaultDimension."Dimension Code", DimensionValue.Code);
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end;
        end;

        if DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"Code Mandatory"
        then
            // Setup blank dimension to generate error.
            if DimSetEntry.FindFirst() then begin
                DimSetID := LibraryDimension.DeleteDimSet(DimSetID, DefaultDimension."Dimension Code");
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end;

        if DefaultDimension."Value Posting" = DefaultDimension."Value Posting"::"No Code" then
            // Setup dimension to generate error.
            if not DimSetEntry.FindFirst() then begin
                LibraryDimension.FindDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
                DimensionValue.FindFirst();
                DimSetID := LibraryDimension.CreateDimSet(DimSetID, DefaultDimension."Dimension Code", DimensionValue.Code);
                PurchaseLine.Validate("Dimension Set ID", DimSetID);
                PurchaseLine.Modify(true);
            end;
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure FindDefaultDim(var DefaultDimension: Record "Default Dimension"; JobNo: Code[20])
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Job);
        DefaultDimension.SetRange("No.", JobNo);
        DefaultDimension.FindFirst();
    end;

    local procedure FindFCY(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Currency.SetFilter(Code, '<>%1', GeneralLedgerSetup."LCY Code");
        Currency.SetRange("Amount Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision");
        Currency.Next(LibraryRandom.RandInt(Currency.Count));
        exit(Currency.Code);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FilterDocumentDim(var DimSetEntry: Record "Dimension Set Entry"; DimSetID: Integer; DefaultDimension: Record "Default Dimension")
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimSetEntry.SetRange("Dimension Code", DefaultDimension."Dimension Code");
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DocumentNo: Code[20]; JobNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.FindSet();
    end;

    local procedure FindLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.SetRange("Use As In-Transit", false);
        Location.SetRange("Bin Mandatory", false);
        Location.Next(LibraryRandom.RandInt(Location.Count));
        exit(Location.Code);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; DocType: Enum "Item Ledger Document Type";
                                                                                                                        DocNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Document Type", DocType);
        ItemLedgerEntry.SetRange("Document No.", DocNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindAndPostPurchHeader(ItemNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindFirst();
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true)
    end;

    local procedure FindPurchRcptLineNo(PurchaseReceiptNo: Code[20]): Integer
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Document No.", PurchaseReceiptNo);
        PurchRcptLine.FindFirst();
        exit(PurchRcptLine."Line No.");
    end;

    local procedure GetPurchaseLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;

    local procedure GetAndUpdatePurchaseLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine.Quantity / 2);  // Update Return Qty to Ship for posting Return Order partially.
        PurchaseLine.Modify(true);
    end;

    local procedure AddPurchaseLineWithNegativeQuantity(var PurchaseLineWithNegativeQuantity: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineWithNegativeQuantity,
          PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", -LibraryRandom.RandDecInDecimalRange(1, PurchaseLine.Quantity, 2));

        PurchaseLineWithNegativeQuantity.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost");
        PurchaseLineWithNegativeQuantity.Validate("Job No.", PurchaseLine."Job No.");
        PurchaseLineWithNegativeQuantity.Validate("Job Task No.", PurchaseLine."Job Task No.");
        PurchaseLineWithNegativeQuantity.Validate("Job Line Type", PurchaseLineWithNegativeQuantity."Job Line Type"::Budget);
        PurchaseLineWithNegativeQuantity.Validate("Job Planning Line No.", 0);
        PurchaseLineWithNegativeQuantity.Modify(true);
        PurchaseLine.SetRange(Type);
    end;

    local procedure GetPurchaseLineAndFillJobNo(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; JobNo: Code[20])
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Job No.", JobNo);
        PurchaseLine.Modify(true);
    end;

    local procedure GetBaseUnitOfMeasureCode(ItemNo: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        exit(Item."Base Unit of Measure");
    end;

    local procedure GetILEAmountSign(ItemLedgerEntry: Record "Item Ledger Entry"): Integer
    begin
        if ItemLedgerEntry.Positive then
            exit(1);

        exit(-1);
    end;

    local procedure OpenDemandOverviewPage(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        JobPlanningLines.OpenView();
        JobPlanningLines.FILTER.SetFilter("Job No.", JobNo);
        JobPlanningLines.FILTER.SetFilter("Job Task No.", JobTaskNo);
        JobPlanningLines.DemandOverview.Invoke();
    end;

    local procedure OpenReservationPage(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        JobPlanningLines.OpenView();
        JobPlanningLines.FILTER.SetFilter("Job No.", JobNo);
        JobPlanningLines.FILTER.SetFilter("Job Task No.", JobTaskNo);
        JobPlanningLines.Reserve.Invoke();
    end;

    local procedure OpenReservationPageFromPurchaseOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchLines.Reserve.Invoke();
    end;

    local procedure PostPartialPurchaseOrder(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        UpdatePurchaseLineQuantities(PurchaseHeader);
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Purchase Order as Receive.
    end;

    local procedure PostAppliedPosAdjustment(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        SetupItemJnlBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", PurchaseLine."No.", PurchaseLine.Quantity);
        ItemJournalLine.Validate("Location Code", PurchaseLine."Location Code");
        FindItemLedgEntry(
          ItemLedgEntry, PurchaseLine."No.", ItemLedgEntry."Entry Type"::"Negative Adjmt.",
          ItemLedgEntry."Document Type"::"Purchase Receipt", DocumentNo);
        ItemJournalLine.Validate("Applies-from Entry", ItemLedgEntry."Entry No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        exit(ItemJournalLine."Document No.");
    end;

    local procedure PostPositiveAdjustment(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SetupItemJnlBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetupItemJnlBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure PurchaseOrderWithJobTask(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        Vendor: Record Vendor;
    begin
        // Used Random value for Direct Unit Cost and Quantity.
        LibraryPurchase.CreateVendor(Vendor);
        CreateJobWithJobTask(JobTask);
        CreatePurchaseHeader(PurchaseHeader."Document Type"::Order, Vendor."No.", PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        AttachJobToPurchaseDocument(JobTask, PurchaseHeader, 0);
    end;

    local procedure InvokeCopyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocNo: Code[20])
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters("Purchase Document Type From"::"Posted Invoice", DocNo, false, true);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
    end;

    local procedure CopyPostedPurchaseReceiptLines(var PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        CopyDocMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocMgt.CopyPurchRcptLinesToDoc(PurchaseHeader, PurchRcptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure MockUpILE(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        EntryNo: Integer;
    begin
        ItemLedgEntry.FindLast();
        EntryNo := ItemLedgEntry."Entry No.";
        Clear(ItemLedgEntry);
        ItemLedgEntry."Entry No." := EntryNo + 1;
        ItemLedgEntry."Source Type" := ItemLedgEntry."Source Type"::Vendor;
        ItemLedgEntry."Source No." := LibraryUtility.GenerateGUID();
        ItemLedgEntry."Country/Region Code" := LibraryUtility.GenerateGUID();
        ItemLedgEntry.Insert();
    end;

    local procedure MockUpVE(ItemLedgEntryNo: Integer; var ValueEntry: Record "Value Entry")
    var
        EntryNo: Integer;
    begin
        ValueEntry.FindLast();
        EntryNo := ValueEntry."Entry No.";
        Clear(ValueEntry);
        ValueEntry."Entry No." := EntryNo + 1;
        ValueEntry."Item Ledger Entry No." := ItemLedgEntryNo;
        ValueEntry."Source Posting Group" := LibraryUtility.GenerateGUID();
        ValueEntry."Salespers./Purch. Code" := LibraryUtility.GenerateGUID();
        ValueEntry.Insert();
    end;

    local procedure MockRoundingValueEntry(var ValueEntry: Record "Value Entry"; JobTask: Record "Job Task"; DocNo: Code[20])
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.";
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::Rounding;
        ValueEntry."Item No." := CreateItem();
        ValueEntry."Document No." := DocNo;
        ValueEntry."Job No." := JobTask."Job No.";
        ValueEntry."Job Task No." := JobTask."Job Task No.";
        ValueEntry."Invoiced Quantity" := -LibraryRandom.RandInt(10);
        ValueEntry."Cost Amount (Actual)" := -LibraryRandom.RandDec(100, 2);
        ValueEntry.Insert();
    end;

    local procedure UpdateAdjustmentAccounts(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; InventoryAdjmtAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjmtAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateAutomaticCostPosting(AutomaticCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateCurrencyOnJob(No: Code[20]; CurrencyCode: Code[10])
    var
        Job: Record Job;
    begin
        Job.Get(No);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);
    end;

    local procedure UpdateItemUnitOfMeasure(PurchaseLine: Record "Purchase Line"; QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.Get(PurchaseLine."No.", PurchaseLine."Unit of Measure Code");
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        ItemUnitOfMeasure.Modify(true);
    end;

    local procedure UpdateJobPlanningLineQuantity(var JobPlanningLine: Record "Job Planning Line"; Quantity: Decimal)
    begin
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure UpdateJobStatus(var Job: Record Job; No: Code[20])
    begin
        Job.Get(No);
        Job.Validate(Status, Job.Status::Planning);
        Job.Modify(true);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        ItemUnitOfMeasure.SetRange("Item No.", PurchaseLine."No.");
        ItemUnitOfMeasure.SetFilter(Code, '<>%1', PurchaseLine."Unit of Measure Code");
        ItemUnitOfMeasure.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random because value is not important.
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePlanningDateOnJobPlanninglLine(JobPlanningLine: Record "Job Planning Line"; PlanningDate: Date)
    begin
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineQuantities(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Update Partial Quantities to Receive and Invoice on Purchase Line.
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        repeat
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
            PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Invoice");
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdatePurchasePrepaymentAccount(PurchaseLine: Record "Purchase Line"; PurchPrepaymentsAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateReturnShipmentOnCreditMemo(ReturnShipmentOnCreditMemo: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Return Shipment on Credit Memo", ReturnShipmentOnCreditMemo);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No." + '_1');  // Need to update Invoice No. due to Posting of Prepayment Invoice.
        PurchaseHeader.Modify(true);
    end;

    local procedure UndoPurchRcpt(var PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchRcptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchLine."Line No.");
        UndoPurchRcptLine.SetHideDialog(true);
        UndoPurchRcptLine.Run(PurchRcptLine);
    end;

    local procedure UndoPurchRcptLine(PurchaseReceiptNo: Code[20]; LineNo: Integer)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        UndoPurchaseReceiptLine: Codeunit "Undo Purchase Receipt Line";
    begin
        PurchRcptLine.Get(PurchaseReceiptNo, LineNo);
        PurchRcptLine.SetRecFilter();
        UndoPurchaseReceiptLine.SetHideDialog(true);
        UndoPurchaseReceiptLine.Run(PurchRcptLine);
    end;

    local procedure UndoPurchReturn(ItemNo: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
        UndoReturnShptLine: Codeunit "Undo Return Shipment Line";
    begin
        ReturnShipmentLine.SetRange(Type, ReturnShipmentLine.Type::Item);
        ReturnShipmentLine.SetRange("No.", ItemNo);
        UndoReturnShptLine.SetHideDialog(true);
        UndoReturnShptLine.Run(ReturnShipmentLine);
    end;

    local procedure UpdatePurchLineQtyToReceive(PurchaseHeader: Record "Purchase Header"; QtyToReceive: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchLineQtyToInvoice(PurchaseHeader: Record "Purchase Header"; QtyToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchLineWithQtyToReceiveAndInvoice(var JobPlanningLine: Record "Job Planning Line"; var PurchaseHeader: Record "Purchase Header"; Quantity: Decimal; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    begin
        PreparePurchHeaderAndJobPlanningLine(PurchaseHeader, JobPlanningLine, Quantity, QtyToReceive);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        UpdateVendorInvoiceNoOnPurchaseHeader(PurchaseHeader);
        UpdatePurchLineQtyToReceive(PurchaseHeader, QtyToReceive);
        UpdatePurchLineQtyToInvoice(PurchaseHeader, QtyToInvoice);
    end;

    local procedure EnqueueVariables(ItemNumber: Code[20]; QuantityOnJobPlanningLine: Decimal; OriginalQuantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemNumber);
        LibraryVariableStorage.Enqueue(QuantityOnJobPlanningLine);
        LibraryVariableStorage.Enqueue(OriginalQuantity);
    end;

    local procedure VerifyJobInfoOnPurchInvoice(OrderPurchaseHeader: Record "Purchase Header"; InvoicePurchaseHeader: Record "Purchase Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchRcptLine.SetRange("Order No.", OrderPurchaseHeader."No.");
        PurchRcptLine.FindSet();
        Assert.AreNotEqual(PurchRcptLine."Job No.", '', 'No job info on receipt line');
        GetPurchaseLines(InvoicePurchaseHeader, PurchaseLine);
        Assert.AreEqual(PurchRcptLine.Count, PurchaseLine.Count, '# purchase invoice lines');
        repeat
            PurchaseLine.TestField("Job No.", PurchRcptLine."Job No.");
            PurchaseLine.TestField("Job Task No.", PurchRcptLine."Job Task No.");
            PurchaseLine.TestField("Job Line Type", PurchRcptLine."Job Line Type");
            PurchaseLine.TestField("Job Unit Price (LCY)", PurchRcptLine."Job Unit Price (LCY)");
            PurchaseLine.TestField("Job Line Amount (LCY)", PurchRcptLine."Job Line Amount (LCY)");
            PurchaseLine.TestField("Job Line Disc. Amount (LCY)", PurchRcptLine."Job Line Disc. Amount (LCY)");
            PurchaseLine.Next();
        until PurchRcptLine.Next() = 0;
    end;

    local procedure VerifyJobLedgerEntryDim(DocNo: Code[20]; DimSetID: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Verify job ledger entry dimension ID is same as purchase invoice line.
        PurchInvHeader.SetRange("Order No.", DocNo);
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindSet();
        repeat
            JobLedgerEntry.SetRange("Document No.", PurchInvLine."Document No.");
            JobLedgerEntry.SetRange("No.", PurchInvLine."No.");
            JobLedgerEntry.FindFirst();
            Assert.AreEqual(JobLedgerEntry."Dimension Set ID", PurchInvLine."Dimension Set ID",
              StrSubstNo(WrongDimJobLedgerEntryErr, JobLedgerEntry."Entry No.", DimSetID, JobLedgerEntry."Dimension Set ID"));
        until PurchInvLine.Next() = 0;
    end;

    local procedure VerifyTotalCostAndPriceOnJobLedgerEntry(ItemNo: Code[20]; DirectUnitCost: Decimal; DirectUnitCostLCY: Decimal; UnitPrice: Decimal; UnitPriceLCY: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("No.", ItemNo);
        JobLedgerEntry.FindSet();
        repeat
            Assert.AreNearlyEqual(
              DirectUnitCost, JobLedgerEntry."Total Cost", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Cost"), DirectUnitCost));
            Assert.AreNearlyEqual(
              UnitPriceLCY, JobLedgerEntry."Total Price (LCY)", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Price (LCY)"), UnitPriceLCY));
            Assert.AreNearlyEqual(
              DirectUnitCostLCY, JobLedgerEntry."Total Cost (LCY)", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Cost (LCY)"), DirectUnitCostLCY));
            Assert.AreNearlyEqual(
              UnitPrice, JobLedgerEntry."Total Price", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Price"), UnitPrice));
            Assert.AreNearlyEqual(
              UnitPrice, JobLedgerEntry."Line Amount", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Line Amount"), UnitPrice));
            Assert.AreNearlyEqual(
              UnitPriceLCY, JobLedgerEntry."Line Amount (LCY)", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Line Amount (LCY)"), UnitPriceLCY));
        until JobLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDimensionErrorMessage(ExpectedErrorMessage: Text)
    var
        ErrorMessagesPage: TestPage "Error Messages";
    begin
        LibraryErrorMessage.GetTestPage(ErrorMessagesPage);
        Assert.ExpectedMessage(ErrorMessagesPage.Description.Value, ExpectedErrorMessage);
        Assert.ExpectedMessage(ErrorMessagesPage."Additional Information".Value, ExpectedErrorMessage);
    end;

    local procedure VerifyJobInfoOnPurchRcptLines(var PurchaseLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        repeat
            PurchRcptLine.SetRange("Line No.", PurchaseLine."Line No.");
            PurchRcptLine.FindFirst();
            PurchRcptLine.TestField("Job No.", PurchaseLine."Job No.");
            PurchRcptLine.TestField("Job Task No.", PurchaseLine."Job Task No.");
            PurchRcptLine.TestField("Job Line Type", PurchaseLine."Job Line Type");
            PurchRcptLine.TestField("Job Unit Price", PurchaseLine."Job Unit Price");
            PurchRcptLine.TestField("Job Total Price", PurchaseLine."Job Total Price");
            PurchRcptLine.TestField("Job Line Amount", PurchaseLine."Job Line Amount");
            PurchRcptLine.TestField("Job Line Discount Amount", PurchaseLine."Job Line Discount Amount");
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyModifyPurchaseDocJobInfo(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // prevent roll back
        Commit();
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        repeat
            asserterror PurchaseLine.Validate("Job No.", '');
            asserterror PurchaseLine.Validate("Job Task No.", '');
            asserterror PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type".AsInteger() + 1);  // Add 1 to change option type.
            asserterror PurchaseLine.Validate("Job Unit Price", LibraryRandom.RandInt(100));
            asserterror PurchaseLine.Validate("Job Line Amount", LibraryRandom.RandInt(100));
            asserterror PurchaseLine.Validate("Job Line Discount Amount", LibraryRandom.RandInt(100));
            asserterror PurchaseLine.Validate("Job Line Discount %", LibraryRandom.RandInt(100));
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyJobInfo(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
    begin
        repeat
            if PurchaseLine.Type = PurchaseLine.Type::Item then begin
                Item.Get(PurchaseLine."No.");
                Assert.AreNearlyEqual(
                  PurchaseLine."Unit Price (LCY)", PurchaseLine."Job Unit Price (LCY)", 0.001,
                  'Job unit Price LCY and unitr price LCY match on the Purchase Line');
            end else begin
                PurchaseLine.TestField("Job Unit Price (LCY)", 0);
                PurchaseLine.TestField("Job Line Discount Amount", 0);
            end;
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyItemApplicationEntry(PurchaseLine: Record "Purchase Line")
    var
        InboundItemLedgerEntry: Record "Item Ledger Entry";
        OutboundItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        InboundItemLedgerEntry.SetRange("Job No.", PurchaseLine."Job No.");
        InboundItemLedgerEntry.SetRange(Positive, true);
        InboundItemLedgerEntry.FindFirst();

        OutboundItemLedgerEntry.SetRange("Job No.", PurchaseLine."Job No.");
        OutboundItemLedgerEntry.SetRange(Positive, false);
        OutboundItemLedgerEntry.FindFirst();

        ItemApplicationEntry.SetRange("Item Ledger Entry No.", OutboundItemLedgerEntry."Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", InboundItemLedgerEntry."Entry No.");
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", OutboundItemLedgerEntry."Entry No.");
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField(Quantity, -InboundItemLedgerEntry.Quantity);
    end;

    local procedure VerifyItemLedger(var PurchaseLine: Record "Purchase Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExpectedCount: Integer;
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindSet();
        repeat
            ItemLedgerEntry.SetRange(Description, PurchaseLine.Description);
            if PurchaseLine."Job No." = '' then
                ExpectedCount := 1
            else
                ExpectedCount := 2;
            Assert.AreEqual(ExpectedCount, ItemLedgerEntry.Count, '# item ledger entries');
            ItemLedgerEntry.FindSet();
            repeat
                ItemLedgerEntry.TestField("Job No.", PurchaseLine."Job No.");
                ItemLedgerEntry.TestField("Job Task No.", PurchaseLine."Job Task No.")
            until ItemLedgerEntry.Next() = 0
        until PurchaseLine.Next() = 0;

        // Clear filter applied on temporary table.
        PurchaseLine.SetRange(Type);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20];
                                                         DocumentType: Enum "Item Ledger Document Type";
                                                         DocumentNo: Code[20];
                                                         JobNo: Code[20];
                                                         Quantity: Decimal;
                                                         InvoicedQuantity: Decimal;
                                                         CostAmountActual: Decimal;
                                                         CostAmountExpected: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgEntry(ItemLedgerEntry, ItemNo, EntryType, DocumentType, DocumentNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        ItemLedgerEntry.TestField("Job No.", JobNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        ItemLedgerEntry."Cost Amount (Actual)" := Round(ItemLedgerEntry."Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
        ItemLedgerEntry.TestField("Cost Amount (Expected)", CostAmountExpected);
    end;

    local procedure VerifyItemLedgerEntryUnitOfMeasure(Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Unit of Measure Code", Item."Base Unit of Measure");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemLedgEntriesInvoiced(ItemNo: Code[20]; ExpectedActualCost: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
            ItemLedgerEntry.TestField("Completely Invoiced", true);
            ItemLedgerEntry.TestField("Invoiced Quantity", ItemLedgerEntry.Quantity);
            ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
            ItemLedgerEntry.TestField("Cost Amount (Actual)", ExpectedActualCost * GetILEAmountSign(ItemLedgerEntry));
            VerifyValueEntry(ItemLedgerEntry."Entry Type", ItemLedgerEntry."Document Type", ItemNo, ItemLedgerEntry."Document No.", ItemLedgerEntry."Job No.", ItemLedgerEntry."Cost Amount (Actual)", 0);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyPurcCrMemoItemLedgerEntry(PurchLine: Record "Purchase Line"; DocNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgEntry(
          ItemLedgerEntry, PurchLine."No.", ItemLedgerEntry."Entry Type"::Purchase,
          ItemLedgerEntry."Document Type"::"Purchase Credit Memo", DocNo);
        Assert.AreEqual(PurchLine."Job No.", ItemLedgerEntry."Job No.", ItemLedgerEntry.FieldCaption("Job No."));
        Assert.AreEqual(-PurchLine.Quantity, ItemLedgerEntry.Quantity, ItemLedgerEntry.FieldCaption(Quantity));
    end;

    local procedure VerifyGLEntry(var PurchaseLine: Record "Purchase Line")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // assign the document no. to find the job ledger entries.
        case PurchaseLine."Document Type" of
            PurchaseLine."Document Type"::Order:
                PurchInvHeader.SetRange("Order No.", PurchaseLine."Document No.");
            PurchaseLine."Document Type"::Invoice:
                PurchInvHeader.SetRange("Pre-Assigned No.", PurchaseLine."Document No.");
            else
                Assert.Fail(StrSubstNo('Unsupported document type %1', PurchaseLine."Document Type"));
        end;
        Assert.AreEqual(1, PurchInvHeader.Count, '# purchase invoices');
        PurchInvHeader.FindFirst();

        PurchaseLine.SetFilter("Job No.", '<>''''');

        JobLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        Assert.AreEqual(PurchaseLine.Count, JobLedgerEntry.Count, 'Number of job ledger entries and purchase lines should be equal.');

        LibraryJob.VerifyGLEntries(JobLedgerEntry);
    end;

    local procedure VerifyPurchaseLine(PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.CalcFields("Reserved Quantity");
        PurchaseLine.TestField("Reserved Quantity", Quantity);
    end;

    local procedure VerifyValueEntries(var PurchaseLine: Record "Purchase Line")
    var
        ValueEntry: Record "Value Entry";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindSet();
        repeat
            ValueEntry.SetRange(Description, PurchaseLine.Description);
            Assert.IsFalse(ValueEntry.IsEmpty, 'value entries not found');
            ValueEntry.FindSet();
            repeat
                ValueEntry.TestField("Job No.", PurchaseLine."Job No.");
                ValueEntry.TestField("Job Task No.", PurchaseLine."Job Task No.")
            until ValueEntry.Next() = 0
        until PurchaseLine.Next() = 0;

        // Clear filter applied on temporary table.
        PurchaseLine.SetRange(Type);
    end;

    local procedure VerifyValueEntry(ItemLedgerEntryType: Enum "Item Ledger Entry Type"; DocumentType: Enum "Item Ledger Document Type";
                                                              ItemNo: Code[20];
                                                              DocumentNo: Code[20];
                                                              JobNo: Code[20];
                                                              CostAmountExpected: Decimal;
                                                              CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();

        ValueEntry.TestField("Job No.", JobNo);
        ValueEntry.TestField("Cost Amount (Expected)", CostAmountExpected);
        ValueEntry."Cost Amount (Actual)" := Round(ValueEntry."Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyValueEntryReversedAmount(DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
        Assert.AreEqual(0, ValueEntry."Cost Amount (Expected)", StrSubstNo(WrongTotalCostAmtErr, DocumentNo));
        Assert.AreEqual(0, ValueEntry."Cost Amount (Actual)", StrSubstNo(WrongTotalCostAmtErr, DocumentNo));
    end;

    local procedure VerifyGLEntryAmountInclVAT(var GLEntry: Record "G/L Entry"; Amount: Decimal)
    var
        TotalGLAmount: Decimal;
    begin
        GLEntry.FindSet();
        repeat
            TotalGLAmount += GLEntry.Amount + GLEntry."VAT Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(Amount, TotalGLAmount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyJobOnGLEntry(JobNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, DocumentType);
        GLEntry.TestField("Job No.", JobNo);
    end;

    local procedure VerifyJobLedgerEntry(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, PurchaseLine."Job No.");
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField(Quantity, Quantity);
        JobLedgerEntry.TestField("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
        JobLedgerEntry.TestField("Qty. per Unit of Measure", PurchaseLine."Qty. per Unit of Measure");
        JobLedgerEntry.TestField("Direct Unit Cost (LCY)", PurchaseLine."Direct Unit Cost");
    end;

    local procedure VerifyLastJobLedgerEntryLine(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; ExpectedQuantitiy: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", PurchaseLine."Job No.");
        JobLedgerEntry.FindLast();
        JobLedgerEntry.TestField("No.", PurchaseLine."No.");
        JobLedgerEntry.TestField(Quantity, ExpectedQuantitiy);
        JobLedgerEntry.TestField("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
        JobLedgerEntry.TestField("Qty. per Unit of Measure", PurchaseLine."Qty. per Unit of Measure");
        JobLedgerEntry.TestField("Direct Unit Cost (LCY)", PurchaseLine."Direct Unit Cost");
    end;

    local procedure VerifyDocumentDateOnJobLedgerEntry(JobNo: Code[20]; DocumentNo: Code[20]; DocumentDate: Date)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        JobLedgerEntry.TestField("Document Date", DocumentDate);
    end;

    local procedure VerifyJobNoInGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; GLAccountNo: Code[20];
                                                                                 JobNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        FindGLEntry(GLEntry, DocumentNo, DocumentType);
        GLEntry.TestField("Job No.", JobNo);
    end;

    local procedure VerifyJobLedgerEntryValue(DocumentNo: Code[20]; JobNo: Code[20]; TotalCostLCY: Decimal; UnitCostLCY: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        JobLedgerEntry.TestField("Total Cost (LCY)", TotalCostLCY);
        JobLedgerEntry.TestField("Unit Cost (LCY)", UnitCostLCY);
    end;

    local procedure VerifyGLEntryValue(DocumentNo: Code[20]; Amount: Decimal; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyUndoLedgerEntrySource(DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20];
                                                                  DocumentLineNo: Integer;
                                                                  EntryType: Enum "Item Ledger Entry Type";
                                                                  SourceNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Document Line No.", DocumentLineNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindLast();
        Assert.AreEqual(
          SourceNo, ItemLedgerEntry."Source No.",
          StrSubstNo(EmptyValueErr, ItemLedgerEntry.FieldCaption("Source No."), ItemLedgerEntry.TableCaption));

        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Line No.", DocumentLineNo);
        ValueEntry.SetRange("Item Ledger Entry Type", EntryType);
        ValueEntry.FindLast();
        Assert.AreEqual(
          SourceNo, ValueEntry."Source No.",
          StrSubstNo(EmptyValueErr, ValueEntry.FieldCaption("Source No."), ValueEntry.TableCaption));
    end;

    local procedure VerifyTransferredSource(ItemJnlLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry")
    begin
        Assert.AreEqual(
          ItemLedgEntry."Source Type", ItemJnlLine."Source Type",
          StrSubstNo(ValueMustMatchErr, ItemJnlLine.FieldCaption("Source Type"), ItemLedgEntry."Source Type"));
        Assert.AreEqual(
          ItemLedgEntry."Source No.", ItemJnlLine."Source No.",
          StrSubstNo(ValueMustMatchErr, ItemJnlLine.FieldCaption("Source No."), ItemLedgEntry."Source No."));
        Assert.AreEqual(
          ItemLedgEntry."Country/Region Code", ItemJnlLine."Country/Region Code",
          StrSubstNo(ValueMustMatchErr, ItemJnlLine.FieldCaption("Country/Region Code"), ItemLedgEntry."Country/Region Code"));
        Assert.AreEqual(
          ValueEntry."Source Posting Group", ItemJnlLine."Source Posting Group",
          StrSubstNo(ValueMustMatchErr, ItemJnlLine.FieldCaption("Source Posting Group"), ValueEntry."Source Posting Group"));
        Assert.AreEqual(
          ValueEntry."Salespers./Purch. Code", ItemJnlLine."Salespers./Purch. Code",
          StrSubstNo(ValueMustMatchErr, ItemJnlLine.FieldCaption("Salespers./Purch. Code"), ValueEntry."Salespers./Purch. Code"));
    end;

    local procedure VerifyQuantityOnJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; Quantity: Decimal)
    begin
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyJobLedgerEntryTotalCostValues(DocumentNo: Code[20]; JobNo: Code[20]; TotalCost: Decimal; TotalCostLCY: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        Assert.AreEqual(
          TotalCost, JobLedgerEntry."Total Cost",
          StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Cost"), TotalCost));
        Assert.AreEqual(
          TotalCostLCY, JobLedgerEntry."Total Cost (LCY)",
          StrSubstNo(ValueMustMatchErr, JobLedgerEntry.FieldCaption("Total Cost (LCY)"), TotalCostLCY));
    end;

    local procedure VerifyJobTotalPricesOnPurchRcptLines(PurchLine: Record "Purchase Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        AmountRoundingPrecision: Decimal;
    begin
        PurchRcptLine.SetRange("Order No.", PurchLine."Document No.");
        PurchRcptLine.CalcSums(
          "Job Line Amount", "Job Line Amount (LCY)", "Job Total Price", "Job Total Price (LCY)");
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Assert.AreNearlyEqual(
          PurchRcptLine."Job Line Amount", PurchLine."Job Line Amount", AmountRoundingPrecision, PurchRcptLine.FieldCaption("Job Line Amount"));
        Assert.AreNearlyEqual(
          PurchRcptLine."Job Line Amount (LCY)", PurchLine."Job Line Amount (LCY)", AmountRoundingPrecision, PurchRcptLine.FieldCaption("Job Line Amount (LCY)"));
        Assert.AreNearlyEqual(
          PurchRcptLine."Job Total Price", PurchLine."Job Total Price", AmountRoundingPrecision, PurchRcptLine.FieldCaption("Job Total Price"));
        Assert.AreNearlyEqual(
          PurchRcptLine."Job Total Price (LCY)", PurchLine."Job Total Price (LCY)", AmountRoundingPrecision, PurchRcptLine.FieldCaption("Job Total Price (LCY)"));
    end;

    local procedure VerifyJobPlanningTrackingReservationEntry(JobNo: Code[20]; ItemNo: Code[20]; TrackedQty: Decimal)
    var
        Job: Record Job;
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Job Planning Line");
        ReservationEntry.SetRange("Source Subtype", Job.Status::Open);
        ReservationEntry.SetRange("Source ID", JobNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, TrackedQty);
    end;

    local procedure VerifyJobLedgerEntriesWithGL(DocumentNo: Code[20]; JobNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::"G/L Account");
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        FindGLEntry(GLEntry, DocumentNo, DocumentType);
        GLEntry.FindSet();
        repeat
            JobLedgerEntry.SetRange("Ledger Entry Type", JobLedgerEntry."Ledger Entry Type"::"G/L Account");
            JobLedgerEntry.SetRange("Ledger Entry No.", GLEntry."Entry No.");
            JobLedgerEntry.FindFirst();
            JobLedgerEntry.CalcSums("Line Amount (LCY)");
            JobLedgerEntry.TestField("Line Amount (LCY)", GLEntry.Amount);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyJobLedgerEntriesWithItemLedger(DocumentNo: Code[20]; JobNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, DocumentNo, JobNo);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.FindSet();
        repeat
            JobLedgerEntry.TestField("Ledger Entry Type", JobLedgerEntry."Ledger Entry Type"::Item);
            ItemLedgerEntry.Get(JobLedgerEntry."Ledger Entry No.");
            ItemLedgerEntry.TestField("Item No.", JobLedgerEntry."No.");
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            // JobLedgerEntry is always linked to ItemLedgerEntry with 1-to-1 relation.
            ItemLedgerEntry."Cost Amount (Actual)" := Round(ItemLedgerEntry."Cost Amount (Actual)");
            ItemLedgerEntry.TestField("Cost Amount (Actual)", -JobLedgerEntry."Line Amount (LCY)");
        until JobLedgerEntry.Next() = 0;
    end;

    local procedure VerifyTwoJobLedgerEntriesLinkedToDiffGLEntriesByDims(JobTask: Record "Job Task"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordCount(GLEntry, 2);

        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.RecordCount(JobLedgerEntry, 2);

        JobLedgerEntry.FindFirst();
        GLEntry.FindFirst();
        JobLedgerEntry.TestField("Ledger Entry No.", GLEntry."Entry No.");
        JobLedgerEntry.TestField("Dimension Set ID", GLEntry."Dimension Set ID");

        JobLedgerEntry.Next();
        GLEntry.Next();
        JobLedgerEntry.TestField("Ledger Entry No.", GLEntry."Entry No.");
        JobLedgerEntry.TestField("Dimension Set ID", GLEntry."Dimension Set ID");
    end;

    local procedure UpdatePurchaseLineDirectUnitCost(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        GetPurchaseLines(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateJobAndJobPlanningLineWithGLAccount(
        var JobPlanningLine: Record "Job Planning Line";
        var JobTask: Record "Job Task";
        GLAccountNo: Code[20];
        Quantity: Decimal)
    begin
        CreateJobWithJobTask(JobTask);
        CreateJobPlanningLine(
            JobPlanningLine,
            JobTask,
            JobPlanningLine.Type::"G/L Account",
            GLAccountNo,
            Quantity,
            true);
    end;

    local procedure CreatePurchaseDocumentWithGLAccountLinkToJobPlanningLine(
        var PurchaseLine: Record "Purchase Line";
        JobPlanningLine: Record "Job Planning Line";
        DocumentType: Enum "Purchase Document Type";
        No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');

        // Create Purchase Line with Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"G/L Account",
            No,
            LibraryRandom.RandInt(10));

        // Update Job Planning Line Details to Purchase Line
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    begin
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoQuantityOnReservePageHandler(var Reservation: TestPage Reservation)
    begin
        // Verify that no Quantity available when there is no source available to Reserve from.
        Reservation."Total Quantity".AssertEquals(0);
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.ItemNo.AssertEquals(LibraryVariableStorage.DequeueText());
        Reservation.QtyToReserveBase.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation."Total Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    var
        QuantityOnJobPlanningLine: Variant;
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.ItemNo.AssertEquals(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Dequeue(QuantityOnJobPlanningLine);
        Reservation.QtyToReserveBase.AssertEquals(QuantityOnJobPlanningLine);
        Reservation.QtyReservedBase.AssertEquals(QuantityOnJobPlanningLine);
        Reservation."Total Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation."Current Reserved Quantity".AssertEquals(QuantityOnJobPlanningLine);
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DemandOverviewPageHandler(var DemandOverview: TestPage "Demand Overview")
    begin
        DemandOverview.FILTER.SetFilter("Item No.", LibraryVariableStorage.DequeueText());
        DemandOverview.FILTER.SetFilter(Type, DemandOverview.Type.GetOption(4));  // Use 4 as the Index for Supply.
        DemandOverview.FILTER.SetFilter(Type, DemandOverview.Type.GetOption(6));  // Use 6 as the Index for Demand.
        DemandOverview.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    var
        CancelReservation: Boolean;
        QuantityOnJobPlanningLine: Decimal;
        OriginalQuantity: Decimal;
    begin
        CancelReservation := LibraryVariableStorage.DequeueBoolean();
        if CancelReservation then begin
            // 2. Exercise.
            Reservation.CancelReservationCurrentLine.Invoke();

            // 3. Verify: Verify Reservation page for Item No.,Quantity Reserved and Current Reserved Quantity.
            Reservation.ItemNo.AssertEquals(LibraryVariableStorage.DequeueText());
            Reservation.QtyReservedBase.AssertEquals(0);
            Reservation."Current Reserved Quantity".AssertEquals(0);
        end else begin
            // 2. Exercise.
            Reservation."Reserve from Current Line".Invoke();

            // 3. Verify: Verify Reservation page.
            Reservation.ItemNo.AssertEquals(LibraryVariableStorage.DequeueText());
            QuantityOnJobPlanningLine := LibraryVariableStorage.DequeueDecimal();
            OriginalQuantity := LibraryVariableStorage.DequeueDecimal();
            Reservation.QtyToReserveBase.AssertEquals(OriginalQuantity);
            Reservation.QtyReservedBase.AssertEquals(QuantityOnJobPlanningLine);
            Reservation."Total Quantity".AssertEquals(QuantityOnJobPlanningLine);
            Reservation."Current Reserved Quantity".AssertEquals(-QuantityOnJobPlanningLine);
        end;
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler2(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());

        ItemTrackingLines.Next();
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutAwayRequestPageHandler(var CreateInvtPutawayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmt.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPickMvmt.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderReserveFromCurrentLineHandler2(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    local procedure UndoPurchReciptAndAdjustCostItemEntries(var PurchaseLine: Record "Purchase Line"; var Item: Record Item)
    begin
        UndoPurchRcpt(PurchaseLine);

        // [WHEN] Run cost adjustment for item "I"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
    end;

    local procedure GetValueEntry(DocumentNo: Code[20]; var ValueEntry: Record "Value Entry")
    var
        ItemLedgerDocumentType: Enum "Item Ledger Document Type";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Document Type", ItemLedgerDocumentType::"Purchase Invoice");
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Customer);
        ValueEntry.FindFirst();
    end;

    local procedure CreateDefaultWarehouseEmployee(var NewDefaultLocation: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange(Default, true);
        if WarehouseEmployee.FindFirst() then begin
            if WarehouseEmployee."Location Code" <> NewDefaultLocation.Code then begin
                WarehouseEmployee.Delete(true);
                LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
            end;
        end else
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.SetLoadFields("No.");
        WarehouseReceiptLine.FindFirst();

        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindPurchaseReceiptNo(PurchaseLine: Record "Purchase Line"): Code[20]
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.SetLoadFields("Document No.");
        PurchRcptLine.FindLast();
        exit(PurchRcptLine."Document No.");
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure CreatePutAwayFromPostedWhseRcpt(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        WhseSourceCreateDocument.SetPostedWhseReceiptLine(PostedWhseReceiptLine, '');
        WhseSourceCreateDocument.SetHideValidationDialog(true);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.RunModal();

        LibraryWarehouse.FindWhseActivityLineBySourceDoc(
          WarehouseActivityLine, PostedWhseReceiptLine."Source Type", PostedWhseReceiptLine."Source Subtype",
          PostedWhseReceiptLine."Source No.", PostedWhseReceiptLine."Source Line No.");
    end;

    local procedure FindPostedWhseReceiptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; PurchaseLine: Record "Purchase Line")
    begin
        PostedWhseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        PostedWhseReceiptLine.SetRange("Source Subtype", PurchaseLine."Document Type");
        PostedWhseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
        PostedWhseReceiptLine.SetRange("Source Line No.", PurchaseLine."Line No.");
        PostedWhseReceiptLine.FindFirst();
    end;

    local procedure VerifyItemLedgerEntry(Item: Record Item; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Reserved Quantity");
        if Item.IsInventoriableType() then
            Assert.AreEqual(ItemLedgerEntry."Reserved Quantity", Quantity,
                StrSubstNo(ValueMustMatchErr, ItemLedgerEntry."Reserved Quantity", Quantity))
        else
            Assert.AreEqual(ItemLedgerEntry."Reserved Quantity", Quantity,
                StrSubstNo(ValueMustMatchErr, ItemLedgerEntry."Reserved Quantity", Quantity))
    end;
}
