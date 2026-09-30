// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.History;
using System;
using System.Reflection;
using System.Utilities;

report 3367 "EDoc CFDI Carta Porte MX"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Report/ElectronicCartaPorteMX.rdlc';
    Caption = 'Electronic Carta Porte Mexico';
    Permissions = TableData "Sales Shipment Header" = rimd,
                  TableData "Sales Shipment Line" = rimd,
                  TableData "Transfer Shipment Header" = rimd,
                  TableData "Transfer Shipment Line" = rimd;

    dataset
    {
        dataitem("Document Header"; "Document Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            UseTemporary = true;
            column(DocumentNo; "No.")
            {
            }
            column(CompanyInformation_RFCNo_Caption; CompanyInformation_RFCNoLbl)
            {
            }
            column(CompanyInformation_RFCNo; CompanyInformation."RFC Number")
            {
            }
            column(CompanyInformation_SATPostalCode; CompanyInformation."SAT Postal Code")
            {
            }
            column(FiscalRegimeCaption; FiscalRegimeLbl)
            {
            }
            column(CompanyInformation_SATTaxRegime; CompanyInformation."SAT Tax Regime Classification" + ' - ' + SATTaxRegimeClassification)
            {
            }
            column(SCTPermissionNumber; FixedAssetVehicle."SCT Permission No.")
            {
            }
            column(TransferRFCNo; TransferRFCNoLbl)
            {
            }
            column(FolioText; TempSalesShipmentHeader."Fiscal Invoice Number PAC")
            {
            }
            column(CertificateSerialNo; TempSalesShipmentHeader."Certificate Serial No.")
            {
            }
            column(DateTimeStamped; TempSalesShipmentHeader."Date/Time Stamped")
            {
            }
            column(InsurerName; "Insurer Name")
            {
            }
            column(InsurerPolicyNumber; "Insurer Policy Number")
            {
            }
            column(StartDateTime; FormatDateTime("Transit-from Date/Time"))
            {
            }
            column(FinishDateTime; FormatDateTime("Transit-from Date/Time" + "Transit Hours" * 1000 * 60 * 60))
            {
            }
            column(TransitDistance; Format("Transit Distance") + 'km')
            {
            }
            column(LocationFromAddress; LocationFrom.GetSATAddress())
            {
            }
            column(LocationToAddress; LocationTo.GetSATAddress())
            {
            }
            column(IDUbicacionOrigen; LocationFrom."ID Ubicacion")
            {
            }
            column(IDUbicacionDestino; LocationTo."ID Ubicacion")
            {
            }
            column(VehicleLicencePlate; FixedAssetVehicle."Vehicle Licence Plate")
            {
            }
            column(SATFederalAutotransport; FixedAssetVehicle."SAT Federal Autotransport")
            {
            }
            column(VehicleYear; FixedAssetVehicle."Vehicle Year")
            {
            }
            column(Trailer1LicencePlate; FixedAssetTrailer1."Vehicle Licence Plate")
            {
            }
            column(Trailer1SATTrailerType; SATTrailerType1.Code + ' - ' + SATTrailerType1.Description)
            {
            }
            column(Trailer2LicencePlate; FixedAssetTrailer2."Vehicle Licence Plate")
            {
            }
            column(Trailer2SATTrailerType; SATTrailerType2.Code + ' - ' + SATTrailerType2.Description)
            {
            }
            column(FolioTextCaption; FolioTextCaptionLbl)
            {
            }
            column(SATTipoRelacion; SATTipoRelacion)
            {
            }
            column(SATFolioFiscal; SATFolioFiscal)
            {
            }
            column(TaxRegimeCaption; TaxRegimeLbl)
            {
            }
            column(DocumentFooter; DocumentFooterLbl)
            {
            }
            column(ClientCartaPorteCaption; ClientCartaPorteLbl)
            {
            }
            column(UsoCFDICaption; UsoCFDILbl)
            {
            }
            column(UsoCFDText; UsoCFDDescriptionLbl)
            {
            }
            column(TotalAmountText; TotalAmountLbl)
            {
            }
            column(OriginalStringBase64Text; OriginalStringBase64Text)
            {
            }
            column(DigitalSignatureBase64Text; DigitalSignatureBase64Text)
            {
            }
            column(DigitalSignaturePACBase64Text; DigitalSignaturePACBase64Text)
            {
            }
            column(Original_StringCaption; Original_StringCaptionLbl)
            {
            }
            column(Digital_StampCaptionSAT; Digital_StampCaptionSATLbl)
            {
            }
            column(Digital_StampCaption; Digital_StampCaptionLbl)
            {
            }
            dataitem("Document Line"; "Document Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");
                UseTemporary = true;
                column(Page_Caption; PageCaptionLbl)
                {
                }
                column(CurrReport_PAGENO; CurrReport.PageNo())
                {
                }
                column(DocumentLine_No; "No.")
                {
                }
                column(DocumentLine_LineNo; "Line No.")
                {
                }
                column(DocumentLine_Description; Description)
                {
                }
                column(ItemSATClassificationCode; SATClassification."SAT Classification")
                {
                }
                column(ItemSATClassificationDescription; SATClassification.Description)
                {
                }
                column(DocumentLine_UnitOfMeasure; "Unit of Measure")
                {
                }
                column(SATUOMDescription; SATUnitOfMeasure."SAT UofM Code" + ' - ' + SATUnitOfMeasure.Name)
                {
                }
                column(DocumentLine_Quantity; Quantity)
                {
                }
                column(GrossWeight; "Gross Weight")
                {
                }
                column(SATHazardousMaterial; Item."SAT Hazardous Material")
                {
                }
                column(SATPackagingType; SATPackagingType.Code + ' - ' + SATPackagingType.Description)
                {
                }
                column(MaterialPeligroso; MaterialPeligroso)
                {
                }
                column(Item_DescriptionCaption; ItemDescriptionCaptionLbl)
                {
                }
                column(UnitCaption; UnitCaptionLbl)
                {
                }
                column(QuantityCaption; QuantityCaptionLbl)
                {
                }
                column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                {
                }
                column(Total_PriceCaption; Total_PriceCaptionLbl)
                {
                }
                column(Subtotal_Caption; Subtotal_CaptionLbl)
                {
                }
                column(Total_Caption; Total_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Item.Get("No.");
                    SATClassification.Get(Item."SAT Item Classification");
                    UnitOfMeasure.Get("Unit of Measure Code");
                    SATUnitOfMeasure.Get(UnitOfMeasure."SAT UofM Classification");
                    if Item."SAT Hazardous Material" <> '' then begin
                        MaterialPeligroso := 'Sí';
                        SATPackagingType.Get(Item."SAT Packaging Type");
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    OriginalStringBase64Text := '';
                    DigitalSignatureBase64Text := '';
                    DigitalSignaturePACBase64Text := '';
                end;
            }
            dataitem(CFDITransportOperator; "CFDI Transport Operator")
            {
                DataItemLink = "Document Table ID" = field("Document Table ID"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Table ID", "Document Type", "Document No.", "Operator Code") where("Document Type" = const(Quote));
                column(OperatorCode; "Operator Code")
                {
                }
                column(OperatorRFC; Employee."RFC No.")
                {
                }
                column(OperatorLicense; Employee."License No.")
                {
                }
                column(OperatorName; Employee."Search Name")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Employee.Get("Operator Code");
                end;
            }
#pragma warning disable AL0589 // Accepted: renaming the data item or column would break the report layout.
            dataitem(QRCode; "Integer")
#pragma warning restore AL0589
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
#pragma warning disable AL0589 // Accepted: renaming the data item or column would break the report layout.
                column(QRCode; TempSalesShipmentHeader."QR Code")
#pragma warning restore AL0589
                {
                }
                column(QRCode_Number; Number)
                {
                }
            }

            trigger OnAfterGetRecord()
            var
                SalesShipmentHeader: Record "Sales Shipment Header";
                TransferShipmentHeader: Record "Transfer Shipment Header";
                Convert: DotNet Convert;
                Encoding: DotNet Encoding;
                InStreamStamp: InStream;
            begin
                case "Document Table ID" of
                    DATABASE::"Sales Shipment Header":
                        begin
                            SalesShipmentHeader.Get("No.");
                            SalesShipmentHeader.CalcFields("Original String", "Digital Stamp PAC", "Digital Stamp SAT", "QR Code");
                            Clear(OriginalStringTextUnbounded);
                            TempBlob.FromRecord(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Original String"));
                            Clear(InStreamStamp);
                            TempBlob.CreateInStream(InStreamStamp);
                            InStreamStamp.Read(OriginalStringTextUnbounded);
                            TempBlob.FromRecord(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Digital Stamp SAT"));
                            Clear(DigitalSignatureTextUnbounded);
                            Clear(InStreamStamp);
                            TempBlob.CreateInStream(InStreamStamp);
                            InStreamStamp.Read(DigitalSignatureTextUnbounded);
                            TempBlob.FromRecord(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Digital Stamp PAC"));
                            Clear(DigitalSignaturePACTextUnbounded);
                            Clear(InStreamStamp);
                            TempBlob.CreateInStream(InStreamStamp);
                            InStreamStamp.Read(DigitalSignaturePACTextUnbounded);

                            TempSalesShipmentHeader := SalesShipmentHeader;
                        end;
                    DATABASE::"Transfer Shipment Header":
                        begin
                            TransferShipmentHeader.Get("No.");
                            TransferShipmentHeader.CalcFields("Original String", "Digital Stamp PAC", "Digital Stamp SAT", "QR Code");
                            Clear(OriginalStringTextUnbounded);
                            TempBlob.FromRecord(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Original String"));
                            Clear(InStreamStamp);
                            TempBlob.CreateInStream(InStreamStamp);
                            InStreamStamp.Read(OriginalStringTextUnbounded);
                            TempBlob.FromRecord(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Digital Stamp SAT"));
                            Clear(DigitalSignatureTextUnbounded);
                            Clear(InStreamStamp);
                            TempBlob.CreateInStream(InStreamStamp);
                            InStreamStamp.Read(DigitalSignatureTextUnbounded);
                            TempBlob.FromRecord(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Digital Stamp PAC"));
                            Clear(DigitalSignaturePACTextUnbounded);
                            Clear(InStreamStamp);
                            TempBlob.CreateInStream(InStreamStamp);
                            InStreamStamp.Read(DigitalSignaturePACTextUnbounded);

                            TempSalesShipmentHeader."QR Code" := TransferShipmentHeader."QR Code";
                            TempSalesShipmentHeader."Certificate Serial No." := TransferShipmentHeader."Certificate Serial No.";
                            TempSalesShipmentHeader."Fiscal Invoice Number PAC" := TransferShipmentHeader."Fiscal Invoice Number PAC";
                            TempSalesShipmentHeader."Date/Time Stamped" := TransferShipmentHeader."Date/Time Stamped";
                        end;
                end;

                OriginalStringBase64Text := Convert.ToBase64String(Encoding.UTF8.GetBytes(OriginalStringTextUnbounded));
                DigitalSignatureBase64Text := Convert.ToBase64String(Encoding.UTF8.GetBytes(DigitalSignatureTextUnbounded));
                DigitalSignaturePACBase64Text := Convert.ToBase64String(Encoding.UTF8.GetBytes(DigitalSignaturePACTextUnbounded));

                if "Foreign Trade" then begin
                    LocationFrom.Get("Transit-from Location");
                    if not LocationTo.Get("Transit-to Location") then begin
                        LocationTo.Init();
                        LocationTo."SAT Address ID" := "SAT Address ID";
                        LocationTo.Address := "Bill-to/Pay-To Address";
                    end;
                end;
                if FixedAssetVehicle.Get("Vehicle Code") then;
                if FixedAssetTrailer1.Get("Trailer 1") then
                    SATTrailerType1.Get(FixedAssetTrailer1."SAT Trailer Type");
                if FixedAssetTrailer2.Get("Trailer 2") then
                    SATTrailerType2.Get(FixedAssetTrailer2."SAT Trailer Type");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        SATUtilities: Codeunit "SAT Utilities";
        EDocCartaPortePrintBuffer: Codeunit "EDoc Carta Porte Print Buffer";
        TempSalesShipmentHeader: Record "Sales Shipment Header";
        TempTransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        CompanyInformation.Get();
        SATTaxRegimeClassification := SATUtilities.GetSATTaxSchemeDescription(CompanyInformation."SAT Tax Regime Classification");
        case EDocCartaPortePrintBuffer.GetSourceTableId() of
            Database::"Sales Shipment Header":
                begin
                    EDocCartaPortePrintBuffer.GetSalesShipment(TempSalesShipmentHeader);
                    CreateTempDocumentTransfer(TempSalesShipmentHeader, "Document Header", "Document Line");
                end;
            Database::"Transfer Shipment Header":
                begin
                    EDocCartaPortePrintBuffer.GetTransferShipment(TempTransferShipmentHeader);
                    CreateTempDocumentTransfer(TempTransferShipmentHeader, "Document Header", "Document Line");
                end;
        end;
    end;

    var
        CompanyInformation: Record "Company Information";
        TempSalesShipmentHeader: Record "Sales Shipment Header" temporary;
        Item: Record Item;
        SATClassification: Record "SAT Classification";
        UnitOfMeasure: Record "Unit of Measure";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        Employee: Record Employee;
        SATPackagingType: Record "SAT Packaging Type";
        SATTrailerType1: Record "SAT Trailer Type";
        SATTrailerType2: Record "SAT Trailer Type";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        FixedAssetVehicle: Record "Fixed Asset";
        FixedAssetTrailer1: Record "Fixed Asset";
        FixedAssetTrailer2: Record "Fixed Asset";
        TempBlob: Codeunit "Temp Blob";
        OriginalStringTextUnbounded: Text;
        DigitalSignatureTextUnbounded: Text;
        DigitalSignaturePACTextUnbounded: Text;
        PageCaptionLbl: Label 'Page:';
        CompanyInformation_RFCNoLbl: Label 'Company RFC';
        FolioTextCaptionLbl: Label 'Folio:';
        ItemDescriptionCaptionLbl: Label 'Item/Description';
        UnitCaptionLbl: Label 'Unit';
        QuantityCaptionLbl: Label 'Quantity';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Total_PriceCaptionLbl: Label 'Total Price';
        Subtotal_CaptionLbl: Label 'Subtotal:';
        Total_CaptionLbl: Label 'Total:';
        Original_StringCaptionLbl: Label 'Cadena original del complemento de certificación digital del SAT', Locked = true;
        Digital_StampCaptionSATLbl: Label 'Sello digital del SAT', Locked = true;
        Digital_StampCaptionLbl: Label 'Sello digital del emisor', Locked = true;
        DocumentFooterLbl: Label 'Este documento es una representación impresa de un CFDI.', Locked = true;
        SATTaxRegimeClassification: Text[100];
        TaxRegimeLbl: Label 'Regimen Fiscal:';
        SATTipoRelacion: Text[100];
        SATFolioFiscal: Text[100];
        TransferRFCNoLbl: Label 'XAXX010101000', Locked = true;
        FiscalRegimeLbl: Label 'Régimen fiscal', Locked = true;
        ClientCartaPorteLbl: Label 'Cliente Extranjero carta porte', Locked = true;
        UsoCFDILbl: Label 'Uso de CFDI';
        UsoCFDDescriptionLbl: Label 'P01 - Por definir';
        TotalAmountLbl: Label 'CERO XXX 00/ 100 XXX', Locked = true;
        OriginalStringBase64Text: Text;
        DigitalSignatureBase64Text: Text;
        DigitalSignaturePACBase64Text: Text;
        MaterialPeligroso: Text;

    local procedure FormatDateTime(DateTime: DateTime): Text[50]
    begin
        exit(Format(DateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;


    local procedure CreateTempDocumentTransfer(DocumentHeaderVariant: Variant; var TempDocumentHeader: Record "Document Header" temporary; var TempDocumentLine: Record "Document Line" temporary)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        GLSetup: Record "General Ledger Setup";
        Location: Record Location;
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        GLSetup.Get();
        DataTypeManagement.GetRecordRef(DocumentHeaderVariant, RecRef);
        case RecRef.Number of
            Database::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShipmentHeader);
                    TempDocumentHeader.TransferFields(SalesShipmentHeader);
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    TempDocumentHeader."CFDI Purpose" := 'S01';
                    TempDocumentHeader."Transit-from Location" := SalesShipmentHeader."Location Code";
                    if TempDocumentHeader."Currency Code" = '' then begin
                        TempDocumentHeader."Currency Code" := GLSetup."LCY Code";
                        TempDocumentHeader."Currency Factor" := 1.0;
                    end;
                    TempDocumentHeader.Insert();
                    SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
                    SalesShipmentLine.SetFilter(Type, '<>%1', SalesShipmentLine.Type::" ");
                    if SalesShipmentLine.FindSet() then
                        repeat
                            TempDocumentLine.TransferFields(SalesShipmentLine);
                            TempDocumentLine."Gross Weight" := SalesShipmentLine."Gross Weight" * SalesShipmentLine.Quantity;
                            TempDocumentLine.Insert();
                            if TempDocumentHeader."Location Code" = '' then
                                TempDocumentHeader."Location Code" := TempDocumentLine."Location Code";
                        until SalesShipmentLine.Next() = 0;
                end;
            Database::"Transfer Shipment Header":
                begin
                    RecRef.SetTable(TransferShipmentHeader);
                    TempDocumentHeader.Init();
                    TempDocumentHeader."No." := TransferShipmentHeader."No.";
                    TempDocumentHeader."Posting Date" := TransferShipmentHeader."Posting Date";
                    TempDocumentHeader."Document Date" := TransferShipmentHeader."Transfer Order Date";
                    TempDocumentHeader."Bill-to/Pay-To Address" := TransferShipmentHeader."Transfer-to Address";
                    TempDocumentHeader."Ship-to/Buy-from Country Code" := TransferShipmentHeader."Trsf.-to Country/Region Code";
                    TempDocumentHeader."Ship-to/Buy-from Post Code" := TransferShipmentHeader."Transfer-from Post Code";
                    TempDocumentHeader."Ship-to/Buy-from City" := TransferShipmentHeader."Transfer-from City";
                    TempDocumentHeader."Transit-from Date/Time" := TransferShipmentHeader."Transit-from Date/Time";
                    TempDocumentHeader."Transit Hours" := TransferShipmentHeader."Transit Hours";
                    TempDocumentHeader."Transit Distance" := TransferShipmentHeader."Transit Distance";
                    TempDocumentHeader."Insurer Name" := TransferShipmentHeader."Insurer Name";
                    TempDocumentHeader."Insurer Policy Number" := TransferShipmentHeader."Insurer Policy Number";
                    TempDocumentHeader."Foreign Trade" := TransferShipmentHeader."Foreign Trade";
                    TempDocumentHeader."Vehicle Code" := TransferShipmentHeader."Vehicle Code";
                    TempDocumentHeader."Trailer 1" := TransferShipmentHeader."Trailer 1";
                    TempDocumentHeader."Trailer 2" := TransferShipmentHeader."Trailer 2";
                    TempDocumentHeader."CFDI Purpose" := 'S01';
                    TempDocumentHeader."CFDI Export Code" := TransferShipmentHeader."CFDI Export Code";
                    TempDocumentHeader."Transit-from Location" := TransferShipmentHeader."Transfer-from Code";
                    TempDocumentHeader."Transit-to Location" := TransferShipmentHeader."Transfer-to Code";
                    TempDocumentHeader."Location Code" := TempDocumentHeader."Transit-to Location";
                    TempDocumentHeader."Medical Insurer Name" := TransferShipmentHeader."Medical Insurer Name";
                    TempDocumentHeader."Medical Ins. Policy Number" := TransferShipmentHeader."Medical Ins. Policy Number";
                    TempDocumentHeader."SAT Weight Unit Of Measure" := TransferShipmentHeader."SAT Weight Unit Of Measure";
                    TempDocumentHeader."SAT Transfer Reason" := TransferShipmentHeader."SAT Transfer Reason";
                    TempDocumentHeader."SAT Customs Regime" := TransferShipmentHeader."SAT Customs Regime";
                    TempDocumentHeader."SAT International Trade Term" := TransferShipmentHeader."SAT International Trade Term";
                    TempDocumentHeader."Exchange Rate USD" := TransferShipmentHeader."Exchange Rate USD";
                    if Location.Get(TransferShipmentHeader."Transfer-to Code") then
                        TempDocumentHeader."SAT Address ID" := Location."SAT Address ID";
                    TempDocumentHeader."Document Table ID" := RecRef.Number;
                    if TempDocumentHeader."Currency Code" = '' then begin
                        TempDocumentHeader."Currency Code" := GLSetup."LCY Code";
                        TempDocumentHeader."Currency Factor" := 1.0;
                    end;
                    TempDocumentHeader.Insert();
                    TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
                    if TransferShipmentLine.FindSet() then
                        repeat
                            TempDocumentLine.Init();
                            TempDocumentLine."Document No." := TransferShipmentLine."Document No.";
                            TempDocumentLine."Line No." := TransferShipmentLine."Line No.";
                            TempDocumentLine.Type := TempDocumentLine.Type::Item;
                            TempDocumentLine."No." := TransferShipmentLine."Item No.";
                            TempDocumentLine.Description := TransferShipmentLine.Description;
                            TempDocumentLine."Unit of Measure Code" := TransferShipmentLine."Unit of Measure Code";
                            TempDocumentLine.Quantity := TransferShipmentLine.Quantity;
                            TempDocumentLine."Gross Weight" := TransferShipmentLine."Gross Weight" * TransferShipmentLine.Quantity;
                            TempDocumentLine."Location Code" := TempDocumentHeader."Location Code";
                            TempDocumentLine."Custom Transit Number" := TransferShipmentLine."Custom Transit Number";
                            TempDocumentLine."SAT Customs Document Type" := TransferShipmentLine."SAT Customs Document Type";
                            TempDocumentLine.Insert();
                            if TempDocumentHeader."Location Code" = '' then
                                TempDocumentHeader."Location Code" := TempDocumentLine."Location Code";
                        until TransferShipmentLine.Next() = 0;
                end;
        end;
        TempDocumentHeader.Modify();
    end;
}
