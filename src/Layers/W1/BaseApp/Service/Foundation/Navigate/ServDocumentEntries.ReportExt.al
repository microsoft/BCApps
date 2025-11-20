// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Service.Ledger;
using Microsoft.Service.History;

reportextension 6465 "Serv. Document Entries" extends "Document Entries"
{
    dataset
    {
        addbefore("Sales Shipment Header")
        {
            dataitem("Service Ledger Entry"; "Service Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(PostDate_ServiceLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ServLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ServLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(AmtLCY_ServLedgEntry; "Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_ServLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(ServCntrtNo_ServLedgEntry; "Service Contract No.")
                {
                    IncludeCaption = true;
                }
                column(ServLedgEntryPostDtCaption; ServLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Service Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Warranty Ledger Entry"; "Warranty Ledger Entry")
            {
                DataItemTableView = sorting("Document No.", "Posting Date");
                column(EntryNo_WarrantyLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PostDt_WarrantyLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_WarrantyLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_WarrantyLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amt_WarrantyLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(WarrantyLedgEntryPostDtCaption; WarrantyLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Warranty Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Service Shipment Header"; "Service Shipment Header")
            {
                DataItemTableView = sorting("No.");
                column(CurrencyCaption; CurrencyCaption)
                {
                }
                column(PostDate_ServShptHeader; Format("Posting Date"))
                {
                }
                column(No_ServShptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ServShptHeader; Description)
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_ServShptHeader; "Currency Code")
                {
                }
                column(ServShptHeaderPostDateCaption; ServShptHeaderPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if TempDocumentEntry."Table ID" <> DATABASE::"Service Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
        }
    }

    var
        ServLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        WarrantyLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ServShptHeaderPostDateCaptionLbl: Label 'Posting Date';
}
