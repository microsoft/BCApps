codeunit 134806 "RED Test Unit for SalesPurDoc2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Revenue Expense Deferral]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalcMethod: Enum "Deferral Calculation Method";
        StartDate: Enum "Deferral Calculation Start Date";
        SalesDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Shipment,"Posted Invoice","Posted Credit Memo","Posted Return Receipt";
        PurchDocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Shipment,"Posted Invoice","Posted Credit Memo","Posted Return Receipt";
        isInitialized: Boolean;
        AllowPostedDocumentDeletionDate: Date;
        DialogTok: Label 'Dialog';
        DateOutOfBoundErr: Label 'The deferral schedule falls outside the accounting periods that have been set up for the company.';
        NoOfPeriodsErr: Label 'No. of Periods must not be %1 in Deferral Header', Comment = '%1 - No of periods';
        FieldErrorTok: Label 'NCLCSRTS:TableErrorStr';
        FieldErrorErr: Label 'Calc. Method must not be 4 in Deferral Template Deferral Code';

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteSalesPostedCreditMemoWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
        LineNo: Integer;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 127736] When a Posted Credit Memo is deleted, the deferrals are also deleted
        // Setup
        Initialize();
        PostingDate := SetDateDay(15, CalcDate('<-1M>', AllowPostedDocumentDeletionDate));
        LibrarySales.SetAllowDocumentDeletionBeforeDate(PostingDate + 1);

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, ItemNo, PostingDate);
        LineNo := SalesLine."Line No.";

        // [GIVEN] Document is posted the deferrals are also posted and moved to the Sales Credit Memo tables
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Posted Credit Memo is deleted
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        DocNo := SalesCrMemoHeader."No.";
        SalesCrMemoHeader."No. Printed" := 1;
        SalesCrMemoHeader.Delete(true);
        Commit(); // Required for the ASSERTERROR to Work

        // [THEN] The deferrals were removed also
        VerifyPostedDeferralScheduleDoesNotExist("Deferral Document Type"::Sales,
          SalesDocType::"Posted Credit Memo", DocNo, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteSalesPostedInvoiceWithDeferral()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
        LineNo: Integer;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 127736] When a Posted Invoice is deleted, the deferrals are also deleted
        Initialize();
        PostingDate := SetDateDay(1, WorkDate());
        LibrarySales.SetAllowDocumentDeletionBeforeDate(PostingDate + 1);

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, PostingDate);

        // [GIVEN] Document is posted the deferrals are also posted and moved to the Sales Invoice tables
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindSalesInvoiceLine(SalesInvLine, DocNo);
        LineNo := SalesInvLine."Line No.";

        // [WHEN] Delete the Posted sales invoice
        SalesInvHeader.Get(DocNo);
        SalesInvHeader."No. Printed" := 1;
        SalesInvHeader.Delete(true);
        Commit(); // Required for the ASSERTERROR to Work

        // [THEN] The deferrals are removed along with the posted sales invoice
        VerifyPostedDeferralScheduleDoesNotExist("Deferral Document Type"::Sales,
          SalesDocType::"Posted Invoice", DocNo, LineNo);
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleHandler')]
    [Scope('OnPrem')]
    procedure TestOpenSalesInvoiceDeferralSchedulePos()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        DeferralTemplateCode: Code[10];
    begin
        // [SCENARIO 127732] Entering a Sales Invoice on the Sales Invoice with GL Account allows editing of the deferral code and accessing schedule
        // Setup
        Initialize();
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        // [GIVEN] User has created a Sales Document with one line item for GL Account
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), SetDateDay(1, WorkDate()));
        DeferralTemplateCode := LibraryERM.CreateDeferralTemplateCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [THEN] Deferral Code can be entered for GL Account
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(SalesLine.GetDeferralAmount());

        // [THEN] Deferral Schedule can be opened for GL Account
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines.DeferralSchedule.Invoke();
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePurchPostedCreditMemoWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
        LineNo: Integer;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 127772] When a Posted Credit Memo is deleted, the deferrals are also deleted
        // Setup
        Initialize();
        PostingDate := SetDateDay(15, WorkDate());
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(PostingDate + 1);

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::Item, ItemNo, PostingDate);
        LineNo := PurchaseLine."Line No.";

        // [GIVEN] Document is posted the deferrals are also posted and moved to the Purchase Credit Memo tables
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Posted Credit Memo is deleted
        PurchCrMemoHdr.Get(DocNo);
        PurchCrMemoHdr."No. Printed" := 1;
        PurchCrMemoHdr.Delete(true);
        Commit(); // Required for the ASSERTERROR to Work

        // [THEN] The deferrals were removed also
        VerifyPostedDeferralScheduleDoesNotExist("Deferral Document Type"::Purchase,
          PurchDocType::"Posted Credit Memo", DocNo, LineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePurchPostedInvoiceWithDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
        LineNo: Integer;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 127772] When a Posted Invoice is deleted, the deferrals are also deleted
        Initialize();
        PostingDate := SetDateDay(1, WorkDate());
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(PostingDate + 1);

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, PostingDate);

        // [GIVEN] Document is posted the deferrals are also posted and moved to the Purchase Invoice tables
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchInvoiceLine(PurchInvLine, DocNo);
        LineNo := PurchInvLine."Line No.";

        // [WHEN] Delete the Posted purchase invoice
        PurchInvHeader.Get(DocNo);
        PurchInvHeader."No. Printed" := 1;
        PurchInvHeader.Delete(true);
        Commit(); // Required for the ASSERTERROR to Work

        // [THEN] The deferrals are removed along with the posted purchase invoice
        VerifyPostedDeferralScheduleDoesNotExist("Deferral Document Type"::Purchase,
          PurchDocType::"Posted Invoice", DocNo, LineNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestUpdatePostDateOnSalesInvoiceWithDeferralRolldown()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posting Date]
        // [SCENARIO 145395] When Posting Date is changed on document header, and roll down confirmed, the deferrals are updated
        // Setup
        Initialize();

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(15, WorkDate()));

        // [GIVEN] Posting date is changed on sales header
        SalesHeader.Validate("Posting Date", SetDateDay(1, WorkDate()));

        // [WHEN] Answer 'Yes' to the confirmation dialog

        // [THEN] The deferrals were updated using the new date
        VerifyDeferralSchedule(
          "Deferral Document Type"::Sales,
          SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SetDateDay(1, WorkDate()), SalesLine.GetDeferralAmount(), 3);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestUpdatePostDateOnSalesInvoiceWithNoDeferralRolldown()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Posting Date]
        // [SCENARIO 145395] When Posting Date is changed on document header with no rolldown selected, the deferrals are not updated
        // Setup
        Initialize();

        // [GIVEN] User has assigned a default deferral code to an Item
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 3);

        // [GIVEN] Creating Sales Line for Item should default deferral code
        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(25, WorkDate()));

        // [GIVEN] Posting Date is changed on sales header
        SalesHeader.Validate("Posting Date", SetDateDay(1, WorkDate()));

        // [WHEN] Answer 'No' to the confirmation dialog

        // [THEN] The deferrals are not updated
        VerifyDeferralSchedule("Deferral Document Type"::Sales,
          SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
          DeferralTemplateCode, SetDateDay(25, WorkDate()), SalesLine.GetDeferralAmount(), 3);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestUpdatePostDateOnPurchInvoiceWithDeferralRolldown()
    var
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Posting Date]
        // [SCENARIO 145395] When Posting Date is changed on document header, and roll down confirmed, the deferrals are updated
        Initialize();

        // [GIVEN] User has assigned a default deferral code to an Item
        // [GIVEN] Creating Purchase Line for Item should default deferral code
        // [GIVEN] Posting Date is changed on purchase header
        SetupPurchaseHeader(PurchaseLine, DeferralTemplateCode, 21);

        // [WHEN] Answer 'Yes' to the confirmation dialog

        // [THEN] The deferrals are updated using the new date
        VerifyDeferralSchedule(
          "Deferral Document Type"::Purchase,
          PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
          DeferralTemplateCode, SetDateDay(1, WorkDate()), PurchaseLine.GetDeferralAmount(), 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestUpdatePostDateOnPurchInvoiceNoWithDeferraRolldown()
    var
        PurchaseLine: Record "Purchase Line";
        DeferralTemplateCode: Code[10];
    begin
        // [FEATURE] [Purchase] [Posting Date]
        // [SCENARIO 145395] When Posting Date is changed on document header and rolldown not selected, the deferrals are not updated
        Initialize();

        // [GIVEN] User has assigned a default deferral code to an Item
        // [GIVEN] Creating Purchase Line for Item should default deferral code
        // [GIVEN] Posting Date is changed on purchase header
        SetupPurchaseHeader(PurchaseLine, DeferralTemplateCode, 28);

        // [WHEN] Answer 'No' to the confirmation dialog

        // [THEN] The deferrals are not updated with the new date
        VerifyDeferralSchedule("Deferral Document Type"::Purchase,
          PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.",
          DeferralTemplateCode, SetDateDay(28, WorkDate()), PurchaseLine.GetDeferralAmount(), 2);
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCalcDeferralScheduleOutOfPeriod()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AccountingPeriod: Record "Accounting Period";
    begin
        // [SCENARIO 376479] System does not allow calculate schedule for Sales Line on date before earliest Accounting Period
        // [FEATURE] [Sales]
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithDeferralCode(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);

        AccountingPeriod.FindFirst();
        LibraryVariableStorage.Enqueue(
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'Y>', AccountingPeriod."Starting Date"));

        asserterror OpenSalesDeferralSchedule(SalesLine, SalesHeader);

        Assert.ExpectedErrorCode(DialogTok);
        Assert.ExpectedError(DateOutOfBoundErr);
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCalcDeferralScheduleOutOfPeriod()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AccountingPeriod: Record "Accounting Period";
    begin
        // [SCENARIO 376479] System does not allow calculate schedule for Purchase Line on date before earliest Accounting Period
        // [FEATURE] [Purchases]
        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithDeferralCode(), LibraryRandom.RandInt(100));

        AccountingPeriod.FindFirst();
        LibraryVariableStorage.Enqueue(
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'Y>', AccountingPeriod."Starting Date"));

        asserterror OpenPurchaseDeferralSchedule(PurchaseLine, PurchaseHeader);

        Assert.ExpectedErrorCode(DialogTok);
        Assert.ExpectedError(DateOutOfBoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithDeferralSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 376902] Posted Sales Order creates VAT Entry with non-zero Base and Amount
        Initialize();

        // [GIVEN] Deferral Template "DT"
        CreateItemWithDefaultDeferralCode(
          DeferralTemplateCode, ItemNo, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Sales Order where "Sales Line"."Deferrral Code" = "DT", "Sales Line".Amount = 100 and "Sales Line"."VAT %" = 10%
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, LibraryRandom.RandInt(10), '', 0D);

        // [WHEN] Post Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "VAT Entry".Base = -100
        // [THEN] "VAT Entry".Amount = -10
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyVATEntry(-SalesLine.Amount, -Round(SalesLine.Amount * VATPostingSetup."VAT %" / 100), DocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithDeferralSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        VATPostingSetup: Record "VAT Posting Setup";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO 376902] Posted Purchase Order creates VAT Entry with non-zero Base and Amount
        Initialize();

        // [GIVEN] Deferral Template "DT"
        CreateItemWithDefaultDeferralCode(
          DeferralTemplateCode, ItemNo, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Sales Order where "Sales Line"."Deferral Code" = "DT", "Sales Line".Amount = 100 and "Sales Line"."VAT %" = 10%
        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          PurchaseLine.Type::Item, ItemNo, SetDateDay(15, WorkDate()));

        // [WHEN] Post Sales Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] "VAT Entry".Base = 100
        // [THEN] "VAT Entry".Amount = 10
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyVATEntry(PurchaseLine.Amount, Round(PurchaseLine.Amount * VATPostingSetup."VAT %" / 100), DocNo);
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleUpdateNoOfPeriodslModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesChangeNoOfPeriodsOnDeferralSchedule()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DeferralTemplate: Record "Deferral Template";
        NoOfPeriods: Integer;
        Offset: Integer;
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 376902] Do not allow to change "No. of Periods" without deferral reschedule
        Initialize();

        // [GIVEN] Sales Order with Deferral Code in Sales Line and calculated Deferral Schedule
        SalesChangeNoOfPeriodsInitScenario(
          NoOfPeriods, Offset, DeferralTemplate."Calc. Method"::"Equal per Period", SalesLine, SalesHeader);

        // [WHEN] Change "No. Of Periods" in Deferral Schedule without rescheduling
        OpenSalesDeferralSchedule(SalesLine, SalesHeader);

        // [THEN] Error occured on closing Deferral Schedule
        Assert.ExpectedMessage(StrSubstNo(NoOfPeriodsErr, NoOfPeriods + Offset), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleUpdateNoOfPeriodslModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseChangeNoOfPeriodsOnDeferralSchedule()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        NoOfPeriods: Integer;
        Offset: Integer;
    begin
        // [FEATURE] [UI] [Purchase]
        // [SCENARIO 376902] Do not allow to change "No. of Periods" without deferral reschedule
        Initialize();

        // [GIVEN] Purchase Order with Deferral Code in Purchase Line and calculated Deferral Schedule
        PurchaseChangeNoOfPeriodsInitScenario(
          NoOfPeriods, Offset, DeferralTemplate."Calc. Method"::"Equal per Period", PurchaseLine, PurchaseHeader);

        // [WHEN] Change "No. Of Periods" in Deferral Schedule without rescheduling
        OpenPurchaseDeferralSchedule(PurchaseLine, PurchaseHeader);

        // [THEN] Error occured on closing Deferral Schedule
        Assert.ExpectedMessage(StrSubstNo(NoOfPeriodsErr, NoOfPeriods + Offset), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsEqualPerPeriod()
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calculate Number of Periods to be generated when "Calc. Method" = "Equal per Period"
        NoOfPeriods := LibraryRandom.RandInt(12);

        Assert.AreEqual(
          NoOfPeriods,
          DeferralUtilities.CalcDeferralNoOfPeriods(DeferralTemplate."Calc. Method"::"Equal per Period", NoOfPeriods, WorkDate()),
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsDaysPerPeriodStartDateEqual()
    var
        DeferralTemplate: Record "Deferral Template";
        AccountingPeriod: Record "Accounting Period";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calculate Number of Periods to be generated when "Calc. Method" = "Days Per Period" and "Start Date" = "Accounting Period"."Starting Date"
        NoOfPeriods := LibraryRandom.RandInt(12);
        AccountingPeriod.FindFirst();

        Assert.AreEqual(
          NoOfPeriods,
          DeferralUtilities.CalcDeferralNoOfPeriods(
            DeferralTemplate."Calc. Method"::"Days per Period", NoOfPeriods, AccountingPeriod."Starting Date"),
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsDaysPerPeriodStartDateNotEqual()
    var
        DeferralTemplate: Record "Deferral Template";
        AccountingPeriod: Record "Accounting Period";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calculate Number of Periods to be generated when "Calc. Method" = "Days Per Period" and "Start Date" <> "Accounting Period"."Starting Date"
        NoOfPeriods := LibraryRandom.RandInt(12);
        AccountingPeriod.FindFirst();

        Assert.AreEqual(
          NoOfPeriods + 1,
          DeferralUtilities.CalcDeferralNoOfPeriods(
            DeferralTemplate."Calc. Method"::"Days per Period", NoOfPeriods, AccountingPeriod."Starting Date" - 1),
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsStraightLineStartDateEqual()
    var
        DeferralTemplate: Record "Deferral Template";
        AccountingPeriod: Record "Accounting Period";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calculate Number of Periods to be generated when "Calc. Method" = "Straight-Line" and "Start Date" = "Accounting Period"."Starting Date"
        NoOfPeriods := LibraryRandom.RandInt(12);
        AccountingPeriod.FindFirst();

        Assert.AreEqual(
          NoOfPeriods,
          DeferralUtilities.CalcDeferralNoOfPeriods(
            DeferralTemplate."Calc. Method"::"Straight-Line", NoOfPeriods, AccountingPeriod."Starting Date"),
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsStraightLineStartDateNotEqual()
    var
        DeferralTemplate: Record "Deferral Template";
        AccountingPeriod: Record "Accounting Period";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calculate Number of Periods to be generated when "Calc. Method" = "Straight-Line" and "Start Date" <> "Accounting Period"."Starting Date"
        NoOfPeriods := LibraryRandom.RandInt(12);
        AccountingPeriod.FindFirst();

        Assert.AreEqual(
          NoOfPeriods + 1,
          DeferralUtilities.CalcDeferralNoOfPeriods(
            DeferralTemplate."Calc. Method"::"Straight-Line", NoOfPeriods, AccountingPeriod."Starting Date" - 1),
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsUserDefined()
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralUtilities: Codeunit "Deferral Utilities";
        NoOfPeriods: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Calculate Number of Periods to be generated when "Calc. Method" = "User Defined"
        NoOfPeriods := LibraryRandom.RandInt(12);

        Assert.AreEqual(
          NoOfPeriods,
          DeferralUtilities.CalcDeferralNoOfPeriods(DeferralTemplate."Calc. Method"::"User-Defined", NoOfPeriods, WorkDate()),
          '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CalcDeferralNoOfPeriodsErrorOnUknownCalcMethod()
    var
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Throw error when unhandled "Calc. Method" passed
        asserterror DeferralUtilities.CalcDeferralNoOfPeriods("Deferral Calculation Method".FromInteger(4), LibraryRandom.RandInt(12), WorkDate());

        Assert.ExpectedErrorCode(FieldErrorTok);
        Assert.ExpectedError(FieldErrorErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicingOfPartialDeferralWithReverseChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT]
        // [SCENARIO 380850] VAT Entries of posted Purchase Invoice with partial deferral and reverse charge VAT match VAT Posting Setup
        Initialize();

        // We remove any existing VAT entries, as this test modifies the VAT posting SETUP.
        VATEntry.DeleteAll();

        // [GIVEN] Purchase Invoice with Deferral % = 50 and Reverse Charge VAT 25% has Amount = 1000
        CreatePurchDocWithLineRevCharge(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithPartialDeferralCode(LibraryRandom.RandIntInRange(20, 30)), SetDateDay(1, WorkDate()));

        // [WHEN] Post Purchase Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] VAT Entry has Base = 1000, Amount = 250
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyVATEntry(PurchaseLine.Amount, Round(PurchaseLine.Amount * VATPostingSetup."VAT %" / 100), DocNo);

        // We remove any existing VAT entries, as this test modifies the VAT posting SETUP.
        VATEntry.DeleteAll();
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicingOfPartialDeferralWithReverseChargeVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Reverse Charge VAT]
        // [SCENARIO 380850] VAT Entries of posted Sales Invoice with partial deferral and reverse charge VAT match VAT Posting Setup
        Initialize();

        // We remove any existing VAT entries, as this test modifies the VAT posting SETUP.
        VATEntry.DeleteAll();

        // [GIVEN] Sales Invoice with Deferral % = 50 and Reverse Charge VAT 25% has Amount = 1000
        CreateSalesDocWithLineRevCharge(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          SalesLine.Type::"G/L Account",
          CreateGLAccountWithPartialDeferralCode(LibraryRandom.RandIntInRange(20, 30)), SetDateDay(1, WorkDate()));

        // [WHEN] Post Sales Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT Entry has Base = -1000, Amount = 0
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyVATEntry(-SalesLine.Amount, 0, DocNo);

        // We remove any existing VAT entries, as this test modifies the VAT posting SETUP.
        VATEntry.DeleteAll();
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicingOfDeferralWithLCYAndRounding()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        CurrencyCode: Code[10];
        ExchRate: Decimal;
    begin
        // [FEATURE] [Purchase] [Currency]
        // [SCENARIO 203345] Posting of Purchase Invoice with Currency when deferral lines generate rounding
        Initialize();

        // [GIVEN] User-defined Deferral Template for 3 periods
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"User-Defined", DeferralTemplate."Start Date"::"Posting Date", 3);

        // [GIVEN] Purchase Invoice with Currency Factor = 57.31123
        ExchRate := 57.31123;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 100 / ExchRate, 100 / ExchRate);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 5, 10));
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Posting Description", '0123456789');
        PurchaseHeader.Modify(true);

        // [GIVEN] Purchase Line 1 with Amount = 1000, VAT 19% where Deferral Schedule amounts are 555.55, 333.33, 111.12
        // [GIVEN] Description of each def.period is matched to Line order/Def.Line order 11,12,13 filled with '0' to the end of the line like '110000000...'
        CreateGLAccountWithVATPostSetup(GLAccount, PurchaseHeader."VAT Bus. Posting Group", 19);
        CreatePurchLineWithUserDefinedDeferralSchedule(
          PurchaseLine, PurchaseHeader, GLAccount."No.", DeferralTemplateCode, 555.55, 333.33, 111.12, 1);
        // [GIVEN] Purchase Line 2 with Amount = 2000, VAT 19%, where Deferral Schedule amounts are 666.66, 555.55, 777.79
        // [GIVEN] Description of each def.period is matched to Line order/Def.Line order 21,22,23 filled with '0' to the end of the line like '210000000...'
        GLAccount."No." := LibraryUtility.GenerateGUID();
        GLAccount.Insert();
        CreatePurchLineWithUserDefinedDeferralSchedule(
          PurchaseLine, PurchaseHeader, GLAccount."No.", DeferralTemplateCode, 666.66, 555.55, 777.79, 2);

        // [WHEN] Post Purchase Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Rounded G/L Entry has Description '0123456789' and Amount 0.01
        // [THEN] G/L Entry for 1st period of 2nd purchase line has Description '21000000000000000000000000000000000000000000000000' and Amount 382.07
        // [THEN] Deferral G/L Entry for 1st period of 2nd purchase line has Description '21000000000000000000000000000000000000000000000000' and Amount -382.07
        // [THEN] G/L Entry for 2nd purchase line has Description '0123456789' and Amount 1146.22
        // [THEN] Initial Deferral G/L Entry for document has Description '0123456789' and Amount 1719.33
        DeferralTemplate.Get(DeferralTemplateCode);
        VerifyRoundedDeferralGLEntries(
          DocNo, PurchaseHeader."Posting Date", GLAccount."No.", DeferralTemplate."Deferral Account",
          PurchaseHeader."Posting Description",
          '2100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
          Round(666.66 * ExchRate / 100), Round(2000 * ExchRate / 100),
          Round(3000 * ExchRate / 100) - LibraryERM.GetAmountRoundingPrecision(), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicingOfDeferralWithLCYAndRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
        DocNo: Code[20];
        CurrencyCode: Code[10];
        ExchRate: Decimal;
    begin
        // [FEATURE] [Sales] [Currency]
        // [SCENARIO 203345] Posting of Sales Invoice with Currency when deferral lines generate rounding
        Initialize();

        // [GIVEN] User-defined Deferral Template for 3 periods
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"User-Defined", DeferralTemplate."Start Date"::"Posting Date", 3);

        // [GIVEN] Sales Invoice with Currency Factor = 57.31123
        ExchRate := 57.31123;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 100 / ExchRate, 100 / ExchRate);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDateFromInRange(CalcDate('<CM>', WorkDate()), 5, 10));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Posting Description", '0123456789');
        SalesHeader.Modify(true);

        // [GIVEN] Sales Line 1 with Amount = 1000, VAT 19%, where Deferral Schedule amounts are 555.55, 333.33, 111.12
        // [GIVEN] Description of each def.period is matched to Line order/Def.Line order 11,12,13 filled with '0' to the end of the line like '110000000...'
        CreateGLAccountWithVATPostSetup(GLAccount, SalesHeader."VAT Bus. Posting Group", 19);
        CreateSalesLineWithUserDefinedDeferralSchedule(
          SalesLine, SalesHeader, GLAccount."No.", DeferralTemplateCode, 555.55, 333.33, 111.12, 1);
        // [GIVEN] Sales Line 2 with Amount = 2000, VAT 19%, where Deferral Schedule amounts are 666.66, 555.55, 777.79
        // [GIVEN] Description of each def.period is matched to Line order/Def.Line order 21,22,23 filled with '0' to the end of the line like '210000000...'
        GLAccount."No." := LibraryUtility.GenerateGUID();
        GLAccount.Insert();
        CreateSalesLineWithUserDefinedDeferralSchedule(
          SalesLine, SalesHeader, GLAccount."No.", DeferralTemplateCode, 666.66, 555.55, 777.79, 2);

        // [WHEN] Post Sales Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Rounded G/L Entry has Description '0123456789' and Amount -0.01
        // [THEN] G/L Entry for 1st period of 2nd sales line has Description '21000000000000000000000000000000000000000000000000' and Amount -382.07
        // [THEN] Deferral G/L Entry for 1st period of 2nd sales line has Description '21000000000000000000000000000000000000000000000000' and Amount 382.07
        // [THEN] G/L Entry for 2nd sales line has Description '0123456789' and Amount -1146.22
        // [THEN] Initial Deferral G/L Entry for document has Description '0123456789' and Amount -1719.33
        DeferralTemplate.Get(DeferralTemplateCode);
        VerifyRoundedDeferralGLEntries(
          DocNo, SalesHeader."Posting Date", GLAccount."No.", DeferralTemplate."Deferral Account",
          SalesHeader."Posting Description",
          '2100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
          Round(666.66 * ExchRate / 100),
          Round(2000 * ExchRate / 100), Round(3000 * ExchRate / 100) - LibraryERM.GetAmountRoundingPrecision(), -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameDeferralCodeInPurchaseInvoiceWithTwoLines()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SourceCodeSetup: Record "Source Code Setup";
        TempGLEntry: Record "G/L Entry" temporary;
        DeferralTemplateCode: Code[10];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 273428] Post Purchase Invoice with two lines and the same deferral code
        Initialize();

        // [GIVEN] Deferral Template of method "Straight-Line" with "Deferral %" = 30 and Deferral Account = "DefAcc"
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Beginning of Next Period", 1);
        DeferralTemplate.Get(DeferralTemplateCode);
        DeferralTemplate.Validate("Deferral %", LibraryRandom.RandIntInRange(20, 30));
        DeferralTemplate.Modify(true);

        // [GIVEN] Purchase Invoice with two lines of G/L Account "GL1" and "GL2" and amounts = 100 and 200 respectively on 15.01.18
        // [GIVEN] Amount to Defer = (100 + 200) * 30% = 90
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreatePurchLineWithGLAccount(PurchaseLine, PurchaseHeader, LibraryERM.CreateGLAccountWithPurchSetup(), DeferralTemplateCode);
        CreatePurchLineWithGLAccount(PurchaseLine, PurchaseHeader, LibraryERM.CreateGLAccountWithPurchSetup(), DeferralTemplateCode);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            FillTempAmountLines(TempGLEntry, PurchaseLine."Line No.", PurchaseLine."No.", PurchaseLine."Line Amount");
        until PurchaseLine.Next() = 0;

        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Deferral amounts posted on 15.01.18:
        // [THEN] "DefAcc" has Amount 90; "GL1" has Amount 70; "GL2" has Amount 140;
        // [THEN] Deferral amounts posted on deferral date 01.02.18 (Beginning of Next Period):
        // [THEN] "DefAcc" has Amount -90; "GL1" has Amount 30; "GL2" has Amount 60;
        // [THEN] Deferral entries has marked with deferral code from Source Code Setup (TFS 422924)
        SourceCodeSetup.Get();
        VerifyDeferralGLEntries(
          TempGLEntry,
          DocumentNo, PurchaseHeader."Posting Date", DeferralTemplate."Deferral Account", SourceCodeSetup."Purchase Deferral", 15, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameDeferralCodeInSalesInvoiceWithTwoLines()
    var
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SourceCodeSetup: Record "Source Code Setup";
        TempGLEntry: Record "G/L Entry" temporary;
        DeferralTemplateCode: Code[10];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 273428] Post Sales Invoice with two lines and the same deferral code
        Initialize();

        // [GIVEN] Deferral Template of method "Straight-Line" with "Deferral %" = 50 and Deferral Account = "DefAcc"
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Beginning of Next Period", 1);
        DeferralTemplate.Get(DeferralTemplateCode);
        DeferralTemplate.Validate("Deferral %", LibraryRandom.RandIntInRange(20, 30));
        DeferralTemplate.Modify(true);

        // [GIVEN] Sales Invoice with two lines of G/L Account "GL1" and "GL2" and amounts = 100 and 200 respectively on 15.01.18
        // [GIVEN] Amount to Defer = (100 + 200) * 30% = 90
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, LibraryERM.CreateGLAccountWithSalesSetup(), DeferralTemplateCode);
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, LibraryERM.CreateGLAccountWithSalesSetup(), DeferralTemplateCode);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            FillTempAmountLines(TempGLEntry, SalesLine."Line No.", SalesLine."No.", SalesLine."Line Amount");
        until SalesLine.Next() = 0;

        // [WHEN] Post Sales Invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Deferral amounts posted on 15.01.18:
        // [THEN] "DefAcc" has Amount -90; "GL1" has Amount -70; "GL2" has Amount -140;
        // [THEN] Deferral amounts posted on deferral date 01.02.18 (Beginning of Next Period):
        // [THEN] "DefAcc" has Amount 90; "GL1" has Amount -30; "GL2" has Amount -60;
        // [THEN] Deferral entries has marked with deferral code from Source Code Setup (TFS 422924)
        SourceCodeSetup.Get();
        VerifyDeferralGLEntries(
          TempGLEntry,
          DocumentNo, SalesHeader."Posting Date", DeferralTemplate."Deferral Account", SourceCodeSetup."Sales Deferral", 15, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseFCYDeferralsWithDimensions()
    var
        DeferralTemplate: Record "Deferral Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Dimension: Record Dimension;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        VATProdPostGr: Code[20];
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        ExchRate: Decimal;
    begin
        // [FEATURE] [Purchase] [Currency] [Dimensions]
        // [SCENARIO 281617] Deferral posting of FCY purchase invoice of four lines with two dimensions and no VAT
        Initialize();

        // [GIVEN] Deferral template with Deferral = 100%, No of Periods = 1, Calc. Method = Beginning of Next Period
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 1);

        // [GIVEN] Purchase invoice with Currency Factor = 0.125001734184240
        ExchRate := 0.12500173418424;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        // [GIVEN] Item "A" with Quantity = 1, Direct Unit Cost = 931.64, Dimension = "Dim1"
        // [GIVEN] Item "B" with Quantity = 1, Direct Unit Cost = 44.70, Dimension = "Dim2"
        // [GIVEN] Item "C" with Quantity = 1, Direct Unit Cost = 868.30, Dimension = "Dim1"
        // [GIVEN] Item "B" with Quantity = 1, Direct Unit Cost = 44.70, Dimension = "Dim2"
        VATProdPostGr := CreateVATProdPostingGroupNoVAT(PurchaseHeader."VAT Bus. Posting Group");
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
        ItemNo := CreateItemWithDefaultDimension(DimensionValue2);
        CreatePurchLineWithItem(
          PurchaseLine, PurchaseHeader, VATProdPostGr, CreateItemWithDefaultDimension(DimensionValue1), DeferralTemplateCode, 931.64);
        CreatePurchLineWithItem(
          PurchaseLine, PurchaseHeader, VATProdPostGr, ItemNo, DeferralTemplateCode, 44.7);
        CreatePurchLineWithItem(
          PurchaseLine, PurchaseHeader, VATProdPostGr, CreateItemWithDefaultDimension(DimensionValue1), DeferralTemplateCode, 868.3);
        CreatePurchLineWithItem(
          PurchaseLine, PurchaseHeader, VATProdPostGr, ItemNo, DeferralTemplateCode, 44.7);

        // [WHEN] Post Purchase Invoice
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Invoice amounts posted for "Dim1" = 14399.33
        // [THEN] Invoice amounts posted for "Dim2" = 715.18
        VerifyGLEntriesWithDimensions(
          InvoiceNo, VATProdPostGr,
          LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue1.Code), PurchaseLine."Dimension Set ID", 14399.33, 715.18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFCYDeferralsWithDimensions()
    var
        DeferralTemplate: Record "Deferral Template";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        VATProdPostGr: Code[20];
        ItemNo: Code[20];
        DeferralTemplateCode: Code[10];
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        ExchRate: Decimal;
    begin
        // [FEATURE] [Sales] [Currency] [Dimensions]
        // [SCENARIO 281617] Deferral posting of FCY sales invoice of four lines with two dimensions and no VAT
        Initialize();

        // [GIVEN] Deferral template with Deferral = 100%, No of Periods = 1, Calc. Method = Beginning of Next Period
        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Beginning of Next Period", 1);

        // [GIVEN] Sales invoice with Currency Factor = 0.125001734184240
        ExchRate := 0.12500173418424;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        // [GIVEN] Item "A" with Quantity = 1, Unit Price = 931.64, Dimension = "Dim1"
        // [GIVEN] Item "B" with Quantity = 1, Unit Price = 44.70, Dimension = "Dim2"
        // [GIVEN] Item "C" with Quantity = 1, Unit Price = 868.30, Dimension = "Dim1"
        // [GIVEN] Item "B" with Quantity = 1, Unit Price = 44.70, Dimension = "Dim2"
        VATProdPostGr := CreateVATProdPostingGroupNoVAT(SalesHeader."VAT Bus. Posting Group");
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension.Code);
        ItemNo := CreateItemWithDefaultDimension(DimensionValue2);
        CreateSalesLineWithItem(
          SalesLine, SalesHeader, VATProdPostGr, CreateItemWithDefaultDimension(DimensionValue1), DeferralTemplateCode, 931.64);
        CreateSalesLineWithItem(
          SalesLine, SalesHeader, VATProdPostGr, ItemNo, DeferralTemplateCode, 44.7);
        CreateSalesLineWithItem(
          SalesLine, SalesHeader, VATProdPostGr, CreateItemWithDefaultDimension(DimensionValue1), DeferralTemplateCode, 868.3);
        CreateSalesLineWithItem(
          SalesLine, SalesHeader, VATProdPostGr, ItemNo, DeferralTemplateCode, 44.7);

        // [WHEN] Post Sales Invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Invoice amounts posted for "Dim1" = -14399.33
        // [THEN] Invoice amounts posted for "Dim2" = -715.18
        VerifyGLEntriesWithDimensions(
          InvoiceNo, VATProdPostGr,
          LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue1.Code), SalesLine."Dimension Set ID", -14399.33, -715.18);
    end;

    [Test]
    [HandlerFunctions('DeferralScheduleModalPageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesLineShowDeferralScheduleUsesHeaderData()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 287104] When showing deferral schedule with SalesLine.ShowDeferralSchedule - header's Posting Date and Currency Code are used
        Initialize();

        // [GIVEN] Sales Document with Currency Code blank and Posting Date not equal to WORKDATE
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", WorkDate() - 1);
        SalesHeader.Modify();

        // [GIVEN] A currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] A deferral template
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Straight-Line",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandInt(10));

        // [GIVEN] Sales Line with Deferral code, and Currency Code not blank
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine."Deferral Code" := DeferralTemplate."Deferral Code";
        SalesLine."Currency Code" := Currency.Code;

        // [WHEN] ShowDeferralSchedule is called for Sales Line
        SalesLine.ShowDeferralSchedule();
        // UI Handled by DeferralScheduleModalPageHandlerOK

        DeferralHeader.Get(DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", 10000);

        // [THEN] DeferralHeader."Currency Code" = SalesHeader."Currency Code"
        DeferralHeader.TestField("Currency Code", SalesHeader."Currency Code");

        // [THEN] DeferralHeader."Start Date" = SalesHeader."Posting Date"
        DeferralHeader.TestField("Start Date", SalesHeader."Posting Date");
    end;

    [Test]
    procedure SalesLineUpdateDeferralScheduleCustomStartDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
        DeferralLine: Record "Deferral Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375050] System does not change custom Start Date in deferral schedule when a user updates amounts in document or journal line.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(3, 10));

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          LibraryRandom.RandIntInRange(5, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        SalesLine.Modify(true);

        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");

        DeferralHeader.Validate("Start Date", WorkDate() + 1);
        DeferralHeader.Modify(true);

        FindDeferralLine(DeferralLine, SalesLine);

        DeferralLine.Delete(true);
        DeferralLine."Posting Date" := WorkDate() + 1;
        DeferralLine.Insert(true);

        SalesLine.Validate(Quantity, SalesLine.Quantity + 1);
        SalesLine.Modify(true);

        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");

        DeferralHeader.TestField("Start Date", WorkDate() + 1);

        Clear(DeferralLine);
        DeferralLine.Reset();
        FindDeferralLine(DeferralLine, SalesLine);

        DeferralLine.TestField("Posting Date", WorkDate() + 1);
    end;

    [Test]
    procedure S463854_SalesLineUpdateDeferralScheduleCustomCalcMethodAndNoOfPeriods()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
    begin
        // [FEATURE] [Sales] [Sales Order] [Deferral Template] [Deferral Schedule]
        // [SCENARIO 463854] System does not change custom Calculation Method and No. of Periods in deferral schedule when a user updates amounts in document or journal line.
        Initialize();

        // [GIVEN] Create Deferral Template with "Calculation Method" = "Equal per Period" and No. of Periods between 3 and 10.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(3, 10));

        // [GIVEN] Create Sales Order with Deferral Template applied in line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
          LibraryRandom.RandIntInRange(5, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        SalesLine.Modify(true);

        // [GIVEN] Change "Calculation Method" to "Straight-Line" and "No. of Periods" to 12 in Deferral Schedule Header.
        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        DeferralHeader.Validate("Calc. Method", DeferralHeader."Calc. Method"::"Straight-Line");
        DeferralHeader.Validate("No. of Periods", 12);
        DeferralHeader.Modify(true);

        // [WHEN] Update Deferral Amounts recreates Defferal Header.
        SalesLine.UpdateDeferralAmounts();

        // [THEN] Customized values are kept. "Calculation Method" is equal to "Straight-Line" and "No. of Periods" is equal to to 12 in Deferral Schedule Header.
        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        DeferralHeader.TestField("Calc. Method", DeferralHeader."Calc. Method"::"Straight-Line");
        DeferralHeader.TestField("No. of Periods", 12);
    end;

    [Test]
    procedure S463854_PurchaseLineUpdateDeferralScheduleCustomCalcMethodAndNoOfPeriods()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
    begin
        // [FEATURE] [Purchase] [Purchase Order] [Deferral Template] [Deferral Schedule]
        // [SCENARIO 463854] System does not change custom Calculation Method and No. of Periods in deferral schedule when a user updates amounts in document or journal line.
        Initialize();

        // [GIVEN] Create Deferral Template with "Calculation Method" = "Equal per Period" and No. of Periods between 3 and 10.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"Equal per Period",
          DeferralTemplate."Start Date"::"Posting Date", LibraryRandom.RandIntInRange(3, 10));

        // [GIVEN] Create Purchase Order with Deferral Template applied in line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandIntInRange(5, 10));
        PurchaseLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Modify(true);

        // [GIVEN] Change "Calculation Method" to "Straight-Line" and "No. of Periods" to 12 in Deferral Schedule Header.
        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::Purchase, '', '', PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        DeferralHeader.Validate("Calc. Method", DeferralHeader."Calc. Method"::"Straight-Line");
        DeferralHeader.Validate("No. of Periods", 12);
        DeferralHeader.Modify(true);

        // [WHEN] Update Deferral Amounts recreates Defferal Header.
        PurchaseLine.UpdateDeferralAmounts();

        // [THEN] Customized values are kept. "Calculation Method" is equal to "Straight-Line" and "No. of Periods" is equal to to 12 in Deferral Schedule Header.
        DeferralHeader.Get(
          DeferralHeader."Deferral Doc. Type"::Purchase, '', '', PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        DeferralHeader.TestField("Calc. Method", DeferralHeader."Calc. Method"::"Straight-Line");
        DeferralHeader.TestField("No. of Periods", 12);
    end;

    local procedure Initialize()
    var
        AccountingPeriod: Record "Accounting Period";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RED Test Unit for SalesPurDoc2");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RED Test Unit for SalesPurDoc2");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        AllowPostedDocumentDeletionDate := LibraryERM.GetDeletionBlockedAfterDate();
        AccountingPeriodMgt.InitDefaultAccountingPeriod(AccountingPeriod, CalcDate('<-1M>', AllowPostedDocumentDeletionDate));
        if AccountingPeriod.Insert() then;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RED Test Unit for SalesPurDoc2");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
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
        DefaultDeferralCode := LibraryERM.CreateDeferralTemplateCode(DefaultCalcMethod, DefaultStartDate, DefaultNoOfPeriods);

        CreateItemWithUnitPrice(Item);
        Item.Validate("Default Deferral Template Code", DefaultDeferralCode);
        Item.Modify(true);
        ItemNo := Item."No.";
    end;

    local procedure CreateGLAccountWithDeferralCode(): Code[20]
    var
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Equal per Period", DeferralTemplate."Start Date"::"Posting Date", 12);

        GLAccount.Validate("Default Deferral Template Code", DeferralTemplateCode);
        GLAccount.Modify(true);

        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithPartialDeferralCode(DeferralPct: Decimal): Code[20]
    var
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralTemplateCode: Code[10];
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        DeferralTemplateCode :=
          LibraryERM.CreateDeferralTemplateCode(
            DeferralTemplate."Calc. Method"::"Straight-Line", DeferralTemplate."Start Date"::"Posting Date", 2);

        DeferralTemplate.Get(DeferralTemplateCode);
        DeferralTemplate.Validate("Deferral %", DeferralPct);
        DeferralTemplate.Modify(true);

        GLAccount.Validate("Default Deferral Template Code", DeferralTemplateCode);
        GLAccount.Modify(true);

        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithVATPostSetup(var GLAccount: Record "G/L Account"; VATBusPostGrCode: Code[20]; VATPct: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        CreateVATPostingSetup(VATBusPostGrCode, VATProductPostingGroup.Code, VATPct);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostGrCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);
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

    local procedure CreatePurchDocWithLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PurchLineType: Enum "Purchase Line Type"; No: Code[20]; PostingDate: Date)
    var
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
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
                    PurchaseLine.Modify(true);
                end;
        end;
    end;

    local procedure CreatePurchDocWithLineRevCharge(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PurchLineType: Enum "Purchase Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        UpdateVATPostSetupWithRevCharge(PurchaseHeader."VAT Bus. Posting Group", No);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchLineType, No, 2);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocWithLineRevCharge(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SalesLineType: Enum "Sales Line Type"; No: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        UpdateVATPostSetupWithRevCharge(SalesHeader."VAT Bus. Posting Group", No);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, No, 2);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLineWithUserDefinedDeferralSchedule(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DeferralTemplateCode: Code[10]; DefAmount1: Decimal; DefAmount2: Decimal; DefAmount3: Decimal; LineNo: Integer)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DefAmount1 + DefAmount2 + DefAmount3);
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);
        UpdateDeferralScheduleForLine(
          "Deferral Document Type"::Purchase, PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          PurchaseLine."Line No.", PurchaseHeader."Posting Date", DefAmount1, DefAmount2, DefAmount3, LineNo);
    end;

    local procedure CreateSalesLineWithUserDefinedDeferralSchedule(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; DeferralTemplateCode: Code[10]; DefAmount1: Decimal; DefAmount2: Decimal; DefAmount3: Decimal; LineNo: Integer)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", DefAmount1 + DefAmount2 + DefAmount3);
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);
        UpdateDeferralScheduleForLine(
          "Deferral Document Type"::Sales, SalesHeader."Document Type".AsInteger(), SalesHeader."No.",
          SalesLine."Line No.", SalesHeader."Posting Date", DefAmount1, DefAmount2, DefAmount3, LineNo);
    end;

    local procedure CreatePurchLineWithGLAccount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DeferralTemplateCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLineWithGLAccount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; DeferralTemplateCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLineWithItem(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostGr: Code[20]; ItemNo: Code[20]; DeferralTemplateCode: Code[10]; Amount: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostGr);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Validate("Deferral Code", DeferralTemplateCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLineWithItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostGr: Code[20]; ItemNo: Code[20]; DeferralTemplateCode: Code[10]; Amount: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostGr);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Validate("Deferral Code", DeferralTemplateCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithDefaultDimension(DimensionValue: Record "Dimension Value") ItemNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
        exit(ItemNo);
    end;

    local procedure CreateVATProdPostingGroupNoVAT(VATBusPostGr: Code[20]): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        CreateVATPostingSetup(VATBusPostGr, VATProductPostingGroup.Code, 0);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetup(VATBusPostGr: Code[20]; VATProdPostGr: Code[20]; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGr, VATProdPostGr);
        VATPostingSetup."VAT Identifier" := VATProdPostGr;
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CalcPeriodDate(PostingDate: Date; Period: Integer): Date
    begin
        exit(CalcDate('<' + Format(Period) + 'M>', PostingDate));
    end;

    local procedure SetDateDay(Day: Integer; StartDate: Date): Date
    begin
        // Use the workdate but set to a specific day of that month
        exit(DMY2Date(Day, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3)));
    end;

    local procedure SetupPurchaseHeader(var PurchaseLine: Record "Purchase Line"; var DeferralTemplateCode: Code[10]; NewDay: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
    begin
        CreateItemWithDefaultDeferralCode(DeferralTemplateCode, ItemNo, CalcMethod::"Straight-Line", StartDate::"Posting Date", 2);

        // [GIVEN] Creating Purchase Line for Item should default deferral code
        CreatePurchDocWithLine(PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, ItemNo, SetDateDay(NewDay, WorkDate()));

        // [GIVEN] Posting Date is changed on purchase header
        PurchaseHeader.Validate("Posting Date", SetDateDay(1, WorkDate()));
    end;

    local procedure DeferralLineSetRange(var DeferralLine: Record "Deferral Line"; DeferralDocType: Enum "Deferral Document Type"; DocType: Integer; DocNo: Code[20]; LineNo: Integer)
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
    end;

    local procedure OpenSalesDeferralSchedule(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.ShowDeferrals(SalesHeader."Posting Date", SalesHeader."Currency Code");
    end;

    local procedure OpenPurchaseDeferralSchedule(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.ShowDeferrals(PurchaseHeader."Posting Date", PurchaseHeader."Currency Code");
    end;

    local procedure PostedDeferralLineSetRange(var PostedDeferralLine: Record "Posted Deferral Line"; DeferralDocType: Enum "Deferral Document Type"; DocType: Integer; DocNo: Code[20]; LineNo: Integer)
    begin
        PostedDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        PostedDeferralLine.SetRange("Gen. Jnl. Document No.", '');
        PostedDeferralLine.SetRange("Account No.", '');
        PostedDeferralLine.SetRange("Document Type", DocType);
        PostedDeferralLine.SetRange("Document No.", DocNo);
        PostedDeferralLine.SetRange("Line No.", LineNo);
    end;

    local procedure SalesChangeNoOfPeriodsInitScenario(var NoOfPeriods: Integer; var Offset: Integer; CalcMethod: Enum "Deferral Calculation Method"; var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        NoOfPeriods := LibraryRandom.RandIntInRange(5, 10);
        Offset := LibraryRandom.RandInt(5);
        CreateItemWithDefaultDeferralCode(
          DeferralTemplateCode, ItemNo, CalcMethod, DeferralTemplate."Start Date"::"Posting Date", NoOfPeriods);

        CreateSalesDocWithLine(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, ItemNo, SetDateDay(LibraryRandom.RandInt(5), WorkDate()));

        LibraryVariableStorage.Enqueue(NoOfPeriods + Offset);
    end;

    local procedure PurchaseChangeNoOfPeriodsInitScenario(var NoOfPeriods: Integer; var Offset: Integer; CalcMethod: Enum "Deferral Calculation Method"; var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    var
        DeferralTemplate: Record "Deferral Template";
        DeferralTemplateCode: Code[10];
        ItemNo: Code[20];
    begin
        NoOfPeriods := LibraryRandom.RandIntInRange(5, 10);
        Offset := LibraryRandom.RandInt(5);
        CreateItemWithDefaultDeferralCode(
          DeferralTemplateCode, ItemNo, CalcMethod, DeferralTemplate."Start Date"::"Posting Date", NoOfPeriods);

        CreatePurchDocWithLine(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          PurchaseLine.Type::Item, ItemNo, SetDateDay(LibraryRandom.RandInt(5), WorkDate()));

        LibraryVariableStorage.Enqueue(NoOfPeriods + Offset);
    end;

    local procedure FindSalesInvoiceLine(var SalesInvLine: Record "Sales Invoice Line"; No: Code[20])
    begin
        SalesInvLine.SetRange("Document No.", No);
        SalesInvLine.FindFirst();
    end;

    local procedure FindPurchInvoiceLine(var PurchInvLine: Record "Purch. Inv. Line"; No: Code[20])
    begin
        PurchInvLine.SetRange("Document No.", No);
        PurchInvLine.FindFirst();
    end;

    local procedure UpdateVATPostSetupWithRevCharge(VATBusPostGrCode: Code[20]; GLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccNo);
        VATPostingSetup.Get(VATBusPostGrCode, GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateDeferralScheduleForLine(DefDocType: Enum "Deferral Document Type"; DocType: Option; DocNo: Code[20]; DocLineNo: Integer; StartDate: Date; DefAmount1: Decimal; DefAmount2: Decimal; DefAmount3: Decimal; LineNo: Integer)
    var
        DeferralLine: Record "Deferral Line";
    begin
        DeferralLine.SetRange("Posting Date", StartDate);
        LibraryERM.FindDeferralLine(DeferralLine, DefDocType, '', '', DocType, DocNo, DocLineNo);
        UpdateDefScheduleLine(DeferralLine, DefAmount1, Format(LineNo) + '1');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+1M>', StartDate));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, DefAmount2, Format(LineNo) + '2');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+2M>', StartDate));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, DefAmount3, Format(LineNo) + '3');
    end;

    local procedure UpdateDefScheduleLine(var DeferralLine: Record "Deferral Line"; DefAmount: Decimal; DefLineDescr: Text[100])
    begin
        DeferralLine.Validate(Description, PadStr(DefLineDescr, MaxStrLen(DeferralLine.Description), '0'));
        DeferralLine.Validate(Amount, DefAmount);
        DeferralLine.Modify(true);
    end;

    local procedure FillTempAmountLines(var TempGLEntry: Record "G/L Entry" temporary; LineNo: Integer; GLAccountNo: Code[20]; Amount: Decimal)
    begin
        TempGLEntry.Init();
        TempGLEntry."Entry No." := LineNo;
        TempGLEntry."G/L Account No." := GLAccountNo;
        TempGLEntry.Amount := Amount;
        TempGLEntry.Insert();
    end;

    local procedure FindDeferralLine(var DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line")
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralLine."Deferral Doc. Type"::Sales);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", SalesLine."Document Type");
        DeferralLine.SetRange("Document No.", SalesLine."Document No.");
        DeferralLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        // Modal Page Handler.
        DeferralSchedule."Amount to Defer".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleModalPageHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        DeferralSchedule."Start Date".SetValue(LibraryVariableStorage.DequeueDate());
        DeferralSchedule.CalculateSchedule.Invoke();
        DeferralSchedule.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleModalPageHandlerOK(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        DeferralSchedule.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeferralScheduleUpdateNoOfPeriodslModalPageHandler(var DeferralSchedule: TestPage "Deferral Schedule")
    begin
        DeferralSchedule."No. of Periods".SetValue(LibraryVariableStorage.DequeueInteger());
        DeferralSchedule.OK().Invoke();
    end;

    local procedure VerifyPostedDeferralScheduleDoesNotExist(DeferralDocType: Enum "Deferral Document Type"; DocType: Integer; DocNo: Code[20]; LineNo: Integer)
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
    begin
        asserterror PostedDeferralHeader.Get(DeferralDocType, '', '', DocType, DocNo, LineNo);

        PostedDeferralLineSetRange(PostedDeferralLine, DeferralDocType, DocType, DocNo, LineNo);
        Assert.RecordIsEmpty(PostedDeferralLine);
    end;

    local procedure VerifyDeferralSchedule(DeferralDocType: Enum "Deferral Document Type"; DocType: Integer; DocNo: Code[20]; LineNo: Integer; DeferralTemplateCode: Code[10]; HeaderPostingDate: Date; HeaderAmountToDefer: Decimal; NoOfPeriods: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        DeferralUtilities: Codeunit "Deferral Utilities";
        Period: Integer;
        DeferralAmount: Decimal;
        PostingDate: Date;
    begin
        DeferralHeader.Get(DeferralDocType, '', '', DocType, DocNo, LineNo);
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date", HeaderPostingDate);
        DeferralHeader.TestField("Amount to Defer", HeaderAmountToDefer);
        DeferralHeader.TestField("No. of Periods", NoOfPeriods);

        DeferralLineSetRange(DeferralLine, DeferralDocType, DocType, DocNo, LineNo);
        Period := 0;
        if DeferralLine.FindSet() then
            repeat
                if Period = 0 then
                    PostingDate := HeaderPostingDate
                else
                    PostingDate := SetDateDay(1, HeaderPostingDate);
                PostingDate := CalcPeriodDate(PostingDate, Period);
                DeferralLine.TestField("Posting Date", PostingDate);
                DeferralAmount := DeferralAmount + DeferralLine.Amount;
                Period += 1;
            until DeferralLine.Next() = 0;

        Assert.RecordCount(
          DeferralLine,
          DeferralUtilities.CalcDeferralNoOfPeriods(
            DeferralHeader."Calc. Method", DeferralHeader."No. of Periods", DeferralHeader."Start Date"));
    end;

    local procedure VerifyVATEntry(ExpectedAmount: Decimal; ExpectedBase: Decimal; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindFirst();
        VATEntry.TestField(Base, ExpectedAmount);
        VATEntry.TestField(Amount, ExpectedBase);
    end;

    local procedure VerifyRoundedDeferralGLEntries(DocumentNo: Code[20]; PostingDate: Date; LineGLAccountNo: Code[20]; DeferralGLAccountNo: Code[20]; DocDescription: Text[100]; PeriodDescription: Text[100]; PeriodAmount: Decimal; LineAmount: Decimal; TotalDefAmount: Decimal; Sign: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        VerifyGLEntryByDescription(GLEntry, LineGLAccountNo, DocDescription, Sign * 0.01);
        GLEntry.SetRange("Gen. Posting Type", 0);
        GLEntry.Next();
        GLEntry.TestField(Amount, -Sign * LineAmount);
        GLEntry.SetRange("Gen. Posting Type");
        VerifyGLEntryByDescription(GLEntry, LineGLAccountNo, PeriodDescription, Sign * PeriodAmount);
        VerifyGLEntryByDescription(GLEntry, DeferralGLAccountNo, PeriodDescription, -Sign * PeriodAmount);

        VerifyGLEntrySumByDescription(GLEntry, DeferralGLAccountNo, DocDescription, Sign * TotalDefAmount);
    end;

    local procedure VerifyDeferralGLEntries(var TempGLEntry: Record "G/L Entry" temporary; DocumentNo: Code[20]; StartingDate: Date; DeferralGLAccountNo: Code[20]; DeferralSourceCode: Code[10]; ExpectedCount: Integer; Sign: Integer)
    var
        GLEntry: Record "G/L Entry";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
        GLEntry.SetRange("Source Code", DeferralSourceCode);
        Assert.RecordCount(GLEntry, ExpectedCount - 5);
        GLEntry.SetRange("Source Code");
        PostedDeferralLine.SetRange("Document No.", DocumentNo);
        PostedDeferralLine.CalcSums(Amount);
        DeferralAmount := PostedDeferralLine.Amount;

        PostedDeferralLine.FindSet();
        TempGLEntry.FindSet();
        VerifyGLEntrySum(GLEntry, StartingDate, DeferralGLAccountNo, Sign * DeferralAmount);
        VerifyGLEntrySum(GLEntry, PostedDeferralLine."Posting Date", DeferralGLAccountNo, -Sign * DeferralAmount);

        repeat
            VerifyGLEntrySum(
              GLEntry, StartingDate, TempGLEntry."G/L Account No.", Sign * (TempGLEntry.Amount - PostedDeferralLine.Amount));
            VerifyGLEntrySum(
              GLEntry, PostedDeferralLine."Posting Date", TempGLEntry."G/L Account No.", Sign * PostedDeferralLine.Amount);
            TempGLEntry.Next();
        until PostedDeferralLine.Next() = 0;
    end;

    local procedure VerifyGLEntryByDescription(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; GLDescription: Text[100]; GLAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange(Description, GLDescription);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, GLAmount);
    end;

    local procedure VerifyGLEntrySumByDescription(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; GLDescription: Text[100]; GLAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange(Description, GLDescription);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, GLAmount);
    end;

    local procedure VerifyGLEntrySum(var GLEntry: Record "G/L Entry"; PostingDate: Date; GLAccountNo: Code[20]; GLAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, GLAmount);
    end;

    local procedure VerifyGLEntriesWithDimensions(DocumentNo: Code[20]; VATProdPostingGr: Code[20]; DimSet1: Integer; DimSet2: Integer; ExpectedAmount1: Decimal; ExpectedAmount2: Decimal)
    var
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Dimension Set ID", 0);
        GLEntry.FindFirst();
        TotalAmount := GLEntry.Amount;
        GLEntry.SetRange("Dimension Set ID");

        GLEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGr);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -TotalAmount);

        GLEntry.SetRange("Dimension Set ID", DimSet1);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmount1);
        GLEntry.SetRange("Dimension Set ID", DimSet2);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedAmount2);
    end;
}

