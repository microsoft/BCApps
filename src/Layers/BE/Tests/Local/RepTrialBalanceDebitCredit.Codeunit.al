codeunit 144014 "Rep Trial Balance Debit/Credit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        AssertHelper: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('RHTrailBalanceDebitCredit')]
    [Scope('OnPrem')]
    procedure TestTrailBalanceDebitCredit()
    begin
        TrailingBalanceDebitCredit(false, CalcDate('<-24M>', WorkDate()), CalcDate('<+11M><+8D>', WorkDate()));
        TrailingBalanceDebitCredit(false, WorkDate(), CalcDate('<+11M><+8D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('RHTrailBalanceDebitCredit')]
    [Scope('OnPrem')]
    procedure TestTrailBalanceDebitCreditAMts()
    begin
        TrailingBalanceDebitCredit(true, CalcDate('<-24M>', WorkDate()), CalcDate('<+11M><+8D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('RHTrailBalanceDebitCreditNoStartDate')]
    [Scope('OnPrem')]
    procedure TestTrailBalanceDebitCreditNoStartDate()
    begin
        // There is a bug in the report which sets an invalid date filter if the startdate is the minimum NAV date 01010000D.
        asserterror REPORT.Run(REPORT::"Trial Balance - Debit/Credit");
        AssertHelper.AreEqual('DateInvalid', GetLastErrorCode, 'invalid error code');
    end;

    [Normal]
    local procedure TrailingBalanceDebitCredit(UseAmtsInAddCurr: Boolean; StartDate: Date; EndDate: Date)
    var
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Variant: Variant;
        DateFilter: Text;
        YearCreditValue: Decimal;
        YearDebitValue: Decimal;
        ABSYearBalanceAtDate: Decimal;
        ABSYearNetChange: Decimal;
        I: Integer;
        RowIndex: Integer;
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(UseAmtsInAddCurr); // Use local currency
        LibraryVariableStorage.Enqueue(Format(StartDate)); // start date
        LibraryVariableStorage.Enqueue(Format(EndDate)); // end date

        REPORT.Run(REPORT::"Trial Balance - Debit/Credit");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.GetElementValueInCurrentRow('PeriodText', Variant);
        DateFilter := Variant;
        GeneralLedgerSetup.Get();
        GLAccount.SetFilter("Date Filter", DateFilter);
        for I := 1 to 2 do begin
            if I = 1 then begin
                GLAccount.FindFirst();
                LibraryReportDataset.GetNextRow();
            end else begin
                GLAccount.FindLast();
                LibraryReportDataset.GetLastRow();
            end;

            GLAccount.CalcFields("Debit Amount", "Credit Amount", "Add.-Currency Credit Amount", "Add.-Currency Debit Amount");

            LibraryReportDataset.GetElementValueInCurrentRow('YearCredit', Variant);
            YearCreditValue := Variant;

            if UseAmtsInAddCurr then
                AssertHelper.AreNearlyEqual(GLAccount."Add.-Currency Credit Amount", YearCreditValue,
                  GLAccount."Add.-Currency Credit Amount" / 10000,
                  'Add.-Currency credit amount')
            else
                AssertHelper.AreNearlyEqual(GLAccount."Credit Amount", YearCreditValue, GLAccount."Credit Amount" / 10000,
                  'Credit amount');
        end;

        // Find the record containing Account No 7, INCOME STATEMENT
        GLAccount.SetFilter("No.", '7');
        if not GLAccount.FindFirst() then
            exit;

        GLAccount.SetRange("Date Filter", 0D, ClosingDate(StartDate - 1));
        GLAccount.CalcFields("Net Change", "Additional-Currency Net Change");

        GLAccount.SetRange("Date Filter", StartDate, EndDate);
        GLAccount.CalcFields("Debit Amount", "Credit Amount", "Balance at Date", "Add.-Currency Debit Amount",
          "Add.-Currency Credit Amount", "Add.-Currency Balance at Date");

        LibraryReportDataset.MoveToRow(1);
        // There is a bug in the library, so FindRow clears the CurrentRow on return
        // which means that you have to use MoveToRow to position the cursor on the desired row.
        RowIndex := LibraryReportDataset.FindRow('GLAccNo', '7');
        AssertHelper.AreNotEqual(-1, RowIndex, 'RowIndex');
        LibraryReportDataset.MoveToRow(RowIndex + 1); // Yet another bug in the librarys FindRow function.

        LibraryReportDataset.GetElementValueInCurrentRow('YearCredit', Variant);
        YearCreditValue := Variant;

        LibraryReportDataset.FindCurrentRowValue('YearDebit', Variant);
        YearDebitValue := Variant;

        LibraryReportDataset.FindCurrentRowValue('ABSYearBalanceAtDate', Variant);
        ABSYearBalanceAtDate := Variant;

        LibraryReportDataset.FindCurrentRowValue('ABSYearNetChange', Variant);
        ABSYearNetChange := Variant;

        if UseAmtsInAddCurr then begin
            AssertHelper.AreNearlyEqual(GLAccount."Add.-Currency Credit Amount", YearCreditValue,
              GLAccount."Add.-Currency Credit Amount" / 10000, 'Credit amount');
            AssertHelper.AreNearlyEqual(GLAccount."Add.-Currency Debit Amount", YearDebitValue,
              GLAccount."Add.-Currency Debit Amount" / 10000, 'Debit amount');
            AssertHelper.AreNearlyEqual(GLAccount."Add.-Currency Balance at Date", ABSYearBalanceAtDate,
              GLAccount."Add.-Currency Balance at Date" / 10000, 'Year balance amount');
            AssertHelper.AreNearlyEqual(GLAccount."Additional-Currency Net Change", ABSYearNetChange,
              GLAccount."Additional-Currency Net Change" / 10000, 'Year net change amount');
        end else begin
            AssertHelper.AreNearlyEqual(GLAccount."Credit Amount", YearCreditValue,
              GLAccount."Credit Amount" / 10000, 'Credit amount');
            AssertHelper.AreNearlyEqual(GLAccount."Debit Amount", YearDebitValue,
              GLAccount."Debit Amount" / 10000, 'Debit amount');
            AssertHelper.AreNearlyEqual(Abs(GLAccount."Balance at Date"), Abs(ABSYearBalanceAtDate),
              Abs(GLAccount."Balance at Date" / 10000), 'Year balance amount');
            AssertHelper.AreNearlyEqual(Abs(GLAccount."Net Change"), Abs(ABSYearNetChange),
              Abs(GLAccount."Net Change" / 10000), 'Year net change amount');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrailBalanceDebitCredit(var TrailBalanceDebitCredit: TestRequestPage "Trial Balance - Debit/Credit")
    var
        LocalVariant: Variant;
        UseAmtsInAddCurr: Boolean;
        StartDate: Text;
        EndDate: Text;
    begin
        LibraryVariableStorage.Dequeue(LocalVariant);
        UseAmtsInAddCurr := LocalVariant;

        LibraryVariableStorage.Dequeue(LocalVariant);
        StartDate := LocalVariant;

        LibraryVariableStorage.Dequeue(LocalVariant);
        EndDate := LocalVariant;

        TrailBalanceDebitCredit.UseAmtsInAddCurr.SetValue(UseAmtsInAddCurr);
        TrailBalanceDebitCredit."G/L Account".SetFilter("Date Filter", StrSubstNo('%1..%2', StartDate, EndDate));
        TrailBalanceDebitCredit.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHTrailBalanceDebitCreditNoStartDate(var TrailBalanceDebitCredit: TestRequestPage "Trial Balance - Debit/Credit")
    begin
        TrailBalanceDebitCredit."G/L Account".SetFilter("Date Filter", StrSubstNo('%1..%2', 00000101D,
            Format(CalcDate('<+11M><+8D>', WorkDate()))));
        TrailBalanceDebitCredit.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

