codeunit 101329 "Create Curr for Reminder Level"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.ForeignCode(), 1, XDKK, 45);
        InsertData(DemoDataSetup.ForeignCode(), 1, XEUR, 4.5);
        InsertData(DemoDataSetup.ForeignCode(), 1, XUSD, 7.5);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDKK: Label 'DKK';
        XEUR: Label 'EUR';
        XUSD: Label 'USD';

    procedure InsertData(ReminderTermsCode: Code[10]; "No.": Integer; CurrencyCode: Code[5]; AdditionalFee: Decimal)
    var
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
    begin
        if CurrencyCode = DemoDataSetup."Currency Code" then
            CurrencyCode := '';
        CurrencyForReminderLevel.Init();
        CurrencyForReminderLevel.Validate("Reminder Terms Code", ReminderTermsCode);
        CurrencyForReminderLevel.Validate("No.", "No.");
        CurrencyForReminderLevel.Validate("Currency Code", CurrencyCode);
        CurrencyForReminderLevel.Validate("Additional Fee", AdditionalFee);
        CurrencyForReminderLevel.Insert();
    end;
}

