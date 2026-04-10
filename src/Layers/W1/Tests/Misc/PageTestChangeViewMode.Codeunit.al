codeunit 137812 PageTestChangeViewMode
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UI]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::PageTestChangeViewMode);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::PageTestChangeViewMode);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::PageTestChangeViewMode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderStatistics()
    var
        SalesOrderStatistics: TestPage "Sales Order Statistics";
    begin
        Initialize();
        SalesOrderStatistics.OpenView();

        Assert.IsFalse(SalesOrderStatistics.InvDiscountAmount_General.Editable(), 'Field should not be editable in View');
        Assert.IsFalse(SalesOrderStatistics."TotalAmount1[1]".Editable(), 'Field should not be editable in View');
        Assert.IsFalse(SalesOrderStatistics.InvDiscountAmount_Invoicing.Editable(), 'Field should not be editable in View');
        Assert.IsFalse(SalesOrderStatistics.TotalInclVAT_Invoicing.Editable(), 'Field should not be editable in View');
        // NAVCZ Assert.IsFalse(SalesOrderStatistics.PrepmtTotalAmount.Editable(), 'Field should not be editable in View');

        // switch to edit
        SalesOrderStatistics.Edit().Invoke();
        Assert.IsTrue(SalesOrderStatistics.InvDiscountAmount_General.Editable(), 'Field should be editable in Edit');
        Assert.IsTrue(SalesOrderStatistics."TotalAmount1[1]".Editable(), 'Field should be editable in Edit');
        Assert.IsTrue(SalesOrderStatistics.InvDiscountAmount_Invoicing.Editable(), 'Field should be editable in Edit');
        Assert.IsTrue(SalesOrderStatistics.TotalInclVAT_Invoicing.Editable(), 'Field should be editable in Edit');
        // NAVCZ Assert.IsTrue(SalesOrderStatistics.PrepmtTotalAmount.Editable(), 'Field should be editable in Edit');

        // switch to view
        SalesOrderStatistics.View().Invoke();
        Assert.IsFalse(SalesOrderStatistics.InvDiscountAmount_General.Editable(), 'Field should not be editable in View');
        Assert.IsFalse(SalesOrderStatistics."TotalAmount1[1]".Editable(), 'Field should not be editable in View');
        Assert.IsFalse(SalesOrderStatistics.InvDiscountAmount_Invoicing.Editable(), 'Field should not be editable in View');
        Assert.IsFalse(SalesOrderStatistics.TotalInclVAT_Invoicing.Editable(), 'Field should not be editable in View');
        // NAVCZ Assert.IsFalse(SalesOrderStatistics.PrepmtTotalAmount.Editable(), 'Field should not be editable in View');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyInformation()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize();
        CompanyInformation.OpenView();
        Assert.IsFalse(CompanyInformation."System Indicator Text".Editable(), 'Field should not be editable in View');

        // switch to edit
        CompanyInformation.Edit().Invoke();
        CompanyInformation."Company Badge".Value := 'Custom';
        Assert.IsTrue(CompanyInformation."System Indicator Text".Editable(), 'Field should be editable in Edit');

        // switch to view
        CompanyInformation.View().Invoke();
        Assert.IsFalse(CompanyInformation."System Indicator Text".Editable(), 'Field should not be editable in View');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrder()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();
        SalesOrder.OpenView();
        Assert.IsFalse(SalesOrder.SalesLines.Editable(), 'Field should not be editable in View');

        // switch to edit
        SalesOrder.Edit().Invoke();
        Assert.IsTrue(SalesOrder.SalesLines.Editable(), 'Field should be editable in Edit');

        // switch to view
        SalesOrder.View().Invoke();
        Assert.IsFalse(SalesOrder.SalesLines.Editable(), 'Field should not be editable in View');
    end;
}

