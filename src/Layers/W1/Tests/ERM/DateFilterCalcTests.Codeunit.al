codeunit 135050 "DateFilter-Calc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Accounting Period] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateFiscalYearFilterWithNoAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        "Filter": Text[30];
        Name: Text[30];
    begin
        // [SCENARIO] CreateFiscalYearFilter function returns empty filter when there is no Accounting Period

        // [GIVEN] There is no Accounting Period
        AccountingPeriod.DeleteAll();

        // [WHEN] CreateAccountingPeriodFilter function is called
        DateFilterCalc.CreateFiscalYearFilter(Filter, Name, WorkDate(), 0);

        // [THEN] The Filter returned is empty
        Assert.AreEqual('', Filter, 'Filter was expected empty');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateAccountingPeriodFilterWithNoAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        "Filter": Text[30];
        Name: Text[30];
    begin
        // [SCENARIO] CreateAccountingPeriodFilter function returns empty filter when there is no Accounting Period

        // [GIVEN] There is no Accounting Period
        AccountingPeriod.DeleteAll();

        // [WHEN] CreateAccountingPeriodFilter function is called
        DateFilterCalc.CreateAccountingPeriodFilter(Filter, Name, WorkDate(), 0);

        // [THEN] The Filter returned is empty
        Assert.AreEqual('', Filter, 'Filter was expected empty');
    end;
}

