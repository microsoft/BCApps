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
    Permissions = tabledata "E-Document" = m,
                  tabledata "E-Document Service Status" = m;

    [EventSubscriber(ObjectType::Table, Database::"E-Document", 'OnBeforeModifyEvent', '', false, false)]
    local procedure SetClearanceDateOnModify(var Rec: Record "E-Document"; var xRec: Record "E-Document"; RunTrigger: Boolean)
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocumentService: Record "E-Document Service";
    begin
        if not GetFrenchEDocumentService(Rec, EDocumentService, EDocumentServiceStatus) then
            exit;

        case EDocumentServiceStatus.Status of
            EDocumentServiceStatus.Status::Approved,
            EDocumentServiceStatus.Status::Cleared:
                Rec."Clearance Date" := CurrentDateTime();
            EDocumentServiceStatus.Status::Rejected,
            EDocumentServiceStatus.Status::"Not Cleared":
                Rec."Clearance Date" := 0DT;
        end;
    end;

    local procedure IsFrenchElectronicDocumentFormat(EDocumentFormat: Enum "E-Document Format"): Boolean
    begin
        exit(
            EDocumentFormat in
            [EDocumentFormat::"E-Reporting FR", EDocumentFormat::"Peppol BIS 3.0 FR", EDocumentFormat::"Factur-X FR"]);
    end;

    procedure GetFrenchEDocumentService(EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var EDocumentServiceStatus: Record "E-Document Service Status"): Boolean
    begin
        EDocumentService.SetLoadFields("Document Format");
        if (EDocument.Service <> '') and EDocumentService.Get(EDocument.Service) then
            if IsFrenchElectronicDocumentFormat(EDocumentService."Document Format") then
                exit(EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code));

        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        if EDocumentServiceStatus.FindSet() then
            repeat
                if EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code") then
                    if IsFrenchElectronicDocumentFormat(EDocumentService."Document Format") then
                        exit(true);
            until EDocumentServiceStatus.Next() = 0;

        exit(false);
    end;

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
            Error(SIRENRequiredErr);
    end;

    procedure CheckSIRETNotEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."SIRET No." = '' then
            Error(SIRETRequiredErr);
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

        Error(SellerElectronicAddressRequiredErr);
    end;

    procedure CheckSellerCountryCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" = '' then
            Error(SellerCountryCodeRequiredErr);
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

        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme", "VAT Registration No.");
        if not Customer.Get(CustomerNo) then
            exit;

        if HasServiceParticipantAddress(EDocumentServiceCode, Enum::"E-Document Source Type"::Customer, Customer."No.") then
            exit;
        if Customer."FR Electronic Address" <> '' then begin
            if Customer."FR Elec. Address Scheme" = Customer."FR Elec. Address Scheme"::" " then
                Error(BuyerElectronicAddressSchemeRequiredErr, Customer."No.");
            exit;
        end;
        if Customer."VAT Registration No." <> '' then
            exit;

        Error(BuyerElectronicAddressRequiredErr, Customer."No.");
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
            ParticipantAddressErrorInfo.Message(
                StrSubstNo(ServiceParticipantAddressIncompleteErr, ServiceParticipant.FieldCaption("Participant Identifier"), ServiceParticipant.FieldCaption("FR Identifier Scheme")));
            ParticipantAddressErrorInfo.RecordId(ServiceParticipant.RecordId());
            ParticipantAddressErrorInfo.PageNo(Page::"Service Participants");
            Error(ParticipantAddressErrorInfo);
        end;

        exit(HasIdentifier);
    end;

    var
        SIRENRequiredErr: Label 'Registration No. must be specified in Company Information for French e-invoicing.';
        SIRETRequiredErr: Label 'SIRET No. must be specified in Company Information for French e-invoicing.';
        SellerElectronicAddressRequiredErr: Label 'SIRET No., Registration No., VAT Registration No., or a Service Participant identifier must be specified for the company for French e-invoicing.';
        BuyerElectronicAddressRequiredErr: Label 'Electronic Address, VAT Registration No., or a Service Participant identifier must be specified for Customer %1 for French e-invoicing.', Comment = '%1 = Customer No.';
        BuyerElectronicAddressSchemeRequiredErr: Label 'Electronic Address Scheme must be specified for Customer %1 for French e-invoicing.', Comment = '%1 = Customer No.';
        SellerCountryCodeRequiredErr: Label 'Country/Region Code must be specified in Company Information for French e-invoicing.';
        ServiceParticipantAddressIncompleteErr: Label '%1 and %2 must both be specified for French electronic invoicing.', Comment = '%1 = Participant Identifier field caption, %2 = French Identifier Scheme field caption';
}
