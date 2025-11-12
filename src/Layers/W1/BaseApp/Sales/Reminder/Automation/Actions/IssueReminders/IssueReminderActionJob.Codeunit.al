// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Telemetry;

codeunit 6757 "Issue Reminder Action Job"
{
    TableNo = "Reminder Action";
    EventSubscriberInstance = Manual;

    var
        GlobalReminderHeader: Record "Reminder Header";
        GlobalGenJournalBatch: Record "Gen. Journal Batch";
        GlobalIssueReminderSetup: Record "Issue Reminders Setup";
        ReminderAutomationLogError: Codeunit "Reminder Automation Log Errors";


    trigger OnRun()
    var
        ErrorsOccured: Boolean;
    begin
        IssueReminders(Rec, ErrorsOccured);
    end;

    procedure IssueReminders(var ReminderAction: Record "Reminder Action"; var ErrorsOccured: Boolean)
    var
        DummyReminderActionGroup: Record "Reminder Action Group";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IssueReminderEventHandler: Codeunit "Issue Reminder Event Handler";
    begin
        FeatureTelemetry.LogUptake('0000MK4', DummyReminderActionGroup.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000MK5', DummyReminderActionGroup.GetFeatureTelemetryName(), 'Reminder Automation - Running creating reminders');

        IssueReminderEventHandler.SetReminderAction(ReminderAction);
        BindSubscription(IssueReminderEventHandler);

        Initialize(ReminderAction);
        RunIssueReminders(ReminderAction, ErrorsOccured);
        IssueReminderEventHandler.UpdateStatusAfterRun();
    end;

    local procedure RunIssueReminders(var ReminderAction: Record "Reminder Action"; var ErrorOccured: Boolean)
    var
        ExistingReminderActionLog: Record "Reminder Action Log";
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
        ReplaceVATDate: Boolean;
        ReplacePostingDate: Boolean;
        NewPostingDate: Date;
        NewVATDate: Date;
    begin
        if not GlobalReminderHeader.FindSet() then
            exit;

        if ReminderActionProgress.GetLastActionEntry(ReminderAction, ExistingReminderActionLog) then
            if ExistingReminderActionLog.Status = ExistingReminderActionLog.Status::Failed then
                if ExistingReminderActionLog."Last Record Processed".TableNo <> 0 then
                    GlobalReminderHeader.Get(ExistingReminderActionLog."Last Record Processed");

        ReminderActionProgress.CreateNewActionEntry(ReminderAction, ReminderActionLog.Status::Running, ReminderActionLog);

        repeat
            CalculatePostingDate(GlobalIssueReminderSetup, GlobalReminderHeader, ReplacePostingDate, NewPostingDate);
            CalculateVATDate(GlobalIssueReminderSetup, GlobalReminderHeader, ReplaceVATDate, NewVATDate);
            if not RunIssueReminder(GlobalReminderHeader, ReplacePostingDate, NewPostingDate, ReplaceVATDate, NewVATDate) then begin
                ErrorOccured := true;
                if ReminderAction."Stop on Error" then begin
                    ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalReminderHeader.RecordId, "Reminder Log Status"::Failed);
                    Commit();
                    exit;
                end;
            end else begin
                ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalReminderHeader.RecordId, "Reminder Log Status"::Running);
                Commit();
            end;
        until GlobalReminderHeader.Next() = 0;

        ReminderActionProgress.UpdateActionEntry(ReminderAction, GlobalReminderHeader.RecordId, "Reminder Log Status"::Completed);
    end;

    local procedure RunIssueReminder(var ReminderHeader: Record "Reminder Header"; ReplacePostingDate: Boolean; NewPostingDate: Date; ReplaceVATDate: Boolean; NewVATDate: Date): Boolean
    var
        Success: Boolean;
    begin
        Commit();
        OnIssueReminderSafe(ReminderHeader, ReplacePostingDate, NewPostingDate, ReplaceVATDate, NewVATDate, GlobalGenJournalBatch, Success);
        if Success then
            exit(true);

        ReminderAutomationLogError.LogLastError(Enum::"Reminder Automation Error Type"::"Issue Reminder");
        ClearLastError();
        exit(false);
    end;

    local procedure Initialize(var ReminderAction: Record "Reminder Action")
    var
        ReminderActionGroup: Record "Reminder Action Group";
    begin
        GlobalIssueReminderSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code");
        if GlobalIssueReminderSetup.GetReminderSelectionDisplayText() <> '' then
            GlobalReminderHeader.SetView(GlobalIssueReminderSetup.GetReminderSelectionFilterView());

        ReminderActionGroup.Get(ReminderAction."Reminder Action Group Code");
        GlobalReminderHeader.SetFilter("Reminder Terms Code", ReminderActionGroup.GetReminderTermsSelectionFilter());

        ReminderAutomationLogError.Initialize(ReminderAction);
    end;

    local procedure CalculatePostingDate(var IssueReminderSetup: Record "Issue Reminders Setup"; var ReminderHeader: Record "Reminder Header"; var ReplacePostingDate: Boolean; var PostingDate: Date)
    var
        BlankFormula: DateFormula;
    begin
        if IssueReminderSetup."Replace Posting Date" = IssueReminderSetup."Replace Posting Date" then begin
            ReplacePostingDate := false;
            Clear(PostingDate);
            exit;
        end;

        ReplacePostingDate := true;
        if IssueReminderSetup."Replace Posting Date" = IssueReminderSetup."Replace Posting Date"::"Use Workdate" then
            PostingDate := WorkDate();

        if IssueReminderSetup."Replace Posting Date" = IssueReminderSetup."Replace Posting Date"::"Use date from reminder" then
            PostingDate := ReminderHeader."Posting Date";

        if IssueReminderSetup."Replace Posting Date formula" <> BlankFormula then
            PostingDate := CalcDate(IssueReminderSetup."Replace Posting Date formula", PostingDate);
    end;

    local procedure CalculateVATDate(var IssueReminderSetup: Record "Issue Reminders Setup"; var ReminderHeader: Record "Reminder Header"; var ReplaceVATDate: Boolean; var VATDate: Date)
    var
        BlankFormula: DateFormula;
    begin
        if IssueReminderSetup."Replace VAT Date" = IssueReminderSetup."Replace VAT Date" then begin
            ReplaceVATDate := false;
            Clear(VATDate);
            exit;
        end;

        ReplaceVATDate := true;
        if IssueReminderSetup."Replace VAT Date" = IssueReminderSetup."Replace VAT Date"::"Use Workdate" then
            VATDate := WorkDate();

        if IssueReminderSetup."Replace VAT Date" = IssueReminderSetup."Replace VAT Date"::"Use date from reminder" then
            VATDate := ReminderHeader."VAT Reporting Date";

        if IssueReminderSetup."Replace VAT Date formula" <> BlankFormula then
            VATDate := CalcDate(IssueReminderSetup."Replace VAT Date formula", VATDate);
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnIssueReminderSafe(var ReminderHeader: Record "Reminder Header"; ReplacePostingDate: Boolean; NewPostingDate: Date; ReplaceVATDate: Boolean; NewVATDate: Date; var GenJournalBatch: Record "Gen. Journal Batch"; var Success: Boolean)
    begin
    end;
}