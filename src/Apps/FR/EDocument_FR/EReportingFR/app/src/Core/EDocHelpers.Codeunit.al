// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Email;

codeunit 10991 "EDoc. Helpers"
{
    Access = Internal;

    procedure FindFieldByName(RecRef: RecordRef; FieldName: Text; var FieldRefResult: FieldRef): Boolean
    var
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FieldRefResult := RecRef.FieldIndex(i);
            if FieldRefResult.Name() = FieldName then
                exit(true);
        end;
        exit(false);
    end;

    procedure GetNodeValue(XmlDoc: XmlDocument; NamespaceMgr: XmlNamespaceManager; XPath: Text): Text
    var
        FoundNode: XmlNode;
        XmlAttribute: XmlAttribute;
    begin
        if not XmlDoc.SelectSingleNode(XPath, NamespaceMgr, FoundNode) then
            exit('');

        if FoundNode.IsXmlElement() then
            exit(FoundNode.AsXmlElement().InnerText());

        if FoundNode.IsXmlAttribute() then begin
            XmlAttribute := FoundNode.AsXmlAttribute();
            exit(XmlAttribute.Value());
        end;
    end;

    procedure CheckSIRENNotEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.SetLoadFields("Registration No.", "SIRET No.");
        CompanyInformation.Get();
        if CompanyInformation."Registration No." = '' then
            RaiseCompanyInformationError(
                StrSubstNo(SIRENRequiredErr, CompanyInformation.FieldCaption("Registration No."), CompanyInformation.TableCaption()),
                CompanyInformation);

        ValidateCompanyIdentifiers(CompanyInformation);
    end;

    procedure CheckSIRETNotEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.SetLoadFields("Registration No.", "SIRET No.");
        CompanyInformation.Get();
        if CompanyInformation."SIRET No." = '' then
            RaiseCompanyInformationError(
                StrSubstNo(SIRETRequiredErr, CompanyInformation.FieldCaption("SIRET No."), CompanyInformation.TableCaption()),
                CompanyInformation);

        ValidateCompanyIdentifiers(CompanyInformation);
    end;

    internal procedure IsValidSIREN(SIREN: Text): Boolean
    begin
        exit(IsNumericIdentifier(SIREN, 9));
    end;

    internal procedure IsValidSIRET(SIRET: Text): Boolean
    begin
        exit(IsNumericIdentifier(SIRET, 14));
    end;

    internal procedure GetSIRENFromSIRET(SIRET: Text): Text[9]
    begin
        if IsValidSIRET(SIRET) then
            exit(CopyStr(SIRET, 1, 9));
    end;

    internal procedure ValidateSIRENSIRET(SIREN: Text; SIRET: Text; RecordVariant: Variant)
    begin
        if (SIREN <> '') and not IsValidSIREN(SIREN) then
            RaiseIdentifierError(StrSubstNo(IdentifierFormatErr, GetSIRENCaption(RecordVariant), 9), RecordVariant);
        if (SIRET <> '') and not IsValidSIRET(SIRET) then
            RaiseIdentifierError(StrSubstNo(IdentifierFormatErr, GetSIRETCaption(RecordVariant), 14), RecordVariant);
        if (SIREN <> '') and (SIRET <> '') and (CopyStr(SIRET, 1, 9) <> SIREN) then
            RaiseIdentifierError(StrSubstNo(SIRENSIRETConflictErr, SIREN, SIRET), RecordVariant);
    end;

    internal procedure ValidateCompanyIdentifiers(CompanyInformation: Record "Company Information")
    begin
        ValidateSIRENSIRET(CompanyInformation."Registration No.", CompanyInformation."SIRET No.", CompanyInformation);
    end;

    internal procedure ValidateCustomerIdentifiers(Customer: Record Customer)
    begin
        ValidateSIRENSIRET(Customer."Registration Number", GetCustomerSIRET(Customer), Customer);
    end;

    internal procedure ValidateVendorIdentifiers(Vendor: Record Vendor)
    begin
        ValidateSIRENSIRET(Vendor."Registration Number", GetVendorSIRET(Vendor), Vendor);
    end;

    internal procedure GetCompanySIREN(CompanyInformation: Record "Company Information"): Text[9]
    begin
        ValidateCompanyIdentifiers(CompanyInformation);
        if CompanyInformation."Registration No." <> '' then
            exit(CopyStr(CompanyInformation."Registration No.", 1, 9));

        exit(GetSIRENFromSIRET(CompanyInformation."SIRET No."));
    end;

    internal procedure GetCustomerSIREN(Customer: Record Customer): Text[9]
    var
        LegacySIREN: Text[250];
    begin
        ValidateCustomerIdentifiers(Customer);
        if Customer."Registration Number" <> '' then
            exit(CopyStr(Customer."Registration Number", 1, 9));
        if GetCustomerSIRET(Customer) <> '' then
            exit(GetSIRENFromSIRET(GetCustomerSIRET(Customer)));
        if GetSIRENFromFrenchVATRegistrationNo(Customer."VAT Registration No.", LegacySIREN) then
            exit(CopyStr(LegacySIREN, 1, 9));
    end;

    internal procedure GetVendorSIREN(Vendor: Record Vendor): Text[9]
    begin
        ValidateVendorIdentifiers(Vendor);
        if Vendor."Registration Number" <> '' then
            exit(CopyStr(Vendor."Registration Number", 1, 9));

        exit(GetSIRENFromSIRET(GetVendorSIRET(Vendor)));
    end;

    internal procedure GetCustomerSIRET(Customer: Record Customer): Text
    begin
        if Customer."FR Elec. Address Scheme" = Customer."FR Elec. Address Scheme"::"0009" then
            exit(Customer."FR Electronic Address");
    end;

    internal procedure GetVendorSIRET(Vendor: Record Vendor): Text
    begin
        if Vendor."FR Elec. Address Scheme" = Vendor."FR Elec. Address Scheme"::"0009" then
            exit(Vendor."FR Electronic Address");
    end;

    internal procedure FindVendorByLegalIdentifiers(SIRET: Text; SIREN: Text; var VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetLoadFields("No.");
        if IsValidSIRET(SIRET) then begin
            Vendor.SetRange("FR Electronic Address", SIRET);
            Vendor.SetRange("FR Elec. Address Scheme", Vendor."FR Elec. Address Scheme"::"0009");
            if Vendor.Count() > 0 then begin
                if Vendor.Count() = 1 then begin
                    Vendor.FindFirst();
                    VendorNo := Vendor."No.";
                end;
                exit(true);
            end;
        end;

        if IsValidSIREN(SIREN) then begin
            Vendor.Reset();
            Vendor.SetRange("Registration Number", SIREN);
            if Vendor.Count() > 0 then begin
                if Vendor.Count() = 1 then begin
                    Vendor.FindFirst();
                    VendorNo := Vendor."No.";
                end;
                exit(true);
            end;
        end;
    end;

    local procedure IsNumericIdentifier(Identifier: Text; RequiredLength: Integer): Boolean
    begin
        exit((StrLen(Identifier) = RequiredLength) and (DelChr(Identifier, '=', '0123456789') = ''));
    end;

    internal procedure IsValidElectronicAddress(ElectronicAddress: Text; ElectronicAddressScheme: Enum "Electronic Address Scheme"): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        case ElectronicAddressScheme of
            ElectronicAddressScheme::"0002":
                exit(IsValidSIREN(ElectronicAddress));
            ElectronicAddressScheme::"0009":
                exit(IsValidSIRET(ElectronicAddress));
            ElectronicAddressScheme::"0225":
                exit(IsValidFRCTCAddress(ElectronicAddress));
            ElectronicAddressScheme::"9957":
                exit(IsValidFrenchVATIdentifier(ElectronicAddress));
            ElectronicAddressScheme::"EM":
                exit((ElectronicAddress <> '') and MailManagement.CheckValidEmailAddress(ElectronicAddress));
        end;

        exit(false);
    end;

    internal procedure GetElectronicAddressSchemeCode(ElectronicAddressScheme: Enum "Electronic Address Scheme"): Text
    begin
        case ElectronicAddressScheme of
            ElectronicAddressScheme::"EM":
                exit('EM');
            ElectronicAddressScheme::"0009":
                exit('0009');
            ElectronicAddressScheme::"0002":
                exit('0002');
            ElectronicAddressScheme::"0225":
                exit('0225');
            ElectronicAddressScheme::"9957":
                exit('9957');
            else
                exit(Format(ElectronicAddressScheme));
        end;
    end;

    internal procedure GetCompanyElectronicAddress(CompanyInformation: Record "Company Information"; EDocumentServiceCode: Code[20]; var ElectronicAddress: Text[250]; var ElectronicAddressScheme: Enum "Electronic Address Scheme"): Boolean
    begin
        if GetServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Company, '', ElectronicAddress, ElectronicAddressScheme) then
            exit(true);
        if IsValidSIRET(CompanyInformation."SIRET No.") then begin
            ElectronicAddress := CompanyInformation."SIRET No.";
            ElectronicAddressScheme := ElectronicAddressScheme::"0009";
            exit(true);
        end;
        if IsValidSIREN(CompanyInformation."Registration No.") then begin
            ElectronicAddress := CompanyInformation."Registration No.";
            ElectronicAddressScheme := ElectronicAddressScheme::"0002";
            exit(true);
        end;
        if IsFrenchCompany(CompanyInformation) and IsValidFrenchVATIdentifier(CompanyInformation.GetVATRegistrationNumber()) then begin
            ElectronicAddress := CopyStr(DelChr(CompanyInformation.GetVATRegistrationNumber(), '=', ' '), 1, MaxStrLen(ElectronicAddress));
            ElectronicAddressScheme := ElectronicAddressScheme::"9957";
            exit(true);
        end;
    end;

    internal procedure GetCustomerElectronicAddress(Customer: Record Customer; EDocumentServiceCode: Code[20]; var ElectronicAddress: Text[250]; var ElectronicAddressScheme: Enum "Electronic Address Scheme"): Boolean
    begin
        if GetServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, Customer."No.", ElectronicAddress, ElectronicAddressScheme) then
            exit(true);
        if Customer."FR Electronic Address" <> '' then begin
            ElectronicAddress := Customer."FR Electronic Address";
            ElectronicAddressScheme := Customer."FR Elec. Address Scheme";
            exit(true);
        end;
        if IsValidSIREN(Customer."Registration Number") then begin
            ElectronicAddress := Customer."Registration Number";
            ElectronicAddressScheme := ElectronicAddressScheme::"0002";
            exit(true);
        end;
        if IsValidFrenchVATIdentifier(Customer."VAT Registration No.") then begin
            ElectronicAddress := CopyStr(DelChr(Customer."VAT Registration No.", '=', ' '), 1, MaxStrLen(ElectronicAddress));
            ElectronicAddressScheme := ElectronicAddressScheme::"9957";
            exit(true);
        end;
    end;

    local procedure GetServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]; var ElectronicAddress: Text[250]; var ElectronicAddressScheme: Enum "Electronic Address Scheme"): Boolean
    var
        ServiceParticipant: Record "Service Participant";
    begin
        if not HasServiceParticipantAddress(EDocumentServiceCode, ParticipantType, ParticipantNo, ServiceParticipant) then
            exit(false);

        ElectronicAddress := CopyStr(ServiceParticipant."Participant Identifier", 1, MaxStrLen(ElectronicAddress));
        ElectronicAddressScheme := ServiceParticipant."FR Identifier Scheme";
        exit(true);
    end;

    local procedure IsValidFRCTCAddress(ElectronicAddress: Text): Boolean
    begin
        if IsValidSIREN(ElectronicAddress) then
            exit(true);

        exit(
            (StrLen(ElectronicAddress) > 10) and
            IsValidSIREN(CopyStr(ElectronicAddress, 1, 9)) and
            (CopyStr(ElectronicAddress, 10, 1) = '_') and
            (DelChr(CopyStr(ElectronicAddress, 11), '<>', ' ') <> ''));
    end;

    local procedure IsValidFrenchVATIdentifier(VATRegistrationNo: Text): Boolean
    begin
        VATRegistrationNo := DelChr(VATRegistrationNo, '=', ' ');
        exit(
            (StrLen(VATRegistrationNo) = 13) and
            (CopyStr(VATRegistrationNo, 1, 2).ToUpper() = 'FR') and
            (DelChr(CopyStr(VATRegistrationNo, 3), '=', '0123456789') = ''));
    end;

    local procedure GetSIRENCaption(RecordVariant: Variant): Text
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecordVariant);
        case RecordRef.Number() of
            Database::"Company Information":
                exit(CompanyInformation.FieldCaption("Registration No."));
            Database::Customer:
                exit(Customer.FieldCaption("Registration Number"));
            Database::Vendor:
                exit(Vendor.FieldCaption("Registration Number"));
        end;
    end;

    local procedure GetSIRETCaption(RecordVariant: Variant): Text
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(RecordVariant);
        case RecordRef.Number() of
            Database::"Company Information":
                exit(CompanyInformation.FieldCaption("SIRET No."));
            Database::Customer:
                exit(Customer.FieldCaption("FR Electronic Address"));
            Database::Vendor:
                exit(Vendor.FieldCaption("FR Electronic Address"));
        end;
    end;

    procedure CheckSellerElectronicAddress(EDocumentServiceCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
        ServiceParticipant: Record "Service Participant";
        SellerElectronicAddress: Text[250];
        SellerElectronicAddressScheme: Enum "Electronic Address Scheme";
    begin
        CompanyInformation.SetLoadFields("Registration No.", "SIRET No.", "VAT Registration No.", "Country/Region Code");
        CompanyInformation.Get();
        ValidateCompanyIdentifiers(CompanyInformation);

        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Company, '', ServiceParticipant) then begin
            if not IsValidElectronicAddress(ServiceParticipant."Participant Identifier", ServiceParticipant."FR Identifier Scheme") then
                RaiseServiceParticipantError(StrSubstNo(ElectronicAddressInvalidErr, ServiceParticipant.FieldCaption("Participant Identifier")), ServiceParticipant);
            exit;
        end;

        if GetCompanyElectronicAddress(CompanyInformation, '', SellerElectronicAddress, SellerElectronicAddressScheme) then
            if IsValidElectronicAddress(SellerElectronicAddress, SellerElectronicAddressScheme) then
                exit;

        RaiseCompanyInformationError(
            StrSubstNo(SellerElectronicAddressRequiredErr, CompanyInformation.FieldCaption("SIRET No."), CompanyInformation.FieldCaption("Registration No."), CompanyInformation.FieldCaption("VAT Registration No."), ServiceParticipant.TableCaption(), CompanyInformation.TableCaption()),
            CompanyInformation);
    end;

    internal procedure IsFrenchCompany(CompanyInformation: Record "Company Information"): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CompanyInformation.GetVATRegistrationNumber().StartsWith('FR') then
            exit(true);

        if not CountryRegion.Get(CompanyInformation."Country/Region Code") then
            exit(false);

        exit(CountryRegion."ISO Code" = 'FR');
    end;

    procedure CheckSellerCountryCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.SetLoadFields("Country/Region Code");
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" = '' then
            RaiseCompanyInformationError(
                StrSubstNo(SellerCountryCodeRequiredErr, CompanyInformation.FieldCaption("Country/Region Code"), CompanyInformation.TableCaption()),
                CompanyInformation);
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef)
    begin
        CheckBuyerElectronicAddress(SourceDocumentHeader, '');
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckBuyerElectronicAddress(SourceDocumentHeader, EDocumentServiceCode, IsHandled);
        if not IsHandled then
            CheckBuyerElectronicAddressCore(SourceDocumentHeader, EDocumentServiceCode);

        OnAfterCheckBuyerElectronicAddress(SourceDocumentHeader, EDocumentServiceCode);
    end;

    local procedure CheckBuyerElectronicAddressCore(var SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20])
    var
        Customer: Record Customer;
        ServiceParticipant: Record "Service Participant";
        FRCIIXMLBuilder: Codeunit "CII XML Builder";
        CustomerNoFieldRef: FieldRef;
        CustomerNo: Code[20];
        BuyerElectronicAddress: Text[250];
        BuyerElectronicAddressScheme: Enum "Electronic Address Scheme";
    begin
        if not FRCIIXMLBuilder.TryGetCustomerNoFieldRef(SourceDocumentHeader, CustomerNoFieldRef) then
            exit;

        CustomerNo := CustomerNoFieldRef.Value();
        if CustomerNo = '' then
            exit;

        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme", "Registration Number", "VAT Registration No.");
        if not Customer.Get(CustomerNo) then
            exit;

        ValidateCustomerIdentifiers(Customer);
        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, CustomerNo, ServiceParticipant) then begin
            CheckServiceParticipantElectronicAddressValue(ServiceParticipant, CustomerNo);
            exit;
        end;

        if GetCustomerElectronicAddress(Customer, '', BuyerElectronicAddress, BuyerElectronicAddressScheme) then begin
            CheckBuyerElectronicAddressValue(BuyerElectronicAddress, BuyerElectronicAddressScheme, Customer.FieldCaption("FR Electronic Address"), CustomerNo);
            exit;
        end;

        RaiseCustomerError(
            StrSubstNo(BuyerElectronicAddressRequiredErr, Customer.FieldCaption("FR Electronic Address"), Customer.FieldCaption("Registration Number"), Customer.FieldCaption("VAT Registration No."), ServiceParticipant.TableCaption(), Customer.TableCaption(), Customer."No."),
            Customer);
    end;

    internal procedure GetBuyerElectronicAddress(Customer: Record Customer; var BuyerElectronicAddress: Text[250]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetBuyerElectronicAddress(Customer, BuyerElectronicAddress, Result, IsHandled);
        if not IsHandled then begin
            BuyerElectronicAddress := Customer."FR Electronic Address";
            if BuyerElectronicAddress <> '' then
                Result := true
            else begin
                BuyerElectronicAddress := CopyStr(Customer."Registration Number", 1, 9);
                if BuyerElectronicAddress <> '' then
                    Result := true
                else
                    Result := GetSIRENFromFrenchVATRegistrationNo(Customer."VAT Registration No.", BuyerElectronicAddress);
            end;
        end;

        OnAfterGetBuyerElectronicAddress(Customer, BuyerElectronicAddress, Result);
    end;

    local procedure GetSIRENFromFrenchVATRegistrationNo(VATRegistrationNo: Text; var SIREN: Text[250]): Boolean
    begin
        VATRegistrationNo := DelChr(VATRegistrationNo, '=', ' ');
        if (StrLen(VATRegistrationNo) <> 13) or (CopyStr(VATRegistrationNo, 1, 2).ToUpper() <> 'FR') then
            exit(false);

        SIREN := CopyStr(VATRegistrationNo, 5, 9);
        if DelChr(SIREN, '=', '0123456789') <> '' then begin
            Clear(SIREN);
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckBuyerElectronicAddressValue(ElectronicAddress: Text; ElectronicAddressScheme: Enum "Electronic Address Scheme"; FieldCaption: Text; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if IsValidElectronicAddress(ElectronicAddress, ElectronicAddressScheme) then
            exit;

        Customer.Get(CustomerNo);
        RaiseCustomerError(StrSubstNo(BuyerElectronicAddressInvalidErr, FieldCaption, CustomerNo), Customer);
    end;

    local procedure CheckServiceParticipantElectronicAddressValue(ServiceParticipant: Record "Service Participant"; CustomerNo: Code[20])
    begin
        if IsValidElectronicAddress(ServiceParticipant."Participant Identifier", ServiceParticipant."FR Identifier Scheme") then
            exit;

        RaiseServiceParticipantError(
            StrSubstNo(BuyerElectronicAddressInvalidErr, ServiceParticipant.FieldCaption("Participant Identifier"), CustomerNo),
            ServiceParticipant);
    end;

    internal procedure HasServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]): Boolean
    var
        ServiceParticipant: Record "Service Participant";
    begin
        exit(HasServiceParticipantAddress(EDocumentServiceCode, ParticipantType, ParticipantNo, ServiceParticipant));
    end;

    internal procedure HasServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]; var ServiceParticipant: Record "Service Participant"): Boolean
    var
        ParticipantAddressErrorInfo: ErrorInfo;
        HasIdentifier: Boolean;
        HasScheme: Boolean;
    begin
        if EDocumentServiceCode = '' then
            exit(false);
        if not ServiceParticipant.Get(EDocumentServiceCode, ParticipantType, ParticipantNo) then
            exit(false);

        HasIdentifier := ServiceParticipant."Participant Identifier" <> '';
        HasScheme := ServiceParticipant."FR Identifier Scheme" <> ServiceParticipant."FR Identifier Scheme"::" ";
        if HasIdentifier <> HasScheme then begin
            ParticipantAddressErrorInfo.Message(GetServiceParticipantAddressIncompleteError());
            ParticipantAddressErrorInfo.DataClassification := DataClassification::SystemMetadata;
            ParticipantAddressErrorInfo.RecordId(ServiceParticipant.RecordId());
            ParticipantAddressErrorInfo.PageNo(Page::"Service Participants");
            ParticipantAddressErrorInfo.AddNavigationAction(ShowServiceParticipantLbl);
            Error(ParticipantAddressErrorInfo);
        end;

        exit(HasIdentifier);
    end;

    local procedure RaiseCompanyInformationError(ErrorMessage: Text; CompanyInformation: Record "Company Information")
    var
        SetupErrorInfo: ErrorInfo;
    begin
        SetupErrorInfo.Message(ErrorMessage);
        SetupErrorInfo.DataClassification := DataClassification::SystemMetadata;
        SetupErrorInfo.RecordId(CompanyInformation.RecordId());
        SetupErrorInfo.PageNo(Page::"Company Information");
        SetupErrorInfo.AddNavigationAction(ShowCompanyInformationLbl);
        Error(SetupErrorInfo);
    end;

    local procedure RaiseCustomerError(ErrorMessage: Text; Customer: Record Customer)
    var
        SetupErrorInfo: ErrorInfo;
    begin
        SetupErrorInfo.Message(ErrorMessage);
        SetupErrorInfo.DataClassification := DataClassification::CustomerContent;
        SetupErrorInfo.RecordId(Customer.RecordId());
        SetupErrorInfo.PageNo(Page::"Customer Card");
        SetupErrorInfo.AddNavigationAction(ShowCustomerLbl);
        Error(SetupErrorInfo);
    end;

    local procedure RaiseServiceParticipantError(ErrorMessage: Text; ServiceParticipant: Record "Service Participant")
    var
        SetupErrorInfo: ErrorInfo;
    begin
        SetupErrorInfo.Message(ErrorMessage);
        SetupErrorInfo.DataClassification := DataClassification::CustomerContent;
        SetupErrorInfo.RecordId(ServiceParticipant.RecordId());
        SetupErrorInfo.PageNo(Page::"Service Participants");
        SetupErrorInfo.AddNavigationAction(ShowServiceParticipantLbl);
        Error(SetupErrorInfo);
    end;

    local procedure RaiseIdentifierError(ErrorMessage: Text; RecordVariant: Variant)
    var
        RecordRef: RecordRef;
        IdentifierErrorInfo: ErrorInfo;
    begin
        RecordRef.GetTable(RecordVariant);
        IdentifierErrorInfo.Message(ErrorMessage);
        IdentifierErrorInfo.DataClassification := DataClassification::CustomerContent;
        IdentifierErrorInfo.RecordId(RecordRef.RecordId());
        case RecordRef.Number() of
            Database::"Company Information":
                begin
                    IdentifierErrorInfo.PageNo(Page::"Company Information");
                    IdentifierErrorInfo.AddNavigationAction(ShowCompanyInformationLbl);
                end;
            Database::Customer:
                begin
                    IdentifierErrorInfo.PageNo(Page::"Customer Card");
                    IdentifierErrorInfo.AddNavigationAction(ShowCustomerLbl);
                end;
            Database::Vendor:
                begin
                    IdentifierErrorInfo.PageNo(Page::"Vendor Card");
                    IdentifierErrorInfo.AddNavigationAction(ShowVendorLbl);
                end;
        end;
        Error(IdentifierErrorInfo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBuyerElectronicAddress(Customer: Record Customer; var BuyerElectronicAddress: Text[250]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBuyerElectronicAddress(Customer: Record Customer; var BuyerElectronicAddress: Text[250]; var Result: Boolean)
    begin
    end;

    internal procedure GetSIRENRequiredError(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        exit(StrSubstNo(SIRENRequiredErr, CompanyInformation.FieldCaption("Registration No."), CompanyInformation.TableCaption()));
    end;

    internal procedure GetSIRETRequiredError(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        exit(StrSubstNo(SIRETRequiredErr, CompanyInformation.FieldCaption("SIRET No."), CompanyInformation.TableCaption()));
    end;

    internal procedure GetSellerElectronicAddressRequiredError(): Text
    var
        CompanyInformation: Record "Company Information";
        ServiceParticipant: Record "Service Participant";
    begin
        exit(StrSubstNo(SellerElectronicAddressRequiredErr, CompanyInformation.FieldCaption("SIRET No."), CompanyInformation.FieldCaption("Registration No."), CompanyInformation.FieldCaption("VAT Registration No."), ServiceParticipant.TableCaption(), CompanyInformation.TableCaption()));
    end;

    internal procedure GetSellerCountryCodeRequiredError(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        exit(StrSubstNo(SellerCountryCodeRequiredErr, CompanyInformation.FieldCaption("Country/Region Code"), CompanyInformation.TableCaption()));
    end;

    internal procedure GetBuyerElectronicAddressRequiredError(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
        ServiceParticipant: Record "Service Participant";
    begin
        exit(StrSubstNo(BuyerElectronicAddressRequiredErr, Customer.FieldCaption("FR Electronic Address"), Customer.FieldCaption("Registration Number"), Customer.FieldCaption("VAT Registration No."), ServiceParticipant.TableCaption(), Customer.TableCaption(), CustomerNo));
    end;

    internal procedure GetBuyerElectronicAddressInvalidError(FieldCaption: Text; CustomerNo: Code[20]): Text
    begin
        exit(StrSubstNo(BuyerElectronicAddressInvalidErr, FieldCaption, CustomerNo));
    end;

    internal procedure GetServiceParticipantAddressIncompleteError(): Text
    var
        ServiceParticipant: Record "Service Participant";
    begin
        exit(StrSubstNo(ServiceParticipantAddressIncompleteErr, ServiceParticipant.FieldCaption("Participant Identifier"), ServiceParticipant.FieldCaption("FR Identifier Scheme")));
    end;

    var
        SIRENRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = Registration No. field caption, %2 = Company Information table caption';
        SIRETRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = SIRET No. field caption, %2 = Company Information table caption';
        SellerElectronicAddressRequiredErr: Label '%1, %2, %3, or a %4 identifier must be specified for the %5 for French e-invoicing.', Comment = '%1 = SIRET No. field caption, %2 = Registration No. field caption, %3 = VAT Registration No. field caption, %4 = Service Participant table caption, %5 = Company Information table caption';
        BuyerElectronicAddressRequiredErr: Label '%1, %2, French %3, or a %4 identifier must be specified for %5 %6 for French e-invoicing.', Comment = '%1 = Electronic Address field caption, %2 = Registration Number field caption, %3 = VAT Registration No. field caption, %4 = Service Participant table caption, %5 = Customer table caption, %6 = Customer No.';
        BuyerElectronicAddressInvalidErr: Label '%1 for customer %2 is not valid for the selected electronic address scheme.', Comment = '%1 = Electronic address field caption, %2 = Customer No.';
        ElectronicAddressInvalidErr: Label '%1 is not valid for the selected electronic address scheme.', Comment = '%1 = Electronic address field caption';
        SellerCountryCodeRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = Country/Region Code field caption, %2 = Company Information table caption';
        ServiceParticipantAddressIncompleteErr: Label '%1 and %2 must both be specified for French electronic invoicing.', Comment = '%1 = Participant Identifier field caption, %2 = French Identifier Scheme field caption';
        IdentifierFormatErr: Label '%1 must contain exactly %2 numeric digits for French electronic invoicing.', Comment = '%1 = Identifier field caption, %2 = Required number of digits';
        SIRENSIRETConflictErr: Label 'SIREN %1 and SIRET %2 do not identify the same legal entity. The first nine digits of SIRET must equal SIREN.', Comment = '%1 = SIREN, %2 = SIRET';
        ShowCompanyInformationLbl: Label 'Show Company Information';
        ShowCustomerLbl: Label 'Show Customer';
        ShowVendorLbl: Label 'Show Vendor';
        ShowServiceParticipantLbl: Label 'Show Service Participant';
}
