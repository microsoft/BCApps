codeunit 101220 "Create Tax Groups SaaS"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then begin
            if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Standard then
                if not "Tax Group".Get(XLABOR) then begin
                    InsertData(XLABOR, XLaboronJob);
                    InsertLocalData();
                end;
            if not "Tax Group".Get(NONTAXABLETok) then
                InsertData(NONTAXABLETok, XNontaxableTxt);
        end;
    end;

    var
        "Tax Group": Record "Tax Group";
        DemoDataSetup: Record "Demo Data Setup";
        XLABOR: Label 'LABOR';
        XLaboronJob: Label 'Labor on Job';
        NONTAXABLETok: Label 'NonTAXABLE';
        XNontaxableTxt: Label 'Nontaxable';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Tax Group".Init();
        "Tax Group".Validate(Code, Code);
        "Tax Group".Validate(Description, Description);
        "Tax Group".Insert();
    end;

    local procedure InsertLocalData()
    begin
    end;
}

