// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 3362 "EDoc Carta Porte Validation MX"
{
    procedure CheckShipmentDocument(SourceDocumentHeader: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        MXConnectionSetup: Record "MX Connection Setup";
    begin
        Clear(TempErrorMessage);
        if not MXConnectionSetup.Get() then
            Error(MXConnectionSetupMissingErr);
        MXConnectionSetup.TestField(Enabled, true);

        CheckSATCatalogs();
        CheckSATCatalogsCartaPorte();

        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    CheckSalesHeaderCartaPorte(SalesHeader);
                end;
            Database::"Sales Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(SalesShipmentHeader);
                    CheckSalesShipmentHeaderCartaPorte(SalesShipmentHeader);
                end;
            else
                Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());
        end;
        ThrowErrors();
    end;

    procedure CheckTransferDocument(SourceDocumentHeader: RecordRef)
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        MXConnectionSetup: Record "MX Connection Setup";
    begin
        Clear(TempErrorMessage);
        if not MXConnectionSetup.Get() then
            Error(MXConnectionSetupMissingErr);
        MXConnectionSetup.TestField(Enabled, true);

        CheckSATCatalogs();
        CheckSATCatalogsCartaPorte();

        case SourceDocumentHeader.Number of
            Database::"Transfer Header":
                begin
                    SourceDocumentHeader.SetTable(TransferHeader);
                    CheckTransferHeaderCartaPorte(TransferHeader);
                end;
            Database::"Transfer Shipment Header":
                begin
                    SourceDocumentHeader.SetTable(TransferShipmentHeader);
                    CheckTransferShipmentHeaderCartaPorte(TransferShipmentHeader);
                end;
            else
                Error(SourceDocumentNotSupportedErr, SourceDocumentHeader.Caption());
        end;
        ThrowErrors();
    end;

    local procedure CheckSalesHeaderCartaPorte(SalesHeader: Record "Sales Header")
    begin
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Location Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Transit-from Date/Time"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Transit Hours"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Transit Distance"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Insurer Name"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Insurer Policy Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Vehicle Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT Weight Unit Of Measure"), TempErrorMessage."Message Type"::Error);

        if SalesHeader."Foreign Trade" then begin
            TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT Customs Regime"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("SAT Transfer Reason"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
        end;

        TempErrorMessage.LogIfEmpty(SalesHeader, SalesHeader.FieldNo("Transport Operators"), TempErrorMessage."Message Type"::Error);
        CheckAutotransport(SalesHeader."Vehicle Code", false);
        CheckAutotransport(SalesHeader."Trailer 1", true);
        CheckAutotransport(SalesHeader."Trailer 2", true);
        CheckLocation(SalesHeader."Location Code");
        CheckSATAddress(SalesHeader."SAT Address ID");
        CheckSalesHeaderLines(SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure CheckSalesShipmentHeaderCartaPorte(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        OriginLocationCode: Code[10];
    begin
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Document Date"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Transit-from Date/Time"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Transit Hours"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Transit Distance"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Insurer Name"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Insurer Policy Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Vehicle Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("SAT Weight Unit Of Measure"), TempErrorMessage."Message Type"::Error);

        if SalesShipmentHeader."Foreign Trade" then begin
            TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("SAT Customs Regime"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("SAT Transfer Reason"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
        end;

        TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Transport Operators"), TempErrorMessage."Message Type"::Error);
        CheckAutotransport(SalesShipmentHeader."Vehicle Code", false);
        CheckAutotransport(SalesShipmentHeader."Trailer 1", true);
        CheckAutotransport(SalesShipmentHeader."Trailer 2", true);
        OriginLocationCode := GetSalesShipmentOriginLocationCode(SalesShipmentHeader);
        if OriginLocationCode = '' then
            TempErrorMessage.LogIfEmpty(SalesShipmentHeader, SalesShipmentHeader.FieldNo("Location Code"), TempErrorMessage."Message Type"::Error);
        CheckLocation(OriginLocationCode);
        CheckSATAddress(SalesShipmentHeader."SAT Address ID");
        CheckShipmentLines(SalesShipmentHeader."No.");
    end;

    local procedure GetSalesShipmentOriginLocationCode(SalesShipmentHeader: Record "Sales Shipment Header"): Code[10]
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        if SalesShipmentHeader."Location Code" <> '' then
            exit(SalesShipmentHeader."Location Code");

        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.SetFilter("Location Code", '<>%1', '');
        if SalesShipmentLine.FindLast() then
            exit(SalesShipmentLine."Location Code");

        exit('');
    end;

    local procedure CheckTransferHeaderCartaPorte(TransferHeader: Record "Transfer Header")
    begin
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Shipment Date"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Transfer-from Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Transfer-to Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Transit-from Date/Time"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Transit Hours"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Transit Distance"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Insurer Name"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Insurer Policy Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Vehicle Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("SAT Weight Unit Of Measure"), TempErrorMessage."Message Type"::Error);

        if TransferHeader."Foreign Trade" then begin
            TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("SAT Customs Regime"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("SAT Transfer Reason"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
        end;

        TempErrorMessage.LogIfEmpty(TransferHeader, TransferHeader.FieldNo("Transport Operators"), TempErrorMessage."Message Type"::Error);
        CheckAutotransport(TransferHeader."Vehicle Code", false);
        CheckAutotransport(TransferHeader."Trailer 1", true);
        CheckAutotransport(TransferHeader."Trailer 2", true);
        CheckLocation(TransferHeader."Transfer-from Code");
        CheckLocation(TransferHeader."Transfer-to Code");
        CheckTransferHeaderLines(TransferHeader."No.");
    end;

    local procedure CheckTransferShipmentHeaderCartaPorte(TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("No."), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Posting Date"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Transfer-from Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Transfer-to Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Transit-from Date/Time"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Transit Hours"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Transit Distance"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Insurer Name"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Insurer Policy Number"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Vehicle Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("SAT Weight Unit Of Measure"), TempErrorMessage."Message Type"::Error);

        if TransferShipmentHeader."Foreign Trade" then begin
            TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("SAT International Trade Term"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("SAT Customs Regime"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("SAT Transfer Reason"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Exchange Rate USD"), TempErrorMessage."Message Type"::Error);
        end;

        TempErrorMessage.LogIfEmpty(TransferShipmentHeader, TransferShipmentHeader.FieldNo("Transport Operators"), TempErrorMessage."Message Type"::Error);
        CheckAutotransport(TransferShipmentHeader."Vehicle Code", false);
        CheckAutotransport(TransferShipmentHeader."Trailer 1", true);
        CheckAutotransport(TransferShipmentHeader."Trailer 2", true);
        CheckLocation(TransferShipmentHeader."Transfer-from Code");
        CheckLocation(TransferShipmentHeader."Transfer-to Code");
        CheckTransferShipmentLines(TransferShipmentHeader."No.");
    end;

    local procedure CheckAutotransport(VehicleCode: Code[20]; IsTrailer: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if VehicleCode = '' then
            exit;

        FixedAsset.Get(VehicleCode);
        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("Vehicle Licence Plate"), TempErrorMessage."Message Type"::Error);

        if IsTrailer then begin
            TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Trailer Type"), TempErrorMessage."Message Type"::Error);
            exit;
        end;

        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("Vehicle Year"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("Vehicle Gross Weight"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SAT Federal Autotransport"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SCT Permission Type"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(FixedAsset, FixedAsset.FieldNo("SCT Permission No."), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit;

        Location.Get(LocationCode);
        TempErrorMessage.LogIfEmpty(Location, Location.FieldNo("SAT Address ID"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(Location, Location.FieldNo(Address), TempErrorMessage."Message Type"::Error);
        CheckSATAddress(Location."SAT Address ID");
    end;

    local procedure CheckSATAddress(SATAddressID: Integer)
    var
        SATAddress: Record "SAT Address";
    begin
        if SATAddressID = 0 then
            exit;

        if not SATAddress.Get(SATAddressID) then
            Error(SATAddressNotFoundErr, SATAddressID);

        TempErrorMessage.LogIfEmpty(SATAddress, SATAddress.FieldNo("Country/Region Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SATAddress, SATAddress.FieldNo("SAT State Code"), TempErrorMessage."Message Type"::Error);
        TempErrorMessage.LogIfEmpty(SATAddress, SATAddress.FieldNo("SAT Suburb ID"), TempErrorMessage."Message Type"::Error);
    end;

    local procedure CheckSATCatalogs()
    var
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        if SATClassification.IsEmpty() then
            Error(EmptySATCatalogErr, SATClassification.TableCaption());
        if SATRelationshipType.IsEmpty() then
            Error(EmptySATCatalogErr, SATRelationshipType.TableCaption());
        if SATUseCode.IsEmpty() then
            Error(EmptySATCatalogErr, SATUseCode.TableCaption());
        if SATUnitOfMeasure.IsEmpty() then
            Error(EmptySATCatalogErr, SATUnitOfMeasure.TableCaption());
        if SATCountryCode.IsEmpty() then
            Error(EmptySATCatalogErr, SATCountryCode.TableCaption());
        if SATTaxScheme.IsEmpty() then
            Error(EmptySATCatalogErr, SATTaxScheme.TableCaption());
        if SATPaymentTerm.IsEmpty() then
            Error(EmptySATCatalogErr, SATPaymentTerm.TableCaption());
        if SATPaymentMethod.IsEmpty() then
            Error(EmptySATCatalogErr, SATPaymentMethod.TableCaption());
    end;

    local procedure CheckSATCatalogsCartaPorte()
    var
        SATFederalMotorTransport: Record "SAT Federal Motor Transport";
        SATTrailerType: Record "SAT Trailer Type";
        SATPermissionType: Record "SAT Permission Type";
        SATHazardousMaterial: Record "SAT Hazardous Material";
        SATPackagingType: Record "SAT Packaging Type";
        SATMaterialType: Record "SAT Material Type";
        SATState: Record "SAT State";
        SATMunicipality: Record "SAT Municipality";
        SATLocality: Record "SAT Locality";
        SATSuburb: Record "SAT Suburb";
        SATCustomsDocumentType: Record "SAT Customs Document Type";
        SATCustomsRegime: Record "SAT Customs Regime";
        SATTransferReason: Record "SAT Transfer Reason";
    begin
        if SATFederalMotorTransport.IsEmpty() then
            Error(EmptySATCatalogErr, SATFederalMotorTransport.TableCaption());
        if SATTrailerType.IsEmpty() then
            Error(EmptySATCatalogErr, SATTrailerType.TableCaption());
        if SATPermissionType.IsEmpty() then
            Error(EmptySATCatalogErr, SATPermissionType.TableCaption());
        if SATHazardousMaterial.IsEmpty() then
            Error(EmptySATCatalogErr, SATHazardousMaterial.TableCaption());
        if SATPackagingType.IsEmpty() then
            Error(EmptySATCatalogErr, SATPackagingType.TableCaption());
        if SATMaterialType.IsEmpty() then
            Error(EmptySATCatalogErr, SATMaterialType.TableCaption());
        if SATState.IsEmpty() then
            Error(EmptySATCatalogErr, SATState.TableCaption());
        if SATMunicipality.IsEmpty() then
            Error(EmptySATCatalogErr, SATMunicipality.TableCaption());
        if SATLocality.IsEmpty() then
            Error(EmptySATCatalogErr, SATLocality.TableCaption());
        if SATSuburb.IsEmpty() then
            Error(EmptySATCatalogErr, SATSuburb.TableCaption());
        if SATCustomsDocumentType.IsEmpty() then
            Error(EmptySATCatalogErr, SATCustomsDocumentType.TableCaption());
        if SATCustomsRegime.IsEmpty() then
            Error(EmptySATCatalogErr, SATCustomsRegime.TableCaption());
        if SATTransferReason.IsEmpty() then
            Error(EmptySATCatalogErr, SATTransferReason.TableCaption());
    end;

    local procedure CheckShipmentLines(DocumentNo: Code[20])
    var
        Item: Record Item;
        SalesShipmentLine: Record "Sales Shipment Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        if not SalesShipmentLine.FindSet() then begin
            TempErrorMessage.LogMessage(SalesShipmentLine, SalesShipmentLine.FieldNo("Document No."), TempErrorMessage."Message Type"::Error, StrSubstNo(CartaPorteShipmentLinesMissingErr, DocumentNo));
            exit;
        end;

        repeat
            TempErrorMessage.LogIfEmpty(SalesShipmentLine, SalesShipmentLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesShipmentLine, SalesShipmentLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesShipmentLine, SalesShipmentLine.FieldNo("Gross Weight"), TempErrorMessage."Message Type"::Error);

            if SalesShipmentLine.Type <> SalesShipmentLine.Type::Item then
                TempErrorMessage.LogMessage(SalesShipmentLine, SalesShipmentLine.FieldNo(Type), TempErrorMessage."Message Type"::Error, StrSubstNo(CartaPorteShipmentLineTypeErr, SalesShipmentLine."Line No.", Format(SalesShipmentLine.Type)));

            if Item.Get(SalesShipmentLine."No.") then begin
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                if Item."SAT Hazardous Material" <> '' then
                    TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Packaging Type"), TempErrorMessage."Message Type"::Error)
                else
                    if IsHazardousMaterialMandatory(Item."SAT Item Classification") then
                        TempErrorMessage.LogMessage(Item, Item.FieldNo("SAT Hazardous Material"), TempErrorMessage."Message Type"::Error, StrSubstNo(HazardousMaterialMandatoryErr, Item."No.", Item."SAT Item Classification"));
            end;

            if UnitOfMeasure.Get(SalesShipmentLine."Unit of Measure Code") then
                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);
        until SalesShipmentLine.Next() = 0;
    end;

    local procedure CheckSalesHeaderLines(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        if not SalesLine.FindSet() then begin
            TempErrorMessage.LogMessage(SalesLine, SalesLine.FieldNo("Document No."), TempErrorMessage."Message Type"::Error, StrSubstNo(CartaPorteShipmentLinesMissingErr, DocumentNo));
            exit;
        end;

        repeat
            TempErrorMessage.LogIfEmpty(SalesLine, SalesLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesLine, SalesLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(SalesLine, SalesLine.FieldNo("Gross Weight"), TempErrorMessage."Message Type"::Error);

            if SalesLine.Type <> SalesLine.Type::Item then
                TempErrorMessage.LogMessage(SalesLine, SalesLine.FieldNo(Type), TempErrorMessage."Message Type"::Error, StrSubstNo(CartaPorteShipmentLineTypeErr, SalesLine."Line No.", Format(SalesLine.Type)));

            if Item.Get(SalesLine."No.") then begin
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                if Item."SAT Hazardous Material" <> '' then
                    TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Packaging Type"), TempErrorMessage."Message Type"::Error)
                else
                    if IsHazardousMaterialMandatory(Item."SAT Item Classification") then
                        TempErrorMessage.LogMessage(Item, Item.FieldNo("SAT Hazardous Material"), TempErrorMessage."Message Type"::Error, StrSubstNo(HazardousMaterialMandatoryErr, Item."No.", Item."SAT Item Classification"));
            end;

            if UnitOfMeasure.Get(SalesLine."Unit of Measure Code") then
                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);
        until SalesLine.Next() = 0;
    end;

    local procedure CheckTransferShipmentLines(DocumentNo: Code[20])
    var
        Item: Record Item;
        TransferShipmentLine: Record "Transfer Shipment Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        TransferShipmentLine.SetRange("Document No.", DocumentNo);
        if not TransferShipmentLine.FindSet() then begin
            TempErrorMessage.LogMessage(TransferShipmentLine, TransferShipmentLine.FieldNo("Document No."), TempErrorMessage."Message Type"::Error, StrSubstNo(CartaPorteTransferLinesMissingErr, DocumentNo));
            exit;
        end;

        repeat
            TempErrorMessage.LogIfEmpty(TransferShipmentLine, TransferShipmentLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferShipmentLine, TransferShipmentLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferShipmentLine, TransferShipmentLine.FieldNo("Gross Weight"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferShipmentLine, TransferShipmentLine.FieldNo("Item No."), TempErrorMessage."Message Type"::Error);

            if Item.Get(TransferShipmentLine."Item No.") then begin
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                if Item."SAT Hazardous Material" <> '' then
                    TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Packaging Type"), TempErrorMessage."Message Type"::Error)
                else
                    if IsHazardousMaterialMandatory(Item."SAT Item Classification") then
                        TempErrorMessage.LogMessage(Item, Item.FieldNo("SAT Hazardous Material"), TempErrorMessage."Message Type"::Error, StrSubstNo(HazardousMaterialMandatoryErr, Item."No.", Item."SAT Item Classification"));
            end;

            if UnitOfMeasure.Get(TransferShipmentLine."Unit of Measure Code") then
                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);
        until TransferShipmentLine.Next() = 0;
    end;

    local procedure CheckTransferHeaderLines(DocumentNo: Code[20])
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        if not TransferLine.FindSet() then begin
            TempErrorMessage.LogMessage(TransferLine, TransferLine.FieldNo("Document No."), TempErrorMessage."Message Type"::Error, StrSubstNo(CartaPorteTransferLinesMissingErr, DocumentNo));
            exit;
        end;

        repeat
            TempErrorMessage.LogIfEmpty(TransferLine, TransferLine.FieldNo(Description), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferLine, TransferLine.FieldNo("Unit of Measure Code"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferLine, TransferLine.FieldNo("Gross Weight"), TempErrorMessage."Message Type"::Error);
            TempErrorMessage.LogIfEmpty(TransferLine, TransferLine.FieldNo("Item No."), TempErrorMessage."Message Type"::Error);

            if Item.Get(TransferLine."Item No.") then begin
                TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Item Classification"), TempErrorMessage."Message Type"::Error);
                if Item."SAT Hazardous Material" <> '' then
                    TempErrorMessage.LogIfEmpty(Item, Item.FieldNo("SAT Packaging Type"), TempErrorMessage."Message Type"::Error)
                else
                    if IsHazardousMaterialMandatory(Item."SAT Item Classification") then
                        TempErrorMessage.LogMessage(Item, Item.FieldNo("SAT Hazardous Material"), TempErrorMessage."Message Type"::Error, StrSubstNo(HazardousMaterialMandatoryErr, Item."No.", Item."SAT Item Classification"));
            end;

            if UnitOfMeasure.Get(TransferLine."Unit of Measure Code") then
                TempErrorMessage.LogIfEmpty(UnitOfMeasure, UnitOfMeasure.FieldNo("SAT UofM Classification"), TempErrorMessage."Message Type"::Error);
        until TransferLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnBeforeTransferOrderPostShipment', '', false, false)]
    local procedure CheckTransferOrderBeforePost(var TransferHeader: Record "Transfer Header")
    var
        EDocumentService: Record "E-Document Service";
        EDocCartaPorteValidationMX: Codeunit "EDoc Carta Porte Validation MX";
        EDocCFDIValidationMX: Codeunit "EDoc CFDI Validation MX";
        SourceDocumentHeader: RecordRef;
    begin

        EDocumentService.SetRange("Document Format", EDocumentService."Document Format"::CFDI);
        if not EDocumentService.FindFirst() then
            exit;

        SourceDocumentHeader.GetTable(TransferHeader);
        CheckTransferDocument(SourceDocumentHeader);
        EDocCFDIValidationMX.CheckCompanyInfo();
        EDocCFDIValidationMX.CheckCertificate(EDocumentService);
    end;

    local procedure IsHazardousMaterialMandatory(SATClassificationCode: Code[10]): Boolean
    var
        SATClassification: Record "SAT Classification";
    begin
        if not SATClassification.Get(SATClassificationCode) then
            exit(false);
        exit(SATClassification."Hazardous Material Mandatory");
    end;

    local procedure ThrowErrors()
    begin
        if TempErrorMessage.HasErrors(false) then
            if TempErrorMessage.ShowErrors() then
                Error('');
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        SourceDocumentNotSupportedErr: Label 'The source document %1 is not supported for Carta Porte validation.', Comment = '%1 = source document caption';
        HazardousMaterialMandatoryErr: Label 'Item %1 uses SAT classification %2 which requires a hazardous material code. Please fill in the SAT Hazardous Material field on the item card.', Comment = '%1 = Item No., %2 = SAT Classification code';
        MXConnectionSetupMissingErr: Label 'MX Connection Setup does not exist. Please complete the Interfactura setup.';
        EmptySATCatalogErr: Label 'The %1 catalog is empty. Please import the SAT catalogs.', Comment = '%1 = table caption';
        SATAddressNotFoundErr: Label 'SAT Address with Id %1 does not exist.', Comment = '%1 = SAT Address Id';
        CartaPorteShipmentLineTypeErr: Label 'Shipment line %1 must be of type Item for Carta Porte. Current type: %2.', Comment = '%1 = line no., %2 = line type';
        CartaPorteShipmentLinesMissingErr: Label 'Shipment document %1 must contain at least one line.', Comment = '%1 = Document No.';
        CartaPorteTransferLinesMissingErr: Label 'Transfer shipment document %1 must contain at least one line.', Comment = '%1 = Document No.';

}
