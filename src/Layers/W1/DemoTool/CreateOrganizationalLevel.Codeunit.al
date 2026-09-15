codeunit 101570 "Create Organizational Level"
{

    trigger OnRun()
    begin
        InsertData(XCEO, XChiefExecutiveOfficer);
        InsertData(XCFO, XChiefFinancialOfficer);
        InsertData(XJMANA, XJuniorManager);
        InsertData(XMANA, XManager);
        InsertData(XSALEMP, XSalariedEmployee);
        InsertData(XSENMAN, XSeniorManager);
    end;

    var
        "Organizational Level": Record "Organizational Level";
        XCEO: Label 'CEO';
        XChiefExecutiveOfficer: Label 'Chief Executive Officer';
        XCFO: Label 'CFO';
        XChiefFinancialOfficer: Label 'Chief Financial Officer';
        XJMANA: Label 'J-MANA';
        XJuniorManager: Label 'Junior Manager';
        XMANA: Label 'MANA';
        XManager: Label 'Manager';
        XSALEMP: Label 'SALEMP';
        XSalariedEmployee: Label 'Salaried Employee';
        XSENMAN: Label 'SENMAN';
        XSeniorManager: Label 'Senior Manager';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Organizational Level".Init();
        "Organizational Level".Validate(Code, Code);
        "Organizational Level".Validate(Description, Description);
        "Organizational Level".Insert();
    end;
}

