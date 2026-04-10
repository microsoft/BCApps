codeunit 134557 "ERM Cash Flow UnitTests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow] [Worksheet]
        IsInitialized := false;
    end;

    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryCF: Codeunit "Library - Cash Flow";
        LibraryCFHelper: Codeunit "Library - Cash Flow Helper";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Matrix1: Label 'Matrix 1x';
        Matrix2: Label 'Matrix 2x';
        Matrix3: Label 'Matrix 3x';
        Matrix4: Label 'Matrix 4x';
        Matrix5: Label 'Matrix 5';
        Matrix7: Label 'Matrix 7';
        Matrix9: Label 'Matrix 9';
        TestForEmptyDocDate: Label 'Test for empty Document Date';
        TestForEmptyDiscDateCalc: Label 'Test For Empty Discount Date Calculation Formula';
        IncorrectField: Label 'Incorrect %1. Expected %2 current %3.';
        IsInitialized: Boolean;
        PlusOneDayFormula: DateFormula;
        MinusOneDayFormula: DateFormula;
        PosNegErrMsg: Label 'Wrong Positive = <%1> for Amount (LCY) = <%2>.';
        NoDefaultCFMsg: Label 'Select the "Show in Chart on Role Center" field in the Cash Flow Forecast window to display the chart on the Role Center.';
        UnexpectedValueInField: Label 'Unexpected value in field %1.';
        CustLedgerEntryNotFoundErr: Label 'The field Source No. of table Cash Flow Forecast Entry contains a value (%1) that cannot be found in the related table (Cust. Ledger Entry).';
        VendLedgerEntryNotFoundErr: Label 'The field Source No. of table Cash Flow Forecast Entry contains a value (%1) that cannot be found in the related table (Vendor Ledger Entry).';
        NothingInsideFilterTok: Label 'NothingInsideFilter';

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix1a()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // 1a Yes Yes Yes Yes Order Yes Jan. 04 96,00: Cash Flow discount date and Cash Flow discount amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix1;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - yes
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Discount Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := Round(CFWorksheetLine."Amount (LCY)" * (100 - PaymentTerms."Discount %") / 100);
        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix1c()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes Yes Yes LE: Cr. Memo Yes Yes Jan. 04 -96,00: Cash Flow discount date and Cash Flow discount amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix1;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - yes
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := Round(CFWorksheetLine."Amount (LCY)" * (100 - PaymentTerms."Discount %") / 100);
        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        ExpectedDate := CalcDate(PaymentTerms."Discount Date Calculation", CFWorksheetLine."Document Date");
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix1d()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes Yes Yes LE: Cr. Memo No Yes Jan. 01 -100,00 Ledger entry due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix1;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - yes
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        CFForecast.Modify();
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := false;
        PaymentTerms.Modify();
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := DocumentDate;
        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix2a()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // 1a Yes Yes Yes Yes Order No Jan. 04 96,00: Cash Flow discount date and Cash Flow discount amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix2;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - yes
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix2c()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes Yes Yes LE: Cr. Memo Yes No Jan. 04 -96,00: Cash Flow discount date and Cash Flow discount amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix2;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - yes
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix2d()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes Yes Yes LE: Cr. Memo No No Jan. 01 -100,00 Ledger entry due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix2;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - yes
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        CFForecast.Modify();
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := false;
        PaymentTerms.Modify();
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CFWorksheetLine."Document Date";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix3a()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // 1a Yes Yes Yes No Order * * Jan. 22 100,00: Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix3;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - No
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify();
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix3c()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes Yes No LE: Cr. Memo Yes * Jan. 22 -100,00:Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix3;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - No
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify();
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix3d()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes Yes No LE: Cr. Memo No No Jan. 01 -100,00 Ledger entry due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix3;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - No
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify();
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        CFForecast.Modify();
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := false;
        PaymentTerms.Modify();
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CFWorksheetLine."Document Date";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix4a()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // 4a Yes Yes No No Order * * Jan. 22 100,00: Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix4;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := false;
        // Cash Flow Payment Terms with Cash Discount? 2) - No
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify();
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix4c()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes No No LE: Cr. Memo Yes * Jan. 22 -100,00:Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix4;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := false;
        // Cash Flow Payment Terms with Cash Discount? 2) - No
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify();
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix4d()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes Yes No No LE: Cr. Memo No No Jan. 01 -100,00 Ledger entry due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix4;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - yes
        CFForecast."Consider Discount" := false;
        // Cash Flow Payment Terms with Cash Discount? 2) - No
        PaymentTerms.Validate("Discount %", 0);
        PaymentTerms.Modify();
        // Source / Document type 4) - Cr.Memo
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        CFForecast.Modify();
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := false;
        PaymentTerms.Modify();
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::"Credit Memo";
        CFWorksheetLine."Amount (LCY)" := -CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";
        ExpectedDate := CFWorksheetLine."Document Date";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix5()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // 5 Yes No Yes * Yes * * Yes Jan. 22 100,00: Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix5;

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - No
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Discount Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := Round(CFWorksheetLine."Amount (LCY)" * (100 - PaymentTerms."Discount %") / 100);

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix7()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes No Yes * Yes * * Yes Jan. 22 100,00: Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix7;

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - No
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix8_3()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes No No * Yes * * Yes Jan. 22 100,00: Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix7;

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - No
        CFForecast."Consider Discount" := false;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix8_5()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // Yes No No * Yes * * Yes Jan. 22 100,00: Cash Flow due date and full amount
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix7;

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := true;
        // Cash Flow payment terms on customer - No
        CFForecast."Consider Discount" := false;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix9_1()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // No * Yes * Yes * Yes * * Yes Jan. 06 98,00: Discount date and default discount amount from order or LE
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix9;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := false;
        // Cash Flow payment terms on customer - **
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Discount Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := Round(CFWorksheetLine."Amount (LCY)" * (100 - PaymentTerms."Discount %") / 100);

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix9_2()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // No * Yes * Yes * Yes * * Yes Jan. 06 98,00: Discount date and default discount amount from order or LE
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix9;

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := false;
        // Cash Flow payment terms on customer - **
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-3D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Discount Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := Round(CFWorksheetLine."Amount (LCY)" * (100 - PaymentTerms."Discount %") / 100);

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix12()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // No * No * * * * * *: Jan. 15 100,00: Due date and full amount from order or LE
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix1;

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := false;
        // Cash Flow payment terms on customer - **
        CFForecast."Consider Discount" := false;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMatrix11()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        ExpectedAmount: Decimal;
        DocumentDate: Date;
        ExpectedDate: Date;
    begin
        // No * Yes * Yes * Yes * * No Jan. 15 100,00: Due date and full amount from order or LE
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := Matrix1;

        CreateDefaultMatrixCFPT(Customer, PaymentTerms);

        PaymentTerms.Get(Customer."Payment Terms Code");

        LibraryCF.CreateCashFlowCard(CFForecast);
        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        // Setup
        CFForecast."Consider CF Payment Terms" := false;
        // Cash Flow payment terms on customer - **
        CFForecast."Consider Discount" := true;
        // Cash Flow Payment Terms with Cash Discount? 2) - *
        // Source / Document type 4) - SO
        // Cash Discount Date <= Work Date Y=workdate: Jan. 3 N=workdate: Jan. 9"
        DocumentDate := CalcDate('<-5D>', WorkDate());
        CFForecast.Modify();

        CFWorksheetLine."Document Date" := DocumentDate;
        CFWorksheetLine.Insert();
        ExpectedDate := CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date");
        ExpectedAmount := CFWorksheetLine."Amount (LCY)";

        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date", ExpectedDate,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), ExpectedDate, CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)", ExpectedAmount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), ExpectedAmount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyDate()
    var
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        Customer: Record Customer;
    begin
        // bug 261713
        // CFForecast - no Doc.Date on orders (sales, service and purchase) result in error msg.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := TestForEmptyDocDate;
        Customer.Modify();
        LibraryCF.CreateCashFlowCard(CFForecast);

        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, '');

        CFWorksheetLine."Document Date" := 0D;
        CFWorksheetLine.Insert();
        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        CFWorksheetLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyDiscountDateCalculationFormula()
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        CFForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        LibraryERM: Codeunit "Library - ERM";
        Amount: Decimal;
    begin
        // bug 261712:
        // CFForecast - Orders (sales, service, purchase) with doc. date = work date or future and CFForecast payment terms result in wrong CFForecast dates
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := TestForEmptyDiscDateCalc;
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<1M>');
        PaymentTerms.Validate("Discount %", LibraryRandom.RandInt(50));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify();

        Customer."Cash Flow Payment Terms Code" := PaymentTerms.Code;
        Customer.Modify();

        LibraryCF.CreateCashFlowCard(CFForecast);
        CFForecast."Consider Discount" := true;
        CFForecast."Consider CF Payment Terms" := true;
        CFForecast.Modify();

        PreFillCFWorksheetLine(CFWorksheetLine, CFForecast."No.", Customer.Address, PaymentTerms.Code);

        CFWorksheetLine."Document Date" := WorkDate();
        CFWorksheetLine.Insert();
        Amount := Round(CFWorksheetLine."Amount (LCY)" * (100 - PaymentTerms."Discount %") / 100);
        CFWorksheetLine.CalculateCFAmountAndCFDate();
        // Modify();
        Assert.AreEqual(
          CFWorksheetLine."Cash Flow Date",
          CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date"),
          StrSubstNo(
            IncorrectField, CFWorksheetLine.FieldCaption("Cash Flow Date"), CalcDate(PaymentTerms."Due Date Calculation", CFWorksheetLine."Document Date"),
            CFWorksheetLine."Cash Flow Date"));

        Assert.AreEqual(
          CFWorksheetLine."Amount (LCY)",
          Amount,
          StrSubstNo(IncorrectField, CFWorksheetLine.FieldCaption("Amount (LCY)"), Amount, CFWorksheetLine."Amount (LCY)"));

        CFWorksheetLine.Delete();
    end;

    local procedure PreFillCFWorksheetLine(var CFWorksheetLine: Record "Cash Flow Worksheet Line"; CashFlowNo: Code[20]; TestDescription: Text[100]; PaymentTermsCode: Code[10])
    begin
        CFWorksheetLine."Line No." := LibraryRandom.RandInt(100000);

        CFWorksheetLine."Document Type" := CFWorksheetLine."Document Type"::Invoice;
        CFWorksheetLine."Cash Flow Forecast No." := CashFlowNo;
        CFWorksheetLine."Amount (LCY)" := LibraryRandom.RandInt(1001);
        CFWorksheetLine.Description := TestDescription;
        CFWorksheetLine."Payment Terms Code" := PaymentTermsCode;
    end;

    local procedure CreateDefaultMatrixCFPT(var Customer: Record Customer; var PaymentTerms: Record "Payment Terms")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<21D>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<3D>');
        PaymentTerms.Validate("Discount %", LibraryRandom.RandInt(90));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify();

        Customer."Cash Flow Payment Terms Code" := PaymentTerms.Code;
        Customer.Modify();
    end;

    local procedure InsertRndCFLedgEntries(CashFlowNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CashFlowDate: Date; var TotalAmount: Decimal)
    var
        Amount: Decimal;
        "Count": Integer;
        i: Integer;
    begin
        Count := LibraryRandom.RandIntInRange(1, 3);
        TotalAmount := 0;
        for i := 1 to Count do begin
            Amount := LibraryRandom.RandDec(100, 2);

            InsertCFLedgerEntry(CashFlowNo, SourceType, CashFlowDate, Amount);

            TotalAmount += Amount;
        end;
    end;

    local procedure InsertCFLedgerEntries(var CashFlowForecast: Record "Cash Flow Forecast"; ConsiderSource: array[16] of Boolean; var PostedAmount: array[16, 2] of Decimal)
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        SourceType: Integer;
        Period: Option ,Before,After;
        Amount: Decimal;
    begin
        Clear(PostedAmount);
        CashFlowForecast.FindFirst();
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.DeleteAll();

        for SourceType := 1 to ArrayLen(ConsiderSource) do
            if ConsiderSource[SourceType] then begin
                InsertRndCFLedgEntries(CashFlowForecast."No.", "Cash Flow Source Type".FromInteger(SourceType), CalcDate(MinusOneDayFormula, WorkDate()), Amount);
                PostedAmount[SourceType, Period::Before] := Amount;
                InsertRndCFLedgEntries(CashFlowForecast."No.", "Cash Flow Source Type".FromInteger(SourceType), CalcDate(PlusOneDayFormula, WorkDate()), Amount);
                PostedAmount[SourceType, Period::After] := Amount;
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalculateAmountsOnCFLedgEntryFromToDate()
    begin
        Initialize();
        VerifyCalculatedAmountsForPeriod(WorkDate(), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalculateAmountsOnCFLedgEntryFromDate()
    begin
        Initialize();
        VerifyCalculatedAmountsForPeriod(WorkDate(), 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalculateAmountsOnCFLedgEntryToDate()
    begin
        Initialize();
        VerifyCalculatedAmountsForPeriod(0D, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalculateAmountsOnCFLedgEntryNoDate()
    begin
        Initialize();
        VerifyCalculatedAmountsForPeriod(0D, 0D);
    end;

    local procedure VerifyCalculatedAmountsForPeriod(FromDate: Date; ToDate: Date)
    var
        CFForecast: Record "Cash Flow Forecast";
        PostedAmount: array[16, 2] of Decimal;
        SumTotal: Decimal;
        Values: array[16] of Decimal;
        SourceType: Option;
        expectedValue: Decimal;
        expectedValueTotal: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderAllSources(ConsiderSource);
        InsertCFLedgerEntries(CFForecast, ConsiderSource, PostedAmount);
        CFForecast.CalculateAllAmounts(FromDate, ToDate, Values, SumTotal);
        for SourceType := 1 to ArrayLen(Values) do begin
            expectedValue := CalcExpectedAmount(FromDate, ToDate, PostedAmount[SourceType]);
            CFForecast."Source Type Filter" := "Cash Flow Source Type".FromInteger(SourceType);
            Assert.AreEqual(
              expectedValue, Values[SourceType],
              StrSubstNo(IncorrectField, CFForecast."Source Type Filter", expectedValue, Values[SourceType]));

            expectedValueTotal := expectedValueTotal + expectedValue;
        end;

        Assert.AreEqual(
          expectedValueTotal, SumTotal,
          StrSubstNo(IncorrectField, 'Total', expectedValueTotal, SumTotal));
    end;

    local procedure ConsiderAllSources(var ConsiderSource: array[16] of Boolean)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ConsiderSource) do
            ConsiderSource[i] := true;
    end;

    local procedure CalcExpectedAmount(FromDate: Date; ToDate: Date; PostedAmount: array[2] of Decimal): Decimal
    begin
        case true of
            (FromDate = 0D) and (ToDate = 0D):
                exit(PostedAmount[1] + PostedAmount[2]);
            (FromDate = 0D) and (ToDate = WorkDate()):
                exit(PostedAmount[1]);
            (FromDate = WorkDate()) and (ToDate = 0D):
                exit(PostedAmount[2]);
            (FromDate = WorkDate()) and (ToDate = WorkDate()):
                exit(0);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXAxisCaption()
    var
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
    begin
        Initialize();
        for BusChartBuf."Period Length" := BusChartBuf."Period Length"::Day to BusChartBuf."Period Length"::Year do begin
            SetPeriodLengthInChartSetup(BusChartBuf."Period Length");
            CFChartMgt.UpdateData(BusChartBuf);
            Assert.AreEqual(
              Format(BusChartBuf."Period Length"), BusChartBuf.GetXCaption(), 'Expected X Axis caption to be related to the period length');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXAxisTypeForPeriods()
    var
        BusChartBuf: Record "Business Chart Buffer";
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowSetup: Record "Cash Flow Setup";
        ConsiderSource: array[16] of Boolean;
        PostedAmount: array[16, 2] of Decimal;
    begin
        Initialize();
        ConsiderSource[CashFlowForecast."Source Type Filter"::Receivables.AsInteger()] := true;
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);
        CashFlowSetup.SetChartRoleCenterCFNo(CashFlowForecast."No.");

        Assert.IsTrue(GetIsXAxisDateTimeForPeriod(BusChartBuf."Period Length"::Day), 'Expected DateTime type of X Axis for Period : Day');
        for BusChartBuf."Period Length" := BusChartBuf."Period Length"::Week to BusChartBuf."Period Length"::Year do
            Assert.IsFalse(
              GetIsXAxisDateTimeForPeriod(BusChartBuf."Period Length"),
              StrSubstNo('Not expected DateTime type of X Axis for Period : %1', BusChartBuf."Period Length"));
    end;

    local procedure GetIsXAxisDateTimeForPeriod(PeriodLength: Integer): Boolean
    var
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
    begin
        SetPeriodLengthInChartSetup(PeriodLength);
        CFChartMgt.UpdateData(BusChartBuf);
        exit(BusChartBuf.IsXAxisDateTime());
    end;

    local procedure SetPeriodLengthInChartSetup(PeriodLength: Integer)
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        if CashFlowChartSetup.Get(UserId) then
            CashFlowChartSetup.Delete();

        CashFlowChartSetup.Init();
        CashFlowChartSetup."User ID" := UserId;
        CashFlowChartSetup."Period Length" := PeriodLength;
        CashFlowChartSetup.Insert();
    end;

    [Test]
    [HandlerFunctions('NoDefaultMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDataUpdateForNoDefaultCFCard()
    var
        BusChartBuf: Record "Business Chart Buffer";
        CashFlowSetup: Record "Cash Flow Setup";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        CFForecastNo: Code[20];
    begin
        Initialize();

        CFForecastNo := CashFlowSetup.GetChartRoleCenterCFNo();
        CashFlowSetup.SetChartRoleCenterCFNo('');

        Assert.IsFalse(CFChartMgt.UpdateData(BusChartBuf), 'Warning message expected.');
        CashFlowSetup.SetChartRoleCenterCFNo(CFForecastNo);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NoDefaultMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, NoDefaultCFMsg) = 1, StrSubstNo('Expected message should start with ''%1 ...''', NoDefaultCFMsg));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnOpenInitChartSetup()
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
    begin
        Initialize();

        if CashFlowChartSetup.Get(UserId) then
            CashFlowChartSetup.Delete();
        CFChartMgt.OnOpenPage(CashFlowChartSetup);

        CashFlowChartSetup.TestField("Start Date", CashFlowChartSetup."Start Date"::"Working Date");
        CashFlowChartSetup.TestField("Period Length", CashFlowChartSetup."Period Length"::Month);
        CashFlowChartSetup.TestField(Show, CashFlowChartSetup.Show::Combined);
        CashFlowChartSetup.TestField("Chart Type", CashFlowChartSetup."Chart Type"::"Stacked Column");
        CashFlowChartSetup.TestField("Group By", CashFlowChartSetup."Group By"::"Source Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnOpenWithExistingChartSetup()
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        ExistingCashFlowChartSetup: Record "Cash Flow Chart Setup";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
    begin
        Initialize();

        SetPeriodLengthInChartSetup(CashFlowChartSetup."Period Length"::Year);
        CashFlowChartSetup.Get(UserId);
        ExistingCashFlowChartSetup := CashFlowChartSetup;
        CFChartMgt.OnOpenPage(CashFlowChartSetup);

        CashFlowChartSetup.TestField("Start Date", ExistingCashFlowChartSetup."Start Date");
        CashFlowChartSetup.TestField("Period Length", ExistingCashFlowChartSetup."Period Length");
        CashFlowChartSetup.TestField(Show, ExistingCashFlowChartSetup.Show);
        CashFlowChartSetup.TestField("Chart Type", ExistingCashFlowChartSetup."Chart Type");
        CashFlowChartSetup.TestField("Group By", ExistingCashFlowChartSetup."Group By");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestZeroPeriodsForNoEntries()
    var
        CFForecast: Record "Cash Flow Forecast";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        BusChartBuf: Record "Business Chart Buffer";
        BusChartMap: Record "Business Chart Map";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
    begin
        Initialize();
        CFForecast.FindFirst();
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CFForecast."No.");
        CFForecastEntry.DeleteAll();

        SetPeriodLengthInChartSetup(BusChartBuf."Period Length"::Day);
        CFChartMgt.UpdateData(BusChartBuf);
        Assert.IsFalse(BusChartBuf.FindFirstColumn(BusChartMap), 'No Periods expected for no entries');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCombinedChart()
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        BusChartBuf: Record "Business Chart Buffer";
        MeasureBusChartMap: Record "Business Chart Map";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        Value: Variant;
        AccumulatedMeasureName: Text[249];
        PostedAmount: array[16, 2] of Decimal;
        ExpectedAmount: Decimal;
        ActualAmount: Decimal;
        i: Integer;
    begin
        Initialize();
        SetDayColumnGroupByChartSetup(CashFlowChartSetup.Show::Combined, CashFlowChartSetup."Group By"::"Source Type");

        InsertCFReceivablesPayables(CashFlowForecast, PostedAmount);
        for i := 1 to 2 do
            ExpectedAmount += PostedAmount[i, 1] + PostedAmount[i, 2];
        CashFlowSetup.SetChartRoleCenterCFNo(CashFlowForecast."No.");

        CFChartMgt.UpdateData(BusChartBuf);

        BusChartBuf.FindFirstMeasure(MeasureBusChartMap);
        BusChartBuf.NextMeasure(MeasureBusChartMap);
        BusChartBuf.NextMeasure(MeasureBusChartMap);
        AccumulatedMeasureName := MeasureBusChartMap.Name;

        BusChartBuf.GetValue(AccumulatedMeasureName, 2, Value);
        Evaluate(ActualAmount, Format(Value));
        Assert.AreEqual(ExpectedAmount, ActualAmount, 'Wrong Amount in the accumulated chart ' + AccumulatedMeasureName)
    end;

    local procedure InsertCFReceivablesPayables(var CashFlowForecast: Record "Cash Flow Forecast"; var PostedAmount: array[16, 2] of Decimal)
    var
        ConsiderSource: array[16] of Boolean;
    begin
        ConsiderSource[CashFlowForecast."Source Type Filter"::Receivables.AsInteger()] := true;
        ConsiderSource[CashFlowForecast."Source Type Filter"::Payables.AsInteger()] := true;
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCombinedChartDrillDown()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        Initialize();
        SetDayColumnGroupByChartSetup(CashFlowChartSetup.Show::Combined, CashFlowChartSetup."Group By"::"Positive/Negative");
        VerifyDateAndSourceTypeOnChartDrillDown(2, CashFlowForecast."Source Type Filter"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccumulatedChartDrillDown()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        Initialize();
        SetDayColumnGroupByChartSetup(CashFlowChartSetup.Show::"Accumulated Cash", CashFlowChartSetup."Group By"::"Positive/Negative");
        VerifyDateAndSourceTypeOnChartDrillDown(0, CashFlowForecast."Source Type Filter"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPosNegChartDrillDown()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        Initialize();
        SetDayColumnGroupByChartSetup(CashFlowChartSetup.Show::"Change in Cash", CashFlowChartSetup."Group By"::"Positive/Negative");
        VerifyDateAndSourceTypeOnChartDrillDown(0, CashFlowForecast."Source Type Filter"::Payables);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSourceTypeChartDrillDown()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        Initialize();
        SetDayColumnGroupByChartSetup(CashFlowChartSetup.Show::"Change in Cash", CashFlowChartSetup."Group By"::"Source Type");
        VerifyDateAndSourceTypeOnChartDrillDown(0, CashFlowForecast."Source Type Filter"::Receivables);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountNoChartDrillDown()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        Initialize();
        SetDayColumnGroupByChartSetup(CashFlowChartSetup.Show::"Change in Cash", CashFlowChartSetup."Group By"::"Account No.");
        VerifyDateAndSourceTypeOnChartDrillDown(0, CashFlowForecast."Source Type Filter"::Receivables);
    end;

    local procedure SetDayColumnGroupByChartSetup(NewShow: Integer; GroupBy: Integer)
    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
    begin
        if CashFlowChartSetup.Get(UserId) then
            CashFlowChartSetup.Delete();

        CashFlowChartSetup.Init();
        CashFlowChartSetup."User ID" := UserId;
        CashFlowChartSetup."Period Length" := CashFlowChartSetup."Period Length"::Day;
        CashFlowChartSetup."Start Date" := CashFlowChartSetup."Start Date"::"First Entry Date";
        CashFlowChartSetup.Show := NewShow;
        CashFlowChartSetup."Group By" := GroupBy;

        CashFlowChartSetup.Insert();
    end;

    local procedure VerifyDateAndSourceTypeOnChartDrillDown(MeasureIndex: Integer; ExpectedSourceType: Enum "Cash Flow Source Type")
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        CFForecastEntries: TestPage "Cash Flow Forecast Entries";
        PostedAmount: array[16, 2] of Decimal;
        Period: Option ,Before,After;
        ExpectedDate: Date;
        ActualTotalAmount: Decimal;
        ExpectedTotalAmount: Decimal;
    begin
        InsertCFReceivablesPayables(CashFlowForecast, PostedAmount);

        CashFlowSetup.SetChartRoleCenterCFNo(CashFlowForecast."No.");
        CFChartMgt.UpdateData(BusChartBuf);

        BusChartBuf."Drill-Down X Index" := 0;
        BusChartBuf."Drill-Down Measure Index" := MeasureIndex;
        ExpectedDate := BusChartBuf.GetXValueAsDate(BusChartBuf."Drill-Down X Index");

        CFForecastEntries.Trap();
        CFChartMgt.DrillDown(BusChartBuf);

        CFForecastEntries.First();
        repeat
            CFForecastEntries."Cash Flow Forecast No.".AssertEquals(CashFlowForecast."No.");
            CFForecastEntries."Cash Flow Date".AssertEquals(ExpectedDate);
            if ExpectedSourceType <> ExpectedSourceType::" " then
                CFForecastEntries."Source Type".AssertEquals(ExpectedSourceType);
            ActualTotalAmount += CFForecastEntries."Amount (LCY)".AsDecimal();
        until not CFForecastEntries.Next();

        if ExpectedSourceType <> ExpectedSourceType::" " then
            ExpectedTotalAmount := PostedAmount[ExpectedSourceType.AsInteger(), Period::Before]
        else
            ExpectedTotalAmount := CalcSum(PostedAmount, Period::Before);
        Assert.AreEqual(ExpectedTotalAmount, ActualTotalAmount, 'Wrong expected sum of Amount (LCY) on the DrillDown page');
    end;

    local procedure CalcSum(PostedAmount: array[16, 2] of Decimal; Period: Option ,Before,After) "Sum": Decimal
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(PostedAmount, 1) do
            Sum += PostedAmount[i, Period];
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSourceTypeCollection()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        PostedAmount: array[16, 2] of Decimal;
        ConsiderSource: array[16] of Boolean;
        SourceType: Option;
        ExpectedNoOfSourceTypes: Integer;
        ActualNoOfSourceTypes: Integer;
    begin
        Initialize();
        ExpectedNoOfSourceTypes := LibraryRandom.RandIntInRange(1, 10);
        for SourceType := 1 to ExpectedNoOfSourceTypes do
            ConsiderSource[SourceType] := true;
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);

        BusChartBuf.Initialize();
        ActualNoOfSourceTypes := CFChartMgt.CollectSourceTypes(CashFlowForecast, BusChartBuf);

        Assert.AreEqual(ExpectedNoOfSourceTypes, ActualNoOfSourceTypes, 'Wrong number of collected Source Types');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountNoCollection()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFAccount: Record "Cash Flow Account";
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        PostedAmount: array[16, 2] of Decimal;
        ConsiderSource: array[16] of Boolean;
        ExpectedNoOfAccounts: Integer;
        ActualNoOfAccounts: Integer;
        SourceType: Integer;
    begin
        Initialize();
        ExpectedNoOfAccounts := LibraryRandom.RandIntInRange(1, 10);
        CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
        for SourceType := 1 to ExpectedNoOfAccounts do
            ConsiderSource[SourceType] := true;
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);

        BusChartBuf.Initialize();
        ActualNoOfAccounts := CFChartMgt.CollectAccounts(CashFlowForecast, BusChartBuf);

        Assert.AreEqual(ExpectedNoOfAccounts, ActualNoOfAccounts, 'Wrong number of collected Accounts');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPosNegCollection()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        PostedAmount: array[16, 2] of Decimal;
        ActualNoOfPosNeg: Integer;
    begin
        Initialize();
        InsertCFReceivablesPayables(CashFlowForecast, PostedAmount);

        BusChartBuf.Initialize();
        ActualNoOfPosNeg := CFChartMgt.CollectPosNeg(CashFlowForecast, BusChartBuf);

        Assert.AreEqual(2, ActualNoOfPosNeg, 'Wrong number of collected Positive-Negative');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPositiveCollection()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        BusChartBuf: Record "Business Chart Buffer";
        CFChartMgt: Codeunit "Cash Flow Chart Mgt.";
        PostedAmount: array[16, 2] of Decimal;
        ConsiderSource: array[16] of Boolean;
        ActualNoOfPosNeg: Integer;
    begin
        Initialize();
        ConsiderSource[CashFlowForecast."Source Type Filter"::Receivables.AsInteger()] := true;
        ConsiderSource[CashFlowForecast."Source Type Filter"::"Sales Orders".AsInteger()] := true;
        ConsiderSource[CashFlowForecast."Source Type Filter"::"Service Orders".AsInteger()] := true;
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);

        BusChartBuf.Initialize();
        ActualNoOfPosNeg := CFChartMgt.CollectPosNeg(CashFlowForecast, BusChartBuf);

        Assert.AreEqual(1, ActualNoOfPosNeg, 'Wrong number of collected Positive-Negative.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPositiveAmount()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        Initialize();
        PostJnlLine(1);
        CFForecastEntry.FindLast();
        Assert.IsTrue(CFForecastEntry.Positive, StrSubstNo(PosNegErrMsg, CFForecastEntry.Positive, CFForecastEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostZeroAmount()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        Initialize();
        PostJnlLine(0);
        CFForecastEntry.FindLast();
        Assert.IsFalse(CFForecastEntry.Positive, StrSubstNo(PosNegErrMsg, CFForecastEntry.Positive, CFForecastEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostNegativeAmount()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        Initialize();
        PostJnlLine(-1);
        CFForecastEntry.FindLast();
        Assert.IsFalse(CFForecastEntry.Positive, StrSubstNo(PosNegErrMsg, CFForecastEntry.Positive, CFForecastEntry."Amount (LCY)"));
    end;

    local procedure PostJnlLine(Amount: Decimal)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowWkshLine: Record "Cash Flow Worksheet Line";
        CFAccount: Record "Cash Flow Account";
        CFWkshRegisterLine: Codeunit "Cash Flow Wksh. -Register Line";
    begin
        CashFlowForecast.FindFirst();
        CFAccount.SetRange(Blocked, false);
        CFAccount.SetRange("Account Type", CFAccount."Account Type"::Entry);
        CFAccount.FindFirst();
        CashFlowWkshLine.Init();
        CashFlowWkshLine."Cash Flow Forecast No." := CashFlowForecast."No.";
        CashFlowWkshLine."Cash Flow Account No." := CFAccount."No.";
        CashFlowWkshLine."Cash Flow Date" := WorkDate();
        CashFlowWkshLine."Amount (LCY)" := Amount;

        CFWkshRegisterLine.RunWithCheck(CashFlowWkshLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForTotal()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderAllSources(ConsiderSource);
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.Total.DrillDown();
        CashFlowCard.Control1905906307.Total.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForServiceOrders()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.ServiceOrders.DrillDown();
        CashFlowCard.Control1905906307.ServiceOrders.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForReceivables()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.Receivables.DrillDown();
        CashFlowCard.Control1905906307.Receivables.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForPayables()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.Payables.DrillDown();
        CashFlowCard.Control1905906307.Payables.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForSalesOrders()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.SalesOrders.DrillDown();
        CashFlowCard.Control1905906307.SalesOrders.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForPurchOrders()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.PurchaseOrders.DrillDown();
        CashFlowCard.Control1905906307.PurchaseOrders.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForLiquidFunds()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.LiquidFunds.DrillDown();
        CashFlowCard.Control1905906307.LiquidFunds.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForManualExpenses()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.ManualExpenses.DrillDown();
        CashFlowCard.Control1905906307.ManualExpenses.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForManualRevenues()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.ManualRevenues.DrillDown();
        CashFlowCard.Control1905906307.ManualRevenues.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForSaleOfFA()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.SaleofFixedAssets.DrillDown();
        CashFlowCard.Control1905906307.SaleofFixedAssets.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForBudgetedFA()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.BudgetedFixedAssets.DrillDown();
        CashFlowCard.Control1905906307.BudgetedFixedAssets.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnFactBoxForBudget()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"G/L Budget".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true; // consider some unrelated values as well
        SetupDrillDownOnFactBox(CashFlowCard, ConsiderSource);

        // Exercise
        CFLedgerEntries.Trap();
        CashFlowCard.Control1905906307.GLBudgets.DrillDown();

        // Verify - CFLedgerEntries should be filtered on budget source type only through DRILLDOWN
        CashFlowCard.Control1905906307.GLBudgets.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForTotal()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderAllSources(ConsiderSource);
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.Total.DrillDown();
        CashFlowStatistic.Total.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForServiceOrders()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.ServiceOrders.DrillDown();
        CashFlowStatistic.ServiceOrders.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForReceivables()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.Receivables.DrillDown();
        CashFlowStatistic.Receivables.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForPayables()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::Payables.AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.Payables.DrillDown();
        CashFlowStatistic.Payables.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForSalesOrders()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.SalesOrders.DrillDown();
        CashFlowStatistic.SalesOrders.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForPurchOrders()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Purchase Orders".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.PurchaseOrders.DrillDown();
        CashFlowStatistic.PurchaseOrders.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForLiquidFunds()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.LiquidFunds.DrillDown();
        CashFlowStatistic.LiquidFunds.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForManualExpenses()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Expense".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.ManualExpenses.DrillDown();
        CashFlowStatistic.ManualExpenses.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForManualRevenues()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Cash Flow Manual Revenue".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.ManualRevenues.DrillDown();
        CashFlowStatistic.ManualRevenues.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForSaleOfFA()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.SalesofFixedAssets.DrillDown();
        CashFlowStatistic.SalesofFixedAssets.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForBudgetedFA()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Budget".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Fixed Assets Disposal".AsInteger()] := true;
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        CFLedgerEntries.Trap();
        CashFlowStatistic.BudgetedFixedAssets.DrillDown();
        CashFlowStatistic.BudgetedFixedAssets.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDrillDownOnPAG868ForBudget()
    var
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
    begin
        // Setup
        Initialize();
        ConsiderSource["Cash Flow Source Type"::"G/L Budget".AsInteger()] := true;
        ConsiderSource["Cash Flow Source Type"::"Sales Orders".AsInteger()] := true; // create some unrelated entries as well
        SetupDrillDownOnPAG868(CashFlowStatistic, ConsiderSource);

        // Exercise
        CFLedgerEntries.Trap();
        CashFlowStatistic.GLBudgets.DrillDown();

        // Verify - ledger entries must be filtered on budget source through DRILLDOWN
        CashFlowStatistic.GLBudgets.AssertEquals(CalcSumOnLedgEntries(CFLedgerEntries));
    end;

    local procedure SetupDrillDownOnFactBox(var CashFlowCard: TestPage "Cash Flow Forecast Card"; ConsiderSource: array[16] of Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        PostedAmount: array[16, 2] of Decimal;
    begin
        // Setup
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);
        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);
    end;

    local procedure SetupDrillDownOnPAG868(var CashFlowStatistic: TestPage "Cash Flow Forecast Statistics"; ConsiderSource: array[16] of Boolean)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowCard: TestPage "Cash Flow Forecast Card";
        PostedAmount: array[16, 2] of Decimal;
    begin
        // Setup
        InsertCFLedgerEntries(CashFlowForecast, ConsiderSource, PostedAmount);
        // Exercise
        CashFlowCard.OpenView();
        CashFlowCard.GotoRecord(CashFlowForecast);
        CashFlowStatistic.Trap();
        CashFlowCard."&Statistics".Invoke();
    end;

    local procedure CalcSumOnLedgEntries(var CFLedgerEntries: TestPage "Cash Flow Forecast Entries") TotalAmountOnPage: Decimal
    begin
        CFLedgerEntries.First();
        repeat
            TotalAmountOnPage += CFLedgerEntries."Amount (LCY)".AsDecimal();
        until not CFLedgerEntries.Next();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLBudgetNameValidation()
    var
        CFWkshLine: Record "Cash Flow Worksheet Line";
        GLBudgetName: Record "G/L Budget Name";
    begin
        Initialize();

        LibraryERM.CreateGLBudgetName(GLBudgetName);

        CFWkshLine."Source Type" := CFWkshLine."Source Type"::"G/L Budget";
        CFWkshLine.Validate("G/L Budget Name", GLBudgetName.Name);

        CFWkshLine."Source Type" :=
            "Cash Flow Source Type".FromInteger(LibraryRandom.RandIntInRange(1, "Cash Flow Source Type"::"G/L Budget".AsInteger() - 1));
        asserterror CFWkshLine.Validate("G/L Budget Name", GLBudgetName.Name);
        Assert.ExpectedTestFieldError(CFWkshLine.FieldCaption("Source Type"), Format(CFWkshLine."Source Type"::"G/L Budget"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetChartTypeFunctionForStackedColumn()
    begin
        GetChartTypeFunction(CashFlowChartSetup."Chart Type"::"Stacked Column");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetChartTypeFunctionForStepLine()
    begin
        GetChartTypeFunction(CashFlowChartSetup."Chart Type"::"Step Line");
    end;

    local procedure GetChartTypeFunction(ChartType: Option)
    var
        Actual: Integer;
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup."Chart Type" := ChartType;
        CashFlowChartSetup.Modify();
        Actual := CashFlowChartSetup.GetChartType();
        if ChartType = CashFlowChartSetup."Chart Type"::"Step Line" then
            Assert.AreEqual(5, Actual, StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Chart Type")))
        else
            Assert.AreEqual(11, Actual, StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Chart Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetStartDateFunction()
    var
        Actual: Date;
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup."Start Date" := CashFlowChartSetup."Start Date"::"Working Date";
        CashFlowChartSetup.Modify();
        Actual := CashFlowChartSetup.GetStartDate();
        Assert.AreEqual(WorkDate(), Actual, StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Start Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCurrentSelectionTextFunction()
    begin
        Initialize();
        CreateAndUpdateCashFlowChartSetup(CashFlowChartSetup, CashFlowChartSetup."Start Date"::"First Entry Date",
          CashFlowChartSetup."Period Length"::Week, CashFlowChartSetup.Show::"Change in Cash",
          CashFlowChartSetup."Group By"::"Source Type");
        VerifyCashFlowChartSetupCurrentSelectionText();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCurrentSelectionTextFunctionWithMaxValues()
    var
        CFSetup: Record "Cash Flow Setup";
        OldCFNo: Code[20];
    begin
        Initialize();
        CreateAndUpdateCashFlowChartSetup(CashFlowChartSetup, CashFlowChartSetup."Start Date"::"First Entry Date",
          CashFlowChartSetup."Period Length"::Quarter, CashFlowChartSetup.Show::"Accumulated Cash",
          CashFlowChartSetup."Group By"::"Positive/Negative");
        CFSetup.Get();
        OldCFNo := SetChartCFNoInSetup(PadStr(CFSetup."CF No. on Chart in Role Center",
              MaxStrLen(CFSetup."CF No. on Chart in Role Center"), 'A'));
        VerifyCashFlowChartSetupCurrentSelectionText();
        SetChartCFNoInSetup(OldCFNo);
    end;

    local procedure VerifyCashFlowChartSetupCurrentSelectionText()
    var
        CFSetup: Record "Cash Flow Setup";
        Expected: Text[150];
    begin
        CFSetup.Get();
        Expected := StrSubstNo('%1 | %2 | %3 | %4 | %5', CFSetup."CF No. on Chart in Role Center", CashFlowChartSetup.Show,
            CashFlowChartSetup."Start Date", CashFlowChartSetup."Period Length", CashFlowChartSetup."Group By");
        Assert.IsTrue(StrPos(CashFlowChartSetup.GetCurrentSelectionText(), Expected) = 1,
          'Unexpected value returned from function GetCurrentSelectionText');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetGroupByFunctionPositiveNegative()
    begin
        SetAndVerifyGroupByValue(CashFlowChartSetup."Group By"::"Source Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetGroupByFunctionAccountNo()
    begin
        SetAndVerifyGroupByValue(CashFlowChartSetup."Group By"::"Positive/Negative");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetGroupByFunctionSourceType()
    begin
        SetAndVerifyGroupByValue(CashFlowChartSetup."Group By"::"Account No.");
    end;

    local procedure SetAndVerifyGroupByValue(GroupBy: Option)
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup.SetGroupBy(GroupBy);
        Assert.AreEqual(
          GroupBy, CashFlowChartSetup."Group By", StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Group By")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetStartDateFunction()
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup.SetStartDate(CashFlowChartSetup."Start Date"::"Working Date");
        Assert.AreEqual(CashFlowChartSetup."Start Date"::"Working Date", CashFlowChartSetup."Start Date",
          StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Start Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetChartTypeFunctionStackedArea()
    begin
        SetAndVerifyChartTypeValue(CashFlowChartSetup."Chart Type"::"Stacked Area (%)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetChartTypeFunctionStackedColumn()
    begin
        SetAndVerifyChartTypeValue(CashFlowChartSetup."Chart Type"::"Stacked Column");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetChartTypeFunctionStackedColumnPercentage()
    begin
        SetAndVerifyChartTypeValue(CashFlowChartSetup."Chart Type"::"Stacked Column (%)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetChartTypeFunctionStepline()
    begin
        SetAndVerifyChartTypeValue(CashFlowChartSetup."Chart Type"::"Step Line");
    end;

    local procedure SetAndVerifyChartTypeValue(ChartType: Option)
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup.SetChartType(ChartType);
        Assert.AreEqual(
          ChartType, CashFlowChartSetup."Chart Type", StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Chart Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetShowFunctionAccumulatedCash()
    begin
        SetAndVerifyShowValue(CashFlowChartSetup.Show::"Accumulated Cash");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetShowFunctionChangeinCash()
    begin
        SetAndVerifyShowValue(CashFlowChartSetup.Show::"Change in Cash");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetShowFunctionCombined()
    begin
        SetAndVerifyShowValue(CashFlowChartSetup.Show::Combined);
    end;

    local procedure SetAndVerifyShowValue(ShowOption: Option)
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup.SetShow(ShowOption);
        Assert.AreEqual(ShowOption, CashFlowChartSetup.Show, StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption(Show)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPeriodLengthFunctionDay()
    begin
        SetAndVerifyPeriodLengthValue(CashFlowChartSetup."Period Length"::Day);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPeriodLengthFunctionWeek()
    begin
        SetAndVerifyPeriodLengthValue(CashFlowChartSetup."Period Length"::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPeriodLengthFunctionMonth()
    begin
        SetAndVerifyPeriodLengthValue(CashFlowChartSetup."Period Length"::Month);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPeriodLengthFunctionQuarter()
    begin
        SetAndVerifyPeriodLengthValue(CashFlowChartSetup."Period Length"::Quarter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPeriodLengthFunctionYear()
    begin
        SetAndVerifyPeriodLengthValue(CashFlowChartSetup."Period Length"::Year);
    end;

    local procedure SetAndVerifyPeriodLengthValue(PeriodLength: Option)
    begin
        Initialize();
        CreateCashFlowChartSetup();
        CashFlowChartSetup.SetPeriodLength(PeriodLength);
        Assert.AreEqual(
          PeriodLength, CashFlowChartSetup."Period Length",
          StrSubstNo(UnexpectedValueInField, CashFlowChartSetup.FieldCaption("Period Length")));
    end;

    local procedure SetChartCFNoInSetup(ChartCashFlowNo: Code[20]) OldCFNo: Code[20]
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        CashFlowSetup.Get();
        OldCFNo := CashFlowSetup."CF No. on Chart in Role Center";
        CashFlowSetup."CF No. on Chart in Role Center" := ChartCashFlowNo;
        CashFlowSetup.Modify();
    end;

    local procedure CreateCashFlowChartSetup()
    begin
        if CashFlowChartSetup.Get(UserId) then
            CashFlowChartSetup.Delete();
        CashFlowChartSetup.Init();
        CashFlowChartSetup."User ID" := UserId;
        CashFlowChartSetup.Insert();
    end;

    local procedure CreateAndUpdateCashFlowChartSetup(var CashFlowChartSetup: Record "Cash Flow Chart Setup"; StartDate: Option; PeriodLength: Option; Show: Option; GroupBy: Option)
    begin
        CreateCashFlowChartSetup();
        CashFlowChartSetup."Start Date" := StartDate;
        CashFlowChartSetup."Period Length" := PeriodLength;
        CashFlowChartSetup.Show := Show;
        CashFlowChartSetup."Group By" := GroupBy;
        CashFlowChartSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPrintRecordsFromCashFlowForecastTable()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFReportSelection: Record "Cash Flow Report Selection";
    begin
        Initialize();
        CFReportSelection.DeleteAll();

        CashFlowForecast.PrintRecords(); // Can't be completely tested since it has REPORT.RUNMODAL
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssistEditFromCashFlowForecastTable()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        OldCashFlowForecast: Record "Cash Flow Forecast";
    begin
        if OldCashFlowForecast.FindFirst() then;
        asserterror CashFlowForecast.AssistEdit(OldCashFlowForecast);
        Assert.ExpectedError('Unhandled UI: ModalPage 456'); // Can't be completely tested since it's running modal page
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLookupCashFlowFilterFromCashFlowForecastTable()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Text: Text[1024];
    begin
        asserterror CashFlowForecast.LookupCashFlowFilter(Text);
        Assert.ExpectedError('Unhandled UI: ModalPage 849'); // Can't be completely tested since it's running modal page
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowMgt_RecurrenceToRecurringFrequency()
    var
        CashFlowMgt: Codeunit "Cash Flow Management";
        Recurrence: Option " ",Daily,Weekly,Monthly,Quarterly,Yearly;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 216302] COD 841 "Cash Flow Management".RecurrenceToRecurringFrequency() maps recurrence option to language-independent dateformula values (i.e. "<1D>")

        Assert.AreEqual('', CashFlowMgt.RecurrenceToRecurringFrequency(Recurrence::" "), '');
        Assert.AreEqual('<1D>', CashFlowMgt.RecurrenceToRecurringFrequency(Recurrence::Daily), '');
        Assert.AreEqual('<1W>', CashFlowMgt.RecurrenceToRecurringFrequency(Recurrence::Weekly), '');
        Assert.AreEqual('<1M>', CashFlowMgt.RecurrenceToRecurringFrequency(Recurrence::Monthly), '');
        Assert.AreEqual('<1Q>', CashFlowMgt.RecurrenceToRecurringFrequency(Recurrence::Quarterly), '');
        Assert.AreEqual('<1Y>', CashFlowMgt.RecurrenceToRecurringFrequency(Recurrence::Yearly), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowMgt_RecurringFrequencyToRecurrence()
    var
        CashFlowMgt: Codeunit "Cash Flow Management";
        RecurringFrequency: DateFormula;
        Recurrence: Option " ",Daily,Weekly,Monthly,Quarterly,Yearly;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 216302] COD 841 "Cash Flow Management".RecurringFrequencyToRecurrence() maps language-dependent dateformula values to recurrence option

        Evaluate(RecurringFrequency, '');
        CashFlowMgt.RecurringFrequencyToRecurrence(RecurringFrequency, Recurrence);
        Assert.AreEqual(Recurrence::" ", Recurrence, '');

        Evaluate(RecurringFrequency, '<1D>');
        CashFlowMgt.RecurringFrequencyToRecurrence(RecurringFrequency, Recurrence);
        Assert.AreEqual(Recurrence::Daily, Recurrence, '');

        Evaluate(RecurringFrequency, '<1W>');
        CashFlowMgt.RecurringFrequencyToRecurrence(RecurringFrequency, Recurrence);
        Assert.AreEqual(Recurrence::Weekly, Recurrence, '');

        Evaluate(RecurringFrequency, '<1M>');
        CashFlowMgt.RecurringFrequencyToRecurrence(RecurringFrequency, Recurrence);
        Assert.AreEqual(Recurrence::Monthly, Recurrence, '');

        Evaluate(RecurringFrequency, '<1Q>');
        CashFlowMgt.RecurringFrequencyToRecurrence(RecurringFrequency, Recurrence);
        Assert.AreEqual(Recurrence::Quarterly, Recurrence, '');

        Evaluate(RecurringFrequency, '<1Y>');
        CashFlowMgt.RecurringFrequencyToRecurrence(RecurringFrequency, Recurrence);
        Assert.AreEqual(Recurrence::Yearly, Recurrence, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SourceNoTableRelationForReceivablesNegative()
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        SourceNo: Code[20];
    begin
        // [FEATURE] [Receivables] [Customer Ledger Entry] [UT]
        // [SCENARIO 226697] "Source No." of receivables Cash Flow Forecast Entry must not allow to set values that are not in "Document No." of Customer Ledger Entries
        CashFlowForecastEntry.Init();
        CashFlowForecastEntry.Validate("Source Type", CashFlowForecastEntry."Source Type"::Receivables);
        SourceNo := LibraryUtility.GenerateGUID();
        asserterror CashFlowForecastEntry.Validate("Source No.", SourceNo);
        Assert.ExpectedError(StrSubstNo(CustLedgerEntryNotFoundErr, SourceNo));
        Assert.ExpectedErrorCode(NothingInsideFilterTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SourceNoTableRelationForReceivablesTrue()
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Receivables] [Customer Ledger Entry] [UT]
        // [SCENARIO 226697] "Source No." of receivables Cash Flow Forecast Entry must allow to set values that are in "Document No." of Customer Ledger Entries
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry.Insert();

        CashFlowForecastEntry.Init();
        CashFlowForecastEntry.Validate("Source Type", CashFlowForecastEntry."Source Type"::Receivables);
        CashFlowForecastEntry.Validate("Source No.", CustLedgerEntry."Document No.");
        CashFlowForecastEntry.TestField("Source No.", CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SourceNoTableRelationForPayablesNegative()
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        SourceNo: Code[20];
    begin
        // [FEATURE] [Payables] [Vendor Ledger Entry] [UT]
        // [SCENARIO 226697] "Source No." of payables Cash Flow Forecast Entry must not allow to set values that are not in "Document No." of Vendor Ledger Entries
        CashFlowForecastEntry.Init();
        CashFlowForecastEntry.Validate("Source Type", CashFlowForecastEntry."Source Type"::Payables);
        SourceNo := LibraryUtility.GenerateGUID();
        asserterror CashFlowForecastEntry.Validate("Source No.", SourceNo);
        Assert.ExpectedError(StrSubstNo(VendLedgerEntryNotFoundErr, SourceNo));
        Assert.ExpectedErrorCode(NothingInsideFilterTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SourceNoTableRelationForPayablesTrue()
    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Payables] [Vendor Ledger Entry] [UT]
        // [SCENARIO 226697] "Source No." of payables Cash Flow Forecast Entry must allow to set values that are in "Document No." of Vendor Ledger Entries
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry.Insert();

        CashFlowForecastEntry.Init();
        CashFlowForecastEntry.Validate("Source Type", CashFlowForecastEntry."Source Type"::Payables);
        CashFlowForecastEntry.Validate("Source No.", VendorLedgerEntry."Document No.");
        CashFlowForecastEntry.TestField("Source No.", VendorLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExcludeReverseChargesForTaxesFromVATEntries()
    var
        VATEntry: Record "VAT Entry";
        CashFlowManagement: Codeunit "Cash Flow Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 269517] Reverse Charge VAT operations are excluded from VAT Entries for Taxes from VAT Entries

        CashFlowManagement.SetViewOnVATEntryForTaxCalc(VATEntry, WorkDate());
        Assert.AreEqual(
          StrSubstNo('<>%1', VATEntry."VAT Calculation Type"::"Reverse Charge VAT"),
          VATEntry.GetFilter("VAT Calculation Type"),
          'Wrong filter of VAT Calculation Type');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastStatisticsWithManualPaymentsTo()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowForecastCard: TestPage "Cash Flow Forecast Card";
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        CFLedgerEntries: TestPage "Cash Flow Forecast Entries";
        ConsiderSource: array[16] of Boolean;
        LedgerEntryAmount: Decimal;
    begin
        Initialize();

        LedgerEntryAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        ConsiderSource["Cash Flow Source Type"::"Liquid Funds".AsInteger()] := true;

        LibraryCFHelper.CreateSpecificCashFlowCard(CashFlowForecast, false, false);
        CashFlowForecast.Validate("Manual Payments From", 0D);
        CashFlowForecast.Validate("Manual Payments To", WorkDate() - 2);
        CashFlowForecast.Modify(true);

        InsertCFLedgerEntriesDifferentDays(CashFlowForecast, ConsiderSource, LedgerEntryAmount);

        CashFlowForecastCard.OpenView();
        CashFlowForecastCard.Filter.SetFilter("No.", CashFlowForecast."No.");
        CashFlowForecastCard.Control1905906307.Total.AssertEquals(LedgerEntryAmount);
        CashFlowStatistic.Trap();
        CashFlowForecastCard."&Statistics".Invoke();

        CFLedgerEntries.Trap();
        CashFlowStatistic.LiquidFunds.DrillDown();
        CashFlowStatistic.LiquidFunds.AssertEquals(LedgerEntryAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastStatisticsWithManualPaymentsFrom()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CashFlowForecastCard: TestPage "Cash Flow Forecast Card";
        CashFlowStatistic: TestPage "Cash Flow Forecast Statistics";
        ConsiderSource: array[16] of Boolean;
        LedgerEntryAmount: Decimal;
    begin
        // [SCENARIO 537619] Cash Flow Forecast Statistics takes into consideration Manual Payments From
        Initialize();

        // [GIVEN] 2 entries for Receivables source type on 2 different days 01/01/24 and 02/01/24
        // [GIVEN] Set Manual Payments From to 02/01/24
        LedgerEntryAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        ConsiderSource["Cash Flow Source Type"::Receivables.AsInteger()] := true;

        LibraryCFHelper.CreateSpecificCashFlowCard(CashFlowForecast, false, false);
        CashFlowForecast.Validate("Manual Payments From", WorkDate() - 1);
        CashFlowForecast.Modify(true);

        InsertCFLedgerEntriesDifferentDays(CashFlowForecast, ConsiderSource, LedgerEntryAmount);

        // [WHEN] Open CF Statistics FactBox and CF Statistics page
        // [THEN] Receivables amount should be equal to the amount of the entry on 02/01/24
        CashFlowForecastCard.OpenView();
        CashFlowForecastCard.Filter.SetFilter("No.", CashFlowForecast."No.");
        CashFlowForecastCard.Control1905906307.Receivables.AssertEquals(LedgerEntryAmount);

        CashFlowStatistic.Trap();
        CashFlowForecastCard."&Statistics".Invoke();
        CashFlowStatistic.Receivables.AssertEquals(LedgerEntryAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowManualRevenueAssignDimension()
    var
        CashFlowManualRevenue: Record "Cash Flow Manual Revenue";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 410654] Validate Global Dimension Codes in Cash Flow Manual Revenue
        Initialize();

        CashFlowManualRevenue.InitNewRecord();
        CashFlowManualRevenue.Insert();
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue1);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue2);

        CashFlowManualRevenue.Validate("Global Dimension 1 Code", DimensionValue1.Code);
        CashFlowManualRevenue.Validate("Global Dimension 2 Code", DimensionValue2.Code);

        CashFlowManualRevenue.TestField("Global Dimension 1 Code", DimensionValue1.Code);
        CashFlowManualRevenue.TestField("Global Dimension 2 Code", DimensionValue2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastCardGLBudgetToDateEarlierThanFromDate()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
    begin
        CashFlowCard.OpenNew();
        CashFlowCard."G/L Budget From".SetValue(Today);
        AssertError CashFlowCard."G/L Budget To".SetValue(Today - 1);
        Assert.ExpectedError('The "G/L Budget To" date precedes the "G/L Budget From" date. Select an end date after the start date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastCardManualPaymentsToDateEarlierThanFromDate()
    var
        CashFlowCard: TestPage "Cash Flow Forecast Card";
    begin
        CashFlowCard.OpenNew();
        CashFlowCard."Manual Payments From".SetValue(Today);
        AssertError CashFlowCard."Manual Payments To".SetValue(Today - 1);
        Assert.ExpectedError('The "Manual Revenue/Expenses To" date precedes the "Manual Revenue/Expenses From" date. Select an end date after the start date.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Flow UnitTests");
        Evaluate(PlusOneDayFormula, '<+1D>');
        Evaluate(MinusOneDayFormula, '<-1D>');
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Flow UnitTests");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Flow UnitTests");
    end;

    local procedure InsertCFLedgerEntry(CashFlowNo: Code[20]; SourceType: Enum "Cash Flow Source Type"; CashFlowDate: Date; var LedgerAmount: Decimal)
    begin
        if SourceType in
            ["Cash Flow Source Type"::"Purchase Orders",
            "Cash Flow Source Type"::"Cash Flow Manual Expense",
            "Cash Flow Source Type"::"Fixed Assets Budget",
            "Cash Flow Source Type"::Payables]
        then
            LedgerAmount := -LedgerAmount;

        LibraryCFHelper.InsertCFLedgerEntry(CashFlowNo, '', SourceType, CashFlowDate, LedgerAmount);
    end;

    local procedure InsertCFLedgerEntriesDifferentDays(CashFlowForecast: Record "Cash Flow Forecast"; ConsiderSource: array[16] of Boolean; LedgerEntryAmount: Decimal)
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        SourceType: Integer;
        Index: Integer;
    begin
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.DeleteAll();

        for SourceType := 1 to ArrayLen(ConsiderSource) do
            if ConsiderSource[SourceType] then
                for Index := 1 to 2 do
                    InsertCFLedgerEntry(CashFlowForecast."No.", "Cash Flow Source Type".FromInteger(SourceType), WorkDate() - Index, LedgerEntryAmount);
    end;
}

