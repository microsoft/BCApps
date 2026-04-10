codeunit 132471 "Reminder Automation Mock"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertEvent(var Rec: Record "Reminder Header"; RunTrigger: Boolean)
    begin
        if not ThrowErrorsOnReminderInsert then
            exit;

        if Rec."Customer No." <> BlockedCustomer then
            exit;

        Error(CannotInsertReminderForCustomerErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reminder Action Log", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterUpdateLog(var Rec: Record "Reminder Action Log"; var xRec: Record "Reminder Action Log"; RunTrigger: Boolean)
    begin
        if not BlockedCreateAutomation then
            exit;

        if Rec."Last Record Processed" <> LastAllowedRecordID then
            exit;

        Commit();
        Error(CreationFailedErr);
    end;

    procedure SetThrowErrorsOnReminderInsert(NewThrowErrorsOnReminderInsert: Boolean)
    begin
        ThrowErrorsOnReminderInsert := NewThrowErrorsOnReminderInsert;
    end;

    procedure SetBlockedCustomer(NewBlockedCustomer: Code[20])
    begin
        BlockedCustomer := NewBlockedCustomer;
    end;

    procedure SetErrorForLastRecordUpdated(NewLastAllowedRecordID: RecordId)
    begin
        LastAllowedRecordID := NewLastAllowedRecordID;
    end;


    procedure SetBlockCreateAutomation(NewBlockedCreateAutomation: Boolean)
    begin
        BlockedCreateAutomation := NewBlockedCreateAutomation;
    end;

    var
        LastAllowedRecordID: RecordId;
        ThrowErrorsOnReminderInsert: Boolean;
        BlockedCreateAutomation: Boolean;
        BlockedCustomer: Code[20];
        CannotInsertReminderForCustomerErr: Label 'Test Mock - Cannot insert reminder for customer';
        CreationFailedErr: Label 'Test Mock - block automation job';
}