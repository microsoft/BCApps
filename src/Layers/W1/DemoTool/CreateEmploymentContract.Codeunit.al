codeunit 101609 "Create Employment Contract"
{

    trigger OnRun()
    begin
        InsertData(XADM, XAdministrators);
        InsertData(XPROD, XProductionStaff);
        InsertData(XDEV, XDevelopers);
    end;

    var
        Contract: Record "Employment Contract";
        XADM: Label 'ADM';
        XAdministrators: Label 'Administrators';
        XPROD: Label 'PROD';
        XProductionStaff: Label 'Production Staff';
        XDEV: Label 'DEV';
        XDevelopers: Label 'Developers';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        Contract.Code := Code;
        Contract.Description := Description;
        Contract.Insert();
    end;
}

