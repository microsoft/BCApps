codeunit 132521 "JOBs-60SP1-Scripts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job] [Purchase]
        Initialized := false;
    end;

    var
        DummyJobsSetup: Record "Jobs Setup";
        Assert: Codeunit Assert;
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Text006: Label 'There is no record in TempPurchHeader.';
        Text007: Label 'Project Planning Line table is missing record for the Purchase Line created.';
        Text008: Label 'There is no Schedule Line created in Project Planning Line for Line Type: Both Schedule and Contract.';
        Text009: Label 'There is no Contract Line created in Project Planning Line for Line Type: Both Schedule and Contract.';
        Text010: Label 'Number of Schedule Lines in Project Planning Line is not equal to the Schedule Lines created in Purchase Line.';
        Text011: Label 'Number of Contract Lines in Project Planning Line is not equal to the Contract Lines created in Purchase Line.';
        Text012: Label 'There is no matching record in Project Ledger Entry for the Purchase Line.';
        Text013: Label 'Project Planning Line - (Planning Date) <> Purchase Line - (Posting Date).';
        Text014: Label 'Project Planning Line - (Project No.) <> Purchase Line - (Project No.).';
        Text015: Label 'Project Planning Line - (Project Task No.) <> Purchase Line - (Project Task No.).';
        Text016: Label 'Project Planning Line - (Quantity) <> Purchase Line - (Qty. to Receive).';
        Text017: Label 'Project Planning Line - (Unit Cost) <> Purchase Line - (Unit Cost).';
        Text018: Label 'Project Planning Line - (Line Discount Amount) <> Purchase Line - (Project Line Discount Amount).';
        Text019: Label 'Project Planning Line - (Total Cost) <> Project Planning Line - (Quantity * Unit Cost).';
        Text020: Label 'Project Planning Line - (Line Amount) <> Project Planning Line - (Quantity * Unit Cost - Line Discount Amount).';
        Text021: Label 'Project Ledger Entry - (Planning Date) <> Purchase Line - (Posting Date).';
        Text022: Label 'Project Ledger Entry - (Project No.) <> Purchase Line - (Project No.).';
        Text023: Label 'Project Ledger Entry - (Project Task No.) <> Purchase Line - (Project Task No.).';
        Text024: Label 'Project Ledger Entry - (Quantity) <> Purchase Line - (Qty. to Receive).';
        Text025: Label 'Project Ledger Entry - (Quantity) <> Purchase Line - (Qty. to Invoice).';
        Text026: Label 'Project Ledger Entry - (Unit Cost) <> Purchase Line - (Unit Cost).';
        Text027: Label 'Project Ledger Entry - (Line Discount Amount) <> Purchase Line - (Project Line Discount Amount).';
        Text028: Label 'Project Ledger Entry - (Total Cost) <> Project Ledger Entry - (Quantity * Unit Cost).';
        Text029: Label 'Project Ledger Entry - (Line Amount) <> Project Ledger Entry - (Quantity * Unit Cost - Line Discount Amount).';
        Text030: Label 'There should be no record in Project Planning Line for a PO posted with Receive option.';
        Initialized: Boolean;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"JOBs-60SP1-Scripts");

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"JOBs-60SP1-Scripts");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        DummyJobsSetup."Allow Sched/Contract Lines Def" := false;
        DummyJobsSetup."Apply Usage Link by Default" := false;
        DummyJobsSetup.Modify();
        LibraryJob.SetJobNoSeriesCode();

        Initialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"JOBs-60SP1-Scripts");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73007()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Steps describing the sequence of actions for Test Case No:73007 in TFS.
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Charge(Item), No. = P-ALLOWANCE(Purchase Allowance),Quantity  11, Job No. = New Job, Job Task No. =
        // 7. Post the PO.
        // 8. Check that its impossible to post it
        // --------------------------------------------------------------------------------------------------------------------------

        // Create a Customer, Vendor, Job and Job Task Line for each test case as it will rollback the creation of data once an error
        // is encountered.  So the next-in-line testcases will have no data present.
        // Setup.
        Initialize();
        PurchaseOrderWithDifferentLineType(PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73008()
    var
        JobTask: Record "Job Task";
    begin
        // Steps describing the sequence of actions for Test Case No:73008 in TFS.
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line of type EndTotal for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Item 1000, Qty = 5 Job No. = New Job, Job Task No. = New Job Task, Job Line Type = Schedule
        // 7. Post the PO.
        // 8. Check that its impossible to post it
        // ---------------------------------------------------------------------------------------------------------------------------------
        // Setup.
        Initialize();
        PurchaseOrderWithDifferentJobTaskType(JobTask."Job Task Type"::"End-Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73009()
    var
        JobTask: Record "Job Task";
    begin
        // Steps describing the sequence of actions for Test Case No:73009 in TFS.
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line of type 'Total' for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Item 1000, Qty = 5 Job No. = New Job, Job Task No. = New Job Task, Job Line Type = Schedule
        // 7. Post the PO.
        // 8. Check that its impossible to post it
        // ---------------------------------------------------------------------------------------------------------------------------------

        Initialize();
        PurchaseOrderWithDifferentJobTaskType(JobTask."Job Task Type"::Total);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73010()
    var
        JobTask: Record "Job Task";
    begin
        // Steps describing the sequence of actions for Test Case No:73010 in TFS.
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line of type 'Begin-Total' for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Item 1000, Qty = 5 Job No. = New Job, Job Task No. = New Job Task, Job Line Type = Schedule
        // 7. Post the PO.
        // 8. Check that its impossible to post it
        // ---------------------------------------------------------------------------------------------------------------------------------

        // Setup.
        Initialize();
        PurchaseOrderWithDifferentJobTaskType(JobTask."Job Task Type"::"Begin-Total");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73013()
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
    begin
        // Steps explaining the Scenario and sequence of actions for the TFS Tescase No:73013

        // Step 1.  Create a new Customer with auto-generated Customer No.
        // Step 2.  Create a new Vendor with auto-generated Vendor No.
        // Step 3.  Create a new Job with auto-generated Job No. and assign the newly created Customer No.
        // to the Bill-to Customer field in Job Card.
        // Step 4.  Create a Job Task Line for that partucular Job created above.
        // Step 5.  Create a Purchase Order with 8 purchase lines, 4 of type 'G/L Account' and 4 of type 'Item'.
        // Step 6.  Post the Purchase Order.
        // Step 7.  Compare the entries in Job Planning Line with the Purchase Order entries before posting.
        // Step 8.  Compare the entries in Job Ledger Entries with the Purchase Order entries before posting.
        // -----------------------------------------------------------------------------------------------------------------

        Initialize();

        // Create a Purchase Order with three Purchase Lines and Post it with Receive & Invoice option.
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreatePurchaseOrderWithMultipleLines(PurchaseHeader, JobTask);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), PurchaseLine."Job Line Type"::Budget);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), PurchaseLine."Job Line Type"::"Both Budget and Billable");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), PurchaseLine."Job Line Type"::Billable);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), PurchaseLine."Job Line Type"::" ");

        // Make a copy of the Purchase Order before posting it.
        CopyHeaderLines(PurchaseHeader."No.", TempPurchHeader, TempPurchLine);

        // Post the Purchase Order with option 'Receive & Invoice'.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify the Copy of the Purchase Order made before posting with the Job Planning Line
        VerifyJobPlanWithPurchOrder(TempPurchHeader, TempPurchLine);

        // Verify the copy of the Purchase Order made before posting with the Job Ledger Entry
        VerifyJobLedgerWithPurchOrder(TempPurchHeader, TempPurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73019()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Steps describing the sequence of actions for Test Case No:73019 in TFS.
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Fixed Asset, No. =FA000010(Mercedes 300), Quantity 1, Job No. = New Job, Job Task No. = New Job Ta
        // 7. Post the PO.
        // 8. Check that its impossible to post it.
        // ---------------------------------------------------------------------------------------------------------------------------------
        Initialize();
        PurchaseOrderWithDifferentLineType(PurchaseLine.Type::"Fixed Asset", FindFixedAsset());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73021()
    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        // Steps explaining the Scenario and sequence of actions for TFS Testcase No:73021
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Item 1000, Qty = 5 Job No. = New Job, Job Task No. = New Job Task, Job Line Type = Schedule
        // 7. Create a Purchase Line for Item 1001, Qty = 6 Job No. = New Job, Job Task No.=New Job Task,Job Line Type = Both Schedule and C
        // 8. Create another Purchase Header for new Vendor
        // 9. Create a Purchase Line for Item 1110, Qty = 7 Job No. = New Job, Job Task No.=New Job Task, Job Line Type = Contract
        // 10. Create a Purchase Line for Item 1110, Qty = 8 Job No. = New Job, Job Task No.=New Job Task, Job Line Type = ''
        // 11. Run the Batch Posting Purchase order report for receipt and invoice

        // Validate that it creates correct entries in Job Planning Line and Job Ledger Entry
        // ---------------------------------------------------------------------------------------------------------------------------------

        Initialize();

        // Create a Purchase Header and 2 Purchase Lines for the first PO
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::Budget);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::Item, CreateItem(),
          PurchaseLine."Job Line Type"::"Both Budget and Billable");

        // Make a copy of the Purchase Order before posting it.
        CopyHeaderLines(PurchaseHeader."No.", TempPurchHeader, TempPurchLine);

        // Post the PO.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create a Purchase Header and 2 Purchase Lines for the second PO
        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader2, JobTask, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::Billable);
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader2, JobTask, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::" ");

        // Make a copy of the Purchase Order before posting it.
        CopyHeaderLines(PurchaseHeader2."No.", TempPurchHeader, TempPurchLine);

        // Post the PO.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, true);

        // Validate the Purchase Orders with Job Planning Line.
        VerifyJobPlanWithPurchOrder(TempPurchHeader, TempPurchLine);
        // Validate the Purchase Orders with Job Ledger Entry.
        VerifyJobLedgerWithPurchOrder(TempPurchHeader, TempPurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73022()
    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
    begin
        // Steps explaining the Scenario and sequence of actions for TFS Testcase No:73022

        // 1. Create a Customer
        // 2. Create a Vendor
        // 3. Create a Job: Set the new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line for the job: Fill out No. and Description
        // 5. Create a Purchase Header for the new Vendor.
        // 6. Create a Purchase Line for Item 1001, Qty=5, Job No.=New Job, Job Task No.=New Job Task,
        // Job Line Type=Schedule, Qty.to Receive=3
        // 7. Create a Purchase Line for Item 1000, Qty=6, Job No.=New Job, Job Task No.=New Job Task,
        // Job Line Type=Both Schedule and contract, Qty. to Receive=3.
        // 8. Create a Purchase Line for Item 1000, Qty=7, Job No.=New Job, Job Task No.=New Job Task, Job Line Type=Contract,
        // Qty. to Receive = 5.
        // 9. Create a Purchase Line for Item 1000, Qty=8,Job No.=New Job, Job Task No.=New Job Task, Job Line Type=''
        // Qty. to Receive = 7
        // 10. Post the the Purchase Order as Receipt
        // 11. Validate that no Job Planning Lines have been created
        // 12. Post the the Purchase Order as Invoice
        // 13. Validate that there are lines created in Job Planning Line and Job Ledger Entry.
        // 14. Post the remaining quantities in rest of the order as receipt and invoice.
        // 15. Validate that there are lines created in Job Planning Line and Job Ledger Entry.

        // Validation:
        // Step 13 should create 4 Planning line, 2 of Type Schedule and 2 of type Contract
        // and 4 Ledger entry with same Qty. as Qty. to Receiv
        // Step 15 should create 4 new Planning lines, 2 of Type Schedule and 2 of type Contract
        // and 4 Ledger entry with  Qty. as the Remaining
        // ------------------------------------------------------------------------------------------------------------------------

        Initialize();

        // Create a Purchase Header and 4 Purchase Lines for Partial Invoicing
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreatePurchaseOrderWithMultipleLines(PurchaseHeader, JobTask);

        // Make a copy of the Purchase Order before posting it.
        CopyHeaderLines(PurchaseHeader."No.", TempPurchHeader, TempPurchLine);

        // Post the Purchase Order with option 'Receive'.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify if there are no lines created in the Job Planning Lines as the PO was posted with only 'Receive' option.
        VerifyJobPlanForNoLines(TempPurchLine);

        // Post the Purchase Order with Option 'Invoice'.
        PurchaseHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify Job Planning Lines if there are entries created for the PO Invoice.
        VerifyJobPlanWithPurchOrder(TempPurchHeader, TempPurchLine);
        // Verify Job Ledger Entry if there are entries created for the PO Invoice.
        VerifyJobLedgerWithPurchOrder(TempPurchHeader, TempPurchLine);

        // Make a copy of the Purchase Order after Invoicing it as it was a Partial Invoice and 'Qty. to Receive' would be different now.
        // Delete the records in TempPurchHeader and TempPurchLine.
        TempPurchHeader.DeleteAll();
        TempPurchLine.DeleteAll();
        CopyHeaderLines(PurchaseHeader."No.", TempPurchHeader, TempPurchLine);

        // Post the Purchase Order with Option 'Receive & Invoice' for the Remaining Quantities.
        // The Vendor Invoice No. should be a different one, for creating an Invoice again.
        // So Modify the Purchase Header by passing a different Vendor Invoice Number.
        PurchaseHeader.Find();
        PurchaseHeader.Validate("Vendor Invoice No.", JobTask."Job No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify Job Planning Lines if there are entries created for the Remaining Quantities.
        VerifyJobPlanWithPurchOrder(TempPurchHeader, TempPurchLine);
        // Verify Job Ledger Entry if there are entries created for the Remaining Quantities.
        VerifyJobLedgerWithPurchOrder(TempPurchHeader, TempPurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TC73024()
    var
        TempPurchHeader: Record "Purchase Header" temporary;
        TempPurchLine: Record "Purchase Line" temporary;
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
        PurchInvoiceNo: Code[20];
    begin
        // Steps explaining the Scenario and sequence of actions for TFS Testcase No:73024
        // 1. Create Customer
        // 2. Create Vendor
        // 3. Create Job: Set new Customer as Bill-to Customer and set Job Posting Group as SETTING UP
        // 4. Create a Job Task Line for the job: Fill out No. and Description
        // 5. Create a Purchase Header for new Vendor
        // 6. Create a Purchase Line for Item 1000, Qty = 5 Job No. = New Job, Job Task No. = New Job Task, Job Line Type = Schedule
        // 7.Create a Purchase Line for Item 1001, Qty = 6 Job No. = New Job, Job Task No.=New Job Task, Job Line Type = Both Schedule and C
        // 8.Create a Purchase Line for Item 1110, Qty = 7 Job No. = New Job, Job Task No.=New Job Task, Job Line Type = Contract
        // 9.Create a Purchase Line for Item 1120, Qty = 8 Job No. = New Job, Job Task No.=New Job Task, Job Line Type = ''
        // 10. Post a Purchase Receipt from the Order.
        // 11. Create a new Purchase Invoice for the same vendor
        // 12. Use the Actions -> Get Receipt lines fuction
        // 13. Post the Invoice
        // Validation:
        // Step 13 should create 3 Planning lines of 2 of type Schedule, one of type Contract and 3 Ledger entries
        // -----------------------------------------------------------------------------------------------------------------------------

        Initialize();

        // Create a Purchase Header and 4 Purchase Lines for Partial Receipt
        CreateJobTask(JobTask, JobTask."Job Task Type"::Posting);
        CreatePurchaseOrderWithMultipleLines(PurchaseHeader, JobTask);
        // Make a copy of the Purchase Order before posting it.
        CopyHeaderLines(PurchaseHeader."No.", TempPurchHeader, TempPurchLine);

        // Post the Purchase Order with option 'Receive'.
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify if there are no lines created in the Job Planning Lines as the PO was posted with only 'Receive' option.
        VerifyJobPlanForNoLines(TempPurchLine);

        // Create a Purchase Invoice Header for the particular vendor.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Buy-from Vendor No.");

        // Create the Purchase Invoice Lines by using 'Get Receipt Lines' in Functions menubutton.
        CreatePurchaseInvoiceLines(PurchInvoiceNo, PurchaseHeader."No.");

        // Post the Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Validate the Purchase Order with Job Planning Lines
        VerifyJobPlanWithPurchOrder(TempPurchHeader, TempPurchLine);

        // Validate the Purchase Order with Job Ledger Entry
        VerifyJobLedgerWithPurchOrder(TempPurchHeader, TempPurchLine);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateJobTask(var JobTask: Record "Job Task"; JobTaskType: Enum "Job Task Type")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate("Job Task Type", JobTaskType);
        JobTask.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Due Date", WorkDate());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceLines(DocumentNo: Code[20]; PurchaseInvoiceNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, PurchaseInvoiceNo);
        // Set the Purchase Header
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);

        // Set filter to all the receipt lines that are posted for the Purchase Order
        PurchRcptLine.SetRange("Document No.", DocumentNo);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task"; Type: Enum "Purchase Line Type"; No: Code[20]; JobLineType: Enum "Job Line Type")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Job Line Type", JobLineType);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithPartialQuantity(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task"; Type: Enum "Purchase Line Type"; No: Code[20]; JobLineType: Enum "Job Line Type")
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, JobTask, Type, No, JobLineType);
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);  // Partial Quantity.
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Invoice");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithJob(JobTaskType: Enum "Job Task Type"; LineType: Enum "Purchase Line Type"; No: Code[20]; JobLineType: Enum "Job Line Type")
    var
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateJobTask(JobTask, JobTaskType);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, JobTask, LineType, No, JobLineType);
    end;

    local procedure CreatePurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; JobTask: Record "Job Task")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        CreatePurchaseLineWithPartialQuantity(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::Budget);
        CreatePurchaseLineWithPartialQuantity(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::Item, CreateItem(),
          PurchaseLine."Job Line Type"::"Both Budget and Billable");
        CreatePurchaseLineWithPartialQuantity(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::Billable);
        CreatePurchaseLineWithPartialQuantity(
          PurchaseLine, PurchaseHeader, JobTask, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::" ");
    end;

    local procedure CreateVendor(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.FindFirst();
        exit(FixedAsset."No.");
    end;

    local procedure PurchaseOrderWithDifferentJobTaskType(JobTaskType: Enum "Job Task Type")
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        // Exercise.
        asserterror CreatePurchaseOrderWithJob(JobTaskType, PurchaseLine.Type::Item, CreateItem(), PurchaseLine."Job Line Type"::Budget);

        // Verify: Verify error message.
        Assert.ExpectedTestFieldError(JobTask.FieldCaption("Job Task Type"), Format(JobTask."Job Task Type"::Posting));
    end;

    local procedure PurchaseOrderWithDifferentLineType(Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        JobTask: Record "Job Task";
    begin
        // Exercise.
        asserterror CreatePurchaseOrderWithJob(JobTask."Job Task Type"::Posting, Type, No, PurchaseLine."Job Line Type"::Budget);

        // Verify: Verify error message.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Job No."), '');
    end;

    local procedure VerifyJobPlanWithPurchOrder(var TempPurchHeader: Record "Purchase Header" temporary; var TempPurchLine: Record "Purchase Line" temporary)
    var
        JobPlanLine: Record "Job Planning Line";
        PurchSchedule: Integer;
        PurchContract: Integer;
        JobSchedule: Integer;
        JobContract: Integer;
    begin
        if not TempPurchHeader.FindFirst() then
            Error(Text006);

        // Verify Job Planning Line fields with Purchase Invoice fields.
        // For each Purchase Line in TempPurchLine, find out the corresponding matching line in Job Planning Line table and Compare both.
        if TempPurchLine.FindFirst() then
            repeat
                Clear(JobPlanLine);
                // Find the particular Line type of 'Schedule' in Job Planning Line.
                JobPlanLine.SetRange("Job No.", TempPurchLine."Job No.");
                JobPlanLine.SetRange("Job Task No.", TempPurchLine."Job Task No.");
                JobPlanLine.SetRange(Quantity, TempPurchLine."Qty. to Receive");
                JobPlanLine.SetRange(Description, TempPurchLine.Description);

                // Find the corresponding Job Planning Lines if Job Line Type is 'Schedule' or 'Contract'.
                if (TempPurchLine."Job Line Type" = TempPurchLine."Job Line Type"::Budget) or
                   (TempPurchLine."Job Line Type" = TempPurchLine."Job Line Type"::Billable)
                then begin
                    // Count how many 'Schedule' and 'Contract' are there in TempPurchLine.
                    if TempPurchLine."Job Line Type" = TempPurchLine."Job Line Type"::Budget then
                        PurchSchedule := PurchSchedule + 1
                    else
                        if TempPurchLine."Job Line Type" = TempPurchLine."Job Line Type"::Billable then
                            PurchContract := PurchContract + 1;

                    // Find the respective Job Planning Line.
                    JobPlanLine.SetRange("Line Type", "Job Planning Line Line Type".FromInteger(TempPurchLine."Job Line Type".AsInteger() - 1));
                    JobPlanLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");
                    if JobPlanLine.FindFirst() then begin
                        // Count how many 'Schedule' and 'Contract' are there in JobPlanLine.
                        if JobPlanLine."Line Type" = JobPlanLine."Line Type"::Budget then
                            JobSchedule := JobSchedule + 1
                        else
                            if JobPlanLine."Line Type" = JobPlanLine."Line Type"::Billable then
                                JobContract := JobContract + 1;
                        // Compare the TempPurchLine values with JobPlanLine.
                        CompareLines(TempPurchHeader, TempPurchLine, JobPlanLine);
                    end
                    else
                        Error(Text007);
                end;

                // Find the corresponding Job Planning Lines if Job Line Type is 'Both Schedule and Contract'.
                if TempPurchLine."Job Line Type" = TempPurchLine."Job Line Type"::"Both Budget and Billable" then begin
                    // Add one count each for Schedule and Contract.
                    PurchSchedule := PurchSchedule + 1;
                    PurchContract := PurchContract + 1;

                    JobPlanLine.SetRange("Schedule Line", true);
                    JobPlanLine.SetCurrentKey("Job No.", "Job Task No.", "Schedule Line", "Planning Date");
                    if JobPlanLine.FindFirst() then begin
                        // It must be a Line Type of 'Schedule', so add one count.
                        JobSchedule := JobSchedule + 1;
                        CompareLines(TempPurchHeader, TempPurchLine, JobPlanLine)
                    end
                    else
                        Error(Text008);

                    // Find the particular Line type of 'Contract' in Job Planning Line.
                    JobPlanLine.SetRange("Contract Line", true);
                    JobPlanLine.SetRange("Schedule Line", false);
                    JobPlanLine.SetCurrentKey("Job No.", "Job Task No.", "Contract Line", "Planning Date");
                    if JobPlanLine.FindFirst() then begin
                        // It must be a Line Type of 'Contract', so add one count.
                        JobContract := JobContract + 1;
                        CompareLines(TempPurchHeader, TempPurchLine, JobPlanLine)
                    end
                    else
                        Error(Text009);
                end;

            until TempPurchLine.Next() = 0;

        // Check if the number of 'Schedule','Contract' Line Type in PurchLine is matching the Job Planning Lines.
        // For e.g. now we have 3 Lines of type 'Schedule', 'Contract', 'Both Schedule and Contract'.
        // It should generate 2 lines of type 'Schedule' and 2 lines of type 'Contract' in JobPlanLine.
        if PurchSchedule <> JobSchedule then
            Error(Text010);
        if PurchContract <> JobContract then
            Error(Text011);
    end;

    local procedure VerifyJobLedgerWithPurchOrder(var TempPurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        // Verify Job Ledger Entry values with Purchase Order Values before posting.

        if TempPurchLine.FindFirst() then
            repeat
                Clear(JobLedgerEntry);
                JobLedgerEntry.SetRange("Job No.", TempPurchLine."Job No.");
                JobLedgerEntry.SetRange("Job Task No.", TempPurchLine."Job Task No.");
                JobLedgerEntry.SetRange("No.", TempPurchLine."No.");
                JobLedgerEntry.SetRange("Line Type", TempPurchLine."Job Line Type");
                JobLedgerEntry.SetRange(Quantity, TempPurchLine."Qty. to Receive");
                if JobLedgerEntry.FindFirst() then
                    CompareEntries(TempPurchHeader, TempPurchLine, JobLedgerEntry)
                else
                    Error(Text012);

            until TempPurchLine.Next() = 0;
    end;

    local procedure CopyHeaderLines(PurchOrderNo: Code[20]; var TempPurchHeader: Record "Purchase Header" temporary; var TempPurchLine: Record "Purchase Line" temporary)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // Copies the Purchase Header and Purchase Line to the Temp Tables.
        PurchHeader.Get(PurchHeader."Document Type"::Order, PurchOrderNo);
        TempPurchHeader := PurchHeader;
        TempPurchHeader.Insert();

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", PurchOrderNo);

        if PurchLine.FindSet() then
            repeat
                TempPurchLine := PurchLine;
                TempPurchLine.Insert();
            until PurchLine.Next() = 0;
    end;

    local procedure CompareLines(TempPurchHeader: Record "Purchase Header" temporary; TempPurchLine: Record "Purchase Line" temporary; JobPlanLine: Record "Job Planning Line")
    begin
        // Compares the entries of Purchase Line with Job Planning Line.

        if TempPurchHeader."Posting Date" <> JobPlanLine."Planning Date" then
            Error(Text013);

        if TempPurchLine."Job No." <> JobPlanLine."Job No." then
            Error(Text014);

        if TempPurchLine."Job Task No." <> JobPlanLine."Job Task No." then
            Error(Text015);

        if TempPurchLine."Qty. to Receive" <> JobPlanLine.Quantity then
            Error(Text015);

        if TempPurchLine."Qty. to Invoice" <> JobPlanLine.Quantity then
            Error(Text016);

        if TempPurchLine."Unit Cost" <> JobPlanLine."Unit Cost" then
            Error(Text017);

        if TempPurchLine."Job Line Discount Amount" <> JobPlanLine."Line Discount Amount" then
            Error(Text018);

        if JobPlanLine."Total Cost" <> (JobPlanLine.Quantity * JobPlanLine."Unit Cost") then
            Error(Text019);

        if JobPlanLine."Line Amount" <>
           ((JobPlanLine.Quantity * JobPlanLine."Unit Price") - JobPlanLine."Line Discount Amount")
        then
            Error(Text020);
    end;

    local procedure CompareEntries(TempPurchHeader: Record "Purchase Header" temporary; TempPurchLine: Record "Purchase Line" temporary; JobLedgerEntry: Record "Job Ledger Entry")
    begin
        // Compares the entries of Purchase Line with Job Ledger Entry.

        if TempPurchHeader."Posting Date" <> JobLedgerEntry."Posting Date" then
            Error(Text021);

        if TempPurchLine."Job No." <> JobLedgerEntry."Job No." then
            Error(Text022);

        if TempPurchLine."Job Task No." <> JobLedgerEntry."Job Task No." then
            Error(Text023);

        if TempPurchLine."Qty. to Receive" <> JobLedgerEntry.Quantity then
            Error(Text024);

        if TempPurchLine."Qty. to Invoice" <> JobLedgerEntry.Quantity then
            Error(Text025);

        if TempPurchLine."Unit Cost" <> JobLedgerEntry."Unit Cost" then
            Error(Text026);

        if TempPurchLine."Job Line Discount Amount" <> JobLedgerEntry."Line Discount Amount" then
            Error(Text027);

        if JobLedgerEntry."Total Cost" <> (JobLedgerEntry.Quantity * JobLedgerEntry."Unit Cost") then
            Error(Text028);

        if JobLedgerEntry."Line Amount" <>
           ((JobLedgerEntry.Quantity * JobLedgerEntry."Unit Price") - JobLedgerEntry."Line Discount Amount")
        then
            Error(Text029);
    end;

    local procedure VerifyJobPlanForNoLines(var TempPurchLine: Record "Purchase Line" temporary)
    var
        JobPlanLine: Record "Job Planning Line";
    begin
        // Verify if there are no lines created in Job Planning Line if the PO is posted with 'Receive' option.
        if TempPurchLine.FindFirst() then
            repeat
                JobPlanLine.SetRange("Job No.", TempPurchLine."Job No.");
                JobPlanLine.SetRange("Job Task No.", TempPurchLine."Job Task No.");
                JobPlanLine.SetCurrentKey("Job No.", "Job Task No.", "Line No.");
                if JobPlanLine.FindFirst() then
                    Error(Text030);
            until TempPurchLine.Next() = 0;
    end;
}
