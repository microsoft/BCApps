// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.IO.CartaPorte;

using Microsoft.eServices.EDocument;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 3310 "EDoc Carta Porte Validation MX"
{


    procedure CheckShipmentDocument(SourceDocumentHeader: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        MXConnectionSetup: Record "MX Connection Setup";
    begin
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
    end;

    procedure CheckTransferDocument(SourceDocumentHeader: RecordRef)
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        MXConnectionSetup: Record "MX Connection Setup";
    begin
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
    end;

    local procedure CheckSalesHeaderCartaPorte(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("No.");
        SalesHeader.TestField("Document Date");
        SalesHeader.TestField("Location Code");
        SalesHeader.TestField("SAT Address ID");
        SalesHeader.TestField("Transit-from Date/Time");
        SalesHeader.TestField("Transit Hours");
        SalesHeader.TestField("Transit Distance");
        SalesHeader.TestField("Insurer Name");
        SalesHeader.TestField("Insurer Policy Number");
        SalesHeader.TestField("Vehicle Code");
        SalesHeader.TestField("SAT Weight Unit Of Measure");

        if SalesHeader."Foreign Trade" then begin
            SalesHeader.TestField("SAT International Trade Term");
            SalesHeader.TestField("SAT Customs Regime");
            SalesHeader.TestField("SAT Transfer Reason");
            SalesHeader.TestField("Exchange Rate USD");
        end;

        CheckAutotransport(SalesHeader."Vehicle Code", false);
        CheckAutotransport(SalesHeader."Trailer 1", true);
        CheckAutotransport(SalesHeader."Trailer 2", true);
        CheckLocation(SalesHeader."Location Code");
        CheckSATAddress(SalesHeader."SAT Address ID");
        CheckTransportOperators(Database::"Sales Header", SalesHeader."No.");
        CheckSalesHeaderLines(SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure CheckSalesShipmentHeaderCartaPorte(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        OriginLocationCode: Code[10];
    begin
        SalesShipmentHeader.TestField("No.");
        SalesShipmentHeader.TestField("Document Date");
        SalesShipmentHeader.TestField("SAT Address ID");
        SalesShipmentHeader.TestField("Transit-from Date/Time");
        SalesShipmentHeader.TestField("Transit Hours");
        SalesShipmentHeader.TestField("Transit Distance");
        SalesShipmentHeader.TestField("Insurer Name");
        SalesShipmentHeader.TestField("Insurer Policy Number");
        SalesShipmentHeader.TestField("Vehicle Code");
        SalesShipmentHeader.TestField("SAT Weight Unit Of Measure");

        if SalesShipmentHeader."Foreign Trade" then begin
            SalesShipmentHeader.TestField("SAT International Trade Term");
            SalesShipmentHeader.TestField("SAT Customs Regime");
            SalesShipmentHeader.TestField("SAT Transfer Reason");
            SalesShipmentHeader.TestField("Exchange Rate USD");
        end;

        CheckAutotransport(SalesShipmentHeader."Vehicle Code", false);
        CheckAutotransport(SalesShipmentHeader."Trailer 1", true);
        CheckAutotransport(SalesShipmentHeader."Trailer 2", true);
        OriginLocationCode := GetSalesShipmentOriginLocationCode(SalesShipmentHeader);
        if OriginLocationCode = '' then
            SalesShipmentHeader.TestField("Location Code");
        CheckLocation(OriginLocationCode);
        CheckSATAddress(SalesShipmentHeader."SAT Address ID");
        CheckTransportOperators(Database::"Sales Shipment Header", SalesShipmentHeader."No.");
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
        TransferHeader.TestField("No.");
        TransferHeader.TestField("Shipment Date");
        TransferHeader.TestField("Transfer-from Code");
        TransferHeader.TestField("Transfer-to Code");
        TransferHeader.TestField("Transit-from Date/Time");
        TransferHeader.TestField("Transit Hours");
        TransferHeader.TestField("Transit Distance");
        TransferHeader.TestField("Insurer Name");
        TransferHeader.TestField("Insurer Policy Number");
        TransferHeader.TestField("Vehicle Code");
        TransferHeader.TestField("SAT Weight Unit Of Measure");

        if TransferHeader."Foreign Trade" then begin
            TransferHeader.TestField("SAT International Trade Term");
            TransferHeader.TestField("SAT Customs Regime");
            TransferHeader.TestField("SAT Transfer Reason");
            TransferHeader.TestField("Exchange Rate USD");
        end;

        CheckAutotransport(TransferHeader."Vehicle Code", false);
        CheckAutotransport(TransferHeader."Trailer 1", true);
        CheckAutotransport(TransferHeader."Trailer 2", true);
        CheckLocation(TransferHeader."Transfer-from Code");
        CheckLocation(TransferHeader."Transfer-to Code");
        CheckTransportOperators(Database::"Transfer Header", TransferHeader."No.");
        CheckTransferHeaderLines(TransferHeader."No.");
    end;

    local procedure CheckTransferShipmentHeaderCartaPorte(TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TransferShipmentHeader.TestField("No.");
        TransferShipmentHeader.TestField("Posting Date");
        TransferShipmentHeader.TestField("Transfer-from Code");
        TransferShipmentHeader.TestField("Transfer-to Code");
        TransferShipmentHeader.TestField("Transit-from Date/Time");
        TransferShipmentHeader.TestField("Transit Hours");
        TransferShipmentHeader.TestField("Transit Distance");
        TransferShipmentHeader.TestField("Insurer Name");
        TransferShipmentHeader.TestField("Insurer Policy Number");
        TransferShipmentHeader.TestField("Vehicle Code");
        TransferShipmentHeader.TestField("SAT Weight Unit Of Measure");

        if TransferShipmentHeader."Foreign Trade" then begin
            TransferShipmentHeader.TestField("SAT International Trade Term");
            TransferShipmentHeader.TestField("SAT Customs Regime");
            TransferShipmentHeader.TestField("SAT Transfer Reason");
            TransferShipmentHeader.TestField("Exchange Rate USD");
        end;

        CheckAutotransport(TransferShipmentHeader."Vehicle Code", false);
        CheckAutotransport(TransferShipmentHeader."Trailer 1", true);
        CheckAutotransport(TransferShipmentHeader."Trailer 2", true);
        CheckLocation(TransferShipmentHeader."Transfer-from Code");
        CheckLocation(TransferShipmentHeader."Transfer-to Code");

        CheckTransportOperators(Database::"Transfer Shipment Header", TransferShipmentHeader."No.");
        CheckTransferShipmentLines(TransferShipmentHeader."No.");
    end;

    local procedure CheckAutotransport(VehicleCode: Code[20]; IsTrailer: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if VehicleCode = '' then
            exit;

        FixedAsset.Get(VehicleCode);
        FixedAsset.TestField("Vehicle Licence Plate");

        if IsTrailer then begin
            FixedAsset.TestField("SAT Trailer Type");
            exit;
        end;

        FixedAsset.TestField("Vehicle Year");
        FixedAsset.TestField("Vehicle Gross Weight");
        FixedAsset.TestField("SAT Federal Autotransport");
        FixedAsset.TestField("SCT Permission Type");
        FixedAsset.TestField("SCT Permission No.");
    end;

    local procedure CheckLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit;

        Location.Get(LocationCode);
        Location.TestField("SAT Address ID");
        Location.TestField(Address);
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

        SATAddress.TestField("Country/Region Code");
        SATAddress.TestField("SAT State Code");
        SATAddress.TestField("SAT Suburb ID");
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

    local procedure CheckTransportOperators(DocumentTableId: Integer; DocumentNo: Code[20])
    var
        CFDITransportOperator: Record "CFDI Transport Operator";
        Employee: Record Employee;
    begin
        CFDITransportOperator.SetRange("Document Table ID", DocumentTableId);
        CFDITransportOperator.SetRange("Document No.", DocumentNo);
        if not CFDITransportOperator.FindSet() then
            Error(MissingTransportOperatorsErr, DocumentNo);

        repeat
            CFDITransportOperator.TestField("Operator Code");
            Employee.Get(CFDITransportOperator."Operator Code");
            Employee.TestField("RFC No.");
            Employee.TestField("License No.");
            if Employee.FullName() = '' then
                Error(EmptyTransportOperatorNameErr, Employee."No.");
        until CFDITransportOperator.Next() = 0;
    end;

    local procedure CheckShipmentLines(DocumentNo: Code[20])
    var
        Item: Record Item;
        SalesShipmentLine: Record "Sales Shipment Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        if not SalesShipmentLine.FindSet() then
            Error(CartaPorteShipmentLinesMissingErr, DocumentNo);

        repeat
            SalesShipmentLine.TestField(Description);
            SalesShipmentLine.TestField("Unit of Measure Code");
            SalesShipmentLine.TestField("Gross Weight");

            if SalesShipmentLine.Type <> SalesShipmentLine.Type::Item then
                Error(CartaPorteShipmentLineTypeErr, SalesShipmentLine."Line No.", Format(SalesShipmentLine.Type));

            if Item.Get(SalesShipmentLine."No.") then begin
                Item.TestField("SAT Item Classification");
                if Item."SAT Hazardous Material" <> '' then
                    Item.TestField("SAT Packaging Type");
            end;

            if UnitOfMeasure.Get(SalesShipmentLine."Unit of Measure Code") then
                UnitOfMeasure.TestField("SAT UofM Classification");
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
        if not SalesLine.FindSet() then
            Error(CartaPorteShipmentLinesMissingErr, DocumentNo);

        repeat
            SalesLine.TestField(Description);
            SalesLine.TestField("Unit of Measure Code");
            SalesLine.TestField("Gross Weight");

            if SalesLine.Type <> SalesLine.Type::Item then
                Error(CartaPorteShipmentLineTypeErr, SalesLine."Line No.", Format(SalesLine.Type));

            if Item.Get(SalesLine."No.") then begin
                Item.TestField("SAT Item Classification");
                if Item."SAT Hazardous Material" <> '' then
                    Item.TestField("SAT Packaging Type");
            end;

            if UnitOfMeasure.Get(SalesLine."Unit of Measure Code") then
                UnitOfMeasure.TestField("SAT UofM Classification");
        until SalesLine.Next() = 0;
    end;

    local procedure CheckTransferShipmentLines(DocumentNo: Code[20])
    var
        Item: Record Item;
        TransferShipmentLine: Record "Transfer Shipment Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        TransferShipmentLine.SetRange("Document No.", DocumentNo);
        if not TransferShipmentLine.FindSet() then
            Error(CartaPorteTransferLinesMissingErr, DocumentNo);

        repeat
            TransferShipmentLine.TestField(Description);
            TransferShipmentLine.TestField("Unit of Measure Code");
            TransferShipmentLine.TestField("Gross Weight");
            TransferShipmentLine.TestField("Item No.");

            if Item.Get(TransferShipmentLine."Item No.") then begin
                Item.TestField("SAT Item Classification");
                if Item."SAT Hazardous Material" <> '' then
                    Item.TestField("SAT Packaging Type");
            end;

            if UnitOfMeasure.Get(TransferShipmentLine."Unit of Measure Code") then
                UnitOfMeasure.TestField("SAT UofM Classification");
        until TransferShipmentLine.Next() = 0;
    end;

    local procedure CheckTransferHeaderLines(DocumentNo: Code[20])
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        if not TransferLine.FindSet() then
            Error(CartaPorteTransferLinesMissingErr, DocumentNo);

        repeat
            TransferLine.TestField(Description);
            TransferLine.TestField("Unit of Measure Code");
            TransferLine.TestField("Gross Weight");
            TransferLine.TestField("Item No.");

            if Item.Get(TransferLine."Item No.") then begin
                Item.TestField("SAT Item Classification");
                if Item."SAT Hazardous Material" <> '' then
                    Item.TestField("SAT Packaging Type");
            end;

            if UnitOfMeasure.Get(TransferLine."Unit of Measure Code") then
                UnitOfMeasure.TestField("SAT UofM Classification");
        until TransferLine.Next() = 0;
    end;

    var
        SourceDocumentNotSupportedErr: Label 'The source document %1 is not supported for Carta Porte validation.', Comment = '%1 = source document caption';
        MXConnectionSetupMissingErr: Label 'MX Connection Setup does not exist. Please complete the Interfactura setup.';
        EmptySATCatalogErr: Label 'The %1 catalog is empty. Please import the SAT catalogs.', Comment = '%1 = table caption';
        SATAddressNotFoundErr: Label 'SAT Address with Id %1 does not exist.', Comment = '%1 = SAT Address Id';
        MissingTransportOperatorsErr: Label 'Document %1 must have one or more CFDI Transport Operators.', Comment = '%1 = Document No.';
        EmptyTransportOperatorNameErr: Label 'Transport operator %1 must have Full Name defined.', Comment = '%1 = Employee No.';
        CartaPorteShipmentLineTypeErr: Label 'Shipment line %1 must be of type Item for Carta Porte. Current type: %2.', Comment = '%1 = line no., %2 = line type';
        CartaPorteShipmentLinesMissingErr: Label 'Shipment document %1 must contain at least one line.', Comment = '%1 = Document No.';
        CartaPorteTransferLinesMissingErr: Label 'Transfer shipment document %1 must contain at least one line.', Comment = '%1 = Document No.';

}