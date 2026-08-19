codeunit 101292 "Create Reminder Terms"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.DomesticCode(), XDomesticCustomers);
        InsertData(DemoDataSetup.ForeignCode(), XForeignCustomers);
    end;

    var
        XDomesticCustomers: Label 'Domestic Customers';
        XForeignCustomers: Label 'Foreign Customers';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Code": Code[10]; Description: Text[30])
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.Init();
        ReminderTerms.Validate(Code, Code);
        ReminderTerms.Validate(Description, Description);
        ReminderTerms.Insert();
    end;
}

