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

codeunit 37214 "Services Export PEPPOL30 Mgmt." implements "PEPPOL30 Export Management"
{
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";

    procedure Init(NewRecordRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment")
    var
        PEPPOLManagement: Codeunit "PEPPOL30 Management";
        ServPEPPOL30Management: Codeunit "Serv. PEPPOL30 Management";
        SpecifyAServCreditMemoNoErr: Label 'Specify a Serv. Credit Memo No.';
    begin
        NewRecordRef.SetTable(ServiceCrMemoHeader);
        if ServiceCrMemoHeader."No." = '' then
            Error(SpecifyAServCreditMemoNoErr);
        ServiceCrMemoHeader.SetRecFilter();
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                SalesLine.Type := ServPEPPOL30Management.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                PEPPOLManagement.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
            until ServiceCrMemoLine.Next() = 0;
        if TempSalesLineRounding."Line No." <> 0 then
            ServiceCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

        DocumentAttachments.SetRange("Table ID", Database::"Service Cr.Memo Header");
        DocumentAttachments.SetRange("No.", ServiceCrMemoHeader."No.");
    end;

    procedure FindNextRec(Position: Integer; EDocumentFormat: Enum "E-Document Format") Found: Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position));
    end;

    procedure FindNextLineRec(Position: Integer; EDocumentFormat: Enum "E-Document Format"): Boolean
    var
        PEPPOLPostedDocumentIterator: Interface "PEPPOL Posted Document Iterator";
    begin
        PEPPOLPostedDocumentIterator := EDocumentFormat;
        exit(PEPPOLPostedDocumentIterator.FindNextServiceCreditMemoLineRec(ServiceCrMemoLine, SalesLine, Position));
    end;

    procedure GetTotals(var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary);
    var
        PEPPOL30Management: Codeunit "PEPPOL30 Management";
        ServPEPPOL30Management: Codeunit "Serv. PEPPOL30 Management";
    begin
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOL30Management.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                SalesLine.Type := ServPEPPOL30Management.MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                PEPPOL30Management.GetTotals(SalesLine, TempVATAmtLine);
            until ServiceCrMemoLine.Next() = 0;
    end;
}