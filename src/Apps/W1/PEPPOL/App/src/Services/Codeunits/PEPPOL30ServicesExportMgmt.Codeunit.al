// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;
using Microsoft.Service.History;

codeunit 37214 "PEPPOL30 Services Export Mgmt." implements "PEPPOL30 Export Management"
{
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceType: Option Invoice,CreditMemo;
        DocumentNo: Code[20];

    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    begin
        case NewRecordRef.Number() of
            Database::"Service Cr.Memo Header":
                InitCreditMemo(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
            Database::"Service Invoice Header":
                InitSalesInvoice(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
        end;
    end;

    local procedure InitSalesInvoice(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLManagement: Codeunit "PEPPOL30 Management";
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesInvoiceNoErr: Label 'You must specify a sales invoice number.';
    begin
        ServiceType := ServiceType::Invoice;
        NewRecordRef.SetTable(ServiceInvoiceHeader);
        if ServiceInvoiceHeader."No." = '' then
            Error(SpecifyASalesInvoiceNoErr);

        DocumentNo := ServiceInvoiceHeader."No.";
        ServiceInvoiceHeader.SetRecFilter();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");

        if ServiceInvoiceLine.FindSet() then
            repeat
                SalesLine.TransferFields(ServiceInvoiceLine);
                SalesLine.Type := PEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);

                PEPPOLMonetaryInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Service";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
            until ServiceInvoiceLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            ServiceInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

        DocumentAttachments.SetRange("Table ID", Database::"Service Invoice Header");
        DocumentAttachments.SetRange("No.", ServiceInvoiceHeader."No.");
    end;

    local procedure InitCreditMemo(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLManagement: Codeunit "PEPPOL30 Management";
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
    begin
        ServiceType := ServiceType::CreditMemo;
        NewRecordRef.SetTable(ServiceCrMemoHeader);
        if ServiceCrMemoHeader."No." = '' then
            Error(SpecifyASalesCreditMemoNoErr);

        DocumentNo := ServiceCrMemoHeader."No.";
        ServiceCrMemoHeader.SetRecFilter();
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");

        if ServiceCrMemoLine.FindSet() then
            repeat
                SalesLine.TransferFields(ServiceCrMemoLine);
                SalesLine.Type := PEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);

                PEPPOLMonetaryInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Service";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
            until ServiceCrMemoLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            ServiceCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

        DocumentAttachments.SetRange("Table ID", Database::"Service Cr.Memo Header");
        DocumentAttachments.SetRange("No.", ServiceCrMemoHeader."No.");
    end;

    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format") Found: Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        case ServiceType of
            ServiceType::Invoice:
                exit(PEPPOLPostedDocumentIterator.FindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position));
            ServiceType::CreditMemo:
                exit(PEPPOLPostedDocumentIterator.FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position));
        end;
    end;

    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format"): Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        case ServiceType of
            ServiceType::Invoice:
                exit(PEPPOLPostedDocumentIterator.FindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Position));
            ServiceType::CreditMemo:
                exit(PEPPOLPostedDocumentIterator.FindNextServiceCreditMemoLineRec(ServiceCrMemoLine, SalesLine, Position));
        end;
    end;

#if not CLEAN25
#pragma warning disable AL0432
#endif
    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
#if not CLEAN25
#pragma warning restore AL0432
#endif
    var
        PEPPOL30Management: Codeunit "PEPPOL30 Management";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        case ServiceType of
            ServiceType::Invoice:
                begin
                    ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(ServiceInvoiceLine);
                            SalesLine.Type := PEPPOL30Management.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                            PEPPOLTaxInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales";
                            PEPPOLTaxInfoProvider.GetTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until ServiceInvoiceLine.Next() = 0;
                end;
            ServiceType::CreditMemo:
                begin
                    ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            SalesLine.TransferFields(ServiceCrMemoLine);
                            SalesLine.Type := PEPPOL30Management.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                            PEPPOLTaxInfoProvider := "PEPPOL 3.0 Format"::"PEPPOL 3.0 - Sales";
                            PEPPOLTaxInfoProvider.GetTotals(SalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                        until ServiceCrMemoLine.Next() = 0;
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