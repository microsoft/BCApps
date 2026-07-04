codeunit 115000 "Interface Reserved for fut. 1"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;
        XName: Label 'Name';

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, XName);

        Steps := 0;
        MaxSteps := 2; // Number of calls to RunCodeunit

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

