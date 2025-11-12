codeunit 113000 "Interface Financials"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        XFinanceManagement: Label 'Finance Management';

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XFinanceManagement);

        Steps := 0;
        MaxSteps := 6; // Number of calls to RunCodeunit
        RunCodeunit(CODEUNIT::"Create IC Partner");
        RunCodeunit(CODEUNIT::"Create IC G/L Account");
        RunCodeunit(CODEUNIT::"Create IC Dimension");
        RunCodeunit(CODEUNIT::"Create IC Dimension Value");
        RunCodeunit(CODEUNIT::"Create PowerBI Data");
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
}

