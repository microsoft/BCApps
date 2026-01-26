// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Service.History;

report 10644 "Create Elec. Service Invoices"
{
    Caption = 'Create Elec. Service Invoices';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Invoice Header"; "Service Invoice Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "Bill-to Customer No.", GLN, "E-Invoice Created";

            trigger OnAfterGetRecord()
            var
                EInvoiceExportServInvoice: Codeunit "E-Invoice Export Serv. Invoice";
            begin
                EInvoiceExportServInvoice.Run("Service Invoice Header");
                EInvoiceExportServInvoice.GetExportedFileInfo(TempEInvoiceTransferFile);
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
                ServInvHeader: Record "Service Invoice Header";
            begin
                Counter := 0;

                // Any electronic service invoices?
                ServInvHeader.Copy("Service Invoice Header");
                ServInvHeader.FilterGroup(6);
                ServInvHeader.SetRange("E-Invoice", true);
                if not ServInvHeader.FindFirst() then
                    Error(Text003);

                // All electronic service invoices?
                ServInvHeader.SetRange("E-Invoice", false);
                if ServInvHeader.FindFirst() then
                    if not Confirm(Text000, true) then
                        CurrReport.Quit();
                ServInvHeader.SetRange("E-Invoice");

                // Some already sent?
                ServInvHeader.SetRange("E-Invoice Created", true);
                if ServInvHeader.FindFirst() then
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
        Text000: Label 'One or more invoice documents that match your filter criteria are not electronic invoices and will be skipped.\\Do you want to continue?';
        Text001: Label 'One or more invoice documents that match your filter criteria have been created before.\\Do you want to continue?';
        Text002: Label 'Successfully created %1 electronic invoice documents.';
        Text003: Label 'Nothing to create.';
}

