// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Utilities;

report 188 "Create Reminders"
{
    Caption = 'Create Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
                Result: Boolean;
            begin
                RecordNo := RecordNo + 1;
                Clear(MakeReminder);
                MakeReminder.Set(Customer, CustLedgEntry, ReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn);
                if NoOfRecords = 1 then begin
                    Result := false;
                    IsHandled := false;
                    OnAfterGetRecordCustomerOnBeforeMakeReminder(
                        Customer, CustLedgEntry, ReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn, Result, IsHandled, MakeReminder);
                    if not IsHandled then
                        MakeReminder.Code();
                    Mark := false;
                end else begin
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        UpdateProgressWindow();
                        OldDateTime := CurrentDateTime;
                    end;
                    Result := false;
                    IsHandled := false;
                    OnAfterGetRecordCustomerOnBeforeMakeReminder(
                        Customer, CustLedgEntry, ReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn, Result, IsHandled, MakeReminder);
                    if IsHandled then
                        Mark(Result)
                    else
                        Mark := not MakeReminder.Code();
                end;
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                Window.Close();
                MarkedOnly := true;
                Commit();
                if FindFirst() then begin
                    FinishDateTime := CurrentDateTime();
                    if ConfirmManagement.GetResponse(Text003, true) then
                        PAGE.RunModal(0, Customer);
                end;
            end;

            trigger OnPreDataItem()
            var
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if ReminderHeaderReq."Document Date" = 0D then
                    Error(Text000, ReminderHeaderReq.FieldCaption("Document Date"));
                FilterGroup := 2;
                SetFilter("Reminder Terms Code", '<>%1', '');
                FilterGroup := 0;
                OnCustomerOnPreDataItemOnBeforeCount(Customer);
                NoOfRecords := Count;
                SalesSetup.Get();
                SalesSetup.TestField("Reminder Nos.");
                OpenProgressWindow();
                ReminderHeaderReq."Use Header Level" := UseHeaderLevel;
            end;
        }
        dataitem(CustLedgEntry2; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Customer No.");
            RequestFilterFields = "Document Type";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(CustLedgEntryLineFeeOn; "Cust. Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.") order(ascending);
            RequestFilterFields = "Document Type";
            RequestFilterHeading = 'Apply Fee per Line On';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#pragma warning disable AA0100
                    field("ReminderHeaderReq.""Posting Date"""; ReminderHeaderReq."Posting Date")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that will appear as the posting date on the header of the reminder that is created by the batch job.';
                    }
                    field(DocumentDate; ReminderHeaderReq."Document Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the date that will appear as the document date on the header of the reminder that is created by the batch job. This date is used for any interest calculations and to determine the due date of the reminder.';
                    }
                    field(OverdueEntriesOnly; OverdueEntriesOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Entries with Overdue Amounts';
                        MultiLine = true;
                        ToolTip = 'Specifies that the batch job will only insert open entries that are overdue for payments and invoices. Overdue open entries have a due date that is before the document date on the reminder.';
                    }
                    field(IncludeEntriesOnHold; IncludeEntriesOnHold)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Entries On Hold';
                        ToolTip = 'Specifies if you want to create reminders for entries that are on hold.';
                    }
                    field(UseHeaderLevel; UseHeaderLevel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Header Level';
                        ToolTip = 'Specifies if the batch job will apply the condition of the reminder level to all the reminder lines.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if ReminderHeaderReq."Document Date" = 0D then begin
                ReminderHeaderReq."Document Date" := WorkDate();
                ReminderHeaderReq."Posting Date" := WorkDate();
            end;
            if InitialCustomer."No." <> '' then
                Customer.SetRange("No.", InitialCustomer."No.");
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OverdueEntriesOnly := true;
    end;

    trigger OnPostReport()
    var
        ReminderLine: Record "Reminder Line";
    begin
        OnBeforeOnPostReport();
        if FinishDateTime = 0DT then
            FinishDateTime := CurrentDateTime();
        NumberOfReminderLines := ReminderLine.Count() - NumberOfReminderLines;
        LogReportTelemetry(StartDateTime, FinishDateTime, NumberOfReminderLines);
        if OpenReminderListAfter then
            Page.Run(Page::"Reminder List");
    end;

    trigger OnPreReport()
    var
        ReminderLine: Record "Reminder Line";
    begin
        StartDateTime := CurrentDateTime();
        OnBeforeOnPreReport();

        CustLedgEntry.Copy(CustLedgEntry2);
        if CustLedgEntryLineFeeOnFilters.GetFilters <> '' then
            CustLedgEntryLineFeeOn.CopyFilters(CustLedgEntryLineFeeOnFilters);

        NumberOfReminderLines := ReminderLine.Count();
        OnAfterOnPreReport(CustLedgEntry);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOnFilters: Record "Cust. Ledger Entry";
        InitialCustomer: Record Customer;
        MakeReminder: Codeunit "Reminder-Make";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;
        OpenReminderListAfter: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text001: Label 'Making reminders...';
        Text002: Label 'Making reminders @1@@@@@@@@@@@@@';
        Text003: Label 'It was not possible to create reminders for some of the selected customers.\Do you want to see these customers?';
#pragma warning restore AA0074
        TelemetryCategoryTxt: Label 'Report', Locked = true;
        CreateRemindersReportGeneratedTxt: Label 'Create Reminders report generated.', Locked = true;

    protected var
        ReminderHeaderReq: Record "Reminder Header";
        NumberOfReminderLines: Integer;
        StartDateTime: DateTime;
        FinishDateTime: DateTime;
        OverdueEntriesOnly: Boolean;
        UseHeaderLevel: Boolean;
        IncludeEntriesOnHold: Boolean;

    procedure InitializeRequest(DocumentDate: Date; PostingDate: Date; OverdueEntries: Boolean; NewUseHeaderLevel: Boolean; IncludeEntries: Boolean)
    begin
        ReminderHeaderReq."Document Date" := DocumentDate;
        ReminderHeaderReq."Posting Date" := PostingDate;
        OverdueEntriesOnly := OverdueEntries;
        UseHeaderLevel := NewUseHeaderLevel;
        IncludeEntriesOnHold := IncludeEntries;
    end;

    procedure SetApplyLineFeeOnFilters(var CustLedgEntryLineFeeOn2: Record "Cust. Ledger Entry")
    begin
        CustLedgEntryLineFeeOnFilters.CopyFilters(CustLedgEntryLineFeeOn2);
    end;

    internal procedure SetCustomer(CustomerNo: Code[20])
    begin
        InitialCustomer.Get(CustomerNo);
    end;

    internal procedure SetOpenReminderListAfter(NewOpenReminderListAfter: Boolean)
    begin
        OpenReminderListAfter := NewOpenReminderListAfter;
    end;

    local procedure LogReportTelemetry(StartDateTime: DateTime; FinishDateTime: DateTime; NumberOfLines: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
        ReportDuration: BigInteger;
    begin
        ReportDuration := FinishDateTime - StartDateTime;
        Dimensions.Add('Category', TelemetryCategoryTxt);
        Dimensions.Add('ReportStartTime', Format(StartDateTime, 0, 9));
        Dimensions.Add('ReportFinishTime', Format(FinishDateTime, 0, 9));
        Dimensions.Add('ReportDuration', Format(ReportDuration));
        Dimensions.Add('NumberOfLines', Format(NumberOfLines));
        Session.LogMessage('0000FJP', CreateRemindersReportGeneratedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure OpenProgressWindow()
    var
        ProgressBarText: Text;
    begin
        if NoOfRecords = 1 then
            ProgressBarText := Text001
        else begin
            ProgressBarText := Text002;
            OldDateTime := CurrentDateTime();
        end;
        OnOpenProgressWindowOnBeforeWindowOpen(NoOfRecords, ProgressBarText);
        Window.Open(ProgressBarText);
    end;

    local procedure UpdateProgressWindow()
    begin
        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
        if NewProgress <> OldProgress then begin
            Window.Update(1, NewProgress * 100);
            OldProgress := NewProgress;
        end;
        OnAfterUpdateProgressWindow(Customer, Window);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreReport(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProgressWindow(Customer: Record Customer; var Window: Dialog)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordCustomerOnBeforeMakeReminder(Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; ReminderHeaderReq: Record "Reminder Header"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry"; var Result: Boolean; var IsHandled: Boolean; var ReminderMake: Codeunit "Reminder-Make")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustomerOnPreDataItemOnBeforeCount(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenProgressWindowOnBeforeWindowOpen(NoOfRecords: Integer; var ProgressBarText: Text)
    begin
    end;
}

