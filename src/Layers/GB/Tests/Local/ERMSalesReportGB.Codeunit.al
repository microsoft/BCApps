codeunit 144039 "ERM Sales Report GB"
{
    // 
    // Test - Various Customer Sales Reports.
    // 
    //  1.  Verify that Customer Statement Report can be printed if it has overdue entries
    // 
    // TFS_TS_ID = 355859
    // Covers Test cases:
    // -----------------------------------------------------------------------------------
    // Test Function Name                                                         TFS ID
    // -----------------------------------------------------------------------------------
    // CustomerStatementReportWithOverdueEntries                                  355859

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
#if not CLEAN27        
        LibraryUtility: Codeunit "Library - Utility";
#endif        

    [Test]
    [HandlerFunctions('StatementRequestPagePreviewHandler')]
    [Scope('OnPrem')]
    procedure CustomerStatementReportWithOverdueEntries()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Statement: Report Statement;
        FileMgt: Codeunit "File Management";
        DateChoice: Option "Due Date","Posting Date";
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        // Verify that Customer Statement Report can be printed if it has overdue entries

        // Setup
        Initialize();
        CustomerNo := CreateCustomer();
        CreateAndPostSalesDocumentWithDueDate(
          SalesLine, CustomerNo, SalesLine."Document Type"::Order, '', true, CalcDate('<+1M>', WorkDate()));

        FileName := LibraryReportDataset.GetFileName();
        LibraryVariableStorage.Enqueue(FileName); // for Statement handler

        // Exercise
        Clear(Statement);

        Customer.SetRange("No.", CustomerNo);
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
          true, false, true, false, false, false, '<' + Format(LibraryRandom.RandInt(5)) + 'M>',
          DateChoice::"Due Date", true, WorkDate(), CalcDate('<+3M>', WorkDate()));
        Commit();
        Statement.Run();

        // Verify
        FileMgt.ServerFileExists(FileName);
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('OrderConfirmationGBRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderConfirmationGBExternalDocumentNoIsPrinted()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Order] [Confirmation]
        // [SCENARIO 225794] "External Document No." is shown with its caption when report "Order Confirmation GB" is printed for Sales Order
        Initialize();

        // [GIVEN] Sales Order with "External Document No." = "XXX"
        MockSalesOrderWithExternalDocumentNo(SalesHeader);

        // [WHEN] Export report "Order Confirmation GB" to XML file
        RunOrderConfirmationGBReport(SalesHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Value "External Document No." is displayed under Tag <ReferenceText> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('ReferenceText', SalesHeader.FieldCaption("External Document No."));

        // [THEN] Value "XXX" is displayed under Tag <YourRef_SalesHeader> in export XML file
        LibraryReportDataset.AssertElementTagWithValueExists('YourRef_SalesHeader', SalesHeader."External Document No.");
    end;
#endif    

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportDataset);

        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateFAPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

#if not CLEAN27
    local procedure RunOrderConfirmationGBReport(SalesHeaderNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        Commit();
        SalesHeader.SetRange("No.", SalesHeaderNo);
        REPORT.Run(REPORT::"Order Confirmation GB", true, false, SalesHeader);
    end;
#endif    

    local procedure CreateCustomer(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        // Create Customer with Application Method Apply to Oldest and attach Payment Terms to it.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndPostSalesDocumentWithDueDate(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; Invoice: Boolean; DueDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, DocumentType, CustomerNo, CurrencyCode);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Due Date", DueDate);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Take Random Values for Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatementRequestPagePreviewHandler(var StatementRequestPage: TestRequestPage Statement)
    var
        FileNameVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(FileNameVar);
        StatementRequestPage.SaveAsPdf(FileNameVar);
    end;

#if not CLEAN27
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OrderConfirmationGBRequestPageHandler(var OrderConfirmationGB: TestRequestPage "Order Confirmation GB")
    begin
        OrderConfirmationGB.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure MockSalesOrderWithExternalDocumentNo(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesHeader.Insert();
    end;
#endif    
}

