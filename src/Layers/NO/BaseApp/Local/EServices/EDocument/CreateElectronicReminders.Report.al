// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Reminder;

report 10642 "Create Electronic Reminders"
{
    Caption = 'Create Electronic Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.";

            trigger OnAfterGetRecord()
#if not CLEAN29
            var
                EInvoiceExportIssReminder: Codeunit "E-Invoice Export Iss. Reminder";
#endif
            begin
#if not CLEAN29
                EInvoiceExportIssReminder.Run("Issued Reminder Header");
                EInvoiceExportIssReminder.GetExportedFileInfo(TempEInvoiceTransferFile);
                TempEInvoiceTransferFile."Line No." := Counter + 1;
                TempEInvoiceTransferFile.Insert();
#endif

                if LogInteraction then
                    SegManagement.LogDocument(
                      8, "No.", 0, 0, DATABASE::Customer, "Customer No.", '', '', "Posting Description", '');

                Commit();
                Counter := Counter + 1;
            end;

            trigger OnPostDataItem()
#if not CLEAN29
            var
                EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
#endif
            begin
#if not CLEAN29
                EInvoiceExportCommon.DownloadEInvoiceFile(TempEInvoiceTransferFile);
#endif
                Message(Text002, Counter);
            end;

            trigger OnPreDataItem()
            var
                IssuedReminderHeader: Record "Issued Reminder Header";
            begin
                Counter := 0;

                // Any electronic reminders?
                IssuedReminderHeader.Copy("Issued Reminder Header");
                IssuedReminderHeader.FilterGroup(6);
#if not CLEAN29
                IssuedReminderHeader.SetRange("E-Invoice", true);
#endif
                if not IssuedReminderHeader.FindFirst() then
                    Error(Text003);

                // All electronic reminders?
#if not CLEAN29
                IssuedReminderHeader.SetRange("E-Invoice", false);
#endif
                if IssuedReminderHeader.FindFirst() then
                    if not Confirm(Text000, true) then
                        CurrReport.Quit();
#if not CLEAN29
                IssuedReminderHeader.SetRange("E-Invoice");
#endif

                // Some already sent?
#if not CLEAN29
                IssuedReminderHeader.SetRange("E-Invoice Created", true);
#endif
                if IssuedReminderHeader.FindFirst() then
                    if not Confirm(Text001, true) then
                        CurrReport.Quit();

#if not CLEAN29
                SetRange("E-Invoice", true);
#endif
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
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the related record to be recorded as an interaction and be added to the Interaction Log Entry table.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction();
    end;

    var
#if not CLEAN29
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;
#endif
        SegManagement: Codeunit SegManagement;
        Counter: Integer;
        LogInteraction: Boolean;
        Text000: Label 'One or more issued reminders that match your filter criteria are not electronic reminders and will be skipped.\\Do you want to continue?';
        Text001: Label 'One or more electronic reminders that match your filter criteria have been created before.\\Do you want to continue?';
        Text002: Label 'Successfully created %1 electronic reminders.';
        Text003: Label 'Nothing to create.';
        LogInteractionEnable: Boolean;

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Rmdr.") <> '';
    end;
}

