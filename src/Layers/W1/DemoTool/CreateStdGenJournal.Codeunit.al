codeunit 101760 "Create Std. Gen. Journal"
{

    trigger OnRun()
    begin
        InsertData(XGENERAL, XPAYROLL, XPayrollJournal);
    end;

    var
        StdGenJournal: Record "Standard General Journal";
        XPAYROLL: Label 'PAYROLL';
        XPayrollJournal: Label 'Payroll Journal';
        XGENERAL: Label 'GENERAL';

    procedure InsertData(JnlTemplateName: Code[10]; "Code": Code[10]; Description: Text[50])
    begin
        StdGenJournal.Init();
        StdGenJournal.Validate("Journal Template Name", JnlTemplateName);
        StdGenJournal.Validate(Code, Code);
        StdGenJournal.Validate(Description, Description);
        StdGenJournal.Insert();
    end;
}

