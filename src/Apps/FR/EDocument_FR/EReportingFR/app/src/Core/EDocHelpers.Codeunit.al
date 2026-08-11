// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service.Participant;
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
            Error(GetSIRENRequiredError());
    end;

    procedure CheckSIRETNotEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."SIRET No." = '' then
            Error(GetSIRETRequiredError());
    end;

    procedure CheckSellerElectronicAddress(EDocumentServiceCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Company, '') then
            exit;

        CompanyInformation.Get();
        if CompanyInformation."SIRET No." <> '' then
            exit;
        if CompanyInformation."Registration No." <> '' then
            exit;
        if CompanyInformation.GetVATRegistrationNumber() <> '' then
            exit;

        Error(GetSellerElectronicAddressRequiredError());
    end;

    procedure CheckSellerCountryCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" = '' then
            Error(GetSellerCountryCodeRequiredError());
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef)
    begin
        CheckBuyerElectronicAddress(SourceDocumentHeader, '');
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20])
    var
        Customer: Record Customer;
        FRCIIXMLBuilder: Codeunit "CII XML Builder";
        CustomerNoFieldRef: FieldRef;
        CustomerNo: Code[20];
    begin
        if not FRCIIXMLBuilder.TryGetCustomerNoFieldRef(SourceDocumentHeader, CustomerNoFieldRef) then
            exit;

        CustomerNo := CustomerNoFieldRef.Value();
        if CustomerNo = '' then
            exit;

        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, CustomerNo) then
            exit;

        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme", "VAT Registration No.", "Country/Region Code");
        if not Customer.Get(CustomerNo) then
            exit;

        if Customer."FR Electronic Address" <> '' then begin
            if Customer."FR Elec. Address Scheme" = Customer."FR Elec. Address Scheme"::" " then
                Error(GetBuyerElectronicAddressSchemeRequiredError(Customer."No."));
            exit;
        end;
        if IsFrenchCustomer(Customer) and (Customer."VAT Registration No." <> '') then
            exit;

        Error(GetBuyerElectronicAddressRequiredError(Customer."No."));
    end;

    procedure IsFrenchCustomer(Customer: Record Customer): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        if Customer."Country/Region Code" = '' then
            exit(true);

        CompanyInformation.SetLoadFields("Country/Region Code");
        CompanyInformation.Get();
        exit(Customer."Country/Region Code" = CompanyInformation."Country/Region Code");
    end;

    procedure HasServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]): Boolean
    var
        ServiceParticipant: Record "Service Participant";
    begin
        exit(HasServiceParticipantAddress(EDocumentServiceCode, ParticipantType, ParticipantNo, ServiceParticipant));
    end;

    procedure HasServiceParticipantAddress(EDocumentServiceCode: Code[20]; ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20]; var ServiceParticipant: Record "Service Participant"): Boolean
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
            ParticipantAddressErrorInfo.RecordId(ServiceParticipant.RecordId());
            ParticipantAddressErrorInfo.PageNo(Page::"Service Participants");
            ParticipantAddressErrorInfo.AddNavigationAction(ShowServiceParticipantLbl);
            Error(ParticipantAddressErrorInfo);
        end;

        exit(HasIdentifier);
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
        exit(StrSubstNo(BuyerElectronicAddressRequiredErr, Customer.FieldCaption("FR Electronic Address"), Customer.FieldCaption("VAT Registration No."), ServiceParticipant.TableCaption(), Customer.TableCaption(), CustomerNo));
    end;

    internal procedure GetBuyerElectronicAddressSchemeRequiredError(CustomerNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        exit(StrSubstNo(BuyerElectronicAddressSchemeRequiredErr, Customer.FieldCaption("FR Elec. Address Scheme"), Customer.TableCaption(), CustomerNo));
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
        BuyerElectronicAddressRequiredErr: Label '%1, French %2, or a %3 identifier must be specified for %4 %5 for French e-invoicing.', Comment = '%1 = Electronic Address field caption, %2 = VAT Registration No. field caption, %3 = Service Participant table caption, %4 = Customer table caption, %5 = Customer No.';
        BuyerElectronicAddressSchemeRequiredErr: Label '%1 must be specified for %2 %3 for French e-invoicing.', Comment = '%1 = Electronic Address Scheme field caption, %2 = Customer table caption, %3 = Customer No.';
        SellerCountryCodeRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = Country/Region Code field caption, %2 = Company Information table caption';
        ServiceParticipantAddressIncompleteErr: Label '%1 and %2 must both be specified for French electronic invoicing.', Comment = '%1 = Participant Identifier field caption, %2 = French Identifier Scheme field caption';
        ShowServiceParticipantLbl: Label 'Show Service Participant';
}
