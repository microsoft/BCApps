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

codeunit 37214 "PEPPOL30 Services Export Mgmt." implements "PEPPOL30 Export Management", "PEPPOL Posted Document Iterator"
{

    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GlobalSalesHeader: Record "Sales Header";
        GlobalSalesLine: Record "Sales Line";
        GlobalPostedDocumentHeader, GlobalPostedDocumentLine : RecordRef;
        Peppol30: Codeunit "PEPPOL30";
        PEPPOL30Setup: Record "PEPPOL 3.0 Setup";
        DocumentNo: Code[20];
        UnsupportedDocumentErr: Label 'The service document type is not supported for PEPPOL 3.0 export.';

    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    begin
        PEPPOL30Setup.GetSetup();
        case NewRecordRef.Number() of
            Database::"Service Cr.Memo Header":
                InitCreditMemo(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
            Database::"Service Invoice Header":
                InitSalesInvoice(NewRecordRef, TempSalesLineRounding, DocumentAttachments);
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    local procedure InitSalesInvoice(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        PEPPOLManagement: Codeunit "PEPPOL30";
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesInvoiceNoErr: Label 'You must specify a sales invoice number.';
    begin
        NewRecordRef.SetTable(ServiceInvoiceHeader);
        if ServiceInvoiceHeader."No." = '' then
            Error(SpecifyASalesInvoiceNoErr);

        DocumentNo := ServiceInvoiceHeader."No.";
        ServiceInvoiceHeader.SetRecFilter();
        GlobalPostedDocumentHeader.GetTable(ServiceInvoiceHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");

        if ServiceInvoiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, GlobalSalesLine);
                GlobalSalesLine.Type := PEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);

                PEPPOLMonetaryInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Service Format";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, GlobalSalesLine);
            until ServiceInvoiceLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            ServiceInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
        GlobalPostedDocumentLine.GetTable(ServiceInvoiceLine);
        DocumentAttachments.SetRange("Table ID", Database::"Service Invoice Header");
        DocumentAttachments.SetRange("No.", ServiceInvoiceHeader."No.");
    end;

    local procedure InitCreditMemo(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        PEPPOLManagement: Codeunit "PEPPOL30";
        PEPPOLMonetaryInfoProvider: Interface "PEPPOL Monetary Info Provider";
        SpecifyASalesCreditMemoNoErr: Label 'You must specify a sales credit memo number.';
    begin
        NewRecordRef.SetTable(ServiceCrMemoHeader);
        if ServiceCrMemoHeader."No." = '' then
            Error(SpecifyASalesCreditMemoNoErr);

        DocumentNo := ServiceCrMemoHeader."No.";
        ServiceCrMemoHeader.SetRecFilter();
        GlobalPostedDocumentHeader.GetTable(ServiceCrMemoHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");

        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, GlobalSalesLine);
                GlobalSalesLine.Type := PEPPOLManagement.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);

                PEPPOLMonetaryInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Service Format";
                PEPPOLMonetaryInfoProvider.GetInvoiceRoundingLine(TempSalesLineRounding, GlobalSalesLine);
            until ServiceCrMemoLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            ServiceCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");
        GlobalPostedDocumentLine.GetTable(ServiceCrMemoLine);
        DocumentAttachments.SetRange("Table ID", Database::"Service Cr.Memo Header");
        DocumentAttachments.SetRange("No.", ServiceCrMemoHeader."No.");
    end;

    // TODO:FIX
    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format") Found: Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextPostedRec(GlobalPostedDocumentHeader, GlobalSalesHeader, Position));
    end;

    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "PEPPOL 3.0 Format"): Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextPostedLineRec(GlobalPostedDocumentLine, GlobalSalesLine, Position));
    end;

#if not CLEAN25
#pragma warning disable AL0432
#endif
    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
#if not CLEAN25
#pragma warning restore AL0432
#endif
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
        PEPPOLTaxInfoProvider: Interface "PEPPOL Tax Info Provider";
    begin
        case GlobalPostedDocumentHeader.Number() of
            Database::"Service Invoice Header":
                begin
                    GlobalPostedDocumentLine.SetTable(ServiceInvoiceLine);
                    ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            GlobalSalesLine.TransferFields(ServiceInvoiceLine);
                            GlobalSalesLine.Type := PEPPOL30Management.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                            PEPPOLTaxInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Service Format";
                            PEPPOLTaxInfoProvider.GetTotals(GlobalSalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(GlobalSalesLine, TempVATProductPostingGroup);
                        until ServiceInvoiceLine.Next() = 0;
                end;
            Database::"Service Cr.Memo Header":
                begin
                    GlobalPostedDocumentLine.SetTable(ServiceInvoiceLine);
                    ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
                    if ServiceCrMemoLine.FindSet() then
                        repeat
                            GlobalSalesLine.TransferFields(ServiceCrMemoLine);
                            GlobalSalesLine.Type := PEPPOL30Management.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                            PEPPOLTaxInfoProvider := PEPPOL30Setup."PEPPOL 3.0 Service Format";
                            PEPPOLTaxInfoProvider.GetTotals(GlobalSalesLine, TempVATAmtLine);
                            PEPPOLTaxInfoProvider.GetTaxCategories(GlobalSalesLine, TempVATProductPostingGroup);
                        until ServiceCrMemoLine.Next() = 0;
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
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        if Position = 1 then
            Found := PostedRec.Find('-')
        else
            Found := PostedRec.Next() <> 0;

        if Found then begin

            case PostedRec.Number() of
                Database::"Service Invoice Header":
                    begin
                        PostedRec.SetTable(ServiceInvoiceHeader);
                        Peppol30.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
                        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                    end;
                Database::"Service Cr.Memo Header":
                    begin
                        PostedRec.SetTable(ServiceCrMemoHeader);
                        Peppol30.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
                        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    end;
                else
                    Error(UnsupportedDocumentErr);
            end;
        end;
        exit(Found);
    end;

    procedure FindNextPostedLineRec(var PostedRecLine: RecordRef; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        if Position = 1 then
            Found := PostedRecLine.Find('-')
        else
            Found := PostedRecLine.Next() <> 0;

        if Found then begin
            case PostedRecLine.Number() of
                Database::"Service Invoice Header":
                    begin
                        PostedRecLine.SetTable(ServiceInvoiceLine);
                        Peppol30.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                        SalesLine.Type := Peppol30.MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                    end;
                Database::"Service Cr.Memo Header":
                    begin
                        PostedRecLine.SetTable(ServiceCrMemoLine);
                        Peppol30.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                        SalesLine.Type := Peppol30.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                        SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                    end;
                else
                    Error(UnsupportedDocumentErr);
            end;
        end;
        exit(Found);
    end;

}