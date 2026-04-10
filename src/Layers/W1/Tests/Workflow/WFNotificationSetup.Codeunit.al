codeunit 134311 "WF Notification Setup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Notification]
    end;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryUtility: Codeunit "Library - Utility";
        TestUserID: Code[50];
        NotificationType: Enum "Notification Method Type";

    [Test]
    [Scope('OnPrem')]
    procedure NotificationSetupOnDelete()
    var
        NotificationSetup: Record "Notification Setup";
        NotificationSchedule: Record "Notification Schedule";
        NotificationType: Option;
    begin
        // [SCENARIO] When Notification Setup with Notification Schedule
        // is deleted then Notification Schedule is deleted
        Initialize();

        // [GIVEN] Notification Setup with Notification Schedule
        CreateNotificationSetup(NotificationSetup);

        // [WHEN] Notification Setup is deleted
        NotificationSetup.Delete(true);

        // [THEN] Notification Schedule is deleted as well
        Assert.IsFalse(NotificationSchedule.Get(TestUserID, NotificationType),
          'Notification Schedule is not deleted');
    end;

    local procedure Initialize()
    begin
        TestUserID := LibraryUtility.GenerateGUID();
    end;

    local procedure CreateNotificationSetup(var NotificationSetup: Record "Notification Setup")
    var
        NotificationSchedule: Record "Notification Schedule";
    begin
        NotificationSchedule.CreateNewRecord(TestUserID, NotificationType);

        LibraryWorkflow.CreateNotificationSetup(
            NotificationSetup, TestUserID, NotificationType, NotificationSetup."Notification Method"::Email);
    end;
}

