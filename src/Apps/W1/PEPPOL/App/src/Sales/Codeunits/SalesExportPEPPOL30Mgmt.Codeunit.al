// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 37213 "Sales Export PEPPOL30 Mgmt." implements "PEPPOL30 Export Management"
{
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];

    /// <summary>
    /// Initializes the export management with the provided record reference and associated data.
    /// </summary>
    /// <param name="NewRecordRef">The record reference to the source document.</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record for handling rounding adjustments.</param>
    /// <param name="DocumentAttachments">Document attachments record for handling file attachments.</param>
    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
    begin
        NewRecordRef.SetTable(SalesCrMemoHeader);
        if SalesCrMemoHeader."No." = '' then
            Error(SpecifyASalesCreditMemoNoErr);

        DocumentNo := SalesCrMemoHeader."No.";
        SalesCrMemoHeader.SetRecFilter();
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");

        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                PEPPOLMonetaryInfoProvider := "E-Document Format"::"PEPPOL 3.0";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
            until SalesCrMemoLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            SalesCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
        DocumentAttachments.SetRange("Table ID", Database::"Sales Cr.Memo Header");
        DocumentAttachments.SetRange("No.", SalesCrMemoHeader."No.");
    end;

    /// <summary>
    /// Finds the next sales credit memo record in the export sequence.
    /// </summary>
    /// <param name="Position">The position/index for finding the next record.</param>
    /// <param name="EDocumentFormat">The e-document format to use.</param>
    /// <returns>True if a record was found, false otherwise.</returns>
    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "E-Document Format") Found: Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position));
    end;

    /// <summary>
    /// Finds the next sales credit memo line record in the export sequence.
    /// </summary>
    /// <param name="Position">The position/index for finding the next line record.</param>
    /// <param name="EDocumentFormat">The e-document format to use.</param>
    /// <returns>True if a line record was found, false otherwise.</returns>
    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "E-Document Format"): Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextSalesCreditMemoLineRec(SalesCrMemoLine, SalesLine, Position));
    end;

    /// <summary>
    /// Calculates and retrieves VAT totals for the sales credit memo.
    /// </summary>
    /// <param name="TempVATAmtLine">Temporary VAT amount line record to store calculated totals.</param>
    /// <param name="TempVATProductPostingGroup">Temporary VAT product posting group record.</param>
    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
    var
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesCrMemoLine);
                PEPPOLTaxInfoProvider := "E-Document Format"::"PEPPOL 3.0";
                PEPPOLTaxInfoProvider.GetTotals(SalesLine, TempVATAmtLine);
                PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
            until SalesCrMemoLine.Next() = 0;
    end;
}