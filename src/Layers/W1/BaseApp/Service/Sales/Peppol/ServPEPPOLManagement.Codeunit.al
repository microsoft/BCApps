// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Service.History;
using Microsoft.Foundation.Attachment;
using Microsoft.Finance.VAT.Calculation;

codeunit 6458 "Serv. PEPPOL Management"
{
    SingleInstance = true;

    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        PEPPOLManagement: Codeunit "PEPPOL Management";

        SpecifyAServCreditMemoNoErr: Label 'You must specify a service credit memo number.';
        SpecifyAServInvoiceNoErr: Label 'You must specify a service invoice number.';

    procedure FindNextServiceInvoiceRec(var ServiceInvoiceHeader: Record "Service Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceInvoiceHeader.Find('-')
        else
            Found := ServiceInvoiceHeader.Next() <> 0;
        if Found then
            PEPPOLManagement.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;

        OnAfterFindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position, Found);
    end;

    procedure FindNextServiceInvoiceLineRec(var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    var
        Found: Boolean;
    begin
        if Position = 1 then
            Found := ServiceInvoiceLine.Find('-')
        else
            Found := ServiceInvoiceLine.Next() <> 0;
        if Found then begin
            PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
            SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
        end;
        OnAfterFindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Found);
        exit(Found);
    end;

    procedure FindNextServiceCreditMemoRec(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceCrMemoHeader.Find('-')
        else
            Found := ServiceCrMemoHeader.Next() <> 0;
        if Found then
            PEPPOLManagement.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);

        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";

        OnAfterFindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position, Found);
    end;

    procedure MapServiceLineTypeToSalesLineType(ServiceLineType: Enum "Service Line Type"): Enum "Sales Line Type"
    begin
        case ServiceLineType of
            "Service Line Type"::" ":
                exit("Sales Line Type"::" ");
            "Service Line Type"::Item:
                exit("Sales Line Type"::Item);
            "Service Line Type"::Resource:
                exit("Sales Line Type"::Resource);
            else
                exit("Sales Line Type"::"G/L Account");
        end;
    end;

    procedure FindNextServiceCreditMemoLineRec(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceCrMemoLine.Find('-')
        else
            Found := ServiceCrMemoLine.Next() <> 0;
        if Found then begin
            PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
            SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
        end;

        OnAfterFindNextServiceCrMemoLineRec(ServiceCrMemoLine, SalesLine, Found);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextServiceInvoiceRec(var ServiceInvoiceHeader: Record "Service Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextServiceInvoiceLineRec(var ServiceInvoiceLine: Record "Service Invoice Line"; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextServiceCreditMemoRec(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindNextServiceCrMemoLineRec(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
    end;

#if not CLEAN26 
#pragma warning disable AL0432
    // XML Port "Sales Credit Memo - PEPPOL 2.0"

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnInitialize', '', false, false)]
    local procedure CreditMemoPEPPOL20_OnInitializeOnSetSourceDocument(SourceRecRef: RecordRef; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean)
    begin
        if SourceRecRef.Number = DATABASE::"Service Cr.Memo Header" then begin
            SourceRecRef.SetTable(ServiceCrMemoHeader);
            if ServiceCrMemoHeader."No." = '' then
                Error(SpecifyAServCreditMemoNoErr);
            ServiceCrMemoHeader.SetRecFilter();
            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            ProcessedDocType := ProcessedDocType::Service;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnFindNextCreditMemoRec', '', false, false)]
    local procedure CreditMemoPEPPOL20_OnFindNextCreditMemoRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
        Found := FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnFindNextCreditMemoLineRec', '', false, false)]
    local procedure CreditMemoPEPPOL20_OnFindNextCreditMemoLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
        Found := FindNextServiceCreditMemoLineRec(ServiceCrMemoLine, SalesLine, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnGetTotals', '', false, false)]
    local procedure CreditMemoPEPPOL20_OnGetTotals(var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
        if ProcessedDocType = ProcessedDocType::Service then begin
            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            if ServiceCrMemoLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                    PEPPOLManagement.GetTotals(SalesLine, TempVATAmtLine);
                until ServiceCrMemoLine.Next() = 0;
        end;
    end;
#pragma warning restore AL0432    
#endif 

#if not CLEAN26 
#pragma warning disable AL0432
    // XML Port "Sales Credit Memo - PEPPOL 2.1"

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnInitialize', '', false, false)]
    local procedure CreditMemoPEPPOL21_OnInitializeOnSetSourceDocument(SourceRecRef: RecordRef; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean)
    begin
        if SourceRecRef.Number = DATABASE::"Service Cr.Memo Header" then begin
            SourceRecRef.SetTable(ServiceCrMemoHeader);
            if ServiceCrMemoHeader."No." = '' then
                Error(SpecifyAServCreditMemoNoErr);
            ServiceCrMemoHeader.SetRecFilter();
            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            ProcessedDocType := ProcessedDocType::Service;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnFindNextCreditMemoRec', '', false, false)]
    local procedure CreditMemoPEPPOL21_OnFindNextCreditMemoRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
        Found := FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnFindNextCreditMemoLineRec', '', false, false)]
    local procedure CreditMemoPEPPOL21_OnFindNextCreditMemoLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
        Found := FindNextServiceCreditMemoLineRec(ServiceCrMemoLine, SalesLine, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Credit Memo - PEPPOL 2.0", 'OnGetTotals', '', false, false)]
    local procedure CreditMemoPEPPOL21_OnGetTotals(var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
        if ProcessedDocType = ProcessedDocType::Service then begin
            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            if ServiceCrMemoLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                    PEPPOLManagement.GetTotals(SalesLine, TempVATAmtLine);
                until ServiceCrMemoLine.Next() = 0;
        end;
    end;
#pragma warning restore AL0432    
#endif

    // XML Port "Sales Cr.Memo - PEPPOL BIS 3.0"

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Cr.Memo - PEPPOL BIS 3.0", 'OnInitialize', '', false, false)]
    local procedure CreditMemoPEPPOLBIS30_OnInitialize(SourceRecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment"; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if SourceRecRef.Number = Database::"Service Cr.Memo Header" then begin
            SourceRecRef.SetTable(ServiceCrMemoHeader);
            if ServiceCrMemoHeader."No." = '' then
                Error(SpecifyAServCreditMemoNoErr);
            ServiceCrMemoHeader.SetRecFilter();
            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            ServiceCrMemoLine.SetFilter(Type, '<>%1', ServiceCrMemoLine.Type::" ");
            OnBeforeFindServiceCrMemoLine(ServiceCrMemoLine);
            if ServiceCrMemoLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                    PEPPOLManagement.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                until ServiceCrMemoLine.Next() = 0;
            if TempSalesLineRounding."Line No." <> 0 then
                ServiceCrMemoLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

            DocumentAttachments.SetRange("Table ID", Database::"Service Cr.Memo Header");
            DocumentAttachments.SetRange("No.", ServiceCrMemoHeader."No.");

            ProcessedDocType := ProcessedDocType::Service;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Cr.Memo - PEPPOL BIS 3.0", 'OnFindNextCreditMemoRec', '', false, false)]
    local procedure CreditMemoPEPPOLBIS30_OnFindNextCreditMemoRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
        Found := FindNextServiceCreditMemoRec(ServiceCrMemoHeader, SalesHeader, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Cr.Memo - PEPPOL BIS 3.0", 'OnFindNextCreditMemoLineRec', '', false, false)]
    local procedure CreditMemoPEPPOLBIS30_OnFindNextCreditMemoLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
        Found := FindNextServiceCreditMemoLineRec(ServiceCrMemoLine, SalesLine, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Cr.Memo - PEPPOL BIS 3.0", 'OnGetTotals', '', false, false)]
    local procedure CreditMemoPEPPOLBIS30_OnGetTotals(var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
        if ProcessedDocType = ProcessedDocType::Service then begin
            ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
            if ServiceCrMemoLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
                    PEPPOLManagement.GetTotals(SalesLine, TempVATAmtLine);
                    PEPPOLManagement.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                until ServiceCrMemoLine.Next() = 0;
        end;
    end;

#if not CLEAN26 
#pragma warning disable AL0432
    // XML Port "Sales Invoice Memo - PEPPOL 2.0"

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.0", 'OnInitialize', '', false, false)]
    local procedure InvoicePEPPOL20_OnInitializeOnSetSourceDocument(SourceRecRef: RecordRef; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean)
    begin
        if SourceRecRef.Number = DATABASE::"Service Invoice Header" then begin
            SourceRecRef.SetTable(ServiceInvoiceHeader);
            if ServiceInvoiceHeader."No." = '' then
                Error(SpecifyAServInvoiceNoErr);
            ServiceInvoiceHeader.SetRecFilter();
            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
            ProcessedDocType := ProcessedDocType::Service;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.0", 'OnFindNextInvoiceRec', '', false, false)]
    local procedure InvoicePEPPOL20_OnFindNextInvoiceRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
        Found := FindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.0", 'OnFindNextInvoiceLineRec', '', false, false)]
    local procedure InvoicePEPPOL20_OnFindNextInvoiceLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
        Found := FindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.0", 'OnGetTotals', '', false, false)]
    local procedure InvoicePEPPOL20_OnGetTotals(var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
        if ProcessedDocType = ProcessedDocType::Service then begin
            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
            if ServiceInvoiceLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                    PEPPOLManagement.GetTotals(SalesLine, TempVATAmtLine);
                until ServiceInvoiceLine.Next() = 0;
        end;
    end;
#pragma warning restore AL0432    
#endif

#if not CLEAN26 
#pragma warning disable AL0432
    // XML Port "Sales Invoice Memo - PEPPOL 2.1"

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.1", 'OnInitialize', '', false, false)]
    local procedure InvoicePEPPOL21_OnInitializeOnSetSourceDocument(SourceRecRef: RecordRef; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean)
    begin
        if SourceRecRef.Number = DATABASE::"Service Invoice Header" then begin
            SourceRecRef.SetTable(ServiceInvoiceHeader);
            if ServiceInvoiceHeader."No." = '' then
                Error(SpecifyAServInvoiceNoErr);
            ServiceInvoiceHeader.SetRecFilter();
            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
            ProcessedDocType := ProcessedDocType::Service;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.1", 'OnFindNextInvoiceRec', '', false, false)]
    local procedure InvoicePEPPOL21_OnFindNextInvoiceRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
        Found := FindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.1", 'OnFindNextInvoiceLineRec', '', false, false)]
    local procedure InvoicePEPPOL21_OnFindNextInvoiceLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
        Found := FindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL 2.1", 'OnGetTotals', '', false, false)]
    local procedure InvoicePEPPOL21_OnGetTotals(var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
        if ProcessedDocType = ProcessedDocType::Service then begin
            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
            if ServiceInvoiceLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                    PEPPOLManagement.GetTotals(SalesLine, TempVATAmtLine);
                until ServiceInvoiceLine.Next() = 0;
        end;
    end;
#pragma warning restore AL0432    
#endif

    // XML Port "Sales Invoice - PEPPOL BIS 3.0"

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL BIS 3.0", 'OnInitialize', '', false, false)]
    local procedure InvoicePEPPOLBIS30_OnInitialize(SourceRecRef: RecordRef; var TempSalesLineRounding: Record "Sales Line" temporary; var DocumentAttachments: Record "Document Attachment"; var ProcessedDocType: Enum "PEPPOL Processing Type"; var IsHandled: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        if SourceRecRef.Number = Database::"Service Invoice Header" then begin
            SourceRecRef.SetTable(ServiceInvoiceHeader);
            if ServiceInvoiceHeader."No." = '' then
                Error(SpecifyAServInvoiceNoErr);
            ServiceInvoiceHeader.SetRecFilter();
            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
            ServiceInvoiceLine.SetFilter(Type, '<>%1', ServiceInvoiceLine.Type::" ");
            OnBeforeFindServiceInvoiceLine(ServiceInvoiceLine);
            if ServiceInvoiceLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                    PEPPOLManagement.GetInvoiceRoundingLine(TempSalesLineRounding, SalesLine);
                until ServiceInvoiceLine.Next() = 0;
            if TempSalesLineRounding."Line No." <> 0 then
                ServiceInvoiceLine.SetFilter("Line No.", '<>%1', TempSalesLineRounding."Line No.");

            DocumentAttachments.SetRange("Table ID", Database::"Service Invoice Header");
            DocumentAttachments.SetRange("No.", ServiceInvoiceHeader."No.");

            ProcessedDocType := ProcessedDocType::Service;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL BIS 3.0", 'OnFindNextInvoiceRec', '', false, false)]
    local procedure InvoicePEPPOLBIS30_OnFindNextInvoiceRec(Position: Integer; var SalesHeader: Record "Sales Header"; var Found: Boolean)
    begin
        Found := FindNextServiceInvoiceRec(ServiceInvoiceHeader, SalesHeader, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL BIS 3.0", 'OnFindNextInvoiceLineRec', '', false, false)]
    local procedure InvoicePEPPOLBIS30_OnFindNextInvoiceLineRec(Position: Integer; var SalesLine: Record "Sales Line"; var Found: Boolean)
    begin
        Found := FindNextServiceInvoiceLineRec(ServiceInvoiceLine, SalesLine, Position);
    end;

    [EventSubscriber(ObjectType::XmlPort, XmlPort::"Sales Invoice - PEPPOL BIS 3.0", 'OnGetTotals', '', false, false)]
    local procedure InvoicePEPPOLBIS30_OnGetTotals(var SalesLine: Record "Sales Line"; var TempVATAmtLine: Record "VAT Amount Line" temporary; var TempVATProductPostingGroup: Record "VAT Product Posting Group" temporary; ProcessedDocType: Enum "PEPPOL Processing Type")
    begin
        if ProcessedDocType = ProcessedDocType::Service then begin
            ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
            if ServiceInvoiceLine.FindSet() then
                repeat
                    PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                    SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
                    PEPPOLManagement.GetTotals(SalesLine, TempVATAmtLine);
                    PEPPOLManagement.GetTaxCategories(SalesLine, TempVATProductPostingGroup);
                until ServiceInvoiceLine.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceInvoiceLine(var SalesInvoiceLine: Record "Service Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindServiceCrMemoLine(var ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
    end;

}
