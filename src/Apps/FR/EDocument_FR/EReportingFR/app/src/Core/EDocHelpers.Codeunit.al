// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;

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
        CompanyInformation.Get();
        if CompanyInformation."Registration No." = '' then
            RaiseCompanyInformationError(
                StrSubstNo(SIRENRequiredErr, CompanyInformation.FieldCaption("Registration No."), CompanyInformation.TableCaption()),
                CompanyInformation);
    end;

    procedure CheckSIRETNotEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."SIRET No." = '' then
            RaiseCompanyInformationError(
                StrSubstNo(SIRETRequiredErr, CompanyInformation.FieldCaption("SIRET No."), CompanyInformation.TableCaption()),
                CompanyInformation);
    end;

    procedure CheckSellerElectronicAddress(EDocumentServiceCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
        ServiceParticipant: Record "Service Participant";
    begin
        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Company, '') then
            exit;

        CompanyInformation.Get();
        if CompanyInformation."SIRET No." <> '' then
            exit;
        if CompanyInformation."Registration No." <> '' then
            exit;
        if (CompanyInformation.GetVATRegistrationNumber() <> '') and IsFrenchCompany(CompanyInformation) then
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
    begin
        if not FRCIIXMLBuilder.TryGetCustomerNoFieldRef(SourceDocumentHeader, CustomerNoFieldRef) then
            exit;

        CustomerNo := CustomerNoFieldRef.Value();
        if CustomerNo = '' then
            exit;

        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, CustomerNo, ServiceParticipant) then begin
            CheckServiceParticipantElectronicAddressValue(ServiceParticipant, CustomerNo);
            exit;
        end;

        Customer.SetLoadFields("FR Electronic Address", "Registration Number", "VAT Registration No.");
        if not Customer.Get(CustomerNo) then
            exit;

        if GetBuyerElectronicAddress(Customer, BuyerElectronicAddress) then begin
            CheckBuyerElectronicAddressValue(BuyerElectronicAddress, Customer.FieldCaption("FR Electronic Address"), CustomerNo);
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

    local procedure CheckBuyerElectronicAddressValue(ElectronicAddress: Text; FieldCaption: Text; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if IsValidBuyerElectronicAddress(ElectronicAddress) then
            exit;

        Customer.Get(CustomerNo);
        RaiseCustomerError(StrSubstNo(BuyerElectronicAddressInvalidErr, FieldCaption, CustomerNo), Customer);
    end;

    local procedure CheckServiceParticipantElectronicAddressValue(ServiceParticipant: Record "Service Participant"; CustomerNo: Code[20])
    begin
        if IsValidBuyerElectronicAddress(ServiceParticipant."Participant Identifier") then
            exit;

        RaiseServiceParticipantError(
            StrSubstNo(BuyerElectronicAddressInvalidErr, ServiceParticipant.FieldCaption("Participant Identifier"), CustomerNo),
            ServiceParticipant);
    end;

    local procedure IsValidBuyerElectronicAddress(ElectronicAddress: Text): Boolean
    begin
        if StrLen(ElectronicAddress) < 9 then
            exit(false);
        if DelChr(CopyStr(ElectronicAddress, 1, 9), '=', '0123456789') <> '' then
            exit(false);
        if StrLen(ElectronicAddress) = 9 then
            exit(true);

        exit(
            (StrLen(ElectronicAddress) > 10) and
            (CopyStr(ElectronicAddress, 10, 1) = '_') and
            (DelChr(CopyStr(ElectronicAddress, 11), '<>', ' ') <> ''));
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
        BuyerElectronicAddressInvalidErr: Label '%1 for customer %2 must contain a nine-digit SIREN, optionally followed by an underscore and a suffix.', Comment = '%1 = Electronic address field caption, %2 = Customer No.';
        SellerCountryCodeRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = Country/Region Code field caption, %2 = Company Information table caption';
        ServiceParticipantAddressIncompleteErr: Label '%1 and %2 must both be specified for French electronic invoicing.', Comment = '%1 = Participant Identifier field caption, %2 = French Identifier Scheme field caption';
        ShowCompanyInformationLbl: Label 'Show Company Information';
        ShowCustomerLbl: Label 'Show Customer';
        ShowServiceParticipantLbl: Label 'Show Service Participant';
}
