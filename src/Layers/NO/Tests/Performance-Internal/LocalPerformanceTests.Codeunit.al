codeunit 139094 "Local Performance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Performance Profiler]
        TestsBuffer := 10;
        TestsBufferPercentage := 5;
        LibraryPerformanceProfiler.SetProfilerIdentification('139094 - Local Performance Tests')
    end;

    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPerformanceProfiler: Codeunit "Library - Performance Profiler";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        TestsBuffer: Integer;
        TestsBufferPercentage: Integer;
        TraceDumpFilePath: Text;

    [Test]
    [Scope('OnPrem')]
    procedure TestExportingPaymentsToBankFile()
    var
        BankAccount: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryApplicationArea.EnablePremiumSetup();

        CreateBankAccount(BankAccount);
        CreateVendorWithBankAccount(Vendor);
        CreateGenJournalBatch(GenJnlBatch, BankAccount."No.");
        CreateGeneralJnlLine(GenJnlBatch, GenJnlLine, Vendor);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Exported to Payment File", false);

        LibraryPerformanceProfiler.StartProfiler(true);
        GenJnlLine.ExportPaymentFile();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestExportingPaymentsToBankFile',
            PerfProfilerEventsTest."Object Type"::Table, DATABASE::"Gen. Journal Line", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestCreatePrepaymentInvoices()
    var
        LineGLAccount: Record "G/L Account";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
        SalesPostYNPrepmt: Codeunit "Sales-Post Prepayment (Yes/No)";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryApplicationArea.EnablePremiumSetup();

        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        CustomerNo := CreateCustomerWithPostingSetup(LineGLAccount);
        ItemNo := CreateItemWithPostingSetup(LineGLAccount);
        CreatePrepayment(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, CustomerNo, ItemNo, LibraryRandom.RandDec(99, 5));
        CreateSalesDocumentPrepayment(SalesHeader, SalesLine, CustomerNo, SalesPrepaymentPct."Item No.");

        LibraryPerformanceProfiler.StartProfiler(true);
        SalesPostYNPrepmt.PostPrepmtInvoiceYN(SalesHeader, false);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestCreatePrepaymentInvoices',
            PerfProfilerEventsTest."Object Type"::Codeunit, CODEUNIT::"Sales-Post Prepayment (Yes/No)", true);
    end;

    [Test]
    [HandlerFunctions('InvokeMakeOrder,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestMakeOrderFromServiceQuotes()
    var
        ServiceHeader: Record "Service Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryApplicationArea.EnablePremiumSetup();

        CreateService(ServiceHeader, ServiceHeader."Document Type"::Quote);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryPerformanceProfiler.StartProfiler(true);
        Page.RunModal(Page::"Service Quote", ServiceHeader);
        LibraryVariableStorage.Clear();
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestMakeOrderFromServiceQuotes',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Service Quote", true);
    end;

    [Test]
    [HandlerFunctions('InvokePostOrder,StrMenuHandlerShipAndInvoice')]
    [Scope('OnPrem')]
    procedure TestPostServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryApplicationArea.EnablePremiumSetup();

        CreateService(ServiceHeader, ServiceHeader."Document Type"::Order);

        LibraryPerformanceProfiler.StartProfiler(true);
        Page.RunModal(Page::"Service Order", ServiceHeader);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostServiceOrder',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Service Order", true);
    end;

    [Test]
    [HandlerFunctions('InvokePostInvoice,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPostServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        PerfProfilerEventsTest: Record "Perf Profiler Events Test";
    begin
        LibraryApplicationArea.EnablePremiumSetup();

        CreateService(ServiceHeader, ServiceHeader."Document Type"::Invoice);

        LibraryPerformanceProfiler.StartProfiler(true);
        Page.RunModal(Page::"Service Invoice", ServiceHeader);
        TraceDumpFilePath := LibraryPerformanceProfiler.StopProfiler(
            PerfProfilerEventsTest, 'TestPostServiceInvoice',
            PerfProfilerEventsTest."Object Type"::Page, PAGE::"Service Invoice", true);
    end;

    local procedure CreateGeneralJnlLine(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlLine: Record "Gen. Journal Line"; var Vendor: Record Vendor)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        GLSetup.Get();
        GenJnlLine."Currency Code" := GLSetup.GetCurrencyCode('EUR');
        GenJnlLine."Exported to Payment File" := false;
        GenJnlLine.Modify();
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");
        VendorBankAccount.IBAN := 'NL55RABO5301200022';
        VendorBankAccount.Modify();
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.FindFirst();

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Branch No." := Format(LibraryRandom.RandIntInRange(1111, 9999));
        BankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(111111111, 999999999)) + '9';
        BankAccount."Payment Export Format" := 'SEPACT';
        BankAccount."Credit Transfer Msg. Nos." := NoSeries.Code;
        BankAccount.IBAN := 'NL46RABO5301200062';
        BankAccount.Modify();

    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPaymentExport.SelectPaymentJournalTemplate());
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BalAccountNo;
        GenJournalBatch."Allow Payment Export" := true;
        GenJournalBatch.Modify();
    end;

    local procedure CreateSalesDocumentPrepayment(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        Quantity: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        Quantity := 10;
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; LineNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, LineNo, Quantity);
        SalesLine."Unit Price" := UnitPrice;
        SalesLine.Modify(true);
    end;

    local procedure CreatePrepayment(var SalesPrepaymentPct: Record "Sales Prepayment %"; SaleType: Option; SalesCode: Code[20]; ItemNo: Code[20]; PrepaymentPercent: Decimal)
    begin
        LibrarySales.CreateSalesPrepaymentPct(SalesPrepaymentPct, SaleType, SalesCode, ItemNo, WorkDate());
        SalesPrepaymentPct."Prepayment %" := PrepaymentPercent;
        SalesPrepaymentPct.Modify(true);
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        AssignPostingGroupsToItem(Item, LineGLAccount);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure AssignPostingGroupsToItem(var Item: Record Item; LineGLAccount: Record "G/L Account")
    begin
        Item."Gen. Prod. Posting Group" := LineGLAccount."Gen. Prod. Posting Group";
        Item."VAT Prod. Posting Group" := LineGLAccount."VAT Prod. Posting Group";
        Item.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := 10 * LibraryRandom.RandDec(99, 5); // Using RANDOM value for Unit Price.
        Item.Modify(true);
    end;

    local procedure CreateCustomerWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomerNotPrepayment(Customer, LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer."Prepayment %" := LibraryRandom.RandDec(99, 5);  // Random Number Generator for Prepayment Percent.
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerNotPrepayment(var Customer: Record Customer; GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Gen. Bus. Posting Group" := GenBusPostingGroup;
        Customer."VAT Bus. Posting Group" := VATBusPostingGroup;
        Customer.Modify(true);
    end;

    local procedure CreateService(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        if DocumentType <> ServiceHeader."Document Type"::Quote then
            CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
    begin
        CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, 10);  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean()
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokeMakeOrder(var ServiceQuote: TestPage "Service Quote")
    begin
        ServiceQuote."Make &Order".Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // This is a dummy Handler
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokePostOrder(var ServiceOrder: TestPage "Service Order")
    begin
        ServiceOrder.Post.Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerShipAndInvoice(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokePostInvoice(var ServiceInvoice: TestPage "Service Invoice")
    begin
        ServiceInvoice.Post.Invoke();
    end;
}