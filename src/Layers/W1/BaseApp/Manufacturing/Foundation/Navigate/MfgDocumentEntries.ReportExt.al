// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;

reportextension 99000965 "Mfg. Document Entries" extends "Document Entries"
{
    dataset
    {
        addafter("Ins. Coverage Ledger Entry")
        {
            dataitem("Capacity Ledger Entry"; "Capacity Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(EntryNo_CapLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_CapLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_CapLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_CapLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_CapLedgEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(CapLedgEntryPostDtCaption; CapLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Capacity Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
        }
        addafter("Purch. Cr. Memo Hdr.")
        {
            dataitem("Production Order"; "Production Order")
            {
                DataItemTableView = sorting(Status, "No.");
                column(No_ProdOrder; "No.")
                {
                    IncludeCaption = true;
                }
                column(Status_ProdOrder; Status)
                {
                    IncludeCaption = true;
                }
                column(StatusCaption_ProdOrder; FieldCaption(Status))
                {
                }
                column(Desc_ProdOrder; Description)
                {
                    IncludeCaption = true;
                }
                column(SourceType_ProdOrder; "Source Type")
                {
                    IncludeCaption = true;
                }
                column(SourceNo_ProdOrder; "Source No.")
                {
                    IncludeCaption = true;
                }
                column(UnitCost_ProdOrder; "Unit Cost")
                {
                    IncludeCaption = true;
                }
                column(CostAmt_ProdOrder; "Cost Amount")
                {
                    IncludeCaption = true;
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Production Order" then
                        CurrReport.Break();

                    SetCurrentKey(Status, "No.");
                    SetRange(Status, Status::Released, Status::Finished);
                    SetFilter("No.", DocNoFilter);
                end;
            }
        }
    }

    var
        CapLedgEntryPostDtCaptionLbl: Label 'Posting Date';
}
