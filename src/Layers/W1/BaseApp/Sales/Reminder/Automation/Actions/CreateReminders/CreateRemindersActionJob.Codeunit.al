// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;
using System.Telemetry;

codeunit 6759 "Create Reminders Action Job"
{
    TableNo = "Reminder Action";
    EventSubscriberInstance = Manual;

    var
        GlobalCreateRemindersSetup: Record "Create Reminders Setup";
        GlobalCustLedgEntry: Record "Cust. Ledger Entry";
        GlobalFeeCustLedgEntry: Record "Cust. Ledger Entry";
        GlobalCustomer: Record Customer;
        GlobalReminderHeader: Record "Reminder Header";
        ReminderAutomationLogErrors: Codeunit "Reminder Automation Log Errors";

    trigger OnRun()
    var
        ErrorOccured: Boolean;
    begin
        CreateReminders(Rec, ErrorOccured);
    end;

    internal procedure CreateReminders(var ReminderAction: Record "Reminder Action"; var ErrorOccured: Boolean)
    var
        DummyReminderActionGroup: Record "Reminder Action Group";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CreateAutEventHandler: Codeunit "Create Aut. Event Handler";
    begin
        FeatureTelemetry.LogUptake('0000MK8', DummyReminderActionGroup.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000MK9', DummyReminderActionGroup.GetFeatureTelemetryName(), 'Reminder Automation - Running creating reminders');
        CreateAutEventHandler.SetReminderAction(ReminderAction);
        BindSubscription(CreateAutEventHandler);

        if ReminderAction.Type <> ReminderAction.Type::"Create Reminder" then
            exit;

        Initialize(ReminderAction);
        RunCreateReminders(ReminderAction, ErrorOccured);
        CreateAutEventHandler.UpdateStatusAfterRun();
    end;

    local procedure RunCreateReminders(var ReminderAction: Record "Reminder Action"; var ErrorOccured: Boolean)
    var
        ExistingReminderActionLog: Record "Reminder Action Log";
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        if not GlobalCustomer.FindSet() then
            exit;

        if ReminderActionProgress.GetLastActionEntry(ReminderAction, ExistingReminderActionLog) then
            if ExistingReminderActionLog.Status = ExistingReminderActionLog.Status::Failed then
                if ExistingReminderActionLog."Last Record Processed".TableNo <> 0 then
                    GlobalCustomer.Get(ExistingReminderActionLog."Last Record Processed");

        ReminderActionProgress.CreateNewActionEntry(ReminderAction, ReminderActionLog.Status::Running, ReminderActionLog);

        repeat
            if not CreateReminderForCustomer(GlobalCustomer) then begin
                ErrorOccured := true;
                if ReminderAction."Stop on Error" then begin
                    ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalCustomer.RecordId, "Reminder Log Status"::Failed);
                    Commit();
                    exit;
                end;
            end else begin
                ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalCustomer.RecordId, "Reminder Log Status"::Running);
                Commit();
            end;
        until GlobalCustomer.Next() = 0;

        ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalCustomer.RecordId, "Reminder Log Status"::Completed);
    end;

    local procedure CreateReminderForCustomer(var Customer: Record Customer): Boolean
    var
        Success: Boolean;
    begin
        Commit();
        OnCreateReminderSafe(Customer, GlobalCustLedgEntry, GlobalReminderHeader, GlobalCreateRemindersSetup."Only Overdue Amount Entries", GlobalCreateRemindersSetup."Include Entries On Hold", GlobalFeeCustLedgEntry, Success);
        if Success then
            exit(true);

        ReminderAutomationLogErrors.LogLastError(Enum::"Reminder Automation Error Type"::"Create Reminder");
        ClearLastError();
        exit(false);
    end;

    local procedure Initialize(var ReminderAction: Record "Reminder Action")
    begin
        InitializeGlobalReminderVariables(ReminderAction);
        ReminderAutomationLogErrors.Initialize(ReminderAction);
    end;

    local procedure InitializeGlobalReminderVariables(var ReminderAction: Record "Reminder Action")
    var
        ReminderActionGroup: Record "Reminder Action Group";
    begin
        ReminderActionGroup.Get(ReminderAction."Reminder Action Group Code");
        GlobalCreateRemindersSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code");
        if GlobalCreateRemindersSetup.GetCustomerSelectionFilter() <> '' then
            GlobalCustomer.SetView(GlobalCreateRemindersSetup.GetCustomerSelectionViewFilter());

        GlobalCustomer.SetFilter("Reminder Terms Code", ReminderActionGroup.GetReminderTermsSelectionFilter());

        if GlobalCreateRemindersSetup.GetCustomerLedgerEntriesSelectionFilter() <> '' then
            GlobalCustLedgEntry.SetView(GlobalCreateRemindersSetup.GetCustomerLedgerEntriesSelectionViewFilter());

        if GlobalCreateRemindersSetup.GetFeeCustomerLegerEntriesSelectionFilter() <> '' then
            GlobalFeeCustLedgEntry.SetView(GlobalCreateRemindersSetup.GetFeeCustomerLedgerEntriesSelectionViewFilter());

        if GlobalReminderHeader."Document Date" = 0D then begin
            GlobalReminderHeader."Document Date" := WorkDate();
            GlobalReminderHeader."Posting Date" := WorkDate();
        end;

        GlobalReminderHeader."Use Header Level" := GlobalCreateRemindersSetup."Set Header Level to all Lines";
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnCreateReminderSafe(var Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderHeader: Record "Reminder Header"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var FeeCustLedgEntryLine: Record "Cust. Ledger Entry"; var Success: Boolean)
    begin
    end;
}