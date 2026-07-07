/// <summary>
/// Insert demo data for Notification Setup
/// </summary>
codeunit 119041 "Create Notification Setup"
{
    trigger OnRun()
    begin
        InsertData(NotificationType::"New Record", NotificationMethod::Email);
        InsertData(NotificationType::"Approval", NotificationMethod::Email);
        InsertData(NotificationType::"Overdue", NotificationMethod::Email);
    end;

    var
        NotificationType: Enum "Notification Entry Type";
        NotificationMethod: Enum "Notification Method Type";

    procedure InsertData(Type: Enum "Notification Entry Type"; Method: Enum "Notification Method Type")
    var
        NotificationSetup: Record "Notification Setup";
    begin
        NotificationSetup.Init();
        NotificationSetup."Notification Type" := Type;
        NotificationSetup."Notification Method" := Method;
        if NotificationSetup.Insert() then;
    end;
}