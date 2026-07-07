codeunit 163408 "Interface Tax Accounting"
{

    trigger OnRun()
    begin
        CreateDemoData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
        CreateTaxDiffSetup: Codeunit "Create Tax Diff. Setup";
        CreateTaxRegisters: Report "Create Tax Registers";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        XTaxAccounting: Label 'Tax Accounting';

    procedure CreateDemoData()
    begin
        DemoDataSetup.Get();

        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XTaxAccounting);

        Steps := 0;
        MaxSteps := 6; // Number of calls to RunCodeunit

        // Tax Accounting
        RunCodeunit(CODEUNIT::"Create FA Charge");
        RunCodeunit(CODEUNIT::"Create Tax Depreciation Book");
        RunCodeunit(CODEUNIT::"Create Tax Norms");
        RunCodeunit(CODEUNIT::"Create Tax Register");

        // Tax Deferrals
        RunCodeunit(CODEUNIT::"Create Tax Diff. Setup");

        Window.Close();
    end;

    procedure "Before Posting"()
    begin
    end;

    procedure Post(PostingDate: Date)
    begin
    end;

    procedure "After Posting"()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XTaxAccounting);

        Steps := 0;
        MaxSteps := 1; // Number of calls to RunCodeunit
        if not DemoDataSetup."Skip sequence of actions" then
            RunCodeunit(CODEUNIT::"Create Tax Diff. Data");

        BuildTaxRegisters(MakeAdjustments.AdjustDate(19020101D));
        BuildTaxRegisters(MakeAdjustments.AdjustDate(19020401D));
        BuildTaxRegisters(MakeAdjustments.AdjustDate(19020701D));
        BuildTaxRegisters(MakeAdjustments.AdjustDate(19021001D));

        CreateTaxDiffSetup.PostFAJournals();
        Window.Close();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;

    procedure BuildTaxRegisters(StartDate: Date)
    var
        TaxRegSection: Record "Tax Register Section";
    begin
        exit;

        TaxRegSection.FindFirst();
        TaxRegSection.SetRange(Code, TaxRegSection.Code);
        CreateTaxRegisters.UseRequestPage(false);
        CreateTaxRegisters.SetTableView(TaxRegSection);
        CreateTaxRegisters.Run();
        Clear(CreateTaxRegisters);
        Commit();
    end;
}

