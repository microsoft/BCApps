codeunit 136306 "Job Invoicing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job]
        Initialized := false
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        NoSeries: Record "No. Series";
        ReportLayoutSelection: Record "Report Layout Selection";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NoLinesErr: Label 'Qty. to Transfer to Invoice cannot be set on a Project Planning Line of type Budget.';
        QtyErr: Label 'Qty. to Transfer to Invoice may not be lower than';
        UnexpectedErrorMsg: Label 'Unexpected error.';
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryCosting: Codeunit "Library - Costing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Initialized: Boolean;
        JobLedgerEntryFieldErr: Label 'Field %1 in Project Ledger Entry has invalid value';
        WrongDimSetIDInSalesLineErr: Label 'Wrong dimension set ID in sales line of document %1.';
        WrongItemInfoErr: Label 'Wrong item info: %1 in posted Sales Invoice Line.';
        WrongDimValueCodeErr: Label 'Wrong dimension value code in Sales Line.';
        WrongJobJnlDimensionsErr: Label 'Wrong %1 in General Journal Line.';
        WrongJobLedgerEntryQtyErr: Label 'Wrong Quantity in General Ledger Entry.';
        WrongSalesInvoiceDimensionsErr: Label 'Dimensions must be equal.';
        UnitPriceMustNotBeZeroErr: Label 'Field Unit Price of Project Journal Line must not be zero.';
        WrongDescriptionInPostedSalesInvoiceErr: Label 'Wrong Description in Sales Invoice Line.';
        TrackingOption: Option "Assign Lot No.","Assign Serial No.";
        CancelPostedInvoiceQst: Label 'This invoice was posted from a sales order. To cancel it, a sales credit memo will be created and posted. The quantities from the original sales order will be restored, provided the sales order still exists.\ \Do you want to continue?';
        CorrectPostedInvoiceQst: Label 'The posted sales invoice will be canceled, and a new version of the sales invoice will automatically be created by the system so that you can make the correction.\ \Do you want to continue?';
        JobMustNotBeBlockedErr: Label 'Project %1 must not be blocked', Comment = '%1 - Project No.';
        ExtDocNoErr: Label 'The actual %1 External Document No. and the expected %2 External Document No. are not equal', Comment = '%1 = Project, %2 = Sales Header';
        YourReferenceErr: Label 'The actual %1 Your Reference and the expected %2 Your Reference are not equal', Comment = '%1 = Project, %2 = Sales Header';
        DetailLevel: Option All,"Per Job","Per Job Task","Per Job Planning Line";
        LineDiscountPctErr: Label '%1 should be %2', Comment = '%1 = Field Caption, %2 = Field Value';
        WrongNoOfLinesLbl: Label 'Wrong number of lines created.';
        ValueFalseErr: Label 'Value must be equal to false';

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferItemLine()
    begin
        // Transfer a billable item line to a sales invoice
        TransferJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferResourceLine()
    begin
        // Transfer a billable resource line to a sales invoice
        TransferJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeContract(), 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferGLLine()
    begin
        // Transfer a billable GL line to a sales invoice
        TransferJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeContract(), 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferItemLineBoth()
    begin
        // Transfer a both schedule and contract item line to a sales invoice
        TransferJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferResourceLineBoth()
    begin
        // Transfer a both schedule and billable resource line to a sales invoice
        TransferJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferGLLineBoth()
    begin
        // Transfer a both schedule and billable GL line to a sales invoice
        TransferJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferItemLineSchedule()
    begin
        // Transfer a schedule item line to a sales invoice (ERROR)
        asserterror TransferJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeSchedule(), 1);
        Assert.AreEqual(StrSubstNo(NoLinesErr), GetLastErrorText, UnexpectedErrorMsg)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferResourceLineSchedule()
    begin
        // Transfer a schedule resource line to a sales invoice (ERROR)
        asserterror TransferJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeSchedule(), 1);
        Assert.AreEqual(StrSubstNo(NoLinesErr), GetLastErrorText, UnexpectedErrorMsg)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferGLLineSchedule()
    begin
        // Transfer a schedule GL line to a sales invoice (ERROR)
        asserterror TransferJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeSchedule(), 1);
        Assert.AreEqual(StrSubstNo(NoLinesErr), GetLastErrorText, UnexpectedErrorMsg)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PTransferItemLine()
    begin
        // Partially transfer a billable item line to a sales invoice
        TransferJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PTransferResourceLine()
    begin
        // Partially transfer a billable resource line to a sales invoice
        TransferJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PTransferGLLine()
    begin
        // Partially transfer a billable GL line to a sales invoice
        TransferJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ETransferItemLine()
    begin
        // Excess transfer a billable item line to a sales invoice (ERROR)
        asserterror TransferJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100 + 1);
        Assert.AreEqual(StrPos(GetLastErrorText, QtyErr), 1, UnexpectedErrorMsg)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ETransferResourceLine()
    begin
        // Excess transfer a billable resource line to a sales invoice (ERROR)
        asserterror TransferJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100 + 1);
        Assert.AreEqual(StrPos(GetLastErrorText, QtyErr), 1, UnexpectedErrorMsg)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ETransferGLLine()
    begin
        // Excess transfer a billable GL line to a sales invoice (ERROR)
        asserterror TransferJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100 + 1);
        Assert.AreEqual(StrPos(GetLastErrorText, QtyErr), 1, UnexpectedErrorMsg)
    end;

    local procedure TransferJob(ConsumableType: Enum "Job Planning Line Type"; LineType: Enum "Job Planning Line Line Type"; Fraction: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Create job, job task
        // Create job planning line with Type = ConsumableType, Line Type = LineType
        // Transfer Fraction of job planning line to sales invoice
        // Verify Qty. Transferred to Invoice is updated
        // Verify created sales invoice

        // Setup
        Initialize();
        Plan(LineType, ConsumableType, JobPlanningLine);

        // Exercise
        TransferJobPlanningLine(JobPlanningLine, Fraction, false, SalesHeader);

        // Verify
        Assert.AreEqual(Fraction * JobPlanningLine.Quantity, JobPlanningLine."Qty. Transferred to Invoice",
          JobPlanningLine.FieldCaption("Qty. Transferred to Invoice"));
        VerifySalesInvoice(JobPlanningLine, SalesHeader)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Create job, job task
        // Create job planning line with Type = Item, Line Type = Billable
        // Transfer Fraction of job planning line to sales invoice
        // Delete sales invoice
        // Verify "Qty. Transferred to Invoice", "Qty. to Transfer to Invoice"

        // Setup
        Initialize();
        Plan(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobPlanningLine);

        // Exercise
        TransferJobPlanningLine(JobPlanningLine, 1, false, SalesHeader);
        SalesHeader.Delete(true);
        // Verify
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        Assert.AreEqual(0, JobPlanningLine."Qty. Transferred to Invoice", JobPlanningLine.FieldCaption("Qty. Transferred to Invoice"));
        Assert.AreEqual(JobPlanningLine.Quantity, JobPlanningLine."Qty. to Transfer to Invoice", JobPlanningLine.FieldCaption("Qty. to Transfer to Invoice"))
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferMultipleInvoices()
    begin
        // Transfer a billable item line to multiple sales invoices
        TransferJobStaged(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100)
    end;

    local procedure TransferJobStaged(ConsumableType: Enum "Job Planning Line Type"; LineType: Enum "Job Planning Line Line Type"; Fraction: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        SalesHeader: Record "Sales Header";
    begin
        // Create job, job task
        // Create job planning line with Type = ConsumableType, Line Type = LineType
        // Transfer Fraction of job planning line to sales invoice
        // Transfer remainder to another sales invoice
        // Verify everything has been transferred (Qty. Transferred to Invoice = Quantity)
        // Verify 2 invoices have been created

        // Setup
        Initialize();
        Plan(LineType, ConsumableType, JobPlanningLine);

        // Exercise
        TransferJobPlanningLine(JobPlanningLine, Fraction, false, SalesHeader);
        TransferJobPlanningLine(JobPlanningLine, 1 - Fraction, false, SalesHeader);
        // Verify
        Assert.AreEqual(JobPlanningLine."Qty. Transferred to Invoice", JobPlanningLine.Quantity, JobPlanningLine.FieldCaption("Qty. Transferred to Invoice"));
        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        Assert.AreEqual(2, JobPlanningLineInvoice.Count, StrSubstNo('%1 count.', JobPlanningLineInvoice.TableCaption()))
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceItemLine()
    begin
        // Invoice a billable item line
        ExecuteJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, 0)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceResourceLine()
    begin
        // Invoice a billable resource line
        ExecuteJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, 0)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvoiceGLLine()
    begin
        // Invoice a billable GL line
        ExecuteJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, 0)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PInvoiceItemLine()
    begin
        // Partially invoice a billable item line
        ExecuteJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), 1, LibraryRandom.RandInt(99) / 100, 0)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PInvoiceResourceLine()
    begin
        // Partially invoice a billable resource line
        ExecuteJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), 1, LibraryRandom.RandInt(99) / 100, 0)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PInvoiceGLLine()
    begin
        // Partially invoice a GL item line
        ExecuteJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), 1, LibraryRandom.RandInt(99) / 100, 0)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CreditItemLine()
    begin
        // Credit a "both" item line
        ExecuteJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CreditResourceLine()
    begin
        // Credit a "both" resource line
        ExecuteJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CreditGLLine()
    begin
        // Credit a "both" GL line
        ExecuteJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure PCreditItemLine()
    begin
        // Partially credit a "both" item line
        ExecuteJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure PCreditResourceLine()
    begin
        // Partially credit a "both" resource line
        ExecuteJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure PCreditGLLine()
    begin
        // Partially credit a "both" resource line
        ExecuteJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, LibraryRandom.RandInt(99) / 100)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure ECreditItemLine()
    begin
        // Excess credit a "both" item line
        ExecuteJob(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, LibraryRandom.RandInt(99) / 100 + 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure ECreditResourceLine()
    begin
        // Excess credit a "both" item line
        ExecuteJob(LibraryJob.ResourceType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, LibraryRandom.RandInt(99) / 100 + 1)
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure ECreditGLLine()
    begin
        // Excess credit a "both" GL line
        ExecuteJob(LibraryJob.GLAccountType(), LibraryJob.PlanningLineTypeBoth(), 1, 1, LibraryRandom.RandInt(99) / 100 + 1)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningAndVerifyGLEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        PostedDocumentNo: Code[20];
        JobNo: Code[20];
        LineAmount: Decimal;
    begin
        // Create Job and Job Planning Line and Create Job Journal with Line Type Blank and Create - Post Sales Invoice and Verify GL Entry.

        // Setup: Create Job and Job Planning Line and Create sales Invoice.
        Initialize();
        JobNo := CreateSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, false, false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        LineAmount := SalesLine."Line Amount";

        // Exercise: Post sales Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entries
        VerifyGLEntry(PostedDocumentNo, JobNo, -1 * LineAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningAndVerifyLineTypeInJobLedger()
    var
        SalesHeader: Record "Sales Header";
        JobPlanningLine: Record "Job Planning Line";
        PostedDocumentNo: Code[20];
        JobNo: Code[20];
    begin
        // Create Job and Job Planning Line and Create Job Journal with Line Type Blank and Create - Post Sales Invoice and Verify Line Type Billable in Job Ledger Entry.

        // Setup: Create Job and Job Planning Line and Create sales Invoice.
        Initialize();
        JobNo := CreateSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, false, false);
        // Exercise: Post sales Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Line Type In Job Ledger Entries.
        VerifyLineTypeInJobLedgerEntry(PostedDocumentNo, JobNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CheckDimensionOnSalesInvoiceFromJobPlanningLine()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Dimension on Sales Invoice line that copied from Job Task.
        SalesDocumentFromJobPlanning(SalesHeader."Document Type"::Invoice, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CheckDimensionOnSalesCreditMemoFromJobPlanningLine()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Dimension on Sales Credit Memo line that copied from Job Task.
        SalesDocumentFromJobPlanning(SalesHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningAndVerifyDimSetID()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
    begin
        // Create Customer & Job with Dimension and Create - Sales Invoice from Job Planning Line and Verify Sales Line Dimension Set ID.

        // Setup: Create Customer & Job with Dimension.
        Initialize();
        CreateJobPlanningLineWithDimension(JobPlanningLine);

        // Exercise: Create sales Invoice from Job Planning Line and find related Sales Line.
        TransferJobPlanningLine(JobPlanningLine, 1, false, SalesHeader);

        // Verify: Verify DimesionSet ID  of Sales Line with Comdined Dimension Set ID from Sales Header & Sales Line.
        VerifyCombinedDimensionSetIDOnSalesLine(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFromJobPlanningWithInvoiceCurrencyCode()
    var
        SalesHeader: Record "Sales Header";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedDocumentNo: Code[20];
        JobNo: Code[20];
    begin
        // Create Job and Job Planning Line and Create Job Journal with Line Type Blank and Create - Post Sales Invoice and Verify Job Ledger Entry.
        // Setup: Create Job and Job Planning Line and Create sales Invoice.
        Initialize();
        JobNo := CreateSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, true, false);
        // Exercise: Post sales Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // Verify: Verify Job Ledger Entries
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, -JobPlanningLine."Line Amount", JobLedgerEntry.FieldNo("Line Amount (LCY)"));
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, JobPlanningLine."Unit Price", JobLedgerEntry.FieldNo("Unit Price (LCY)"));
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, JobPlanningLine."Unit Cost", JobLedgerEntry.FieldNo("Unit Cost (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnJobJournalLine()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        DimMgt: Codeunit DimensionManagement;
        DimensionValueCode: Code[20];
    begin
        // Verify dimension value on Job Journal Line when Job Journal line created with Job and Job Task.

        // Setup: Create Job and Job task with dimension.
        Initialize();
        DimensionValueCode := CreateJobTaskWithDimension(JobTask);

        // Exercise: Create Job Journal Line.
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);

        // Verify: Verifying dimension on Job Journal Line.
        JobJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValueCode);
        JobJournalLine.TestField("Dimension Set ID",
          DimMgt.CreateDimSetFromJobTaskDim(
            JobTask."Job No.", JobTask."Job Task No.", DimensionValueCode, JobJournalLine."Shortcut Dimension 2 Code"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnJobLedgerEntry()
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Verify dimension value on Job Ledger Entry when Job Journal line posted with Job and Job Task.

        // Setup: Create Job and Job task with dimension.
        Initialize();
        CreateJobTaskWithDimension(JobTask);

        // Exercise: Create and post Job Journal Line.
        CreateAndPostJobJournalLineWithTypeItem(JobJournalLine, JobTask);

        // Verify: Verifying dimension on Job Ledger Entry.
        VerifyDimensionOnJobLedgerEntry(JobTask, JobJournalLine."Shortcut Dimension 1 Code", JobJournalLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,JobCalculateWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnJobWIPEntry()
    var
        JobTask: Record "Job Task";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Verify dimension on Job WIP Entry after running the report Job calculate WIP.

        // Setup: Create Job and Job task with dimension and create Post Job Journal Line.
        Initialize();
        LibraryVariableStorage.Enqueue(true);
        CreateJobTaskWithDimension(JobTask);
        CreateAndPostJobJournalLineWithTypeItem(JobJournalLine, JobTask);
        FindJobLedgerEntry(JobLedgerEntry, JobTask);

        // Exercise: Run Job Calculate WIP report.
        Job.SetRange("No.", JobTask."Job No.");
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Job Calculate WIP", true, false, Job);

        // Verify: Verifying dimension on Job WIP Entry.
        VerifyDimensionOnJobWIPEntry(JobTask."Job No.", JobJournalLine."Shortcut Dimension 1 Code", JobLedgerEntry."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemDimensionOnJobJournalLine()
    var
        Item: Record Item;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        GeneralLedgerSetup: Record "General Ledger Setup";
        JobTransferLine: Codeunit "Job Transfer Line";
    begin
        // Verify Item dimension on Job journal line when Job jounal line created from Job Planning line.

        // Setup: Create Item With Dimension and Create Job Planning Line.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, LibraryInventory.CreateItem(Item), GeneralLedgerSetup."Shortcut Dimension 1 Code", DimensionValue.Code);
        Plan(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobPlanningLine);
        UpdateJobPlanningLine(JobPlanningLine, Item."No.");

        // Exercise: Create Job Journal Line.
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, WorkDate(), LibraryJob.GetJobJournalTemplate(JobJournalTemplate),
          LibraryJob.CreateJobJournalBatch(LibraryJob.GetJobJournalTemplate(JobJournalTemplate), JobJournalBatch), JobJournalLine);

        // Verify: Verifying Dimension on Job Journal Line.
        VerifyDimensionOnJobJournalLine(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", DimensionValue.Code)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDimensionFromJobPlanningLine()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobTaskDim: Record "Job Task Dimension";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedCombDimSetID: Integer;
    begin
        // Check that dimensions are successfully combined from job journal line and job task dimensions

        // Setup: Create job task, job task dimenion, item and item default dimension.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateJobTaskDim(JobTaskDim, JobTask);
        LibraryInventory.CreateItem(Item);
        CreateDefDimForItem(DefaultDimension, Item."No.");

        // Exercuse: Post job journal line with item, transfer posted job planning line to sales invoice.
        CreatePostJobJournalLineWithItem(JobTask, Item."No.");
        TransJobPlanningLineToSalesInvoice(SalesHeader, JobTask);

        // Verify: Calculate expected combined dimension set ID and compare with set ID in sales line.
        ExpectedCombDimSetID :=
          GetCombinedDimSetID(JobTaskDim, DefaultDimension);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(
          ExpectedCombDimSetID, SalesLine."Dimension Set ID", StrSubstNo(WrongDimSetIDInSalesLineErr, SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TryPostSalesInvoiceFromJobPlanningLineStdCostChanged()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Verify that Sales Invoice for Job Planning Line can be posted if Standard Cost is changed after creation of Job Planning Line.

        // Setup.
        PrepareJobForSalesInvoice(JobTask, Item);

        // Exercise.
        CreatePostJobJournalLineWithItem(JobTask, Item."No.");
        TransJobPlanningLineToSalesInvoice(SalesHeader, JobTask);
        SetItemStandardCost(Item, Item."Standard Cost" * 2);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        VerifyPostedSalesInvoice(DocumentNo, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure TryPostSalesInvoiceFromJobPlanningLineStdCostDiffUOM()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Verify that Sales Invoice for Job Planning Line can be posted with Unit of Measure different from Base Unit of Measure.

        // Setup.
        PrepareJobForSalesInvoice(JobTask, Item);

        // Exercise.
        CreateJobJournalLineWithItem(JobJournalLine, JobTask, Item."No.");
        JobJournalLine.Validate("Unit of Measure Code", CreateItemUnitOfMeasure(Item));
        JobJournalLine.Modify();
        LibraryJob.PostJobJournal(JobJournalLine);
        TransJobPlanningLineToSalesInvoice(SalesHeader, JobTask);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        VerifyPostedSalesInvoice(DocumentNo, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDimensionFromJobPlanningLineManual()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobTaskDim: Record "Job Task Dimension";
        JobJournalLine: Record "Job Journal Line";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedDimValueCode: Code[20];
    begin
        // Create Job and Job Planning Line and Create Job Journal with Line Type Billable and Manually set Dimension and Create Sales Invoice and Verify Dimensions.

        // Setup.
        Initialize();
        CreateJobWithJobTask(JobTask);
        CreateJobTaskGlobalDim(JobTaskDim, JobTask);
        LibraryInventory.CreateItem(Item);
        CreateDefDimForItem(DefaultDimension, Item."No.");

        // Exercise.
        CreateJobJournalLineWithItem(JobJournalLine, JobTask, Item."No.");
        ExpectedDimValueCode := ModifyDimension(JobJournalLine);
        LibraryJob.PostJobJournal(JobJournalLine);

        TransJobPlanningLineToSalesInvoice(SalesHeader, JobTask);

        // Verify.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(
          ExpectedDimValueCode, SalesLine."Shortcut Dimension 1 Code", WrongDimValueCodeErr);
    end;

    local procedure ExecuteJob(ConsumableType: Enum "Job Planning Line Type"; LineType: Enum "Job Planning Line Line Type"; UsageFraction: Decimal; InvoiceFraction: Decimal; CreditFraction: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        // Plan job with LineType and ConsumableType
        // Consume UsageFraction of the job planning line
        // Invoice InvoiceFraction of the job planning line
        // Verify Qty. Invoiced, Qty. to Invoice
        // Credit CreditFraction of the job planning line
        // Verify Qty. Invoiced, Qty. to Invoice

        // Setup
        Initialize();
        // Plan
        Plan(LineType, ConsumableType, JobPlanningLine);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Modify(true);
        // Consume
        LibraryJob.UseJobPlanningLine(JobPlanningLine, LibraryJob.UsageLineType(JobPlanningLine."Line Type"), UsageFraction, JobJournalLine);
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        // Invoice
        Invoice(JobPlanningLine, InvoiceFraction);
        JobPlanningLine.CalcFields("Qty. Invoiced");
        Assert.AreEqual(InvoiceFraction * JobPlanningLine.Quantity, JobPlanningLine."Qty. Invoiced", JobPlanningLine.FieldCaption("Qty. Invoiced"));
        Assert.AreEqual(JobPlanningLine."Qty. Posted" - JobPlanningLine."Qty. Invoiced", JobPlanningLine."Qty. to Invoice", JobPlanningLine.FieldCaption("Qty. to Invoice"));
        // Credit
        Credit(JobPlanningLine, CreditFraction);
        JobPlanningLine.CalcFields("Qty. Invoiced");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJournalLineFromJobJnlLine()
    var
        JobTask: Record "Job Task";
        GenJournalLine: Record "Gen. Journal Line";
        JobJnlLine: Record "Job Journal Line";
    begin
        // SETUP
        Initialize();
        CreateJobTaskWithDimensions(JobTask);
        LibraryJob.CreateJobJournalLine(JobJnlLine."Line Type"::Billable, JobTask, JobJnlLine);

        // EXERCISE: Add Job General Line
        LibraryJob.CreateJobGLJournalLine(GenJournalLine."Job Line Type"::"Both Budget and Billable", JobTask, GenJournalLine);

        // VERIFY
        Assert.AreEqual(JobJnlLine."Dimension Set ID", GenJournalLine."Dimension Set ID",
          StrSubstNo(WrongJobJnlDimensionsErr, GenJournalLine.FieldCaption("Dimension Set ID")));
        Assert.AreEqual(JobJnlLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 1 Code",
          StrSubstNo(WrongJobJnlDimensionsErr, GenJournalLine.FieldCaption("Shortcut Dimension 1 Code")));
        Assert.AreEqual(JobJnlLine."Shortcut Dimension 2 Code", GenJournalLine."Shortcut Dimension 2 Code",
          StrSubstNo(WrongJobJnlDimensionsErr, GenJournalLine.FieldCaption("Shortcut Dimension 2 Code")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostJobJnlLineFromJobPlanningLine()
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        // SETUP
        Initialize();
        CreateJobPlanningLineWithItem(JobPlanningLine);
        CreateJobJnlLineFromJobPlanningLine(JobJournalLine, JobPlanningLine);

        // EXERCISE
        LibraryJob.PostJobJournal(JobJournalLine);

        // VERIFY
        FindJobLedgerEntryByJob(JobLedgerEntry, JobPlanningLine."Job No.", JobPlanningLine."No.");
        Assert.AreEqual(JobPlanningLine.Quantity, JobLedgerEntry.Quantity,
          StrSubstNo(WrongJobLedgerEntryQtyErr));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CreateJobSalesInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionSetEntrySalesLine: Record "Dimension Set Entry";
        DimensionCode: Code[20];
        JobJournalLineDimSetID: Integer;
    begin
        // SETUP
        Initialize();
        CreatePostJobJnlLineWithDimJobPlanningLine(JobPlanningLine, DimensionCode, JobJournalLineDimSetID);
        // EXERCISE: Create Job Sales Line
        TransferJobPlanningLine(JobPlanningLine, 1, false, SalesHeader);
        // VERIFY
        FindDimensionSetEntryByCode(DimensionSetEntry, JobJournalLineDimSetID, DimensionCode);
        FindSalesLineByDocumentType(SalesLine, SalesHeader);
        FindDimensionSetEntryByCode(DimensionSetEntrySalesLine, SalesLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(DimensionSetEntry."Dimension Value Code",
          DimensionSetEntrySalesLine."Dimension Value Code", WrongSalesInvoiceDimensionsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantityInJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [SCENARIO] Verifies Job Journal Line's Unit Price properly calculated after line's quantity update
        Initialize();
        // [GIVEN] Create Job Journal Line with Item and Job Item Price setup
        ExpectedUnitPrice := CreateJobJnlLine(JobJournalLine);
        // [WHEN] Quantity updated in Job Journal Line
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(10));
        // [THEN] Line's "Unit Price" must be calculated using Item's Unit Cost and Job Item Price factor.
        Assert.AreEqual(Round(ExpectedUnitPrice, 2), Round(JobJournalLine."Unit Price", 2), UnitPriceMustNotBeZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeLocationCodeInJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
        Location: Record Location;
        ExpectedUnitPrice: Decimal;
    begin
        // [SCENARIO] Verifies Job Journal Line's Unit Price properly calculated after line's location update
        Initialize();
        // [GIVEN] Create Job Journal Line with Item and Job Item Price setup
        // [GIVEN] Create new location for update Job Journal Line
        ExpectedUnitPrice := CreateJobJnlLine(JobJournalLine);
        LibraryWarehouse.CreateLocation(Location);
        // [WHEN] Location updated in Job Journal Line
        JobJournalLine.Validate("Location Code", Location.Code);
        // [THEN] Line's "Unit Price" must be calculated using Item's Unit Cost and Job Item Price factor.
        Assert.AreEqual(Round(ExpectedUnitPrice, 2), Round(JobJournalLine."Unit Price", 2), UnitPriceMustNotBeZeroErr);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TryPostSalesInvoiceFromJobPlanningLineAfterDescriptionChanged()
    var
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        NewDescription: Text[50];
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verifies that Sales Invoice can be posted after changing Description
        Initialize();
        // [GIVEN] Create Job Journal Line
        CreateJobPlanningLineWithResource(JobTask);
        // [GIVEN] Create Sales Invoice and change Description
        TransJobPlanningLineToSalesInvoice(SalesHeader, JobTask);
        NewDescription := UpdateDesriptionInSalesLine(SalesHeader."No.", SalesHeader."Document Type");
        // [WHEN] Sales invoice posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] Sales invoice line must have with changed description
        VerifyDescriptionInPostedSalesInvoice(DocumentNo, NewDescription);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLCYFromJobPlanningPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedDocumentNo: Code[20];
        JobNo: Code[20];
    begin
        // [SCENARIO 120828] Sales Invoice's "Prices Incl. VAT" value should not affect Job Ledger Entry fields "Line Amount" and "Unit Price". Sale is in LCY.
        Initialize();
        // [GIVEN] Sales Invoice (LCY, Prices Incl. VAT = true) created from Job Planning Line
        JobNo := CreateSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, false, true);
        // [WHEN] Sales Invoice posted
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] Job Ledger Entry values of Line Amount and Unit Price are equal to the values of Job Planning Line
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, -JobPlanningLine."Line Amount", JobLedgerEntry.FieldNo("Line Amount"));
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, JobPlanningLine."Unit Price", JobLedgerEntry.FieldNo("Unit Price"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFCYFromJobPlanningPricesInclVAT()
    var
        SalesHeader: Record "Sales Header";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedDocumentNo: Code[20];
        JobNo: Code[20];
    begin
        // [SCENARIO 120828] Sales Invoice's "Prices Incl. VAT" value should not affect Job Ledger Entry fields "Line Amount" and "Unit Price". Sale is in FCY.
        Initialize();
        // [GIVEN] Sales Invoice (FCY, Prices Incl. VAT = true) created from Job Planning Line
        JobNo := CreateSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, true, true);
        // [WHEN] Sales Invoice posted
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] Job Ledger Entry values of Line Amount and Unit Price are equal to the values of Job Planning Line
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, -JobPlanningLine."Line Amount", JobLedgerEntry.FieldNo("Line Amount"));
        VerifyJobLedgerEntry(PostedDocumentNo, JobNo, JobPlanningLine."Unit Price", JobLedgerEntry.FieldNo("Unit Price"));
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceFCYWithTextJobPlanningLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 375614] Sales Invoice created from Job with FCY and Job Planning Line with Type = Text

        Initialize();
        // [GIVEN] Job with Currency Code
        CreateJobWithCurrency(Job);

        // [GIVEN] Job Task with Resource and Text job planning lines
        // Resource line is mandatory in order to have non-zero Sales Invoice
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        CreateJobPlanningLineWithTypeText(JobPlanningLine, JobPlanningLine."Line Type"::Billable, JobTask);
        Commit();

        // [WHEN] Create Sales Invoice for job planning lines
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sales Invoice invoice with Text line created
        VerifySalesLineWithTextExists(JobPlanningLine);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDocumentDateOnJobLedgEntry()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
    begin
        // [SCENARIO 376225] Document Date should be transfered from Sales Invoice to Job Ledger Entry

        // [GIVEN] Sales Invoice with "Posting Date" = 15.01 and "Document Date" = 10.01
        Initialize();
        Plan(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobPlanningLine);
        TransferJobPlanningLine(JobPlanningLine, 1, false, SalesHeader);

        SalesHeader.Validate("Document Date", SalesHeader."Document Date" - 1);

        // [WHEN] Post Sales Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Job Ledger Entry created with "Document Date" = 10.01
        VerifyDocDateOnJobLedgEntry(
          JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", DocNo, SalesHeader."Document Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerFalseReply')]
    [Scope('OnPrem')]
    procedure JobCurrencyFactorNotUpdatedWhenCancelExchRateConfOnPurchOrder()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchHeader: Record "Purchase Header";
        NewPostingDate: Date;
    begin
        // [FEATURE] [Currency] [Purchase]
        // [SCNEARIO 377381] "Job Currency Factor" should not be updated in Purchase Line when cancel exchange rate update on Purchase Order

        Initialize();
        // [GIVEN] Job Task with Currency
        CreateJobWithCurrency(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Purchase Order related to Job Task with Currency, "Posting Date" = 01.01 and "Exchage Rate" = "A"
        CreatePurchInvWithCurrencyAndJobTask(PurchHeader, Job."Currency Code", JobTask);

        // [GIVEN] Currency Exchange Rate with "Starting Date" = 02.01 and "Exchange Rate" = "B"
        NewPostingDate := LibraryRandom.RandDate(10);
        CreateCurrencyExchangeRate(Job."Currency Code", NewPostingDate);

        // [WHEN] Change "Posting Date" of Purchase Order to 02.01. Cancel confirmation "Do you want to update Exchange Rate?"
        PurchHeader.Validate("Posting Date", NewPostingDate);

        // [THEN] "Job Currency Factor" = "A" in Purchase Line
        VerifyJobCurrencyFactorOnPurchLine(PurchHeader);
    end;

    [Test]
    [HandlerFunctions('CreateSalesInvoiceReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithJobAndVATGroups()
    var
        SalesHeader: Record "Sales Header";
        JobTask: Record "Job Task";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroupArray: array[6] of Record "VAT Product Posting Group";
        VATPostingSetupArray: array[6] of Record "VAT Posting Setup";
        ItemNo: Code[20];
        GLAccountNo: Code[20];
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
        GenBusPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        // [SCENARIO 380416] Job Ledger Entry is pointing to a correct General Ledger Entry when Sales Invoice has been posted with various VAT Production Posting Groups.

        Initialize();
        CreateGenPostingGroups(GenProdPostingGroupCode, GenBusPostingGroupCode);
        CreateVATPostingGroupsArray(VATBusPostingGroup, VATProdPostingGroupArray, VATPostingSetupArray);
        GLAccountNo := SetupGLAccount(VATPostingSetupArray[1], GenBusPostingGroupCode, GenProdPostingGroupCode);
        ItemNo := LibraryInventory.CreateItemNoWithPostingSetup(GenProdPostingGroupCode, VATProdPostingGroupArray[1].Code);
        CustomerNo := SetupCustomerWithVATPostingGroup(VATBusPostingGroup.Code, GenProdPostingGroupCode);

        // [GIVEN] Job with Job Task "JT" with Planning Lines with 8 Items and GL Accounts.
        // [GIVEN] Created Sales Invoice from Job Task where are 8 G/L Account/Items lines have various VAT Prod. Posting Group.
        CreateJobWithVATPostingGroupsWithPlanningLines(
          JobTask, GenBusPostingGroupCode, GenProdPostingGroupCode, CustomerNo, ItemNo, GLAccountNo);
        CreateSalesInvoiceWithVariousVATPostingGroups(SalesHeader, JobTask, VATProdPostingGroupArray, VATBusPostingGroup.Code, CustomerNo);

        // [WHEN] Post the Sales Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Job Ledger Entries, where "Ledger Entry Type" is "G/L Account", are mapped 1-to-1 and 1-to-many to G/L Entries by "Ledger Entry No.".
        // [THEN] Posted Job Ledger Entries, where "Ledger Entry Type" is "Item", are mapped 1-to-1 to Item Ledger Entries by "Ledger Entry No.".
        VerifyJobLedgerEntriesWithGLEntries(JobTask, PostedDocumentNo, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceTwiceFromJobPlanningLineWithCurrency()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Currency] [UI]
        // [SCENARIO 201069] Isaac can create Sales Invoice from Job Planning Line twice for Job with "Currency Code"

        Initialize();

        // [GIVEN] Job with "Currency Code"
        CreateJobWithCurrency(Job);

        // [GIVEN] Job Planning Line with Quantity = 2 and "Qty. to Transfer to Invoice" = 1
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, 2, 1);
        Commit(); // needed for TransferToInvoiceHandler which shows modal page

        // [GIVEN] Created first Sales Invoice for Job Planning Line. "Qty. Transferred to Invoice" = 1; "Qty. to Transfer to Invoice" = 1
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [WHEN] Create Sales Invoice second time
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Two Sales Lines created in total (for the first and second invoice)
        VerifySalesLineCountLinkedToJob(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", 2);

        // [THEN] Job Planning Line is updated. "Qty. Transferred to Invoice" = 2; "Qty. to Transfer to Invoice" = 0
        VerifyInvoiceQuantityInJobPlanningLine(JobPlanningLine, JobPlanningLine.Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CostAmountWhenUndoReceiptWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedRcptNo: Code[20];
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 209289] Cost Amount is actual when undo the receipt of Purchase Order with Job

        Initialize();

        // [GIVEN] Receive Purchase Order with Item "X", Job and Cost Amount = 100
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);
        PostedRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Undo Receipt
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [WHEN] Post Purchase Order (Receive & Invoice)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] All Item Ledger Entry posted with Item "X" has "Cost Amount (Expected)" = 0 and "Cost Amount (Actual)" = 100
        VerifyItemLedgEntriesInvoiced(PurchRcptLine."No.", PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPartialInvoiceOrderWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedRcptNo: Code[20];
        UndoReceiptErr: Label 'This receipt has already been invoiced. Undo Receipt can be applied only to posted, but not invoiced receipts.';
    begin
        // [Bug] [Undo Receipt]
        // [SCENARIO 488264] Undo receipt for partially invoiced order with jobs should not be allowed
        Initialize();

        // [GIVEN] Create Purchase Order with Job
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);

        // [GIVEN] Post Purchase Order (Receive)
        PostedRcptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Update Qty. to Invoice to half of Qty. Received
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Order (Invoice)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [Then] Try to Undo Receipt for partially invoiced order
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);
        asserterror LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        Assert.ExpectedError(UndoReceiptErr);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CostAmountWhenPostCrMemoLinesToReverseFromInvWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO 209289] Cost amount is actual when post Credit Memo with lines to reverse from Purchase Order with Job

        Initialize();

        // [GIVEN] Posted Purchase Invoice with Item "X", Job and Cost Amount = 100
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Purchase Credit Memo with lines to reverse from Posted Purchase Invoice
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(PostedInvoiceNo);
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [WHEN] Post Purchase Credit Memo
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] All Item Ledger Entry posted with Item "X" has "Cost Amount (Expected)" = 0 and "Cost Amount (Actual)" = 100
        VerifyItemLedgEntriesInvoiced(PurchaseLine."No.", PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CostAmountWhenUndoReceiptWithJobAndLotTracking()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedRcptNo: Code[20];
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 209289] Cost Amount is actual when undo the receipt of Purchase Order with Job and Lot tracking

        Initialize();

        // [GIVEN] Receive Purchase Order with Item "X", Lot Tracking, Job and Cost Amount = 100
        LibraryItemTracking.CreateLotItem(Item);
        PostedRcptNo := ReceivePurchOrderWithJobAndItemTracking(PurchaseHeader, Item."No.", TrackingOption::"Assign Lot No.");
        FindPurchLine(PurchLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Undo Receipt
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [WHEN] Post Purchase Order (Receive & Invoice)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] All Item Ledger Entry posted with Item "X" has "Cost Amount (Expected)" = 0 and "Cost Amount (Actual)" = 100
        VerifyItemLedgEntriesInvoiced(Item."No.", PurchLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure CostAmountWhenUndoReceiptWithJobAndSerialNoTracking()
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedRcptNo: Code[20];
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 209289] Cost Amount is actual when undo the receipt of Purchase Order with Job and Serial No. tracking

        Initialize();

        // [GIVEN] Receive Purchase Order with Item "X", Serial No. Tracking, Job and Cost Amount = 100
        LibraryItemTracking.CreateSerialItem(Item);
        PostedRcptNo := ReceivePurchOrderWithJobAndItemTracking(PurchaseHeader, Item."No.", TrackingOption::"Assign Serial No.");

        // [GIVEN] Undo Receipt
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [WHEN] Post Purchase Order (Receive & Invoice)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] All Item Ledger Entry posted with Item "X" has "Cost Amount (Expected)" = 0 and "Cost Amount (Actual)" = 100
        Item.Find();
        VerifyItemLedgEntriesInvoiced(Item."No.", Item."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesAfterUndoReceiptAreReopenForAdjustment()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        PostedRcptNo: Code[20];
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 209289] Item Ledger Entries after undo the receipt are reopen for adjustment

        Initialize();

        // [GIVEN] Receive Purchase Order with Item "X", Job and Cost Amount = 100
        PostedRcptNo := PostPurchaseOrderWithJob(true, false);
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);

        // [GIVEN] Adjust Cost Item Entries for Item "X"
        LibraryCosting.AdjustCostItemEntries(PurchRcptLine."No.", '');

        // [WHEN] Undo receipt
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] All Item Ledger Entry posted with Item "X" has "Applied Entry to Adjust" = TRUE
        VerifyAppliedEntryToAdjustFalseInItemLedgEntries(PurchRcptLine."No.");

        // [THEN] Item has "Cost is Adjust" = FALSE
        Item.Get(PurchRcptLine."No.");
        Item.TestField("Cost is Adjusted", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CostAmountWhenUndoReceiptOnLaterDateWithJob()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchLine: Record "Purchase Line";
        PostedRcptNo: Code[20];
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 209289] Cost Amount is actual when undo the receipt of Purchase Order with Job on later "Posting Date"

        Initialize();

        // [GIVEN] Receive Purchase Order with "Posting Date" = 01.01, Item "X", Job and Cost Amount = 100
        PostedRcptNo := PostPurchaseOrderWithJob(true, false);
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);

        // [GIVEN] Change "Posting Date" = 05.01 in Purchase Order
        ChangePostingDateWithLaterDateOnPurchHeader(PurchaseHeader, PurchRcptLine."No.");
        FindPurchLine(PurchLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Undo Receipt
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [WHEN] Post Purchase Order (Receive & Invoice)
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] All Item Ledger Entry posted with Item "X" has "Cost Amount (Expected)" = 0 and "Cost Amount (Actual)" = 100
        VerifyItemLedgEntriesInvoiced(PurchRcptLine."No.", PurchLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemRegisterWhenUndoReceiptWithJob()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedRcptNo: Code[20];
    begin
        // [FEATURE] [Undo Receipt]
        // [SCENARIO 209289] Item Register is created when undo the receipt of Purchase Order with Job
        Initialize();

        // [GIVEN] Receive Purchase Order with Item and Job
        PostedRcptNo := PostPurchaseOrderWithJob(true, false);
        FindPurchaseReceiptLine(PurchRcptLine, PostedRcptNo);

        // [WHEN] Undo Receipt
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Item Register is created for Item Ledger Entries from Negative Adjustment of Job to Purchase of Job
        VerifyItemRegisterExistsFromNegativeToPurchItemLedgEntry(PurchRcptLine."No.");

        // [GIVEN] Value Entries in Item Register has Cost Amount (Actual)
        VerifyItemRegisterWithCostAmtActualValueEntriesExists(PurchRcptLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobInvoicesPageInDrillDownMode()
    var
        JobInvoicesTestPage: TestPage "Job Invoices";
        JobInvoicesPage: Page "Job Invoices";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 222559] "Transferred Date", "Invoiced Date" and "Job Lendger Entry No." fields are not visible when page "Job Invoices" opened without "Show Details"
        JobInvoicesTestPage.Trap();

        JobInvoicesPage.SetShowDetails(false);
        JobInvoicesPage.Run();

        Assert.IsFalse(JobInvoicesTestPage."Transferred Date".Visible(), JobInvoicesTestPage."Transferred Date".Caption);
        Assert.IsFalse(JobInvoicesTestPage."Invoiced Date".Visible(), JobInvoicesTestPage."Invoiced Date".Caption);
        Assert.IsFalse(JobInvoicesTestPage."Job Ledger Entry No.".Visible(), JobInvoicesTestPage."Job Ledger Entry No.".Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobInvoicesPageInNormalMode()
    var
        JobInvoicesTestPage: TestPage "Job Invoices";
        JobInvoicesPage: Page "Job Invoices";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 222559] "Transferred Date", "Invoiced Date" and "Job Lendger Entry No." fields are visible when page "Job Invoices" opened with "Show Details"
        JobInvoicesTestPage.Trap();

        JobInvoicesPage.SetShowDetails(true);
        JobInvoicesPage.Run();

        Assert.IsTrue(JobInvoicesTestPage."Transferred Date".Visible(), JobInvoicesTestPage."Transferred Date".Caption);
        Assert.IsTrue(JobInvoicesTestPage."Invoiced Date".Visible(), JobInvoicesTestPage."Invoiced Date".Caption);
        Assert.IsTrue(JobInvoicesTestPage."Job Ledger Entry No.".Visible(), JobInvoicesTestPage."Job Ledger Entry No.".Caption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobInvoicesPageFromJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobInvoicesTestPage: TestPage "Job Invoices";
    begin
        // [FEATURE] [Job Planning Line] [UI]
        // [SCENARIO 222559] "Transferred Date", "Invoiced Date" and "Job Lendger Entry No." fields are not visible when page "Job Invoices" opened as drill down from job planning line
        JobInvoicesTestPage.Trap();

        JobPlanningLine.DrillDownJobInvoices();

        Assert.IsFalse(JobInvoicesTestPage."Transferred Date".Visible(), JobInvoicesTestPage."Transferred Date".Caption);
        Assert.IsFalse(JobInvoicesTestPage."Invoiced Date".Visible(), JobInvoicesTestPage."Invoiced Date".Caption);
        Assert.IsFalse(JobInvoicesTestPage."Job Ledger Entry No.".Visible(), JobInvoicesTestPage."Job Ledger Entry No.".Caption);
    end;

    [Test]
    [HandlerFunctions('JobInvoicesDetailsVisibleModalPageHandler')]
    [Scope('OnPrem')]
    procedure JobInvoicesPageFromJobTask()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobInvoicesTestPage: TestPage "Job Invoices";
        JobCard: TestPage "Job Card";
    begin
        // [FEATURE] [Job Task] [UI]
        // [SCENARIO 222559] "Transferred Date", "Invoiced Date" and "Job Lendger Entry No." fields are visible when page "Job Invoices" opened by "Sales Invoices / Credit Memos" action on job task line subpage
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        JobInvoicesTestPage.Trap();

        JobCard.OpenView();
        JobCard.GotoRecord(Job);

        JobCard.JobTaskLines.SalesInvoicesCreditMemos.Invoke();

        // Visibility verified in JobInvoicesDetailsVisibleModalPageHandler
    end;

    [Test]
    [HandlerFunctions('JobInvoicesDetailsVisibleModalPageHandler')]
    [Scope('OnPrem')]
    procedure JobInvoicesPageFromJob()
    var
        Job: Record Job;
        JobInvoicesTestPage: TestPage "Job Invoices";
        JobList: TestPage "Job List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 222559] "Transferred Date", "Invoiced Date" and "Job Lendger Entry No." fields are visible when page "Job Invoices" opened by "Sales Invoices / Credit Memos" action on jobs page
        LibraryJob.CreateJob(Job);

        JobInvoicesTestPage.Trap();

        JobList.OpenView();
        JobList.GotoRecord(Job);

        JobList.SalesInvoicesCreditMemos.Invoke();

        // Visibility verified in JobInvoicesDetailsVisibleModalPageHandler
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoiceBillableFullyInvoiced()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Cancel Invoice action from posted sales invoice card leads to creating job planning lines and posting appropriate credit memo
        Initialize();

        // [GIVEN] Posted sales invoice with job
        CreateSimpleSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel Invoice function is being run
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Posted invoice become cancelled
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields(Cancelled);
        SalesInvoiceHeader.TestField(Cancelled, true);

        // [THEN] Credit Memo posted
        Assert.IsTrue(CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No."), 'Cancelled Credit Memo not found');
        SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");

        // [THEN] Reversed job planning line created
        Assert.IsTrue(FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine), 'Reversed Jop Planning Line not found');
        // [THEN] Reversed job planning line fully invoiced
        JobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.TestField("Invoiced Amount (LCY)", -JobPlanningLine."Invoiced Amount (LCY)");
        ReversedJobPlanningLine.TestField("Qty. to Transfer to Invoice", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoicePartlyTransferredFromJobPlanningLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Job Planning Line for credit memo (created during cancel sales invoice) has same quantity which were used for creation sales invoice
        Initialize();

        // [GIVEN] Job planning line with Quantity = 100, "Qty. to Transfer to Invoice" = 50
        CreateSimpleSalesInvoiceFromJobPlanningLine(
          SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100);
        // [GIVEN] Sales invoice created and posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel Invoice function is being run
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Reversed job planning line created
        FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine);
        // [THEN] Reversed job planning line invoiced with same amount as initial one
        JobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.TestField("Invoiced Amount (LCY)", -JobPlanningLine."Invoiced Amount (LCY)");
        // [THEN] Reversed job planning line Quantity = -50
        ReversedJobPlanningLine.TestField(Quantity, -JobPlanningLine."Qty. Transferred to Invoice");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoicePartlyInvoicedFromJobPlanningLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Job Planning Line for credit memo (created during cancel sales invoice) has same quantity which were used for creation sales invoice when there is a nonposted second invoice create from same job planing line
        Initialize();

        // [GIVEN] Job planning line with Quantity = 100, "Qty. to Transfer to Invoice" = 60
        CreateSimpleSalesInvoiceFromJobPlanningLine(
          SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100);
        // [GIVEN] Sales invoice created and posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Create new sales invoice from Job Planning Line with the rest of quantity 40, but do not post it
        JobPlanningLine.Find();
        TransferJobPlanningLine(
          JobPlanningLine, JobPlanningLine."Qty. to Transfer to Invoice" / JobPlanningLine.Quantity, false, SalesHeader);

        // [WHEN] Cancel Invoice function is being run
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Reversed job planning line created
        FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine);
        // [THEN] Reversed job planning line invoiced with same amount as initial one
        JobPlanningLine.CalcFields("Invoiced Amount (LCY)", "Qty. Invoiced");
        ReversedJobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.TestField("Invoiced Amount (LCY)", -JobPlanningLine."Invoiced Amount (LCY)");
        // [THEN] Reversed job planning line Quantity = -60
        ReversedJobPlanningLine.TestField(Quantity, -JobPlanningLine."Qty. Invoiced");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelSecondPostedSalesInvoiceFromPartlyInvoicedJobPlanningLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SecondInvoiceQty: Decimal;
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Job Planning Line for credit memo (created during cancel of second sales invoice) has same quantity which were used for creation sales invoice
        Initialize();

        // [GIVEN] Job planning line with Quantity = 100, "Qty. to Transfer to Invoice" = 60
        CreateSimpleSalesInvoiceFromJobPlanningLine(
          SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandInt(99) / 100);
        // [GIVEN] Sales invoice created and posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create new sales invoice from Job Planning Line with the rest of quantity 40
        JobPlanningLine.Find();
        SecondInvoiceQty := JobPlanningLine."Qty. to Transfer to Invoice";
        TransferJobPlanningLine(
          JobPlanningLine, JobPlanningLine."Qty. to Transfer to Invoice" / JobPlanningLine.Quantity, false, SalesHeader);

        // [GIVEN] Posted second invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel Invoice function is being run for second invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Reversed job planning line created
        FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine);
        // [THEN] Reversed job planning line Quantity = -40
        ReversedJobPlanningLine.TestField(Quantity, -SecondInvoiceQty);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoiceBothBudgetAndBillableFull()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Cancel Invoice action from posted sales invoice card leads to creating job planning lines with line type = "Billable" and posting appropriate credit memo
        Initialize();

        // [GIVEN] Posted sales invoice with job, line type of job planning line = "Both Budget and Billable"
        CreateSimpleSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeBoth(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel Invoice function is being run
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Reversed job planning line created
        Assert.IsTrue(FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine), 'Reversed Jop Planning Line not found');
        // [THEN] Reversed job planning line has line type Billable
        ReversedJobPlanningLine.TestField("Line Type", ReversedJobPlanningLine."Line Type"::Billable);
        // [THEN] Reversed job planning line fully invoiced
        JobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.CalcFields("Invoiced Amount (LCY)");
        ReversedJobPlanningLine.TestField("Invoiced Amount (LCY)", -JobPlanningLine."Invoiced Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyQuestion,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoiceWithJobConfirmationMessage()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice] [UI]
        // [SCENARIO 208992] The confirmation message for Cancel Invoice action for document with job does not contain old job related part
        Initialize();

        // [GIVEN] Posted sales invoice with job
        // [GIVEN] Open posted invoice card page
        CreatePostSalesInvoiceAndOpenItWithCardPage(PostedSalesInvoice, SalesInvoiceHeader);

        // [WHEN] Action Cancel Invoice function is being hit
        PostedSalesInvoice.CancelInvoice.Invoke();

        // [THEN] Confirmation message is "The posted sales invoice will be canceled, and a sales credit memo will be created and posted, which reverses the posted sales invoice.\ \Do you want to continue?"
        Assert.AreEqual(CancelPostedInvoiceQst, LibraryVariableStorage.DequeueText(), 'Invalid confirmation question');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoiceResourceWithChangedUnitCost()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Resource unit cost for the reversing job planning line is copied from initial job planning line while canceling the sales invoice
        Initialize();

        // [GIVEN] Posted sales invoice with job and resource with Unit Cost = 100
        CreateSimpleSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), 1);

        // [GIVEN] Change resource Unit Cost to 200
        Resource.Get(JobPlanningLine."No.");
        Resource.Validate("Unit Cost", JobPlanningLine."Unit Cost" + LibraryRandom.RandIntInRange(50, 100));
        Resource.Modify(true);

        // [WHEN] Cancel Invoice function is being run
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Reversed job planning line created
        FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine);

        // [THEN] Reversed job planning line has Unit Cost = 100
        ReversedJobPlanningLine.TestField("Unit Cost", JobPlanningLine."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoiceWithTextType()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] Sales invoice can be canceled if it was created from job planning line with Text type
        Initialize();

        // [GIVEN] Posted sales invoice made from job planning lines with resource and text types
        CreateSalesInvoiceWithResourceAndTextTypes(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract());

        // [WHEN] Cancel Invoice function is being run
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Reversed job planning line with Text type created
        ReversedJobPlanningLine.SetRange(Type, ReversedJobPlanningLine.Type::Text);
        ReversedJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        ReversedJobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        Assert.AreEqual(2, ReversedJobPlanningLine.Count, 'Reversed job planning line with Text type not found');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CancelPostedSalesInvoiceWithBlockedJob()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice]
        // [SCENARIO 208992] User is not able to cancel posted sales invoice if it contains reference to the blocked job
        Initialize();

        // [GIVEN] Posted sales invoice with job
        CreateSimpleSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Set job blocked
        Job.Get(JobPlanningLine."Job No.");
        Job.Validate(Blocked, Job.Blocked::All);
        Job.Modify(true);
        Commit();

        // [WHEN] Cancel Invoice function is being run
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Error "Job musnt not be blocked" displayed
        Assert.ExpectedError(StrSubstNo(JobMustNotBeBlockedErr, Job."No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CorrectPostedSalesInvoiceBillableFullyInvoiced()
    var
        SalesHeader: Record "Sales Header";
        NewSalesInvoiceHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        JobPlanningLine: Record "Job Planning Line";
        NewJobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Correct Invoice]
        // [SCENARIO 208992] Correct Invoice action from posted sales invoice card leads to creating job planning lines and posting appropriate credit memo
        Initialize();

        // [GIVEN] Posted sales invoice with job
        CreateSimpleSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Correct Invoice function is being run
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, NewSalesInvoiceHeader);

        // [THEN] Posted invoice become cancelled
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader.CalcFields(Cancelled);
        SalesInvoiceHeader.TestField(Cancelled, true);

        // [THEN] Credit Memo posted
        Assert.IsTrue(CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No."), 'Cancelled Credit Memo not found');
        SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");

        // [THEN] New invoice sales line has link to the job planning line
        SalesLine.SetRange("Document Type", NewSalesInvoiceHeader."Document Type");
        SalesLine.SetRange("Document No.", NewSalesInvoiceHeader."No.");
        SalesLine.SetFilter(Type, '<>0');
        SalesLine.SetFilter("Job Contract Entry No.", '<>%1', JobPlanningLine."Job Contract Entry No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Job Contract Entry No.");

        // [THEN] Job planning line for new invoice created
        NewJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        NewJobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
        Assert.IsTrue(NewJobPlanningLine.FindFirst(), 'New Job Planning line is not found');
        // [THEN] Job planning line fully transferred to new invoice
        NewJobPlanningLine.TestField("Qty. to Transfer to Invoice", 0);
        NewJobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        NewJobPlanningLine.TestField("Qty. Transferred to Invoice", JobPlanningLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyQuestion,MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CorrectPostedSalesInvoiceWithJobConfirmationMessage()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [Cancel Invoice] [UI]
        // [SCENARIO 208992] The confirmation message for Correct Invoice action for document with job does not contain old job related part
        Initialize();

        // [GIVEN] Posted sales invoice with job
        // [GIVEN] Open posted invoice card page
        CreatePostSalesInvoiceAndOpenItWithCardPage(PostedSalesInvoice, SalesInvoiceHeader);

        // [WHEN] Action Correct Invoice function is being hit
        PostedSalesInvoice.CorrectInvoice.Invoke();

        // [THEN] Confirmation message is "The posted sales invoice will be canceled, and a new version of the sales invoice will be created so that you can make the correction.\ \Do you want to continue?"
        Assert.AreEqual(CorrectPostedInvoiceQst, LibraryVariableStorage.DequeueText(), 'Invalid confirmation question');
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyTransferedAndPostingDateFromPostedInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempJobPlanningLineInvoice: Record "Job Planning Line Invoice" temporary;
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Sales] [UT]
        // [SCENARIO 225966] COD1002.FindInvoices function transfers copies "Transfered Date" and "Invoiced Date" to output temporary record
        Initialize();

        // [GIVEN] Posted sales invoice "I" created from job "X" with the job planning line
        // [GIVEN] Created "Job Planning Line Invoice" for "I" has "Transfered Date" and "Invoiced Date" = WORKDATE
        CreateSimpleSalesInvoiceFromJobPlanningLine(
          SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), LibraryRandom.RandDecInRange(0, 1, 2));

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] When call COD1002.FindInvoices function with detail level = "Per Job" for job "X"
        JobCreateInvoice.FindInvoices(TempJobPlanningLineInvoice, JobPlanningLine."Job No.", '', 0, DetailLevel::"Per Job");

        // [THEN] Inserted temporary "Job Planning Line Invoice" record has "Transfered Date" and "Invoiced Date" = WORKDATE
        TempJobPlanningLineInvoice.TestField("Job No.", JobPlanningLine."Job No.");
        TempJobPlanningLineInvoice.TestField("Document No.", DocumentNo);
        TempJobPlanningLineInvoice.TestField("Document Type", TempJobPlanningLineInvoice."Document Type"::"Posted Invoice");
        TempJobPlanningLineInvoice.TestField("Transferred Date", WorkDate());
        TempJobPlanningLineInvoice.TestField("Invoiced Date", WorkDate());

        Assert.RecordCount(TempJobPlanningLineInvoice, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceForTwoJobPlanningLinesWithGLAccHasCorrectJobLedgerEntryNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 235814] Sales Invoice created for two Job Planning Lines with G/L Account has correct Job Ledger Entry No. in Job Planning Line Invoice

        Initialize();

        // [GIVEN] Job with two identical Job Planning Lines with G/L Accounts
        CreateJob(Job, '', false);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");

        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);

        // [WHEN] Post Sales Invoice
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two Job Ledger Entries generated - "X" and "Y"
        // [THEN] Two Job Planning Line Invoice records created, first corresponds to "X", second to "Y"
        VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(
          JobPlanningLine, JobPlanningLineInvoice."Document Type"::"Posted Invoice", PostedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoForTwoJobPlanningLinesWithGLAccHasCorrectJobLedgerEntryNo()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        PostedDocumentNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 235814] Sales Credit Memo created for two Job Planning Lines with G/L Account has correct Job Ledger Entry No. in Job Planning Line Invoice

        Initialize();

        // [GIVEN] Job with two identical Job Planning Lines with G/L Accounts
        CreateJob(Job, '', false);
        LibraryJob.CreateJobTask(Job, JobTask);
        for i := 1 to 2 do begin
            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
            JobPlanningLine.Validate(Quantity, -JobPlanningLine.Quantity);
            JobPlanningLine.Modify(true);
        end;
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");

        // [WHEN] Post Sales Credit Memo
        Commit();
        JobPlanningLine.FindSet();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, true);
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two Job Ledger Entries generated - "X" and "Y"
        // [THEN] Two Job Planning Line Invoice records created, first corresponds to "X", second to "Y"
        VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(
          JobPlanningLine, JobPlanningLineInvoice."Document Type"::"Posted Credit Memo", PostedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure JobItemCostUpdatedOnAutomaticCostAdjustment()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnitCost: Decimal;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Update Job Item Cost]
        // [SCENARIO 234898] Cost amount in job ledger entries should be updated when item cost is automatically adjusted on invoice posting, and automatic update of job item cost is enabled

        Initialize();

        // [GIVEN] Enable automatic cost adjustment and automatic update job item cost
        LibraryInventory.SetAutomaticCostAdjmtAlways();
        LibraryJob.SetAutomaticUpdateJobItemCost(true);

        // [GIVEN] Item "I" with no cost amount defined
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create purchase order for item "I" and post receipt
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Post a billable job journal line for item "I"
        CreateJobWithJobTask(JobTask);
        CreatePostJobJournalLineWithItem(JobTask, Item."No.");

        // [GIVEN] Reopen the purchase order and update direct unit cost to "10"
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        UnitCost := LibraryRandom.RandInt(100);
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] "Unit Cost" in the item card "I" is "10"
        Item.Find();
        Item.TestField("Unit Cost", UnitCost);

        // [THEN] "Unit Cost" in the job ledger entry created from the job journal is "10"
        VerifyJobLedgerEntryUnitCost(JobTask, Item."No.", UnitCost);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostServiceItemPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Item] [Non-Inventoriable] [Update Job Item Cost]
        // [SCENARIO 252306] "Update Job Item Cost" batch job should copy non-inventoriable cost amount to job ledger entries when updating entries for an item with Type = Service

        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service"
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Purchase order for item "I" with assigned job, "Line Amount" = "X". Receive and Invoice the order.
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderAssignJob(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.", JobTask);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "Update Job Item Cost"
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // [THEN] "Total Cost" in job ledger entry is "X"
        VerifyJobLedgerEntry(PostedDocNo, JobTask."Job No.", PurchaseLine."Line Amount", JobLedgerEntry.FieldNo("Total Cost"));
        VerifyJobLedgerEntry(PostedDocNo, JobTask."Job No.", PurchaseLine."Line Amount", JobLedgerEntry.FieldNo("Total Cost (LCY)"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostServiceItemReceiveAndInvoicePurchOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Service Item] [Non-Inventoriable] [Update Job Item Cost]
        // [SCENARIO 252306] "Update Job Item Cost" batch job should update job entries for an item with Type = Service when it is received, then invoiced

        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service"
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Purchase order for item "I" with assigned job, "Line Amount" = "X". Receive the order without invoicing.
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderAssignJob(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.", JobTask);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Reopen the purchase order and update unit cost. New line amount is "Y"
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Unit Cost" * LibraryRandom.RandIntInRange(2, 5));
        PurchaseLine.Modify(true);

        // [GIVEN] Post invoice
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run "Update Job Item Cost"
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // [THEN] "Total Cost" in job ledger entry is "Y"
        VerifyJobLedgerEntry(PostedDocNo, JobTask."Job No.", PurchaseLine."Line Amount", JobLedgerEntry.FieldNo("Total Cost"));
        VerifyJobLedgerEntry(PostedDocNo, JobTask."Job No.", PurchaseLine."Line Amount", JobLedgerEntry.FieldNo("Total Cost (LCY)"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostItemCharge()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ValueEntry: Record "Value Entry";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Update Job Item Cost] [Item Charge]
        // [SCENARIO 252306] "Update Job Item Cost" should carry item charge amount from purchase entry to the applied job consumption entry

        Initialize();

        // [GIVEN] Item "I" with "Type" = "Inventory"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order for item "I" with assigned job, "Line Amount" = "X". Receive and invoice the order.
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderAssignJob(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.", JobTask);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", Item."No.");
        PurchRcptLine.FindFirst();

        // [GIVEN] Assign item charge to the posted purchase receipt. Charge amount is "Y".
        CreateItemCharge(ItemCharge, PurchaseHeader."Buy-from Vendor No.");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", Item."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Run "Adjust Cost - Item Entries" batch job
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Run "Update Job Item Cost"
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // [THEN] "Total Cost" in job ledger entry is "X" + "Y"
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.CalcSums("Cost Amount (Actual)");

        VerifyJobLedgerEntry(PostedDocNo, JobTask."Job No.", ValueEntry."Cost Amount (Actual)", JobLedgerEntry.FieldNo("Total Cost"));
        VerifyJobLedgerEntry(PostedDocNo, JobTask."Job No.", ValueEntry."Cost Amount (Actual)", JobLedgerEntry.FieldNo("Total Cost (LCY)"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateJobItemCostServiceItemJobJournal()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // [FEATURE] [Service Item] [Non-Inventoriable] [Update Job Item Cost] [Job Journal]
        // [SCENARIO 252306] "Update Job Item Cost" batch job should copy non-inventoriable cost amount to job ledger entries when for an item with Type = Service when usage is posted via job journal

        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service"
        LibraryInventory.CreateServiceTypeItem(Item);

        // [GIVEN] Post usage of item "I" via the job journal. "Line Amount" = "X"
        CreateJobWithJobTask(JobTask);
        CreateJobJournalLineWithItem(JobJournalLine, JobTask, Item."No.");
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);

        // [WHEN] Run "Update Job Item Cost"
        LibraryJob.RunUpdateJobItemCost(JobTask."Job No.");

        // [THEN] "Total Cost" in job ledger entry is "X"
        VerifyJobLedgerEntry(
          JobJournalLine."Document No.", JobTask."Job No.", JobJournalLine."Total Cost", JobLedgerEntry.FieldNo("Total Cost"));
        VerifyJobLedgerEntry(
          JobJournalLine."Document No.", JobTask."Job No.", JobJournalLine."Total Cost (LCY)", JobLedgerEntry.FieldNo("Total Cost (LCY)"));
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferSortedByQtyToTransfer()
    var
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Invoice] [Job Planning] [Sales]
        // [SCENARIO 316575] Sales invoice lines are created for multiple Job Planning Lines sorted by "Qty. to Transfer to Invoice" descending
        Initialize();

        // [GIVEN] Crated Job with two Job planning Lines, Quantity on JobPlanningLine2 is greater
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine1);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine2);
        JobPlanningLine2.Validate(Quantity, JobPlanningLine1.Quantity * 2);
        JobPlanningLine2.Modify();

        // [GIVEN] Applied filters and descending sorting for JobPlanningLine2
        JobPlanningLine2.SetCurrentKey("Qty. to Transfer to Invoice");
        JobPlanningLine2.SetAscending("Qty. to Transfer to Invoice", false);
        JobPlanningLine2.SetFilter("Job No.", JobPlanningLine1."Job No.");

        // [WHEN] Invoke Create Sales Invoice
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine2, false);

        // [THEN] Sales Invoice Lines created for both Job Planning Lines, including JobPlanningLine1
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesLine.SetRange("Job No.", JobTask."Job No.");
        Assert.AreEqual(2, SalesLine.Count, '');
        SalesLine.SetRange("No.", JobPlanningLine1."No.");
        SalesLine.FindFirst();
        Assert.AreEqual(JobPlanningLine1.Quantity, SalesLine."Qty. to Invoice", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesArchiveJobTaskNo()
    var
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 292637] Job related fields are copied to sales archive
        Initialize();

        // [GIVEN] Crated Job with Job task "JT"
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create sales order with Job task "JT"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Job No.", JobTask."Job No.");
        SalesLine.Validate("Job Task No.", JobTask."Job Task No.");
        SalesLine."Job Contract Entry No." := LibraryRandom.RandIntInRange(10, 100); // mock entry number
        SalesLine.Modify();

        // [WHEN] Sales order is being archived
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [THEN] Sales Line Archive created with same job related fields
        SalesLineArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeader."No.");
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Job Task No.", JobTask."Job Task No.");
        SalesLineArchive.TestField("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseArchiveJobTaskNo()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineArchive: Record "Purchase Line Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 292637] Job Task No. field is copied to purchase archive
        Initialize();

        // [GIVEN] Crated Job with Job task "JT"
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create purchase order with Job task "JT"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        MockPurchaseLineJobRelatedFields(PurchaseLine);
        PurchaseLine.Modify();

        // [WHEN] Purchase order is being archived
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);

        // [THEN] Purchase Line Archive created with same job related fields
        PurchaseLineArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLineArchive.FindFirst();
        VerifyPurchaseLineArchive(PurchaseLine, PurchaseLineArchive);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceForCustomerWithShipToCodeRespectsAddress()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 373670] When creating Sales Invoice from Job Planning line for Customer with alternative Ship-to Code that codes Ship-to Address is used.
        Initialize();

        // [GIVEN] Customer has address "XXX" and alternate Ship-to Code with a ship-to address "YYY"
        CreateCustomerWithAlternateShipToCode(Customer, ShipToAddress);

        // [GIVEN] Job for a customer created
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Job Task with Item job planning line
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, LibraryJob.ItemType(), JobTask, JobPlanningLine);
        Commit();

        // [WHEN] Create Sales Invoice for job planning line
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Ship-to Address of Sales Invoice is "YYY"
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
        SalesHeader.TestField("Ship-to Address", ShipToAddress.Address);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceJobPlanningLinesCopiedCountryRegionCodeAndCounty()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        BillToCountryRegion: Record "Country/Region";
        BillToCountyCode: Code[10];
        SellToCountryRegion: Record "Country/Region";
        SellToCountyCode: Code[10];
        ShipToCountryRegion: Record "Country/Region";
        ShipToCountyCode: Code[10];
    begin
        // [SCENARIO 385236] Sales Invoice created for  Job Planning Lines has correct County and Country/Region Code
        Initialize();

        // [GIVEN] Create Country Region and County Code
        LibraryERM.CreateCountryRegion(BillToCountryRegion);
        BillToCountryRegion.Validate("Address Format", BillToCountryRegion."Address Format"::"City+County+Post Code");
        BillToCountryRegion.Modify(true);
        BillToCountyCode := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(BillToCountyCode));

        LibraryERM.CreateCountryRegion(SellToCountryRegion);
        SellToCountryRegion.Validate("Address Format", SellToCountryRegion."Address Format"::"City+County+Post Code");
        SellToCountryRegion.Modify(true);
        SellToCountyCode := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(SellToCountyCode));

        LibraryERM.CreateCountryRegion(ShipToCountryRegion);
        ShipToCountryRegion.Validate("Address Format", ShipToCountryRegion."Address Format"::"City+County+Post Code");
        ShipToCountryRegion.Modify(true);
        ShipToCountyCode := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(ShipToCountyCode));

        // [GIVEN] Job with Country Region and County Code, two identical Job Planning Lines with G/L Accounts
        CreateJob(Job, '', false);

        Job.Validate("Sell-to Country/Region Code", SellToCountryRegion.Code);
        Job.Validate("Sell-to County", SellToCountyCode);

        Job.Validate("Bill-to Country/Region Code", BillToCountryRegion.Code);
        Job.Validate("Bill-to County", BillToCountyCode);

        Job.Validate("Ship-to Country/Region Code", ShipToCountryRegion.Code);
        Job.Validate("Ship-to County", ShipToCountyCode);

        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        Commit();

        // [WHEN] Create Sales Invoice from Job
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);

        // [THEN] Field "Bill-to County" is filled from Job in Sales Header
        // [THEN] Field "Sell-to County" is filled from Job in Sales Header
        // [THEN] Field "Ship-to County" is filled from Job in Sales Header
        // [THEN] Field "Bill-to Country/Region Code" is filled from Job in Sales Header
        // [THEN] Field "Sell-to Country/Region Code" is filled from Job in Sales Header
        // [THEN] Field "Ship-to Country/Region Code" is filled from Job in Sales Header
        SalesHeader.TestField("Bill-to County", BillToCountyCode);
        SalesHeader.TestField("Sell-to County", SellToCountyCode);
        SalesHeader.TestField("Ship-to County", ShipToCountyCode);
        SalesHeader.TestField("Bill-to Country/Region Code", BillToCountryRegion.Code);
        SalesHeader.TestField("Sell-to Country/Region Code", SellToCountryRegion.Code);
        SalesHeader.TestField("Ship-to Country/Region Code", ShipToCountryRegion.Code);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    procedure CreateSalesInvoiceFromSelectedJobPlanningLines()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        Qty: Decimal;
    begin
        // [FEATURE] [Invoice] [Job Planning] [Sales]
        // [SCENARIO 396007] "Create Sales Invoice" function works properly for a job planning line filtered with "Qty. to Transfer to Invoice" > 0.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Job with job task and job planning line.
        // [GIVEN] "Qty. to Transfer to Invoice" on the job planning line = 1.
        CreateJob(Job, '', false);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, Qty);

        // [GIVEN] Set filter "Qty. to Transfer to Invoice" > 0 on job planning lines.
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetFilter("Qty. to Transfer to Invoice", '>%1', 0);

        // [WHEN] Run "Create Sales Invoice" for the filtered job planning line.
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] The job planning line has been transferred to a sales invoice line.
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    procedure InvoicedAmountOnJobPlanningLineEqualToSalesInvoiceInLCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        Qty: Decimal;
        QtyToInvoice: Decimal;
        UnitPrice: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Job Planning Line] [Sales Invoice] [Rounding]
        // [SCENARIO 395872] Invoiced Amount (LCY) on job planning line is equal to the amount of the sales invoice created for this line. A scenario for local currency (LCY).
        Initialize();
        Qty := 500;
        QtyToInvoice := 408;
        UnitPrice := 38.21951;

        // [GIVEN] Set "Unit-Amount Rounding Precision" in G/L Setup to 3 decimal digits.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unit-Amount Rounding Precision", 0.001);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Job with job task.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Job planning line, Quantity = 500, "Qty. to Transfer to Invoice" = 408.
        // [GIVEN] Set "Unit Price" = 38.21951.
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, QtyToInvoice);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Create sales invoice for the job planning line.
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [WHEN] Post the sales invoice.
        SalesHeader.SetRange("Bill-to Customer No.", Job."Bill-to Customer No.");
        SalesHeader.FindFirst();
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Invoiced Amount (LCY)" is equal to the sales invoice amount, which is 38.21951 * 408 = 15593.56.
        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceHeader.CalcFields(Amount);
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice", "Invoiced Amount (LCY)");
        JobPlanningLine.TestField("Qty. Transferred to Invoice", QtyToInvoice);
        JobPlanningLine.TestField("Invoiced Amount (LCY)", SalesInvoiceHeader.Amount);
        JobPlanningLine.TestField("Invoiced Amount (LCY)", Round(QtyToInvoice * UnitPrice, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    procedure InvoicedAmountOnJobPlanningLineEqualToSalesInvoiceInFCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        Qty: Decimal;
        QtyToInvoice: Decimal;
        UnitPrice: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Job Planning Line] [Sales Invoice] [Rounding] [Currency]
        // [SCENARIO 395872] Invoiced Amount (LCY) on job planning line is equal to the amount of the sales invoice created for this line. A scenario for foreign currency (FCY).
        Initialize();
        Qty := 500;
        QtyToInvoice := 408;
        UnitPrice := 38.21951;

        // [GIVEN] Set "Unit-Amount Rounding Precision" in G/L Setup to 3 decimal digits.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unit-Amount Rounding Precision", 0.001);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Job with job task.
        // [GIVEN] Set currency code = "FCY" on the job. Currency exchange rate = 1.0.
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1.0, 1.0));
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Job planning line, Quantity = 500, "Qty. to Transfer to Invoice" = 408.
        // [GIVEN] Set "Unit Price" = 38.21951.
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, QtyToInvoice);
        JobPlanningLine.Validate("Unit Price", UnitPrice);
        JobPlanningLine.Modify(true);

        // [GIVEN] Create sales invoice for the job planning line.
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [WHEN] Post the sales invoice.
        SalesHeader.SetRange("Bill-to Customer No.", Job."Bill-to Customer No.");
        SalesHeader.FindFirst();
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Invoiced Amount (LCY)" is equal to the sales invoice amount, which is 38.21951 * 408 = 15593.56.
        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceHeader.CalcFields(Amount);
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice", "Invoiced Amount (LCY)");
        JobPlanningLine.TestField("Qty. Transferred to Invoice", QtyToInvoice);
        JobPlanningLine.TestField("Invoiced Amount (LCY)", SalesInvoiceHeader.Amount);
        JobPlanningLine.TestField("Invoiced Amount (LCY)", Round(QtyToInvoice * UnitPrice, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUsesSellToBillToShipToFields()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [SCENARIO] When creating Sales Invoice from Job Planning line the sell-to/bill-to/ship-to fields from the job
        //  should be used for filling out the sales invoice.
        Initialize();

        // [GIVEN] Sell-to customer with a shipping address and a bill-to customer.
        LibrarySales.CreateCustomer(SellToCustomer);
        LibrarySales.CreateCustomerAddress(SellToCustomer);
        LibrarySales.CreateCustomer(BillToCustomer);

        // [GIVEN] Job for a customers created
        LibraryJob.CreateJob(Job, SellToCustomer."No.");
        Job.Validate("Bill-to Customer No.", BillToCustomer."No.");
        Job.Modify(true);

        // [GIVEN] Job Task with Item job planning line
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, LibraryJob.ItemType(), JobTask, JobPlanningLine);
        Commit();

        // [WHEN] Create Sales Invoice for job planning line
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Sell-to, bill-to and ship-to fields from the job are used.
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
        SalesHeader.TestField("Sell-to Customer No.", SellToCustomer."No.");
        SalesHeader.TestField("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.TestField("Ship-to Address", SellToCustomer.Address);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUsesPaymentFields()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [SCENARIO] When creating Sales Invoice from Job Planning line the payment fields from the job
        //  should be used for filling out the sales invoice.
        Initialize();

        // [GIVEN] Job with payment fields set.
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryJob.CreateJob(Job);
        Job.Validate("Payment Method Code", PaymentMethod.Code);
        Job.Validate("Payment Terms Code", PaymentTerms.Code);
        Job.Modify(true);

        // [GIVEN] Job Task with Item job planning line
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, LibraryJob.ItemType(), JobTask, JobPlanningLine);
        Commit();

        // [WHEN] Create Sales Invoice for job planning line
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        // [THEN] Payment fields from the job are used.
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
        SalesHeader.TestField("Payment Method Code", PaymentMethod.Code);
        SalesHeader.TestField("Payment Terms Code", PaymentTerms.Code);
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure JobLedgerEntryNoWhenPostSalesInvoiceForMultJobPlanLinesWithGLAccount()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        JobPlanningLineToCheck: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 419117] Job Ledger Entry No. on Job Planning Line Invoice record when create one Sales Invoice for Job Planning Lines with G/L Account from multiple Jobs in random order.
        Initialize();

        // [GIVEN] Three Jobs "J1", "J2", "J3" for one Customer. Each Job has one Job Planning Line "P1" / "P2" / "P3" with G/L Account.
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 3 do begin
            LibraryJob.CreateJob(Job, CustomerNo);
            LibraryJob.CreateJobTask(Job, JobTask);
            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine[i]);
        end;
        Commit();

        // [GIVEN] Sales Invoice "I" created from Job Planning Line "P3".
        CreateOrAppendToSalesDocument(JobPlanningLine[3], true, '', false);
        GetSalesDocument(JobPlanningLine[3], SalesHeader."Document Type"::Invoice, SalesHeader);

        // [GIVEN] Sales Lines are created from Job Planning Lines "P1" and "P2" and appended to Invoice "I".
        CreateOrAppendToSalesDocument(JobPlanningLine[1], false, SalesHeader."No.", false);
        CreateOrAppendToSalesDocument(JobPlanningLine[2], false, SalesHeader."No.", false);

        // [WHEN] Post Sales Invoice "I".
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Three Job Ledger Entries with Entry No. 21, 22, 23 were created. Entry 21 has Job No. "J3", entry 22 - "J2", entry 23 - "J1".
        // [THEN] Three Job Planning Line Invoice records were created. First has Job No. "J1" and Job Ledger Entry No. 23; second "J2" and 22; third "J3" and 21.
        JobPlanningLineToCheck.SetRange("Job No.", JobPlanningLine[1]."Job No.", JobPlanningLine[3]."Job No.");
        VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(
            JobPlanningLineToCheck, JobPlanningLineInvoice."Document Type"::"Posted Invoice", PostedDocumentNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesCrMemoRequestPageHandler,MessageHandler')]
    procedure JobLedgerEntryNoWhenPostSalesCrMemoForMultJobPlanLinesWithGLAccount()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        JobPlanningLineToCheck: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 419117] Job Ledger Entry No. on Job Planning Line Invoice record when create one Sales Credit Memo for Job Planning Lines with G/L Account from multiple Jobs in random order.
        Initialize();

        // [GIVEN] Three Jobs "J1", "J2", "J3" for one Customer. Each Job has one Job Planning Line "P1" / "P2" / "P3" with G/L Account.
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 3 do begin
            LibraryJob.CreateJob(Job, CustomerNo);
            LibraryJob.CreateJobTask(Job, JobTask);
            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine[i]);
            JobPlanningLine[i].Validate(Quantity, -JobPlanningLine[i].Quantity);
            JobPlanningLine[i].Modify(true);
        end;
        Commit();

        // [GIVEN] Sales Credit Memo "I" created from Job Planning Line "P3".
        CreateOrAppendToSalesDocument(JobPlanningLine[3], true, '', true);
        GetSalesDocument(JobPlanningLine[3], SalesHeader."Document Type"::"Credit Memo", SalesHeader);

        // [GIVEN] Sales Lines are created from Job Planning Lines "P1" and "P2" and appended to Invoice "I".
        CreateOrAppendToSalesDocument(JobPlanningLine[1], false, SalesHeader."No.", true);
        CreateOrAppendToSalesDocument(JobPlanningLine[2], false, SalesHeader."No.", true);

        // [WHEN] Post Sales Credit Memo "I".
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Three Job Ledger Entries with Entry No. 21, 22, 23 were created. Entry 21 has Job No. "J3", entry 22 - "J2", entry 23 - "J1".
        // [THEN] Three Job Planning Line Invoice records were created. First has Job No. "J1" and Job Ledger Entry No. 23; second "J2" and 22; third "J3" and 21.
        JobPlanningLineToCheck.SetRange("Job No.", JobPlanningLine[1]."Job No.", JobPlanningLine[3]."Job No.");
        VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(
            JobPlanningLineToCheck, JobPlanningLineInvoice."Document Type"::"Posted Credit Memo", PostedDocumentNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceRequestPageHandler,MessageHandler')]
    procedure JobLedgerEntryNoWhenPostSalesInvoiceForMultJobPlanLinesWithResource()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        JobPlanningLineToCheck: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 419117] Job Ledger Entry No. on Job Planning Line Invoice record when create one Sales Invoice for Job Planning Lines with Resource from multiple Jobs in random order.
        Initialize();

        // [GIVEN] Three Jobs "J1", "J2", "J3" for one Customer. Each Job has one Job Planning Line "P1" / "P2" / "P3" with Resource.
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 3 do begin
            LibraryJob.CreateJob(Job, CustomerNo);
            LibraryJob.CreateJobTask(Job, JobTask);
            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine[i]);
        end;
        Commit();

        // [GIVEN] Sales Invoice "I" created from Job Planning Line "P3".
        CreateOrAppendToSalesDocument(JobPlanningLine[3], true, '', false);
        GetSalesDocument(JobPlanningLine[3], SalesHeader."Document Type"::Invoice, SalesHeader);

        // [GIVEN] Sales Lines are created from Job Planning Lines "P1" and "P2" and appended to Invoice "I".
        CreateOrAppendToSalesDocument(JobPlanningLine[1], false, SalesHeader."No.", false);
        CreateOrAppendToSalesDocument(JobPlanningLine[2], false, SalesHeader."No.", false);

        // [WHEN] Post Sales Invoice "I".
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Three Job Ledger Entries with Entry No. 21, 22, 23 were created. Entry 21 has Job No. "J3", entry 22 - "J2", entry 23 - "J1".
        // [THEN] Three Job Planning Line Invoice records were created. First has Job No. "J1" and Job Ledger Entry No. 23; second "J2" and 22; third "J3" and 21.
        JobPlanningLineToCheck.SetRange("Job No.", JobPlanningLine[1]."Job No.", JobPlanningLine[3]."Job No.");
        VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(
            JobPlanningLineToCheck, JobPlanningLineInvoice."Document Type"::"Posted Invoice", PostedDocumentNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesCrMemoRequestPageHandler,MessageHandler')]
    procedure JobLedgerEntryNoWhenPostSalesCrMemoForMultJobPlanLinesWithResource()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        JobPlanningLineToCheck: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 419117] Job Ledger Entry No. on Job Planning Line Invoice record when create one Sales Credit Memo for Job Planning Lines with Resource from multiple Jobs in random order.
        Initialize();

        // [GIVEN] Three Jobs "J1", "J2", "J3" for one Customer. Each Job has one Job Planning Line "P1" / "P2" / "P3" with Resource.
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to 3 do begin
            LibraryJob.CreateJob(Job, CustomerNo);
            LibraryJob.CreateJobTask(Job, JobTask);
            LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine[i]);
            JobPlanningLine[i].Validate(Quantity, -JobPlanningLine[i].Quantity);
            JobPlanningLine[i].Modify(true);
        end;
        Commit();

        // [GIVEN] Sales Credit Memo "I" created from Job Planning Line "P3".
        CreateOrAppendToSalesDocument(JobPlanningLine[3], true, '', true);
        GetSalesDocument(JobPlanningLine[3], SalesHeader."Document Type"::"Credit Memo", SalesHeader);

        // [GIVEN] Sales Lines are created from Job Planning Lines "P1" and "P2" and appended to Invoice "I".
        CreateOrAppendToSalesDocument(JobPlanningLine[1], false, SalesHeader."No.", true);
        CreateOrAppendToSalesDocument(JobPlanningLine[2], false, SalesHeader."No.", true);

        // [WHEN] Post Sales Credit Memo "I".
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Three Job Ledger Entries with Entry No. 21, 22, 23 were created. Entry 21 has Job No. "J3", entry 22 - "J2", entry 23 - "J1".
        // [THEN] Three Job Planning Line Invoice records were created. First has Job No. "J1" and Job Ledger Entry No. 23; second "J2" and 22; third "J3" and 21.
        JobPlanningLineToCheck.SetRange("Job No.", JobPlanningLine[1]."Job No.", JobPlanningLine[3]."Job No.");
        VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(
            JobPlanningLineToCheck, JobPlanningLineInvoice."Document Type"::"Posted Credit Memo", PostedDocumentNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,ConfirmHandlerMultipleResponses,MessageHandler')]
    procedure JobToSalesInvPriceInclVATDiff()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        DimensionValue: array[2] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobTaskDimension: Record "Job Task Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DimValueCode: Code[20];
        DimensionSetID: Integer;
    begin
        // [SCENARIO 424833] Dimension of Sales Line created from Job Task should not depend on Customer "Prices Including VAT" value
        Initialize();

        // [GIVEN] Customer "C" with Default Dimension Value = "DDV1" and Prices Including VAT = false
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Prices Including VAT", false);
        Customer.Modify();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionCustomer(
            DefaultDimension, Customer."No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        DimValueCode := DimensionValue[1].Code;

        // [GIVEN] Job with Job Task and Job Planning Line and Default Dimension Value = "DDV2"
        CreateJobWithJobTask(JobTask);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        Job.Get(JobTask."Job No.");
        Job.Validate("Sell-to Customer No.", Customer."No.");
        Job.Modify();
        CreateJobTaskGlobalDim(JobTaskDimension, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        Commit();

        // [WHEN] Create Sales Invoice from Job Planning Line
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();

        // [THEN] Sales Line of created Invoice has Dimension Value = "DDV2"
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        DimensionSetID := SalesLine."Dimension Set ID";
        FindDimensionSetEntryByCode(DimensionSetEntry, DimensionSetID, JobTaskDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", JobTaskDimension."Dimension Value Code");

        SalesHeader.Delete(true); // Delete created Sales Invoice

        // [GIVEN] Customer "C" with Prices Including VAT = true
        Customer.Find();
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify();
        Commit();

        // [WHEN] Create Sales Invoice from Job Planning Line
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();

        // [THEN] Sales Line of created Invoice has Dimension Value = "DDV2"
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        DimensionSetID := SalesLine."Dimension Set ID";
        FindDimensionSetEntryByCode(DimensionSetEntry, DimensionSetID, JobTaskDimension."Dimension Code");
        DimensionSetEntry.TestField("Dimension Value Code", JobTaskDimension."Dimension Value Code");
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    procedure CancellingSalesCreditMemoCreatesCorrectingJobPlanningLine()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
    begin
        Initialize();

        // [SCENARIO] When cancelling a credit memo linked to a job, a corrective job planning line should be created.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] A job for a customer with one job planning line.
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(
            JobPlanningLine."Line Type"::Billable, LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify();
        Commit();

        // [GIVEN] A posted sales invoice for the job planning line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Cancelling the posted sales invoice.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [WHEN] Cancelling the posted sales credit memo.
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesCrMemoHeader.FindFirst();
        CancelPostedSalesCrMemo.CancelPostedCrMemo(SalesCrMemoHeader);

        // [THEN] Three job planning lines exists in total.
        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        Assert.AreEqual(3, JobPlanningLine.Count(), 'Expected three job planning lines.');

        // [THEN] A job planning line for the sales invoice exist.
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesInvoiceLine."Job Contract Entry No.");
        Assert.AreEqual(1, JobPlanningLine.Count(), 'Expected one job planning line.');
        JobPlanningLine.FindFirst();
        Assert.AreEqual(1, JobPlanningLine.Quantity, 'Expected quantity to be 1.');

        // [THEN] A job planning line for the sales credit memo exist.
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.FindFirst();
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesCrMemoLine."Job Contract Entry No.");
        Assert.AreEqual(1, JobPlanningLine.Count(), 'Expected one job planning line.');
        JobPlanningLine.FindFirst();
        Assert.AreEqual(-1, JobPlanningLine.Quantity, 'Expected quantity to be -1.');

        // [THEN] A job planning line for the correcting sales invoice exists.
        SalesInvoiceHeader.SetRange("Applies-to Doc. Type", SalesInvoiceHeader."Applies-to Doc. Type"::"Credit Memo");
        SalesInvoiceHeader.SetRange("Applies-to Doc. No.", SalesCrMemoHeader."No.");
        SalesInvoiceHeader.FindFirst();

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        JobPlanningLine.SetRange("Job Contract Entry No.", SalesInvoiceLine."Job Contract Entry No.");
        Assert.AreEqual(1, JobPlanningLine.Count(), 'Expected one job planning line.');
        JobPlanningLine.FindFirst();
        Assert.AreEqual(1, JobPlanningLine.Quantity, 'Expected quantity to be 1.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,TransferToInvoiceHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CalcWIPToGLUpdatesJobLedgerWhenUsageQuantityIsReturned()
    begin
        // [SCENARIO] Calculate WIP and posted to G/L when consumed quantity on a task is returned
        Initialize();
        CalculateWIPWithReturnedJobUsage(1, -1, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,TransferToInvoiceHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CalcWIPToGLUpdatesJobLedgerWhenUsageQuantityIsReturnedPartially()
    begin
        // [SCENARIO] Calculate WIP with posting to G/L when consumed quantity on a task is partially returned
        Initialize();
        CalculateWIPWithReturnedJobUsage(4, -1, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerMultipleResponses,MessageHandler,TransferToInvoiceHandler,TransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure CalcWIPUpdatesJobLedgerWhenUsageQuantityIsReturned()
    begin
        // [SCENARIO] Calculate WIP without posting to G/L when consumed quantity on a task is returned
        Initialize();
        CalculateWIPWithReturnedJobUsage(1, -1, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure VerifyJobExternalDocNoAndYourReferenceFieldOnSalesInvoice()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [SCENARIO 453005] External Document No. and Your Reference field in the Job Card are not transferred to Sales Invoice
        Initialize();

        // [GIVEN] Create Job with Job Planning Lines with G/L Accounts
        CreateJob(Job, '', false);
        Job.Validate("External Document No.", CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(Job."External Document No.")));
        Job.Validate("Your Reference", CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(Job."Your Reference")));
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.GLAccountType(), JobTask, JobPlanningLine);
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        Commit();

        // [WHEN] Create Sales Invoice
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);

        // [VERIFY] Verify External Document No. and Your Reference on Sales Invoice        
        Assert.AreEqual(Job."External Document No.", SalesHeader."External Document No.", StrSubstNo(ExtDocNoErr, Job.TableCaption(), SalesHeader.TableCaption));
        Assert.AreEqual(Job."Your Reference", SalesHeader."Your Reference", StrSubstNo(YourReferenceErr, Job.TableCaption(), SalesHeader.TableCaption));
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    procedure VerifyPostedSalesInvoiceCreatedFromJobPlanningLineIsCanceled()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 454741] Verify Cancel Posted Sales Invoice created from Job Planning Line, with updated Unit Cost, for Item with Standard costing method
        Initialize();

        // [GIVEN] Create Item with Standard Cost      
        CreateItemWithStandardCost(Item);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [GIVEN] Update Unit Cost on Job Planning Line
        JobPlanningLine.Validate("Unit Cost", Item."Standard Cost" + 1);
        JobPlanningLine.Modify(true);

        // [GIVEN] Create new Sales Invoice from Job Planning Line                
        TransferJobPlanningLine(JobPlanningLine, JobPlanningLine.Quantity, false, SalesHeader);

        // [GIVEN] Post Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Cancel Posted Sales Invoice
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // [THEN] Verify additional Job Planning Line is created with updated Unit Cost
        FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine);
        ReversedJobPlanningLine.TestField(Quantity, -JobPlanningLine.Quantity);
        ReversedJobPlanningLine.TestField("Unit Cost (LCY)", JobPlanningLine."Unit Cost (LCY)");
        ReversedJobPlanningLine.TestField("Unit Cost", JobPlanningLine."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('TransferSalesCreditMemoReportWithDatesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DatesPropagateFromTransferRequestPageToSalesCreditMemo()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobTask: Record "Job Task";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        PostingDate, DocumentDate : Date;
    begin
        // [SCENARIO 474989] New Document date field in Transfer Job Create Invoice request page
        // [GIVEN] New job, job task, dates
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), JobTask, JobPlanningLine);
        PostingDate := WorkDate() + 20;
        DocumentDate := WorkDate() + 10;
        Commit();

        // [WHEN] Sales credit memo created via "Job Transfer to Credit Memo" request page, where the fields for dates are set manually
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, true);
        GetSalesHeaderFromJobPlanningLine(JobPlanningLine, SalesHeader, false);

        // [THEN] The dates correctly propagate from the request page to the created Sales Credit Memo
        Assert.AreEqual(PostingDate, SalesHeader."Posting Date", 'Wrong Posting Date on created job sales credit memo.');
        Assert.AreEqual(DocumentDate, SalesHeader."Document Date", 'Wrong Document Date on created job sales credit memo.');

        JobPlanningLine.Delete();
        SalesHeader.Delete();
        JobTask.Delete();
    end;

    [Test]
    [HandlerFunctions('CreateSalesInvoiceReportWithDatesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DatesPropagateFromCreateRequestPageToSalesInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobTask: Record "Job Task";
        PostingDate, DocumentDate : Date;
    begin
        // [SCENARIO 474989] New Document date field in Create Job Sales Invoice request page
        // [GIVEN] New job, job task, dates
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), JobTask, JobPlanningLine);
        PostingDate := WorkDate() + 20;
        DocumentDate := WorkDate() + 10;

        // [WHEN] Sales invoice created via "Job Create Sales Invoice" request page, where the fields for dates are set manually
        CreateSalesInvoiceWithDates(SalesHeader, JobTask, PostingDate, DocumentDate);

        // [THEN] The dates correctly propagates from the request page to the created Sales Invoice
        Assert.AreEqual(PostingDate, SalesHeader."Posting Date", 'Wrong Posting Date on created job sales invoice');
        Assert.AreEqual(DocumentDate, SalesHeader."Document Date", 'Wrong Document Date on created job sales invoice');

        SalesHeader.Delete();
        JobTask.Delete();
    end;

    [Test]
    [HandlerFunctions('TransferSalesInvoiceReportWithDatesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DatesPropagateFromTransferRequestPageToSalesInvoice()
    var
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobTask: Record "Job Task";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        PostingDate, DocumentDate : Date;
    begin
        // [SCENARIO 474989] New Document date field in Transfer Job Sales Invoice request page
        // [GIVEN] New job, job task, dates
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.ItemType(), LibraryJob.PlanningLineTypeContract(), JobTask, JobPlanningLine);
        PostingDate := WorkDate() + 20;
        DocumentDate := WorkDate() + 10;
        Commit();

        // [WHEN] Sales invoice created via "Job Transfer to Sales Invoice" request page, where the fields for dates are set manually
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        GetSalesHeaderFromJobPlanningLine(JobPlanningLine, SalesHeader, true);

        // [THEN] The dates correctly propagates from the request page to the created Sales Invoice
        Assert.AreEqual(SalesHeader."Posting Date", PostingDate, 'Wrong Posting Date on created job sales invoice');
        Assert.AreEqual(SalesHeader."Document Date", DocumentDate, 'Wrong Document Date on created job sales invoice');

        SalesHeader.Delete();
        JobPlanningLine.Delete();
        JobTask.Delete();
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure DatesFollowSalesReceivablesSetupOnTransferToSalesInvoiceRequestPage_DatesLinked()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobTransferToSalesInvoiceReport: Report "Job Transfer to Sales Invoice";
    begin
        // [SCENARIO 474989] New Document date field in Job Transfer to Sales Invoice request page
        // [GIVEN] New date, setting on
        SalesReceivablesSetup.GetRecordOnce();
        SalesReceivablesSetup."Link Doc. Date To Posting Date" := true;
        SalesReceivablesSetup.Modify();
        Commit();

        // [WHEN] User inputs DocumentDate, then PostingDate in the report's request page
        JobTransferToSalesInvoiceReport.RunModal();

        // [THEN] The DocumentDate is equal to the PostingDate on the request page because of the setting
        // This is checked within the RequestPageHandler
    end;

    [Test]
    [HandlerFunctions('JobTransferToSalesInvoiceHandler2')]
    [Scope('OnPrem')]
    procedure DatesFollowSalesReceivablesSetupOnTransferToSalesInvoiceRequestPage_DatesNotLinked()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobTransferToSalesInvoiceReport: Report "Job Transfer to Sales Invoice";
    begin
        // [SCENARIO 474989] New Document date field in Job Transfer to Sales Invoice request page
        // [GIVEN] New date, setting off
        SalesReceivablesSetup.GetRecordOnce();
        SalesReceivablesSetup."Link Doc. Date To Posting Date" := false;
        SalesReceivablesSetup.Modify();
        Commit();

        // [WHEN] User inputs DocumentDate, then PostingDate in the report's request page
        JobTransferToSalesInvoiceReport.RunModal();

        // [THEN] The DocumentDate is not equal to the PostingDate on the request page because of the setting
        // This is checked within the RequestPageHandler
    end;

    [Test]
    [HandlerFunctions('CreateSalesInvoiceHandler')]
    [Scope('OnPrem')]
    procedure DatesFollowSalesReceivablesSetupOnCreateSalesInvoiceRequestPage_DatesLinked()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobCreateSalesInvoiceReport: Report "Job Create Sales Invoice";
    begin
        // [SCENARIO 474989] New Document date field in Job Create Sales Invoice request page
        // [GIVEN] New date, setting on
        SalesReceivablesSetup.GetRecordOnce();
        SalesReceivablesSetup."Link Doc. Date To Posting Date" := true;
        SalesReceivablesSetup.Modify();
        Commit();

        // [WHEN] User inputs DocumentDate, then PostingDate in the report's request page
        JobCreateSalesInvoiceReport.RunModal();

        // [THEN] The DocumentDate is equal to the PostingDate on the request page because of the setting
        // This is checked within the RequestPageHandler
    end;

    [Test]
    [HandlerFunctions('CreateSalesInvoiceHandler2')]
    [Scope('OnPrem')]
    procedure DatesFollowSalesReceivablesSetupOnCreateSalesInvoiceRequestPage_DatesNotLinked()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobCreateSalesInvoiceReport: Report "Job Create Sales Invoice";
    begin
        // [SCENARIO 474989] New Document date field in Job Create Sales Invoice request page
        // [GIVEN] New date, setting off
        SalesReceivablesSetup.GetRecordOnce();
        SalesReceivablesSetup."Link Doc. Date To Posting Date" := false;
        SalesReceivablesSetup.Modify();
        Commit();

        // [WHEN] User inputs DocumentDate, then PostingDate in the report's request page
        JobCreateSalesInvoiceReport.RunModal();

        // [THEN] The DocumentDate is not equal to the PostingDate on the request page because of the setting
        // This is checked within the RequestPageHandler
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoHandler')]
    [Scope('OnPrem')]
    procedure DatesFollowSalesReceivablesSetupOnTransferToCreditMemoRequestPage_DatesLinked()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobTransferToCreditMemoReport: Report "Job Transfer to Credit Memo";
    begin
        // [SCENARIO 474989] New Document date field in Job Transfer to Sales Invoice request page
        // [GIVEN] New date, setting on
        SalesReceivablesSetup.GetRecordOnce();
        SalesReceivablesSetup."Link Doc. Date To Posting Date" := true;
        SalesReceivablesSetup.Modify();
        Commit();

        // [WHEN] User inputs DocumentDate, then PostingDate in the report's request page
        JobTransferToCreditMemoReport.RunModal();

        // [THEN] The DocumentDate is equal to the PostingDate on the request page because of the setting
        // This is checked within the RequestPageHandler
    end;

    [Test]
    [HandlerFunctions('JobTransferToCreditMemoHandler2')]
    [Scope('OnPrem')]
    procedure DatesFollowSalesReceivablesSetupOnTransferToCreditMemoRequestPage_DatesNotLinked()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobTransferToCreditMemoReport: Report "Job Transfer to Credit Memo";
    begin
        // [SCENARIO 474989] New Document date field in Job Transfer to Sales Invoice request page
        // [GIVEN] New date, setting off
        SalesReceivablesSetup.GetRecordOnce();
        SalesReceivablesSetup."Link Doc. Date To Posting Date" := false;
        SalesReceivablesSetup.Modify();
        Commit();

        // [WHEN] User inputs DocumentDate, then PostingDate in the report's request page
        JobTransferToCreditMemoReport.RunModal();

        // [THEN] The DocumentDate is not equal to the PostingDate on the request page because of the setting
        // This is checked within the RequestPageHandler
    end;

    local procedure CreateJobAndJobTask(var JobTask: Record "Job Task")
    var
        Customer: Record Customer;
        Job: Record Job;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;


    local procedure CreateJobPlanningLineWithItem(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; LineType: Enum "Job Planning Line Line Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(LineType, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateItemWithStandardCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        Item.Modify(true);
    end;

    procedure CalculateWIPWithReturnedJobUsage(QuantityOnInvoice: Integer; QuantityOnCreditmemo: Integer; PostToGL: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine1: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        JobWIPMethod: Record "Job WIP Method";
        JobPostingGroup: Record "Job Posting Group";
        JobLedgerEntry: Record "Job Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        // [GIVEN] Journal template name is not mandatory for this test. This saves additional data setup. 
        GLSetup.Get();
        GLSetup.Validate("Journal Templ. Name Mandatory", false);
        GLSetup.Modify();

        // [GIVEN] Job WIP Method
        LibraryJob.CreateJobWIPMethod(JobWIPMethod);
        JobWIPMethod.Validate("Recognized Costs", JobWIPMethod."Recognized Costs"::"Usage (Total Cost)");
        JobWIPMethod.Validate("Recognized Sales", JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)");
        JobWIPMethod.Validate("WIP Cost", true);
        JobWIPMethod.Validate("WIP Sales", true);
        JobWIPMethod.Validate(Valid, true);
        JobWIPMethod.Modify(true);

        // [GIVEN] Job where the Job WIP Method is set to the above
        CreateJob(Job, '', false);
        Job.Validate("WIP Method", JobWIPMethod.Code);
        Job.Validate("WIP Posting Method", Job."WIP Posting Method"::"Per Job Ledger Entry");
        LibraryJob.CreateJobPostingGroup(JobPostingGroup);
        Job.Validate("Job Posting Group", JobPostingGroup.Code);
        Job.Modify(true);

        // [GIVEN] Job Task with 2 planning lines where consumed quantity is completely returned. Invoice for 1 and creditmemo for 1
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine1);
        JobPlanningLine1.Validate(Quantity, QuantityOnInvoice);
        JobPlanningLine1.Modify(true);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine2);
        JobPlanningLine2.Validate("No.", JobPlanningLine1."No.");
        JobPlanningLine2.Validate(Quantity, QuantityOnCreditmemo);
        JobPlanningLine2.Modify(true);

        // [GIVEN] Create Sales Invoice for the first line and post
        Commit();
        JobPlanningLine1.SetRecFilter();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine1, false);
        GetSalesDocument(JobPlanningLine1, SalesHeader."Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Calculate WIP and Post to G/L is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        if PostToGL then
            RunJobPostWIPToGL(Job);

        // [THEN] Verify Job Ledger Entry
        FindJobLedgerEntry(JobLedgerEntry, JobTask);
        if PostToGL then
            JobLedgerEntry.TestField("Amt. Posted to G/L", -JobPlanningLine1."Total Price")
        else
            JobLedgerEntry.TestField("Amt. to Post to G/L", -JobPlanningLine1."Total Price");
        JobLedgerEntry.CalcSums("Amt. to Post to G/L", "Amt. Posted to G/L");
        JobTask.Find();
        JobLedgerEntry.TestField("Amt. Posted to G/L", -JobTask."Recognized Sales G/L Amount");
        JobLedgerEntry.TestField("Amt. to Post to G/L", -JobTask."Recognized Sales Amount");
        //------------------------------------------------

        // [GIVEN] Create Sales Creditmemo for the second line and post
        JobPlanningLine2.SetRecFilter();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine2, true);
        GetSalesDocument(JobPlanningLine2, SalesHeader."Document Type"::"Credit Memo", SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Calculate WIP and Post to G/L is called
        LibraryVariableStorage.Enqueue(false);
        RunJobCalculateWIP(Job);
        if PostToGL then
            RunJobPostWIPToGL(Job);

        // [THEN] Verify Job Ledger Entry
        FindJobLedgerEntry(JobLedgerEntry, JobTask);
        JobLedgerEntry.CalcSums("Amt. to Post to G/L", "Amt. Posted to G/L");
        JobTask.Find();
        JobLedgerEntry.TestField("Amt. Posted to G/L", -JobTask."Recognized Sales G/L Amount");
        JobLedgerEntry.TestField("Amt. to Post to G/L", -JobTask."Recognized Sales Amount");
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,CreateSalesNotificationHandler')]
    procedure VerifyReversedJobPlanningLineForCorrectiveCreditMemoCreatedFromPostedSalesInvoice()
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        ReversedJobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [SCENARIO 484285] Verify Reversed Job Planning Line for Corrective Credit Memo created from Posted Sales Invoice
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        // [GIVEN] Create Item with Standard Cost      
        CreateItemWithStandardCost(Item);

        // [GIVEN] Create Job and Job Task
        CreateJobAndJobTask(JobTask);

        // [GIVEN] Create Job Planning Line
        CreateJobPlanningLineWithItem(JobPlanningLine, JobTask, JobPlanningLine."Line Type"::"Both Budget and Billable", Item."No.", 1);

        // [GIVEN] Create new Sales Invoice from Job Planning Line                
        TransferJobPlanningLine(JobPlanningLine, JobPlanningLine.Quantity, false, SalesHeader);

        // [GIVEN] Post Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [GIVEN] Post Payment and apply to Posted Sales Invoice
        CreateGenJnlLineWithBalAccount(
         GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, SalesInvoiceHeader."Sell-to Customer No.",
         GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -SalesInvoiceHeader."Amount Including VAT");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        GenJournalLine.Modify();

        // [GIVEN] Post Payment
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Open "Posted Sales Invoice" page for original Invoice
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.Filter.SetFilter("No.", SalesInvoiceHeader."No.");

        // [WHEN] Run "Create Corrective Credit Memo" action
        SalesCreditMemo.Trap();
        PostedSalesInvoice.CreateCreditMemo.Invoke();

        // [THEN] Verify additional Job Planning Line is created
        FindReversedJobPlanningLine(JobPlanningLine, ReversedJobPlanningLine);
        ReversedJobPlanningLine.TestField(Quantity, -JobPlanningLine.Quantity);
        ReversedJobPlanningLine.TestField("Unit Cost (LCY)", JobPlanningLine."Unit Cost (LCY)");
        ReversedJobPlanningLine.TestField("Unit Cost", JobPlanningLine."Unit Cost");
        ReversedJobPlanningLine.TestField("Line Amount", -JobPlanningLine."Line Amount");
        ReversedJobPlanningLine.TestField("Line Amount (LCY)", -JobPlanningLine."Line Amount (LCY)");

        // Clean-up notifications
        NotificationLifecycleMgt.RecallAllNotifications();
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('GetJobPlanLines')]
    procedure AllowCreatingSalesInvoiceLineOutsideOfProject()
    var
        JobTask: Record "Job Task";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        Qty: Decimal;
    begin
        // [SCENARIO 337091] Allow creating sales invoice line outside of project 
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Job and Job Task
        CreateJobWithJobTask(JobTask, Customer."No.");

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLine, JobTask, Qty, Qty);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [WHEN] Get Job Planning Lines
        // [HANDLER] [GetJobPlanLines] Get Job Plan Lines        
        Codeunit.Run(Codeunit::"Job-Process Plan. Lines", SalesLine);

        // [THEN] Verify Job Info on Sales Line
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Job No.", JobTask."Job No.");
        SalesLine.TestField("Job Task No.", JobTask."Job Task No.");
        SalesLine.TestField("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
    end;

    [Test]
    [HandlerFunctions('GetJobPlanLines')]
    procedure CheckInvoicedQtyOnJobPlanningLinesAfterSalesInvoiceCreatedFromJobPlanningLineIsPosted()
    var
        JobTask: Record "Job Task";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
    begin
        // [SCENARIO 337091] Check Invoiced Qty. on Job Planning Line after Sales Invoice created from Job Planning Line is posted
        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Job and Job Task
        CreateJobWithJobTask(JobTask, Customer."No.");

        // [GIVEN] Create Job Planning Line with Qty to Transfer to Invoice
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ItemType(), JobTask, JobPlanningLine);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Get Job Planning Lines
        // [HANDLER] [GetJobPlanLines] Get Job Plan Lines        
        Codeunit.Run(Codeunit::"Job-Process Plan. Lines", SalesLine);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify Qty. Invoiced and Qty. Transferred to Invoice on Job Planning Line
        JobPlanningLine.CalcFields("Qty. Invoiced", "Qty. Transferred to Invoice");
        JobPlanningLine.TestField("Qty. Invoiced", JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Qty. Transferred to Invoice", JobPlanningLine.Quantity);
    end;

    [Test]
    procedure AllowCreatingSalesInvoiceLinesOutsideForMultipleProjects()
    var
        JobTasks: array[2] of Record "Job Task";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLines: array[3] of Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobFilter: Text;
        Qty: Decimal;
        i: Integer;
    begin
        // [SCENARIO 337091] Allow creating sales invoice line outside for multiple projects
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create two Jobs and Job Tasks
        for i := 1 to 2 do begin
            CreateJobWithJobTask(JobTasks[i], Customer."No.");
            JobFilter += JobTasks[i]."Job No." + '|';
        end;
        JobFilter := CopyStr(JobFilter, 1, StrLen(JobFilter) - 1);

        // [GIVEN] Create two Job Planning Lines
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLines[1], JobTasks[1], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLines[2], JobTasks[2], Qty, Qty);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [WHEN] Create Sales Lines from multiple Job Planning Lines
        JobPlanningLines[3].SetFilter("Job No.", JobFilter);
        JobPlanningLines[3].FindSet();
        JobPlanningLines[3].SetSkipCheckForMultipleJobsOnSalesLine(true);
        JobCreateInvoice.CreateSalesInvoiceLines(JobPlanningLines[3]."Job No.", JobPlanningLines[3], SalesHeader."No.", false, SalesHeader."Posting Date", SalesHeader."Document Date", false);

        // [THEN] Verify Job Info on Sales Lines
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 10000);
        SalesLine.TestField("Job No.", JobTasks[1]."Job No.");
        SalesLine.TestField("Job Task No.", JobTasks[1]."Job Task No.");
        SalesLine.TestField("Job Contract Entry No.", JobPlanningLines[1]."Job Contract Entry No.");

        SalesLine.Reset();
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", 20000);
        SalesLine.TestField("Job No.", JobTasks[2]."Job No.");
        SalesLine.TestField("Job Task No.", JobTasks[2]."Job Task No.");
        SalesLine.TestField("Job Contract Entry No.", JobPlanningLines[2]."Job Contract Entry No.");
    end;

    [Test]
    procedure CheckInvoicedQtyOnJobPlanningLinesAfterSalesInvoiceCreatedFromMultipleJobPlanningLinesIsPosted()
    var
        JobTasks: array[2] of Record "Job Task";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLines: array[3] of Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        JobFilter: Text;
        Qty: Decimal;
        i: Integer;
    begin
        // [SCENARIO 337091] Check Invoiced Qty. on Job Planning Line after Sales Invoice created from multiple Job Planning Lines is posted
        Initialize();

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create two Jobs and Job Tasks
        for i := 1 to 2 do begin
            CreateJobWithJobTask(JobTasks[i], Customer."No.");
            JobFilter += JobTasks[i]."Job No." + '|';
        end;
        JobFilter := CopyStr(JobFilter, 1, StrLen(JobFilter) - 1);

        // [GIVEN] Create two Job Planning Lines
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLines[1], JobTasks[1], Qty, Qty);
        CreateJobPlanningLineWithQtyToTransferToInvoice(JobPlanningLines[2], JobTasks[2], Qty, Qty);

        // [GIVEN] Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create Sales Line
        CreateSimpleSalesLine(SalesLine, SalesHeader);

        // [GIVEN] Create Sales Lines from multiple Job Planning Lines
        JobPlanningLines[3].SetFilter("Job No.", JobFilter);
        JobPlanningLines[3].FindSet();
        JobPlanningLines[3].SetSkipCheckForMultipleJobsOnSalesLine(true);
        JobCreateInvoice.CreateSalesInvoiceLines(JobPlanningLines[3]."Job No.", JobPlanningLines[3], SalesHeader."No.", false, SalesHeader."Posting Date", SalesHeader."Document Date", false);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Verify Qty. Invoiced and Qty. Transferred to Invoice on Job Planning Lines
        JobPlanningLines[1].CalcFields("Qty. Invoiced", "Qty. Transferred to Invoice");
        JobPlanningLines[1].TestField("Qty. Invoiced", JobPlanningLines[1].Quantity);
        JobPlanningLines[1].TestField("Qty. Transferred to Invoice", JobPlanningLines[1].Quantity);

        JobPlanningLines[2].CalcFields("Qty. Invoiced", "Qty. Transferred to Invoice");
        JobPlanningLines[2].TestField("Qty. Invoiced", JobPlanningLines[2].Quantity);
        JobPlanningLines[2].TestField("Qty. Transferred to Invoice", JobPlanningLines[2].Quantity);
    end;

    local procedure RunJobCalculateWIP(Job: Record Job)
    var
        JobCalculateWIP: Report "Job Calculate WIP";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobCalculateWIP);
        JobCalculateWIP.SetTableView(Job);

        // Use Document No. as Job No. because value is not important.
        JobCalculateWIP.InitializeRequest();
        JobCalculateWIP.UseRequestPage(false);
        JobCalculateWIP.Run();
    end;

    local procedure RunJobPostWIPToGL(Job: Record Job)
    var
        JobPostWIPToGL: Report "Job Post WIP to G/L";
    begin
        Job.SetRange("No.", Job."No.");
        Clear(JobPostWIPToGL);
        JobPostWIPToGL.SetTableView(Job);
        JobPostWIPToGL.UseRequestPage(false);
        JobPostWIPToGL.Run();
    end;

    [Test]
    [HandlerFunctions('JobJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimensionsFilledCorrectlyAsSoonAsJobTaskNoEnteredOnJobJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        JobTask: Record "Job Task";
        JobJournalPage: TestPage "Job Journal";
        DimensionValueCode: array[3] of Code[20];
    begin
        // [SCENARIO 492284] Shortcut Dimension does not get filled in job journal from the beginning.
        Initialize();

        // [GIVEN] Setup: Create and Update Shourtcut Dimension 3 and 4 on General Ledger Setup
        GeneralLedgerSetup.Get();
        CreateDimensionWithDimensionValues(GeneralLedgerSetup."Shortcut Dimension 3 Code", DimensionValueCode[2]);
        CreateDimensionWithDimensionValues(GeneralLedgerSetup."Shortcut Dimension 4 Code", DimensionValueCode[3]);
        GeneralLedgerSetup.Modify();

        // [THEN] Create Job Task with Dimensions
        CreateJobTaskWithDimension(
            JobTask,
            GeneralLedgerSetup."Shortcut Dimension 3 Code",
            GeneralLedgerSetup."Shortcut Dimension 4 Code",
            DimensionValueCode);

        // [WHEN] Create new Job Journal Line on Job Journal Page
        CreateJobJournalLine(JobJournalPage, JobTask);

        // [VERIFY] Verify: Dimensions on Job Journal Line Page
        JobJournalPage."Shortcut Dimension 1 Code".AssertEquals(DimensionValueCode[1]);
        JobJournalPage.ShortcutDimCode3.AssertEquals(DimensionValueCode[2]);
        JobJournalPage.ShortcutDimCode4.AssertEquals(DimensionValueCode[3]);
        JobJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    [Scope('OnPrem')]
    procedure CorrectPostedSalesInvoicePostWithoutErrorWhenLineDiscountPctExist()
    var
        SalesHeader: Record "Sales Header";
        NewSalesInvoiceHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CancelledDocument: Record "Cancelled Document";
        JobPlanningLine: Record "Job Planning Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LineDiscountPct: Decimal;
    begin
        // [SCENARIO 500639] "Line Discount % has been changed (initial a Job Task: Job No.= XX, Job Task No.= YY) in Sales Line Doc Type='Credit Memo'" error occurs if you create a credit memo from a posted sales invoice that includes a discount from the job planning lines
        Initialize();

        // [GIVEN] Create and Post sales invoice with job
        LineDiscountPct := LibraryRandom.RandDecInRange(1, 5, 2);
        CreateSimpleSalesInvoiceFromJobPlanningLineWithLineDiscountPct(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), 1, LineDiscountPct);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Correct Invoice function is being run
        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, NewSalesInvoiceHeader);

        // [THEN] Credit Memo posted without error
        CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No.");
        SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");

        // [VERIFY] Verify: Posted Credit Memo line contains Line Discount %
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>0');
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(
            LineDiscountPct, SalesCrMemoLine."Line Discount %",
            StrSubstNo(LineDiscountPctErr, SalesCrMemoLine.FieldCaption("Line Discount %"), Format(LineDiscountPct)));
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SingleInvoiceCreatedBillingMethodMultipleCustomerSameCustomerOnPlanningLines()
    var
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentType: Enum "Sales Document Type";
        TaskBillingMethod: Enum "Task Billing Method";
        InvoicesList: List of [Code[20]];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 556289] When Task Billing Method set to Multiple Customers on the Project Header and Customer No is same on
        // all Project Planning Lines of same task then single invoice is created.
        Initialize();

        // [GIVEN] Create a Job and a Job Task with Billing Method set Multiple Customers.
        CreateJobAndJobTaskWithBillingMethod(JobTask, TaskBillingMethod::"Multiple customers");

        // [GIVEN] Create Three Job Planning Lines for Type Item. 
        CreateThreeJobPlanningLinesWithItem(JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Create Invoice for all three Job Planning Lines.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine[3], false);

        // [WHEN] Get Sales Invoice Document.
        GetSalesInvoiceDocumentList(JobPlanningLine[3], DocumentType::Invoice, InvoicesList);

        // [THEN] Verify One Sales Invoice is Created.
        Assert.AreEqual(1, InvoicesList.Count, WrongNoOfLinesLbl);

        // [GIVEN] Get Sales Invoice No from List.
        InvoicesList.Get(1, DocumentNo);

        // [WHEN] Get Sales Header and Lines.
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);

        // [THEN] Verify Three Sales Lines are created in a single invoice.
        Assert.AreEqual(3, SalesLine.Count, WrongNoOfLinesLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,TransferToInvoiceHandler')]
    procedure RetrieveUnitCostFromPostedInvoiceForFullyInvoicedJobPlanningLine()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        OldUnitCost: Decimal;
    begin
        // [SCENARIO 559747] Retrieve Unit Cost from the posted invoice for fully invoiced Job Planning Line.
        Initialize();

        // [GIVEN] Job, job task, job planning line with item.
        LibraryJob.CreateJob(Job, LibrarySales.CreateCustomerNo());
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Billable, LibraryJob.ItemType(), JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Create and post Sales Invoice for the Job Planning Line.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Change Unit Cost of the item to "Y".
        Item.Get(JobPlanningLine."No.");
        Item.Validate("Unit Cost", 2 * Item."Unit Cost");
        Item.Modify(true);

        // [GIVEN] Current Unit Cost of the Job Planning Line = "X".
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Qty. Invoiced");
        OldUnitCost := JobPlanningLine."Unit Cost";

        // [GIVEN] Set Quantity on the Job Planning Line to greater than Qty. Invoiced.
        // [GIVEN] Verify that "Unit Cost" is updated to the new value "Y".
        JobPlanningLine.Validate(Quantity, 2 * JobPlanningLine.Quantity);
        JobPlanningLine.TestField("Unit Cost", Item."Unit Cost");

        // [WHEN] Set Quantity on the Job Planning Line to equal to Qty. Invoiced.
        JobPlanningLine.Validate(Quantity, JobPlanningLine."Qty. Invoiced");

        // [THEN] Verify that "Unit Cost" is updated to the old value "X".
        JobPlanningLine.TestField("Unit Cost", OldUnitCost);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SingleInvoiceCreatedBillingMethodMultipleCustomerSameCustomerOnPlanningLinesWithTwoTaskNo()
    var
        JobTask: Record "Job Task";
        Job: Record Job;
        Item: array[2] of Record Item;
        JobTask2: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        JobPlanningLine: array[2] of Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DocumentType: Enum "Sales Document Type";
        TaskBillingMethod: Enum "Task Billing Method";
        InvoicesList: List of [Code[20]];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 566879] When the field Task Billing Method is set to Multiple Customers on the Project Card with 2 Project Tasks and a Single Planning Line Each, 
        // the system now generates a Single Sales Invoice when a Single Project Task is Selected.
        Initialize();

        // [GIVEN] Create a Job and 2 Job Task with Billing Method set Multiple Customers.
        CreateJobAndJobTaskWithBillingMethod(JobTask, TaskBillingMethod::"Multiple customers");
        Job.Get(JobTask."Job No.");
        LibraryJob.CreateJobTask(Job, JobTask2);

        // [GIVEN] Create One Job Planning Lines for Each JobTask. 
        LibraryInventory.CreateItem(Item[1]);
        CreateJobPlanningLineWithItem(JobPlanningLine[1], JobTask, JobPlanningLine[1]."Line Type"::"Both Budget and Billable", Item[1]."No.", LibraryRandom.RandIntInRange(1, 10));
        LibraryInventory.CreateItem(Item[2]);
        CreateJobPlanningLineWithItem(JobPlanningLine[2], JobTask2, JobPlanningLine[2]."Line Type"::"Both Budget and Billable", Item[2]."No.", LibraryRandom.RandIntInRange(1, 10));
        Commit();

        // [GIVEN] Create Invoice for 1st Job Task - Job Planning Lines.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine[1], false);

        // [WHEN] Get Sales Invoice Document.
        GetSalesInvoiceDocumentList(JobPlanningLine[1], DocumentType::Invoice, InvoicesList);
        GetSalesInvoiceDocumentList(JobPlanningLine[2], DocumentType::Invoice, InvoicesList);

        // [THEN] Verify One Sales Invoice is Created.
        Assert.AreEqual(1, InvoicesList.Count, WrongNoOfLinesLbl);

        // [GIVEN] Get Sales Invoice No from List.
        InvoicesList.Get(1, DocumentNo);

        // [WHEN] Get Sales Header and Lines.
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);

        // [THEN] Verify One Sales Lines are created in a single invoice.
        Assert.AreEqual(1, SalesLine.Count, WrongNoOfLinesLbl);
    end;

    [Test]
    [HandlerFunctions('TransferToInvoiceHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyInvoicedJobAndCreateInvoiceWithoutError()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: array[3] of Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        CopyJob: Codeunit "Copy Job";
        DocumentType: Enum "Sales Document Type";
        TaskBillingMethod: Enum "Task Billing Method";
        InvoicesList: List of [Code[20]];
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 569370] After copying an existed project card & task to new, cannot create sales invoice although there is quantity to invoice
        Initialize();

        // [GIVEN] Create a Job and a Job Task with Billing Method set Multiple Customers.
        CreateJobAndJobTaskWithBillingMethod(JobTask, TaskBillingMethod::"Multiple customers");

        // [GIVEN] Create Three Job Planning Lines for Type Item. 
        CreateThreeJobPlanningLinesWithItem(JobTask, JobPlanningLine);
        Commit();

        // [GIVEN] Create Invoice for all three Job Planning Lines.
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine[3], false);

        // [WHEN] Get Sales Invoice Document.
        GetSalesInvoiceDocumentList(JobPlanningLine[3], DocumentType::Invoice, InvoicesList);

        // [THEN] Verify One Sales Invoice is Created.
        Assert.AreEqual(1, InvoicesList.Count, WrongNoOfLinesLbl);

        // [GIVEN] Save Target Job No.
        TargetJobNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Copy Job 
        Job.Get(JobTask."Job No.");
        CopyJob.CopyJob(Job, TargetJobNo, TargetJobNo, Job."Bill-to Customer No.", '');

        // [GIVEN] Update Task Billing method to Multiple Customer
        Job.Get(TargetJobNo);
        Job.Validate("Task Billing Method", TaskBillingMethod::"Multiple customers");
        Job.Modify(true);

        // [GIVEN]  Update Quantity in Job Planning Line
        UpdateQuantityInJobPlanningLine(Job."No.");

        // [GIVEN] Get the Job Planning Line 
        JobPlanningLine2.SetRange("Job No.", Job."No.");
        JobPlanningLine2.FindSet();

        // [GIVEN]  Commit before run the report
        Commit();

        // [WHEN] Run the Create Sales Invoice
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine2, false);

        // [GIVEN] Clear the list 
        Clear(InvoicesList);

        // [WHEN] Gwt Sales Invoice Document List
        GetSalesInvoiceDocumentList(JobPlanningLine2, DocumentType::Invoice, InvoicesList);

        // [THEN] Verify the invoice is created successfully
        Assert.AreEqual(1, InvoicesList.Count, WrongNoOfLinesLbl);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyJobAndCreateProjectJournalLineWithoutError()
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        CopyJob: Codeunit "Copy Job";
        JobLineType: Enum "Job Line Type";
        TargetJobNo: Code[20];
    begin
        // [SCENARIO 573397] Copy project of System-Created Entry must be equal to 'No' in Project Planning Line
        Initialize();

        // [GIVEN] Create Job with Customer
        CreateJobWithCustomer(Job);

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Job Journal Line of type "Both Budget and Billable" and post it.
        CreateAndPostJobJournalLineWithIteAndType(JobJournalLine, JobTask, JobLineType::"Both Budget and Billable");

        // [GIVEN] Create target Job Id
        TargetJobNo := LibraryUtility.GenerateGUID();

        // [WHEN] Copy Job by setting Copy Quantity as true.
        CopyJob.SetCopyOptions(false, true, false, 0, 0, 0);
        CopyJob.CopyJob(Job, TargetJobNo, TargetJobNo, Job."Bill-to Customer No.", '');

        // [THEN] Find the created Job Planning Line and "System-Created Entry" should be set false
        JobPlanningLine.SetRange("Job No.", TargetJobNo);
        JobPlanningLine.FindFirst();
        Assert.IsFalse(JobPlanningLine."System-Created Entry", ValueFalseErr);
    end;

    [Test]
    procedure PostPurchaseCreditMemoWithNonInventoryItemLinkedToProject()
    var
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 580434] Error when posting a Purchase Credit Memo for 'Non-Inventory' item with Project No. selected
        Initialize();

        // [GIVEN] Create Non-Inventory Item
        LibraryInventory.CreateNonInventoryTypeItem(Item);

        // [GIVEN] Create Job with Customer
        CreateJobWithCustomer(Job);

        // [GIVEN] Create Job Task
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create Purchase Credit Memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [GIVEN] Set Job No., Job Task No. and Job Line Type as Billable
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Billable);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Credit Memo
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] No error should come, as posting for Non-Inventory Item.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        JobBatchJobs: Codeunit "Job Batch Jobs";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Job Invoicing");
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Job Invoicing");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();

        JobBatchJobs.SetJobNoSeries(DummyJobsSetup, NoSeries);

        // Have to set report layout for 1306 to use RDLC, or else report won't export to excel.
        ReportLayoutSelection.SetRange("Report ID", 1306);
        ReportLayoutSelection.SetRange("Company Name", CompanyName);
        if ReportLayoutSelection.FindFirst() then begin
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Modify();
        end else begin
            ReportLayoutSelection."Report ID" := 1306;
            ReportLayoutSelection."Company Name" := CompanyName;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Insert();
        end;

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.Save(DATABASE::"Jobs Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Job Invoicing");
    end;

    local procedure MockPurchaseLineJobRelatedFields(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Job Currency Code" := LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("Job Currency Code"), Database::"Purchase Line");
        PurchaseLine."Job Currency Factor" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Line Amount" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Line Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Line Disc. Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Line Discount %" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Line Discount Amount" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Line Type" := PurchaseLine."Job Line Type"::"Both Budget and Billable";
        PurchaseLine."Job Planning Line No." := LibraryRandom.RandInt(100);
        PurchaseLine."Job Remaining Qty." := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Remaining Qty. (Base)" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Total Price" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Total Price (LCY)" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Unit Price" := LibraryRandom.RandDec(100, 2);
        PurchaseLine."Job Unit Price (LCY)" := LibraryRandom.RandDec(100, 2);
    end;

    local procedure Plan(LineType: Enum "Job Planning Line Line Type"; ConsumableType: Enum "Job Planning Line Type"; var JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LineType, ConsumableType, JobTask, JobPlanningLine);
    end;

    local procedure TransferJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; Fraction: Decimal; Credit: Boolean; var SalesHeader: Record "Sales Header")
    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        QtyToTransfer: Decimal;
    begin
        // Transfer Fraction of JobPlanningLine to a sales invoice
        QtyToTransfer := Fraction * JobPlanningLine.Quantity;
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", QtyToTransfer);
        JobPlanningLine.Modify(true);
        JobPlanningLine.SetRecFilter();
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, Credit);

        if QtyToTransfer > 0 then
            GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader)
        else
            GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader)
    end;

    local procedure TransJobPlanningLineToSalesInvoice(var SalesHeader: Record "Sales Header"; JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetRange("Line Type", JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.FindLast();
        TransferJobPlanningLine(JobPlanningLine, 1, false, SalesHeader);
    end;

    local procedure Invoice(var JobPlanningLine: Record "Job Planning Line"; Fraction: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        TransferJobPlanningLine(JobPlanningLine, Fraction, false, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.")
    end;

    local procedure CreateJobTaskWithDimension(var JobTask: Record "Job Task") DimensionValueCode: Code[20]
    var
        Job: Record Job;
        DimensionCode: Code[20];
    begin
        DimensionCode := CreateJobWithDimension(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        DimensionValueCode := UpdateDimensionOnJobTask(JobTask, DimensionCode);
    end;

    local procedure CreateAndPostJobJournalLine(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task")
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate(Quantity, JobPlanningLine.Quantity / LibraryRandom.RandIntInRange(2, 4));
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateCustomerWithAlternateShipToCode(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerAddress(Customer);
        CreateShipToAddressWithAddress(ShipToAddress, Customer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);
    end;

    local procedure CreateShipToAddressWithAddress(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate(Address, LibraryUtility.GenerateGUID());
        ShipToAddress.Modify(true);
    end;

    local procedure CreateAndPostJobJournalLineWithTypeItem(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task")
    var
        Item: Record Item;
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", LibraryInventory.CreateItem(Item));
        JobJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        JobJournalLine.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreatePostJobJournalLineWithItem(JobTask: Record "Job Task"; ItemNo: Code[20])
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        CreateJobJournalLineWithItem(JobJournalLine, JobTask, ItemNo);
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateJobJournalLineWithItem(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; ItemNo: Code[20])
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Billable, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobJournalLine.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateJobWithJobTask(JobTask, Customer."No.");
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task"; CustomerNo: Code[20])
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job, CustomerNo);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateSalesInvoiceFromJobPlanningLine(var SalesHeader: Record "Sales Header"; var JobPlanningLine: Record "Job Planning Line"; ForeignCustomer: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Currency: Record Currency;
    begin
        if ForeignCustomer then begin
            LibraryERM.CreateCurrency(Currency);
            CreateCurrencyExchangeRate(Currency.Code, WorkDate());
        end;
        CreateJob(Job, Currency.Code, PricesInclVAT);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        CreateAndPostJobJournalLine(JobPlanningLine, JobTask);
        TransferJobPlanningLine(JobPlanningLine, 1, false, SalesHeader);
        exit(Job."No.");
    end;

    local procedure CreateSimpleSalesInvoiceFromJobPlanningLine(var SalesHeader: Record "Sales Header"; var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; QtyInvoiceFraction: Decimal): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateJob(Job, '', false);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LineType, LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        TransferJobPlanningLine(JobPlanningLine, QtyInvoiceFraction, false, SalesHeader);
        exit(Job."No.");
    end;

    local procedure CreateSalesInvoiceWithResourceAndTextTypes(var SalesHeader: Record "Sales Header"; var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        CreateJob(Job, '', false);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LineType, LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        LibraryJob.CreateJobPlanningLine(LineType, LibraryJob.TextType(), JobTask, JobPlanningLine);
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);

        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
        exit(Job."No.");
    end;

    local procedure CreateSalesInvoiceWithVariousVATPostingGroups(var SalesHeader: Record "Sales Header"; JobTask: Record "Job Task"; VATProdPostingGroupArray: array[6] of Record "VAT Product Posting Group"; VATBusPostingGroupCode: Code[20]; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        CurrentArrayNo: Integer;
    begin
        Commit();
        JobTask.SetRecFilter();
        REPORT.Run(REPORT::"Job Create Sales Invoice", true, false, JobTask);

        SalesHeader.Reset();
        SalesHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Posting Date", WorkDate());
        SalesHeader.FindFirst();

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        if SalesLine.FindSet() then
            repeat
                if CurrentArrayNo < ArrayLen(VATProdPostingGroupArray) then
                    CurrentArrayNo += 1;
                SalesLine.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
                SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupArray[CurrentArrayNo].Code);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
    end;

    local procedure CreatePostSalesInvoiceAndOpenItWithCardPage(var PostedSalesInvoice: TestPage "Posted Sales Invoice"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        JobPlanningLine: Record "Job Planning Line";
    begin
        CreateSimpleSalesInvoiceFromJobPlanningLine(SalesHeader, JobPlanningLine, LibraryJob.PlanningLineTypeContract(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
    end;

    local procedure CreateJobWithDimension(var Job: Record Job): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        CreateJob(Job, '', false);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Job, Job."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DefaultDimension."Dimension Code");
    end;

    local procedure SetItemStandardCost(var Item: Record Item; StandardCost: Decimal)
    begin
        Item.Get(Item."No.");
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", StandardCost);
        Item.Modify();
    end;

    local procedure CreateItemUnitOfMeasure(Item: Record Item): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.SetFilter(Code, '<>%1', Item."Base Unit of Measure");
        UnitOfMeasure.FindFirst();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, LibraryRandom.RandIntInRange(2, 10));
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure PrepareJobForSalesInvoice(var JobTask: Record "Job Task"; var Item: Record Item)
    begin
        Initialize();
        CreateJobWithJobTask(JobTask);
        LibraryInventory.CreateItem(Item);
        SetItemStandardCost(Item, LibraryRandom.RandDecInRange(1, 10, 2));
    end;

    local procedure ModifyDimension(var JobJournalLine: Record "Job Journal Line"): Code[20]
    var
        DimValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
        JobJournalLine.Validate("Shortcut Dimension 1 Code", DimValue.Code);
        JobJournalLine.Modify();
        exit(DimValue.Code);
    end;

    local procedure Credit(JobPlanningLine: Record "Job Planning Line"; Fraction: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        if Fraction = 0 then
            exit;
        // we cannot credit from the same line.
        JobPlanningLine."Line No." += 1;
        JobPlanningLine."Usage Link" := false;
        JobPlanningLine."Line Type" := LibraryJob.PlanningLineTypeContract();
        JobPlanningLine."Qty. Posted" := 0;
        JobPlanningLine.Validate(Quantity, -Fraction * JobPlanningLine.Quantity);
        JobPlanningLine.Insert(true);

        TransferJobPlanningLine(JobPlanningLine, 1, true, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateItemCharge(var ItemCharge: Record "Item Charge"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        Vendor.Get(VendorNo);
        if not VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", ItemCharge."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", ItemCharge."VAT Prod. Posting Group");
    end;

    local procedure CreateJob(var Job: Record Job; CurrencyCode: Code[10]; PricesInclVAT: Boolean)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.Validate("WIP Method", FindJobWipMethods());
        Job.Validate("Starting Date", WorkDate());
        Job.Validate("Ending Date", WorkDate());
        SetCustomerCurrencyCodePricesInclVAT(Customer, CurrencyCode, PricesInclVAT);
        Job.Modify(true);
    end;

    local procedure CreateJobWithCurrency(var Job: Record Job)
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(Currency.Code, WorkDate());
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify(true);
    end;

    local procedure CreateJobWithVATPostingGroupsWithPlanningLines(var JobTask: Record "Job Task"; GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; CustomerNo: Code[20]; ItemNo: Code[20]; GLAccountNo: Code[20])
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job, CustomerNo);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(JobTask, LibraryJob.ItemType(), ItemNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.GLAccountType(), GLAccountNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.ItemType(), ItemNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.GLAccountType(), GLAccountNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.GLAccountType(), GLAccountNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.GLAccountType(), GLAccountNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.GLAccountType(), GLAccountNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
        CreateJobPlanningLine(JobTask, LibraryJob.GLAccountType(), GLAccountNo, GenBusPostingGroupCode, GenProdPostingGroupCode);
    end;

    local procedure CreateJobPlanningLine(JobTask: Record "Job Task"; ConsumableType: Enum "Job Planning Line Type"; CodeNo: Code[20];
                                                                                          GenBusPostingGroupCode: Code[20];
                                                                                          GenProdPostingGroupCode: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", JobTask."Job No.");
        JobPlanningLine.Validate("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.Validate("Line No.", LibraryJob.GetNextLineNo(JobPlanningLine));
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.Validate("Line Type", LibraryJob.PlanningLineTypeBoth());
        JobPlanningLine.Validate(Type, ConsumableType);
        JobPlanningLine.Validate("No.", CodeNo);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 50));
        JobPlanningLine.Validate("Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        JobPlanningLine.Validate("Unit Price", JobPlanningLine."Unit Cost" * (LibraryRandom.RandIntInRange(2, 10) / 10));
        JobPlanningLine.Validate(Description, LibraryUtility.GenerateGUID());
        JobPlanningLine.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        JobPlanningLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; PostingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, PostingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(1000, 2));
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(1000, 2));
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomerwithDimension(): Code[20]
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        exit(Customer."No.");
    end;

    local procedure CreateJobPlanningLineWithDimension(var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CreateJobWithCustomer(Job);
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Job, Job."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);
    end;

    local procedure CreateJobPlanningLineWithResource(var JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Plan(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobPlanningLine);
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
    end;

    local procedure CreateJobPlanningLineWithQtyToTransferToInvoice(var JobPlanningLine: Record "Job Planning Line"; JobTask: Record "Job Task"; Quantity: Decimal; QtyToTransferToInvoice: Decimal)
    begin
        LibraryJob.CreateJobPlanningLine(
          JobPlanningLine."Line Type"::Billable, LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Validate("Qty. to Transfer to Invoice", QtyToTransferToInvoice);
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobWithCustomer(var Job: Record Job)
    begin
        LibraryJob.CreateJob(Job, CreateCustomerwithDimension());
    end;

    local procedure CreateDefDimForItem(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, ItemNo, DimValue."Dimension Code", DimValue.Code);
    end;

    local procedure CreateJobTaskDim(var JobTaskDim: Record "Job Task Dimension"; JobTask: Record "Job Task")
    var
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
        InsertJobTaskDim(JobTaskDim, JobTask, DimValue);
    end;

    local procedure CreateJobTaskGlobalDim(var JobTaskDim: Record "Job Task Dimension"; JobTask: Record "Job Task")
    var
        DimValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimValue, LibraryERM.GetGlobalDimensionCode(1));
        InsertJobTaskDim(JobTaskDim, JobTask, DimValue);
    end;

    local procedure CreatePurchaseOrderWithJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        JobTask: Record "Job Task";
    begin
        LibraryInventory.CreateItem(Item);
        CreateJobWithJobTask(JobTask);

        CreatePurchaseOrderAssignJob(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.", JobTask);
    end;

    local procedure CreatePurchInvWithCurrencyAndJobTask(var PurchHeader: Record "Purchase Header"; CurrencyCode: Code[10]; JobTask: Record "Job Task")
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Job No.", JobTask."Job No.");
        PurchLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchLine.Modify(true);
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
            if (CurrentGroupNo = 3) or (CurrentGroupNo = 4) then
                VATRate := 0;
            VATPostingSetupArray[CurrentGroupNo].Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetupArray[CurrentGroupNo].Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
            VATPostingSetupArray[CurrentGroupNo].Validate("VAT %", VATRate);
            VATPostingSetupArray[CurrentGroupNo].Validate(
              "VAT Identifier",
              CopyStr(
                LibraryERM.CreateRandomVATIdentifierAndGetCode(), 1, MaxStrLen(VATPostingSetupArray[CurrentGroupNo]."VAT Identifier")));
            VATPostingSetupArray[CurrentGroupNo].Modify(true);
        end;
    end;

    local procedure CreatePurchaseOrderAssignJob(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; JobTask: Record "Job Task")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(500, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateOrAppendToSalesDocument(JobPlanningLine: Record "Job Planning Line"; CreateNewSalesDoc: Boolean; AppendToSalesDocNo: Code[20]; IsCreditMemo: Boolean)
    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        LibraryVariableStorage.Enqueue(CreateNewSalesDoc);
        LibraryVariableStorage.Enqueue(AppendToSalesDocNo);
        JobPlanningLine.SetRecFilter();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, IsCreditMemo);
    end;

    local procedure PostPurchaseOrderWithJob(ToReceive: Boolean; ToInvoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrderWithJob(PurchaseHeader, PurchaseLine);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToReceive, ToInvoice));
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

    local procedure SetupCustomerWithVATPostingGroup(VATBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Customer: Record Customer;
    begin
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode));
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, Customer."Gen. Bus. Posting Group", GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        exit(Customer."No.");
    end;

    local procedure ReceivePurchOrderWithJobAndItemTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; TrackingOption: Option): Code[20]
    var
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrderAssignJob(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemNo, JobTask);
        LibraryVariableStorage.Enqueue(TrackingOption);
        PurchaseLine.OpenItemTrackingLines();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure InsertJobTaskDim(var JobTaskDim: Record "Job Task Dimension"; JobTask: Record "Job Task"; DimValue: Record "Dimension Value")
    begin
        JobTaskDim.Init();
        JobTaskDim.Validate("Job No.", JobTask."Job No.");
        JobTaskDim.Validate("Job Task No.", JobTask."Job Task No.");
        JobTaskDim.Validate("Dimension Code", DimValue."Dimension Code");
        JobTaskDim.Validate("Dimension Value Code", DimValue.Code);
        JobTaskDim.Insert(true);
    end;

    local procedure FindItemLedgerEntry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; IsPositive: Boolean): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindFirst();

        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindJobWipMethods(): Code[20]
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        JobWIPMethod.Next(LibraryRandom.RandInt(JobWIPMethod.Count));
        exit(JobWIPMethod.Code);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobTask: Record "Job Task")
    begin
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobLedgerEntry.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FindReversedJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; var ReversedJobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        ReversedJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        ReversedJobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        if JobPlanningLine.Quantity > 0 then
            ReversedJobPlanningLine.SetFilter(Quantity, '<0')
        else
            ReversedJobPlanningLine.SetFilter(Quantity, '>0');
        exit(ReversedJobPlanningLine.FindFirst())
    end;

    local procedure CreateGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure GetILEAmountSign(ItemLedgerEntry: Record "Item Ledger Entry"): Integer
    begin
        if ItemLedgerEntry.Positive then
            exit(1);

        exit(-1);
    end;

    local procedure GetDimensionSetIdFromSalesLine(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        exit(SalesLine."Dimension Set ID");
    end;

    local procedure SalesDocumentFromJobPlanning(DocumentType: Enum "Sales Document Type"; SalesDocumentType: Boolean)
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        DimensionValueCode: Code[20];
    begin
        // Setup: Create Job Planning Line with Dimesion.
        Initialize();
        DimensionValueCode := CreateJobTaskWithDimension(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeContract(), LibraryJob.ResourceType(), JobTask, JobPlanningLine);

        // Exercise: Create sales Document from Job Planning Line.
        Commit();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, SalesDocumentType);

        // Verify: Verifying Dimension Value Code on Dimension Set Entry equal to Dimension Value Code of Job Task.
        VerifyDimensionSetEntry(JobPlanningLine, DimensionValueCode, DocumentType);
    end;

    local procedure SetCustomerCurrencyCodePricesInclVAT(var Customer: Record Customer; CurrencyCode: Code[10]; PricesInclVAT: Boolean)
    begin
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
    end;

    local procedure UpdateDimensionOnJobTask(JobTask: Record "Job Task"; DimensionCode: Code[20]): Code[20]
    var
        JobTaskDimension: Record "Job Task Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        JobTaskDimension.Get(JobTask."Job No.", JobTask."Job Task No.", DimensionCode);
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        JobTaskDimension.Validate("Dimension Value Code", DimensionValue.Code);
        JobTaskDimension.Modify(true);
        exit(JobTaskDimension."Dimension Value Code");
    end;

    local procedure UpdateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20])
    begin
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(5));
        JobPlanningLine.Validate("Qty. to Transfer to Journal", JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure ChangePostingDateWithLaterDateOnPurchHeader(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDateFrom(WorkDate(), 5));
        PurchaseHeader.Modify(true);
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PostedRcptNo: Code[20])
    begin
        PurchRcptLine.SetRange("Document No.", PostedRcptNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure CreateJobJnlLine(var JobJournalLine: Record "Job Journal Line"): Decimal
    var
        Item: Record Item;
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
        PriceListLine: Record "Price List Line";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(100, 2));
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobItemPrice(
          JobItemPrice, JobTask."Job No.", JobTask."Job Task No.", Item."No.", '', '', Item."Base Unit of Measure");
        JobItemPrice.Validate("Unit Cost Factor", LibraryRandom.RandDec(2, 2));
        JobItemPrice.Modify(true);
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::"Both Budget and Billable", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Modify(true);
        exit(JobItemPrice."Unit Cost Factor" * Item."Unit Cost");
    end;

    local procedure UpdateDesriptionInSalesLine(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"): Text[50]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.FindFirst();
        SalesLine.Validate(Description, LibraryUtility.GenerateGUID());
        SalesLine.Modify(true);
        exit(SalesLine.Description);
    end;

    local procedure VerifyLineTypeInJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Line Type", JobLedgerEntry."Line Type"::Billable);
    end;

    local procedure VerifyDimensionSetEntry(JobPlanningLine: Record "Job Planning Line"; DimensionValueCode: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        GetSalesDocument(JobPlanningLine, DocumentType, SalesHeader);
        DimensionSetEntry.SetRange("Dimension Set ID", GetDimensionSetIdFromSalesLine(SalesHeader));
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(DimensionSetEntry."Dimension Value Code", DimensionValueCode, 'Dimension value mismatch');
    end;

    local procedure VerifyDimensionOnJobJournalLine(JobNo: Code[20]; JobTaskNo: Code[20]; DimensionValueCode: Code[20])
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobJournalLine.SetRange("Job No.", JobNo);
        JobJournalLine.SetRange("Job Task No.", JobTaskNo);
        JobJournalLine.FindFirst();
        JobJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValueCode);
    end;

    local procedure VerifySalesInvoice(JobPlanningLine: Record "Job Planning Line"; SalesHeader: Record "Sales Header")
    var
        Job: Record Job;
        SalesLine: Record "Sales Line";
    begin
        // Verify JobPlanningLine has a corresponding sales invoice

        Job.Get(JobPlanningLine."Job No.");
        SalesHeader.TestField("Sell-to Customer No.", Job."Bill-to Customer No.");
        SalesHeader.TestField("Bill-to Customer No.", Job."Bill-to Customer No.");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField(Type, LibraryJob.Job2SalesConsumableType(JobPlanningLine.Type));
        SalesLine.TestField("No.", JobPlanningLine."No.");
        SalesLine.TestField(Quantity, JobPlanningLine."Qty. Transferred to Invoice");
        SalesLine.TestField("Unit Price", JobPlanningLine."Unit Price")
    end;

    local procedure GetSalesDocument(JobPlanningLine: Record "Job Planning Line"; DocumentType: Enum "Sales Document Type"; var SalesHeader: Record "Sales Header")
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        if DocumentType = SalesHeader."Document Type"::Invoice then
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice)
        else
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::"Credit Memo");
        JobPlanningLineInvoice.FindFirst();
        SalesHeader.Get(DocumentType, JobPlanningLineInvoice."Document No.")
    end;

    local procedure GetCombinedDimSetID(JobTaskDim: Record "Job Task Dimension"; DefaultDimension: Record "Default Dimension"): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        DimValue.Get(JobTaskDim."Dimension Code", JobTaskDim."Dimension Value Code");
        InsertDimSetEntry(TempDimSetEntry, DimValue);
        DimValue.Get(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        InsertDimSetEntry(TempDimSetEntry, DimValue);
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry))
    end;

    local procedure InsertDimSetEntry(var DimSetEntry: Record "Dimension Set Entry"; DimValue: Record "Dimension Value")
    begin
        DimSetEntry."Dimension Code" := DimValue."Dimension Code";
        DimSetEntry."Dimension Value Code" := DimValue.Code;
        DimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        DimSetEntry.Insert();
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; JobNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Job No.", JobNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyCombinedDimensionSetIDOnSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
        DimensionSetID: Integer;
    begin
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        DimensionSetIDArr[1] := SalesHeader."Dimension Set ID";
        DimensionSetIDArr[2] := SalesLine."Dimension Set ID";
        DimensionSetID :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
        SalesLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyDimensionOnJobLedgerEntry(JobTask: Record "Job Task"; DimensionValueCode: Code[20]; DimensionSetID: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        FindJobLedgerEntry(JobLedgerEntry, JobTask);
        JobLedgerEntry.TestField("Global Dimension 1 Code", DimensionValueCode);
        JobLedgerEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyDimensionOnJobWIPEntry(JobNo: Code[20]; DimensionValueCode: Code[20]; DimensionSetID: Integer)
    var
        JobWIPEntry: Record "Job WIP Entry";
    begin
        JobWIPEntry.SetRange("Job No.", JobNo);
        JobWIPEntry.FindFirst();
        JobWIPEntry.TestField("Global Dimension 1 Code", DimensionValueCode);
        JobWIPEntry.TestField("Dimension Set ID", DimensionSetID);
    end;

    local procedure VerifyJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20]; Amount: Decimal; FieldNo: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.FindLast();
        RecRef.GetTable(JobLedgerEntry);
        FieldRef := RecRef.Field(FieldNo);
        Assert.AreEqual(FieldRef.Value, Amount, StrSubstNo(JobLedgerEntryFieldErr, FieldRef.Name));
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        Assert.AreEqual(SalesInvoiceLine.Type::Item, SalesInvoiceLine.Type,
          StrSubstNo(WrongItemInfoErr, SalesInvoiceLine.FieldCaption(Type)));
        Assert.AreEqual(ItemNo, SalesInvoiceLine."No.",
          StrSubstNo(WrongItemInfoErr, SalesInvoiceLine.FieldCaption("No.")));
    end;

    local procedure VerifyDescriptionInPostedSalesInvoice(DocumentNo: Code[20]; NewDescription: Text[50])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        FindSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        Assert.AreEqual(NewDescription, SalesInvoiceLine.Description, WrongDescriptionInPostedSalesInvoiceErr);
    end;

    local procedure VerifySalesLineWithTextExists(JobPlanningLine: Record "Job Planning Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        GetSalesDocument(JobPlanningLine, SalesHeader."Document Type"::Invoice, SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        Assert.RecordIsNotEmpty(SalesLine);
    end;

    local procedure VerifyDocDateOnJobLedgEntry(JobNo: Code[20]; JobTaskNo: Code[20]; DocNo: Code[20]; ExpectedDocDate: Date)
    var
        JobTask: Record "Job Task";
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        JobTask.Get(JobNo, JobTaskNo);
        JobLedgEntry.SetRange("Document No.", DocNo);
        FindJobLedgerEntry(JobLedgEntry, JobTask);
        JobLedgEntry.TestField("Document Date", ExpectedDocDate);
    end;

    local procedure VerifyJobCurrencyFactorOnPurchLine(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        PurchLine.TestField("Job Currency Factor", PurchHeader."Currency Factor");
    end;

    local procedure VerifyJobLedgerEntriesWithGLEntries(JobTask: Record "Job Task"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::"G/L Account");
        FindJobLedgerEntry(JobLedgerEntry, JobTask);
        FindGLEntry(GLEntry, DocumentNo, GLEntry."Document Type"::Invoice);
        GLEntry.SetFilter("G/L Account No.", GLAccountNo);
        GLEntry.FindSet();
        repeat
            JobLedgerEntry.SetRange("Ledger Entry No.", GLEntry."Entry No.");
            JobLedgerEntry.SetRange("Ledger Entry Type", JobLedgerEntry."Ledger Entry Type"::"G/L Account");
            JobLedgerEntry.FindFirst();
            JobLedgerEntry.CalcSums("Line Amount (LCY)");
            JobLedgerEntry.TestField("Line Amount (LCY)", GLEntry.Amount);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyJobLedgerEntryUnitCost(JobTask: Record "Job Task"; ItemNo: Code[20]; ExpectedCost: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.SetRange("No.", ItemNo);
        JobLedgerEntry.FindFirst();

        JobLedgerEntry.TestField("Unit Cost", ExpectedCost);
    end;

    local procedure VerifySalesLineCountLinkedToJob(JobNo: Code[20]; JobTaskNo: Code[20]; ExpectedCount: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Job No.", JobNo);
        SalesLine.SetRange("Job Task No.", JobTaskNo);
        Assert.RecordCount(SalesLine, ExpectedCount);
    end;

    local procedure VerifyInvoiceQuantityInJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; QtyTransferredToInvoice: Decimal; QtyToTransferToInvoice: Decimal)
    begin
        JobPlanningLine.Find();
        JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
        JobPlanningLine.TestField("Qty. Transferred to Invoice", QtyTransferredToInvoice);
        JobPlanningLine.TestField("Qty. to Transfer to Invoice", QtyToTransferToInvoice);
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
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyAppliedEntryToAdjustFalseInItemLedgEntries(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.TestField("Applied Entry to Adjust", true);
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemRegisterExistsFromNegativeToPurchItemLedgEntry(ItemNo: Code[20])
    var
        ItemRegister: Record "Item Register";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemRegister.SetRange(
          "From Entry No.", FindItemLedgerEntry(ItemNo, ItemLedgerEntry."Entry Type"::"Negative Adjmt.", true));
        ItemRegister.SetRange(
          "To Entry No.", FindItemLedgerEntry(ItemNo, ItemLedgerEntry."Entry Type"::Purchase, false));
        Assert.RecordIsNotEmpty(ItemRegister);
    end;

    local procedure VerifyItemRegisterWithCostAmtActualValueEntriesExists(ItemNo: Code[20])
    var
        ItemRegister: Record "Item Register";
        ValueEntry: Record "Value Entry";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetFilter("Cost Amount (Actual)", '<>%1', 0);
        ValueEntry.FindFirst();
        FromEntryNo := ValueEntry."Entry No.";
        ValueEntry.FindLast();
        ToEntryNo := ValueEntry."Entry No.";

        ItemRegister.SetRange("From Value Entry No.", FromEntryNo);
        ItemRegister.SetRange("To Value Entry No.", ToEntryNo);
        ItemRegister.FindFirst();
        ItemRegister.TestField("From Entry No.", 0);
        ItemRegister.TestField("To Entry No.", 0);
    end;

    local procedure VerifyJobPlanningLineInvoiceCorrespondsToJobLedgerEntries(var JobPlanningLine: Record "Job Planning Line"; DocType: Enum "Job Planning Line Invoice Document Type"; DocNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Document Type", DocType);
        JobPlanningLineInvoice.SetRange("Document No.", DocNo);
        JobPlanningLine.FindSet();
        repeat
            JobLedgerEntry.SetRange("Job No.", JobPlanningLine."Job No.");
            JobLedgerEntry.SetRange("No.", JobPlanningLine."No.");
            JobLedgerEntry.FindFirst();

            JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
            JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
            JobPlanningLineInvoice.FindFirst();
            JobPlanningLineInvoice.TestField("Job Ledger Entry No.", JobLedgerEntry."Entry No.");
        until JobPlanningLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobCalculateWIPRequestPageHandler(var JobCalculateWIP: TestRequestPage "Job Calculate WIP")
    begin
        JobCalculateWIP.PostingDate.SetValue(WorkDate());
        JobCalculateWIP.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        JobCalculateWIP.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToInvoiceHandler(var RequestPage: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        RequestPage.CreateNewInvoice.SetValue(true);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferToCreditMemoHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo.CreateNewCreditMemo.SetValue(true);
        JobTransferToCreditMemo.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.CreateNewInvoice.SetValue(LibraryVariableStorage.DequeueBoolean());
        JobTransferToSalesInvoice.AppendToSalesInvoiceNo.SetValue(LibraryVariableStorage.DequeueText());
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure JobTransferToSalesCrMemoRequestPageHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo.CreateNewCreditMemo.SetValue(LibraryVariableStorage.DequeueBoolean());
        JobTransferToCreditMemo.AppendToCreditMemoNo.SetValue(LibraryVariableStorage.DequeueText());
        JobTransferToCreditMemo.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalseReply(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure CreateJobTaskWithDimensions(var JobTask: Record "Job Task")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        GlobalDimensionValue: Record "Dimension Value";
        JobTaskDimension: Record "Job Task Dimension";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        InsertJobTaskDim(JobTaskDimension, JobTask, DimensionValue);
        LibraryDimension.FindDimensionValue(GlobalDimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        JobTask.Validate("Global Dimension 1 Code", GlobalDimensionValue.Code);
        LibraryDimension.FindDimensionValue(GlobalDimensionValue, LibraryERM.GetGlobalDimensionCode(2));
        JobTask.Validate("Global Dimension 2 Code", GlobalDimensionValue.Code);
        JobTask.Modify(true);
    end;

    local procedure CreateJobPlanningLineWithItem(var JobPlanningLine: Record "Job Planning Line")
    var
        JobTask: Record "Job Task";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        AddDiffUOMItemToJobPlanningLine(JobPlanningLine);
    end;

    local procedure CreateJobJnlLineFromJobPlanningLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    var
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        JobTransferLine: Codeunit "Job Transfer Line";
        JobJournalTemplateName: Code[10];
        JobJournalBatchName: Code[10];
    begin
        JobJournalTemplateName := LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        JobJournalBatchName := LibraryJob.CreateJobJournalBatch(JobJournalTemplateName, JobJournalBatch);
        JobTransferLine.FromPlanningLineToJnlLine(JobPlanningLine, 0D, JobJournalTemplateName, JobJournalBatchName, JobJournalLine);
    end;

    local procedure CreateJobPlanningLineWithTypeText(var JobPlanningLine: Record "Job Planning Line"; LineType: Enum "Job Planning Line Line Type"; JobTask: Record "Job Task")
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.FindFirst();
        LibraryJob.CreateJobPlanningLine(LineType, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Text);
        JobPlanningLine.Validate("No.", StandardText.Code);
        JobPlanningLine.Modify(true);
    end;

    local procedure AddDiffUOMItemToJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate("Unit of Measure Code", CreateItemUnitOfMeasure(Item));
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobPlanningLine.Validate("Qty. to Transfer to Journal", JobPlanningLine.Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure FindJobLedgerEntryByJob(var JobLedgerEntry: Record "Job Ledger Entry"; JobNo: Code[20]; JobPlanningLineNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("No.", JobPlanningLineNo);
        JobLedgerEntry.FindLast();
    end;

    local procedure CreateJobJournalLineWithDim(var JobJnlLine: Record "Job Journal Line")
    var
        JobTask: Record "Job Task";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.CreateJobJournalLineForType(LibraryJob.UsageLineTypeBoth(), LibraryJob.GLAccountType(), JobTask, JobJnlLine);
        JobJnlLine.Validate("No.", LibraryJob.FindConsumable(LibraryJob.GLAccountType()));
        JobJnlLine.Validate(Quantity, LibraryRandom.RandInt(100));
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionSetID := LibraryDimension.CreateDimSet(JobJnlLine."Dimension Set ID", Dimension.Code, DimensionValue.Code);
        JobJnlLine.Validate("Dimension Set ID", DimensionSetID);
        JobJnlLine.Modify(true);
    end;

    local procedure FindDimensionSetEntryByCode(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionSetID: Integer; DimensionCode: Code[20])
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
    end;

    local procedure FindSalesLineByDocumentType(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        JobPlanningLine.SetRange(Type, LibraryJob.GLAccountType());
        JobPlanningLine.SetRange("Line Type", LibraryJob.PlanningLineTypeContract());
        JobPlanningLine.FindLast();
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; DocNo: Code[20])
    begin
        PurchLine.SetRange("Document Type", DocType);
        PurchLine.SetRange("Document No.", DocNo);
        PurchLine.FindFirst();
    end;

    local procedure CreatePostJobJnlLineWithDimJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var DimensionCode: Code[20]; var JobJournalLineDimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        JobJournalLine: Record "Job Journal Line";
        JobPostingGroup: Record "Job Posting Group";
    begin
        CreateJobJournalLineWithDim(JobJournalLine);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, JobJournalLine."Dimension Set ID");
        DimensionCode := DimensionSetEntry."Dimension Code";
        JobJournalLineDimSetID := JobJournalLine."Dimension Set ID";
        JobPostingGroup.FindLast();
        JobPostingGroup.Validate("G/L Expense Acc. (Contract)", LibraryJob.FindConsumable(LibraryJob.GLAccountType()));
        JobPostingGroup.Modify(true);
        LibraryJob.PostJobJournal(JobJournalLine);
        FindJobPlanningLine(JobPlanningLine, JobJournalLine."Job No.", JobJournalLine."Job Task No.");
    end;

    local procedure VerifyPurchaseLineArchive(PurchaseLine: Record "Purchase Line"; PurchaseLineArchive: Record "Purchase Line Archive")
    begin
        PurchaseLineArchive.TestField("Job Currency Code", PurchaseLine."Job Currency Code");
        PurchaseLineArchive.TestField("Job Currency Factor", PurchaseLine."Job Currency Factor");
        PurchaseLineArchive.TestField("Job Line Amount", PurchaseLine."Job Line Amount");
        PurchaseLineArchive.TestField("Job Line Amount (LCY)", PurchaseLine."Job Line Amount (LCY)");
        PurchaseLineArchive.TestField("Job Line Disc. Amount (LCY)", PurchaseLine."Job Line Disc. Amount (LCY)");
        PurchaseLineArchive.TestField("Job Line Discount %", PurchaseLine."Job Line Discount %");
        PurchaseLineArchive.TestField("Job Line Discount Amount", PurchaseLine."Job Line Discount Amount");
        PurchaseLineArchive.TestField("Job Line Type", PurchaseLine."Job Line Type");
        PurchaseLineArchive.TestField("Job No.", PurchaseLine."Job No.");
        PurchaseLineArchive.TestField("Job Planning Line No.", PurchaseLine."Job Planning Line No.");
        PurchaseLineArchive.TestField("Job Remaining Qty.", PurchaseLine."Job Remaining Qty.");
        PurchaseLineArchive.TestField("Job Remaining Qty. (Base)", PurchaseLine."Job Remaining Qty. (Base)");
        PurchaseLineArchive.TestField("Job Task No.", PurchaseLine."Job Task No.");
        PurchaseLineArchive.TestField("Job Total Price", PurchaseLine."Job Total Price");
        PurchaseLineArchive.TestField("Job Total Price (LCY)", PurchaseLine."Job Total Price (LCY)");
        PurchaseLineArchive.TestField("Job Unit Price", PurchaseLine."Job Unit Price");
        PurchaseLineArchive.TestField("Job Unit Price (LCY)", PurchaseLine."Job Unit Price (LCY)");
    end;

    local procedure CreateDimensionWithDimensionValues(var DimensionCode: Code[20]; var DimensionValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionCode := DimensionValue."Dimension Code";
        LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
        DimensionValueCode := DimensionValue.Code;
    end;

    local procedure CreateJobTaskWithDimension(
        var JobTask: Record "Job Task";
        ShortcudDim3: Code[20];
        ShortcudDim4: Code[20];
        var DimensionValueCode: array[3] of Code[20])
    var
        Job: Record Job;
        DimensionCode: Code[20];
    begin
        DimensionCode := CreateJobWithDimension(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        DimensionValueCode[1] := UpdateDimensionOnJobTask(JobTask, DimensionCode);
        CreateJobTaskDimension(Job."No.", JobTask."Job Task No.", ShortcudDim3, DimensionValueCode[2]);
        CreateJobTaskDimension(Job."No.", JobTask."Job Task No.", ShortcudDim4, DimensionValueCode[3]);
    end;

    local procedure CreateJobTaskDimension(JobNo: Code[20]; JobTaskNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        JobTaskDimension: Record "Job Task Dimension";
    begin
        JobTaskDimension.Init();
        JobTaskDimension.Validate("Job No.", JobNo);
        JobTaskDimension.Validate("Job Task No.", JobTaskNo);
        JobTaskDimension.Validate("Dimension Code", DimensionCode);
        JobTaskDimension.Validate("Dimension Value Code", DimensionValueCode);
        JobTaskDimension.Insert(true);
    end;

    local procedure CreateJobJournalLine(
        var JobJournalPage: TestPage "Job Journal";
        JobTask: Record "Job Task")
    begin
        JobJournalPage.OpenEdit();
        JobJournalPage.New();
        JobJournalPage."Job No.".SetValue(JobTask."Job No.");
        JobJournalPage."Job Task No.".SetValue(JobTask."Job Task No.");
        JobJournalPage."Line Type".SetValue("Job Line Type"::Budget);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobJournalTemplateListPageHandler(var JobJournalTemplateListPage: TestPage "Job Journal Template List")
    begin
        JobJournalTemplateListPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerMultipleResponses(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerifyQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceReportHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
        PostedPurchaseDocumentLines.PostedRcpts.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingOption::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::"Assign Serial No.":
                ItemTrackingLines."Assign Serial No.".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobInvoicesDetailsVisibleModalPageHandler(var JobInvoices: TestPage "Job Invoices")
    begin
        Assert.IsTrue(JobInvoices."Transferred Date".Visible(), JobInvoices."Transferred Date".Caption);
        Assert.IsTrue(JobInvoices."Invoiced Date".Visible(), JobInvoices."Invoiced Date".Caption);
        Assert.IsTrue(JobInvoices."Job Ledger Entry No.".Visible(), JobInvoices."Job Ledger Entry No.".Caption);
    end;

    local procedure GetSalesHeaderFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; var SalesHeader: Record "Sales Header"; isInvoice: Boolean)
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        if JobPlanningLine."Line No." = 0 then
            exit;
        JobPlanningLine.TestField("Job No.");
        JobPlanningLine.TestField("Job Task No.");

        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        if JobPlanningLineInvoice.FindFirst() then
            if isInvoice then
                SalesHeader.Get(SalesHeader."Document Type"::Invoice, JobPlanningLineInvoice."Document No.")
            else
                SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", JobPlanningLineInvoice."Document No.");
    end;

    local procedure CreateSalesInvoiceWithDates(var SalesHeader: Record "Sales Header"; JobTask: Record "Job Task"; PostingDate: Date; DocumentDate: Date)
    begin
        Commit();
        JobTask.SetRecFilter();
        REPORT.Run(REPORT::"Job Create Sales Invoice", true, false, JobTask);

        SalesHeader.Reset();
        SalesHeader.SetRange("Posting Date", PostingDate);
        SalesHeader.SetRange("Document Date", DocumentDate);
        SalesHeader.FindFirst();
    end;

    local procedure CreateSimpleSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        RecRef.GetTable(SalesLine);
        SalesLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, SalesLine.FieldNo("Line No.")));
    end;

    local procedure CreateSimpleSalesInvoiceFromJobPlanningLineWithLineDiscountPct(
        var SalesHeader: Record "Sales Header";
        var JobPlanningLine: Record "Job Planning Line";
        LineType: Enum "Job Planning Line Line Type";
        QtyInvoiceFraction: Decimal;
        LineDiscountPct: Decimal): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateJob(Job, '', false);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LineType, LibraryJob.ResourceType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Line Discount %", LineDiscountPct);
        JobPlanningLine.Modify(true);
        TransferJobPlanningLine(JobPlanningLine, QtyInvoiceFraction, false, SalesHeader);
        exit(Job."No.");
    end;

    local procedure CreateJobAndJobTaskWithBillingMethod(var JobTask: Record "Job Task"; TaskBillingMethod: Enum "Task Billing Method")
    var
        Customer: Record Customer;
        Job: Record Job;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.Validate("Task Billing Method", TaskBillingMethod);
        Job.Modify(true);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateThreeJobPlanningLinesWithItem(JobTask: Record "Job Task"; var JobPlanningLine: array[3] of Record "Job Planning Line")
    var
        Item: array[3] of Record Item;
        i: Integer;
    begin
        for i := 1 to ArrayLen((Item)) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateJobPlanningLineWithItem(JobPlanningLine[i], JobTask, JobPlanningLine[i]."Line Type"::"Both Budget and Billable", Item[i]."No.", LibraryRandom.RandIntInRange(1, 10));
        end;
    end;

    local procedure GetSalesInvoiceDocumentList(
       JobPlanningLine: Record "Job Planning Line";
       DocumentType: Enum "Sales Document Type";
       var InvoicesList: List of [Code[20]])
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLineInvoice.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        if DocumentType = DocumentType::Invoice then
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::Invoice)
        else
            JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::"Credit Memo");
        if JobPlanningLineInvoice.FindSet() then
            Repeat
                if not InvoicesList.Contains(JobPlanningLineInvoice."Document No.") then
                    InvoicesList.Add(JobPlanningLineInvoice."Document No.");
            until JobPlanningLineInvoice.Next() = 0;
    end;

    local procedure UpdateQuantityInJobPlanningLine(JobNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.FindSet();
        repeat
            JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(1, 10));
            JobPlanningLine.Modify();
        until JobPlanningLine.Next() = 0;
    end;

    local procedure CreateAndPostJobJournalLineWithIteAndType(var JobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task"; JobLineType: Enum "Job Line Type")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJobJournalLine(JobLineType, JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", Item."No.");
        JobJournalLine.Validate(Quantity, LibraryRandom.RandInt(100));
        JobJournalLine.Modify(true);

        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferSalesCreditMemoReportWithDatesHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo.PostingDate.SetValue(WorkDate() + 20);
        JobTransferToCreditMemo."Document Date".SetValue(WorkDate() + 10);
        JobTransferToCreditMemo.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceReportWithDatesHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice.PostingDate.SetValue(WorkDate() + 20);
        JobCreateSalesInvoice."Document Date".SetValue(WorkDate() + 10);
        JobCreateSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferSalesInvoiceReportWithDatesHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.PostingDate.SetValue(WorkDate() + 20);
        JobTransferToSalesInvoice."Document Date".SetValue(WorkDate() + 10);
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoHandler2(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo."Document Date".SetValue(WorkDate());
        JobTransferToCreditMemo.PostingDate.SetValue(WorkDate() + 10);
        Assert.AreNotEqual(JobTransferToCreditMemo.PostingDate.AsDate(), JobTransferToCreditMemo."Document Date".AsDate(), 'Wrong Document Date');
        JobTransferToCreditMemo.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToCreditMemoHandler(var JobTransferToCreditMemo: TestRequestPage "Job Transfer to Credit Memo")
    begin
        JobTransferToCreditMemo."Document Date".SetValue(WorkDate());
        JobTransferToCreditMemo.PostingDate.SetValue(WorkDate() + 10);
        Assert.AreEqual(JobTransferToCreditMemo.PostingDate.AsDate(), JobTransferToCreditMemo."Document Date".AsDate(), 'Wrong Document Date');
        JobTransferToCreditMemo.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice."Document Date".SetValue(WorkDate());
        JobTransferToSalesInvoice.PostingDate.SetValue(WorkDate() + 10);
        Assert.AreEqual(JobTransferToSalesInvoice.PostingDate.AsDate(), JobTransferToSalesInvoice."Document Date".AsDate(), 'Wrong Document Date');
        JobTransferToSalesInvoice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceHandler2(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice."Document Date".SetValue(WorkDate());
        JobTransferToSalesInvoice.PostingDate.SetValue(WorkDate() + 10);
        Assert.AreNotEqual(JobTransferToSalesInvoice.PostingDate.AsDate(), JobTransferToSalesInvoice."Document Date".AsDate(), 'Wrong Document Date');
        JobTransferToSalesInvoice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceHandler(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice."Document Date".SetValue(WorkDate());
        JobCreateSalesInvoice.PostingDate.SetValue(WorkDate() + 10);
        Assert.AreEqual(JobCreateSalesInvoice.PostingDate.AsDate(), JobCreateSalesInvoice."Document Date".AsDate(), 'Wrong Document Date');
        JobCreateSalesInvoice.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceHandler2(var JobCreateSalesInvoice: TestRequestPage "Job Create Sales Invoice")
    begin
        JobCreateSalesInvoice."Document Date".SetValue(WorkDate());
        JobCreateSalesInvoice.PostingDate.SetValue(WorkDate() + 10);
        Assert.AreNotEqual(JobCreateSalesInvoice.PostingDate.AsDate(), JobCreateSalesInvoice."Document Date".AsDate(), 'Wrong Document Date');
        JobCreateSalesInvoice.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure GetJobPlanLines(var GetJobPlanningLines: TestPage "Get Job Planning Lines")
    begin
        GetJobPlanningLines.OK().Invoke();
    end;

    [SendNotificationHandler]
    procedure CreateSalesNotificationHandler(var Notification: Notification): Boolean
    var
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CorrectPostedSalesInvoice.CreateCorrectiveCreditMemo(Notification); // simulate 'Create credit memo anyway' action
    end;
}

