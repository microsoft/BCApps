// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

report 10641 "Create Electronic Credit Memos"
{
    Caption = 'Create Electronic Credit Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", GLN, "E-Invoice Created";

            trigger OnAfterGetRecord()
            var
                EInvoiceExpSalesCrMemo: Codeunit "E-Invoice Exp. Sales Cr. Memo";
            begin
                EInvoiceExpSalesCrMemo.Run("Sales Cr.Memo Header");
                EInvoiceExpSalesCrMemo.GetExportedFileInfo(TempEInvoiceTransferFile);
                TempEInvoiceTransferFile."Line No." := Counter + 1;
                TempEInvoiceTransferFile.Insert();

                if LogInteraction then
                    SegManagement.LogDocument(
                      6, "No.", 0, 0, DATABASE::Customer, "Sell-to Customer No.", "Salesperson Code",
                      "Campaign No.", "Posting Description", '');

                Commit();
                Counter := Counter + 1;
            end;

            trigger OnPostDataItem()
            var
                EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
            begin
                EInvoiceExportCommon.DownloadEInvoiceFile(TempEInvoiceTransferFile);
                Message(Text002, Counter);
            end;

            trigger OnPreDataItem()
            var
                SalesCrMemoHeader: Record "Sales Cr.Memo Header";
            begin
                Counter := 0;

                // Any electronic credit memos?
                SalesCrMemoHeader.Copy("Sales Cr.Memo Header");
                SalesCrMemoHeader.FilterGroup(6);
                SalesCrMemoHeader.SetRange("E-Invoice", true);
                if not SalesCrMemoHeader.FindFirst() then
                    Error(Text003);

                // All electronic credit memos?
                SalesCrMemoHeader.SetRange("E-Invoice", false);
                if SalesCrMemoHeader.FindFirst() then
                    if not Confirm(Text000, true) then
                        CurrReport.Quit();
                SalesCrMemoHeader.SetRange("E-Invoice");

                // Some already sent?
                SalesCrMemoHeader.SetRange("E-Invoice Created", true);
                if SalesCrMemoHeader.FindFirst() then
                    if not Confirm(Text001, true) then
                        CurrReport.Quit();

                SetRange("E-Invoice", true);
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
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;
        SegManagement: Codeunit SegManagement;
        Counter: Integer;
        Text000: Label 'One or more credit memo documents that match your filter criteria are not electronic credit memos and will be skipped.\\Do you want to continue?';
        Text001: Label 'One or more credit memo documents that match your filter criteria have been created before.\\Do you want to continue?';
        Text002: Label 'Successfully created %1 electronic credit memo documents.';
        Text003: Label 'Nothing to create.';
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;

    [Scope('OnPrem')]
    procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.") <> '';
    end;
}

