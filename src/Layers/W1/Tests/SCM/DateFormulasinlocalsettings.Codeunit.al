codeunit 137024 "DateFormulas in local settings"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Lead Time] [SCM] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure VSTF306969()
    begin
        VSTF306969Scenario('', '', '<0D>');

        VSTF306969Scenario('<1D>', '', '<1D>');

        VSTF306969Scenario('', '<1D>', '<1D>');

        VSTF306969Scenario('<2D>', '<1D>', '<3D>');

        VSTF306969Scenario('<-1D>', '<2D>', '<1D>');

        VSTF306969Scenario('<-1D>', '', '<-1D>');

        VSTF306969Scenario('', '<-1D>', '<-1D>');
    end;

    local procedure VSTF306969Scenario(SafetyLeadTimeDF: Text[30]; InbndWhseHandlingTime: Text[30]; ExpectedResult: Text[30])
    var
        PurchaseLine: Record "Purchase Line";
        ExpectedDF: DateFormula;
    begin
        PurchaseLine.Init();
        Evaluate(PurchaseLine."Safety Lead Time", SafetyLeadTimeDF);
        Evaluate(PurchaseLine."Inbound Whse. Handling Time", InbndWhseHandlingTime);
        Evaluate(ExpectedDF, ExpectedResult);
        Assert.AreEqual(Format(ExpectedDF), Format(PurchaseLine.InternalLeadTimeDays(WorkDate())), '');
    end;
}

