codeunit 163415 "Create Assessed Tax Allowance"
{

    trigger OnRun()
    begin
        InsertData('2010221', XATAllowance1);
        InsertData('2010224', XATAllowance2);
        InsertData('2010231', XATAllowance3);
    end;

    var
        ATAllowance: Record "Assessed Tax Allowance";
        XATAllowance1: Label 'Ministry of Justice Departments';
        XATAllowance2: Label 'Invalid''s Public Organizations';
        XATAllowance3: Label 'Objects with Military Purpose';

    procedure InsertData("Code": Code[20]; Name: Text[50])
    begin
        ATAllowance.Init();
        ATAllowance.Code := Code;
        ATAllowance.Name := Name;
        ATAllowance.Insert();
    end;
}

