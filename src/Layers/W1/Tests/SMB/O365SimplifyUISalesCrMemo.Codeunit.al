codeunit 138016 "O365 Simplify UI Sales Cr.Memo"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Credit Memo] [SMB] [Sales] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        SelectCustErr: Label 'You must select an existing customer.';
        HelloWordTxt: Label 'Hello World';

    local procedure Initialize()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Simplify UI Sales Cr.Memo");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.DeleteAll(true);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Simplify UI Sales Cr.Memo");

        ClearTable(DATABASE::"Production BOM Line");
        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Simplify UI Sales Cr.Memo");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Production BOM Line":
                ProductionBOMLine.DeleteAll();
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostFromCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        // Setup
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesCrMemoHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        PostedSalesCreditMemo.Trap();

        // Exercise
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();
        SalesCreditMemo.Post.Invoke();

        // Verify
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostFromList()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        // Setup
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreateSalesCrMemoHeader(SalesHeader, Customer);
        LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        PostedSalesCreditMemo.Trap();

        // Exercise
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        SalesCreditMemos.Post.Invoke();

        // Verify
        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('CurrencyHandler')]
    [Scope('OnPrem')]
    procedure Currency()
    var
        Cust: Record Customer;
        Item: Record Item;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        OldValue: Decimal;
    begin
        Initialize();

        CurrExchRate.FindFirst();
        LibrarySmallBusiness.CreateCustomer(Cust);
        Cust.Validate("Currency Code", CurrExchRate."Currency Code");
        Cust.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Cust.Name);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        SalesHeader.FindFirst();
        OldValue := SalesHeader."Currency Factor";

        // Exercise
        SalesCreditMemo."Currency Code".AssistEdit();
        SalesCreditMemo.Close();

        // Verify
        SalesHeader.Find();
        Assert.AreNotEqual(OldValue, SalesHeader."Currency Factor", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenters()
    var
        Cust: Record Customer;
        Item: Record Item;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        LibrarySmallBusiness.CreateItem(Item);
        CreateNewRespCenter(ResponsibilityCenter);

        UserSetup.Init();
        UserSetup."User ID" := UserId;
        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        if not UserSetup.Insert() then
            UserSetup.Modify();

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Cust.Name);

        SalesHeader.SetRange("Sell-to Customer No.", Cust."No.");
        SalesHeader.FindFirst();
        SalesCreditMemo.Close();

        Assert.AreEqual(ResponsibilityCenter.Code, SalesHeader."Responsibility Center", '');

        CreateNewRespCenter(ResponsibilityCenter);

        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify();

        SalesCreditMemo.OpenEdit();
        Assert.IsFalse(SalesCreditMemo.GotoRecord(SalesHeader), '');
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedText()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomer(Cust);
        LibrarySmallBusiness.CreateItem(Item);

        ExtendedTextHeader.Init();
        ExtendedTextHeader.Validate("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.Validate("No.", Item."No.");
        ExtendedTextHeader.Validate("Sales Invoice", true);
        ExtendedTextHeader.Insert(true);

        ExtendedTextLine.Init();
        ExtendedTextLine.Validate("Table Name", ExtendedTextHeader."Table Name");
        ExtendedTextLine.Validate("No.", ExtendedTextHeader."No.");
        ExtendedTextLine.Validate("Language Code", ExtendedTextHeader."Language Code");
        ExtendedTextLine.Validate("Text No.", ExtendedTextHeader."Text No.");
        ExtendedTextLine.Validate("Line No.", 1);
        ExtendedTextLine.Validate(Text, HelloWordTxt);
        ExtendedTextLine.Insert(true);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Cust.Name);

        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.InsertExtTexts.Invoke();
        SalesCreditMemo.SalesLines.New();
        SalesCreditMemo.Close();

        // Verify
        SalesLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        SalesLine.SetRange("Sell-to Customer No.", Cust."No.");
        SalesLine.FindSet();
        Assert.AreEqual(SalesLine."No.", Item."No.", '');

        SalesLine.SetRange("Sell-to Customer No.");
        SalesLine.Next();
        Assert.AreEqual(SalesLine."No.", '', '');
        Assert.AreNotEqual(0, SalesLine."Attached to Line No.", '');
        Assert.AreEqual(SalesLine.Description, Format(HelloWordTxt), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingCustomer()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();
        CreateCustomer(Customer);

        // Exercise: Select existing customer.
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        // Verify.
        VerifySalesCreditMemoAgainstCustomer(SalesCreditMemo, Customer);
        VerifySalesCreditMemoAgainstBillToCustomer(SalesCreditMemo, Customer);
    end;

    [Test]
    [HandlerFunctions('ChangeSellToBillToCustomerConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCustomerNameWithExistingCustomerName()
    var
        Customer1: Record Customer;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();
        CreateCustomer(Customer);
        CreateCustomer(Customer1);

        // Exercise: Select existing customer.
        SalesCreditMemo.OpenNew();
        SalesCreditMemo.SalesLines.First();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);
        // Enqueue for ChangeSellToBillToCustomerConfirmHandler that is called twice
        // for sell-to and bill-to
        AnswerYesToAllConfirmDialogs();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer1.Name);

        // Verify.
        VerifySalesCreditMemoAgainstCustomer(SalesCreditMemo, Customer1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewCustomerExpectError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustomerName: Text[50];
    begin
        Initialize();

        LibrarySmallBusiness.CreateCustomerTemplate(ConfigTemplateHeader);

        // Exercise.
        CustomerName := CopyStr(Format(CreateGuid()), 1, 50);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo.SalesLines.First();

        // Verify
        asserterror SalesCreditMemo."Sell-to Customer Name".SetValue(CustomerName);
    end;

    [Test]
    [HandlerFunctions('CustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure CustomersWithSameName()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        CreateTwoCustomersSameName(Customer);

        // Exercise: Select existing customer - second one in the page handler
        LibraryVariableStorage.Enqueue(Customer.Name); // for the customer list page handler
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(CopyStr(Customer.Name, 2, StrLen(Customer.Name) - 1));

        // Verify.
        VerifySalesCreditMemoAgainstCustomer(SalesCreditMemo, Customer);
    end;

    [Test]
    [HandlerFunctions('CustomerListCancelPageHandler')]
    [Scope('OnPrem')]
    procedure CustomersWithSameNameCancelSelect()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        CreateTwoCustomersSameName(Customer);

        // Exercise: Select existing customer - second one in the page handler
        LibraryVariableStorage.Enqueue(Customer.Name); // for the customer list page handler
        SalesCreditMemo.OpenNew();
        asserterror SalesCreditMemo."Sell-to Customer Name".SetValue(CopyStr(Customer.Name, 2, StrLen(Customer.Name) - 1));
        Assert.ExpectedError(SelectCustErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoLinesControlsItem()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        LibrarySmallBusiness.CreateItem(Item);
        CreateCustomer(Customer);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        // Set item on line - if no errors than is ok
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));
        SalesCreditMemo.SalesLines.New();

        LibraryVariableStorage.Enqueue(true); // for the posting confirm handler
        LibraryVariableStorage.Enqueue(false); // for open posted sales credit memo confirm handler
        SalesCreditMemo.Post.Invoke();

        VerifyUnitCostOnItemCard(Item, false); // ILEs exist and control should be non - editable
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoLinesControlsService()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        LibrarySmallBusiness.CreateItemAsService(Item);
        CreateCustomer(Customer);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        // Set item as service on line - if no errors than is ok
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));
        SalesCreditMemo.SalesLines.New();

        LibraryVariableStorage.Enqueue(true); // for the posting confirm handler
        LibraryVariableStorage.Enqueue(false); // for open posted sales credit memo confirm handler
        SalesCreditMemo.Post.Invoke();

        VerifyUnitCostOnItemCard(Item, true); // ILEs exist but is service item so control should be editable
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateAutoFilled()
    var
        Customer: Record Customer;
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();

        CreateCustomer(Customer);
        Customer."Payment Terms Code" := '';
        Customer.Modify();

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        Assert.AreEqual(SalesCreditMemo."Payment Terms Code".Value, '', 'Payment Terms Code should be empty by default');
        Assert.AreEqual(SalesCreditMemo."Due Date".AsDate(), SalesCreditMemo."Document Date".AsDate(), 'Due Date incorrectly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateUpdatedWithPaymentTermsChange()
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        ExpectedDueDate: Date;
    begin
        Initialize();

        CreateCustomer(Customer);

        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer.Name);

        PaymentTerms.Get(Customer."Payment Terms Code");
        SalesCreditMemo."Payment Terms Code".SetValue(PaymentTerms.Code);
        ExpectedDueDate := CalcDate(PaymentTerms."Due Date Calculation", SalesCreditMemo."Document Date".AsDate());
        Assert.AreEqual(SalesCreditMemo."Due Date".AsDate(), ExpectedDueDate, 'Due Date incorrectly calculated.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentDatePresentOnSalesCreditMemo()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        Initialize();

        SalesCreditMemo.OpenNew();
        Assert.IsTrue(SalesCreditMemo."Shipment Date".Enabled(),
          Format('Shipment Date should be present on Sales Credit Memo'));

        PostedSalesCreditMemo.OpenView();
        Assert.IsTrue(SalesCreditMemo."Shipment Date".Enabled(),
          Format('Shipment Date should be present on Posted Sales Credit Memo'));
    end;

    local procedure CreateTwoCustomersSameName(var Customer: Record Customer)
    var
        Customer1: Record Customer;
    begin
        CreateCustomer(Customer1);
        CreateCustomer(Customer);
        Customer.Validate(Name, Customer1.Name);
        Customer.Modify(true);
    end;

    local procedure VerifySalesCreditMemoAgainstCustomer(SalesCreditMemo: TestPage "Sales Credit Memo"; Customer: Record Customer)
    begin
        SalesCreditMemo."Sell-to Customer Name".AssertEquals(Customer.Name);
        SalesCreditMemo."Sell-to Address".AssertEquals(Customer.Address);
        SalesCreditMemo."Sell-to City".AssertEquals(Customer.City);
        SalesCreditMemo."Sell-to Post Code".AssertEquals(Customer."Post Code");
    end;

    local procedure VerifySalesCreditMemoAgainstBillToCustomer(SalesCreditMemo: TestPage "Sales Credit Memo"; Customer: Record Customer)
    begin
        SalesCreditMemo."Bill-to Name".AssertEquals(Customer.Name);
        SalesCreditMemo."Bill-to Address".AssertEquals(Customer.Address);
        SalesCreditMemo."Bill-to City".AssertEquals(Customer.City);
        SalesCreditMemo."Bill-to Post Code".AssertEquals(Customer."Post Code");
    end;

    local procedure VerifyUnitCostOnItemCard(Item: Record Item; Editable: Boolean)
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        Assert.IsTrue(ItemCard."Unit Cost".Editable() = Editable,
          'Editable property for Unit cost field should be: ' + Format(Editable));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        VarReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarReply);
        Reply := VarReply;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListPageHandler(var CustomerList: TestPage "Customer List")
    var
        CustomerName: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerName);
        CustomerList.FILTER.SetFilter(Name, CustomerName);
        CustomerList.Last();
        CustomerList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerListCancelPageHandler(var CustomerList: TestPage "Customer List")
    begin
        CustomerList.Cancel().Invoke();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate("Address 2", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Address 2"), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Post Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Post Code"), DATABASE::Customer));
        Customer.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeSellToBillToCustomerConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        VarReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarReply);
        Reply := VarReply;
    end;

    local procedure AnswerYesToAllConfirmDialogs()
    var
        I: Integer;
    begin
        asserterror
        begin
            for I := 1 to 10 do
                LibraryVariableStorage.Enqueue(true);
            Commit();
            Error('');
        end
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyHandler(var ChangeExchRate: TestPage "Change Exchange Rate")
    var
        OldValue: Decimal;
    begin
        Evaluate(OldValue, ChangeExchRate.RefExchRate.Value);
        ChangeExchRate.RefExchRate.SetValue(OldValue + 1);
        ChangeExchRate.OK().Invoke();
    end;

    local procedure CreateNewRespCenter(var ResponsibilityCenter: Record "Responsibility Center")
    var
        NewCode: Code[10];
    begin
        ResponsibilityCenter.Init();
        NewCode := LibraryUtility.GenerateRandomCode(ResponsibilityCenter.FieldNo(Code), DATABASE::"Responsibility Center");
        ResponsibilityCenter.Validate(Code, NewCode);
        ResponsibilityCenter.Insert();
    end;
}

