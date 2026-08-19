// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

codeunit 10991 "EDoc. Helpers"
{
    Access = Internal;

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

    procedure CheckSellerCountryCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation."Country/Region Code" = '' then
            Error(SellerCountryCodeRequiredErr);
    end;

    procedure CheckBuyerElectronicAddress(var SourceDocumentHeader: RecordRef)
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

        if not Customer.Get(CustomerNo) then
            exit;

        if Customer."FR Electronic Address" = '' then
            Error(BuyerElectronicAddressRequiredErr, Customer."No.");
    end;

    var
        SIRENRequiredErr: Label 'Registration No. must be specified in Company Information for French e-invoicing.';
        SIRETRequiredErr: Label 'SIRET No. must be specified in Company Information for French e-invoicing.';
        BuyerElectronicAddressRequiredErr: Label 'Electronic Address must be specified for Customer %1 for French e-invoicing.', Comment = '%1 = Customer No.';
        SellerCountryCodeRequiredErr: Label 'Country/Region Code must be specified in Company Information for French e-invoicing.';
}
