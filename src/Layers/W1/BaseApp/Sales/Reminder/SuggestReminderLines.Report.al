// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Receivables;
using System.Utilities;

report 189 "Suggest Reminder Lines"
{
    Caption = 'Suggest Reminder Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Reminder Header"; "Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
                Result: Boolean;
            begin
                RecordNo := RecordNo + 1;
                Clear(ReminderMake);
                ReminderMake.SuggestLines("Reminder Header", CustLedgerEntry, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn);
                if NoOfRecords = 1 then begin
                    Result := false;
                    IsHandled := false;
                    OnAfterGetRecordReminderHeaderOnBeforeMakeReminder(
                        "Reminder Header", CustLedgerEntry, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn, Result, IsHandled);
                    if not IsHandled then
                        ReminderMake.Code();
                    Mark := false;
                end else begin
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
                        if NewProgress <> OldProgress then begin
                            Window.Update(1, NewProgress * 100);
                            OldProgress := NewProgress;
                        end;
                        OldDateTime := CurrentDateTime;
                    end;
                    Result := false;
                    IsHandled := false;
                    OnAfterGetRecordReminderHeaderOnBeforeMarkReminder(
                        "Reminder Header", CustLedgerEntry, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn, Result, IsHandled);
                    if not IsHandled then
                        Mark := not ReminderMake.Code();
                end;
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                Commit();
                Window.Close();
                MarkedOnly := true;
                if FindFirst() then
                    if ConfirmManagement.GetResponse(Text002, true) then
                        PAGE.RunModal(0, "Reminder Header");
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(Text000)
                else begin
                    Window.Open(Text001);
                    OldDateTime := CurrentDateTime;
                end;
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
                    field(OverdueEntriesOnly; OverdueEntriesOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Entries with Overdue Amounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if the batch job will only insert open entries that are overdue, meaning they have a due date earlier than the document date on the reminder header.';
                    }
                    field(IncludeEntriesOnHold; IncludeEntriesOnHold)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Entries On Hold';
                        ToolTip = 'Specifies if the batch job will also insert overdue open entries that are on hold.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CustLedgerEntry.Copy(CustLedgEntry2)
    end;

    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;

#pragma warning disable AA0074
        Text000: Label 'Suggesting lines...';
        Text001: Label 'Suggesting lines @1@@@@@@@@@@@@@';
        Text002: Label 'It was not possible to process some of the selected reminders.\Do you want to see these reminders?';
#pragma warning restore AA0074

    protected var
        OverdueEntriesOnly: Boolean;
        IncludeEntriesOnHold: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordReminderHeaderOnBeforeMakeReminder(var ReminderHeader: Record "Reminder Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var CustLedgerEntryLineFeeOn: Record "Cust. Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordReminderHeaderOnBeforeMarkReminder(var ReminderHeader: Record "Reminder Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var CustLedgerEntryLineFeeOn: Record "Cust. Ledger Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

