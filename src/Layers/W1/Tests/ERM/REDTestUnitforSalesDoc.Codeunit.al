codeunit 134805 "RED Test Unit for Sales Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Revenue Expense Deferral] [Sales] [Deferral]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryResource: Codeunit "Library - Resource";
        DeferralUtilities: Codeunit "Deferral Utilities";
        ArchiveManagement: Codeunit ArchiveManagement;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalcMethod: Enum "Deferral Calculation Method";
        StartDate: Enum "Deferral Calculation Start Date";
        SalesDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Shipment,"Posted Invoice","Posted Credit Memo","Posted Return Receipt";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        isInitialized: Boolean;
        StockWarningSetup: Boolean;
        GLAccountOmitErr: Label 'When %1 is selected for';
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ConfirmCallOnceErr: Label 'Confirm should be called once.';
        DeferralLineQst: Label 'Do you want to update the deferral schedules for the lines?';

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127732] Annie can apply a deferral template to a Sales Order
        // Setup
        Initialize();

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was assigned to the sales line
        SalesLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SalesHeader."Posting Date", SalesLine.GetDeferralAmount(), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127732] Annie can apply a deferral template to a Sales Invoice
        // [GIVEN] User has created a deferral template
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] User has assigned a default deferral code to a GL Account
        CreateGLAccount(GLAccount);
        GLAccount.Validate("Default Deferral Template Code", DeferralTemplateCode);
        GLAccount.Modify();

        // [WHEN] Creating Sales Line for GL Account should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was assigned to the sales line
        SalesLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SalesHeader."Posting Date", SalesLine.GetDeferralAmount(), 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoWithResource()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127753] Annie can apply a deferral template to a Sales Credit Memo
        // [GIVEN] User has created a deferral template
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Equal per Period", StartDate::"Posting Date", 3);

        // [GIVEN] User has assigned a default deferral code to a Resource
        CreateResource(Resource);
        Resource.Validate("Default Deferral Template Code", DeferralTemplateCode);
        Resource.Modify(true);

        // [WHEN] Creating Sales Line for GL Account should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Resource, Resource."No.", SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was assigned to the sales line
        SalesLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SalesHeader."Posting Date", SalesLine.GetDeferralAmount(), 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
        DeferralAmount: Decimal;
    begin
        // [FEATURE] [Deferral Code] [Returns Deferral Start Date]
        // [SCENARIO 127753] Annie can apply a deferral template to a Sales Return on Beginning of Period
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Days per Period", StartDate::"Beginning of Period", 4);

        // [WHEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, ItemNo, SetDateDay(10, WorkDate()));

        // [THEN] The Deferral Code was assigned to the sales line
        SalesLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        DeferralHeader.Get("Deferral Document Type"::Sales, '', '',
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date", GetStartDate(StartDate::"Beginning of Period", SalesHeader."Posting Date"));
        DeferralHeader.TestField("Amount to Defer", SalesLine.GetDeferralAmount());
        DeferralHeader.TestField("No. of Periods", 4);

        // [THEN] Returns Deferral Start Date is set correctly
        ValidateReturnsDeferralStartDate(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          SalesLine."Returns Deferral Start Date", DeferralAmount);
        DeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderWithItemReturnStartDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
        DeferralAmount: Decimal;
    begin
        // [FEATURE] [Deferral Code] [Returns Deferral Start Date]
        // [SCENARIO 127753] Annie can apply a deferral template to a Sales Return on End of Period
        // and update the Sales Line to use a separate deferral start date
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Days per Period", StartDate::"End of Period", 4);

        // [WHEN] Creating Sales Line for Item should default deferral code and update the Sales Line Return Deferral Start Date
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, ItemNo, SetDateDay(10, WorkDate()));
        SalesLine.Validate("Returns Deferral Start Date", SetDateDay(15, WorkDate()));
        SalesLine.Modify();

        // [THEN] The Deferral Code was assigned to the sales line
        SalesLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created using the sales line Return Deferral Start Date
        DeferralHeader.Get("Deferral Document Type"::Sales, '', '',
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date", SalesLine."Returns Deferral Start Date");
        DeferralHeader.TestField("Amount to Defer", SalesLine.GetDeferralAmount());
        DeferralHeader.TestField("No. of Periods", 4);

        // [THEN] Returns Deferral Start Date is set correctly
        ValidateReturnsDeferralStartDate(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          SalesLine."Returns Deferral Start Date", DeferralAmount);
        DeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127732] Deferral template does not default on Sales Quote
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Creating Sales Line for Item on a Quote, the deferral code should not default
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Quote, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was not assigned to the sales line
        SalesLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was not created
        ValidateDeferralScheduleDoesNotExist(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127732] Deferral template does not default on Sales Blanket Order
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Creating Sales Line for Item on a Quote, the deferral code should not default
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Blanket Order", SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was not assigned to the sales line
        SalesLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was not created
        ValidateDeferralScheduleDoesNotExist(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingSalesLineType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Document Type] [Line]
        // [SCENARIO 127732] Changing the Sales Line Type removes the deferral code
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateGLAccountWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for GL Account defaults deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Changing the Sales Line Type
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Modify(true);

        // [THEN] The Deferral Code was removed from the sales line
        SalesLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingSalesLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Document Type] [Line]
        // [SCENARIO 127732] Changing Sales Line No. to an Item that does not have a default deferral code removes deferral schedule
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for Item defaults deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Changing the Sales Line No. to an Item that does not have a default deferral code
        Clear(Item);
        CreateItem(Item);
        Item.Validate("Unit Price", 500.0);
        Item.Modify(true);

        SalesLine.Validate("No.", Item."No.");
        SalesLine.Modify(true);

        // [THEN] The Deferral Code was removed from the sales line
        SalesLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClearingSalesLineDeferralCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Deferral Code] [Line]
        // [SCENARIO 127732] Clearing the Deferral Code on a line removes the deferral schedule
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateGLAccountWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for GL Account defaults deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::"G/L Account", AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Clearing the deferral code from the sales line
        SalesLine.Validate("Deferral Code", '');

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Deferral Code] [Delete Line]
        // [SCENARIO 127732]Deleting a sales line removes the deferral schedule
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateGLAccountWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for GL Account defaults deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Delete the sales line
        SalesLine.Delete(true);

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyOrderWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderDest: Record "Sales Header";
        SalesLineDest: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127732] Annie can copy a document and the deferrals are copied
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        Initialize();
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Creating Sales Line for Item should default deferral code - then modify the amounts
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Equal per Period", 3,
          SalesLine.GetDeferralAmount() * 0.8, SetDateDay(15, WorkDate()));

        // [WHEN] Create New sales document and copy the existing one with recalculate unmarked
        CreateSalesHeaderForCustomer(SalesHeaderDest,
          SalesHeaderDest."Document Type"::Invoice, SetDateDay(1, WorkDate()), SalesHeader."Sell-to Customer No.");
        CopyDoc(SalesHeaderDest, SalesHeader."Document Type", SalesHeader."No.", true, false);

        // [THEN] The deferral schedule was copied from the existing line
        SalesLineDest.SetRange("Document Type", SalesHeaderDest."Document Type");
        SalesLineDest.SetRange("Document No.", SalesHeaderDest."No.");
        SalesLineDest.FindFirst();
        SalesLineDest.TestField("Deferral Code", DeferralTemplateCode);
        SalesLineDest.TestField("Returns Deferral Start Date", 0D);
        VerifyDeferralsAreEqual(SalesLine, SalesLineDest);

        // Clean-up
        SetupStockWarning(StockWarningSetup);
        SetupCreditWarning(CreditWarningSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedInvoiceWithDeferral()
    var
        SalesHeaderDest: Record "Sales Header";
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127732] Annie can copy a posted document and the deferrals are copied
        CommonTestCopyPostedInvoiceWithDeferral(
          SalesHeaderDest."Document Type"::Order, StartDate::"Posting Date", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedInvoiceWithDeferralToReturnOrder()
    var
        SalesHeaderDest: Record "Sales Header";
    begin
        // [FEATURE] [Copy Document] [Returns Deferral Start Date]
        // [SCENARIO 127732] Annie can copy a posted invoice to a return order
        CommonTestCopyPostedInvoiceWithDeferral(
          SalesHeaderDest."Document Type"::"Return Order", StartDate::"Beginning of Next Period", true);
    end;

    local procedure CommonTestCopyPostedInvoiceWithDeferral(CopyToDocType: Enum "Sales Document Type"; LocalStartDate: Enum "Deferral Calculation Start Date"; UseStartDateForTest: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesHeaderDest: Record "Sales Header";
        SalesLineDest: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
    begin
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", LocalStartDate, 2);
        Initialize();
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Create and post the sales invoice with the default deferral
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvHeader.Get(DocNo);

        // [WHEN] Create New sales document and copy the existing one
        CreateSalesHeaderForCustomer(SalesHeaderDest, CopyToDocType, SetDateDay(1, WorkDate()), SalesInvHeader."Sell-to Customer No.");
        CopyDoc(SalesHeaderDest, "Sales Document Type From"::"Posted Invoice", SalesInvHeader."No.", true, false);

        // [THEN] The deferral schedule was copied from the existing line
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.FindFirst();

        SalesLineDest.SetRange("Document Type", SalesHeaderDest."Document Type");
        SalesLineDest.SetRange("Document No.", SalesHeaderDest."No.");
        SalesLineDest.Find('-');
        if SalesLineDest."No." = '' then
            SalesLineDest.Next();
        SalesLineDest.TestField("Deferral Code", DeferralTemplateCode);
        if UseStartDateForTest then
            SalesLineDest.TestField(
              "Returns Deferral Start Date", GetStartDate(LocalStartDate, SalesHeader."Posting Date"))
        else
            SalesLineDest.TestField("Returns Deferral Start Date", 0D);
        VerifyPostedDeferralsAreEqual(SalesInvLine, SalesLineDest);

        // Clean-up
        SetupStockWarning(StockWarningSetup);
        SetupCreditWarning(CreditWarningSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyOrderWithDeferralToQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderDest: Record "Sales Header";
        SalesLineDest: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127732] Copy an order with deferrals to a quote does not default the deferrals on a quote
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        Initialize();
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [WHEN] Create New sales document and copy the existing one
        CreateSalesHeaderForCustomer(SalesHeaderDest,
          SalesHeaderDest."Document Type"::Quote, SetDateDay(1, WorkDate()), SalesHeader."Sell-to Customer No.");
        CopyDoc(SalesHeaderDest, SalesHeader."Document Type", SalesHeader."No.", true, false);

        // [THEN] The Deferral Code was not assigned to the Quote sales line
        SalesLineDest.SetRange("Document Type", SalesHeaderDest."Document Type");
        SalesLineDest.SetRange("Document No.", SalesHeaderDest."No.");
        SalesLineDest.FindFirst();
        SalesLineDest.TestField("Deferral Code", '');
        SalesLineDest.TestField("Returns Deferral Start Date", 0D);

        // [THEN] The deferral schedule was not created
        ValidateDeferralScheduleDoesNotExist(
          SalesLineDest."Document Type", SalesLineDest."Document No.", SalesLineDest."Line No.");

        // Clean-up
        SetupStockWarning(StockWarningSetup);
        SetupCreditWarning(CreditWarningSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyQuoteToOrderDefaultsDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderDest: Record "Sales Header";
        SalesLineDest: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127732] Annie can copy a Quote to a different type and the deferrals are defaulted from the item
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        Initialize();
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Creating Sales Line for Item on Quote does not default the deferral
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Quote, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [WHEN] Create New sales Order and copy the existing Quote
        CreateSalesHeaderForCustomer(SalesHeaderDest,
          SalesHeaderDest."Document Type"::Order, SetDateDay(1, WorkDate()), SalesHeader."Sell-to Customer No.");
        CopyDoc(SalesHeaderDest, SalesHeader."Document Type", SalesHeader."No.", true, false);

        // [THEN] The Deferral Code was assigned to the Order sales line
        SalesLineDest.SetRange("Document Type", SalesHeaderDest."Document Type");
        SalesLineDest.SetRange("Document No.", SalesHeaderDest."No.");
        SalesLineDest.FindFirst();
        SalesLineDest.TestField("Deferral Code", DeferralTemplateCode);
        SalesLineDest.TestField("Returns Deferral Start Date", 0D);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          SalesLineDest."Document Type", SalesLineDest."Document No.", SalesLineDest."Line No.",
          DeferralTemplateCode, SalesHeaderDest."Posting Date", SalesLineDest.GetDeferralAmount(), 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyOrderWithDeferralToReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderDest: Record "Sales Header";
        SalesLineDest: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Returns Deferral Start Date]
        // [SCENARIO 127732] Copy an order with deferrals to a Return Order
        // defaults the Returns Deferral Start Date from the Return Order
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo,
          CalcMethod::"Straight-Line", StartDate::"End of Period", 3);
        Initialize();
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Creating Sales Line for Item should default deferral code - order uses day = 1
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [WHEN] Create New sales document and copy the existing one - Return uses day = 15
        CreateSalesHeaderForCustomer(SalesHeaderDest,
          SalesHeaderDest."Document Type"::"Return Order", SetDateDay(15, WorkDate()), SalesHeader."Sell-to Customer No.");
        CopyDoc(SalesHeaderDest, SalesHeader."Document Type", SalesHeader."No.", false, false);

        // [THEN] The Deferral Code was assigned to the Return Order sales line
        SalesLineDest.SetRange("Document Type", SalesHeaderDest."Document Type");
        SalesLineDest.SetRange("Document No.", SalesHeaderDest."No.");
        SalesLineDest.FindFirst();
        SalesLineDest.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The Returns Deferral Start Date was assigned a start date based on header posting date
        SalesLineDest.TestField("Returns Deferral Start Date",
          GetStartDate(StartDate::"End of Period", SalesHeader."Posting Date"));

        // Clean-up
        SetupStockWarning(StockWarningSetup);
        SetupCreditWarning(CreditWarningSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyReturnOrderWithDeferralToReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderDest: Record "Sales Header";
        SalesLineDest: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Returns Deferral Start Date]
        // [SCENARIO 127732] Copy Return order with deferrals defaults
        // the Returns Deferral Start Date from the original return order line
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo,
          CalcMethod::"Straight-Line", StartDate::"Beginning of Next Period", 3);
        Initialize();
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Creating Sales Line for Item should default deferral code - order uses day = 1
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // [WHEN] Create New sales document and copy the existing one - Return uses day = 15
        CreateSalesHeaderForCustomer(SalesHeaderDest,
          SalesHeaderDest."Document Type"::"Return Order", SetDateDay(15, WorkDate()), SalesHeader."Sell-to Customer No.");
        CopyDoc(SalesHeaderDest, SalesHeader."Document Type", SalesHeader."No.", false, false);

        // [THEN] The Deferral Code was assigned to the Return Order sales line
        SalesLineDest.SetRange("Document Type", SalesHeaderDest."Document Type");
        SalesLineDest.SetRange("Document No.", SalesHeaderDest."No.");
        SalesLineDest.FindFirst();
        SalesLineDest.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The Returns Deferral Start Date was assigned from the date on the original return order line
        SalesLineDest.TestField("Returns Deferral Start Date", SalesLine."Returns Deferral Start Date");
        SalesLineDest.TestField("Returns Deferral Start Date",
          GetStartDate(StartDate::"Beginning of Next Period", SalesHeader."Posting Date"));

        // Clean-up
        SetupStockWarning(StockWarningSetup);
        SetupCreditWarning(CreditWarningSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestArchiveOrderWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Archive Document]
        // [SCENARIO 127732] When a Sales Order is archived, the deferrals are archived along with it
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Days per Period", 4,
          SalesLine.GetDeferralAmount() * 0.7, SetDateDay(12, WorkDate()));

        // [WHEN] Document is archived
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesLine(SalesHeader, SalesLine);
        FindSalesLineArchive(SalesHeader, SalesLineArchive);

        // [THEN] The deferrals were moved to the archive
        VerifyDeferralArchivesAreEqual(SalesLineArchive, SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRestoreArchiveWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Restore Document]
        // [SCENARIO 127732] When a Sales Order Archive is restored, the deferrals are restored with it

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [GIVEN] Document is archived
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesLine(SalesHeader, SalesLine);
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Equal per Period", 5,
          SalesLine.GetDeferralAmount() * 0.9, SetDateDay(21, WorkDate()));

        // [GIVEN] Validation that the deferral schedule was updated
        ValidateDeferralSchedule(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SetDateDay(21, WorkDate()), SalesLine.GetDeferralAmount() * 0.9, 5);

        // [WHEN] Document is Restored from archive
        SalesHeaderArchive.Get(SalesHeader."Document Type", SalesHeader."No.", 1, 1);
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

        // [THEN] The deferrals were restored to original
        ValidateDeferralSchedule(
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SetDateDay(1, WorkDate()), SalesLine.GetDeferralAmount(), 3);

        FindSalesLineArchive(SalesHeader, SalesLineArchive);
        // [THEN] The deferrals match the archive
        VerifyDeferralArchivesAreEqual(SalesLineArchive, SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteArchiveOrderWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        LineNo: Integer;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Delete Archive]
        // [SCENARIO 127732] Deletion of Sales Order Archive should lead to deletion of archived deferral schedule
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Days per Period", 4,
          SalesLine.GetDeferralAmount() * 0.7, SetDateDay(12, WorkDate()));

        // [GIVEN] Document is archived
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesLineArchive(SalesHeader, SalesLineArchive);
        DocNo := SalesLineArchive."Document No.";
        LineNo := SalesLineArchive."Line No.";

        // [GIVEN] Remove the sales Doc
        DeleteSalesDoc(SalesHeader);

        // [WHEN] Remove the archives
        SaleslineArchive.Delete(true);

        // [THEN] the archived deferral schedule was deleted
        ValidateDeferralArchiveScheduleDoesNotExist(SalesHeader."Document Type"::Order, DocNo, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        AmtToDefer: Decimal;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice is posted, the general ledger accounts for the deferrals are created
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := SalesLine.GetDeferralAmount();

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Invoice Line and Posted Deferral tables - GL is correct
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 2, 3, SetDateDay(1, WorkDate()), false);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoInvoicesWithDeferralConfirmYes()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Sales Invoices with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibrarySales.SetPostWithJobQueue(false);

        // [GIVEN] Two Sales Invoices with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::Invoice);

        // [WHEN] Sales Invoices are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", true,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Invoices");

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo1, DeferralTemplateCode, AccNo, AmtToDefer1, AmtToDefer1, 2, 3, NewPostDate, false);
        VerifyPostedInvoiceDeferralsAndGL(DocNo2, DeferralTemplateCode, AccNo, AmtToDefer2, AmtToDefer2, 2, 3, NewPostDate, false);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoInvoicesWithDeferralConfirmYesBackground()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Sales Invoices with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Sales Invoices with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::Invoice);

        // [WHEN] Sales Invoices are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", true,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Invoices");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo1, DeferralTemplateCode, AccNo, AmtToDefer1, AmtToDefer1, 2, 3, NewPostDate, false);
        VerifyPostedInvoiceDeferralsAndGL(DocNo2, DeferralTemplateCode, AccNo, AmtToDefer2, AmtToDefer2, 2, 3, NewPostDate, false);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrdersRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoOrdersWithDeferralConfirmYes()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Sales Orders with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Sales Orders with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::Order);

        // [WHEN] Sales Orders are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", true,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Orders");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo1, DeferralTemplateCode, AccNo, AmtToDefer1, AmtToDefer1, 2, 3, NewPostDate, false);
        VerifyPostedInvoiceDeferralsAndGL(DocNo2, DeferralTemplateCode, AccNo, AmtToDefer2, AmtToDefer2, 2, 3, NewPostDate, false);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesCreditMemosRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoCreditMemosWithDeferralConfirmYes()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Credit Memos with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Credit Memos with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::"Credit Memo");

        // [WHEN] Credit Memos are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", true,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Credit Memos");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Posted Credit Memos is 01.11.16
        VerifyCrMemoPostingDate(DocNo1, NewPostDate);
        VerifyCrMemoPostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedCrMemosDeferralsAndGL(
          SalesDocType::"Posted Credit Memo", DocNo1, DeferralTemplateCode, AccNo, AmtToDefer1, AmtToDefer1, 2, 3, NewPostDate);
        VerifyPostedCrMemosDeferralsAndGL(
          SalesDocType::"Posted Credit Memo", DocNo2, DeferralTemplateCode, AccNo, AmtToDefer2, AmtToDefer2, 2, 3, NewPostDate);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesInvoicesRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoInvoicesWithDeferralConfirmNo()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Sales Invoices with updated Posting Date should update deferral schedule with Confirm No
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Sales Invoices with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::Invoice);

        // [WHEN] Sales Invoices are posted with batch report on 01.11.16 and confirm update on deferral date = No
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", false,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Invoices");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.10.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(
          DocNo1, DeferralTemplateCode, AccNo, AmtToDefer1, AmtToDefer1, 2, 3, SalesHeader1."Posting Date", false);
        VerifyPostedInvoiceDeferralsAndGL(
          DocNo2, DeferralTemplateCode, AccNo, AmtToDefer2, AmtToDefer2, 2, 3, SalesHeader2."Posting Date", false);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesOrdersRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoOrdersWithDeferralConfirmNo()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Sales Orders with updated Posting Date should update deferral schedule with Confirm No
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Sales Orders with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::Order);

        // [WHEN] Sales Orders are posted with batch report on 01.11.16 and confirm update on deferral date = No
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", false,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Orders");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.10.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(
          DocNo1, DeferralTemplateCode, AccNo, AmtToDefer1, AmtToDefer1, 2, 3, SalesHeader1."Posting Date", false);
        VerifyPostedInvoiceDeferralsAndGL(
          DocNo2, DeferralTemplateCode, AccNo, AmtToDefer2, AmtToDefer2, 2, 3, SalesHeader2."Posting Date", false);
    end;

    [Test]
    [HandlerFunctions('BatchPostSalesCreditMemosRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoCreditMemosWithDeferralConfirmNo()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AccNo: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Credit Memos with updated Posting Date should update deferral schedule with Confirm No
        Initialize();
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Credit Memos with Posting Date = 01.10.16 and deferral code
        CreateTwoSalesDocsWithDeferral(
          SalesHeader1, SalesHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, SalesHeader1."Document Type"::"Credit Memo");

        // [WHEN] Credit Memos are posted with batch report on 01.11.16 and confirm update on deferral date = No
        RunBatchPostReport(
          NewPostDate, SalesHeader1."Posting Date", false,
          SalesHeader1."No.", SalesHeader2."No.",
          REPORT::"Batch Post Sales Credit Memos");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(SalesHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Posted Credit Memos is 01.11.16
        VerifyCrMemoPostingDate(DocNo1, NewPostDate);
        VerifyCrMemoPostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.10.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedCrMemosDeferralsAndGL(
          SalesDocType::"Posted Credit Memo", DocNo1, DeferralTemplateCode,
          AccNo, AmtToDefer1, AmtToDefer1, 2, 3, SalesHeader1."Posting Date");
        VerifyPostedCrMemosDeferralsAndGL(
          SalesDocType::"Posted Credit Memo", DocNo2, DeferralTemplateCode,
          AccNo, AmtToDefer2, AmtToDefer2, 2, 3, SalesHeader1."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralDeletesDeferralHeaderAndLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        OriginalDocNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        LineNo: Integer;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 159878] When a Sales Invoice is posted, the Deferral Header and Deferral Line records are deleted
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Create Sales Line for Item
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := SalesLine.GetDeferralAmount();
        OriginalDocNo := SalesHeader."No.";
        LineNo := SalesLine."Line No.";

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Invoice Line and Posted Deferral tables
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 2, 3, SetDateDay(1, WorkDate()), false);

        // [THEN] Deferrals were removed from the Deferral Header and Deferral Line Tables
        VerifyDeferralHeaderLinesRemoved(SalesDocType::Invoice, OriginalDocNo, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithCurrencyAndDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrExchRate: Record "Currency Exchange Rate";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        AmtToDeferLCY: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When Sales Invoice with currency posts, GL accounts for deferrals are created
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithCurrencyAndLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := SalesLine.GetDeferralAmount();
        AmtToDeferLCY :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(SetDateDay(1, WorkDate()),
              SalesHeader."Currency Code", AmtToDefer, SalesHeader."Currency Factor"));

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Invoice Line and Posted Deferral tables - GL is correct
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDeferLCY, 2, 3, SetDateDay(1, WorkDate()), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceTwoLinesWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice is posted with multiple lines of the same type,
        // the general ledger accounts for the deferrals are combined when they are created
        // [GIVEN] User has assigned a default deferral code to two differnt Items
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        CreateItemWithUnitPrice(Item);
        Item.Validate("Default Deferral Template Code", DeferralTemplateCode);
        Item.Modify(true);
        ItemNo := Item."No.";
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [GIVEN] Add the second item to the document
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 2);
        SalesHeader.CalcFields(Amount);

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were posted to GL
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, false);

        // [THEN] G/L Entries for deferral periods are posted according to Deferral Schedule (TFS 378831)
        VerifySalesGLDeferralAccount(SalesLine, DocNo, -SalesHeader.Amount);
        VerifyGLForDeferralPeriod(DocNo, AccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithPartialDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DeferralHeader: Record "Deferral Header";
        SalesAccount: Code[20];
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        SalesAmount: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice is posted with a partial deferral, the sales accounts is reduced by the deferral and balance posted to first period
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := Round(SalesLine.GetDeferralAmount() * 0.7);
        SalesAmount := SalesLine.GetDeferralAmount() - AmtToDefer;
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Straight-Line", 2,
          AmtToDefer, SetDateDay(1, WorkDate()));
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesAccount := GenPostingSetup."Sales Account";

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Invoice Line and Posted Deferral tables - GL & Sales is correct
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGLWithSalesAmt(
          DocNo, DeferralTemplateCode, AccNo, SalesAccount, AmtToDefer, AmtToDefer, 1, 2, 3, 5, SalesAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralNoDeferralHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice will not post if the deferral header record is not created
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(SalesLine, DeferralHeader);
        DeferralHeader.Delete();

        // [WHEN] Document is posted
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(NoDeferralScheduleErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralDeferralHeaderZero()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice will not post if the deferral header Amount To Defer is Zero
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(SalesLine, DeferralHeader);
        DeferralHeader."Amount to Defer" := 0;
        DeferralHeader.Modify();

        // [WHEN] Document is posted
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(NoDeferralScheduleErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralNoDeferralLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice will not post if the deferral schedule does not have any lines
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(SalesLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        DeferralLine.DeleteAll();

        // [WHEN] Document is posted
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(NoDeferralScheduleErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralOneZeroDeferralLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Sales Invoice will not post if one of the deferral schedule lines has a zero amount
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(SalesLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        if DeferralLine.FindFirst() then begin
            DeferralLine.Amount := 0.0;
            DeferralLine."Amount (LCY)" := 0.0;
            DeferralLine.Modify();
        end;

        // [WHEN] Document is posted
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(ZeroDeferralAmtErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        LineNo: Integer;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Credit Memo is posted, the general ledger accounts for the deferrals are created
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, ItemNo, SetDateDay(15, WorkDate()));
        AmtToDefer := SalesLine.GetDeferralAmount();

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Credit Memo and Posted Deferral tables
        FindSalesCrMemoLine(SalesCrMemoLine, DocNo);
        LineNo := SalesCrMemoLine."Line No.";
        SalesCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(SalesDocType::"Posted Credit Memo", DocNo,
          LineNo, DeferralTemplateCode, SetDateDay(15, WorkDate()), AmtToDefer, AmtToDefer, 3);

        // [THEN] The deferrals were posted to GL
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(15, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 5, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoWithPartialDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        GenPostingSetup: Record "General Posting Setup";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GLAccount: Record "G/L Account";
        SalesAmount: Decimal;
        GLSalesAmount: Decimal;
        SalesAccount: Code[20];
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        GLSum: Decimal;
        GLCount: Integer;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Credit Memo is posted with a partial deferral, the correct Sales Credit Memo Account is posted to with correct amounts
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := Round(SalesLine.GetDeferralAmount() * 0.7);
        SalesAmount := SalesLine.GetDeferralAmount() - AmtToDefer;
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Straight-Line", 2,
          AmtToDefer, SetDateDay(1, WorkDate()));

        // [GIVEN] Sales Credit Memo Account updated
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        CreateGLAccount(GLAccount);
        SalesAccount := GLAccount."No.";
        GenPostingSetup.Validate("Sales Credit Memo Account", SalesAccount);
        GenPostingSetup.Modify();

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Credit Memo and Posted Deferral tables
        FindSalesCrMemoLine(SalesCrMemoLine, DocNo);
        SalesCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(SalesDocType::"Posted Credit Memo", DocNo,
          SalesCrMemoLine."Line No.", DeferralTemplateCode, SetDateDay(1, WorkDate()), AmtToDefer, AmtToDefer, 2);

        // [THEN] The amount not deferred was posted to GL for the sales credit memo account
        GLCalcSalesAmount(DocNo, SalesAccount, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), GLCount, GLSum, GLSalesAmount);
        Assert.AreEqual(5, GLCount, 'An incorrect number of lines was posted');
        Assert.AreEqual(SalesAmount, Abs(GLSalesAmount), 'An incorrect Amount was posted for sales');

        // [THEN] The deferrals were posted to GL
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 3, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostReturnOrderWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127736] When a Return Order is posted, the general ledger accounts for the deferrals are created
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, ItemNo, SetDateDay(15, WorkDate()));
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        AmtToDefer := SalesLine.GetDeferralAmount();

        // [WHEN] Document is posted
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were moved to the Sales Credit Memo and Posted Deferral tables
        FindSalesCrMemoLine(SalesCrMemoLine, DocNo);
        SalesCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(SalesDocType::"Posted Credit Memo", DocNo,
          SalesCrMemoLine."Line No.", DeferralTemplateCode, SetDateDay(15, WorkDate()), AmtToDefer, AmtToDefer, 3);

        // [THEN] The deferrals were posted to GL
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(15, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 5, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOrderWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document] [Orders]
        // [SCENARIO 159878] When a Order is Shipped & Invoiced, G/L entries post to deferral account
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Sales Line for Item
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := SalesLine.GetDeferralAmount();
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [WHEN] Invoice the Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Deferral code is in Sales Invoice Line
        // [THEN] Posted Deferral header and Line tables created
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 2, 3, SetDateDay(1, WorkDate()), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial Order is Shipped-Invoiced,  G/L entries post to deferral account for partial amts only
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Create Sales Line for Item with partial qtys Shipped/Invoiced
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 5, 2, 1);
        AmtToDefer := GetInvoiceQtyAmtToDefer(SalesLine, SalesLine.GetDeferralAmount(), SalesHeader."Currency Code");

        // [WHEN] Invoice the partial Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Deferral header and Line tables are for the partial quantities
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 2, 3, SetDateDay(1, WorkDate()), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithCurrencyAndDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrExchRate: Record "Currency Exchange Rate";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        AmtToDeferLCY: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial order with currency posts,  G/L entries post to deferral account
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Sales Line for Item with partial qtys Shipped/Invoiced with currency amounts
        CreateSalesDocWithCurrencyAndLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 6, 3, 2);
        AmtToDefer := GetInvoiceQtyAmtToDefer(SalesLine, SalesLine.GetDeferralAmount(), SalesHeader."Currency Code");
        AmtToDeferLCY :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(SetDateDay(1, WorkDate()),
              SalesHeader."Currency Code", AmtToDefer, SalesHeader."Currency Factor"));
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [WHEN] Invoice the Sales Order with currency
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Deferral header and Line tables are for the partial quantities and appropriate currency
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDeferLCY, 2, 3, SetDateDay(1, WorkDate()), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderTwoLinesWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial Order is posted with multiple lines/same type, G/L entries for deferral account are combined
        // [GIVEN] User has assigned a default deferral code to two different Items
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        CreateItemWithUnitPrice(Item);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        Item.Validate("Default Deferral Template Code", DeferralTemplateCode);
        Item.Modify(true);
        ItemNo := Item."No.";

        // [GIVEN] Create Sales Line for Item with partial qtys Shipped/Invoiced
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 5, 3, 2);

        // [GIVEN] Add the second item to the document
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 2);
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 4, 2, 1);

        // [WHEN] Invoice the partial Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries are combined for the deferral account from both lines
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithPartialDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DeferralHeader: Record "Deferral Header";
        SalesAccount: Code[20];
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        SalesAmount: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When a Sales Order is posted with a partial deferral, the sales accounts is reduced by the deferral and balance posted to first period
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Sales Line with Deferral for 70%
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 5, 1, 1);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        AmtToDefer := Round(SalesLine.GetDeferralAmount() * 0.7);
        ModifyDeferral(SalesLine, DeferralHeader."Calc. Method"::"Straight-Line", 2,
          AmtToDefer, SetDateDay(1, WorkDate()));
        AmtToDefer := GetInvoiceQtyAmtToDefer(SalesLine, AmtToDefer, SalesHeader."Currency Code");
        SalesAmount := GetInvoiceQtyAmtToDefer(SalesLine, SalesLine.GetDeferralAmount(), SalesHeader."Currency Code") - AmtToDefer;
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesAccount := GenPostingSetup."Sales Account";

        // [WHEN] Invoice the partial order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entries for sales account is reduced by amt deferred which is posted directly to deferral account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGLWithSalesAmt(DocNo,
          DeferralTemplateCode, AccNo, SalesAccount, AmtToDefer, AmtToDefer, 1, 2, 3, 5, SalesAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithDeferralMultipleTimes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial Order is Shipped-Invoiced multiple times, the G/L entries post to deferral account for partial amounts
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Sales Line with partial quantities
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 5, 2, 1);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        AmtToDefer := GetInvoiceQtyAmtToDefer(SalesLine, SalesLine.GetDeferralAmount(), SalesHeader."Currency Code");

        // [WHEN] Invoice the partial order the first time
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] The Order Qty to Invoice is updated again
        FindSalesLine(SalesHeader, SalesLine);
        UpdateQtyToShipInvoiceOnSalesLine(SalesLine, 5, 3, 2);
        AmtToDefer := GetInvoiceQtyAmtToDefer(SalesLine, SalesLine.GetDeferralAmount(), SalesHeader."Currency Code");

        // [WHEN] Invoice the partial order the second time
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Deferral header and Line tables are for the partial quantities from second order
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 2, 3, SetDateDay(1, WorkDate()), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesInvoiceDeferralSchedulePos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        SalesInvoice: TestPage "Sales Invoice";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Invoice with GL Account allows editing of the deferral code and accessing schedule
        // [GIVEN] User has created a Sales Document with one line item for GL Account
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Open the Sales Invoice as edit with the document
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.First();

        // [THEN] Deferral Code can be entered for GL Account
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);

        // [THEN] Deferral Schedule can be opened for GL Account
        SalesInvoice.SalesLines.DeferralSchedule.Invoke();

        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesInvoiceDeferralScheduleNeg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Invoice with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();

        // [GIVEN] User has created a Sales Document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());

        // [WHEN] Open the Sales Invoice as edit with the document
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.Type.Value(Format(SalesLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        // Assert.IsFalse(SalesInvoice.SalesLines."Deferral Code".Enabled(),'Deferral Code should not be enabled');
        Assert.IsFalse(SalesInvoice.SalesLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        SalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('UpdateDeferralSchedulePeriodHandler')]
    [Scope('OnPrem')]
    procedure TestEditSalesInvoiceDeferralScheduleIsRecalculated()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        SalesInvoice: TestPage "Sales Invoice";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Updating Deferral Schedule period updates the deferral lines
        Initialize();

        // [GIVEN] User has created a Sales Document with one line item for Item that has a default deferral code
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        Commit();

        // [GIVEN] Two periods are created
        FindDeferralHeader(SalesLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        Assert.AreEqual(2, DeferralLine.Count, 'An incorrect number of lines was created');

        // [GIVEN] Open the Sales Invoice as edit with the document
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.First();
        LibraryVariableStorage.Enqueue(3);

        // [WHEN] Deferral Schedule is updated - happens in the handler function
        SalesInvoice.SalesLines.DeferralSchedule.Invoke();

        // [THEN] Three periods have created three deferral lines
        FindDeferralHeader(SalesLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        Assert.AreEqual(3, DeferralLine.Count, 'An incorrect number of lines was recalculated');
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSalesOrderDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        SalesOrder: TestPage "Sales Order";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Order with GL Account allows editing of the deferral code and accessing schedule
        Initialize();

        // [GIVEN] User has created a Sales Document with one line item for GL Account
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [THEN] Deferral Code can be entered for GL Account
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);

        // [THEN] Deferral Schedule can be opened for GL Account
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(SalesLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(SalesHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesOrderDeferralScheduleNeg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Order with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();

        // [GIVEN] User has created a Sales Document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());

        // [WHEN] Open the Sales Order as edit with the document
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Type.Value(Format(SalesLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(SalesOrder.SalesLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSalesCreditMemoDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Credit Memo with GL Account allows editing of the deferral code and accessing schedule
        // [GIVEN] User has created a Sales Document with one line item for GL Account
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [THEN] Deferral Code can be entered for GL Account
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);

        // [THEN] Deferral Schedule can be opened for GL Account
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.SalesLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(SalesLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(SalesHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesCreditMemoDeferralScheduleNeg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Credit Memo with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();

        // [GIVEN] User has created a Sales Document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer());

        // [WHEN] Open the Sales Invoice as edit with the document
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.SalesLines.Type.Value(Format(SalesLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(SalesCreditMemo.SalesLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        SalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSalesReturnOrderDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        SalesReturnOrder: TestPage "Sales Return Order";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Return Order with GL Account allows editing of the deferral code and accessing schedule
        // [GIVEN] User has created a Sales Document with one line item for GL Account
        CreateGLAccount(GLAccount);
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Return Order", SalesLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [THEN] Deferral Code can be entered for GL Account
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);

        // [THEN] Deferral Schedule can be opened for GL Account
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder.SalesLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(SalesLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(SalesHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenSalesReturnOrderDeferralScheduleNeg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] Entering a Sales Return Order with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();

        // [GIVEN] User has created a Sales Document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer());

        // [WHEN] Open the Sales Return Order as edit with the document
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrder.SalesLines.Type.Value(Format(SalesLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(SalesReturnOrder.SalesLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        SalesReturnOrder.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleViewHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPostedSalesInvoiceDeferralSchedulePos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] View deferrals for posted invoice
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Create and post the sales invoice with the default deferral
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvHeader.Get(DocNo);

        // [WHEN] Open the Posted Sales Invoice
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", DocNo);
        PostedSalesInvoice.SalesInvLines.First();

        // [THEN] Deferral Schedule can be opened for line
        PostedSalesInvoice.SalesInvLines.DeferralSchedule.Invoke();

        PostedSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleViewHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPostedSalesCreditMemoDeferralSchedulePos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] View deferrals for posted Credit Memo
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] Create and post the sales Credit Memo with the default deferral
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesCrMemoHeader.Get(DocNo);

        // [WHEN] Open the Posted Sales Invoice
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", DocNo);
        PostedSalesCreditMemo.SalesCrMemoLines.First();

        // [THEN] Deferral Schedule can be opened for line
        PostedSalesCreditMemo.SalesCrMemoLines.DeferralSchedule.Invoke();

        PostedSalesCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleArchiveHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSalesOrderArchiveDeferralSchedulePos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesOrderArchive: TestPage "Sales Order Archive";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732] View deferrals for Archived Sales Order
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [GIVEN] Document is archived
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesOrderArchive(SalesHeaderArchive, SalesHeader."No.");

        // [WHEN] Open the Posted Sales Order Archive
        SalesOrderArchive.OpenView();
        SalesOrderArchive.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrderArchive.FILTER.SetFilter("Doc. No. Occurrence", '1');
        SalesOrderArchive.FILTER.SetFilter("Version No.", '1');
        SalesOrderArchive.SalesLinesArchive.First();

        // [THEN] Deferral Schedule Archive can be opened for line
        SalesOrderArchive.SalesLinesArchive.DeferralSchedule.Invoke();

        SalesOrderArchive.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleArchiveHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSalesReturnOrderArchiveDeferralSchedulePos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesReturnOrderArchive: TestPage "Sales Return Order Archive";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127732]  View archive deferrals for return order
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create and archive the sales return order with the default deferral
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Return Order", SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesReturnOrderArchive(SalesHeaderArchive, SalesHeader."No.");

        // [WHEN] Open the Posted Sales Invoice
        SalesReturnOrderArchive.OpenView();
        SalesReturnOrderArchive.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrderArchive.FILTER.SetFilter("Doc. No. Occurrence", '1');
        SalesReturnOrderArchive.FILTER.SetFilter("Version No.", '1');
        SalesReturnOrderArchive.SalesLinesArchive.First();

        // [THEN] Deferral Schedule Archive can be opened for line
        SalesReturnOrderArchive.SalesLinesArchive.DeferralSchedule.Invoke();

        SalesReturnOrderArchive.Close();
    end;

    [Test]
    [HandlerFunctions('UpdateAmountToDeferOnDeferralScheduleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateAmountToDeferOnDeferralScheduleCreatedBeforeAmountValidation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        DeferralTemplateCode: Code[10];
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 416877] Stan can change "Amount to Defer" on deferall schedule created before Amount is validated on Line/Document

        Initialize();

        NoOfPeriods := LibraryRandom.RandIntInRange(10, 20);
        DeferralTemplateCode :=
            CreateDeferralCode(CalcMethod::"Equal per Period", StartDate::"Beginning of Next Period", NoOfPeriods);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 0);

        SalesLine.Validate("Deferral Code", DeferralTemplateCode);

        SalesLine.Modify(true);

        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);

        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(SalesLine.GetDeferralAmount() / 2);

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.DeferralSchedule.Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('UpdateAmountToDeferOnDeferralScheduleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateAmountToDeferOnDeferralScheduleCreatedAfterAmountValidation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        DeferralTemplateCode: Code[10];
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 416877] Stan can change "Amount to Defer" on deferall schedule created after Amount is validated on Line/Document

        Initialize();

        NoOfPeriods := LibraryRandom.RandIntInRange(10, 20);
        DeferralTemplateCode :=
            CreateDeferralCode(CalcMethod::"Equal per Period", StartDate::"Beginning of Next Period", NoOfPeriods);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 0);

        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);

        SalesLine.Modify(true);

        SalesLine.Validate("Deferral Code", DeferralTemplateCode);

        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(SalesLine.GetDeferralAmount() / 2);

        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.DeferralSchedule.Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDeferralsWithBlankDescriptionWhenOmitDefaultDescriptionEnabledOnDeferralGLAccount()
    var
        GLAccountDeferral: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 422767] Stan can't post Sales document with Deferral setup when Deferral Account has enabled "Omit Default Descr. in Jnl." and blank Description Deferral Template
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(GLAccountDeferral, DeferralTemplateCode, '', true);

        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Assert.ExpectedError(StrSubstNo(GLAccountOmitErr, GLAccountDeferral.FieldCaption("Omit Default Descr. in Jnl.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDeferralsWithBlankDescriptionWhenOmitDefaultDescriptionDisabledOnDeferralGLAccount()
    var
        GLAccountDeferral: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 422767] Stan can post Sales document with Deferral setup when Deferral Account has disabled "Omit Default Descr. in Jnl." and blank Description Deferral Template
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(GLAccountDeferral, DeferralTemplateCode, '', false);

        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyGLEntriesExistWithBlankDescription(GLAccountDeferral."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDeferralsWithDescriptionWhenOmitDefaultDescriptionEnabledOnDeferralGLAccount()
    var
        GLAccountDeferral: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 422767] Stan can post Sales document with Deferral setup when Deferral Account has enabled "Omit Default Descr. in Jnl." and specified Description Deferral Template
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        PrepareSalesReceivableSetup(StockWarningSetup, CreditWarningSetup);

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(GLAccountDeferral, DeferralTemplateCode, LibraryRandom.RandText(10), true);

        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyGLEntriesDoNotExistWithBlankDescription(GLAccountDeferral."No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RED Test Unit for Sales Doc");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RED Test Unit for Sales Doc");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RED Test Unit for Sales Doc");
    end;

    local procedure CreateDeferralCode(CalcMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumOfPeriods: Integer): Code[10]
    begin
        exit(LibraryERM.CreateDeferralTemplateCode(CalcMethod, StartDate, NumOfPeriods));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure CreateItemWithUnitPrice(var Item: Record Item)
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2),
          LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateItemWithDefaultDeferralCode(var DefaultDeferralCode: Code[10]; var ItemNo: Code[20]; DefaultCalcMethod: Enum "Deferral Calculation Method"; DefaultStartDate: Enum "Deferral Calculation Start Date"; DefaultNoOfPeriods: Integer)
    var
        Item: Record Item;
    begin
        DefaultDeferralCode := CreateDeferralCode(DefaultCalcMethod, DefaultStartDate, DefaultNoOfPeriods);

        CreateItemWithUnitPrice(Item);
        Item.Validate("Default Deferral Template Code", DefaultDeferralCode);
        Item.Modify(true);
        ItemNo := Item."No.";
    end;

    local procedure CreateGLAccountWithDefaultDeferralCode(var DefaultDeferralCode: Code[10]; var No: Code[20]; DefaultCalcMethod: Enum "Deferral Calculation Method"; DefaultStartDate: Enum "Deferral Calculation Start Date"; DefaultNoOfPeriods: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        DefaultDeferralCode := CreateDeferralCode(DefaultCalcMethod, DefaultStartDate, DefaultNoOfPeriods);

        CreateGLAccount(GLAccount);
        GLAccount.Validate("Default Deferral Template Code", DefaultDeferralCode);
        GLAccount.Modify(true);
        No := GLAccount."No.";
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        No: Code[20];
    begin
        No := LibraryERM.CreateGLAccountWithSalesSetup();
        GLAccount.Get(No);
    end;

    local procedure CreateResource(var Resource: Record Resource)
    begin
        LibraryResource.CreateResourceNew(Resource);
    end;

    local procedure CreateSalesDocWithLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, 2);
        case SalesLine.Type of
            SalesLine.Type::"G/L Account",
            SalesLine.Type::Resource:
                begin
                    SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
                    SalesLine.Modify(true);
                end;
        end;
    end;

    local procedure CreateSalesHeaderForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; PostingDate: Date; CustomerCode: Code[20])
    begin
        Clear(SalesHeader);
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Validate("Sell-to Customer No.", CustomerCode);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Insert(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var AmtToDefer: Decimal; var PostingDocNo: Code[20]; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
    begin
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          DocumentType, SalesLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := SalesLine.GetDeferralAmount();
        PostingDocNo := NoSeries.PeekNextNo(SalesHeader."Posting No. Series", SalesHeader."Posting Date");
    end;

    local procedure CreateTwoSalesDocsWithDeferral(var SalesHeader1: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var DeferralTemplateCode: Code[10]; var AccNo: Code[20]; var DocNo1: Code[20]; var DocNo2: Code[20]; var AmtToDefer1: Decimal; var AmtToDefer2: Decimal; DocType: Enum "Sales Document Type")
    var
        ItemNo: Code[20];
    begin
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        CreateSalesDocument(SalesHeader1, AmtToDefer1, DocNo1, DocType, ItemNo);
        CreateSalesDocument(SalesHeader2, AmtToDefer2, DocNo2, DocType, ItemNo);
    end;

    local procedure DeleteSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Delete(true);
    end;

    local procedure SetDateDay(Day: Integer; StartDate: Date): Date
    begin
        // Use the workdate but set to a specific day of that month
        exit(DMY2Date(Day, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3)));
    end;

    local procedure DeferralLineSetRange(var DeferralLine: Record "Deferral Line"; DocType: Enum "Sales Document Type"; DocNo: Code[20]; LineNo: Integer)
    begin
        DeferralLine.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
    end;

    local procedure ValidateDeferralSchedule(DocType: Enum "Sales Document Type"; DocNo: Code[20]; LineNo: Integer; DeferralTemplateCode: Code[10]; HeaderPostingDate: Date; HeaderAmountToDefer: Decimal; NoOfPeriods: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        Period: Integer;
        DeferralAmount: Decimal;
        PostingDate: Date;
    begin
        DeferralHeader.Get("Deferral Document Type"::Sales, '', '', DocType, DocNo, LineNo);
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date", HeaderPostingDate);
        DeferralHeader.TestField("Amount to Defer", HeaderAmountToDefer);
        DeferralHeader.TestField("No. of Periods", NoOfPeriods);

        DeferralLineSetRange(DeferralLine, DocType, DocNo, LineNo);
        Clear(DeferralAmount);
        Period := 0;
        if DeferralLine.FindSet() then
            repeat
                if Period = 0 then
                    PostingDate := HeaderPostingDate
                else
                    PostingDate := SetDateDay(1, HeaderPostingDate);
                PostingDate := PeriodDate(PostingDate, Period);
                DeferralLine.TestField("Posting Date", PostingDate);
                DeferralAmount := DeferralAmount + DeferralLine.Amount;
                Period := Period + 1;
            until DeferralLine.Next() = 0;
        DeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    local procedure ValidateDeferralScheduleDoesNotExist(DocType: Enum "Sales Document Type"; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        asserterror DeferralHeader.Get("Deferral Document Type"::Sales, '', '', DocType, DocNo, LineNo);

        DeferralLineSetRange(DeferralLine, DocType, DocNo, LineNo);
        asserterror DeferralLine.FindFirst();
    end;

    local procedure CopyDoc(SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; DocNo: Code[20]; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopySalesDoc: Report "Copy Sales Document";
    begin
        Clear(CopySalesDoc);
        CopySalesDoc.SetParameters(ConvertDocType(DocType), DocNo, IncludeHeader, RecalculateLines);
        CopySalesDoc.SetSalesHeader(SalesHeader);
        CopySalesDoc.UseRequestPage(false);
        CopySalesDoc.RunModal();
    end;

    local procedure ConvertDocType(DocType: Enum "Sales Document Type"): Enum "Sales Document Type From"
    var
        SalesHeader: Record "Sales Header";
    begin
        case DocType of
            SalesHeader."Document Type"::Quote:
                exit("Sales Document Type From"::Quote);
            SalesHeader."Document Type"::"Blanket Order":
                exit("Sales Document Type From"::"Blanket Order");
            SalesHeader."Document Type"::Order:
                exit("Sales Document Type From"::Order);
            SalesHeader."Document Type"::Invoice:
                exit("Sales Document Type From"::Invoice);
            SalesHeader."Document Type"::"Return Order":
                exit("Sales Document Type From"::"Return Order");
            SalesHeader."Document Type"::"Credit Memo":
                exit("Sales Document Type From"::"Credit Memo");
            else
                exit(DocType);
        end;
    end;

    local procedure PrepareSalesReceivableSetup(var StockWarningSetup: Boolean; var CreditWarningSetup: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        StockWarningSetup := false;
        SetupStockWarning(StockWarningSetup);

        CreditWarningSetup := SalesReceivablesSetup."Credit Warnings"::"No Warning";
        SetupCreditWarning(CreditWarningSetup);
    end;

    local procedure SetupStockWarning(var Option: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OrigianlOption: Boolean;
    begin
        SalesReceivablesSetup.Get();
        OrigianlOption := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", Option);
        SalesReceivablesSetup.Modify(true);
        Option := OrigianlOption;
    end;

    local procedure SetupCreditWarning(var Option: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OrigianlOption: Option;
    begin
        SalesReceivablesSetup.Get();
        OrigianlOption := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", Option);
        SalesReceivablesSetup.Modify(true);
        Option := OrigianlOption;
    end;

    local procedure UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(var GLAccountDeferral: Record "G/L Account"; DeferralCode: Code[10]; NewDescription: Text[100]; NewOmit: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(DeferralCode);
        DeferralTemplate.Validate("Period Description", NewDescription);
        DeferralTemplate.Modify(true);

        GLAccountDeferral.Get(DeferralTemplate."Deferral Account");
        GLAccountDeferral.Validate(Name, NewDescription);
        GLAccountDeferral.Validate("Omit Default Descr. in Jnl.", NewOmit);
        GLAccountDeferral.Modify(true);
    end;

    local procedure ValidateDeferralHeader(DeferralHeader: Record "Deferral Header"; DeferralCode: Code[10]; AmountToDefer: Decimal; CalcMethod: Enum "Deferral Calculation Method"; StartDate: Date; NoOfPeriods: Integer; ScheduleDesc: Text[100]; CurrencyCode: Code[10])
    begin
        DeferralHeader.TestField("Deferral Code", DeferralCode);
        DeferralHeader.TestField("Amount to Defer", AmountToDefer);
        DeferralHeader.TestField("Calc. Method", CalcMethod);
        DeferralHeader.TestField("Start Date", StartDate);
        DeferralHeader.TestField("No. of Periods", NoOfPeriods);
        DeferralHeader.TestField("Schedule Description", ScheduleDesc);
        DeferralHeader.TestField("Currency Code", CurrencyCode);
    end;

    local procedure ValidateDeferralLine(DeferralLine: Record "Deferral Line"; PostingDate: Date; Desc: Text[100]; Amt: Decimal; CurrencyCode: Code[10])
    begin
        DeferralLine.TestField("Posting Date", PostingDate);
        DeferralLine.TestField(Description, Desc);
        DeferralLine.TestField(Amount, Amt);
        DeferralLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyDeferralsAreEqual(SalesLineOrig: Record "Sales Line"; SalesLineDest: Record "Sales Line")
    var
        DeferralHeaderOrig: Record "Deferral Header";
        DeferralHeaderDest: Record "Deferral Header";
        DeferralLineOrig: Record "Deferral Line";
        DeferralLineDest: Record "Deferral Line";
    begin
        FindDeferralHeader(SalesLineOrig, DeferralHeaderOrig);
        FindDeferralHeader(SalesLineDest, DeferralHeaderDest);

        ValidateDeferralHeader(DeferralHeaderDest,
          DeferralHeaderOrig."Deferral Code",
          DeferralHeaderOrig."Amount to Defer",
          DeferralHeaderOrig."Calc. Method",
          DeferralHeaderOrig."Start Date",
          DeferralHeaderOrig."No. of Periods",
          DeferralHeaderOrig."Schedule Description",
          DeferralHeaderOrig."Currency Code");

        RangeDeferralLines(DeferralHeaderDest, DeferralLineDest);
        RangeDeferralLines(DeferralHeaderOrig, DeferralLineOrig);
        repeat
            ValidateDeferralLine(DeferralLineDest, DeferralLineOrig."Posting Date",
              DeferralLineOrig.Description, DeferralLineOrig.Amount, DeferralLineOrig."Currency Code");
            DeferralLineDest.Next();
        until DeferralLineOrig.Next() = 0;
    end;

    local procedure FindDeferralHeader(SalesLine: Record "Sales Line"; var DeferralHeader: Record "Deferral Header")
    begin
        DeferralHeader.Get("Deferral Document Type"::Sales, '', '',
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    local procedure RangeDeferralLines(DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line")
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralHeader."Deferral Doc. Type");
        DeferralLine.SetRange("Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Template Name");
        DeferralLine.SetRange("Gen. Jnl. Batch Name", DeferralHeader."Gen. Jnl. Batch Name");
        DeferralLine.SetRange("Document Type", DeferralHeader."Document Type");
        DeferralLine.SetRange("Document No.", DeferralHeader."Document No.");
        DeferralLine.SetRange("Line No.", DeferralHeader."Line No.");
        DeferralLine.Find('-');
    end;

    local procedure VerifyPostedDeferralsAreEqual(SalesInvLine: Record "Sales Invoice Line"; SalesLine: Record "Sales Line")
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        DeferralHeader: Record "Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralLine: Record "Deferral Line";
    begin
        FindPostedDeferralHeader(SalesInvLine, PostedDeferralHeader);
        FindDeferralHeader(SalesLine, DeferralHeader);

        ValidateDeferralHeader(DeferralHeader,
          PostedDeferralHeader."Deferral Code",
          PostedDeferralHeader."Amount to Defer",
          PostedDeferralHeader."Calc. Method",
          PostedDeferralHeader."Start Date",
          PostedDeferralHeader."No. of Periods",
          PostedDeferralHeader."Schedule Description",
          PostedDeferralHeader."Currency Code");

        RangeDeferralLines(DeferralHeader, DeferralLine);
        RangePostedDeferralLines(PostedDeferralHeader, PostedDeferralLine);
        repeat
            ValidateDeferralLine(DeferralLine, PostedDeferralLine."Posting Date", PostedDeferralLine.Description,
              PostedDeferralLine.Amount, PostedDeferralLine."Currency Code");
            DeferralLine.Next();
        until PostedDeferralLine.Next() = 0;
    end;

    local procedure FindPostedDeferralHeader(SalesInvLine: Record "Sales Invoice Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
        PostedDeferralHeader.Get("Deferral Document Type"::Sales, '', '',
          "Sales Document Type From"::"Posted Invoice", SalesInvLine."Document No.", SalesInvLine."Line No.");
    end;

    local procedure RangePostedDeferralLines(PostedDeferralHeader: Record "Posted Deferral Header"; var PostedDeferralLine: Record "Posted Deferral Line")
    begin
        PostedDeferralLine.SetRange("Deferral Doc. Type", PostedDeferralHeader."Deferral Doc. Type");
        PostedDeferralLine.SetRange("Gen. Jnl. Document No.", PostedDeferralHeader."Gen. Jnl. Document No.");
        PostedDeferralLine.SetRange("Account No.", PostedDeferralHeader."Account No.");
        PostedDeferralLine.SetRange("Document Type", PostedDeferralHeader."Document Type");
        PostedDeferralLine.SetRange("Document No.", PostedDeferralHeader."Document No.");
        PostedDeferralLine.SetRange("Line No.", PostedDeferralHeader."Line No.");
        PostedDeferralLine.Find('-');
    end;

    local procedure ModifyDeferral(SalesLine: Record "Sales Line"; CalcMethod: Enum "Deferral Calculation Method"; NoOfPeriods: Integer; DeferralAmount: Decimal; StartDate: Date)
    var
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralHeader.Get("Deferral Document Type"::Sales, '', '',
          SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        DeferralUtilities.SetDeferralRecords(DeferralHeader, "Deferral Document Type"::Sales.AsInteger(), '', '',
          SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          CalcMethod, NoOfPeriods, DeferralAmount, StartDate,
          DeferralHeader."Deferral Code", DeferralHeader."Schedule Description",
          SalesLine.GetDeferralAmount(), true, DeferralHeader."Currency Code");
        DeferralUtilities.CreateDeferralSchedule(DeferralHeader."Deferral Code", DeferralHeader."Deferral Doc. Type".AsInteger(),
          DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
          DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.",
          DeferralHeader."Amount to Defer", DeferralHeader."Calc. Method", DeferralHeader."Start Date",
          DeferralHeader."No. of Periods", false, DeferralHeader."Schedule Description", false, DeferralHeader."Currency Code");
    end;

    local procedure VerifyDeferralArchivesAreEqual(SalesLineArchive: Record "Sales Line Archive"; SalesLine: Record "Sales Line")
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralLineArchive: Record "Deferral Line Archive";
        DeferralLine: Record "Deferral Line";
    begin
        FindDeferralHeaderArchive(SalesLineArchive, DeferralHeaderArchive);
        FindDeferralHeader(SalesLine, DeferralHeader);

        ValidateDeferralHeader(DeferralHeader,
          DeferralHeaderArchive."Deferral Code",
          DeferralHeaderArchive."Amount to Defer",
          DeferralHeaderArchive."Calc. Method",
          DeferralHeaderArchive."Start Date",
          DeferralHeaderArchive."No. of Periods",
          DeferralHeaderArchive."Schedule Description",
          DeferralHeaderArchive."Currency Code");

        RangeDeferralLines(DeferralHeader, DeferralLine);
        RangeDeferralLineArchives(DeferralHeaderArchive, DeferralLineArchive);
        repeat
            ValidateDeferralLine(DeferralLine, DeferralLineArchive."Posting Date", DeferralLineArchive.Description,
              DeferralLineArchive.Amount, DeferralLineArchive."Currency Code");
            DeferralLine.Next();
        until DeferralLineArchive.Next() = 0;
    end;

    local procedure FindDeferralHeaderArchive(SalesLineArchive: Record "Sales Line Archive"; var DeferralHeaderArchive: Record "Deferral Header Archive")
    begin
        DeferralHeaderArchive.Get("Deferral Document Type"::Sales,
          SalesLineArchive."Document Type", SalesLineArchive."Document No.",
          SalesLineArchive."Doc. No. Occurrence", SalesLineArchive."Version No.", SalesLineArchive."Line No.");
    end;

    local procedure RangeDeferralLineArchives(DeferralHeaderArchive: Record "Deferral Header Archive"; var DeferralLineArchive: Record "Deferral Line Archive")
    begin
        DeferralLineArchive.SetRange("Deferral Doc. Type", DeferralHeaderArchive."Deferral Doc. Type");
        DeferralLineArchive.SetRange("Document Type", DeferralHeaderArchive."Document Type");
        DeferralLineArchive.SetRange("Document No.", DeferralHeaderArchive."Document No.");
        DeferralLineArchive.SetRange("Line No.", DeferralHeaderArchive."Line No.");
        DeferralLineArchive.SetRange("Doc. No. Occurrence", DeferralHeaderArchive."Doc. No. Occurrence");
        DeferralLineArchive.SetRange("Version No.", DeferralHeaderArchive."Version No.");
        DeferralLineArchive.Find('-');
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
    end;

    local procedure FindSalesLineArchive(SalesHeader: Record "Sales Header"; var SalesLineArchive: Record "Sales Line Archive")
    begin
        SalesLineArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeader."No.");
        SalesLineArchive.SetRange("Doc. No. Occurrence", 1);
        SalesLineArchive.SetRange("Version No.", 1);
        SalesLineArchive.Find('-');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    local procedure FindSalesOrderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", No);
        SalesHeaderArchive.FindFirst();
    end;

    local procedure FindSalesReturnOrderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeaderArchive.SetRange("No.", No);
        SalesHeaderArchive.FindFirst();
    end;

    local procedure ValidateDeferralArchiveScheduleDoesNotExist(DocType: Enum "Sales Document Type"; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
        DeferralLineArchive: Record "Deferral Line Archive";
    begin
        asserterror DeferralHeaderArchive.Get("Deferral Document Type"::Sales, '', '', DocType, DocNo, LineNo);

        DeferralLineArchive.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralLineArchive.SetRange("Document Type", DocType);
        DeferralLineArchive.SetRange("Document No.", DocNo);
        DeferralLineArchive.SetRange("Line No.", LineNo);
        asserterror DeferralLineArchive.FindFirst();
    end;

    local procedure ValidatePostedDeferralSchedule(DocType: Integer; DocNo: Code[20]; LineNo: Integer; DeferralTemplateCode: Code[10]; HeaderPostingDate: Date; HeaderAmountToDefer: Decimal; HeaderAmountToDeferLCY: Decimal; NoOfPeriods: Integer)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        Period: Integer;
        DeferralAmount: Decimal;
        PostingDate: Date;
    begin
        PostedDeferralHeader.Get("Deferral Document Type"::Sales, '', '', DocType, DocNo, LineNo);
        PostedDeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        PostedDeferralHeader.TestField("Start Date", HeaderPostingDate);
        PostedDeferralHeader.TestField("Amount to Defer", HeaderAmountToDefer);
        PostedDeferralHeader.TestField("Amount to Defer (LCY)", HeaderAmountToDeferLCY);
        PostedDeferralHeader.TestField("No. of Periods", NoOfPeriods);

        RangePostedDeferralLines(PostedDeferralHeader, PostedDeferralLine);
        Clear(DeferralAmount);
        Period := 0;
        if PostedDeferralLine.FindSet() then
            repeat
                if Period = 0 then
                    PostingDate := HeaderPostingDate
                else
                    PostingDate := SetDateDay(1, HeaderPostingDate);
                PostingDate := PeriodDate(PostingDate, Period);
                PostedDeferralLine.TestField("Posting Date", PostingDate);
                DeferralAmount := DeferralAmount + PostedDeferralLine.Amount;
                Period := Period + 1;
            until PostedDeferralLine.Next() = 0;
        PostedDeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    local procedure FindSalesInvoiceLine(var SalesInvLine: Record "Sales Invoice Line"; No: Code[20])
    begin
        SalesInvLine.SetRange("Document No.", No);
        SalesInvLine.FindFirst();
    end;

    local procedure FindSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; No: Code[20])
    begin
        SalesCrMemoLine.SetRange("Document No.", No);
        SalesCrMemoLine.FindFirst();
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocNo: Code[20]; AccNo: Code[20]; GenPostType: Enum "General Posting Type")
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostType);
    end;

    local procedure FilterInvoiceGLEntryGroups(var GLEntry: Record "G/L Entry"; GenPostingType: Enum "General Posting Type"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("VAT Bus. Posting Group", SalesInvoiceLine."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");
        GLEntry.SetRange("Gen. Bus. Posting Group", SalesInvoiceLine."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", SalesInvoiceLine."Gen. Prod. Posting Group");
    end;

    local procedure FilterCrMemoGLEntryGroups(var GLEntry: Record "G/L Entry"; GenPostingType: Enum "General Posting Type"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("VAT Bus. Posting Group", SalesCrMemoLine."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");
        GLEntry.SetRange("Gen. Bus. Posting Group", SalesCrMemoLine."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", SalesCrMemoLine."Gen. Prod. Posting Group");
    end;

    local procedure GetDeferralTemplateAccount(DeferralTemplateCode: Code[10]): Code[20]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(DeferralTemplateCode);
        exit(DeferralTemplate."Deferral Account");
    end;

    local procedure GetSalesAccountNo(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        exit(GeneralPostingSetup."Sales Account");
    end;

    local procedure GetSalesCrMemoAccountNo(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        exit(GeneralPostingSetup."Sales Credit Memo Account");
    end;

    local procedure GetGLEntryPairAmount(var GLEntry: Record "G/L Entry"; PartialDeferral: Boolean): Decimal
    begin
        if PartialDeferral then begin
            GLEntry.SetRange("VAT Amount", 0);
            Assert.RecordCount(GLEntry, 1);
        end;
        GLEntry.FindFirst();
        GLEntry.SetRange("VAT Amount");
        exit(GLEntry.Amount);
    end;

    local procedure GLCalcSum(DocNo: Code[20]; AccNo: Code[20]; StartPostDate: Date; EndPostDate: Date; var RecCount: Integer; var AccAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(AccAmt);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", StartPostDate, EndPostDate);
        RecCount := GLEntry.Count();
        if GLEntry.FindSet() then
            repeat
                AccAmt := AccAmt + GLEntry.Amount;
            until GLEntry.Next() = 0;
    end;

    local procedure PeriodDate(PostingDate: Date; Period: Integer): Date
    var
        Expr: Text[50];
    begin
        // Expr := '<' + FORMAT(Period) + 'M>';
        // EXIT(CALCDATE(Expr,PostingDate));
        Expr := Format(Period);
        exit(CalcDate('<' + Expr + 'M>', PostingDate));
    end;

    local procedure GLCalcSalesAmount(DocNo: Code[20]; AccNo: Code[20]; StartPostDate: Date; EndPostDate: Date; var RecCount: Integer; var AccAmt: Decimal; var SalesAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(AccAmt);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", StartPostDate, EndPostDate);
        RecCount := GLEntry.Count();
        if GLEntry.FindSet() then begin
            SalesAmt := GLEntry.Amount;
            repeat
                AccAmt := AccAmt + GLEntry.Amount;
            until GLEntry.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateReturnsDeferralStartDate(DocType: Enum "Sales Document Type"; DocNo: Code[20]; LineNo: Integer; RetDeferralStartDate: Date; var DeferralAmount: Decimal)
    var
        DeferralLine: Record "Deferral Line";
        Period: Integer;
        PostingDate: Date;
    begin
        Clear(DeferralAmount);
        DeferralLine.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
        Period := 0;
        if DeferralLine.FindSet() then
            repeat
                if Period = 0 then
                    PostingDate := RetDeferralStartDate
                else
                    PostingDate := SetDateDay(1, RetDeferralStartDate);
                PostingDate := PeriodDate(PostingDate, Period);
                DeferralLine.TestField("Posting Date", PostingDate);
                DeferralAmount := DeferralAmount + DeferralLine.Amount;
                Period := Period + 1;
            until DeferralLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetStartDate(DeferralStartOption: Enum "Deferral Calculation Start Date"; StartDate: Date) AdjustedStartDate: Date
    var
        AccountingPeriod: Record "Accounting Period";
        DeferralTemplate: Record "Deferral Template";
    begin
        case DeferralStartOption of
            DeferralTemplate."Start Date"::"Posting Date":
                AdjustedStartDate := StartDate;
            DeferralTemplate."Start Date"::"Beginning of Period":
                begin
                    AccountingPeriod.SetRange("Starting Date", 0D, StartDate);
                    if AccountingPeriod.FindLast() then
                        AdjustedStartDate := AccountingPeriod."Starting Date";
                end;
            DeferralTemplate."Start Date"::"End of Period":
                begin
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst() then
                        AdjustedStartDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");
                end;
            DeferralTemplate."Start Date"::"Beginning of Next Period":
                begin
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst() then
                        AdjustedStartDate := AccountingPeriod."Starting Date";
                end;
        end;
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateSalesDocWithCurrencyAndLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Currency Code", CreateCurrency());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, 2);
        case SalesLine.Type of
            SalesLine.Type::"G/L Account",
            SalesLine.Type::Resource:
                begin
                    SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
                    SalesLine.Modify(true);
                end;
        end;
    end;

    local procedure UpdateQtyToShipInvoiceOnSalesLine(var SalesLine: Record "Sales Line"; Quantity: Decimal; QuantityToShip: Decimal; QuantityToInvoice: Decimal)
    begin
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Validate("Qty. to Ship", QuantityToShip);
        SalesLine.Validate("Qty. to Invoice", QuantityToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure GetInvoiceQtyAmtToDefer(var SalesLine: Record "Sales Line"; DeferralAmount: Decimal; CurrencyCode: Code[20]): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Amount Rounding Precision");
        end;
        exit(Round(DeferralAmount *
            SalesLine."Qty. to Invoice" / SalesLine.Quantity, Currency."Amount Rounding Precision"));
    end;

    local procedure RunBatchPostReport(var NewPostingDate: Date; PostingDate: Date; ConfirmValue: Boolean; DocNo1: Code[20]; DocNo2: Code[20]; ReportID: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        NewPostingDate := CalcDate('<+1M>', PostingDate);
        SetupBatchPostingReportParameters(NewPostingDate, ConfirmValue);
        Commit();
        SalesHeader.SetFilter("No.", '%1|%2', DocNo1, DocNo2);
        REPORT.Run(ReportID, true, false, SalesHeader);
    end;

    local procedure SetupBatchPostingReportParameters(PostingDate: Date; ConfirmValue: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(0); // confirm counter
        LibraryVariableStorage.Enqueue(ConfirmValue);
    end;

    local procedure VerifyPostedInvoiceDeferralsAndGL(DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; AmtToDefer: Decimal; AmtToDeferLCY: Decimal; NoOfPeriods: Integer; GLRecordCount: Integer; PostingDate: Date; PartialDeferral: Boolean)
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        // The deferrals were moved to the Posted Invoice Line and Posted Deferral tables
        FindSalesInvoiceLine(SalesInvLine, DocNo);
        SalesInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(SalesDocType::"Posted Invoice", DocNo,
          SalesInvLine."Line No.", DeferralTemplateCode, PostingDate, AmtToDefer, AmtToDeferLCY, NoOfPeriods);

        // The correct deferrals were posted to GL
        VerifyGLForInvoice(DocNo, AccNo, PostingDate, PeriodDate(PostingDate, NoOfPeriods), GLRecordCount, 0, PartialDeferral);
    end;

    local procedure VerifyPostedInvoiceDeferralsAndGLWithSalesAmt(DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; SalesAccount: Code[20]; AmtToDefer: Decimal; AmtToDeferLCY: Decimal; Day: Integer; NoOfPeriods: Integer; GLRecordCount: Integer; SalesRecordCount: Integer; SalesAmount: Decimal)
    var
        SalesInvLine: Record "Sales Invoice Line";
        GLSalesAmount: Decimal;
        GLSum: Decimal;
        GLCount: Integer;
    begin
        // The deferrals were moved to the Sales Invoice Line and Posted Deferral tables
        FindSalesInvoiceLine(SalesInvLine, DocNo);
        SalesInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(SalesDocType::"Posted Invoice", DocNo,
          SalesInvLine."Line No.", DeferralTemplateCode, SetDateDay(Day, WorkDate()), AmtToDefer, AmtToDeferLCY, NoOfPeriods);

        // The amount not deferred was posted to GL for the sales account
        GLCalcSalesAmount(DocNo, SalesAccount,
          SetDateDay(Day, WorkDate()), PeriodDate(SetDateDay(Day, WorkDate()), NoOfPeriods), GLCount, GLSum, GLSalesAmount);
        Assert.AreEqual(SalesRecordCount, GLCount, 'An incorrect number of lines was posted');
        Assert.AreEqual(SalesAmount, Abs(GLSalesAmount), 'An incorrect Amount was posted for sales');

        // The deferrals account was updated
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(Day, WorkDate()), PeriodDate(SetDateDay(Day, WorkDate()), NoOfPeriods), GLRecordCount, 0, true);
    end;

    local procedure VerifyDeferralHeaderLinesRemoved(DocType: Option; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        asserterror DeferralHeader.Get("Deferral Document Type"::Sales, '', '', DocType, DocNo, LineNo);
        asserterror LibraryERM.FindDeferralLine(DeferralLine, "Deferral Document Type"::Sales, '', '', DocType, DocNo, LineNo);
    end;

    local procedure VerifyPostedCrMemosDeferralsAndGL(DocType: Option; DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; AmtToDefer: Decimal; AmtToDeferLCY: Decimal; NoOfPeriods: Integer; GLRecordCount: Integer; PostingDate: Date)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // The deferrals were moved to the Posted Credit Memo Line and Posted Deferral tables
        FindSalesCrMemoLine(SalesCrMemoLine, DocNo);
        SalesCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(
          DocType, DocNo,
          SalesCrMemoLine."Line No.", DeferralTemplateCode, PostingDate, AmtToDefer, AmtToDeferLCY, NoOfPeriods);

        // The correct deferrals were posted to GL
        VerifyGLForCrMemo(DocNo, AccNo, PostingDate, PeriodDate(PostingDate, NoOfPeriods), GLRecordCount, 0, false);
    end;

    local procedure VerifyInvoicePostingDate(DocNo: Code[20]; PostingDate: Date)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyCrMemoPostingDate(DocNo: Code[20]; PostingDate: Date)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(DocNo);
        SalesCrMemoHeader.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifySalesGLDeferralAccount(SalesLine: Record "Sales Line"; PostedDocNo: Code[20]; SalesAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(
          GLEntry,
          PostedDocNo,
          GetSalesAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          GLEntry."Gen. Posting Type"::Sale);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, SalesAmt);
    end;

    local procedure VerifyGLForDeferralPeriod(DocNo: Code[20]; AccNo: Code[20])
    var
        TempPostedDeferralLine: Record "Posted Deferral Line" temporary;
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, DocNo, AccNo, GLEntry."Gen. Posting Type"::" ");
        LibraryERM.GetCombinedPostedDeferralLines(TempPostedDeferralLine, DocNo);
        TempPostedDeferralLine.FindSet();
        repeat
            GLEntry.SetFilter(Amount, '>%1', 0);
            GLEntry.SetRange("Posting Date", TempPostedDeferralLine."Posting Date");
            GLEntry.FindFirst();
            GLEntry.TestField(Amount, TempPostedDeferralLine.Amount);
        until TempPostedDeferralLine.Next() = 0;
    end;

    local procedure VerifyGLForInvoice(DocNo: Code[20]; AccNo: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; DeferralSum: Decimal; PartialDeferral: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        GLSum: Decimal;
        GLCount: Integer;
    begin
        GLCalcSum(DocNo, AccNo, PostingDate, PeriodDate, GLCount, GLSum);
        ValidateAccounts(DeferralCount, DeferralSum, GLCount, GLSum);
        FindSalesInvoiceLine(SalesInvoiceLine, DocNo);
        VerifyInvoiceVATGLEntryForPostingAccount(SalesInvoiceLine, PartialDeferral);
    end;

    local procedure VerifyGLForCrMemo(DocNo: Code[20]; AccNo: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; DeferralSum: Decimal; PartialDeferral: Boolean)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GLSum: Decimal;
        GLCount: Integer;
    begin
        GLCalcSum(DocNo, AccNo, PostingDate, PeriodDate, GLCount, GLSum);
        ValidateAccounts(DeferralCount, DeferralSum, GLCount, GLSum);
        FindSalesCrMemoLine(SalesCrMemoLine, DocNo);
        VerifyCrMemoVATGLEntryForPostingAccount(SalesCrMemoLine, PartialDeferral);
    end;

    local procedure ValidateAccounts(DeferralCount: Integer; DeferralAmount: Decimal; GLCount: Integer; GLAmt: Decimal)
    begin
        Assert.AreEqual(DeferralCount, GLCount, 'An incorrect number of lines was posted');
        Assert.AreEqual(DeferralAmount, GLAmt, 'An incorrect Amount was posted for purchase');
    end;

    local procedure VerifyGLEntriesExistWithBlankDescription(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetFilter(Description, '=%1', '');
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyGLEntriesDoNotExistWithBlankDescription(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetFilter(Description, '=%1', '');
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyInvoiceVATGLEntryForPostingAccount(SalesInvoiceLine: Record "Sales Invoice Line"; PartialDeferral: Boolean)
    var
        GLEntry: Record "G/L Entry";
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        PairAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
        GLEntry.SetRange(
          "G/L Account No.",
          GetSalesAccountNo(SalesInvoiceLine."Gen. Bus. Posting Group", SalesInvoiceLine."Gen. Prod. Posting Group"));

        GLEntry.SetFilter("VAT Amount", '<>%1', 0);
        FilterInvoiceGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::Sale, SalesInvoiceLine);
        Assert.RecordCount(GLEntry, 1);
        // Verify paired GLEntry
        PairAmount := GetGLEntryPairAmount(GLEntry, PartialDeferral);
        GLEntry.SetFilter(Amount, '>%1', 0);
        FilterInvoiceGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::" ", DummySalesInvoiceLine);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PairAmount);
    end;

    local procedure VerifyCrMemoVATGLEntryForPostingAccount(SalesCrMemoLine: Record "Sales Cr.Memo Line"; PartialDeferral: Boolean)
    var
        GLEntry: Record "G/L Entry";
        DummySalesCrMemoLine: Record "Sales Cr.Memo Line";
        PairAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
        GLEntry.SetRange(
          "G/L Account No.",
          GetSalesCrMemoAccountNo(SalesCrMemoLine."Gen. Bus. Posting Group", SalesCrMemoLine."Gen. Prod. Posting Group"));

        GLEntry.SetFilter("VAT Amount", '<>%1', 0);
        FilterCrMemoGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::Sale, SalesCrMemoLine);
        Assert.RecordCount(GLEntry, 1);
        // Verify paired GLEntry
        PairAmount := GetGLEntryPairAmount(GLEntry, PartialDeferral);
        GLEntry.SetFilter(Amount, '<%1', 0);
        FilterCrMemoGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::" ", DummySalesCrMemoLine);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PairAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        // Modal Page Handler.
        LibraryVariableStorage.AssertEmpty();
        LibraryVariableStorage.Enqueue(DeferralSchedule."Amount to Defer".AsDEcimal());
        LibraryVariableStorage.Enqueue(DeferralSchedule.PostingDate.AsDate());
        LibraryVariableStorage.Enqueue(DeferralSchedule.StartDateCalcMethod.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateDeferralSchedulePeriodHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        // Modal Page Handler.
        DeferralSchedule."No. of Periods".SetValue(LibraryVariableStorage.DequeueInteger());
        DeferralSchedule.CalculateSchedule.Invoke();
        DeferralSchedule.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateAmountToDeferOnDeferralScheduleModalPageHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        DeferralSchedule."Amount to Defer".SetValue(LibraryVariableStorage.DequeueDecimal());
        DeferralSchedule.CalculateSchedule.Invoke();
        DeferralSchedule.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleViewHandler(var DeferralScheduleView: TestPage "Deferral Schedule View")
    begin
        // Modal Page Handler.
        DeferralScheduleView.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleArchiveHandler(var DeferralScheduleArchive: TestPage "Deferral Schedule Archive")
    begin
        // Modal Page Handler.
        DeferralScheduleArchive.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesInvoicesRequestPageHandler(var BatchPostSalesInvoices: TestRequestPage "Batch Post Sales Invoices")
    begin
        BatchPostSalesInvoices.ReplacePostingDate.SetValue(true);
        BatchPostSalesInvoices.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        BatchPostSalesInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesOrdersRequestPageHandler(var BatchPostSalesOrders: TestRequestPage "Batch Post Sales Orders")
    begin
        BatchPostSalesOrders.Ship.SetValue(true);
        BatchPostSalesOrders.Invoice.SetValue(true);
        BatchPostSalesOrders.ReplacePostingDate.SetValue(true);
        BatchPostSalesOrders.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        BatchPostSalesOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostSalesCreditMemosRequestPageHandler(var BatchPostSalesCreditMemos: TestRequestPage "Batch Post Sales Credit Memos")
    begin
        BatchPostSalesCreditMemos.ReplacePostingDate.SetValue(true);
        BatchPostSalesCreditMemos.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        BatchPostSalesCreditMemos.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(DeferralLineQst, Question);
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1); // count of handler call's
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

