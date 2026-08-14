// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

codeunit 10991 "EDoc. Helpers"
{
    Access = Internal;
    Permissions = tabledata "E-Document" = m,
                  tabledata "E-Document Service Status" = m;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure ClassifyDataSensitivity()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"FR E-Invoice Lifecycle");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"FR E-Invoice Lifecycle VAT");
    end;

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
                if Rec."Clearance Date" = 0DT then
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
            RaiseCompanyInformationError(
                CompanyInformation,
                StrSubstNo(SIRENRequiredErr, CompanyInformation.FieldCaption("Registration No."), CompanyInformation.TableCaption()));
    end;

    procedure CheckSIRETNotEmpty()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."SIRET No." = '' then
            RaiseCompanyInformationError(
                CompanyInformation,
                StrSubstNo(SIRETRequiredErr, CompanyInformation.FieldCaption("SIRET No."), CompanyInformation.TableCaption()));
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
        if CompanyInformation.GetVATRegistrationNumber() <> '' then
            exit;

        RaiseCompanyInformationError(
            CompanyInformation,
            StrSubstNo(
                SellerElectronicAddressRequiredErr, CompanyInformation.FieldCaption("SIRET No."),
                CompanyInformation.FieldCaption("Registration No."), CompanyInformation.FieldCaption("VAT Registration No."),
                ServiceParticipant.TableCaption()));
    end;

    procedure CheckSellerCountryCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" = '' then
            RaiseCompanyInformationError(
                CompanyInformation,
                StrSubstNo(SellerCountryCodeRequiredErr, CompanyInformation.FieldCaption("Country/Region Code"), CompanyInformation.TableCaption()));
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef)
    begin
        CheckBuyerElectronicAddress(SourceDocumentHeader, '');
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef; EDocumentServiceCode: Code[20])
    var
        Customer: Record Customer;
        ServiceParticipant: Record "Service Participant";
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

        Customer.SetLoadFields("FR Electronic Address", "FR Elec. Address Scheme", "VAT Registration No.");
        if not Customer.Get(CustomerNo) then
            exit;

        if Customer."FR Electronic Address" <> '' then begin
            if Customer."FR Elec. Address Scheme" = Customer."FR Elec. Address Scheme"::" " then
                RaiseCustomerError(
                    Customer, StrSubstNo(BuyerElectronicAddressSchemeRequiredErr, Customer.FieldCaption("FR Elec. Address Scheme")));
            exit;
        end;
        if Customer."VAT Registration No." <> '' then
            exit;

        RaiseCustomerError(
            Customer,
            StrSubstNo(
                BuyerElectronicAddressRequiredErr, Customer.FieldCaption("FR Electronic Address"),
                Customer.FieldCaption("VAT Registration No."), ServiceParticipant.TableCaption()));
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
            ParticipantAddressErrorInfo.Title(StrSubstNo(SetupIncompleteTitleLbl, ServiceParticipant.TableCaption()));
            ParticipantAddressErrorInfo.Message(
                StrSubstNo(ServiceParticipantAddressIncompleteErr, ServiceParticipant.FieldCaption("Participant Identifier"), ServiceParticipant.FieldCaption("FR Identifier Scheme")));
            ParticipantAddressErrorInfo.DetailedMessage(ParticipantAddressErrorInfo.Message());
            ParticipantAddressErrorInfo.RecordId(ServiceParticipant.RecordId());
            ParticipantAddressErrorInfo.PageNo(Page::"Service Participants");
            ParticipantAddressErrorInfo.AddNavigationAction(StrSubstNo(ShowRecordLbl, ServiceParticipant.TableCaption()));
            Error(ParticipantAddressErrorInfo);
        end;

        exit(HasIdentifier);
    end;

    local procedure RaiseCompanyInformationError(CompanyInformation: Record "Company Information"; ErrorMessage: Text)
    var
        CompanyInformationErrorInfo: ErrorInfo;
    begin
        CompanyInformationErrorInfo.Title(StrSubstNo(SetupIncompleteTitleLbl, CompanyInformation.TableCaption()));
        CompanyInformationErrorInfo.Message(ErrorMessage);
        CompanyInformationErrorInfo.DetailedMessage(ErrorMessage);
        CompanyInformationErrorInfo.RecordId(CompanyInformation.RecordId());
        CompanyInformationErrorInfo.PageNo(Page::"Company Information");
        CompanyInformationErrorInfo.AddNavigationAction(StrSubstNo(ShowRecordLbl, CompanyInformation.TableCaption()));
        Error(CompanyInformationErrorInfo);
    end;

    local procedure RaiseCustomerError(Customer: Record Customer; ErrorMessage: Text)
    var
        CustomerErrorInfo: ErrorInfo;
    begin
        CustomerErrorInfo.Title(StrSubstNo(SetupIncompleteTitleLbl, Customer.TableCaption()));
        CustomerErrorInfo.Message(ErrorMessage);
        CustomerErrorInfo.DetailedMessage(ErrorMessage);
        CustomerErrorInfo.RecordId(Customer.RecordId());
        CustomerErrorInfo.PageNo(Page::"Customer Card");
        CustomerErrorInfo.AddNavigationAction(StrSubstNo(ShowRecordLbl, Customer.TableCaption()));
        Error(CustomerErrorInfo);
    end;

    var
        SetupIncompleteTitleLbl: Label '%1 setup is incomplete', Comment = '%1 = table caption';
        ShowRecordLbl: Label 'Show %1', Comment = '%1 = table caption';
        SIRENRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = Registration No. field caption, %2 = Company Information table caption';
        SIRETRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = SIRET No. field caption, %2 = Company Information table caption';
        SellerElectronicAddressRequiredErr: Label '%1, %2, %3, or a %4 identifier must be specified for the company for French e-invoicing.', Comment = '%1 = SIRET No. field caption, %2 = Registration No. field caption, %3 = VAT Registration No. field caption, %4 = Service Participant table caption';
        BuyerElectronicAddressRequiredErr: Label '%1, %2, or a %3 identifier must be specified for the customer for French e-invoicing.', Comment = '%1 = Electronic Address field caption, %2 = VAT Registration No. field caption, %3 = Service Participant table caption';
        BuyerElectronicAddressSchemeRequiredErr: Label '%1 must be specified for the customer for French e-invoicing.', Comment = '%1 = Electronic Address Scheme field caption';
        SellerCountryCodeRequiredErr: Label '%1 must be specified in %2 for French e-invoicing.', Comment = '%1 = Country/Region Code field caption, %2 = Company Information table caption';
        ServiceParticipantAddressIncompleteErr: Label '%1 and %2 must both be specified for French electronic invoicing.', Comment = '%1 = Participant Identifier field caption, %2 = French Identifier Scheme field caption';
}
