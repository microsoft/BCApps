codeunit 161413 "Create Delivery Reminders"
{

    trigger OnRun()
    begin
        CreateDeliveryReminderTerm(XDEFAULT, XCRONUSDEF, 2);

        CreateDeliveryReminderLevel(XDEFAULT, 1, '<1D>');
        CreateDeliveryReminderLevel(XDEFAULT, 2, '<7D>');

        ChangePurchaseAndPayablesSetup();
    end;

    var
        XDEFAULT: Label 'DEFAULT';
        XCRONUSDEF: Label 'Cronus Default Delivery Remind';

    procedure CreateDeliveryReminderTerm(DCode: Code[10]; DDescription: Text[30]; DMaxNo: Integer)
    var
        DeliveryReminderTerm: Record "Delivery Reminder Term";
    begin
        DeliveryReminderTerm.Init();
        DeliveryReminderTerm.Code := DCode;
        DeliveryReminderTerm.Description := DDescription;
        DeliveryReminderTerm."Max. No. of Delivery Reminders" := DMaxNo;
        if not DeliveryReminderTerm.Insert() then;
    end;

    procedure CreateDeliveryReminderLevel(DCode: Code[10]; DNo: Integer; DDue: Text[30])
    var
        DeliveryReminderLevel: Record "Delivery Reminder Level";
    begin
        DeliveryReminderLevel.Init();
        DeliveryReminderLevel."Reminder Terms Code" := DCode;
        DeliveryReminderLevel."No." := DNo;
        Evaluate(DeliveryReminderLevel."Due Date Calculation", DDue);
        if not DeliveryReminderLevel.Insert() then;
    end;

    procedure ChangePurchaseAndPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Default Del. Rem. Date Field" := PurchasesPayablesSetup."Default Del. Rem. Date Field"::"Promised Receipt Date";
        PurchasesPayablesSetup.Modify();
    end;
}

