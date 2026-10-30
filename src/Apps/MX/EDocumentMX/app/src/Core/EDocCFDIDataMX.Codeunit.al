// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Inventory.Transfer;
using Microsoft.Sales.History;
using Microsoft.eServices.EDocument;

codeunit 3373 "EDoc CFDI Data MX"
{
    Access = Internal;

    procedure IsSupportedSource(EDocument: Record "E-Document"): Boolean
    begin
        if EDocument.Direction <> EDocument.Direction::Outgoing then
            exit(false);
        exit(EDocument."Document Record ID".TableNo() in [
            Database::"Sales Invoice Header",
            Database::"Sales Cr.Memo Header",
            Database::"Sales Shipment Header",
            Database::"Transfer Shipment Header"]);
    end;

    procedure IsCartaPorte(EDocument: Record "E-Document"): Boolean
    begin
        exit(EDocument."Document Record ID".TableNo() in [Database::"Sales Shipment Header", Database::"Transfer Shipment Header"]);
    end;

    procedure GetFieldVisibility(EDocument: Record "E-Document"; var CartaPorteVisible: Boolean; var SATAddressVisible: Boolean; var CertificateOfOriginVisible: Boolean)
    begin
        CartaPorteVisible := IsCartaPorte(EDocument);
        SATAddressVisible := EDocument."Document Record ID".TableNo() <> Database::"Transfer Shipment Header";
        CertificateOfOriginVisible := not CartaPorteVisible;
    end;

    procedure GetSourceCountryCodes(EDocument: Record "E-Document"; var ShipToCountryCode: Code[10]; var BillToCountryCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        ShipToCountryCode := '';
        BillToCountryCode := '';
        case EDocument."Document Record ID".TableNo() of
            Database::"Sales Invoice Header":
                if SalesInvoiceHeader.Get(EDocument."Document Record ID") then begin
                    ShipToCountryCode := SalesInvoiceHeader."Ship-to Country/Region Code";
                    BillToCountryCode := SalesInvoiceHeader."Bill-to Country/Region Code";
                end;
            Database::"Sales Cr.Memo Header":
                if SalesCrMemoHeader.Get(EDocument."Document Record ID") then begin
                    ShipToCountryCode := SalesCrMemoHeader."Ship-to Country/Region Code";
                    BillToCountryCode := SalesCrMemoHeader."Bill-to Country/Region Code";
                end;
            Database::"Sales Shipment Header":
                if SalesShipmentHeader.Get(EDocument."Document Record ID") then begin
                    ShipToCountryCode := SalesShipmentHeader."Ship-to Country/Region Code";
                    BillToCountryCode := SalesShipmentHeader."Bill-to Country/Region Code";
                end;
        end;
    end;

    procedure IsEditable(EDocument: Record "E-Document"): Boolean
    var
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
    begin
        if not IsSupportedSource(EDocument) then
            exit(false);
        exit(CFDIWriteBackMX.GetUUIDForDocument(EDocument."Document Record ID") = '');
    end;

    procedure OpenTransportOperators(EDocument: Record "E-Document")
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
        CFDITransportOperators: Page "CFDI Transport Operators";
    begin
        CFDITransportOperator.SetRange("Document Table ID", Database::"E-Document");
        CFDITransportOperator.SetRange("Document No.", GetTransportOperatorDocumentNo(EDocument));
        CFDITransportOperators.SetTableView(CFDITransportOperator);
        CFDITransportOperators.Editable(IsEditable(EDocument));
        CFDITransportOperators.RunModal();
    end;

    procedure GetTransportOperatorDocumentNo(EDocument: Record "E-Document"): Code[20]
    begin
        exit(CopyStr(Format(EDocument."Entry No", 0, 9), 1, 20));
    end;

    procedure CountTransportOperators(EDocument: Record "E-Document"): Integer
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
    begin
        CFDITransportOperator.SetRange("Document Table ID", Database::"E-Document");
        CFDITransportOperator.SetRange("Document No.", GetTransportOperatorDocumentNo(EDocument));
        exit(CFDITransportOperator.Count());
    end;

    local procedure CopyFromSourceDocument(var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        case SourceDocumentHeader.Number of
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    EDocument."CFDI Export Code" := SalesInvoiceHeader."CFDI Export Code";
                    EDocument."CFDI Exchange Rate USD" := SalesInvoiceHeader."Exchange Rate USD";
                    EDocument."CFDI Foreign Trade" := SalesInvoiceHeader."Foreign Trade";
                    EDocument."CFDI SAT Address ID" := SalesInvoiceHeader."SAT Address ID";
                    EDocument."CFDI Intl. Trade Term" := SalesInvoiceHeader."SAT International Trade Term";
                    EDocument."CFDI Cert. of Origin No." := SalesInvoiceHeader."CFDI Certificate of Origin No.";
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    EDocument."CFDI Export Code" := SalesCrMemoHeader."CFDI Export Code";
                    EDocument."CFDI Exchange Rate USD" := SalesCrMemoHeader."Exchange Rate USD";
                    EDocument."CFDI Foreign Trade" := SalesCrMemoHeader."Foreign Trade";
                    EDocument."CFDI SAT Address ID" := SalesCrMemoHeader."SAT Address ID";
                    EDocument."CFDI Intl. Trade Term" := SalesCrMemoHeader."SAT International Trade Term";
                    EDocument."CFDI Cert. of Origin No." := SalesCrMemoHeader."CFDI Certificate of Origin No.";
                end;
            Database::"Sales Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(SalesShipmentHeader);
                    EDocument."CFDI Export Code" := SalesShipmentHeader."CFDI Export Code";
                    EDocument."CFDI Exchange Rate USD" := SalesShipmentHeader."Exchange Rate USD";
                    EDocument."CFDI Foreign Trade" := SalesShipmentHeader."Foreign Trade";
                    EDocument."CFDI SAT Address ID" := SalesShipmentHeader."SAT Address ID";
                    EDocument."CFDI Intl. Trade Term" := SalesShipmentHeader."SAT International Trade Term";
                    EDocument."CFDI Transport Type" := SalesShipmentHeader."SAT Transport Type";
                    EDocument."CFDI Transit-from Date/Time" := SalesShipmentHeader."Transit-from Date/Time";
                    EDocument."CFDI Transit Hours" := SalesShipmentHeader."Transit Hours";
                    EDocument."CFDI Transit Distance" := SalesShipmentHeader."Transit Distance";
                    EDocument."CFDI Vehicle Code" := SalesShipmentHeader."Vehicle Code";
                    EDocument."CFDI Trailer 1" := SalesShipmentHeader."Trailer 1";
                    EDocument."CFDI Trailer 2" := SalesShipmentHeader."Trailer 2";
                    EDocument."CFDI Customs Regime" := SalesShipmentHeader."SAT Customs Regime";
                    EDocument."CFDI Transfer Reason" := SalesShipmentHeader."SAT Transfer Reason";
                    EDocument."CFDI SAT ISTMO" := SalesShipmentHeader."SAT ISTMO";
                    EDocument."CFDI ISTMO Polo Origen" := SalesShipmentHeader."SAT ISTMO Polo Origen";
                    EDocument."CFDI ISTMO Polo Destino" := SalesShipmentHeader."SAT ISTMO Polo Destino";
                    EDocument."CFDI Insurer Name" := SalesShipmentHeader."Insurer Name";
                    EDocument."CFDI Insurer Policy Number" := SalesShipmentHeader."Insurer Policy Number";
                    EDocument."CFDI Medical Insurer Name" := SalesShipmentHeader."Medical Insurer Name";
                    EDocument."CFDI Medical Ins. Policy No." := SalesShipmentHeader."Medical Ins. Policy Number";
                    EDocument."CFDI Weight Unit Of Measure" := SalesShipmentHeader."SAT Weight Unit Of Measure";
                    CopyTransportOperators(EDocument, Database::"Sales Shipment Header", SalesShipmentHeader."No.");
                end;
            Database::"Transfer Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(TransferShipmentHeader);
                    EDocument."CFDI Export Code" := TransferShipmentHeader."CFDI Export Code";
                    EDocument."CFDI Exchange Rate USD" := TransferShipmentHeader."Exchange Rate USD";
                    EDocument."CFDI Foreign Trade" := TransferShipmentHeader."Foreign Trade";
                    EDocument."CFDI Intl. Trade Term" := TransferShipmentHeader."SAT International Trade Term";
                    EDocument."CFDI Transport Type" := TransferShipmentHeader."SAT Transport Type";
                    EDocument."CFDI Transit-from Date/Time" := TransferShipmentHeader."Transit-from Date/Time";
                    EDocument."CFDI Transit Hours" := TransferShipmentHeader."Transit Hours";
                    EDocument."CFDI Transit Distance" := TransferShipmentHeader."Transit Distance";
                    EDocument."CFDI Vehicle Code" := TransferShipmentHeader."Vehicle Code";
                    EDocument."CFDI Trailer 1" := TransferShipmentHeader."Trailer 1";
                    EDocument."CFDI Trailer 2" := TransferShipmentHeader."Trailer 2";
                    EDocument."CFDI Customs Regime" := TransferShipmentHeader."SAT Customs Regime";
                    EDocument."CFDI Transfer Reason" := TransferShipmentHeader."SAT Transfer Reason";
                    EDocument."CFDI SAT ISTMO" := TransferShipmentHeader."SAT ISTMO";
                    EDocument."CFDI ISTMO Polo Origen" := TransferShipmentHeader."SAT ISTMO Polo Origen";
                    EDocument."CFDI ISTMO Polo Destino" := TransferShipmentHeader."SAT ISTMO Polo Destino";
                    EDocument."CFDI Insurer Name" := TransferShipmentHeader."Insurer Name";
                    EDocument."CFDI Insurer Policy Number" := TransferShipmentHeader."Insurer Policy Number";
                    EDocument."CFDI Medical Insurer Name" := TransferShipmentHeader."Medical Insurer Name";
                    EDocument."CFDI Medical Ins. Policy No." := TransferShipmentHeader."Medical Ins. Policy Number";
                    EDocument."CFDI Weight Unit Of Measure" := TransferShipmentHeader."SAT Weight Unit Of Measure";
                    CopyTransportOperators(EDocument, Database::"Transfer Shipment Header", TransferShipmentHeader."No.");
                end;
            else
                exit;
        end;
    end;

    local procedure CopyTransportOperators(EDocument: Record "E-Document"; SourceTableID: Integer; SourceDocumentNo: Code[20])
    var
        SourceTransportOperator: Record "CFDI Transport Operator";
        CFDITransportOperator: Record "CFDI Transport Operator";
    begin
        SourceTransportOperator.SetRange("Document Table ID", SourceTableID);
        SourceTransportOperator.SetRange("Document No.", SourceDocumentNo);
        if SourceTransportOperator.FindSet() then
            repeat
                CFDITransportOperator := SourceTransportOperator;
                CFDITransportOperator."Document Table ID" := Database::"E-Document";
                CFDITransportOperator."Document No." := GetTransportOperatorDocumentNo(EDocument);
                if CFDITransportOperator.Insert() then;
            until SourceTransportOperator.Next() = 0;
    end;

    procedure ApplyToDocument(EDocument: Record "E-Document"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if EDocument."Document Record ID" <> SalesInvoiceHeader.RecordId() then
            exit;
        SalesInvoiceHeader."CFDI Export Code" := EDocument."CFDI Export Code";
        SalesInvoiceHeader."Exchange Rate USD" := EDocument."CFDI Exchange Rate USD";
        SalesInvoiceHeader."Foreign Trade" := EDocument."CFDI Foreign Trade";
        SalesInvoiceHeader."SAT Address ID" := EDocument."CFDI SAT Address ID";
        SalesInvoiceHeader."SAT International Trade Term" := EDocument."CFDI Intl. Trade Term";
        SalesInvoiceHeader."CFDI Certificate of Origin No." := EDocument."CFDI Cert. of Origin No.";
    end;

    procedure ApplyToDocument(EDocument: Record "E-Document"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        if EDocument."Document Record ID" <> SalesCrMemoHeader.RecordId() then
            exit;
        SalesCrMemoHeader."CFDI Export Code" := EDocument."CFDI Export Code";
        SalesCrMemoHeader."Exchange Rate USD" := EDocument."CFDI Exchange Rate USD";
        SalesCrMemoHeader."Foreign Trade" := EDocument."CFDI Foreign Trade";
        SalesCrMemoHeader."SAT Address ID" := EDocument."CFDI SAT Address ID";
        SalesCrMemoHeader."SAT International Trade Term" := EDocument."CFDI Intl. Trade Term";
        SalesCrMemoHeader."CFDI Certificate of Origin No." := EDocument."CFDI Cert. of Origin No.";
    end;

    procedure ApplyToDocument(EDocument: Record "E-Document"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        if EDocument."Document Record ID" <> SalesShipmentHeader.RecordId() then
            exit;
        SalesShipmentHeader."CFDI Export Code" := EDocument."CFDI Export Code";
        SalesShipmentHeader."Exchange Rate USD" := EDocument."CFDI Exchange Rate USD";
        SalesShipmentHeader."Foreign Trade" := EDocument."CFDI Foreign Trade";
        SalesShipmentHeader."SAT Address ID" := EDocument."CFDI SAT Address ID";
        SalesShipmentHeader."SAT International Trade Term" := EDocument."CFDI Intl. Trade Term";
        SalesShipmentHeader."SAT Transport Type" := EDocument."CFDI Transport Type";
        SalesShipmentHeader."Transit-from Date/Time" := EDocument."CFDI Transit-from Date/Time";
        SalesShipmentHeader."Transit Hours" := EDocument."CFDI Transit Hours";
        SalesShipmentHeader."Transit Distance" := EDocument."CFDI Transit Distance";
        SalesShipmentHeader."Vehicle Code" := EDocument."CFDI Vehicle Code";
        SalesShipmentHeader."Trailer 1" := EDocument."CFDI Trailer 1";
        SalesShipmentHeader."Trailer 2" := EDocument."CFDI Trailer 2";
        SalesShipmentHeader."SAT Customs Regime" := EDocument."CFDI Customs Regime";
        SalesShipmentHeader."SAT Transfer Reason" := EDocument."CFDI Transfer Reason";
        SalesShipmentHeader."SAT ISTMO" := EDocument."CFDI SAT ISTMO";
        SalesShipmentHeader."SAT ISTMO Polo Origen" := EDocument."CFDI ISTMO Polo Origen";
        SalesShipmentHeader."SAT ISTMO Polo Destino" := EDocument."CFDI ISTMO Polo Destino";
        SalesShipmentHeader."Insurer Name" := EDocument."CFDI Insurer Name";
        SalesShipmentHeader."Insurer Policy Number" := EDocument."CFDI Insurer Policy Number";
        SalesShipmentHeader."Medical Insurer Name" := EDocument."CFDI Medical Insurer Name";
        SalesShipmentHeader."Medical Ins. Policy Number" := EDocument."CFDI Medical Ins. Policy No.";
        SalesShipmentHeader."SAT Weight Unit Of Measure" := EDocument."CFDI Weight Unit Of Measure";
    end;

    procedure ApplyToDocument(EDocument: Record "E-Document"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        if EDocument."Document Record ID" <> TransferShipmentHeader.RecordId() then
            exit;
        TransferShipmentHeader."CFDI Export Code" := EDocument."CFDI Export Code";
        TransferShipmentHeader."Exchange Rate USD" := EDocument."CFDI Exchange Rate USD";
        TransferShipmentHeader."Foreign Trade" := EDocument."CFDI Foreign Trade";
        TransferShipmentHeader."SAT International Trade Term" := EDocument."CFDI Intl. Trade Term";
        TransferShipmentHeader."SAT Transport Type" := EDocument."CFDI Transport Type";
        TransferShipmentHeader."Transit-from Date/Time" := EDocument."CFDI Transit-from Date/Time";
        TransferShipmentHeader."Transit Hours" := EDocument."CFDI Transit Hours";
        TransferShipmentHeader."Transit Distance" := EDocument."CFDI Transit Distance";
        TransferShipmentHeader."Vehicle Code" := EDocument."CFDI Vehicle Code";
        TransferShipmentHeader."Trailer 1" := EDocument."CFDI Trailer 1";
        TransferShipmentHeader."Trailer 2" := EDocument."CFDI Trailer 2";
        TransferShipmentHeader."SAT Customs Regime" := EDocument."CFDI Customs Regime";
        TransferShipmentHeader."SAT Transfer Reason" := EDocument."CFDI Transfer Reason";
        TransferShipmentHeader."SAT ISTMO" := EDocument."CFDI SAT ISTMO";
        TransferShipmentHeader."SAT ISTMO Polo Origen" := EDocument."CFDI ISTMO Polo Origen";
        TransferShipmentHeader."SAT ISTMO Polo Destino" := EDocument."CFDI ISTMO Polo Destino";
        TransferShipmentHeader."Insurer Name" := EDocument."CFDI Insurer Name";
        TransferShipmentHeader."Insurer Policy Number" := EDocument."CFDI Insurer Policy Number";
        TransferShipmentHeader."Medical Insurer Name" := EDocument."CFDI Medical Insurer Name";
        TransferShipmentHeader."Medical Ins. Policy Number" := EDocument."CFDI Medical Ins. Policy No.";
        TransferShipmentHeader."SAT Weight Unit Of Measure" := EDocument."CFDI Weight Unit Of Measure";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Export", 'OnAfterCreateEDocument', '', false, false)]
    local procedure OnAfterCreateEDocument(var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef)
    begin
        if not IsSupportedSource(EDocument) then
            exit;
        CopyFromSourceDocument(EDocument, SourceDocumentHeader);
        EDocument.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"E-Document", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteEDocument(var Rec: Record "E-Document"; RunTrigger: Boolean)
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
    begin
        if Rec.IsTemporary() then
            exit;
        CFDITransportOperator.SetRange("Document Table ID", Database::"E-Document");
        CFDITransportOperator.SetRange("Document No.", GetTransportOperatorDocumentNo(Rec));
        if not CFDITransportOperator.IsEmpty() then
            CFDITransportOperator.DeleteAll();
    end;
}
