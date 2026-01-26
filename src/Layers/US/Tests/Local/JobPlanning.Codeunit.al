codeunit 144016 "Job Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Planning] [Sales] [Invoice]
    end;

    var
        JobsUtil: Codeunit "Library - Job";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,JobTransferToPlanningLineRequestPageHandler,JobTransferToSalesInvoiceRequestPageHandler,SalesInvoiceModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceFromJobPlanningLineWithUnitOfMeasure()
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        LineAmount: Variant;
        SellToCustomerNo: Variant;
        DocumentNo: Code[20];
    begin
        // Verify Sales Invoice Created and Posted from the Job Planning Billable Lines without any error, when Item having multiple decimal places in Quantity per Unit of Measure.

        // Setup: Create Job Planning Line, Create and Post Job Journal Line, Job Transfer To Planning Line.
        CreateJobPlanningLine(JobPlanningLine, JobTask);
        DocumentNo := CreateAndPostJobJournalLine(JobTask, JobPlanningLine);
        TransferJobLedgerEntryToPlanningLine(JobPlanningLine."Job No.");

        // Exercise: Create and Post Sales Invoice from Job Planning Line.
        CreateAndPostSalesInvoiceFromJobPlanningLine(JobPlanningLine."Job No.", DocumentNo);

        // Verify: Verify General Ledger Entry Amount with Sales Invoice Line Amount.
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        LibraryVariableStorage.Dequeue(LineAmount);
        VerifyGeneralLedgerEntry(JobTask."Job No.", LineAmount, SellToCustomerNo);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        JobsUtil.CreateJob(Job, CreateCustomer());
        JobsUtil.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var JobTask: Record "Job Task")
    var
        Location: Record Location;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        CreateJobTask(JobTask);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure);
        JobsUtil.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemUnitOfMeasure."Item No.");
        JobPlanningLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandDecInDecimalRange(10, 100, 2));  // Quantity more than JobJournalLine - Quantity.
        JobPlanningLine.Validate("Location Code", LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateAndPostJobJournalLine(JobTask: Record "Job Task"; JobPlanningLine: Record "Job Planning Line") DocumentNo: Code[20]
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        JobsUtil.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", JobPlanningLine."No.");
        JobJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        JobJournalLine.Validate("Unit of Measure Code", JobPlanningLine."Unit of Measure Code");
        JobJournalLine.Validate("Location Code", JobPlanningLine."Location Code");
        JobJournalLine.Modify(true);
        DocumentNo := JobJournalLine."Document No.";
        JobsUtil.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateAndPostSalesInvoiceFromJobPlanningLine(JobNo: Code[20]; DocumentNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Line Type", JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.SetRange("Document No.", DocumentNo);
        JobPlanningLine.FindFirst();
        JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);  // Create Sales Invoice, Request Page Handler - JobTransferToSalesInvoiceRequestPageHandler
        JobCreateInvoice.GetJobPlanningLineInvoices(JobPlanningLine);  // Open Sales Invoice in Page Handler -SalesInvoiceModalPageHandler and Post Sales Invoice in Handler.
    end;

    local procedure TransferJobLedgerEntryToPlanningLine(JobNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTransferToPlanningLine: Report "Job Transfer To Planning Lines";
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobTransferToPlanningLine.GetJobLedgEntry(JobLedgerEntry);
        JobTransferToPlanningLine.Run();  // Added Request Page Handler - JobTransferToPlanningLineRequestPageHandler
    end;

    local procedure VerifyGeneralLedgerEntry(JobNo: Code[20]; Amount: Decimal; SourceNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Job No.", JobNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Sale);
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Customer);
        GLEntry.FindFirst();
        GLEntry.TestField("Source No.", SourceNo);
        GLEntry.TestField(Amount, -Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToPlanningLineRequestPageHandler(var JobTransferToPlanningLine: TestRequestPage "Job Transfer To Planning Lines")
    var
        LineType: Option Budget,Billable;
    begin
        JobTransferToPlanningLine.TransferTo.SetValue(LineType::Billable);
        JobTransferToPlanningLine.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure JobTransferToSalesInvoiceRequestPageHandler(var JobTransferToSalesInvoice: TestRequestPage "Job Transfer to Sales Invoice")
    begin
        JobTransferToSalesInvoice.CreateNewInvoice.SetValue(true);
        JobTransferToSalesInvoice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceModalPageHandler(var SalesInvoice: TestPage "Sales Invoice")
    begin
        // Enqueue value for General Ledger Entry verification.
        LibraryVariableStorage.Enqueue(SalesInvoice."Sell-to Customer Name".Value);
        LibraryVariableStorage.Enqueue(SalesInvoice.SalesLines."Line Amount".AsDecimal());
        LibrarySales.DisableConfirmOnPostingDoc();
        SalesInvoice.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

