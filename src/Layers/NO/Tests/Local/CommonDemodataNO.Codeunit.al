codeunit 138550 "Common Demodata (NO)"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Common]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure SettledVATPeriodsForCurrYearAreOpen()
    var
        SettledVATPeriod: Record "Settled VAT Period";
    begin
        // [FEATURE] [Settled VAT Period]
        // [THEN] No open periods in years before the current
        SettledVATPeriod.SetFilter(Year, '<%1', Date2DMY(Today, 3));
        SettledVATPeriod.SetRange(Closed, false);
        Assert.RecordIsEmpty(SettledVATPeriod);
        // [THEN] No closed periods in the current and next years
        SettledVATPeriod.SetFilter(Year, '>=%1', Date2DMY(Today, 3));
        SettledVATPeriod.SetRange(Closed, true);
        Assert.RecordIsEmpty(SettledVATPeriod);
    end;
}

