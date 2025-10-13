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

codeunit 37213 "PEPPOL30 Sales Export Mgmt." implements "PEPPOL30 Export Management"
{
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesType: Option Invoice,CreditMemo;
        DocumentNo: Code[20];

    /// <summary>
    /// Initializes the export management with the provided record reference and associated data.
    /// </summary>
    /// <param name="NewRecordRef">The record reference to the source document.</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record for handling rounding adjustments.</param>
    /// <param name="DocumentAttachments">Document attachments record for handling file attachments.</param>
    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    begin
        case NewRecordRef.Number() of
            Database::"Sales Cr.Memo Header":
                InitCreditMemo(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
            Database::"Sales Invoice Header":
                InitSalesInvoice(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
        end;
    end;

    local procedure InitSalesInvoice(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesInvoiceNoErr: Label 'You must specify a sales invoice number.';
    begin
        SalesType := SalesType::Invoice;
        NewRecordRef.SetTable(SalesInvoiceHeader);
        if SalesInvoiceHeader."No." = '' then
            Error(SpecifyASalesInvoiceNoErr);

        DocumentNo := SalesInvoiceHeader."No.";
        SalesInvoiceHeader.SetRecFilter();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");

        if SalesInvoiceLine.FindSet() then
            repeat
                SalesLine.TransferFields(SalesInvoiceLine);
                PEPPOLMonetaryInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
            until SalesInvoiceLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            SalesInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

        DocumentAttachments.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachments.SetRange("No.", SalesInvoiceHeader."No.");
    end;

    local procedure InitCreditMemo(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
    begin
        SalesType := SalesType::CreditMemo;
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
                PEPPOLMonetaryInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales";
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
    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format") Found: Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        case SalesType of
            SalesType::Invoice:
                exit(PEPPOLPostedDocumentIterator.FindNextSalesInvoiceRec(SalesInvoiceHeader, SalesHeader, Position));
            SalesType::CreditMemo:
                exit(PEPPOLPostedDocumentIterator.FindNextSalesCreditMemoRec(SalesCrMemoHeader, SalesHeader, Position));
        end;
    end;

    /// <summary>
    /// Finds the next sales credit memo line record in the export sequence.
    /// </summary>
    /// <param name="Position">The position/index for finding the next line record.</param>
    /// <param name="EDocumentFormat">The e-document format to use.</param>
    /// <returns>True if a line record was found, false otherwise.</returns>
    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format"): Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        case SalesType of
            SalesType::Invoice:
                exit(PEPPOLPostedDocumentIterator.FindNextSalesInvoiceLineRec(SalesInvoiceLine, SalesLine, Position));
            SalesType::CreditMemo:
                exit(PEPPOLPostedDocumentIterator.FindNextSalesCreditMemoLineRec(SalesCrMemoLine, SalesLine, Position));
        end;
    end;

    /// <summary>
    /// Calculates and retrieves VAT totals for the sales credit memo.
    /// </summary>
    /// <param name="TempVATAmtLine">Temporary VAT amount line record to store calculated totals.</param>
    /// <param name="TempVATProductPostingGroup">Temporary VAT product posting group record.</param>
#if not CLEAN25
#pragma warning disable AL0432
#endif
    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
#if not CLEAN25
#pragma warning restore AL0432
#endif
    var
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        case SalesType of
            SalesType::Invoice:
                begin
                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesInvoiceLine);
                            PEPPOLTaxInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales";
                            PEPPOLTaxInfoProvider.GetTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesInvoiceLine.Next() = 0;
                end;
            SalesType::CreditMemo:
                begin
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(SalesCrMemoLine);
                            PEPPOLTaxInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales";
                            PEPPOLTaxInfoProvider.GetTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesCrMemoLine.Next() = 0;
                end;
        end;
    end;

    procedure GetRec(): Variant
    begin
        exit(SalesHeader);
    end;

    procedure GetLineRec(): Variant
    begin
        exit(SalesLine);
    end;
}