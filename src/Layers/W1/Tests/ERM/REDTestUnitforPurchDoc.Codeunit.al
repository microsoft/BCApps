codeunit 134804 "RED Test Unit for Purch Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Revenue Expense Deferral] [Purchase]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryResource: Codeunit "Library - Resource";
        CalcMethod: Enum "Deferral Calculation Method";
        StartDate: Enum "Deferral Calculation Start Date";
        PurchDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Shipment,"Posted Invoice","Posted Credit Memo","Posted Return Receipt";
        isInitialized: Boolean;
        GLAccountOmitErr: Label 'When %1 is selected for';
        NoDeferralScheduleErr: Label 'You must create a deferral schedule because you have specified the deferral code %2 in line %1.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ZeroDeferralAmtErr: Label 'Deferral amounts cannot be 0. Line: %1, Deferral Template: %2.', Comment = '%1=The item number of the sales transaction line, %2=The Deferral Template Code';
        ConfirmCallOnceErr: Label 'Confirm should be called once.';
        DeferralLineQst: Label 'do you want to update the deferral schedules for the lines with this date?';

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderWithItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127770] Annie can apply a deferral template to a Purchse Order
        // [GIVEN] User has assigned a default deferral code to an Item
        Initialize();
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
          DeferralTemplateCode, PurchaseHeader."Posting Date", PurchaseLine.GetDeferralAmount(), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceWithGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127770] Annie can apply a deferral template to a Purchase Invoice
        Initialize();
        // [GIVEN] User has created a deferral template
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] User has assigned a default deferral code to a GL Account
        CreateGLAccount(GLAccount);
        GLAccount.Validate("Default Deferral Template Code", DeferralTemplateCode);
        GLAccount.Modify();

        // [WHEN] Creating Purchase Line for GL Account should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
          DeferralTemplateCode, PurchaseHeader."Posting Date", PurchaseLine.GetDeferralAmount(), 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoWithGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127773] Annie can apply a deferral template to a Purchase Credit Memo
        Initialize();
        // [GIVEN] User has created a deferral template
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Equal per Period", StartDate::"Posting Date", 3);

        // [GIVEN] User has assigned a default deferral code to a GL Account
        CreateGLAccount(GLAccount);
        GLAccount.Validate("Default Deferral Template Code", DeferralTemplateCode);
        GLAccount.Modify();

        // [WHEN] Creating Purchase Line for GL Account should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
          DeferralTemplateCode, PurchaseHeader."Posting Date", PurchaseLine.GetDeferralAmount(), 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseReturnOrderWithItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DeferralAmount: Decimal;
    begin
        // [FEATURE] [Deferral Code] [Returns Deferral Start Date]
        // [SCENARIO 127773] Annie can apply a deferral template to a Purchase Return
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Days per Period", StartDate::"Beginning of Period", 4);

        // [WHEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, ItemNo, SetDateDay(10, WorkDate()));

        // [THEN] The Deferral Code was assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '',
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date",
          GetStartDate(StartDate::"Beginning of Period", PurchaseHeader."Posting Date"));
        DeferralHeader.TestField("Amount to Defer", PurchaseLine.GetDeferralAmount());
        DeferralHeader.TestField("No. of Periods", 4);

        // [THEN] Returns Deferral Start Date is set correctly
        ValidateReturnsDeferralStartDate(PurchaseLine."Document Type",
          PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine."Returns Deferral Start Date", DeferralAmount);

        DeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseReturnOrderWithItemReturnStartDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DeferralAmount: Decimal;
    begin
        // [FEATURE] [Deferral Code] [Returns Deferral Start Date]
        // [SCENARIO 127773] Annie can apply a deferral template and update the Purchase Line to use a separate deferral start date
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Days per Period", StartDate::"End of Period", 4);

        // [WHEN] Creating Purchase Line for Item should default deferral code and update the Purchase Line Return Deferral Start Date
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, ItemNo, SetDateDay(10, WorkDate()));
        PurchaseLine.Validate("Returns Deferral Start Date", SetDateDay(15, WorkDate()));
        PurchaseLine.Modify();

        // [THEN] The Deferral Code was assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The deferral schedule was created using the Purchase Line Return Deferral Start Date
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '',
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date", PurchaseLine."Returns Deferral Start Date");
        DeferralHeader.TestField("Amount to Defer", PurchaseLine.GetDeferralAmount());
        DeferralHeader.TestField("No. of Periods", 4);

        // [THEN] Returns Deferral Start Date is set correctly
        ValidateReturnsDeferralStartDate(PurchaseLine."Document Type",
          PurchaseLine."Document No.", PurchaseLine."Line No.", PurchaseLine."Returns Deferral Start Date", DeferralAmount);

        DeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseQuoteWithItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127770] Deferral template does not default on Purchase Quote
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Creating Purchase Line for Item on a Quote, the deferral code should not default
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Quote, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was not assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was not created
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseBlanketOrderWithItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127770] Deferral template does not default on Purchase Blanket Order
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [WHEN] Creating Purchase Line for Item on a Quote, the deferral code should not default
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Blanket Order", PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [THEN] The Deferral Code was not assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was not created
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderDeferralSchedule()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 379200] Amount in Deferral Schedule should match days in period when Calc. Method "Days per Period" is used
        Initialize();
        // [GIVEN] Deferral Template with Calc. Method "Days per Period"
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Days per Period", StartDate::"Posting Date", 4);

        // [WHEN] Create Purchase Line with deferral code
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo,
          CalcDate('<-CM>', WorkDate()) + LibraryRandom.RandInt(10));

        // [THEN] Amount in Deferral Line per each period corresponds to days' count in period
        VerifyDeferralScheduleAmounts(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingPurchaseLineType()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Document Type]
        // [SCENARIO 127770] Changing the Purchase Line Type removes the deferral code
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateGLAccountWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Purchase Line for GL Account defaults deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::"G/L Account", AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Changing the Purchase Line Type
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Modify(true);

        // [THEN] The Deferral Code was removed from the Purchase Line
        PurchaseLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingPurchaseLineNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [No.]
        // [SCENARIO 127770] Changing Purchase Line No. to an Item that does not have a default deferral code removes deferral schedule
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Purchase Line for Item defaults deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Changing the Purchase Line No. to an Item that does not have a default deferral code
        Clear(Item);
        CreateItem(Item);
        Item.Validate("Unit Price", 500.0);
        Item.Modify(true);

        PurchaseLine.Validate("No.", Item."No.");
        PurchaseLine.Modify(true);

        // [THEN] The Deferral Code was removed from the Purchase Line
        PurchaseLine.TestField("Deferral Code", '');

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestClearingPurchaseLineDeferralCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Deferral Code]
        // [SCENARIO 127770] Clearing the Deferral Code on a line removes the deferral schedule
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateGLAccountWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for GL Account defaults deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::"G/L Account", AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Clearing the deferral code from the Purchase Line
        PurchaseLine.Validate("Deferral Code", '');

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
    begin
        // [FEATURE] [Delete Line]
        // [SCENARIO 127770] Deleting a Purchase Line removes the deferral schedule
        Initialize();
        // [GIVEN] User has created a GL Account and assigned a default deferral code to it
        CreateGLAccountWithDefaultDeferralCode(DeferralTemplateCode, AccNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Purchase Line for GL Account defaults deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::"G/L Account", AccNo, SetDateDay(1, WorkDate()));

        // [WHEN] Delete the Purchase Line
        PurchaseLine.Delete(true);

        // [THEN] The deferral schedule was removed
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyOrderWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127770] Annie can copy a document and the deferrals are copied
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        Initialize();

        // [GIVEN] Creating Purchase Line for Item should default deferral code - then modify the amounts
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Find('-');
        ModifyDeferral(PurchaseLine, DeferralHeader."Calc. Method"::"Equal per Period", 3,
          PurchaseLine.GetDeferralAmount() * 0.8, SetDateDay(15, WorkDate()));

        // [WHEN] Create New purchase invoice document and copy the existing one with recalculate unmarked
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::Invoice, SetDateDay(1, WorkDate()), PurchaseHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);

        // [THEN] The deferral schedule was copied from the existing line
        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        PurchaseLineDest.TestField("Deferral Code", DeferralTemplateCode);
        PurchaseLineDest.TestField("Returns Deferral Start Date", 0D);
        VerifyDeferralsAreEqual(PurchaseLine, PurchaseLineDest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedInvoiceWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127770] Annie can copy a posted document and the deferrals are copied
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        Initialize();

        // [GIVEN] Create and post the purchase invoice with the default deferral
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocNo);

        // [WHEN] Create New purchase order document and copy the existing one
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::Order, SetDateDay(1, WorkDate()), PurchInvHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, "Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);

        // [THEN] The deferral schedule was copied from the existing line
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();

        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        if PurchaseLineDest."No." = '' then
            PurchaseLineDest.Next();
        PurchaseLineDest.TestField("Deferral Code", DeferralTemplateCode);
        PurchaseLineDest.TestField("Returns Deferral Start Date", 0D);
        VerifyPostedDeferralsAreEqual(PurchInvLine, PurchaseLineDest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedInvoiceWithDeferralToReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Returns Deferral Start Date]
        // [SCENARIO 127770] Annie can copy a posted invoice to a return order
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo,
          CalcMethod::"Straight-Line", StartDate::"Beginning of Next Period", 2);
        Initialize();

        // [GIVEN] Create and post the purchase invoice with the default deferral
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocNo);

        // [WHEN] Create New purchase order document and copy the existing one
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::"Return Order", SetDateDay(1, WorkDate()), PurchInvHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, "Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);

        // [THEN] The deferral schedule was copied from the existing line
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();

        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        if PurchaseLineDest."No." = '' then
            PurchaseLineDest.Next();
        PurchaseLineDest.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The Returns Deferral Start Date was assigned a start date based on header posting date
        PurchaseLineDest.TestField("Returns Deferral Start Date",
          GetStartDate(StartDate::"Beginning of Next Period", PurchaseHeader."Posting Date"));

        VerifyPostedDeferralsAreEqual(PurchInvLine, PurchaseLineDest);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyOrderWithDeferralToQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127770] Copy an order with deferrals to a quote does not default the deferrals on a quote
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        Initialize();

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [WHEN] Create New quote document and copy the existing one
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::Quote, SetDateDay(1, WorkDate()), PurchaseHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);

        // [THEN] The Deferral Code was not assigned to the Quote Purchase Line
        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        PurchaseLineDest.TestField("Deferral Code", '');
        PurchaseLineDest.TestField("Returns Deferral Start Date", 0D);

        // [THEN] The deferral schedule was not created
        ValidateDeferralScheduleDoesNotExist(
          PurchaseLineDest."Document Type", PurchaseLineDest."Document No.", PurchaseLineDest."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyQuoteToOrderDefaultsDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 127770] Annie can copy a Quote to a different type and the deferrals are defaulted from the item
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        Initialize();

        // [GIVEN] Creating Purchase Line for Item on Quote does not default the deferral
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Quote, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [WHEN] Create New purchase Order and copy the existing Quote
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::Order, SetDateDay(1, WorkDate()), PurchaseHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, PurchaseHeader."Document Type", PurchaseHeader."No.", true, false);

        // [THEN] The Deferral Code was assigned to the Order Purchase Line
        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        PurchaseLineDest.TestField("Deferral Code", DeferralTemplateCode);
        PurchaseLineDest.TestField("Returns Deferral Start Date", 0D);

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          PurchaseLineDest."Document Type", PurchaseLineDest."Document No.", PurchaseLineDest."Line No.",
          DeferralTemplateCode, PurchaseHeaderDest."Posting Date", PurchaseLineDest.GetDeferralAmount(), 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyOrderWithDeferralToReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document] [Returns Deferral Start Date]
        // [SCENARIO 127732] Copy an order with deferrals to a Return Order
        // defaults the Returns Deferral Start Date from the Return Order
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"End of Period", 3);
        Initialize();

        // [GIVEN] Creating Purchase Line for Item should default deferral code - order uses day = 1
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [WHEN] Create New purchase document and copy the existing one - Return uses day = 15
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::"Return Order", SetDateDay(15, WorkDate()), PurchaseHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, PurchaseHeader."Document Type", PurchaseHeader."No.", false, false);

        // [THEN] The Deferral Code was assigned to the Return Order purchase line
        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        PurchaseLineDest.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The Returns Deferral Start Date was assigned a start date based on header posting date
        PurchaseLineDest.TestField("Returns Deferral Start Date",
          GetStartDate(StartDate::"End of Period", PurchaseHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyReturnOrderWithDeferralToReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeaderDest: Record "Purchase Header";
        PurchaseLineDest: Record "Purchase Line";
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

        // [GIVEN] Creating Purchase Line for Item should default deferral code - order uses day = 1
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // [WHEN] Create New purchase document and copy the existing one - Return uses day = 15
        CreatePurchHeaderForVendor(PurchaseHeaderDest,
          PurchaseHeaderDest."Document Type"::"Return Order", SetDateDay(15, WorkDate()), PurchaseHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeaderDest, PurchaseHeader."Document Type", PurchaseHeader."No.", false, false);

        // [THEN] The Deferral Code was assigned to the Return Order purchase line
        FindPurchLine(PurchaseHeaderDest, PurchaseLineDest);
        PurchaseLineDest.TestField("Deferral Code", DeferralTemplateCode);

        // [THEN] The Returns Deferral Start Date was assigned from the date on the original return order line
        PurchaseLineDest.TestField("Returns Deferral Start Date", PurchaseLine."Returns Deferral Start Date");
        PurchaseLineDest.TestField("Returns Deferral Start Date",
          GetStartDate(StartDate::"Beginning of Next Period", PurchaseHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestArchiveOrderWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineArchive: Record "Purchase Line Archive";
        DeferralHeader: Record "Deferral Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Archive Document]
        // [SCENARIO 127770] When a purchase Order is archived, the deferrals are archived along with it
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        ModifyDeferral(PurchaseLine, DeferralHeader."Calc. Method"::"Days per Period", 4,
          PurchaseLine.GetDeferralAmount() * 0.7, SetDateDay(12, WorkDate()));

        // [WHEN] Document is archive
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        FindPurchLine(PurchaseHeader, PurchaseLine);
        FindPurchLineArchive(PurchaseHeader, PurchLineArchive);

        // [THEN] The deferrals were moved to the archive
        VerifyDeferralArchivesAreEqual(PurchLineArchive, PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteArchiveOrderWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchLineArchive: Record "Purchase Line Archive";
        DeferralHeader: Record "Deferral Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Delete Archive]
        // [SCENARIO 127770] Deletion of Purchase Order Archive should lead to deletion of archived deferral schedule
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        ModifyDeferral(PurchaseLine, DeferralHeader."Calc. Method"::"Days per Period", 4,
          PurchaseLine.GetDeferralAmount() * 0.7, SetDateDay(12, WorkDate()));

        // [GIVEN] Document is archived
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        FindPurchLineArchive(PurchaseHeader, PurchLineArchive);
        DocNo := PurchLineArchive."Document No.";
        LineNo := PurchLineArchive."Line No.";

        // [GIVEN] Remove the purch Doc
        DeletePurchDoc(PurchaseHeader);

        // [WHEN] Remove the archives
        PurchLineArchive.Delete(true);

        // [THEN] the archived deferral schedule was deleted
        ValidateDeferralArchiveScheduleDoesNotExist(PurchaseHeader."Document Type"::Order, DocNo, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostOrderWithDeferral()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document] [Orders]
        // [SCENARIO 159878] When a Order is Received & Invoiced, G/L entries post to deferral account
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Purchase Order Line for Item
        CreatePurchDocWithLine(PurchHeader, PurchLine,
          PurchHeader."Document Type"::Order, PurchLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := PurchLine.GetDeferralAmount();
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [WHEN] Invoice the Purchase Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Deferral code is in Purchase Invoice Line
        // [THEN] Posted Deferral header and Line tables created
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 1, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithDeferral()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial Order is Received-Invoiced, G/L entries post to deferral account for partial amts only
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN]  Create PO Line for Item with partial qtys Received/Invoiced
        CreatePurchDocWithLine(PurchHeader, PurchLine,
          PurchHeader."Document Type"::Order, PurchLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 5, 2, 1);
        AmtToDefer := GetInvoiceQtyAmtToDefer(PurchLine, PurchLine.GetDeferralAmount(), PurchHeader."Currency Code");

        // [WHEN] Invoice the partial Purchase Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Posted Deferral header and Line tables are for the partial quantities
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 1, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithCurrencyAndDeferral()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CurrExchRate: Record "Currency Exchange Rate";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        AmtToDeferLCY: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial order with currency posts, G/L entries post to deferral account
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create PO Line for Item with partial qtys Received/Invoiced with currency amounts
        CreatePurchDocWithCurrencyAndLine(PurchHeader, PurchLine,
          PurchHeader."Document Type"::Order, PurchLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 6, 3, 2);
        AmtToDefer := GetInvoiceQtyAmtToDefer(PurchLine, PurchLine.GetDeferralAmount(), PurchHeader."Currency Code");
        AmtToDeferLCY :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(SetDateDay(1, WorkDate()),
              PurchHeader."Currency Code", AmtToDefer, PurchHeader."Currency Factor"));
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Posted Deferral header and Line tables are for the partial quantities and appropriate currency
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDeferLCY, 1, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderTwoLinesWithDeferral()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document] [Partial Orders]
        // [SCENARIO 159878] When partial PO is posted with multiple lines same type, G/L entries deferral account are combined
        Initialize();
        // [GIVEN] User has assigned a default deferral code to two differnt Items
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        CreateItemWithUnitPrice(Item);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        Item.Validate("Default Deferral Template Code", DeferralTemplateCode);
        Item.Modify(true);
        ItemNo := Item."No.";

        // [GIVEN] Create Purchase Line for Item with partial Received/Invoiced qtys
        CreatePurchDocWithLine(PurchHeader, PurchLine,
          PurchHeader."Document Type"::Order, PurchLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 5, 3, 2);

        // [GIVEN] Add the second item to the document that also has partial qtys
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, 2);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 4, 2, 1);

        // [WHEN] Invoice the partial PO
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/L Entries are combined for the deferral account from both lines
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithPartialDeferral()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DeferralHeader: Record "Deferral Header";
        PurchAccount: Code[20];
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
        PurchAmount: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Orders]
        // [SCENARIO 159878] When an Order is posted with a partial deferral, the purchase accounts is reduced by the deferral and balance posted to first period
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create PO line with deferral for 70%
        CreatePurchDocWithLine(PurchHeader, PurchLine,
          PurchHeader."Document Type"::Order, PurchLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 5, 1, 1);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        AmtToDefer := Round(PurchLine.GetDeferralAmount() * 0.7);
        ModifyDeferral(PurchLine, DeferralHeader."Calc. Method"::"Straight-Line", 2,
          AmtToDefer, SetDateDay(1, WorkDate()));
        AmtToDefer := GetInvoiceQtyAmtToDefer(PurchLine, AmtToDefer, PurchHeader."Currency Code");
        PurchAmount := GetInvoiceQtyAmtToDefer(PurchLine, PurchLine.GetDeferralAmount(), PurchHeader."Currency Code") - AmtToDefer;
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        PurchAccount := GenPostingSetup."Purch. Account";

        // [WHEN] Invoice the partial order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/L Entries for purch account is reduced by amt deferred which is posted directly to deferral account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGLWithPurchAmt(DocNo,
          DeferralTemplateCode, AccNo, PurchAccount, AmtToDefer, AmtToDefer, 1, 2, 3, 5, PurchAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPartialOrderWithDeferralMultipleTimes()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        AccNo: Code[20];
        ItemNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document] [Partial Invoice]
        // [SCENARIO 159878] When partial Order is Received-Invoiced multiple times, G/L entries post to deferral account
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Purchase Line woth partial quantites
        CreatePurchDocWithLine(PurchHeader, PurchLine,
          PurchHeader."Document Type"::Order, PurchLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 5, 1, 1);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);
        AmtToDefer := GetInvoiceQtyAmtToDefer(PurchLine, PurchLine.GetDeferralAmount(), PurchHeader."Currency Code");

        // [WHEN] Invoice the partial order the first time
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] The Order Qty to Invoice is updated again
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify();
        FindPurchLine(PurchHeader, PurchLine);
        UpdateQtyToReceiveInvoiceOnPurchLine(PurchLine, 5, 2, 2);
        AmtToDefer := GetInvoiceQtyAmtToDefer(PurchLine, PurchLine.GetDeferralAmount(), PurchHeader."Currency Code");

        // [WHEN] Invoice the partial order the second time
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Posted Deferral header and Line tables are for the partial quantities from second order
        // [THEN] G/L Entries are posted to Deferral Account
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyPostedInvoiceDeferralsAndGL(DocNo, DeferralTemplateCode, AccNo, AmtToDefer, AmtToDefer, 1, 2, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document]
        Initialize();
        // [SCENARIO 127772] When a Purchase Invoice is posted, the general ledger accounts for the deferrals are created
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := PurchaseLine.GetDeferralAmount();

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Invoice Line and Posted Deferral tables
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        PurchInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, SetDateDay(1, WorkDate()), AmtToDefer, AmtToDefer, 2);

        // [THEN] The deferrals were posted to GL for 3 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, false);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoInvoicesWithDeferralConfirmYes()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Purchase Invoices with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(false);

        // [GIVEN] Two Purchase Invoices with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::Invoice);

        // [WHEN] Purchase Invoices are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", true,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purchase Invoices");

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyInvoicePostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer1);
        VerifyInvoicePostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer2);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoInvoicesWithDeferralConfirmYesBackground()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting (background) of Deferral Purchase Invoices with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Purchase Invoices with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::Invoice);

        // [WHEN] Purchase Invoices are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", true,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purchase Invoices");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyInvoicePostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer1);
        VerifyInvoicePostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer2);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseOrdersReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoOrdersWithDeferralConfirmYes()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Purchase Orders with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Purchase Orders with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::Order);

        // [WHEN] Purchase Orders are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", true,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purchase Orders");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyInvoicePostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer1);
        VerifyInvoicePostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer2);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchCreditMemosReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoCrMemosWithDeferralConfirmYes()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Purchase Credit Memos with updated Posting Date should update deferral schedule with Confirm Yes
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Purchase Credit Memos with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::"Credit Memo");

        // [WHEN] Purchase Credit Memos are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", true,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purch. Credit Memos");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date in Posted Credit Memos is 01.11.16
        VerifyCrMemoPostingDate(DocNo1, NewPostDate);
        VerifyCrMemoPostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyCrMemoPostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer1);
        VerifyCrMemoPostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, NewPostDate, AmtToDefer2);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseInvoicesReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoInvoicesWithDeferralConfirmNo()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Purchase Invoices with updated Posting Date should update deferral schedule with Confirm No
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Purchase Invoices with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::Invoice);

        // [WHEN] Purchase Invoices are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", false,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purchase Invoices");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.10.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyInvoicePostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, PurchaseHeader1."Posting Date", AmtToDefer1);
        VerifyInvoicePostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, PurchaseHeader2."Posting Date", AmtToDefer2);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchaseOrdersReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoOrdersWithDeferralConfirmNo()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Purchase Orders with updated Posting Date should update deferral schedule with Confirm No
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Purchase Orders with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::Order);

        // [WHEN] Purchase Orders are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", false,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purchase Orders");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date of Purchase Invoices is 01.11.16
        VerifyInvoicePostingDate(DocNo1, NewPostDate);
        VerifyInvoicePostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.10.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyInvoicePostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, PurchaseHeader1."Posting Date", AmtToDefer1);
        VerifyInvoicePostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, PurchaseHeader2."Posting Date", AmtToDefer2);
    end;

    [Test]
    [HandlerFunctions('BatchPostPurchCreditMemosReportHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPostBatchTwoCrMemosWithDeferralConfirmNo()
    var
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        DeferralTemplateCode: Code[10];
        AccNo: Code[20];
        DocNo1: Code[20];
        DocNo2: Code[20];
        AmtToDefer1: Decimal;
        AmtToDefer2: Decimal;
        NewPostDate: Date;
    begin
        // [FEATURE] [Post Document] [Batch Posting]
        // [SCENARIO 382285] Batch Posting of Deferral Purchase Credit Memos with updated Posting Date should update deferral schedule with Confirm No
        Initialize();
        LibraryPurchase.SetPostWithJobQueue(true);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Two Purchase Credit Memos with Posting Date = 01.10.16 and deferral code
        CreateTwoPurchDocsWithDeferral(
          PurchaseHeader1, PurchaseHeader2, DeferralTemplateCode, AccNo, DocNo1, DocNo2,
          AmtToDefer1, AmtToDefer2, PurchaseHeader1."Document Type"::"Credit Memo");

        // [WHEN] Purchase Credit Memos are posted with batch report on 01.11.16 and confirm update on deferral date = Yes
        RunBatchPostReport(
          NewPostDate, PurchaseHeader1."Posting Date", false,
          PurchaseHeader1."No.", PurchaseHeader2."No.",
          REPORT::"Batch Post Purch. Credit Memos");
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader1.RecordId);
        LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(PurchaseHeader2.RecordId);

        // [THEN] Confirm is called once
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), ConfirmCallOnceErr);

        // [THEN] Posting Date in Posted Credit Memos is 01.11.16
        VerifyCrMemoPostingDate(DocNo1, NewPostDate);
        VerifyCrMemoPostingDate(DocNo2, NewPostDate);

        // [THEN] The deferrals are posted according to schedule from 01.11.16
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyCrMemoPostedDeferrals(DocNo1, DeferralTemplateCode, AccNo, PurchaseHeader1."Posting Date", AmtToDefer1);
        VerifyCrMemoPostedDeferrals(DocNo2, DeferralTemplateCode, AccNo, PurchaseHeader2."Posting Date", AmtToDefer2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralDeletesDeferralHdrAndLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
        OriginalDocNo: Code[20];
        AmtToDefer: Decimal;
        LineNo: Integer;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 159878] When a Purchase Invoice is posted, the Deferral Header and Line Records are deleted
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create Purchase Line for Item
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := PurchaseLine.GetDeferralAmount();
        OriginalDocNo := PurchaseHeader."No.";
        LineNo := PurchaseLine."Line No.";

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Invoice Line and Posted Deferral tables
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        PurchInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, SetDateDay(1, WorkDate()), AmtToDefer, AmtToDefer, 2);

        // [THEN] Deferrals were removed from the Deferral Header and Deferral Line Tables
        VerifyDeferralHeaderLinesRemoved(PurchDocType::Invoice, OriginalDocNo, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithCurrencyAndDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        CurrExchRate: Record "Currency Exchange Rate";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
        AmtToDefer: Decimal;
        AmtToDeferLCY: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice with Currency is posted, the deferrals are created
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Create Purchase Invoice with FCY, and Item with default deferral code
        CreatePurchDocWithCurrencyAndLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := PurchaseLine.GetDeferralAmount();
        AmtToDeferLCY :=
          Round(CurrExchRate.ExchangeAmtFCYToLCY(SetDateDay(1, WorkDate()),
              PurchaseHeader."Currency Code", AmtToDefer, PurchaseHeader."Currency Factor"));

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Invoice Line and Posted Deferral tables
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        PurchInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, SetDateDay(1, WorkDate()), AmtToDefer, AmtToDeferLCY, 2);

        // [THEN] The deferrals were posted to GL for 3 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceTwoLinesWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice is posted with multiple lines of the same type,
        // the general ledger accounts for the deferrals are combined when they are created
        Initialize();
        // [GIVEN] User has assigned a default deferral code to two differnt Items
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        CreateItemWithUnitPrice(Item);
        Item.Validate("Default Deferral Template Code", DeferralTemplateCode);
        Item.Modify(true);
        ItemNo := Item."No.";
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [GIVEN] Add the second item to the document
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 2);
        if Item.Get(ItemNo) then begin
            PurchaseLine.Validate("Direct Unit Cost", Item."Unit Cost");
            PurchaseLine.Modify(true);
        end;
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were posted to GL for 3 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, false);

        // [THEN] G/L Entries for deferral periods are posted according to Deferral Schedule (TFS 378831)
        VerifyPurchGLDeferralAccount(PurchaseLine, DocNo, PurchaseHeader.Amount);
        VerifyGLForDeferralPeriod(DocNo, AccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithPartialDeferral()
    var
        GenPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
        PurchAccount: Code[20];
        PurchAmount: Decimal;
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice is posted with a partial deferral, the Purchase accounts is reduced by the deferral and balance posted to first period
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := Round(PurchaseLine.GetDeferralAmount() * 0.7);
        PurchAmount := PurchaseLine.GetDeferralAmount() - AmtToDefer;
        ModifyDeferral(PurchaseLine, DeferralHeader."Calc. Method"::"Straight-Line", 2,
          AmtToDefer, SetDateDay(1, WorkDate()));
        GenPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchAccount := GenPostingSetup."Purch. Account";

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Invoice Line and Posted Deferral tables
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        PurchInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, SetDateDay(1, WorkDate()), AmtToDefer, AmtToDefer, 2);

        // [THEN] The amount not deferred was posted to GL for the Purchase account
        ValidateGLPurchAccount(DocNo, PurchAccount, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 5, PurchAmount);

        // [THEN] The deferrals were posted to GL for 3 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 2), 3, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralNoDeferralHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice will not post if the deferral header record is not created
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(PurchaseLine, DeferralHeader);
        DeferralHeader.Delete();

        // [WHEN] Document is posted
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(NoDeferralScheduleErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralDeferralHeaderZero()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice will not post if the deferral header Amount To Defer is Zero
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(PurchaseLine, DeferralHeader);
        DeferralHeader."Amount to Defer" := 0;
        DeferralHeader.Modify();

        // [WHEN] Document is posted
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(NoDeferralScheduleErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralNoDeferralLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice will not post if the deferral schedule does not have any lines
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(PurchaseLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        DeferralLine.DeleteAll();

        // [WHEN] Document is posted
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(NoDeferralScheduleErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostInvoiceWithDeferralOneZeroDeferralLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralLine: Record "Deferral Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Purchase Invoice will not post if one of the deferral schedule lines has a zero amount
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        FindDeferralHeader(PurchaseLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        if DeferralLine.FindFirst() then begin
            DeferralLine.Amount := 0.0;
            DeferralLine."Amount (LCY)" := 0.0;
            DeferralLine.Modify();
        end;

        // [WHEN] Document is posted
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The error specifying the No and Deferral Code is given
        Assert.ExpectedError(StrSubstNo(ZeroDeferralAmtErr, ItemNo, DeferralTemplateCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Credit Memo is posted, the general ledger accounts for the deferrals are created
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::Item, ItemNo, SetDateDay(15, WorkDate()));
        AmtToDefer := PurchaseLine.GetDeferralAmount();

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Credit Memo and Posted Deferral tables
        FindPurchCrMemoLine(PurchCrMemoLine, DocNo);
        PurchCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Credit Memo", DocNo,
          PurchCrMemoLine."Line No.", DeferralTemplateCode, SetDateDay(15, WorkDate()), AmtToDefer, AmtToDefer, 3);

        // [THEN] The deferrals were posted to GL for 5 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(15, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 5, 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostCreditMemoWithPartialDeferral()
    var
        GenPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DeferralHeader: Record "Deferral Header";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
        PurchAccount: Code[20];
        PurchAmount: Decimal;
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Credit Memo is posted with a partial deferral,
        // the correct Purchase Credit Memo Account is posted to with correct amounts
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := Round(PurchaseLine.GetDeferralAmount() * 0.7);
        PurchAmount := PurchaseLine.GetDeferralAmount() - AmtToDefer;
        ModifyDeferral(PurchaseLine, DeferralHeader."Calc. Method"::"Straight-Line", 2,
          AmtToDefer, SetDateDay(1, WorkDate()));

        // [GIVEN] Purchase Credit Memo Account updated
        GenPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        CreateGLAccount(GLAccount);
        PurchAccount := GLAccount."No.";
        GenPostingSetup.Validate("Purch. Credit Memo Account", PurchAccount);
        GenPostingSetup.Modify();

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Credit Memo and Posted Deferral tables
        FindPurchCrMemoLine(PurchCrMemoLine, DocNo);
        PurchCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Credit Memo", DocNo,
          PurchCrMemoLine."Line No.", DeferralTemplateCode, SetDateDay(1, WorkDate()), AmtToDefer, AmtToDefer, 2);

        // [THEN] The amount not deferred was posted to GL for the Purchase account
        ValidateGLPurchAccount(DocNo, PurchAccount, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 5, PurchAmount);

        // [THEN] The deferrals were posted to GL for 3 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 3, 0, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostReturnOrderWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        AccNo: Code[20];
        DocNo: Code[20];
        AmtToDefer: Decimal;
    begin
        // [FEATURE] [Post Document]
        // [SCENARIO 127772] When a Return Order is posted, the general ledger accounts for the deferrals are created
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, ItemNo, SetDateDay(15, WorkDate()));
        AmtToDefer := PurchaseLine.GetDeferralAmount();

        // [WHEN] Document is posted
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were moved to the Purchase Credit Memo and Posted Deferral tables
        FindPurchCrMemoLine(PurchCrMemoLine, DocNo);
        PurchCrMemoLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Credit Memo", DocNo,
          PurchCrMemoLine."Line No.", DeferralTemplateCode, SetDateDay(15, WorkDate()), AmtToDefer, AmtToDefer, 3);

        // [THEN] The deferrals were posted to GL for 5 periods with zero balance if reversed out correctly
        // [THEN] There is a G/L Entry for a posting account with VAT (TFS 251252)
        // [THEN] There is a pair of initial deferral G/L Entries for a posting account (TFS 258121)
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(15, WorkDate()), PeriodDate(SetDateDay(1, WorkDate()), 3), 5, 0, false);
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseInvoiceDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Invoice with GL Account allows editing of the deferral code and accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document with one line item for GL Account
        CreatePurchDocAndDeferralTemplateCode(PurchaseHeader, PurchaseLine, DeferralTemplateCode, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Deferral Code entered for GL Account, where amount to defer is 'X'
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);

        // [WHEN] Run "Deferral Schedule" action on the line
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(PurchaseLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(PurchaseHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseInvoiceDeferralScheduleNeg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Invoice with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // [WHEN] Open the Purchase Invoice as edit with the document
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.Type.Value(Format(PurchaseLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(PurchaseInvoice.PurchLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        PurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('UpdateDeferralSchedulePeriodHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Updating Deferral Schedule period updates the deferral lines
        Initialize();
        // [GIVEN] User has created a Purchase Document with one line item for Item that has a default deferral code
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        Commit();

        // [GIVEN] Two periods are created
        FindDeferralHeader(PurchaseLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        Assert.AreEqual(2, DeferralLine.Count, 'An incorrect number of lines was created');

        // [GIVEN] Open the Purchase Invoice as edit with the document
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.First();

        // [WHEN] Deferral Schedule is updated - happens in the handler function
        LibraryVariableStorage.Enqueue(3);
        PurchaseInvoice.PurchLines.DeferralSchedule.Invoke();

        // [THEN] Three periods have created three deferral lines
        FindDeferralHeader(PurchaseLine, DeferralHeader);
        RangeDeferralLines(DeferralHeader, DeferralLine);
        Assert.AreEqual(3, DeferralLine.Count, 'An incorrect number of lines was recalculated');
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseOrderDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Order with GL Account allows editing of the deferral code and accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document with one line item for GL Account
        CreatePurchDocAndDeferralTemplateCode(PurchaseHeader, PurchaseLine, DeferralTemplateCode, PurchaseHeader."Document Type"::Order);

        // [GIVEN] Deferral Code entered for GL Account, where amount to defer is 'X'
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);

        // [WHEN] Run "Deferral Schedule" action on the line
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(PurchaseLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(PurchaseHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseOrderDeferralScheduleNeg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Order with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());

        // [WHEN] Open the Purchase Order as edit with the document
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.Type.Value(Format(PurchaseLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(PurchaseOrder.PurchLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseCreditMemoDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Credit Memo with GL Account allows editing of the deferral code and accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document with one line item for GL Account
        CreatePurchDocAndDeferralTemplateCode(PurchaseHeader, PurchaseLine, DeferralTemplateCode,
          PurchaseHeader."Document Type"::"Credit Memo");

        // [GIVEN] Deferral Code entered for GL Account, where amount to defer is 'X'
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);

        // [WHEN] Run "Deferral Schedule" action on the line
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.PurchLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(PurchaseLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(PurchaseHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseCreditMemoDeferralScheduleNeg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Credit Memo with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendor());

        // [WHEN] Open the Purchase Invoice as edit with the document
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo.PurchLines.Type.Value(Format(PurchaseLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(PurchaseCreditMemo.PurchLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        PurchaseCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseReturnOrderDeferralSchedulePos()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Return Order with GL Account allows editing of the deferral code and accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document with one line item for GL Account
        CreatePurchDocAndDeferralTemplateCode(PurchaseHeader, PurchaseLine, DeferralTemplateCode,
          PurchaseHeader."Document Type"::"Return Order");

        // [GIVEN] Deferral Code entered for GL Account, where amount to defer is 'X'
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);

        // [WHEN] Run "Deferral Schedule" action on the line
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder.PurchLines.DeferralSchedule.Invoke();
        // [THEN] Page "Deferral Schedule" is open, where "Amount to Defer" is 'X'
        Assert.AreEqual(PurchaseLine.GetDeferralAmount(), LibraryVariableStorage.DequeueDecimal(), 'Amount to defer.');
        Assert.AreEqual(PurchaseHeader."Posting Date", LibraryVariableStorage.DequeueDate(), 'Header Posting Date');
        DeferralTemplate.Get(DeferralTemplateCode);
        Assert.AreEqual(Format(DeferralTemplate."Start Date"), LibraryVariableStorage.DequeueText(), 'Start date calc method');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseReturnOrderDeferralScheduleNeg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] Entering a Purchase Return Order with Fixed Asset does not allow editing of the deferral code or accessing schedule
        Initialize();
        // [GIVEN] User has created a Purchase Document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateVendor());

        // [WHEN] Open the Purchase Return Order as edit with the document
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrder.PurchLines.Type.Value(Format(PurchaseLine.Type::"Fixed Asset"));

        // [THEN] Deferral Code and Deferral Schedule menu are not enabled
        Assert.IsFalse(PurchaseReturnOrder.PurchLines.DeferralSchedule.Enabled(), 'Deferral Schedule should NOT be enabled');

        PurchaseReturnOrder.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleViewHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPostedPurchaseInvoiceDeferralSchedulePos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] View deferrals for posted invoice
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create and post the purchase invoice with the default deferral
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocNo);

        // [WHEN] Open the Posted Purchase Invoice
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", DocNo);
        PostedPurchaseInvoice.PurchInvLines.First();

        // [THEN] Deferral Schedule can be opened for line
        PostedPurchaseInvoice.PurchInvLines.DeferralSchedule.Invoke();

        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleViewHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPostedPurchaseInvoiceDeferralScheduleNeg()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
        DocNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] View deferrals for posted Credit Memo
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create and post the Purchase Credit Memo with the default deferral
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchCrMemoHdr.Get(DocNo);

        // [WHEN] Open the Posted Purchase Invoice
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", DocNo);
        PostedPurchaseCreditMemo.PurchCrMemoLines.First();

        // [THEN] Deferral Schedule can be opened for line
        PostedPurchaseCreditMemo.PurchCrMemoLines.DeferralSchedule.Invoke();

        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleArchiveHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseOrderArchiveDeferralSchedulePos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseOrderArchive: TestPage "Purchase Order Archive";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] View deferrals for Archived Purchase Order
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        // [GIVEN] Document is archived
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        FindPurchOrderArchive(PurchHeaderArchive, PurchaseHeader."No.");

        // [WHEN] Open the Posted Purchase Order Archive
        PurchaseOrderArchive.OpenView();
        PurchaseOrderArchive.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrderArchive.FILTER.SetFilter("Doc. No. Occurrence", '1');
        PurchaseOrderArchive.FILTER.SetFilter("Version No.", '1');
        PurchaseOrderArchive.PurchLinesArchive.First();

        // [THEN] Deferral Schedule Archive can be opened for line
        PurchaseOrderArchive.PurchLinesArchive.DeferralSchedule.Invoke();

        PurchaseOrderArchive.Close();
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleArchiveHandler')]
    [Scope('OnPrem')]
    procedure TestOpenPurchaseReturnOrderArchiveDeferralSchedulePos()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseReturnOrderArchive: TestPage "Purchase Return Order Archive";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 127771] View archive deferrals for return order
        Initialize();
        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Create and archive the purchase return order with the default deferral
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
        FindPurchReturnOrderArchive(PurchHeaderArchive, PurchaseHeader."No.");

        // [WHEN] Open the Posted Purchase Invoice
        PurchaseReturnOrderArchive.OpenView();
        PurchaseReturnOrderArchive.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrderArchive.FILTER.SetFilter("Doc. No. Occurrence", '1');
        PurchaseReturnOrderArchive.FILTER.SetFilter("Version No.", '1');
        PurchaseReturnOrderArchive.PurchLinesArchive.First();

        // [THEN] Deferral Schedule Archive can be opened for line
        PurchaseReturnOrderArchive.PurchLinesArchive.DeferralSchedule.Invoke();

        PurchaseReturnOrderArchive.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resources]
        // [SCENARIO 289386] Deferral template code filled in the purchase order line when select resource with default deferral template
        Initialize();

        // [GIVEN] Resource with default deferral code
        CreateResourceWithDefaultDeferralCode(Resource);

        // [WHEN] Create purchase order with resource line
        CreatePurchDocWithLine(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Resource, Resource."No.", CalcDate('<-CM>', WorkDate()));

        // [THEN] The Deferral Code was assigned to the Purchase Line
        PurchaseLine.TestField("Deferral Code", Resource."Default Deferral Template Code");

        // [THEN] The deferral schedule was created
        ValidateDeferralSchedule(
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
          Resource."Default Deferral Template Code", PurchaseHeader."Posting Date", PurchaseLine.GetDeferralAmount(), 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedInvoiceWithResourceAndDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        Resource: Record Resource;
        DocNo: Code[20];
    begin
        // [FEATURE] [Resources]
        // [SCENARIO 289386] Deferral template code filled in the purchase order line when copy document from posted invoice with resource line
        Initialize();

        // [GIVEN] Resource with default deferral code
        CreateResourceWithDefaultDeferralCode(Resource);

        // [GIVEN] Posted purchase invoice with resource line
        CreatePurchDocWithLine(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Resource, Resource."No.", CalcDate('<-CM>', WorkDate()));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(DocNo);

        // [WHEN] Create New purchase order document and copy the existing one
        CreatePurchHeaderForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Order, CalcDate('<-CM>', WorkDate()), PurchInvHeader."Buy-from Vendor No.");
        CopyDoc(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PurchInvHeader."No.", true, false);

        // [THEN] The deferral schedule was copied from the existing line
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        FindPurchLine(PurchaseHeader, PurchaseLine);
        if PurchaseLine."No." = '' then
            PurchaseLine.Next();
        PurchaseLine.TestField("Deferral Code", Resource."Default Deferral Template Code");
        PurchaseLine.TestField("Returns Deferral Start Date", 0D);
        VerifyPostedDeferralsAreEqual(PurchInvLine, PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('UpdateAmountToDeferOnDeferralScheduleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateAmountToDeferOnDeferralScheduleCreatedBeforeAmountValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DeferralTemplateCode: Code[10];
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 416877] Stan can change "Amount to Defer" on deferall schedule created before Amount is validated on Line/Document

        Initialize();

        NoOfPeriods := LibraryRandom.RandIntInRange(10, 20);
        DeferralTemplateCode :=
            CreateDeferralCode(CalcMethod::"Equal per Period", StartDate::"Beginning of Next Period", NoOfPeriods);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 0);

        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);

        PurchaseLine.Modify(true);

        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);

        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(PurchaseLine.GetDeferralAmount() / 2);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.DeferralSchedule.Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('UpdateAmountToDeferOnDeferralScheduleModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateAmountToDeferOnDeferralScheduleCreatedAfterAmountValidation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DeferralTemplateCode: Code[10];
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 416877] Stan can change "Amount to Defer" on deferall schedule created after Amount is validated on Line/Document

        Initialize();

        NoOfPeriods := LibraryRandom.RandIntInRange(10, 20);
        DeferralTemplateCode :=
            CreateDeferralCode(CalcMethod::"Equal per Period", StartDate::"Beginning of Next Period", NoOfPeriods);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 0);

        PurchaseLine.Validate(Quantity, LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200) * NoOfPeriods);

        PurchaseLine.Modify(true);

        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);

        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(PurchaseLine.GetDeferralAmount() / 2);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.Filter.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.DeferralSchedule.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDeferralsWithBlankDescriptionWhenOmitDefaultDescriptionEnabledOnDeferralGLAccount()
    var
        GLAccountDeferral: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 422767] Stan can't post Purchase document with Deferral setup when Deferral Account has enabled "Omit Default Descr. in Jnl." and blank Description Deferral Template
        Initialize();
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(GLAccountDeferral, DeferralTemplateCode, '', true);

        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Assert.ExpectedError(StrSubstNo(GLAccountOmitErr, GLAccountDeferral.FieldCaption("Omit Default Descr. in Jnl.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDeferralsWithBlankDescriptionWhenOmitDefaultDescriptionDisabledOnDeferralGLAccount()
    var
        GLAccountDeferral: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 422767] Stan can post Purchase document with Deferral setup when Deferral Account has disabled "Omit Default Descr. in Jnl." and blank Description Deferral Template
        Initialize();
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(GLAccountDeferral, DeferralTemplateCode, '', false);

        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyGLEntriesExistWithBlankDescription(GLAccountDeferral."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostDeferralsWithDescriptionWhenOmitDefaultDescriptionEnabledOnDeferralGLAccount()
    var
        GLAccountDeferral: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO 422767] Stan can post Sales document with Deferral setup when Deferral Account has enabled "Omit Default Descr. in Jnl." and specified Description Deferral Template
        Initialize();
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        UpdateDescriptionAndOmitDefaultDescriptionOnDeferralGLAccount(GLAccountDeferral, DeferralTemplateCode, LibraryUtility.GenerateGUID(), true);

        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyGLEntriesDoNotExistWithBlankDescription(GLAccountDeferral."No.");
    end;

    [Test]
    [HandlerFunctions('UpdateStartDateOnDeferralScheduleModalPageHandler')]
    procedure T459058_PurchaseInvoiceDeferralScheduleStartDateChange_WithGeneralLedgerSetupDateLimits()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        DeferralTemplateCode: Code[10];
        BaseDate: Date;
    begin
        // [FEATURE] [UI] [Allow Deferral Posting From] [Allow Deferral Posting To] [Deferral Template] [Purchase Invoice] [Deferral Schedule]
        // [SCENARIO 459058] Define "Allow Posting From" and "Allow Deferral Posting From" in "General Ledger Setup" to year start. Define "Allow Posting To" to end of January and "Allow Deferral Posting To" to end of the year.
        // [SCENARIO 459058] Create a Purchase Invoice with G/L Account and Deferral Code. Modify "Start Date" in "Deferral Schedule" to date after "Allow Posting To", but before "Allow Deferral Posting To".
        Initialize();

        BaseDate := WorkDate();
        // [GIVEN] "User Setup" has no setup on "Allow Deferrals Posting From" and "Allow Deferral Posting To"
        // [GIVEN] "General Ledger Setup", set "Allow Posting From" to 1/January and "Allow Posting To" to 31/January
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := DMY2Date(1, 1, Date2DMY(BaseDate, 3));
        GeneralLedgerSetup."Allow Posting To" := DMY2Date(31, 1, Date2DMY(BaseDate, 3));
        // [GIVEN] "General Ledger Setup", set "Allow Deferral Posting From" to 1/January and "Allow Deferral Posting To" to 31/December
        GeneralLedgerSetup."Allow Deferral Posting From" := DMY2Date(1, 1, Date2DMY(BaseDate, 3));
        GeneralLedgerSetup."Allow Deferral Posting To" := DMY2Date(31, 12, Date2DMY(BaseDate, 3));
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Deferral Template
        DeferralTemplateCode := CreateDeferralTemplate(100, "Deferral Calculation Method"::"Straight-Line", "Deferral Calculation Start Date"::"Beginning of Period", 3, 'Deferral %1');

        // [GIVEN] Create Purchase Invoice on 15/January with G/L Account and "Deferral Code"
        CreateGLAccount(GLAccount);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::"G/L Account", GLAccount."No.", DMY2Date(15, 1, Date2DMY(BaseDate, 3)));
        PurchaseLine.Validate("Quantity", 1);
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);

        // [GIVEN] Open "Purchase Invoice" page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // [GIVEN] Run "Deferral Schedule" action on the line
        LibraryVariableStorage.Enqueue(DMY2Date(1, 5, Date2DMY(BaseDate, 3)));
        PurchaseInvoice.PurchLines.DeferralSchedule.Invoke();

        // [WHEN] Change "Start Date" to 1/February
        // "Start Date" change handled in UpdateStartDateOnDeferralScheduleModalPageHandler.

        // [THEN] There was no error for "Start Date" change

        PurchaseInvoice.Close();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RED Test Unit for Purch Doc");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        // Setup demo data.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RED Test Unit for Purch Doc");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RED Test Unit for Purch Doc");
    end;

    local procedure CreateDeferralCode(CalcMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumOfPeriods: Integer): Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" :=
          LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        DeferralTemplate."Deferral Account" := LibraryERM.CreateGLAccountNo();
        DeferralTemplate."Calc. Method" := CalcMethod;
        DeferralTemplate."Start Date" := StartDate;
        DeferralTemplate."No. of Periods" := NumOfPeriods;
        DeferralTemplate."Period Description" := 'Deferral Revenue for %4';

        DeferralTemplate.Insert();
        exit(DeferralTemplate."Deferral Code");
    end;

    local procedure CreateDeferralTemplate(DeferralPercent: Decimal; DeferralCalculationMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumberOfPeriods: Integer; PeriodDescription: Text[100]): Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" := LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        DeferralTemplate."Deferral Account" := LibraryERM.CreateGLAccountNo();
        DeferralTemplate."Deferral %" := DeferralPercent;
        DeferralTemplate."Calc. Method" := DeferralCalculationMethod;
        DeferralTemplate."Start Date" := StartDate;
        DeferralTemplate."No. of Periods" := NumberOfPeriods;
        DeferralTemplate."Period Description" := PeriodDescription;

        DeferralTemplate.Insert();
        exit(DeferralTemplate."Deferral Code");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
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
        No := LibraryERM.CreateGLAccountWithPurchSetup();
        GLAccount.Get(No);
    end;

    local procedure CreatePurchDocWithLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PurchLineType: Enum "Purchase Line Type"; No: Code[20]; PostingDate: Date)
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchLineType, No, 2);
        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                begin
                    PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
                    PurchaseLine.Modify(true);
                end;
            PurchaseLine.Type::Item:
                if Item.Get(No) then begin
                    PurchaseLine.Validate("Direct Unit Cost", Item."Unit Cost");
                    PurchaseLine.Modify(true)
                end;
            PurchaseLine.Type::Resource:
                begin
                    PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
                    PurchaseLine.Modify(true)
                end;
        end;
    end;

    local procedure CreatePurchHeaderForVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PostingDate: Date; VendorCode: Code[20])
    begin
        Clear(PurchaseHeader);
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorCode);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Insert(true);
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; var AmtToDefer: Decimal; var PostingDocNo: Code[20]; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
    begin
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          DocumentType, PurchaseLine.Type::Item, ItemNo, SetDateDay(1, WorkDate()));
        AmtToDefer := PurchaseLine.GetDeferralAmount();
        PostingDocNo := NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series", PurchaseHeader."Posting Date");
    end;

    local procedure CreateTwoPurchDocsWithDeferral(var PurchaseHeader1: Record "Purchase Header"; var PurchaseHeader2: Record "Purchase Header"; var DeferralTemplateCode: Code[10]; var AccNo: Code[20]; var DocNo1: Code[20]; var DocNo2: Code[20]; var AmtToDefer1: Decimal; var AmtToDefer2: Decimal; DocType: Enum "Purchase Document Type")
    var
        ItemNo: Code[20];
    begin
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
        AccNo := GetDeferralTemplateAccount(DeferralTemplateCode);

        CreatePurchDocument(PurchaseHeader1, AmtToDefer1, DocNo1, DocType, ItemNo);
        CreatePurchDocument(PurchaseHeader2, AmtToDefer2, DocNo2, DocType, ItemNo);
    end;

    local procedure DeletePurchDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Delete(true);
    end;

    local procedure SetDateDay(Day: Integer; StartDate: Date): Date
    begin
        // Use the workdate but set to a specific day of that month
        exit(DMY2Date(Day, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3)));
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

    local procedure DeferralLineSetRange(var DeferralLine: Record "Deferral Line"; DocType: Enum "Purchase Document Type"; DocNo: Code[20]; LineNo: Integer)
    begin
        DeferralLine.SetRange("Deferral Doc. Type", "Deferral Document Type"::Purchase);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
    end;

    local procedure ValidateDeferralSchedule(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; LineNo: Integer; DeferralTemplateCode: Code[10]; HeaderPostingDate: Date; HeaderAmountToDefer: Decimal; NoOfPeriods: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        Period: Integer;
        DeferralAmount: Decimal;
        PostingDate: Date;
    begin
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '', DocType, DocNo, LineNo);
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

    local procedure ValidateDeferralScheduleDoesNotExist(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        asserterror DeferralHeader.Get("Deferral Document Type"::Purchase, '', '', DocType, DocNo, LineNo);

        DeferralLineSetRange(DeferralLine, DocType, DocNo, LineNo);
        asserterror DeferralLine.FindFirst();
    end;

    local procedure CopyDoc(PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; DocNo: Code[20]; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopyPurchaseDoc: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchaseDoc);
        CopyPurchaseDoc.SetParameters(ConvertDocType(DocType), DocNo, IncludeHeader, RecalculateLines);
        CopyPurchaseDoc.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDoc.UseRequestPage(false);
        CopyPurchaseDoc.RunModal();
    end;

    local procedure ConvertDocType(DocType: Enum "Purchase Document Type"): Enum "Purchase Document Type From"
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        case DocType of
            PurchaseHeader."Document Type"::Quote:
                exit("Purchase Document Type From"::Quote);
            PurchaseHeader."Document Type"::"Blanket Order":
                exit("Purchase Document Type From"::"Blanket Order");
            PurchaseHeader."Document Type"::Order:
                exit("Purchase Document Type From"::Order);
            PurchaseHeader."Document Type"::Invoice:
                exit("Purchase Document Type From"::Invoice);
            PurchaseHeader."Document Type"::"Return Order":
                exit("Purchase Document Type From"::"Return Order");
            PurchaseHeader."Document Type"::"Credit Memo":
                exit("Purchase Document Type From"::"Credit Memo");
            else
                exit(DocType);
        end;
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

    local procedure VerifyDeferralsAreEqual(PurchaseLineOrig: Record "Purchase Line"; PurchaseLineDest: Record "Purchase Line")
    var
        DeferralHeaderOrig: Record "Deferral Header";
        DeferralHeaderDest: Record "Deferral Header";
        DeferralLineOrig: Record "Deferral Line";
        DeferralLineDest: Record "Deferral Line";
    begin
        FindDeferralHeader(PurchaseLineOrig, DeferralHeaderOrig);
        FindDeferralHeader(PurchaseLineDest, DeferralHeaderDest);

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

    local procedure FindDeferralHeader(PurchaseLine: Record "Purchase Line"; var DeferralHeader: Record "Deferral Header")
    begin
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '',
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
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

    local procedure VerifyPostedDeferralsAreEqual(PurchInvLine: Record "Purch. Inv. Line"; PurchaseLine: Record "Purchase Line")
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        DeferralHeader: Record "Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralLine: Record "Deferral Line";
    begin
        FindPostedDeferralHeader(PurchInvLine, PostedDeferralHeader);
        FindDeferralHeader(PurchaseLine, DeferralHeader);

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

    local procedure FindPostedDeferralHeader(PurchInvLine: Record "Purch. Inv. Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
        PostedDeferralHeader.Get("Deferral Document Type"::Purchase, '', '',
          "Purchase Document Type From"::"Posted Invoice", PurchInvLine."Document No.", PurchInvLine."Line No.");
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

    local procedure ModifyDeferral(PurchaseLine: Record "Purchase Line"; CalcMethod: Enum "Deferral Calculation Method"; NoOfPeriods: Integer; DeferralAmount: Decimal; StartDate: Date)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '',
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        DeferralUtilities.SetDeferralRecords(DeferralHeader, "Deferral Document Type"::Purchase.AsInteger(), '', '',
          PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
          CalcMethod, NoOfPeriods, DeferralAmount, StartDate,
          DeferralHeader."Deferral Code", DeferralHeader."Schedule Description",
          PurchaseLine.GetDeferralAmount(), true, DeferralHeader."Currency Code");
        DeferralUtilities.CreateDeferralSchedule(DeferralHeader."Deferral Code", DeferralHeader."Deferral Doc. Type".AsInteger(),
          DeferralHeader."Gen. Jnl. Template Name", DeferralHeader."Gen. Jnl. Batch Name",
          DeferralHeader."Document Type", DeferralHeader."Document No.", DeferralHeader."Line No.",
          DeferralHeader."Amount to Defer", DeferralHeader."Calc. Method", DeferralHeader."Start Date",
          DeferralHeader."No. of Periods", false, DeferralHeader."Schedule Description", false, DeferralHeader."Currency Code");
    end;

    local procedure VerifyDeferralArchivesAreEqual(PurchLineArchive: Record "Purchase Line Archive"; PurchaseLine: Record "Purchase Line")
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
        DeferralHeader: Record "Deferral Header";
        DeferralLineArchive: Record "Deferral Line Archive";
        DeferralLine: Record "Deferral Line";
    begin
        FindDeferralHeaderArchive(PurchLineArchive, DeferralHeaderArchive);
        FindDeferralHeader(PurchaseLine, DeferralHeader);

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

    local procedure FindDeferralHeaderArchive(PurchaseLineArchive: Record "Purchase Line Archive"; var DeferralHeaderArchive: Record "Deferral Header Archive")
    begin
        DeferralHeaderArchive.Get("Deferral Document Type"::Purchase,
          PurchaseLineArchive."Document Type", PurchaseLineArchive."Document No.",
          PurchaseLineArchive."Doc. No. Occurrence", PurchaseLineArchive."Version No.", PurchaseLineArchive."Line No.");
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

    local procedure FindPurchLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.Find('-');
    end;

    local procedure FindPurchLineArchive(PurchaseHeader: Record "Purchase Header"; var PurchaseLineArchive: Record "Purchase Line Archive")
    begin
        PurchaseLineArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLineArchive.SetRange("Doc. No. Occurrence", 1);
        PurchaseLineArchive.SetRange("Version No.", 1);
        PurchaseLineArchive.Find('-');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    local procedure FindPurchOrderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeaderArchive.SetRange("No.", No);
        PurchaseHeaderArchive.FindFirst();
    end;

    local procedure FindPurchReturnOrderArchive(var PurchHeaderArchive: Record "Purchase Header Archive"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type"::"Return Order");
        PurchHeaderArchive.SetRange("No.", No);
        PurchHeaderArchive.FindFirst();
    end;

    local procedure ValidateDeferralArchiveScheduleDoesNotExist(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeaderArchive: Record "Deferral Header Archive";
        DeferralLineArchive: Record "Deferral Line Archive";
    begin
        asserterror DeferralHeaderArchive.Get("Deferral Document Type"::Purchase, '', '', DocType, DocNo, LineNo);

        DeferralLineArchive.SetRange("Deferral Doc. Type", "Deferral Document Type"::Purchase);
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
        PostedDeferralHeader.Get("Deferral Document Type"::Purchase, '', '', DocType, DocNo, LineNo);
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

    local procedure FindPurchInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; No: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", No);
        PurchInvLine.FindFirst();
    end;

    local procedure FindPurchCrMemoLine(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; No: Code[20])
    begin
        PurchCrMemoLine.SetRange("Document No.", No);
        PurchCrMemoLine.FindFirst();
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocNo: Code[20]; AccNo: Code[20]; GenPostType: Enum "General Posting Type")
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostType);
    end;

    local procedure FilterInvoiceGLEntryGroups(var GLEntry: Record "G/L Entry"; GenPostingType: Enum "General Posting Type"; PurchInvLine: Record "Purch. Inv. Line")
    begin
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("VAT Bus. Posting Group", PurchInvLine."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", PurchInvLine."VAT Prod. Posting Group");
        GLEntry.SetRange("Gen. Bus. Posting Group", PurchInvLine."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
    end;

    local procedure FilterCrMemoGLEntryGroups(var GLEntry: Record "G/L Entry"; GenPostingType: Enum "General Posting Type"; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.SetRange("VAT Bus. Posting Group", PurchCrMemoLine."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", PurchCrMemoLine."VAT Prod. Posting Group");
        GLEntry.SetRange("Gen. Bus. Posting Group", PurchCrMemoLine."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", PurchCrMemoLine."Gen. Prod. Posting Group");
    end;

    local procedure GetDeferralTemplateAccount(DeferralTemplateCode: Code[10]): Code[20]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(DeferralTemplateCode);
        exit(DeferralTemplate."Deferral Account");
    end;

    local procedure GetPurchAccountNo(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        exit(GeneralPostingSetup."Purch. Account");
    end;

    local procedure GetPurchCrMemoAccountNo(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        exit(GeneralPostingSetup."Purch. Credit Memo Account");
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

    local procedure GLCalcSum(DocNo: Code[20]; AccNo: Code[20]; StartPostDate: Date; EndPostDate: Date; var RecCount: Integer; var AccAmt: Decimal; var NonDeferralAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(AccAmt);
        Clear(GLEntry);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", StartPostDate, EndPostDate);
        RecCount := GLEntry.Count();
        GLEntry.CalcSums(Amount);
        AccAmt := GLEntry.Amount;
        if GLEntry.FindFirst() then
            NonDeferralAmt := GLEntry.Amount;
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

    local procedure ValidateReturnsDeferralStartDate(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; LineNo: Integer; ReturnsDeferralStartDate: Date; var DeferralAmount: Decimal)
    var
        DeferralLine: Record "Deferral Line";
        Period: Integer;
        PostingDate: Date;
    begin
        Clear(DeferralAmount);
        DeferralLine.SetRange("Deferral Doc. Type", "Deferral Document Type"::Purchase);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
        Period := 0;
        if DeferralLine.FindSet() then
            repeat
                if Period = 0 then
                    PostingDate := ReturnsDeferralStartDate
                else
                    PostingDate := SetDateDay(1, ReturnsDeferralStartDate);
                PostingDate := PeriodDate(PostingDate, Period);
                DeferralLine.TestField("Posting Date", PostingDate);
                DeferralAmount := DeferralAmount + DeferralLine.Amount;
                Period := Period + 1;
            until DeferralLine.Next() = 0;
    end;

    local procedure GetStartDate(DeferralStartOption: Enum "Deferral Calculation Start Date"; StartDate: Date) AdjustedStartDate: Date
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

    local procedure CreatePurchDocWithCurrencyAndLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PurchLineType: Enum "Purchase Line Type"; No: Code[20]; PostingDate: Date)
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchLineType, No, 2);
        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                begin
                    PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
                    PurchaseLine.Modify(true);
                end;
            PurchaseLine.Type::Item:
                if Item.Get(No) then begin
                    PurchaseLine.Validate("Direct Unit Cost", Item."Unit Cost");
                    PurchaseLine.Modify(true)
                end;
        end;
    end;

    local procedure VerifyGLForInvoice(DocNo: Code[20]; AccNo: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; DeferralSum: Decimal; PartialDeferral: Boolean)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GLSum: Decimal;
        NonDeferralAmt: Decimal;
        GLCount: Integer;
    begin
        GLCalcSum(DocNo, AccNo, PostingDate, PeriodDate, GLCount, GLSum, NonDeferralAmt);
        ValidateAccounts(DeferralCount, DeferralSum, GLCount, GLSum);
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        VerifyInvoiceVATGLEntryForPostingAccount(PurchInvLine, PartialDeferral);
    end;

    local procedure VerifyGLForCrMemo(DocNo: Code[20]; AccNo: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; DeferralSum: Decimal; PartialDeferral: Boolean)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        GLSum: Decimal;
        NonDeferralAmt: Decimal;
        GLCount: Integer;
    begin
        GLCalcSum(DocNo, AccNo, PostingDate, PeriodDate, GLCount, GLSum, NonDeferralAmt);
        ValidateAccounts(DeferralCount, DeferralSum, GLCount, GLSum);
        FindPurchCrMemoLine(PurchCrMemoLine, DocNo);
        VerifyCrMemoVATGLEntryForPostingAccount(PurchCrMemoLine, PartialDeferral);
    end;

    local procedure ValidateGLPurchAccount(DocNo: Code[20]; PurchAccount: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; PurchAmount: Decimal)
    var
        GLPurchAmount: Decimal;
        GLSum: Decimal;
        GLCount: Integer;
    begin
        GLCalcSum(DocNo, PurchAccount, PostingDate, PeriodDate, GLCount, GLSum, GLPurchAmount);
        ValidateAccounts(DeferralCount, PurchAmount, GLCount, Abs(GLPurchAmount));
    end;

    local procedure ValidateAccounts(DeferralCount: Integer; DeferralAmount: Decimal; GLCount: Integer; GLAmt: Decimal)
    begin
        Assert.AreEqual(DeferralCount, GLCount, 'An incorrect number of lines was posted');
        Assert.AreEqual(DeferralAmount, GLAmt, 'An incorrect Amount was posted for purchase');
    end;

    local procedure CreatePurchDocAndDeferralTemplateCode(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var DeferralTemplateCode: Code[10]; DocType: Enum "Purchase Document Type")
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount);
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          DocType, PurchaseLine.Type::"G/L Account", GLAccount."No.", SetDateDay(1, WorkDate()));
        DeferralTemplateCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);
    end;

    local procedure VerifyPostedInvoiceDeferralsAndGL(DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; AmtToDefer: Decimal; AmtToDeferLCY: Decimal; Day: Integer; NoOfPeriods: Integer; GLRecordCount: Integer)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // The deferrals were moved to the Posted Invoice Line and Posted Deferral tables
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        PurchInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, SetDateDay(Day, WorkDate()), AmtToDefer, AmtToDeferLCY, NoOfPeriods);

        // The correct deferrals were posted to GL
        VerifyGLForInvoice(
          DocNo, AccNo, SetDateDay(Day, WorkDate()), PeriodDate(SetDateDay(Day, WorkDate()), NoOfPeriods), GLRecordCount, 0, false);
    end;

    local procedure VerifyPostedInvoiceDeferralsAndGLWithPurchAmt(DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; PurchAccount: Code[20]; AmtToDefer: Decimal; AmtToDeferLCY: Decimal; Day: Integer; NoOfPeriods: Integer; GLRecordCount: Integer; PurchRecordCount: Integer; PurchAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GLPurchAmount: Decimal;
        GLSum: Decimal;
        GLCount: Integer;
    begin
        // The deferrals were moved to the Purchase Invoice Line and Posted Deferral tables
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        PurchInvLine.TestField("Deferral Code", DeferralTemplateCode);
        ValidatePostedDeferralSchedule(PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, SetDateDay(Day, WorkDate()), AmtToDefer, AmtToDeferLCY, NoOfPeriods);

        // The amount not deferred was posted to GL for the purchase account
        GLCalcPurchAmount(DocNo, PurchAccount,
          SetDateDay(Day, WorkDate()), PeriodDate(SetDateDay(Day, WorkDate()), NoOfPeriods), GLCount, GLSum, GLPurchAmount);
        Assert.AreEqual(PurchRecordCount, GLCount, 'An incorrect number of lines was posted');
        Assert.AreEqual(PurchAmount, Abs(GLPurchAmount), 'An incorrect Amount was posted for purchases');

        // The deferrals account was
        VerifyGLForInvoice(
          DocNo, AccNo, SetDateDay(Day, WorkDate()), PeriodDate(SetDateDay(Day, WorkDate()), NoOfPeriods), GLRecordCount, 0, true);
    end;

    local procedure GLCalcPurchAmount(DocNo: Code[20]; AccNo: Code[20]; StartPostDate: Date; EndPostDate: Date; var RecCount: Integer; var AccAmt: Decimal; var PurchAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(AccAmt);
        Clear(GLEntry);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", StartPostDate, EndPostDate);
        RecCount := GLEntry.Count();
        if GLEntry.Find('-') then begin
            PurchAmt := GLEntry.Amount;
            repeat
                AccAmt := AccAmt + GLEntry.Amount;
            until GLEntry.Next() = 0;
        end;
    end;

    local procedure UpdateQtyToReceiveInvoiceOnPurchLine(var PurchLine: Record "Purchase Line"; Quantity: Decimal; QuantityToReceive: Decimal; QuantityToInvoice: Decimal)
    begin
        PurchLine.Validate(Quantity, Quantity);
        PurchLine.Validate("Qty. to Receive", QuantityToReceive);
        PurchLine.Validate("Qty. to Invoice", QuantityToInvoice);
        PurchLine.Modify(true);
    end;

    local procedure GetInvoiceQtyAmtToDefer(var PurchLine: Record "Purchase Line"; DeferralAmount: Decimal; CurrencyCode: Code[20]): Decimal
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
            PurchLine."Qty. to Invoice" / PurchLine.Quantity, Currency."Amount Rounding Precision"));
    end;

    local procedure RunBatchPostReport(var NewPostingDate: Date; PostingDate: Date; ConfirmValue: Boolean; DocNo1: Code[20]; DocNo2: Code[20]; ReportID: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        NewPostingDate := CalcDate('<+1M>', PostingDate);
        SetupBatchPostingReportParameters(NewPostingDate, ConfirmValue);
        Commit();
        PurchaseHeader.SetFilter("No.", '%1|%2', DocNo1, DocNo2);
        REPORT.Run(ReportID, true, false, PurchaseHeader);
    end;

    local procedure SetupBatchPostingReportParameters(PostingDate: Date; ConfirmValue: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(0); // confirm counter
        LibraryVariableStorage.Enqueue(ConfirmValue);
    end;

    local procedure VerifyDeferralHeaderLinesRemoved(DocType: Option; DocNo: Code[20]; LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        asserterror DeferralHeader.Get("Deferral Document Type"::Purchase, '', '', DocType, DocNo, LineNo);
        asserterror LibraryERM.FindDeferralLine(DeferralLine, "Deferral Document Type"::Purchase, '', '', DocType, DocNo, LineNo);
    end;

    local procedure VerifyPurchGLDeferralAccount(PurchaseLine: Record "Purchase Line"; PostedDocNo: Code[20]; ExpectedAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(
          GLEntry,
          PostedDocNo,
          GetPurchAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          GLEntry."Gen. Posting Type"::Purchase);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmt);
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
            GLEntry.SetFilter(Amount, '<%1', 0);
            GLEntry.SetRange("Posting Date", TempPostedDeferralLine."Posting Date");
            GLEntry.FindFirst();
            GLEntry.TestField(Amount, -TempPostedDeferralLine.Amount);
        until TempPostedDeferralLine.Next() = 0;
    end;

    local procedure VerifyDeferralScheduleAmounts(PurchaseLine: Record "Purchase Line")
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralAmount: Decimal;
        CostOfDay: Decimal;
        PeriodAmt: Decimal;
        TotalAmt: Decimal;
        TotalDays: Integer;
        i: Integer;
    begin
        DeferralHeader.Get(
          "Deferral Document Type"::Purchase, '', '',
          PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        DeferralAmount := PurchaseLine.GetDeferralAmount();
        TotalDays :=
          CalcDate(StrSubstNo('<%1M>', DeferralHeader."No. of Periods"), DeferralHeader."Start Date") - DeferralHeader."Start Date";
        CostOfDay := DeferralAmount / TotalDays;

        DeferralLine.SetRange("Document Type", PurchaseLine."Document Type");
        DeferralLine.SetRange("Document No.", PurchaseLine."Document No.");
        DeferralLine.FindSet();
        for i := 1 to DeferralHeader."No. of Periods" do begin
            PeriodAmt := Round((CalcDate('<CM>', DeferralLine."Posting Date") - DeferralLine."Posting Date" + 1) * CostOfDay);
            DeferralLine.TestField(Amount, PeriodAmt);
            TotalAmt += DeferralLine.Amount;
            DeferralLine.Next();
        end;
        DeferralLine.TestField(Amount, DeferralAmount - TotalAmt);
    end;

    local procedure VerifyInvoicePostedDeferrals(DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; NewPostDate: Date; AmtToDefer: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        ValidatePostedDeferralSchedule(
          PurchDocType::"Posted Invoice", DocNo,
          PurchInvLine."Line No.", DeferralTemplateCode, NewPostDate, AmtToDefer, AmtToDefer, 2);
        VerifyGLForInvoice(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(NewPostDate, 2), 3, 0, false);
    end;

    local procedure VerifyCrMemoPostedDeferrals(DocNo: Code[20]; DeferralTemplateCode: Code[10]; AccNo: Code[20]; NewPostDate: Date; AmtToDefer: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        FindPurchCrMemoLine(PurchCrMemoLine, DocNo);
        ValidatePostedDeferralSchedule(
          PurchDocType::"Posted Credit Memo", DocNo,
          PurchCrMemoLine."Line No.", DeferralTemplateCode, NewPostDate, AmtToDefer, AmtToDefer, 2);
        VerifyGLForCrMemo(DocNo, AccNo, SetDateDay(1, WorkDate()), PeriodDate(NewPostDate, 2), 3, 0, false);
    end;

    local procedure VerifyInvoicePostingDate(DocNo: Code[20]; PostingDate: Date)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocNo);
        PurchInvHeader.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyCrMemoPostingDate(DocNo: Code[20]; PostingDate: Date)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Get(DocNo);
        PurchCrMemoHdr.TestField("Posting Date", PostingDate);
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

    local procedure VerifyInvoiceVATGLEntryForPostingAccount(PurchInvLine: Record "Purch. Inv. Line"; PartialDeferral: Boolean)
    var
        GLEntry: Record "G/L Entry";
        DummyPurchInvLine: Record "Purch. Inv. Line";
        PairAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", PurchInvLine."Document No.");
        GLEntry.SetRange(
          "G/L Account No.",
          GetPurchAccountNo(PurchInvLine."Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group"));

        GLEntry.SetFilter("VAT Amount", '<>%1', 0);
        FilterInvoiceGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::Purchase, PurchInvLine);
        Assert.RecordCount(GLEntry, 1);
        // Verify paired GLEntry
        PairAmount := GetGLEntryPairAmount(GLEntry, PartialDeferral);
        GLEntry.SetFilter(Amount, '<%1', 0);
        FilterInvoiceGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::" ", DummyPurchInvLine);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PairAmount);
    end;

    local procedure VerifyCrMemoVATGLEntryForPostingAccount(PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PartialDeferral: Boolean)
    var
        GLEntry: Record "G/L Entry";
        DummyPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PairAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetRange("Document No.", PurchCrMemoLine."Document No.");
        GLEntry.SetRange(
          "G/L Account No.",
          GetPurchCrMemoAccountNo(PurchCrMemoLine."Gen. Bus. Posting Group", PurchCrMemoLine."Gen. Prod. Posting Group"));

        GLEntry.SetFilter("VAT Amount", '<>%1', 0);
        FilterCrMemoGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::Purchase, PurchCrMemoLine);
        Assert.RecordCount(GLEntry, 1);
        // Verify paired GLEntry
        PairAmount := GetGLEntryPairAmount(GLEntry, PartialDeferral);
        GLEntry.SetFilter(Amount, '>%1', 0);
        FilterCrMemoGLEntryGroups(GLEntry, GLEntry."Gen. Posting Type"::" ", DummyPurchCrMemoLine);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PairAmount);
    end;

    local procedure CreateResourceWithDefaultDeferralCode(var Resource: Record Resource)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate(
            "Default Deferral Template Code",
            CreateDeferralCode(DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Posting Date", 2));
        Resource.Modify(true);
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
    var
        NoOfPeriods: Variant;
    begin
        // Modal Page Handler.
        LibraryVariableStorage.Dequeue(NoOfPeriods);
        DeferralSchedule."No. of Periods".SetValue(NoOfPeriods);
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
    procedure UpdateStartDateOnDeferralScheduleModalPageHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        DeferralSchedule."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
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
    procedure BatchPostPurchaseInvoicesReportHandler(var BatchPostPurchaseInvoices: TestRequestPage "Batch Post Purchase Invoices")
    begin
        BatchPostPurchaseInvoices.ReplacePostingDate.SetValue(true);
        BatchPostPurchaseInvoices.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        BatchPostPurchaseInvoices.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchaseOrdersReportHandler(var BatchPostPurchaseOrders: TestRequestPage "Batch Post Purchase Orders")
    begin
        BatchPostPurchaseOrders.Receive.SetValue(true);
        BatchPostPurchaseOrders.Invoice.SetValue(true);
        BatchPostPurchaseOrders.ReplacePostingDate.SetValue(true);
        BatchPostPurchaseOrders.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        BatchPostPurchaseOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostPurchCreditMemosReportHandler(var BatchPostPurchCreditMemos: TestRequestPage "Batch Post Purch. Credit Memos")
    begin
        BatchPostPurchCreditMemos.ReplacePostingDate.SetValue(true);
        BatchPostPurchCreditMemos.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        BatchPostPurchCreditMemos.OK().Invoke();
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

