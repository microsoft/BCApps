// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

/// <summary>
/// Report for generating sample purchase invoice PDFs using temporary tables.
/// This report is independent from the standard Purchase - Invoice report (Report 406).
/// </summary>
report 5392 "Sample Purchase Invoice"
{
    Caption = 'Sample Purchase Invoice';
    DefaultLayout = Word;
    WordLayout = 'SamplePurchInvoice.docx';

    dataset
    {
        dataitem(Header; "Sample Purch. Inv. Header")
        {
            UseTemporary = true;
            column(No_; "No.")
            {
            }
            column(BuyFromVendorNo; "Buy-from Vendor No.")
            {
            }
            column(VendorInvoiceNo; "Vendor Invoice No.")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            dataitem(Line; "Sample Purch. Inv. Line")
            {
                UseTemporary = true;
                DataItemLink = "Document No." = field("No.");
                column(DocumentNo; "Document No.")
                {
                }
                column(LineNo; "Line No.")
                {
                }
                column(Type; Type)
                {
                }
                column(LineNo_; "No.")
                {
                }
                column(TaxGroupCode; "Tax Group Code")
                {
                }
                column(Description; Description)
                {
                }
                column(Quantity; Quantity)
                {
                }
                column(DirectUnitCost; "Direct Unit Cost")
                {
                }
                column(DeferralCode; "Deferral Code")
                {
                }
                column(UnitOfMeasureCode; "Unit of Measure Code")
                {
                }
                column(LineAmount; Quantity * "Direct Unit Cost")
                {
                }
            }

            trigger OnPreDataItem()
            begin
                Header.Copy(TempSamplePurchInvHeader, true);
            end;
        }
    }

    var
        TempSamplePurchInvHeader: Record "Sample Purch. Inv. Header" temporary;
        TempSamplePurchInvLine: Record "Sample Purch. Inv. Line" temporary;

    /// <summary>
    /// Sets the data for the report from external temporary tables.
    /// </summary>
    /// <param name="TempHeader">Temporary header record to use.</param>
    /// <param name="TempLines">Temporary line records to use.</param>
    procedure SetData(var TempHeader: Record "Sample Purch. Inv. Header" temporary; var TempLines: Record "Sample Purch. Inv. Line" temporary)
    begin
        TempSamplePurchInvHeader.Copy(TempHeader, true);
        TempSamplePurchInvLine.Copy(TempLines, true);
        Line.Copy(TempSamplePurchInvLine, true);
    end;
}
