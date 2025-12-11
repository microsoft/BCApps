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

codeunit 37213 "PEPPOL30 Sales Export Mgmt." implements "PEPPOL30 Export Management", "PEPPOL Posted Document Iterator"
{

    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        PEPPOL30Setup: Record "PEPPOL 3.0 Setup";
        GlobalPostedDocumentHeader, GlobalPostedDocumentLine : RecordRef;
        DocumentNo: Code[20];
        UnsupportedDocumentErr: Label 'The sales document type is not supported for PEPPOL 3.0 export.';

    /// <summary>
    /// Initializes the export management with the provided record reference and associated data.
    /// </summary>
    /// <param name="NewRecordRef">The record reference to the source document.</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record for handling rounding adjustments.</param>
    /// <param name="DocumentAttachments">Document attachments record for handling file attachments.</param>
    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    begin
        PEPPOL30Setup.GetSetup();
        case NewRecordRef.Number() of
            Database::"Sales Cr.Memo Header":
                InitCreditMemo(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
            Database::"Sales Invoice Header":
                InitSalesInvoice(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    local procedure InitSalesInvoice(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesInvoiceNoErr: Label 'You must specify a sales invoice number.';
    begin
        // SalesType := SalesType::Invoice;
        NewRecordRef.SetTable(SalesInvoiceHeader);
        if SalesInvoiceHeader."No." = '' then
            Error(SpecifyASalesInvoiceNoErr);

        DocumentNo := SalesInvoiceHeader."No.";
        SalesInvoiceHeader.SetRecFilter();
        GlobalPostedDocumentHeader.GetTable(SalesInvoiceHeader);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");

        if SalesInvoiceLine.FindSet() then
            repeat
                GlobalSalesLine.TransferFields(SalesInvoiceLine);
                PEPPOLMonetaryInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Sales Format";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, GlobalSalesLine);
            until SalesInvoiceLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            SalesInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

        GlobalPostedDocumentLine.GetTable(SalesInvoiceLine);
        DocumentAttachments.SetRange("Table ID", Database::"Sales Invoice Header");
        DocumentAttachments.SetRange("No.", SalesInvoiceHeader."No.");
    end;

    local procedure InitCreditMemo(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
    begin
        // SalesType := SalesType::CreditMemo;
        NewRecordRef.SetTable(SalesCrMemoHeader);
        if SalesCrMemoHeader."No." = '' then
            Error(SpecifyASalesCreditMemoNoErr);

        DocumentNo := SalesCrMemoHeader."No.";
        SalesCrMemoHeader.SetRecFilter();
        GlobalPostedDocumentHeader.GetTable(SalesCrMemoHeader);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");

        if SalesCrMemoLine.FindSet() then
            repeat
                GlobalSalesLine.TransferFields(SalesCrMemoLine);
                PEPPOLMonetaryInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Sales Format";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, GlobalSalesLine);
            until SalesCrMemoLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            SalesCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
        GlobalPostedDocumentLine.GetTable(SalesCrMemoLine);
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
        exit(PEPPOLPostedDocumentIterator.FindNextPostedRec(GlobalPostedDocumentHeader, GlobalSalesHeader, Position));
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
        exit(PEPPOLPostedDocumentIterator.FindNextPostedLineRec(GlobalPostedDocumentLine, GlobalSalesLine, Position));
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
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        case GlobalPostedDocumentHeader.Number() of
            Database::"Sales Invoice Header":
                begin
                    GlobalPostedDocumentLine.SetTable(SalesInvoiceLine);
                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            GlobalSalesLine.TransferFields(SalesInvoiceLine);
                            PEPPOLTaxInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Sales Format";
                            PEPPOLTaxInfoProvider.GetTotals(GlobalSalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(GlobalSalesLine, TempVATProductPostingGroup);
                        until SalesInvoiceLine.Next() = 0;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    GlobalPostedDocumentLine.SetTable(SalesCrMemoLine);
                    SalesCrMemoLine.SetRange("Document No.", DocumentNo);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            GlobalSalesLine.TransferFields(SalesCrMemoLine);
                            PEPPOLTaxInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Sales Format";
                            PEPPOLTaxInfoProvider.GetTotals(GlobalSalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(GlobalSalesLine, TempVATProductPostingGroup);
                        until SalesCrMemoLine.Next() = 0;
                end;
        end;
    end;

    procedure GetRec(): Variant
    begin
        exit(GlobalSalesHeader);
    end;

    procedure GetLineRec(): Variant
    begin
        exit(GlobalSalesLine);
    end;

    procedure FindNextPostedRec(var PostedRec: RecordRef; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Position = 1 then
            Found := PostedRec.Find('-')
        else
            Found := PostedRec.Next() <> 0;

        if Found then
            case PostedRec.Number() of
                Database::"Sales Invoice Header":
                    begin
                        PostedRec.SetTable(SalesInvoiceHeader);
                        SalesHeader.TransferFields(SalesInvoiceHeader);
                        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                    end;
                Database::"Sales Cr.Memo Header":
                    begin
                        PostedRec.SetTable(SalesCrMemoHeader);
                        SalesHeader.TransferFields(SalesCrMemoHeader);
                        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    end;
                else
                    Error(UnsupportedDocumentErr);
            end;
        exit(Found);
    end;

    procedure FindNextPostedLineRec(var PostedRecLine: RecordRef; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        if Position = 1 then
            Found := PostedRecLine.Find('-')
        else
            Found := PostedRecLine.Next() <> 0;

        if Found then
            case PostedRecLine.Number() of
                Database::"Sales Invoice Header":
                    begin
                        PostedRecLine.SetTable(SalesInvoiceLine);
                        SalesLine.TransferFields(SalesInvoiceLine);
                        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                    end;
                Database::"Sales Cr.Memo Header":
                    begin
                        PostedRecLine.SetTable(SalesCrMemoLine);
                        SalesLine.TransferFields(SalesCrMemoLine);
                        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                    end;
                else
                    Error(UnsupportedDocumentErr);
            end;
        exit(Found);
    end;

}