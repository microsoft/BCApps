// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Telemetry;

codeunit 6754 "Send Reminder Action Job"
{
    TableNo = "Reminder Action";

    var
        GlobalIssuedReminderHeader: Record "Issued Reminder Header";
        GlobalSendReminderSetup: Record "Send Reminders Setup";
        ReminderAutomationLogError: Codeunit "Reminder Automation Log Errors";


    trigger OnRun()
    var
        ErrorsOccured: Boolean;
    begin
        SendReminders(Rec, ErrorsOccured);
    end;

    procedure SendReminders(var ReminderAction: Record "Reminder Action"; var ErrorsOccured: Boolean)
    var
        DummyReminderActionGroup: Record "Reminder Action Group";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SendReminderEventHandler: Codeunit "Send Reminder Event Handler";
    begin
        FeatureTelemetry.LogUptake('0000MKC', DummyReminderActionGroup.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000MKD', DummyReminderActionGroup.GetFeatureTelemetryName(), 'Reminder Automation - Running creating reminders');

        SendReminderEventHandler.SetGlobalReminderAction(ReminderAction);
        BindSubscription(SendReminderEventHandler);

        Initialize(ReminderAction);
        RunSendReminders(ReminderAction, ErrorsOccured);

        SendReminderEventHandler.UpdateStatusAfterRun();
    end;

    local procedure RunSendReminders(var ReminderAction: Record "Reminder Action"; var ErrorOccured: Boolean)
    var
        ExistingReminderActionLog: Record "Reminder Action Log";
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
        ShouldSendReminder: Boolean;
    begin
        if not GlobalIssuedReminderHeader.FindSet() then
            exit;

        if ReminderActionProgress.GetLastActionEntry(ReminderAction, ExistingReminderActionLog) then
            if ExistingReminderActionLog.Status = ExistingReminderActionLog.Status::Failed then
                if ExistingReminderActionLog."Last Record Processed".TableNo <> 0 then
                    GlobalIssuedReminderHeader.Get(ExistingReminderActionLog."Last Record Processed");

        ReminderActionProgress.CreateNewActionEntry(ReminderAction, ReminderActionLog.Status::Running, ReminderActionLog);

        repeat
            ShouldSendReminder := GetShouldSendReminder(GlobalIssuedReminderHeader);
            if ShouldSendReminder then
                if not RunSendReminder(GlobalIssuedReminderHeader) then begin
                    ErrorOccured := true;
                    if ReminderAction."Stop on Error" then begin
                        ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalIssuedReminderHeader.RecordId, "Reminder Log Status"::Failed);
                        Commit();
                        exit;
                    end;
                end else begin
                    ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalIssuedReminderHeader.RecordId, "Reminder Log Status"::Running);
                    Commit();
                end;
        until GlobalIssuedReminderHeader.Next() = 0;

        ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalIssuedReminderHeader.RecordId, "Reminder Log Status"::Completed);
    end;

    local procedure GetShouldSendReminder(var IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        CurrentDateTime: DateTime;
    begin
        if (IssuedReminderHeader."Email Sent Level" <> IssuedReminderHeader."Reminder Level") then
            exit(true);

        if not GlobalSendReminderSetup."Send Multiple Times Per Level" then
            exit(false);

        if IssuedReminderHeader."Last Email Sent Date Time" = 0DT then
            exit(true);

        CurrentDateTime := CurrentDateTime();
        if CurrentDateTime <= IssuedReminderHeader."Last Email Sent Date Time" then
            exit(false);

        exit(CurrentDateTime - IssuedReminderHeader."Last Email Sent Date Time" > GlobalSendReminderSetup."Minimum Time Between Sending");
    end;

    local procedure RunSendReminder(var IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    var
        Success: Boolean;
    begin
        Commit();
        OnSendReminderSafe(IssuedReminderHeader, GlobalSendReminderSetup, Success);
        if Success then
            exit(true);

        ReminderAutomationLogError.LogLastError(Enum::"Reminder Automation Error Type"::"Send Reminder");
        ClearLastError();
        exit(false);
    end;

    local procedure Initialize(var ReminderAction: Record "Reminder Action")
    var
        ReminderActionGroup: Record "Reminder Action Group";
    begin
        GlobalSendReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code");
        if GlobalSendReminderSetup.GetReminderSelectionDisplayText() <> '' then
            GlobalIssuedReminderHeader.SetView(GlobalSendReminderSetup.GetReminderSelectionFilterView());

        ReminderActionGroup.Get(ReminderAction."Reminder Action Group Code");
        GlobalIssuedReminderHeader.SetFilter("Reminder Terms Code", ReminderActionGroup.GetReminderTermsSelectionFilter());

        ReminderAutomationLogError.Initialize(ReminderAction);
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnSendReminderSafe(var IssuedReminderHeader: Record "Issued Reminder Header"; var SendReminderSetup: Record "Send Reminders Setup"; var Success: Boolean)
    begin
    end;
}