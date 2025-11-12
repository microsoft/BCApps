codeunit 120000 "Interface ADCS"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        XADCS: Label 'ADCS';

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XADCS);
        Steps := 0;
        MaxSteps := 1; // Number of calls to RunCodeunit

        RunCodeunit(CODEUNIT::"Create Item Identifier");
        RunCodeunit(CODEUNIT::"Modify Location for ADCS");
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

