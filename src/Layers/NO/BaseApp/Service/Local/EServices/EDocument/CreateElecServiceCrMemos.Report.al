// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Service.History;

report 10645 "Create Elec. Service Cr. Memos"
{
    Caption = 'Create Elec. Service Cr. Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "Bill-to Customer No.", GLN, "E-Invoice Created";

            trigger OnAfterGetRecord()
            var
                EInvoiceExpServCrMemo: Codeunit "E-Invoice Exp. Serv. Cr. Memo";
            begin
                EInvoiceExpServCrMemo.Run("Service Cr.Memo Header");
                EInvoiceExpServCrMemo.GetExportedFileInfo(TempEInvoiceTransferFile);
                TempEInvoiceTransferFile."Line No." := Counter + 1;
                TempEInvoiceTransferFile.Insert();

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
                ServCrMemoHeader: Record "Service Cr.Memo Header";
            begin
                Counter := 0;

                // Any electronic service credit memos?
                ServCrMemoHeader.Copy("Service Cr.Memo Header");
                ServCrMemoHeader.FilterGroup(6);
                ServCrMemoHeader.SetRange("E-Invoice", true);
                if not ServCrMemoHeader.FindFirst() then
                    Error(Text003);

                // All electronic service credit memos?
                ServCrMemoHeader.SetRange("E-Invoice", false);
                if ServCrMemoHeader.FindFirst() then
                    if not Confirm(Text000, true) then
                        CurrReport.Quit();
                ServCrMemoHeader.SetRange("E-Invoice");

                // Some already sent?
                ServCrMemoHeader.SetRange("E-Invoice Created", true);
                if ServCrMemoHeader.FindFirst() then
                    if not Confirm(Text001) then
                        CurrReport.Quit();

                SetRange("E-Invoice", true);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;
        Counter: Integer;
        Text000: Label 'One or more credit memo documents that match your filter criteria are not electronic credit memos and will be skipped.\\Do you want to continue?';
        Text001: Label 'One or more credit memo documents that match your filter criteria have been created before.\\Do you want to continue?';
        Text002: Label 'Successfully created %1 electronic credit memo documents.';
        Text003: Label 'Nothing to create.';
}

