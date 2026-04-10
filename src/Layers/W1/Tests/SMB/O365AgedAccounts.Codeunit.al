codeunit 138027 "O365 Aged Accounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Aged Acc. Receivable] [SMB] [Sales]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        WrongAmmountColumnTxt: Label 'Wrong amount for data column %1.';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        ExpectedRowCount: Integer;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPeriodLengthWeek()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerNo: Code[20];
        AmountSum: Decimal;
        StartDate: Date;
    begin
        // Setup
        Initialize();

        // Create Customer Ledger Entries
        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesWeekView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');

        AmountSum := 0;
        if TempEntryNoAmountBuffer.FindSet() then
            repeat
                AmountSum := AmountSum + TempEntryNoAmountBuffer.Amount;

                case TempEntryNoAmountBuffer."Entry No." of
                    0:
                        Assert.AreEqual(
                          1000, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    1:
                        Assert.AreEqual(
                          11000, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    2:
                        Assert.AreEqual(
                          9000, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13:
                        Assert.AreEqual(
                          0, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                end;
            until TempEntryNoAmountBuffer.Next() = 0;

        Assert.AreEqual(21000, AmountSum, 'Wrong total amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPeriodLengthMonth()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerNo: Code[20];
        AmountSum: Decimal;
        StartDate: Date;
    begin
        // Setup
        Initialize();

        // Create Customer Ledger Entries
        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesMonthView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Month;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');

        AmountSum := 0;
        if TempEntryNoAmountBuffer.FindSet() then
            repeat
                AmountSum := AmountSum + TempEntryNoAmountBuffer.Amount;

                case TempEntryNoAmountBuffer."Entry No." of
                    0:
                        Assert.AreEqual(
                          1500, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11:
                        Assert.AreEqual(
                          0, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    12:
                        Assert.AreEqual(
                          17000, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    13:
                        Assert.AreEqual(
                          12500, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                end;
            until TempEntryNoAmountBuffer.Next() = 0;

        Assert.AreEqual(31000, AmountSum, 'Wrong total amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPeriodLengthYear()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerNo: Code[20];
        AmountSum: Decimal;
        StartDate: Date;
    begin
        // Setup
        Initialize();

        // Create Customer Ledger Entries
        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesYearView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Year;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(7, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');

        AmountSum := 0;
        if TempEntryNoAmountBuffer.FindSet() then
            repeat
                AmountSum := AmountSum + TempEntryNoAmountBuffer.Amount;

                case TempEntryNoAmountBuffer."Entry No." of
                    0:
                        Assert.AreEqual(
                          2000, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    1, 2, 3, 4:
                        Assert.AreEqual(
                          0, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    5:
                        Assert.AreEqual(
                          22000, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                    6:
                        Assert.AreEqual(
                          7500, TempEntryNoAmountBuffer.Amount, StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
                end;
            until TempEntryNoAmountBuffer.Next() = 0;

        Assert.AreEqual(31500, AmountSum, 'Wrong total amount');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPeriodLengthWeekAddin()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        OfficeHostType: DotNet OfficeHostType;
        CustomerNo: Code[20];
        StartDate: Date;
    begin
        // Setup
        Initialize();
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemRead);

        // Create Customer Ledger Entries
        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesWeekView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPeriodLengthMonthAddin()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        OfficeHostType: DotNet OfficeHostType;
        CustomerNo: Code[20];
        StartDate: Date;
    begin
        // Setup
        Initialize();
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemRead);

        // Create Customer Ledger Entries
        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesMonthView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Month;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPeriodLengthYearAddin()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        OfficeHostType: DotNet OfficeHostType;
        CustomerNo: Code[20];
        StartDate: Date;
    begin
        // Setup
        Initialize();
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemRead);

        // Create Customer Ledger Entries
        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesYearView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Year;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(7, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPerGroupPeriodWeek()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustGroupCode: Code[20];
        StartDate: Date;
        StartAmount: Decimal;
        NoOfEntriesPerPeriod: Integer;
    begin
        // Setup
        Initialize();

        StartDate := WorkDate();

        // Create entries to exclude from verification
        CreateCustGroupLedgEntries2perWeek(CreateCustPostingGroup(), StartDate, 100);
        CreateCustGroupLedgEntries2perWeek(CreateCustPostingGroup(), StartDate, 1);

        // Create the entries for verification
        CustGroupCode := CreateCustPostingGroup();
        StartAmount := 1000;
        NoOfEntriesPerPeriod := CreateCustGroupLedgEntries2perWeek(CustGroupCode, StartDate, StartAmount);
        NoOfEntriesPerPeriod += CreateCustGroupLedgEntries2perWeek(CustGroupCode, StartDate, StartAmount);

        // Generate Aged Accounts Receivable Data Set per group
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;
        AgedAccReceivable.UpdateDataPerGroup(BusinessChartBuffer, TempEntryNoAmountBuffer);

        // Verify Data Points for Customer Posting Group
        TempEntryNoAmountBuffer.SetRange("Business Unit Code", CustGroupCode);
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');
        if TempEntryNoAmountBuffer.FindSet() then
            repeat
                Assert.AreEqual(
                  NoOfEntriesPerPeriod * StartAmount * (TempEntryNoAmountBuffer."Entry No." + 1),
                  TempEntryNoAmountBuffer.Amount,
                  StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
            until TempEntryNoAmountBuffer.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CustLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure TestReceivableEntriesDrillDown()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerNo: Code[20];
        StartDate: Date;
    begin
        // Setup
        Initialize();

        StartDate := CreateStartDate();
        CustomerNo := CreateCustomer();
        CreateCustomerLedgEntriesWeekView(CustLedgerEntry, CustomerNo, StartDate);

        // Generate Aged Accounts Receivable Data Set
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;

        AgedAccReceivable.UpdateDataPerCustomer(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verification - drill down on the first 4 columns
        Clear(ExpectedRowCount);
        // Verify DrillDown for Data Point "0"
        BusinessChartBuffer."Drill-Down X Index" := 0;
        ExpectedRowCount := 1;
        AgedAccReceivable.DrillDown(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify DrillDown for Data Point "0"
        BusinessChartBuffer."Drill-Down X Index" := 1;
        ExpectedRowCount := 2;
        AgedAccReceivable.DrillDown(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify DrillDown for Data Point "2"
        BusinessChartBuffer."Drill-Down X Index" := 2;
        ExpectedRowCount := 3;
        AgedAccReceivable.DrillDown(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);

        // Verify DrillDown for Data Point "3" - Drill Down page is not invoked
        BusinessChartBuffer."Drill-Down X Index" := 3;
        ExpectedRowCount := 0;
        AgedAccReceivable.DrillDown(
          BusinessChartBuffer, CustomerNo, TempEntryNoAmountBuffer);
    end;

    [Test]
    [HandlerFunctions('CustLedgEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure TestReceivableGroupEntDrillDown()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustGroupCode: Code[20];
        StartDate: Date;
        StartAmount: Decimal;
        NoOfEntriesPerPeriod: Integer;
    begin
        // Setup
        Initialize();

        StartDate := Today;
        // Create entries to exclude from verification
        CreateCustGroupLedgEntries2perWeek(CreateCustPostingGroup(), StartDate, 100);
        CreateCustGroupLedgEntries2perWeek(CreateCustPostingGroup(), StartDate, 1);

        // Create the entries for verification
        CustGroupCode := CreateCustPostingGroup();
        StartAmount := 1000;
        NoOfEntriesPerPeriod := CreateCustGroupLedgEntries2perWeek(CustGroupCode, StartDate, StartAmount);
        NoOfEntriesPerPeriod += CreateCustGroupLedgEntries2perWeek(CustGroupCode, StartDate, StartAmount);

        // Generate Aged Accounts Receivable Data Set per group
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;
        AgedAccReceivable.UpdateDataPerGroup(BusinessChartBuffer, TempEntryNoAmountBuffer);

        // Verify DrillDown for Customer Posting Group
        TempEntryNoAmountBuffer.SetRange("Business Unit Code", CustGroupCode);
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');
        if TempEntryNoAmountBuffer.FindSet() then
            repeat
                ExpectedRowCount := NoOfEntriesPerPeriod;
                AgedAccReceivable.DrillDownCustLedgEntries(
                  '', TempEntryNoAmountBuffer."Business Unit Code",
                  TempEntryNoAmountBuffer."Start Date", TempEntryNoAmountBuffer."End Date");
            until TempEntryNoAmountBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnOpenReceivableChart()
    var
        BusinessChartUserSetup: Record "Business Chart User Setup";
        AgedAccReceivableChart: TestPage "Aged Acc. Receivable Chart";
        Found: Boolean;
    begin
        // Setup
        Initialize();

        if BusinessChartUserSetup.Get(UserId, BusinessChartUserSetup."Object Type"::Page, GetAgedAccReceivableChartID()) then
            BusinessChartUserSetup.Delete();

        AgedAccReceivableChart.OpenView();
        Found := BusinessChartUserSetup.Get(UserId, BusinessChartUserSetup."Object Type"::Page, GetAgedAccReceivableChartID());

        // Verify that the default values for User Setup are populated on open chart page
        Assert.IsTrue(Found, 'Business Chart record not inserted');
        Assert.AreEqual(
          Format(BusinessChartUserSetup."Period Length"::Week),
          Format(BusinessChartUserSetup."Period Length"), 'Wrong default value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnCloseReceivableChart()
    var
        BusinessChartUserSetup: Record "Business Chart User Setup";
        Found: Boolean;
    begin
        // Setup
        Initialize();

        BusinessChartUserSetup."Period Length" := BusinessChartUserSetup."Period Length"::Year;
        BusinessChartUserSetup.SaveSetupPage(BusinessChartUserSetup, GetAgedAccReceivableChartID());

        Found := BusinessChartUserSetup.Get(UserId, BusinessChartUserSetup."Object Type"::Page, GetAgedAccReceivableChartID());

        // Verify that the selected values are saved
        Assert.IsTrue(Found, 'Business Chart record not inserted');
        Assert.AreEqual(
          Format(BusinessChartUserSetup."Period Length"::Year),
          Format(BusinessChartUserSetup."Period Length"), 'Wrong period length');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvPmtAvgDaysLater()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerNo: Code[20];
        DueDate: Date;
        PaymentDate: Date;
        NoOfInv: Integer;
        DaysTotal: Integer;
        Days: Integer;
    begin
        // The average days for payment of invoices is calculated by total no of days
        // counted from Due Date to Payment Date divided by total number of payed invoices.
        // A positive value is late payment, a negative value is early payment.
        // Setup
        Initialize();

        CustomerNo := CreateCustomer();

        // Invoice 1
        DueDate := CalcDate('<1M>', WorkDate());
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo, WorkDate(), DueDate, 0, false, CustLedgerEntry."Document Type"::Invoice, '');
        Days := 7; // Payment 7 days after due date
        PaymentDate := CalcDateDays(Days, DueDate);
        CreateDetailedCustLedgEntry(
          CustLedgerEntry."Entry No.", GetDetailedCustLedgEntryNo(), PaymentDate, DetailedCustLedgEntry."Document Type"::Payment);

        NoOfInv += 1;
        DaysTotal += Days;

        // Invoice 2
        DueDate := CalcDate('<2M>', WorkDate());
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo, WorkDate(), DueDate, 0, false, CustLedgerEntry."Document Type"::Invoice, '');
        Days := 4; // Payment 4 days after due date
        PaymentDate := CalcDateDays(Days, DueDate);
        CreateDetailedCustLedgEntry(
          CustLedgerEntry."Entry No.", 0, PaymentDate, DetailedCustLedgEntry."Document Type"::Payment);

        NoOfInv += 1;
        DaysTotal += Days;

        // Verify
        Assert.AreEqual(
          Round(DaysTotal / NoOfInv, 1),
          AgedAccReceivable.InvoicePaymentDaysAverage(CustomerNo),
          'Wrong calculation of days to pay invoice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvPmtAvgDaysSooner()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AgedAccReceivable: Codeunit "Aged Acc. Receivable";
        CustomerNo: Code[20];
        DueDate: Date;
        PaymentDate: Date;
        NoOfInv: Integer;
        DaysTotal: Integer;
        Days: Integer;
    begin
        // The average days for payment of invoices is calculated by total no of days
        // counted from Due Date to Payment Date divided by total number of payed invoices.
        // A positive value is late payment, a negative value is early payment.
        // Setup
        Initialize();

        CustomerNo := CreateCustomer();

        // Invoice 1
        DueDate := CalcDate('<1M>', WorkDate());
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo, WorkDate(), DueDate, 0, false, CustLedgerEntry."Document Type"::Invoice, '');
        Days := -12; // Payment 12 days before due date
        PaymentDate := CalcDateDays(Days, DueDate);
        CreateDetailedCustLedgEntry(
          CustLedgerEntry."Entry No.", 0, PaymentDate, DetailedCustLedgEntry."Document Type"::Payment);

        NoOfInv += 1;
        DaysTotal += Days;

        // Invoice 2
        DueDate := CalcDate('<2M>', WorkDate());
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo, WorkDate(), DueDate, 0, false, CustLedgerEntry."Document Type"::Invoice, '');
        // First payment 3 days before due date - this entry should be ignored by calculation since there is a later payment
        Days := -3;
        PaymentDate := CalcDateDays(Days, DueDate);
        CreateDetailedCustLedgEntry(
          CustLedgerEntry."Entry No.", 0, PaymentDate, DetailedCustLedgEntry."Document Type"::Payment);
        Days := 2; // Last Payment 2 days after due date
        PaymentDate := CalcDateDays(Days, DueDate);
        CreateDetailedCustLedgEntry(
          CustLedgerEntry."Entry No.", 0, PaymentDate, DetailedCustLedgEntry."Document Type"::Payment);

        NoOfInv += 1;
        DaysTotal += Days;

        // Verify
        Assert.AreEqual(
          Round(DaysTotal / NoOfInv, 1),
          AgedAccReceivable.InvoicePaymentDaysAverage(CustomerNo),
          'Wrong calculation of days to pay invoice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChartDataPayablesPeriodWeek()
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        TempEntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        TempEntryNoAmountBuf2: Record "Entry No. Amount Buffer" temporary;
        AgedAccPayable: Codeunit "Aged Acc. Payable";
        StartDate: Date;
        StartAmount: Decimal;
        NoOfEntriesPerPeriod: Integer;
    begin
        // Setup
        Initialize();

        StartDate := WorkDate();
        BusinessChartBuffer."Period Filter Start Date" := StartDate;
        BusinessChartBuffer."Period Length" := BusinessChartBuffer."Period Length"::Week;

        // Data set before verification
        AgedAccPayable.UpdateData(BusinessChartBuffer, TempEntryNoAmountBuf2);

        // Create the entries for verification
        StartAmount := 1000;
        NoOfEntriesPerPeriod := CreateVendLedgEntries2perWeek(StartDate, StartAmount);
        NoOfEntriesPerPeriod += CreateVendLedgEntries2perWeek(StartDate, StartAmount);

        // Generate Aged Accounts Receivable Data Set
        AgedAccPayable.UpdateData(BusinessChartBuffer, TempEntryNoAmountBuffer);

        // Verify Data Points
        Assert.AreEqual(14, TempEntryNoAmountBuffer.Count, 'Wrong number of Data Columns in Data Buffer Table');

        if TempEntryNoAmountBuffer.FindSet() then
            repeat
                TempEntryNoAmountBuf2.Get('', TempEntryNoAmountBuffer."Entry No.");

                Assert.AreEqual(
                  NoOfEntriesPerPeriod * StartAmount * (TempEntryNoAmountBuffer."Entry No." + 1),
                  TempEntryNoAmountBuffer.Amount - TempEntryNoAmountBuf2.Amount,
                  StrSubstNo(WrongAmmountColumnTxt, TempEntryNoAmountBuffer."Entry No."));
            until TempEntryNoAmountBuffer.Next() = 0;
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustPostingGroup(): Code[20]
    var
        CustPostingGroup: Record "Customer Posting Group";
    begin
        CustPostingGroup.Init();
        CustPostingGroup.Code := LibraryUtility.GenerateGUID();
        CustPostingGroup.Insert();
        exit(CustPostingGroup.Code);
    end;

    local procedure CreateCustomerLedgEntriesWeekView(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; StartDate: Date)
    var
        PostingDate: Date;
        DueDate: Date;
        Amount: Decimal;
    begin
        CustLedgerEntry."Entry No." := GetCustLedgEntryNo();

        // Data entries that is included in columns
        PostingDate := StartDate;
        DueDate := CalcDate('<+1M>', PostingDate);
        Amount := 1000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+4D>', PostingDate);
        Amount := 2000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+5D>', PostingDate);
        Amount := 3000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Payment, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+6D>', PostingDate);
        Amount := 4000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::"Credit Memo", '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+7D>', PostingDate);
        Amount := 5000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+8D>', PostingDate);
        Amount := 6000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        // Data entries that is NOT included in columns
        CustLedgerEntry."Entry No." += 1;
        DueDate := CalcDate('<+1M>', PostingDate);
        Amount := 1000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+5D>', PostingDate);
        Amount := 2000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-2W>', StartDate);
        DueDate := CalcDate('<+8D>', PostingDate);
        Amount := 3000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');
    end;

    local procedure CreateCustomerLedgEntriesMonthView(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; StartDate: Date)
    var
        PostingDate: Date;
        DueDate: Date;
        Amount: Decimal;
    begin
        CustLedgerEntry."Entry No." := GetCustLedgEntryNo();

        // Data entries that is included in columns
        PostingDate := StartDate;
        DueDate := CalcDate('<+1M>', PostingDate);
        Amount := 1500;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+2W>', PostingDate);
        Amount := 3000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+3W>', PostingDate);
        Amount := 4500;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Payment, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+4W>', PostingDate);
        Amount := 5000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::"Credit Memo", '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+5W>', PostingDate);
        Amount := 8000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+6W>', PostingDate);
        Amount := 9000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        // Data entries that is NOT included in columns
        CustLedgerEntry."Entry No." += 1;
        DueDate := CalcDate('<+1M>', PostingDate);
        Amount := 1000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+3W>', PostingDate);
        Amount := 2000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+6W>', PostingDate);
        Amount := 3000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');
    end;

    local procedure CreateCustomerLedgEntriesYearView(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; StartDate: Date)
    var
        PostingDate: Date;
        DueDate: Date;
        Amount: Decimal;
    begin
        CustLedgerEntry."Entry No." := GetCustLedgEntryNo();

        // Data entries that is included in columns
        PostingDate := StartDate;
        DueDate := CalcDate('<+1M>', PostingDate);
        Amount := 2000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-5Y-2W>', StartDate);
        DueDate := CalcDate('<+1W+2D>', PostingDate);
        Amount := 3000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-5Y-2W>', StartDate);
        DueDate := CalcDate('<+1W+6D>', PostingDate);
        Amount := 4500;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Payment, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-5Y-2W>', StartDate);
        DueDate := CalcDate('<+1W+7D>', PostingDate);
        Amount := 5000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::"Credit Memo", '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-5Y-2W>', StartDate);
        DueDate := CalcDate('<+1W+8D>', PostingDate);
        Amount := 8000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-5Y-2W>', StartDate);
        DueDate := CalcDate('<+1W+9D>', PostingDate);
        Amount := 9000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, true, CustLedgerEntry."Document Type"::Invoice, '');

        // Data entries that is NOT included in columns
        CustLedgerEntry."Entry No." += 1;
        DueDate := CalcDate('<+1M>', PostingDate);
        Amount := 1000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+3W>', PostingDate);
        Amount := 2000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');

        CustLedgerEntry."Entry No." += 1;
        PostingDate := CalcDate('<-13M>', StartDate);
        DueDate := CalcDate('<+6W>', PostingDate);
        Amount := 3000;
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo,
          PostingDate, DueDate, Amount, false, CustLedgerEntry."Document Type"::Invoice, '');
    end;

    local procedure CreateCustGroupLedgEntries2perWeek(CustGroupCode: Code[20]; StartDate: Date; StartAmount: Decimal): Integer
    var
        i: Integer;
    begin
        for i := 1 to 14 do begin
            CreateOpenInvCustLedgEntry(Format(i), StartDate, StartAmount * i, CustGroupCode);
            CreateOpenInvCustLedgEntry(Format(i), CalcDate('<1D>', StartDate), StartAmount * i, CustGroupCode);

            StartDate := CalcDate('<-1W>', StartDate);
        end;

        exit(2);
    end;

    local procedure CreateVendLedgEntries2perWeek(StartDate: Date; StartAmount: Decimal): Integer
    var
        i: Integer;
    begin
        for i := 1 to 14 do begin
            CreateVendLedgEntry(Format(i), StartDate, -StartAmount * i);
            CreateVendLedgEntry(Format(i), CalcDate('<1D>', StartDate), -StartAmount * i);

            StartDate := CalcDate('<-1W>', StartDate);
        end;

        exit(2);
    end;

    local procedure CreateOpenInvCustLedgEntry(CustomerNo: Code[20]; DueDate: Date; AmountLCY: Decimal; CustPostingGroup: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateCustomerLedgEntry(
          CustLedgerEntry, CustomerNo, WorkDate(), DueDate, AmountLCY,
          true, CustLedgerEntry."Document Type"::Invoice, CustPostingGroup);
    end;

    local procedure CreateCustomerLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date; DueDate: Date; AmountLCY: Decimal; DocOpen: Boolean; DocType: Enum "Gen. Journal Document Type"; CustPostingGroup: Code[20])
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := GetCustLedgEntryNo();
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry.Open := DocOpen;
        CustLedgerEntry."Document Type" := DocType;
        CustLedgerEntry."Customer Posting Group" := CustPostingGroup;
        CustLedgerEntry.Insert();

        CreateDetailedCustLedgEntry(CustLedgerEntry."Entry No.", AmountLCY, PostingDate, DocType);
    end;

    local procedure CreateDetailedCustLedgEntry(CustLedgNo: Integer; AmountLCY: Decimal; PostingDate: Date; DocType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := GetDetailedCustLedgEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgNo;
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedCustLedgEntry."Document Type" := DocType;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure GetCustLedgEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetDetailedCustLedgEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure CreateVendLedgEntry(VendorNo: Code[20]; DueDate: Date; AmountLCY: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Init();
        VendLedgEntry."Entry No." := GetVendLedgEntryNo();
        VendLedgEntry."Due Date" := DueDate;
        VendLedgEntry."Vendor No." := VendorNo;
        VendLedgEntry.Open := true;
        VendLedgEntry."Document Type" := VendLedgEntry."Document Type"::Invoice;
        VendLedgEntry.Insert();

        CreateDetailedVendLedgEntry(VendLedgEntry."Entry No.", AmountLCY, DueDate);
    end;

    local procedure CreateDetailedVendLedgEntry(VendLedgEntryNo: Integer; AmountLCY: Decimal; PostingDate: Date)
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendLedgEntry.Init();
        DetailedVendLedgEntry."Entry No." := GetDetailedVendLedgEntryNo();
        DetailedVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        DetailedVendLedgEntry."Posting Date" := PostingDate;
        DetailedVendLedgEntry."Amount (LCY)" := AmountLCY;
        DetailedVendLedgEntry."Document Type" := DetailedVendLedgEntry."Document Type"::Invoice;
        DetailedVendLedgEntry.Insert();
    end;

    local procedure GetVendLedgEntryNo(): Integer
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgerEntry.FindLast() then
            exit(VendLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetDetailedVendLedgEntryNo(): Integer
    var
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if DetailedVendLedgEntry.FindLast() then
            exit(DetailedVendLedgEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetAgedAccReceivableChartID(): Integer
    begin
        exit(PAGE::"Aged Acc. Receivable Chart");
    end;

    local procedure CalcDateDays(Days: Integer; StartDate: Date): Date
    begin
        exit(CalcDate('<' + Format(Days) + 'D>', StartDate));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustLedgEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    var
        i: Integer;
    begin
        CustomerLedgerEntries.First();
        i := 1;
        while CustomerLedgerEntries.Next() do
            i += 1;
        Assert.AreEqual(ExpectedRowCount, i, 'Wrong number of entries');
    end;

    local procedure CreateStartDate(): Date
    begin
        exit(DMY2Date(15, 1, 2015));
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Aged Accounts");
        LibraryApplicationArea.EnableFoundationSetup();
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        SetOfficeHostUnAvailable();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Aged Accounts");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Aged Accounts");
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;
}

