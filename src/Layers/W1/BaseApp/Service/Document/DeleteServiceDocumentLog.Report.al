// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.History;
using System.Utilities;

report 6002 "Delete Service Document Log"
{
    Caption = 'Delete Service Document Log';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Document Log"; "Service Document Log")
        {
            DataItemTableView = sorting("Change Date");
            RequestFilterFields = "Change Date", "Document Type", "Document No.";

            trigger OnAfterGetRecord()
            begin
                if not ProcessDeletedOnly then
                    CurrReport.Break();

                ServHeader.Reset();
                if (("Document Type" = "Document Type"::Order) or
                    ("Document Type" = "Document Type"::Invoice) or
                    ("Document Type" = "Document Type"::"Credit Memo") or
                    ("Document Type" = "Document Type"::Quote)) and not ServHeader.Get("Document Type", "Document No.") or
                   ("Document Type" = "Document Type"::Shipment) and not ServShptHeader.Get("Document No.") or
                   ("Document Type" = "Document Type"::"Posted Invoice") and not ServInvHeader.Get("Document No.") or
                   ("Document Type" = "Document Type"::"Posted Credit Memo") and not ServCrMemoHeader.Get("Document No.")
                then begin
                    ServOrdLog.Reset();
                    ServOrdLog.SetRange("Document Type", "Document Type");
                    ServOrdLog.SetRange("Document No.", "Document No.");
                    LogEntryFiltered := ServOrdLog.Count();

                    LogEntryDeleted := LogEntryDeleted + LogEntryFiltered;
                    LogEntryProcessed := LogEntryProcessed + LogEntryFiltered;
                    ServOrdLog.DeleteAll();

                    Window.Update(2, LogEntryDeleted)
                end else
                    LogEntryProcessed := LogEntryProcessed + 1;

                Window.Update(1, LogEntryProcessed);
                Window.Update(3, Round(LogEntryProcessed / CounterTotal * 10000, 1));
            end;

            trigger OnPostDataItem()
            begin
                if not HideConfirmationDlg then
                    if LogEntryDeleted > 1 then
                        Message(Text004, LogEntryDeleted)
                    else
                        Message(Text005, LogEntryDeleted);
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                CounterTotal := Count;
                if ProcessDeletedOnly then begin
                    if not HideConfirmationDlg then
                        if not ConfirmManagement.GetResponseOrDefault(Text006, true) then
                            CurrReport.Break();
                    Window.Open(Text007 + Text008 + Text009);
                    exit;
                end;
                if CounterTotal = 0 then begin
                    if not HideConfirmationDlg then
                        Message(Text000);
                    CurrReport.Break();
                end;
                if not HideConfirmationDlg then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(Text001, CounterTotal, TableCaption), true)
                    then
                        Error(Text003);

                DeleteAll();
                LogEntryDeleted := CounterTotal;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ProcessDeletedOnly; ProcessDeletedOnly)
                    {
                        ApplicationArea = Service;
                        Caption = 'Delete Log Entries for Deleted Documents Only';
                        ToolTip = 'Specifies if you want the batch job to process log entries only for the documents that have already been deleted. ';
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

    trigger OnInitReport()
    begin
        OnPostReportStatus := false;
    end;

    trigger OnPostReport()
    begin
        OnPostReportStatus := true;
    end;

    var
        ServHeader: Record "Service Header";
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ServOrdLog: Record "Service Document Log";
        Window: Dialog;
        LogEntryProcessed: Integer;
        LogEntryDeleted: Integer;
        LogEntryFiltered: Integer;
        CounterTotal: Integer;
        ProcessDeletedOnly: Boolean;
        HideConfirmationDlg: Boolean;
        OnPostReportStatus: Boolean;

#pragma warning disable AA0074
        Text000: Label 'There is nothing to delete.';
#pragma warning disable AA0470
        Text001: Label '%1 %2 records will be deleted.\\Do you want to continue?', Comment = '10 Service Docuent Log record(s) will be deleted.\\Do you want to continue?';
#pragma warning restore AA0470
        Text003: Label 'No records were deleted.';
#pragma warning disable AA0470
        Text004: Label '%1 records were deleted.';
        Text005: Label '%1 record was deleted.';
#pragma warning restore AA0470
        Text006: Label 'Do you want to delete the service order log entries for deleted service orders?';
#pragma warning disable AA0470
        Text007: Label 'Log entries processed: #1######\\';
        Text008: Label 'Log entries deleted:   #2######\\';
#pragma warning restore AA0470
        Text009: Label '@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0074

    procedure SetHideConfirmationDlg(HideDlg: Boolean)
    begin
        HideConfirmationDlg := HideDlg;
    end;

    procedure SetProcessDeletedOnly(DeletedOnly: Boolean)
    begin
        ProcessDeletedOnly := DeletedOnly;
    end;

    procedure GetServDocLog(var ServDocLog: Record "Service Document Log")
    begin
        ServDocLog.Copy("Service Document Log");
    end;

    procedure GetOnPostReportStatus(): Boolean
    begin
        exit(OnPostReportStatus and not ProcessDeletedOnly);
    end;
}

