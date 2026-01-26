// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using System.Environment;
using System.IO;
using System.Utilities;

codeunit 27030 "SAT Utilities"
{
    // This codeunit will house various utility functions used by the CFDI Mexican Reg F functionality.


    trigger OnRun()
    begin
    end;

    var
        PACWebServiceTxt: Label 'PAC', Locked = true;
        PACWebServiceDetailTypeRequestStampTxt: Label 'GeneraTimbre', Locked = true;
        PACWebServiceDetailTypeCancelTxt: Label 'CancelaTimbre', Locked = true;
        PACWebServiceDetailTypeCancelRequestTxt: Label 'ConsultaEstatusCancelacion', Locked = true;

    [Scope('OnPrem')]
    procedure GetSATUnitofMeasure(UofM: Code[10]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UofM) then
            exit(UnitOfMeasure."SAT UofM Classification");
        exit(UofM);
    end;

    [Scope('OnPrem')]
    procedure GetSATCountryCode(CountryCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CountryCode) then
            exit(CountryRegion."SAT Country Code");
        exit(CountryCode);
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentMethod(PaymentMeth: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.Get(PaymentMeth) then
            exit(PaymentMethod."SAT Method of Payment");
        exit(PaymentMeth);
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentMethodDescription(PaymentMeth: Code[10]): Text[50]
    var
        PaymentMethod: Record "Payment Method";
        SATPaymentMethod: Record "SAT Payment Method";
    begin
        if PaymentMethod.Get(PaymentMeth) then
            if SATPaymentMethod.Get(PaymentMethod."SAT Method of Payment") then
                exit(SATPaymentMethod.Description);
        exit(PaymentMeth);
    end;


    procedure GetSATClassification(LineType: Enum "Sales Line Type"; ReferenceCode: Code[20]): Code[10]
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        FixedAsset: Record "Fixed Asset";
        ItemCharge: Record "Item Charge";
        SATClassification: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSATClassification(LineType, ReferenceCode, SATClassification, IsHandled);
        if IsHandled then
            exit(SATClassification);

        case LineType of
            LineType::Item:
                if Item.Get(ReferenceCode) then
                    exit(Item."SAT Item Classification");
            LineType::"G/L Account":
                if GLAccount.Get(ReferenceCode) then
                    exit(GLAccount."SAT Classification Code");
            LineType::"Fixed Asset":
                if FixedAsset.Get(ReferenceCode) then
                    exit(FixedAsset."SAT Classification Code");
            LineType::"Charge (Item)":
                if ItemCharge.Get(ReferenceCode) then
                    exit(ItemCharge."SAT Classification Code");
            LineType::Resource:
                exit('01010101'); // Does not exist in the catalog
        end;
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentTerm(PaymentTerm: Code[10]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(PaymentTerm) then
            exit(PaymentTerms."SAT Payment Term");
        exit(PaymentTerm);
    end;

    [Scope('OnPrem')]
    procedure GetSATPaymentTermDescription(PaymentTerm: Code[10]): Text[50]
    var
        PaymentTerms: Record "Payment Terms";
        SATPaymentTerm: Record "SAT Payment Term";
    begin
        if PaymentTerms.Get(PaymentTerm) then
            if SATPaymentTerm.Get(PaymentTerms."SAT Payment Term") then
                exit(SATPaymentTerm.Description);
        exit(PaymentTerm);
    end;

    [Scope('OnPrem')]
    procedure GetSATTaxSchemeDescription(TaxScheme: Code[10]): Text[100]
    var
        SATTaxScheme: Record "SAT Tax Scheme";
    begin
        if SATTaxScheme.Get(TaxScheme) then
            exit(SATTaxScheme.Description);
        exit(TaxScheme);
    end;

    [Scope('OnPrem')]
    procedure GetSATUnitOfMeasureFixedAsset(): Code[10]
    begin
        exit('H87'); // Unidad de conteo que define el número de piezas (pieza: un solo artículo, artículo o ejemplar).
    end;

    [Scope('OnPrem')]
    procedure GetSATUnitOfMeasureGLAccount(): Code[10]
    begin
        exit('E48'); // Unidad de recuento de definir el número de unidades de contabilidad.
    end;

    [Scope('OnPrem')]
    procedure MapCountryCodes()
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegion.FindSet() then
            repeat
                case CountryRegion.Code of
                    'AE':
                        CountryRegion."SAT Country Code" := 'ARE';
                    'AT':
                        CountryRegion."SAT Country Code" := 'AUT';
                    'AU':
                        CountryRegion."SAT Country Code" := 'AUS';
                    'BE':
                        CountryRegion."SAT Country Code" := 'BEL';
                    'BG':
                        CountryRegion."SAT Country Code" := 'BGR';
                    'BN':
                        CountryRegion."SAT Country Code" := 'BRN';
                    'BR':
                        CountryRegion."SAT Country Code" := 'BRA';
                    'CA':
                        CountryRegion."SAT Country Code" := 'CAN';
                    'CH':
                        CountryRegion."SAT Country Code" := 'CHE';
                    'CN':
                        CountryRegion."SAT Country Code" := 'CHN';
                    'CY':
                        CountryRegion."SAT Country Code" := 'CYP';
                    'CZ':
                        CountryRegion."SAT Country Code" := 'CZE';
                    'DE':
                        CountryRegion."SAT Country Code" := 'DEU';
                    'DK':
                        CountryRegion."SAT Country Code" := 'DNK';
                    'DZ':
                        CountryRegion."SAT Country Code" := 'DZA';
                    'EE':
                        CountryRegion."SAT Country Code" := 'EST';
                    'EL':
                        CountryRegion."SAT Country Code" := 'GRC';
                    'ES':
                        CountryRegion."SAT Country Code" := 'ESP';
                    'FI':
                        CountryRegion."SAT Country Code" := 'FIN';
                    'FJ':
                        CountryRegion."SAT Country Code" := 'FJI';
                    'FR':
                        CountryRegion."SAT Country Code" := 'FRA';
                    'GB':
                        CountryRegion."SAT Country Code" := 'GBR';
                    'HR':
                        CountryRegion."SAT Country Code" := 'HRV';
                    'HU':
                        CountryRegion."SAT Country Code" := 'HUN';
                    'ID':
                        CountryRegion."SAT Country Code" := 'IDN';
                    'IE':
                        CountryRegion."SAT Country Code" := 'IRL';
                    'IN':
                        CountryRegion."SAT Country Code" := 'IND';
                    'IS':
                        CountryRegion."SAT Country Code" := 'ISL';
                    'IT':
                        CountryRegion."SAT Country Code" := 'ITA';
                    'JP':
                        CountryRegion."SAT Country Code" := 'JPN';
                    'KE':
                        CountryRegion."SAT Country Code" := 'KEN';
                    'LT':
                        CountryRegion."SAT Country Code" := 'LTU';
                    'LU':
                        CountryRegion."SAT Country Code" := 'LUX';
                    'LV':
                        CountryRegion."SAT Country Code" := 'LVA';
                    'MA':
                        CountryRegion."SAT Country Code" := 'MAR';
                    'ME':
                        CountryRegion."SAT Country Code" := 'MNE';
                    'MT':
                        CountryRegion."SAT Country Code" := 'MLT';
                    'MX':
                        CountryRegion."SAT Country Code" := 'MEX';
                    'MY':
                        CountryRegion."SAT Country Code" := 'MYS';
                    'MZ':
                        CountryRegion."SAT Country Code" := 'MOZ';
                    'NG':
                        CountryRegion."SAT Country Code" := 'NGA';
                    'NL':
                        CountryRegion."SAT Country Code" := 'NLD';
                    'NO':
                        CountryRegion."SAT Country Code" := 'NOR';
                    'NZ':
                        CountryRegion."SAT Country Code" := 'NZL';
                    'PH':
                        CountryRegion."SAT Country Code" := 'PHL';
                    'PL':
                        CountryRegion."SAT Country Code" := 'POL';
                    'PT':
                        CountryRegion."SAT Country Code" := 'PRT';
                    'RO':
                        CountryRegion."SAT Country Code" := 'ROU';
                    'RS':
                        CountryRegion."SAT Country Code" := 'SRB';
                    'RU':
                        CountryRegion."SAT Country Code" := 'RUS';
                    'SA':
                        CountryRegion."SAT Country Code" := 'SAU';
                    'SB':
                        CountryRegion."SAT Country Code" := 'SLB';
                    'SE':
                        CountryRegion."SAT Country Code" := 'SWE';
                    'SG':
                        CountryRegion."SAT Country Code" := 'SGP';
                    'SI':
                        CountryRegion."SAT Country Code" := 'SVN';
                    'SK':
                        CountryRegion."SAT Country Code" := 'SVK';
                    'SZ':
                        CountryRegion."SAT Country Code" := 'SWZ';
                    'TH':
                        CountryRegion."SAT Country Code" := 'THA';
                    'TN':
                        CountryRegion."SAT Country Code" := 'TUN';
                    'TR':
                        CountryRegion."SAT Country Code" := 'TUR';
                    'TZ':
                        CountryRegion."SAT Country Code" := 'TZA';
                    'UG':
                        CountryRegion."SAT Country Code" := 'UGA';
                    'US':
                        CountryRegion."SAT Country Code" := 'USA';
                    'VU':
                        CountryRegion."SAT Country Code" := 'VUT';
                    'WS':
                        CountryRegion."SAT Country Code" := 'WSM';
                    'ZA':
                        CountryRegion."SAT Country Code" := 'ZAF';
                    else
                        CountryRegion."SAT Country Code" := 'ZZZ';
                end;
                CountryRegion.Modify();
            until CountryRegion.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure MapUnitsofMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.FindSet() then
            repeat
                case UnitOfMeasure.Code of
                    'DAY':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'DAY', '');
                    'GR':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'GRM', '02');
                    'HOUR':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'HUR', '');
                    'KG':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'KGM', '01');
                    'KM':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'KMT', '');
                    'L':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'LTR', '08');
                    'PCS':
                        UpdateUnitOfMeasure(UnitOfMeasure, 'EA', '');
                end;
                UnitOfMeasure.Modify();
            until UnitOfMeasure.Next() = 0;
    end;

    local procedure UpdateUnitOfMeasure(var UnitOfMeasure: Record "Unit of Measure"; SATUoMCode: Code[10]; SATCustomsCode: Code[10])
    begin
        UnitOfMeasure."SAT UofM Classification" := SATUoMCode;
        UnitOfMeasure."SAT Customs Unit" := SATCustomsCode;
    end;

    procedure PopulatePACWebServiceData()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
        PACWebServiceDetail: Record "PAC Web Service Detail";
        PACCode: Code[10];
    begin
        if not GeneralLedgerSetup.Get() then
            exit;

        PACCode := GeneralLedgerSetup."PAC Code";
        if PACCode = '' then
            PACCode := PACWebServiceTxt;

        if not PACWebService.Get(PACCode) then begin
            PACWebService.Init();
            PACWebService.Code := PACCode;
            PACWebService.Name := PACCode;
            PACWebService.Insert();
        end;

        if GeneralLedgerSetup."PAC Code" = '' then begin
            GeneralLedgerSetup.Validate("PAC Code", PACCode);
            GeneralLedgerSetup.Modify(true);
        end;

        CreatePACWebServiceDetail(
          PACCode, PACWebServiceDetail.Environment::Production, PACWebServiceDetail.Type::"Request Stamp",
          PACWebServiceDetailTypeRequestStampTxt);
        CreatePACWebServiceDetail(
          PACCode, PACWebServiceDetail.Environment::Production, PACWebServiceDetail.Type::Cancel,
          PACWebServiceDetailTypeCancelTxt);
        CreatePACWebServiceDetail(
          PACCode, PACWebServiceDetail.Environment::Production, PACWebServiceDetail.Type::CancelRequest,
          PACWebServiceDetailTypeCancelRequestTxt);
    end;

    local procedure CreatePACWebServiceDetail(PACCode: Code[10]; Environment: Option; MethodType: Option; MethodName: Text[50])
    var
        PACWebServiceDetail: Record "PAC Web Service Detail";
    begin
        if PACWebServiceDetail.Get(PACCode, Environment, MethodType) then
            exit;

        PACWebServiceDetail.Init();
        PACWebServiceDetail."PAC Code" := PACCode;
        PACWebServiceDetail.Environment := Environment;
        PACWebServiceDetail.Type := MethodType;
        PACWebServiceDetail."Method Name" := MethodName;
        PACWebServiceDetail.Insert();
    end;

    [Scope('OnPrem')]
    procedure PopulateSATInformation()
    var
        SATPaymentMethod: Record "SAT Payment Method";
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        CFDICancellationReason: Record "CFDI Cancellation Reason";
        CFDIExportCode: Record "CFDI Export Code";
        CFDISubjectToTax: Record "CFDI Subject to Tax";
        SATInternationalTradeTerm: Record "SAT International Trade Term";
        SATCustomsUnit: Record "SAT Customs Unit";
        SATTransferReason: Record "SAT Transfer Reason";
        MediaResources: Record "Media Resources";
        SATClassificationPort: XMLport "SAT Classification";
        SATRelationshipTypePort: XMLport "SAT Relationship Type";
        SATUseCodePort: XMLport "SAT Use Code";
        SATUnitOfMeasurePort: XMLport "SAT Unit of Measure";
        SATCountryCodePort: XMLport "SAT Country Code";
        SATPaymentMethodPort: XMLport "SAT Payment Method";
        SATTaxSchemePort: XMLport "SAT Tax Scheme";
        SATPaymentTermPort: XMLport "SAT Payment Term";
        CFDICancellationReasonPort: XMLport "CFDI Cancellation Reason";
        CFDIExportCodePort: XMLport "CFDI Export Code";
        CFDISubjectToTaxPort: XMLport "CFDI Subject to Tax";
        SATInternationalTradeTermPort: XMLport "SAT International Trade Term";
        SATCustomsUnitPort: XMLport "SAT Customs Unit";
        SATTransferReasonPort: XMLport "SAT Transfer Reason";
        IStr: InStream;
    begin
        if SATClassification.IsEmpty() then begin
            MediaResources.Get('SATClassifications.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATClassificationPort.SetSource(IStr);
            SATClassificationPort.Import();
        end;

        if SATCountryCode.IsEmpty() then begin
            MediaResources.Get('SATCountry_Codes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATCountryCodePort.SetSource(IStr);
            SATCountryCodePort.Import();
        end;

        if SATPaymentTerm.IsEmpty() then begin
            MediaResources.Get('SATPayment_Terms.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATPaymentTermPort.SetSource(IStr);
            SATPaymentTermPort.Import();
        end;

        if SATRelationshipType.IsEmpty() then begin
            MediaResources.Get('SATRelationship_Types.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATRelationshipTypePort.SetSource(IStr);
            SATRelationshipTypePort.Import();
        end;

        if SATTaxScheme.IsEmpty() then begin
            MediaResources.Get('SATTax_Schemes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATTaxSchemePort.SetSource(IStr);
            SATTaxSchemePort.Import();
        end;

        if SATUnitOfMeasure.IsEmpty() then begin
            MediaResources.Get('SATU_of_M.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATUnitOfMeasurePort.SetSource(IStr);
            SATUnitOfMeasurePort.Import();
        end;

        if SATUseCode.IsEmpty() then begin
            MediaResources.Get('SATUse_Codes.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATUseCodePort.SetSource(IStr);
            SATUseCodePort.Import();
        end;

        if SATPaymentMethod.IsEmpty() then begin
            MediaResources.Get('SATPayment_Methods.xml');
            MediaResources.CalcFields(Blob);
            MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
            SATPaymentMethodPort.SetSource(IStr);
            SATPaymentMethodPort.Import();
        end;

        if CFDICancellationReason.IsEmpty() then
            if MediaResources.Get('CFDICancellationReasons.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                CFDICancellationReasonPort.SetSource(IStr);
                CFDICancellationReasonPort.Import();
            end;

        if CFDIExportCode.IsEmpty() then
            if MediaResources.Get('CFDIExportCodes.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                CFDIExportCodePort.SetSource(IStr);
                CFDIExportCodePort.Import();
            end;

        if CFDISubjectToTax.IsEmpty() then
            if MediaResources.Get('CFDISubjectsToTax.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                CFDISubjectToTaxPort.SetSource(IStr);
                CFDISubjectToTaxPort.Import();
            end;

        if SATInternationalTradeTerm.IsEmpty() then
            if MediaResources.Get('SATIncoterms.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATInternationalTradeTermPort.SetSource(IStr);
                SATInternationalTradeTermPort.Import();
            end;

        if SATCustomsUnit.IsEmpty() then
            if MediaResources.Get('SATCustomUnits.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATCustomsUnitPort.SetSource(IStr);
                SATCustomsUnitPort.Import();
            end;

        if SATTransferReason.IsEmpty() then
            if MediaResources.Get('SATTransferReasons.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATTransferReasonPort.SetSource(IStr);
                SATTransferReasonPort.Import();
            end;

        PopulateCartaPorteSATCatalogs();
    end;

    local procedure PopulateCartaPorteSATCatalogs()
    var
        SATFederalMotorTransport: Record "SAT Federal Motor Transport";
        SATTrailerType: Record "SAT Trailer Type";
        SATPermissionType: Record "SAT Permission Type";
        SATHazardousMaterial: Record "SAT Hazardous Material";
        SATPackagingType: Record "SAT Packaging Type";
        SATState: Record "SAT State";
        SATMunicipality: Record "SAT Municipality";
        SATLocality: Record "SAT Locality";
        SATSuburb: Record "SAT Suburb";
        SATWeightUnitOfMeasure: Record "SAT Weight Unit of Measure";
        SATMaterialType: Record "SAT Material Type";
        SATCustomsRegime: Record "SAT Customs Regime";
        SATCustomsDocument: Record "SAT Customs Document Type";
        MediaResources: Record "Media Resources";
        SATFederalMotorTransportPort: XMLport "SAT Federal Motor Transport";
        SATTrailerTypePort: XMLport "SAT Trailer Type";
        SATPermissionTypePort: XMLport "SAT Permission Type";
        SATHazardousMaterialPort: XMLport "SAT Hazardous Material";
        SATPackagingTypePort: XMLport "SAT Packaging Type";
        SATStatePort: XMLport "SAT State";
        SATMunicipalityPort: XMLport "SAT Municipality";
        SATLocalityPort: XMLport "SAT Locality";
        SATSuburbPort: XMLport "SAT Suburb";
        SATWeightUnitOfMeasurePort: XMLport "SAT Weight Unit of Measure";
        SATMaterialTypePort: XMLport "SAT Material Type";
        SATCustomsRegimePort: XMLport "SAT Customs Regime";
        SATCustomsDocumentPort: XMLport "SAT Customs Document Type";
        IStr: InStream;
    begin
        if SATFederalMotorTransport.IsEmpty() then
            if MediaResources.Get('SATFederalMotorTransport.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATFederalMotorTransportPort.SetSource(IStr);
                SATFederalMotorTransportPort.Import();
            end;

        if SATTrailerType.IsEmpty() then
            if MediaResources.Get('SATTrailerTypes.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATTrailerTypePort.SetSource(IStr);
                SATTrailerTypePort.Import();
            end;

        if SATPermissionType.IsEmpty() then
            if MediaResources.Get('SATPermissionTypes.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATPermissionTypePort.SetSource(IStr);
                SATPermissionTypePort.Import();
            end;

        if SATHazardousMaterial.IsEmpty() then
            if MediaResources.Get('SATHazardousMaterials.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATHazardousMaterialPort.SetSource(IStr);
                SATHazardousMaterialPort.Import();
            end;

        if SATPackagingType.IsEmpty() then
            if MediaResources.Get('SATPackagingTypes.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATPackagingTypePort.SetSource(IStr);
                SATPackagingTypePort.Import();
            end;

        if SATState.IsEmpty() then
            if MediaResources.Get('SATStates.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATStatePort.SetSource(IStr);
                SATStatePort.Import();
            end;

        if SATMunicipality.IsEmpty() then
            if MediaResources.Get('SATMunicipalities.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATMunicipalityPort.SetSource(IStr);
                SATMunicipalityPort.Import();
            end;

        if SATLocality.IsEmpty() then
            if MediaResources.Get('SATLocalities.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATLocalityPort.SetSource(IStr);
                SATLocalityPort.Import();
            end;

        if SATSuburb.IsEmpty() then begin
            if MediaResources.Get('SATSuburb1.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATSuburbPort.SetSource(IStr);
                SATSuburbPort.Import();
            end;
            if MediaResources.Get('SATSuburb2.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATSuburbPort.SetSource(IStr);
                SATSuburbPort.Import();
            end;
            if MediaResources.Get('SATSuburb3.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATSuburbPort.SetSource(IStr);
                SATSuburbPort.Import();
            end;
            if MediaResources.Get('SATSuburb4.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATSuburbPort.SetSource(IStr);
                SATSuburbPort.Import();
            end;
        end;

        if SATWeightUnitOfMeasure.IsEmpty() then
            if MediaResources.Get('SATWeightUnitsOfMeasure.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TEXTENCODING::UTF16);
                SATWeightUnitOfMeasurePort.SetSource(IStr);
                SATWeightUnitOfMeasurePort.Import();
            end;

        if SATMaterialType.IsEmpty() then
            if MediaResources.Get('SATMaterialTypes.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TextEncoding::UTF16);
                SATMaterialTypePort.SetSource(IStr);
                SATMaterialTypePort.Import();
            end;

        if SATCustomsRegime.IsEmpty() then
            if MediaResources.Get('SATCustomsRegimes.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TextEncoding::UTF16);
                SATCustomsRegimePort.SetSource(IStr);
                SATCustomsRegimePort.Import();
            end;

        if SATCustomsDocument.IsEmpty() then
            if MediaResources.Get('SATCustomsDocuments.xml') then begin
                MediaResources.CalcFields(Blob);
                MediaResources.Blob.CreateInStream(IStr, TextEncoding::UTF16);
                SATCustomsDocumentPort.SetSource(IStr);
                SATCustomsDocumentPort.Import();
            end;
    end;

    [Scope('OnPrem')]
    procedure CreateSATXMLFiles()
    var
        SATPaymentMethodCode: Record "SAT Payment Method Code";
        SATClassification: Record "SAT Classification";
        SATRelationshipType: Record "SAT Relationship Type";
        SATUseCode: Record "SAT Use Code";
        SATUnitOfMeasure: Record "SAT Unit of Measure";
        SATCountryCode: Record "SAT Country Code";
        SATTaxScheme: Record "SAT Tax Scheme";
        SATPaymentTerm: Record "SAT Payment Term";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Classification", OutStr, SATClassification);
        FileManagement.BLOBExport(TempBlob, 'SATClassifications.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Country Code", OutStr, SATCountryCode);
        FileManagement.BLOBExport(TempBlob, 'SATCountry_Codes.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Payment Term", OutStr, SATPaymentTerm);
        FileManagement.BLOBExport(TempBlob, 'SATPayment_Forms.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Payment Method", OutStr, SATPaymentMethodCode);
        FileManagement.BLOBExport(TempBlob, 'SATPayment_Methods.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Relationship Type", OutStr, SATRelationshipType);
        FileManagement.BLOBExport(TempBlob, 'SATRelationship_Types.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Tax Scheme", OutStr, SATTaxScheme);
        FileManagement.BLOBExport(TempBlob, 'SATTax_Schemes.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Unit of Measure", OutStr, SATUnitOfMeasure);
        FileManagement.BLOBExport(TempBlob, 'SATU_of_M.xml', true);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPORT::"SAT Use Code", OutStr, SATUseCode);
        FileManagement.BLOBExport(TempBlob, 'SATUse_Codes.xml', true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSATClassification(LineType: Enum "Sales Line Type"; ReferenceCode: Code[20]; var SATClassification: Code[10]; var IsHandled: Boolean)
    begin
    end;
}
