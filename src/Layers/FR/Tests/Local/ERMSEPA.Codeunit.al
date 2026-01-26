codeunit 144059 "ERM SEPA"
{
    // 1. Test to Verify XML Data after print Payment Slip using report Remittance.
    // 2. Test to Verify XML Data after print Payment Slip using report Withdraw recapitulation.
    // 3. Test to Verify XML Data after print Payment Slip using report Draft recapitulation.
    // 
    // Covers Test Cases for WI - 344201
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // PaymentSlipUsingReportRemittance                                              217031
    // PaymentSlipUsingReportWithdrawRecapitulation                                  217030
    // PaymentSlipUsingReportDraftRecapitulation                                     217028

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IBANCap: Label 'Payment_Lines_IBAN';
        SWIFTCodeCap: Label 'Payment_Lines__SWIFT_Code_';

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyCustomerEntriesPageHandler,RemittanceRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipUsingReportRemittance()
    begin
        // Test to Verify XML Data after print Payment Slip using report Remittance.
        PaymentSlipUsingAccountTypeCustomer(REPORT::Remittance, 'Payment_Line_IBAN', 'Payment_Line__SWIFT_Code_');
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyCustomerEntriesPageHandler,WithdrawRecapitulationRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipUsingReportWithdrawRecapitulation()
    begin
        // Test to Verify XML Data after print Payment Slip using report Withdraw recapitulation.
        PaymentSlipUsingAccountTypeCustomer(REPORT::"Withdraw recapitulation", IBANCap, SWIFTCodeCap);
    end;

    local procedure PaymentSlipUsingAccountTypeCustomer(ReportID: Integer; Caption: Text; Caption2: Text)
    var
        PaymentLine: Record "Payment Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup:  Create Setup for Payment Slip, create and post Sales Order and create Payment Slip.
        Initialize();
        CreateSalesOrder(SalesHeader);
        LibraryVariableStorage.Enqueue(SetupForPaymentSlip(ReportID));  // Enqueue Payment Class Code for PaymentClassListPageHandler.
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Enqueue Sales Invoice Header No for ApplyCustomerEntriesPageHandler.
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.");

        // Exercise: Print Payment Slip.
        PrintPaymentSlip(PaymentLine."No.");

        // Verify: Verify values of Payment_Line_IBAN, Payment_Line__SWIFT_Code_ and PaymtHeader__No__ on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PaymtHeader__No__', PaymentLine."No.");
        LibraryReportDataset.AssertElementWithValueExists(Caption, PaymentLine.IBAN);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, PaymentLine."SWIFT Code");
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler,ApplyVendorEntriesPageHandler,ConfirmHandler,DraftRecapitulationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipUsingReportDraftRecapitulation()
    var
        PaymentLine: Record "Payment Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to Verify XML Data after print Payment Slip using report Draft recapitulation.

        // Setup:  Create Setup for Payment Slip. Create and post Purchase Order and create Payment Slip.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader);
        LibraryVariableStorage.Enqueue(SetupForPaymentSlip(REPORT::"Draft recapitulation"));  // Enqueue Payment Class Code for PaymentClassListPageHandler.
        LibraryVariableStorage.Enqueue(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Enqueue Purchase Invoice Header No for ApplyVendorEntriesPageHandler.
        CreatePaymentSlip(PaymentLine, PaymentLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.");

        // Exercise: Print Payment Slip.
        PrintPaymentSlip(PaymentLine."No.");

        // Verify: Verify values of Payment_Lines_IBAN, Payment_Lines__SWIFT_Code_ and PaymtHeader__No__ on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PaymtHeader__No__', PaymentLine."No.");
        LibraryReportDataset.AssertElementWithValueExists(IBANCap, PaymentLine.IBAN);
        LibraryReportDataset.AssertElementWithValueExists(SWIFTCodeCap, PaymentLine."SWIFT Code");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomerBankAccount(): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
    begin
        CompanyInformation.Get();
        LibrarySales.CreateCustomer(Customer);
        LibraryFRLocalization.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.Validate(IBAN, CompanyInformation.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", LibraryUtility.GenerateGUID());
        CustomerBankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        CustomerBankAccount.Modify(true);
        exit(CustomerBankAccount."Customer No.");
    end;

    local procedure CreatePaymentClass(): Text[30]
    var
        NoSeries: Record "No. Series";
        PaymentClass: Record "Payment Class";
    begin
        NoSeries.FindFirst();
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Validate("Header No. Series", NoSeries.Code);
        PaymentClass.Modify(true);
        exit(PaymentClass.Code);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorBankAccount());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(
            Item), LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Take random Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePaymentSlip(var PaymentLine: Record "Payment Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        PaymentHeader: Record "Payment Header";
    begin
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", AccountType);
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Modify(true);
    end;

    local procedure CreatePaymentStep(PaymentClass: Code[30]; ReportNo: Integer)
    var
        PaymentStep: Record "Payment Step";
    begin
        LibraryFRLocalization.CreatePaymentStep(PaymentStep, PaymentClass);
        PaymentStep.Validate("Action Type", PaymentStep."Action Type"::Report);
        PaymentStep.Validate("Report No.", ReportNo);
        PaymentStep.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerBankAccount());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(
            Item), LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Take random Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorBankAccount(): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CompanyInformation.Get();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate(IBAN, CompanyInformation.IBAN);
        VendorBankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        VendorBankAccount.Validate("SWIFT Code", LibraryUtility.GenerateGUID());
        VendorBankAccount.Modify(true);
        exit(VendorBankAccount."Vendor No.");
    end;

    local procedure PrintPaymentSlip(No: Code[20])
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("No.", No);
        PaymentSlip.Lines.Application.Invoke();
        Commit();
        PaymentSlip.Print.Invoke();
        PaymentSlip.Close();
    end;

    local procedure SetupForPaymentSlip(ReportID: Integer) PaymentClass: Text[30]
    var
        PaymentStatus: Record "Payment Status";
    begin
        PaymentClass := CreatePaymentClass();
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass);
        CreatePaymentStep(PaymentClass, ReportID);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        ApplyCustomerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        ApplyVendorEntries.FILTER.SetFilter("Document No.", DocumentNo);
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassListPageHandler(var PaymentClassList: TestPage "Payment Class List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        PaymentClassList.FILTER.SetFilter(Code, Code);
        PaymentClassList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftRecapitulationRequestPageHandler(var DraftRecapitulation: TestRequestPage "Draft recapitulation")
    begin
        DraftRecapitulation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceRequestPageHandler(var Remittance: TestRequestPage Remittance)
    begin
        Remittance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithdrawRecapitulationRequestPageHandler(var WithdrawRecapitulation: TestRequestPage "Withdraw recapitulation")
    begin
        WithdrawRecapitulation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

