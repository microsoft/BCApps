codeunit 138026 "O365 Simplify UI Purch.Cr.Memo"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Credit Memo] [SMB] [Purchase] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        SelectVendErr: Label 'You must select an existing vendor.';
        HelloWordTxt: Label 'Hello World';

    local procedure ClearTable(TableID: Integer)
    var
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PostedPurchCredMemoPageHandler')]
    [Scope('OnPrem')]
    procedure PostFromCard()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        // Setup
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreatePurchaseCrMemoHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        // Exercise
        PurchaseCreditMemo.OpenView();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        LibrarySales.EnableConfirmOnPostingDoc();
        PurchaseCreditMemo.Post.Invoke();

        // Verify
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostFromList()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        Initialize();

        // Setup
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.CreateItem(Item);
        LibrarySmallBusiness.CreatePurchaseCrMemoHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, LibraryRandom.RandDecInRange(1, 100, 2));

        // Exercise
        PurchaseCreditMemos.OpenView();
        PurchaseCreditMemos.GotoRecord(PurchaseHeader);
        LibrarySales.EnableWarningOnCloseUnpostedDoc();
        PurchaseCreditMemos.Post.Invoke();

        // Verify
    end;

    [Test]
    [HandlerFunctions('CurrencyHandler')]
    [Scope('OnPrem')]
    procedure Currency()
    var
        Vend: Record Vendor;
        Item: Record Item;
        CurrExchRate: Record "Currency Exchange Rate";
        PurchHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        OldValue: Decimal;
    begin
        Initialize();

        CurrExchRate.FindFirst();

        LibrarySmallBusiness.CreateVendor(Vend);
        Vend.Validate("Currency Code", CurrExchRate."Currency Code");
        Vend.Modify(true);

        LibrarySmallBusiness.CreateItem(Item);

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);

        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Credit Memo");
        PurchHeader.SetRange("Buy-from Vendor No.", Vend."No.");
        PurchHeader.FindFirst();
        OldValue := PurchHeader."Currency Factor";

        // Exercise
        PurchaseCreditMemo."Currency Code".AssistEdit();
        PurchaseCreditMemo.Close();

        // Verify
        PurchHeader.Find();
        Assert.AreNotEqual(OldValue, PurchHeader."Currency Factor", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenters()
    var
        Vend: Record Vendor;
        Item: Record Item;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        PurchHeader: Record "Purchase Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendor(Vend);
        LibrarySmallBusiness.CreateItem(Item);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);

        UserSetup.Init();
        UserSetup."User ID" := UserId;
        UserSetup.Validate("Purchase Resp. Ctr. Filter", ResponsibilityCenter.Code);
        if not UserSetup.Insert() then
            UserSetup.Modify();

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);
        PurchaseCreditMemo.Close();

        PurchHeader.SetRange("Buy-from Vendor No.", Vend."No.");
        PurchHeader.FindFirst();

        ResponsibilityCenter.TestField(Code, PurchHeader."Responsibility Center");

        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        UserSetup.Validate("Purchase Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify();

        PurchaseCreditMemo.OpenEdit();
        Assert.IsFalse(PurchaseCreditMemo.GotoRecord(PurchHeader), '');
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedText()
    var
        Vend: Record Vendor;
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        PurchLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendor(Vend);
        LibrarySmallBusiness.CreateItem(Item);

        ExtendedTextHeader.Init();
        ExtendedTextHeader.Validate("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.Validate("No.", Item."No.");
        ExtendedTextHeader.Validate("Purchase Invoice", true);
        ExtendedTextHeader.Insert(true);
        CreateExtTextLine(ExtendedTextHeader, HelloWordTxt);

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);

        PurchaseCreditMemo.PurchLines.New();
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines.InsertExtTexts.Invoke();

        // Verify
        PurchLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        PurchLine.SetRange("Buy-from Vendor No.", Vend."No.");
        PurchLine.FindSet();
        PurchLine.TestField("No.", Item."No.");

        PurchLine.SetRange("Buy-from Vendor No.");
        PurchLine.Next();
        PurchLine.TestField("No.", '');
        Assert.AreNotEqual(0, PurchLine."Attached to Line No.", '');
        PurchLine.TestField(Description, HelloWordTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingVend()
    var
        Vend: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        CreateVend(Vend);

        // Exercise: Select existing Vend.
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);

        // Verify.
        VerifyPurchCreditMemoAgainstVend(PurchaseCreditMemo, Vend);
        VerifyPurchCreditMemoAgainstBillToVend(PurchaseCreditMemo, Vend);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateVendNameWithExistingVendName()
    var
        Vend1: Record Vendor;
        Vend: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();
        CreateVend(Vend);
        CreateVend(Vend1);

        // Exercise: Select existing Vend.
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo.PurchLines.First();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend1.Name);

        // Verify.
        VerifyPurchCreditMemoAgainstVend(PurchaseCreditMemo, Vend1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewVendExpectError()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        VendName: Text[50];
    begin
        Initialize();

        LibrarySmallBusiness.CreateVendorTemplate(ConfigTemplateHeader);

        // Exercise.
        VendName := CopyStr(Format(CreateGuid()), 1, 50);

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo.PurchLines.First();

        // Verify
        asserterror PurchaseCreditMemo."Buy-from Vendor Name".SetValue(VendName);
    end;

    [Test]
    [HandlerFunctions('VendListPageHandler')]
    [Scope('OnPrem')]
    procedure VendorsWithSameName()
    var
        Vend: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        CreateTwoVendorsSameName(Vend);

        // Exercise: Select existing Vend - second one in the page handler
        LibraryVariableStorage.Enqueue(Vend.Name); // for the Vend list page handler
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(CopyStr(Vend.Name, 2, StrLen(Vend.Name) - 1));

        // Verify.
        VerifyPurchCreditMemoAgainstVend(PurchaseCreditMemo, Vend);
    end;

    [Test]
    [HandlerFunctions('VendListCancelPageHandler')]
    [Scope('OnPrem')]
    procedure VendorsWithSameNameCancelSelect()
    var
        Vend: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        CreateTwoVendorsSameName(Vend);

        // Exercise: Select existing Vend - second one in the page handler
        LibraryVariableStorage.Enqueue(Vend.Name); // for the Vend list page handler
        PurchaseCreditMemo.OpenNew();
        asserterror PurchaseCreditMemo."Buy-from Vendor Name".SetValue(CopyStr(Vend.Name, 2, StrLen(Vend.Name) - 1));
        Assert.ExpectedError(SelectVendErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateAutoFilled()
    var
        Vend: Record Vendor;
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();

        CreateVend(Vend);
        Vend."Payment Terms Code" := '';
        Vend.Modify();

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);

        PurchaseCreditMemo."Payment Terms Code".AssertEquals('');
        PurchaseCreditMemo."Due Date".AssertEquals(PurchaseCreditMemo."Document Date".AsDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateUpdatedWithPaymentTermsChange()
    var
        Vend: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        ExpectedDueDate: Date;
    begin
        Initialize();

        CreateVend(Vend);

        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vend.Name);

        PaymentTerms.Get(Vend."Payment Terms Code");
        PurchaseCreditMemo."Payment Terms Code".SetValue(PaymentTerms.Code);
        ExpectedDueDate := CalcDate(PaymentTerms."Due Date Calculation", PurchaseCreditMemo."Document Date".AsDate());
        PurchaseCreditMemo."Due Date".AssertEquals(ExpectedDueDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedRcptDatePresentOnPurchCreditMemo()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        Initialize();

        PurchaseCreditMemo.OpenNew();
        Assert.IsTrue(PurchaseCreditMemo."Expected Receipt Date".Enabled(),
          Format('Shipment Date should be present on Purch Credit Memo'));

        PostedPurchaseCreditMemo.OpenView();
        Assert.IsTrue(PurchaseCreditMemo."Expected Receipt Date".Enabled(),
          Format('Shipment Date should be present on Posted Purch Credit Memo'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePurchaseHeaderBuyFromName()
    var
        PurchaseHeader: Record "Purchase Header";
        NewName: Text[100];
    begin
        // [SCENARIO 288843] User is able to change document Buy-from Vendor Name after buy-from vendor had been specified when Vendor has "Disable Search by Name" = TRUE
        Initialize();

        // [GIVEN] Create purchase credit memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // [GIVEN] Vendor has "Disable Search by Name" = TRUE
        SetVendorDisableSearchByName(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] "Buy-from Vendor Name" is being changed to 'XXX'
        NewName := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Buy-from Vendor Name"), DATABASE::"Purchase Header");
        PurchaseHeader.Validate("Buy-from Vendor Name", NewName);

        // [THEN] Field "Buy-from Vendor Name" value changed to 'XXX'
        PurchaseHeader.TestField("Buy-from Vendor Name", NewName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePurchaseHeaderPayToName()
    var
        PurchaseHeader: Record "Purchase Header";
        NewName: Text[100];
    begin
        // [SCENARIO 288843] User is able to change document Buy-from Name after buy-from vendor had been specified when Vendor has "Disable Search by Name" = TRUE
        Initialize();

        // [GIVEN] Create purchase credit memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // [GIVEN] Vendor has "Disable Search by Name" = TRUE
        SetVendorDisableSearchByName(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] "Pay-to Name" is being changed to 'XXX'
        NewName := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Pay-to Name"), DATABASE::"Purchase Header");
        PurchaseHeader.Validate("Pay-to Name", NewName);

        // [THEN] Field "Pay-to Name" value changed to 'XXX'
        PurchaseHeader.TestField("Pay-to Name", NewName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePurchaseHeaderBuyFromNamePurchsSetupDisableSearchByName()
    var
        PurchaseHeader: Record "Purchase Header";
        NewName: Text[100];
    begin
        // [SCENARIO 362012] User is able to change document Buy-from Vendor Name after buy-from vendor had been specified when Purch Setup has "Disable Search by Name" = TRUE
        Initialize();

        // [GIVEN] Create purchase credit memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);

        // [GIVEN] Purchase Setup has "Disable Search by Name" = TRUE
        SetSalesSetupDisableSearchByName(true);

        // [WHEN] "Buy-from Vendor Name" is being changed to 'XXX'
        NewName := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Buy-from Vendor Name"), DATABASE::"Purchase Header");
        PurchaseHeader.Validate("Buy-from Vendor Name", NewName);

        // [THEN] Field "Buy-from Vendor Name" value changed to 'XXX'
        PurchaseHeader.TestField("Buy-from Vendor Name", NewName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePurchaseOrderBuyFromNameDisableSearchByName()
    var
        PurchaseHeader: Record "Purchase Header";
        PayToOptions: Option "Default (Vendor)","Another Vendor","Custom Address";
        NewName: Text[100];
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 424124] Pay-to Name should be editable when Purchase Order created for Vendor with Disable Search By Name = true
        Initialize();

        // [GIVEN] Create Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [GIVEN] Vendor has "Disable Search by Name" = TRUE
        SetVendorDisableSearchByName(PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] "Buy-from Vendor Name" is being changed to 'Test'
        NewName := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Buy-from Vendor Name"), DATABASE::"Purchase Header");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder."Buy-from Vendor Name".SetValue(NewName);

        // [WHEN] Pay-to = "Custom Address"
        PurchaseOrder.PayToOptions.SetValue(PayToOptions::"Custom Address");

        // [THEN] "Pay-to Name" field is editable and the value can be changed
        Assert.IsTrue(PurchaseOrder."Pay-to Name".Editable(), 'Pay-to Name is not editable');
        PurchaseOrder."Pay-to Name".SetValue(NewName);
        PurchaseOrder."Pay-to Name".AssertEquals(NewName);
    end;

    local procedure Initialize()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Simplify UI Purch.Cr.Memo");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Vendor);
        ConfigTemplateHeader.DeleteAll(true);

        LibraryApplicationArea.EnableFoundationSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Simplify UI Purch.Cr.Memo");

        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        InventorySetup.Get();
        InventorySetup."Automatic Cost Posting" := false;
        InventorySetup.Modify();

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Simplify UI Purch.Cr.Memo");
    end;

    local procedure CreateTwoVendorsSameName(var Vend: Record Vendor)
    var
        Vend1: Record Vendor;
    begin
        CreateVend(Vend1);
        CreateVend(Vend);
        Vend.Validate(Name, Vend1.Name);
        Vend.Modify(true);
    end;

    local procedure SetVendorDisableSearchByName(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Disable Search by Name", true);
        Vendor.Modify();
    end;

    local procedure SetSalesSetupDisableSearchByName(NewDisableSearchByName: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Disable Search by Name", NewDisableSearchByName);
        PurchSetup.Modify();
    end;

    local procedure VerifyPurchCreditMemoAgainstVend(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; Vend: Record Vendor)
    begin
        PurchaseCreditMemo."Buy-from Vendor Name".AssertEquals(Vend.Name);
        PurchaseCreditMemo."Buy-from Address".AssertEquals(Vend.Address);
        PurchaseCreditMemo."Buy-from City".AssertEquals(Vend.City);
        PurchaseCreditMemo."Buy-from Post Code".AssertEquals(Vend."Post Code");
    end;

    local procedure VerifyPurchCreditMemoAgainstBillToVend(PurchaseCreditMemo: TestPage "Purchase Credit Memo"; Vend: Record Vendor)
    begin
        PurchaseCreditMemo."Pay-to Name".AssertEquals(Vend.Name);
        PurchaseCreditMemo."Pay-to Address".AssertEquals(Vend.Address);
        PurchaseCreditMemo."Pay-to City".AssertEquals(Vend.City);
        PurchaseCreditMemo."Pay-to Post Code".AssertEquals(Vend."Post Code");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendListPageHandler(var VendorList: TestPage "Vendor List")
    var
        VendName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendName);
        VendorList.FILTER.SetFilter(Name, VendName);
        VendorList.Last();
        VendorList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendListCancelPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.Cancel().Invoke();
    end;

    local procedure CreateVend(var Vend: Record Vendor)
    begin
        LibrarySmallBusiness.CreateVendor(Vend);

        Vend.Validate(Name, LibraryUtility.GenerateRandomCode(Vend.FieldNo(Name), DATABASE::Vendor));
        Vend.Validate(Address, LibraryUtility.GenerateRandomCode(Vend.FieldNo(Address), DATABASE::Vendor));
        Vend.Validate("Address 2", LibraryUtility.GenerateRandomCode(Vend.FieldNo("Address 2"), DATABASE::Vendor));
        Vend.Validate(City, LibraryUtility.GenerateRandomCode(Vend.FieldNo(City), DATABASE::Vendor));
        Vend.Validate("Post Code", LibraryUtility.GenerateRandomCode(Vend.FieldNo("Post Code"), DATABASE::Vendor));
        Vend.Modify();
    end;

    local procedure CreateExtTextLine(ExtendedTextHeader: Record "Extended Text Header"; Description: Text[50])
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        ExtendedTextLine.Init();
        ExtendedTextLine.Validate("Table Name", ExtendedTextHeader."Table Name");
        ExtendedTextLine.Validate("No.", ExtendedTextHeader."No.");
        ExtendedTextLine.Validate("Language Code", ExtendedTextHeader."Language Code");
        ExtendedTextLine.Validate("Text No.", ExtendedTextHeader."Text No.");
        ExtendedTextLine.Validate("Line No.", 1);
        ExtendedTextLine.Validate(Text, Description);
        ExtendedTextLine.Insert(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
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

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchCredMemoPageHandler(var PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo")
    begin
        PostedPurchaseCreditMemo.OK().Invoke();
    end;
}

