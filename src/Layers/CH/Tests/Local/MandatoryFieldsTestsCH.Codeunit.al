codeunit 144082 "Mandatory Fields Tests CH"
{
    // // [FEATURE] [UI] [Mandatory Fields] [Sales]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        SalesLine: Record "Sales Line";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        UnexpectedShowMandatoryValueErr: Label 'Unexpected value of ShowMandatory property.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocumentsLineTypeEmpty()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Certain fields are not mandatory when Type of "Sales Line" is not specified
        VerifyMandatoryFieldsOnSalesDocuments(SalesLine.Type::" ", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocumentsLineTypeItem()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Certain fields are mandatory when Item specified as Type of "Sales Line"
        VerifyMandatoryFieldsOnSalesDocuments(SalesLine.Type::Item, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocumentsLineTypeTitle()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Certain fields are not mandatory when Title specified as Type of "Sales Line"
        VerifyMandatoryFieldsOnSalesDocuments(SalesLine.Type::Title, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocumentsLineTypeBeginTotal()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Certain fields are not mandatory when "Begin-Total" specified as Type of "Sales Line"
        VerifyMandatoryFieldsOnSalesDocuments(SalesLine.Type::"Begin-Total", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocumentsLineTypeEndTotal()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Certain fields are not mandatory when "End-Total" specified as Type of "Sales Line"
        VerifyMandatoryFieldsOnSalesDocuments(SalesLine.Type::"End-Total", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryFieldsOnSalesDocumentsLineTypeNewPage()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Certain fields are not mandatory when "New Page" specified as Type of "Sales Line"
        VerifyMandatoryFieldsOnSalesDocuments(SalesLine.Type::"New Page", false);
    end;

    [Test]
    procedure NoErrorDescriptionValidationForSalesLineTitle()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 418419] No error after validation "Sales Line".Description with Type = Title
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Title, '', 0);

        SalesLine.Validate(Description, LibraryUtility.GenerateGUID());
    end;

    local procedure VerifyMandatoryFieldsOnSalesDocuments(LineType: Enum "Sales Line Type"; ExpectedMandatory: Boolean)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibrarySales.DisableWarningOnCloseUnreleasedDoc();
        VerifyMandatoryFieldsOnSalesInvoice(Customer."No.", LineType, ExpectedMandatory);
        // VerifyMandatoryFieldsOnSalesOrder(Customer."No.", LineType, ExpectedMandatory);
        VerifyMandatoryFieldsOnSalesReturnOrder(Customer."No.", LineType, ExpectedMandatory);
        VerifyMandatoryFieldsOnSalesQuote(Customer."No.", LineType, ExpectedMandatory);
        VerifyMandatoryFieldsOnSalesCreditMemo(Customer."No.", LineType, ExpectedMandatory);
    end;

    local procedure VerifyMandatoryFieldsOnSalesInvoice(CustomerNo: Code[20]; LineType: Enum "Sales Line Type"; ExpectedMandatory: Boolean)
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SetExternalDocNoMandatory(true);
        SalesInvoice.OpenNew();
        Assert.IsTrue(SalesInvoice."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsTrue(SalesInvoice."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerNo);
        SalesInvoice.SalesLines.New();
        Assert.IsFalse(SalesInvoice.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsFalse(SalesInvoice.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesInvoice.SalesLines.Type.SetValue(LineType);
        Assert.AreEqual(ExpectedMandatory, SalesInvoice.SalesLines.Description.ShowMandatory(),
          UnexpectedShowMandatoryValueErr);
        if LineType = SalesLine.Type::Item then
            SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.AreEqual(ExpectedMandatory, SalesInvoice.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.AreEqual(ExpectedMandatory, SalesInvoice.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesInvoice.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetExternalDocNoMandatory(false);
        SalesInvoice.OpenNew();
        Assert.IsFalse(SalesInvoice."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesInvoice.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesReturnOrder(CustomerNo: Code[20]; LineType: Enum "Sales Line Type"; ExpectedMandatory: Boolean)
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenNew();
        Assert.IsTrue(SalesReturnOrder."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesReturnOrder."Sell-to Customer Name".SetValue(CustomerNo);
        SalesReturnOrder.SalesLines.New();
        SalesReturnOrder.SalesLines.Type.SetValue("Sales Line Type"::" ");
        Assert.IsFalse(SalesReturnOrder.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsFalse(SalesReturnOrder.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsFalse(SalesReturnOrder.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesReturnOrder.SalesLines.Type.SetValue(LineType);
        Assert.AreEqual(ExpectedMandatory, SalesReturnOrder.SalesLines."No.".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        if LineType = SalesLine.Type::Item then
            SalesReturnOrder.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.AreEqual(ExpectedMandatory, SalesReturnOrder.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.AreEqual(ExpectedMandatory, SalesReturnOrder.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesReturnOrder.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesQuote(CustomerNo: Code[20]; LineType: Enum "Sales Line Type"; ExpectedMandatory: Boolean)
    var
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenNew();
        Assert.IsTrue(SalesQuote."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Customer.Get(CustomerNo);
        SalesQuote."Sell-to Customer Name".SetValue(Customer.Name);
        SalesQuote.SalesLines.New();
        Assert.IsFalse(SalesQuote.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsFalse(SalesQuote.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesQuote.SalesLines.Type.SetValue(LineType);
        if LineType = SalesLine.Type::Item then
            SalesQuote.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.AreEqual(ExpectedMandatory, SalesQuote.SalesLines.Description.ShowMandatory(),
          UnexpectedShowMandatoryValueErr);
        Assert.AreEqual(ExpectedMandatory, SalesQuote.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.AreEqual(ExpectedMandatory, SalesQuote.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesQuote.Close();
    end;

    local procedure VerifyMandatoryFieldsOnSalesCreditMemo(CustomerNo: Code[20]; LineType: Enum "Sales Line Type"; ExpectedMandatory: Boolean)
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SetExternalDocNoMandatory(true);
        SalesCreditMemo.OpenNew();
        Assert.IsTrue(SalesCreditMemo."Sell-to Customer Name".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsTrue(SalesCreditMemo."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesCreditMemo."Sell-to Customer Name".SetValue(CustomerNo);
        SalesCreditMemo.SalesLines.New();
        Assert.IsFalse(SalesCreditMemo.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.IsFalse(SalesCreditMemo.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesCreditMemo.SalesLines.Type.SetValue(LineType);
        if LineType = SalesLine.Type::Item then
            SalesCreditMemo.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        Assert.AreEqual(ExpectedMandatory, SalesCreditMemo.SalesLines.Description.ShowMandatory(),
          UnexpectedShowMandatoryValueErr);
        Assert.AreEqual(ExpectedMandatory, SalesCreditMemo.SalesLines.Quantity.ShowMandatory(), UnexpectedShowMandatoryValueErr);
        Assert.AreEqual(ExpectedMandatory, SalesCreditMemo.SalesLines."Unit Price".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesCreditMemo.Close();

        // verify that external document number is not mandatory if you specify so in the setup
        SetExternalDocNoMandatory(false);
        SalesCreditMemo.OpenNew();
        Assert.IsFalse(SalesCreditMemo."External Document No.".ShowMandatory(), UnexpectedShowMandatoryValueErr);
        SalesCreditMemo.Close();
    end;

    local procedure SetExternalDocNoMandatory(ExternalDocNoMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Ext. Doc. No. Mandatory" := ExternalDocNoMandatory;
        SalesReceivablesSetup.Modify();
    end;
}
