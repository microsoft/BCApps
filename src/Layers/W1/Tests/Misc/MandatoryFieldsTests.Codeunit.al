codeunit 134590 "Mandatory Fields Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Show Mandatory] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        UnexpectedShowMandatoryValueTxt: Label 'Unexpected value of ShowMandatory property.';
        LibraryInventory: Codeunit "Library - Inventory";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Mandatory Fields Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Mandatory Fields Tests");

        LibraryTemplates.EnableTemplatesFeature();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Mandatory Fields Tests");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnItem()
    var
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [Item]
        Initialize();
        DeleteAllTemplates();

        ItemCard.OpenNew();
        Assert.IsTrue(ItemCard.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(ItemCard."Base Unit of Measure".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(ItemCard."Gen. Prod. Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(ItemCard."VAT Prod. Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(ItemCard."Inventory Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnCustomer()
    var
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer]
        Initialize();
        DeleteAllTemplates();

        CustomerCard.OpenNew();
        Assert.IsTrue(CustomerCard.Name.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CustomerCard."Gen. Bus. Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(CustomerCard."VAT Bus. Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CustomerCard."Customer Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CustomerCard."Payment Terms Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(CustomerCard."Tax Area Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnVendor()
    var
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor]
        Initialize();
        DeleteAllTemplates();

        VendorCard.OpenNew();
        Assert.IsTrue(VendorCard.Name.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(VendorCard."Gen. Bus. Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(VendorCard."VAT Bus. Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(VendorCard."Vendor Posting Group".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(VendorCard."Tax Area Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocuments()
    var
        Customer: Record Customer;
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        // [FEATURE] [Sales]
        Initialize();
        LibraryApplicationArea.DisableApplicationAreaSetup();

        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibrarySales.DisableWarningOnCloseUnreleasedDoc();
        LibrarySales.CreateCustomer(Customer);
        VerifyMandatoryFieldsOnSalesInvoice(Customer);
        VerifyMandatoryFieldsOnSalesOrder(Customer);
        VerifyMandatoryFieldsOnSalesReturnOrder(Customer);
        VerifyMandatoryFieldsOnSalesQuote(Customer);
        VerifyMandatoryFieldsOnSalesCreditMemo(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnPurchaseDocuments()
    var
        Vendor: Record Vendor;
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        // [FEATURE] [Purchase]
        LibraryApplicationArea.DisableApplicationAreaSetup();

        Initialize();
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc();
        LibraryPurchase.DisableWarningOnCloseUnreleasedDoc();
        LibraryPurchase.CreateVendor(Vendor);
        VerifyMandatoryFieldsOnPurchaseInvoice(Vendor);
        VerifyMandatoryFieldsOnPurchaseOrder(Vendor);
        VerifyMandatoryFieldsOnPurchaseCreditMemo(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnReminder()
    var
        Customer: Record Customer;
        ReminderLine: Record "Reminder Line";
        ReminderTerms: Record "Reminder Terms";
        Reminder: TestPage Reminder;
    begin
        // [FEATURE] [Sales] [Reminder]
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Reminder.OpenNew();
        Assert.IsTrue(Reminder."Customer No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(Reminder."Reminder Terms Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Reminder."Customer No.".SetValue(Customer."No.");
        ReminderTerms.FindFirst();
        Reminder."Reminder Terms Code".SetValue(ReminderTerms.Code);
        Reminder.ReminderLines.New();
        Assert.IsTrue(Reminder.ReminderLines.Type.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(Reminder.ReminderLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(Reminder.ReminderLines."Document Type".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(Reminder.ReminderLines."Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Reminder.ReminderLines.Type.SetValue(ReminderLine.Type::"Customer Ledger Entry");
        Assert.IsFalse(Reminder.ReminderLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(Reminder.ReminderLines."Document Type".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(Reminder.ReminderLines."Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Reminder.ReminderLines.Type.SetValue(ReminderLine.Type::"G/L Account");
        Assert.IsTrue(Reminder.ReminderLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(Reminder.ReminderLines."Document Type".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(Reminder.ReminderLines."Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Reminder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnFinanceChargeMemo()
    var
        Customer: Record Customer;
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        // [FEATURE] [Sales] [Finance Charge Memo]
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        FinanceChargeMemo.OpenNew();
        Assert.IsTrue(FinanceChargeMemo."Customer No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(FinanceChargeMemo."Fin. Charge Terms Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        FinanceChargeMemo."Customer No.".SetValue(Customer."No.");
        FinanceChargeTerms.FindFirst();
        FinanceChargeMemo."Fin. Charge Terms Code".SetValue(FinanceChargeTerms.Code);
        FinanceChargeMemo.FinChrgMemoLines.New();
        Assert.IsTrue(FinanceChargeMemo.FinChrgMemoLines.Type.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(FinanceChargeMemo.FinChrgMemoLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(FinanceChargeMemo.FinChrgMemoLines."Document Type".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(FinanceChargeMemo.FinChrgMemoLines."Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        FinanceChargeMemo.FinChrgMemoLines.Type.SetValue(FinanceChargeMemoLine.Type::"Customer Ledger Entry");
        Assert.IsFalse(FinanceChargeMemo.FinChrgMemoLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(FinanceChargeMemo.FinChrgMemoLines."Document Type".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(FinanceChargeMemo.FinChrgMemoLines."Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        FinanceChargeMemo.FinChrgMemoLines.Type.SetValue(FinanceChargeMemoLine.Type::"G/L Account");
        Assert.IsTrue(FinanceChargeMemo.FinChrgMemoLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(FinanceChargeMemo.FinChrgMemoLines."Document Type".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(FinanceChargeMemo.FinChrgMemoLines."Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        FinanceChargeMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnCompanyInformation()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [Company Information]
        Initialize();
        CompanyInformation.OpenEdit();
        Assert.IsTrue(CompanyInformation.Name.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation.Address.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation."Post Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation.City.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation."Country/Region Code".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation."Bank Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation."Bank Branch No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation."Bank Account No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(CompanyInformation.IBAN.ShowMandatory(), UnexpectedShowMandatoryValueTxt);

        // if you set Bank Branch No. and Bank Account No., IBAN is no longer mandatory
        CompanyInformation."Bank Branch No.".SetValue('0123');
        CompanyInformation."Bank Account No.".SetValue('3176000000');
        Assert.IsFalse(CompanyInformation.IBAN.ShowMandatory(), UnexpectedShowMandatoryValueTxt);

        // if you set IBAN, Bank Branch No. and Bank Account No. are no longer mandatory
        CompanyInformation."Bank Branch No.".SetValue('');
        CompanyInformation."Bank Account No.".SetValue('');
        CompanyInformation.IBAN.SetValue('DK44 0123 3176 0000 00');
        Assert.IsFalse(CompanyInformation."Bank Branch No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(CompanyInformation."Bank Account No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        CompanyInformation.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesInvoice(Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SetExternalDocNoMandatory(true);
        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesInvoice."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");
        SalesInvoice.SalesLines.New();
        Assert.AreEqual(false, SalesInvoice.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(SalesInvoice.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesInvoice.SalesLines.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(SalesInvoice.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesInvoice.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Customer."Tax Area Code" <> '', SalesInvoice.SalesLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesInvoice.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesInvoice.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        Assert.IsFalse(SalesInvoice.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesInvoice.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetExternalDocNoMandatory(false);
        SalesInvoice.OpenNew();
        Assert.IsFalse(SalesInvoice."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesInvoice.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesOrder(Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SetExternalDocNoMandatory(true);
        SalesOrder.OpenNew();
        Assert.IsTrue(SalesOrder."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesOrder."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesOrder."Sell-to Customer Name".SetValue(Customer."No.");
        SalesOrder.SalesLines.New();
        Assert.IsFalse(SalesOrder.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(SalesOrder.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesOrder.SalesLines.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(SalesOrder.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesOrder.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Customer."Tax Area Code" <> '', SalesOrder.SalesLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        SalesOrder.SalesLines.FilteredTypeField.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesOrder.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesOrder.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        Assert.IsFalse(SalesOrder.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesOrder.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetExternalDocNoMandatory(false);
        SalesOrder.OpenNew();
        Assert.IsFalse(SalesOrder."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesOrder.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesReturnOrder(Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenNew();
        Assert.IsTrue(SalesReturnOrder."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer."No.");
        SalesReturnOrder.SalesLines.New();
        Assert.IsFalse(SalesReturnOrder.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(SalesReturnOrder.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesReturnOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesReturnOrder.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesReturnOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(SalesReturnOrder.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesReturnOrder.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Customer."Tax Area Code" <> '', SalesReturnOrder.SalesLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        SalesReturnOrder.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesQuote(Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenNew();
        Assert.IsTrue(SalesQuote."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        SalesQuote.SalesLines.New();
        Assert.IsFalse(SalesQuote.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(SalesQuote.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesQuote.SalesLines.Type.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesQuote.SalesLines.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesQuote.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(SalesQuote.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesQuote.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Customer."Tax Area Code" <> '', SalesQuote.SalesLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        SalesQuote.SalesLines.FilteredTypeField.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesQuote.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesQuote.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        Assert.IsFalse(SalesQuote.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesQuote.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesCreditMemo(Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SetExternalDocNoMandatory(true);
        SalesCreditMemo.OpenNew();
        Assert.AreEqual(true, SalesCreditMemo."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer."No.");
        SalesCreditMemo.SalesLines.New();
        Assert.IsFalse(SalesCreditMemo.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(SalesCreditMemo.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo.SalesLines.Type.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesCreditMemo.SalesLines.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(SalesCreditMemo.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(SalesCreditMemo.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Customer."Tax Area Code" <> '', SalesCreditMemo.SalesLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(SalesLine.Type::Item);
        Assert.IsTrue(SalesCreditMemo.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo.SalesLines.FilteredTypeField.SetValue(SalesLine.FormatType());
        Assert.IsFalse(SalesCreditMemo.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetExternalDocNoMandatory(false);
        SalesCreditMemo.OpenNew();
        Assert.IsFalse(SalesCreditMemo."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        SalesCreditMemo.Close();
    end;

    local procedure VerifyMandatoryFieldsOnPurchaseInvoice(Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        SetVendorInvoiceNoMandatory(true);
        PurchaseInvoice.OpenNew();
        Assert.IsTrue(PurchaseInvoice."Buy-from Vendor Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseInvoice."Vendor Invoice No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice.PurchLines.New();
        Assert.IsFalse(PurchaseInvoice.PurchLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(PurchaseInvoice.PurchLines."Direct Unit Cost".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        Assert.IsTrue(PurchaseInvoice.PurchLines.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(PurchaseInvoice.PurchLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseInvoice.PurchLines."Direct Unit Cost".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Vendor."Tax Area Code" <> '', PurchaseInvoice.PurchLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(PurchaseLine.Type::Item);
        Assert.IsTrue(PurchaseInvoice.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType());
        Assert.IsFalse(PurchaseInvoice.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetVendorInvoiceNoMandatory(false);
        PurchaseInvoice.OpenNew();
        Assert.IsFalse(PurchaseInvoice."Vendor Invoice No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseInvoice.Close();
    end;

    local procedure VerifyMandatoryFieldsOnPurchaseOrder(Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        SetVendorInvoiceNoMandatory(true);
        PurchaseOrder.OpenNew();
        Assert.IsTrue(PurchaseOrder."Buy-from Vendor Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseOrder."Vendor Invoice No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        PurchaseOrder.PurchLines.New();
        Assert.IsFalse(PurchaseOrder.PurchLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(PurchaseOrder.PurchLines."Direct Unit Cost".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseOrder.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        PurchaseOrder.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(PurchaseOrder.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseOrder.PurchLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseOrder.PurchLines."Direct Unit Cost".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Vendor."Tax Area Code" <> '', PurchaseOrder.PurchLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(PurchaseLine.Type::Item);
        Assert.IsTrue(PurchaseOrder.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseOrder.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType());
        Assert.IsFalse(PurchaseOrder.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseOrder.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetVendorInvoiceNoMandatory(false);
        PurchaseOrder.OpenNew();
        Assert.IsFalse(PurchaseOrder."Vendor Invoice No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseOrder.Close();
    end;

    local procedure VerifyMandatoryFieldsOnPurchaseCreditMemo(Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        SetVendorInvoiceNoMandatory(true);
        PurchaseCreditMemo.OpenNew();
        Assert.IsTrue(PurchaseCreditMemo."Buy-from Vendor Name".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseCreditMemo."Vendor Cr. Memo No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseCreditMemo.PurchLines.New();
        Assert.IsFalse(PurchaseCreditMemo.PurchLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."Direct Unit Cost".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseLine.Type::Item);
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Description.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseCreditMemo.PurchLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.IsTrue(PurchaseCreditMemo.PurchLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."Direct Unit Cost".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.IsTrue(PurchaseCreditMemo."Vendor Cr. Memo No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        Assert.AreEqual(Vendor."Tax Area Code" <> '', PurchaseCreditMemo.PurchLines."Tax Group Code".ShowMandatory(),
            UnexpectedShowMandatoryValueTxt);
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(PurchaseLine.Type::Item);
        Assert.IsTrue(PurchaseCreditMemo.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseCreditMemo.PurchLines.FilteredTypeField.SetValue(PurchaseLine.FormatType());
        Assert.IsFalse(PurchaseCreditMemo.PurchLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueTxt);
        PurchaseCreditMemo.Close();
    end;

    local procedure SetVendorInvoiceNoMandatory(VendorInvoiceNoMandatory: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.FindFirst();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := VendorInvoiceNoMandatory;
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetExternalDocNoMandatory(ExternalDocNoMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.FindFirst();
        SalesReceivablesSetup."Ext. Doc. No. Mandatory" := ExternalDocNoMandatory;
        SalesReceivablesSetup.Modify();
    end;

    local procedure DeleteAllTemplates()
    var
        CustomerTempl: Record "Customer Templ.";
        VendorTempl: Record "Vendor Templ.";
        ItemTempl: Record "Item Templ.";
    begin
        CustomerTempl.DeleteAll(true);
        VendorTempl.DeleteAll(true);
        ItemTempl.DeleteAll(true);
    end;
}

