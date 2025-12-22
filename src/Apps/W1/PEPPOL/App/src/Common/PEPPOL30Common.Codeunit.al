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
using Microsoft.Service.History;

/// <summary>
/// Provides conversion utilities for transforming posted document records into Sales Header/Line buffers.
/// Used by the PEPPOL Posted Document Iterator implementations to normalize different document types.
/// </summary>
codeunit 37218 "PEPPOL30 Common"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Peppol30: Codeunit "PEPPOL30";
        UnsupportedDocumentErr: Label 'The document type is not supported for PEPPOL 3.0 export.';

    /// <summary>
    /// Converts a posted document header RecordRef to a Sales Header buffer.
    /// Supports Sales Invoice Header, Sales Cr.Memo Header, Service Invoice Header, and Service Cr.Memo Header.
    /// </summary>
    /// <param name="PostedRecRef">The RecordRef pointing to the posted document header.</param>
    /// <param name="SalesHeader">Return value: The Sales Header record populated with fields from the posted document.</param>
    procedure ConvertPostedHeaderToSalesHeader(var PostedRecRef: RecordRef; var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case PostedRecRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    PostedRecRef.SetTable(SalesInvoiceHeader);
                    SalesHeader.TransferFields(SalesInvoiceHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    PostedRecRef.SetTable(SalesCrMemoHeader);
                    SalesHeader.TransferFields(SalesCrMemoHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                end;
            Database::"Service Invoice Header":
                begin
                    PostedRecRef.SetTable(ServiceInvoiceHeader);
                    Peppol30.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    PostedRecRef.SetTable(ServiceCrMemoHeader);
                    Peppol30.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    /// <summary>
    /// Converts a posted document line RecordRef to a Sales Line buffer.
    /// Supports Sales Invoice Line, Sales Cr.Memo Line, Service Invoice Line, and Service Cr.Memo Line.
    /// </summary>
    /// <param name="PostedLineRecRef">The RecordRef pointing to the posted document line.</param>
    /// <param name="SalesLine">Return value: The Sales Line record populated with fields from the posted document line.</param>
    procedure ConvertPostedLineToSalesLine(var PostedLineRecRef: RecordRef; var SalesLine: Record "Sales Line")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        case PostedLineRecRef.Number() of
            Database::"Sales Invoice Line":
                begin
                    PostedLineRecRef.SetTable(SalesInvoiceLine);
                    SalesLine.TransferFields(SalesInvoiceLine);
                    SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                end;
            Database::"Sales Cr.Memo Line":
                begin
                    PostedLineRecRef.SetTable(SalesCrMemoLine);
                    SalesLine.TransferFields(SalesCrMemoLine);
                    SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                end;
            Database::"Service Invoice Line":
                begin
                    PostedLineRecRef.SetTable(ServiceInvoiceLine);
                    Peppol30.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                    SalesLine.Type := Peppol30.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                    SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                end;
            Database::"Service Cr.Memo Line":
                begin
                    PostedLineRecRef.SetTable(ServiceCrMemoLine);
                    Peppol30.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                    SalesLine.Type := Peppol30.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                    SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    /// <summary>
    /// Calculates and retrieves VAT totals for a posted document.
    /// Supports Sales Invoice, Sales Credit Memo, Service Invoice, and Service Credit Memo.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="TempVATAmtLine">Temporary VAT amount line record to store calculated totals.</param>
    /// <param name="TempVATProductPostingGroup">Temporary VAT product posting group record.</param>
    /// <param name="PEPPOLFormat">The PEPPOL 3.0 format to use for tax info provider.</param>
    procedure GetTotals(var PostedDocHeaderRecRef: RecordRef; var PostedDocLineRecRef: RecordRef; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary; PEPPOLFormat: Enum "PEPPOL 3.0 Format")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesLine: Record "Sales Line";
        LineRecRef: RecordRef;
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
        PostedDocNo: Code[20];
    begin
        PEPPOLTaxInfoProvider := PEPPOLFormat;
        case PostedDocHeaderRecRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesInvoiceHeader);
                    PostedDocLineRecRef.SetTable(SalesInvoiceLine);
                    PostedDocNo := SalesInvoiceHeader."No.";
                    SalesInvoiceLine.SetRange("Document No.", PostedDocNo);
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(SalesInvoiceLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLTaxInfoProvider.GetTaxTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesInvoiceLine.Next() = 0;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesCrMemoHeader);
                    PostedDocLineRecRef.SetTable(SalesCrMemoLine);
                    PostedDocNo := SalesCrMemoHeader."No.";
                    SalesCrMemoLine.SetRange("Document No.", PostedDocNo);
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(SalesCrMemoLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLTaxInfoProvider.GetTaxTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until SalesCrMemoLine.Next() = 0;
                end;
            Database::"Service Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceInvoiceHeader);
                    PostedDocLineRecRef.SetTable(ServiceInvoiceLine);
                    PostedDocNo := ServiceInvoiceHeader."No.";
                    ServiceInvoiceLine.SetRange("Document No.", PostedDocNo);
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(ServiceInvoiceLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLTaxInfoProvider.GetTaxTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until ServiceInvoiceLine.Next() = 0;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceCrMemoHeader);
                    PostedDocLineRecRef.SetTable(ServiceCrMemoLine);
                    PostedDocNo := ServiceCrMemoHeader."No.";
                    ServiceCrMemoLine.SetRange("Document No.", PostedDocNo);
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(ServiceCrMemoLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLTaxInfoProvider.GetTaxTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until ServiceCrMemoLine.Next() = 0;
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    /// <summary>
    /// Sets document attachment filters based on the posted document header.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="DocumentAttachments">The Document Attachment record to set filters on.</param>
    procedure SetDocumentAttachmentFilters(var PostedDocHeaderRecRef: RecordRef; var DocumentAttachments: Record "Document Attachment")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case PostedDocHeaderRecRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesInvoiceHeader);
                    DocumentAttachments.SetRange("Table ID", Database::"Sales Invoice Header");
                    DocumentAttachments.SetRange("No.", SalesInvoiceHeader."No.");
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesCrMemoHeader);
                    DocumentAttachments.SetRange("Table ID", Database::"Sales Cr.Memo Header");
                    DocumentAttachments.SetRange("No.", SalesCrMemoHeader."No.");
                end;
            Database::"Service Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceInvoiceHeader);
                    DocumentAttachments.SetRange("Table ID", Database::"Service Invoice Header");
                    DocumentAttachments.SetRange("No.", ServiceInvoiceHeader."No.");
                end;
            Database::"Service Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceCrMemoHeader);
                    DocumentAttachments.SetRange("Table ID", Database::"Service Cr.Memo Header");
                    DocumentAttachments.SetRange("No.", ServiceCrMemoHeader."No.");
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    /// <summary>
    /// Gets the invoice rounding line from the posted document lines.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record for storing the rounding line.</param>
    /// <param name="PEPPOLFormat">The PEPPOL 3.0 format to use for monetary info provider.</param>
    procedure GetInvoiceRoundingLine(PostedDocHeaderRecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; PEPPOLFormat: Enum "PEPPOL 3.0 Format")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesLine: Record "Sales Line";
        LineRecRef: RecordRef;
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
    begin
        PEPPOLMonetaryInfoProvider := PEPPOLFormat;
        case PostedDocHeaderRecRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                    SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
                    if SalesInvoiceLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(SalesInvoiceLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until SalesInvoiceLine.Next() = 0;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                    SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(SalesCrMemoLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until SalesCrMemoLine.Next() = 0;
                end;
            Database::"Service Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
                    ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(ServiceInvoiceLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until ServiceInvoiceLine.Next() = 0;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
                    ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            LineRecRef.GetTable(ServiceCrMemoLine);
                            ConvertPostedLineToSalesLine(LineRecRef, SalesLine);
                            PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                        until ServiceCrMemoLine.Next() = 0;
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    /// <summary>
    /// Sets filters on posted document lines, excluding the rounding line if present.
    /// </summary>
    /// <param name="PostedDocHeaderRecRef">The RecordRef for the posted document header.</param>
    /// <param name="PostedDocLineRecRef">The RecordRef for the posted document lines to set filters on.</param>
    /// <param name="TempSalesLineRounding">Temporary sales line record containing the rounding line to exclude.</param>
    procedure SetFilters(var PostedDocHeaderRecRef: RecordRef; var PostedDocLineRecRef: RecordRef; TempSalesLineRounding: Record "Sales Line" temporary)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        PostedDocHeaderRecRef.SetRecFilter();
        case PostedDocHeaderRecRef.Number() of
            Database::"Sales Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
                    SalesInvoiceLine.SetFilter(Type, '<>%1', SalesInvoiceLine.Type::" ");
                    if TempSalesLineRounding."Line No." <> 0 then
                        SalesInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
                    PostedDocLineRecRef.GetTable(SalesInvoiceLine);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
                    SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
                    if TempSalesLineRounding."Line No." <> 0 then
                        SalesCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
                    PostedDocLineRecRef.GetTable(SalesCrMemoLine);
                end;
            Database::"Service Invoice Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
                    ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
                    if TempSalesLineRounding."Line No." <> 0 then
                        ServiceInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
                    PostedDocLineRecRef.GetTable(ServiceInvoiceLine);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    PostedDocHeaderRecRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
                    ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
                    if TempSalesLineRounding."Line No." <> 0 then
                        ServiceCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
                    PostedDocLineRecRef.GetTable(ServiceCrMemoLine);
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;
}
