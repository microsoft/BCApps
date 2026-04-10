codeunit 101903 "Localized Create Demo Data"
{

    trigger OnRun()
    begin
    end;

    procedure CreateDataBeforeActions()
    var
        DemoDataSetup: Record "Demo Data Setup";
        "Interface Russian Accounting": Codeunit "Interface Russian Accounting";
        "Interface Tax Accounting": Codeunit "Interface Tax Accounting";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Russian Accounting" then
            "Interface Russian Accounting".CreateDemoData();
        if DemoDataSetup."Tax Accounting" then
            "Interface Tax Accounting".CreateDemoData();
    end;

    procedure CreateDataAfterActions()
    begin
    end;

    procedure CreateEvaluationData()
    begin
    end;

    procedure CreateExtendedData()
    var
        "Interface Russian Accounting": Codeunit "Interface Russian Accounting";
    begin
        "Interface Russian Accounting"."Finalize Setup"();
    end;
}

