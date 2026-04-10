// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

report 10640 "Create Electronic Invoices"
{
    Caption = 'Create Electronic Invoices';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Invoice Header"; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");
#if not CLEAN29
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", GLN, "E-Invoice Created";
#endif

            trigger OnAfterGetRecord()
#if not CLEAN29
            var
                EInvoiceExportSalesInvoice: Codeunit "E-Invoice Export Sales Invoice";
#endif
            begin
#if not CLEAN29
                EInvoiceExportSalesInvoice.Run("Sales Invoice Header");
                EInvoiceExportSalesInvoice.GetExportedFileInfo(TempEInvoiceTransferFile);
                TempEInvoiceTransferFile."Line No." := Counter + 1;
                TempEInvoiceTransferFile.Insert();
#endif

                if LogInteraction then
                    if "Bill-to Contact No." <> '' then
                        SegManagement.LogDocument(
                          4, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.", "Salesperson Code",
                          "Campaign No.", "Posting Description", '')
                    else
                        SegManagement.LogDocument(
                          4, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.", "Salesperson Code",
                          "Campaign No.", "Posting Description", '');

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
                SalesInvHeader: Record "Sales Invoice Header";
            begin
                Counter := 0;

                // Any electronic invoices?
                SalesInvHeader.Copy("Sales Invoice Header");
                SalesInvHeader.FilterGroup(6);
#if not CLEAN29
                SalesInvHeader.SetRange("E-Invoice", true);
#endif
                if not SalesInvHeader.FindFirst() then
                    Error(Text003);

                // All electronic invoices?
#if not CLEAN29
                SalesInvHeader.SetRange("E-Invoice", false);
#endif
                if SalesInvHeader.FindFirst() then
                    if not Confirm(Text000, true) then
                        CurrReport.Quit();
#if not CLEAN29
                SalesInvHeader.SetRange("E-Invoice");
#endif

                // Some already sent?
#if not CLEAN29
                SalesInvHeader.SetRange("E-Invoice Created", true);
#endif
                if SalesInvHeader.FindFirst() then
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
        Text000: Label 'One or more invoice documents that match your filter criteria are not electronic invoices and will be skipped.\\Do you want to continue?';
        Text001: Label 'One or more invoice documents that match your filter criteria have been created before.\\Do you want to continue?';
        Text002: Label 'Successfully created %1 electronic invoice documents.';
#if not CLEAN29
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;
#endif
        SegManagement: Codeunit SegManagement;
        Counter: Integer;
        Text003: Label 'Nothing to create.';
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.") <> '';
    end;
}

