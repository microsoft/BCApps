// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

codeunit 10988 "FR E-Invoice Profile Validator"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Validate(XmlDoc: XmlDocument; IsPPFProfile: Boolean)
    var
        ExpectedProfileID: Text;
    begin
        RequireNode(XmlDoc, '/*[local-name()="CrossDomainAcknowledgementAndResponse" and namespace-uri()="' + RsmNamespaceTok + '"]');
        if IsPPFProfile then
            ExpectedProfileID := PPFInvoiceProfileTok
        else
            ExpectedProfileID := CDVInvoiceProfileTok;

        RequireNodeText(XmlDoc, '/*[local-name()="CrossDomainAcknowledgementAndResponse"]/*[local-name()="ExchangedDocumentContext"]/*[local-name()="GuidelineSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', ExpectedProfileID);
        RequireNode(XmlDoc, '/*[local-name()="CrossDomainAcknowledgementAndResponse"]/*[local-name()="ExchangedDocument"]/*[local-name()="ID"]');
        RequireDateTimeNode(XmlDoc, '/*[local-name()="CrossDomainAcknowledgementAndResponse"]/*[local-name()="ExchangedDocument"]/*[local-name()="IssueDateTime"]/*[local-name()="DateTimeString"]', DateTimeFormatCodeTok);
        RequireNodeText(XmlDoc, '/*[local-name()="CrossDomainAcknowledgementAndResponse"]/*[local-name()="AcknowledgementDocument"]/*[local-name()="TypeCode"]', InformationTypeCodeTok);
        RequireDateTimeNode(XmlDoc, '/*[local-name()="CrossDomainAcknowledgementAndResponse"]/*[local-name()="AcknowledgementDocument"]/*[local-name()="IssueDateTime"]/*[local-name()="DateTimeString"]', DateTimeFormatCodeTok);
        RequireNodeText(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="StatusCode"]', InvoiceReferenceStatusCodeTok);
        RequireNodeText(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="TypeCode"]', InvoiceTypeCodeTok);
        ValidateLifecycleStatus(XmlDoc);

        if IsPPFProfile then
            ValidatePPFProfile(XmlDoc)
        else
            ValidateCDVProfile(XmlDoc);
    end;

    local procedure ValidateLifecycleStatus(XmlDoc: XmlDocument)
    var
        StatusCodeNode: XmlNode;
        StatusCode: Text;
    begin
        if not XmlDoc.SelectSingleNode('//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ProcessConditionCode"]', StatusCodeNode) then
            Error(RequiredProfileNodeErr, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ProcessConditionCode"]');

        StatusCode := StatusCodeNode.AsXmlElement().InnerText();
        case StatusCode of
            AcceptedStatusCodeTok:
                RequireNodeText(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ProcessCondition"]', AcceptedStatusNameTok);
            RefusedStatusCodeTok:
                RequireNodeText(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ProcessCondition"]', RefusedStatusNameTok);
            CollectedStatusCodeTok:
                begin
                    RequireNodeText(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ProcessCondition"]', CollectedStatusNameTok);
                    ValidateCollectedStatus(XmlDoc);
                end;
            else
                Error(UnsupportedLifecycleStatusErr, StatusCode);
        end;
    end;

    local procedure ValidateCollectedStatus(XmlDoc: XmlDocument)
    begin
        RequireNodeText(XmlDoc, '//*[local-name()="SpecifiedDocumentCharacteristic"]/*[local-name()="TypeCode"]', CollectedAmountTypeCodeTok);
        RequireNodeText(XmlDoc, '//*[local-name()="SpecifiedDocumentCharacteristic"]/*[local-name()="ValueChangedIndicator"]/*[local-name()="IndicatorString"]', FalseIndicatorTok);
        RequireNode(XmlDoc, '//*[local-name()="SpecifiedDocumentCharacteristic"]/*[local-name()="ValueAmount"]');
        RequireNode(XmlDoc, '//*[local-name()="SpecifiedDocumentCharacteristic"]/*[local-name()="ValueAmount"]/@currencyID');
        RequireNode(XmlDoc, '//*[local-name()="SpecifiedDocumentCharacteristic"]/*[local-name()="ValuePercent"]');
    end;

    local procedure ValidatePPFProfile(XmlDoc: XmlDocument)
    begin
        RequireTradeParty(XmlDoc, 'SenderTradeParty', '', '', SenderRoleCodeTok);
        RequireTradeParty(XmlDoc, 'IssuerTradeParty', SIRENSchemeTok, '', SellerRoleCodeTok);
        RequireTradeParty(XmlDoc, 'RecipientTradeParty', PPFIdentifierSchemeTok, PPFIdentifierTok, PPFRoleCodeTok);
        RequireDateTimeNode(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ReceiptDateTime"]/*[local-name()="DateTimeString"]', DateTimeFormatCodeTok);
        RequireNodeText(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ReferenceTypeCode"]', PPFInvoiceProfileTok);
        RequireDateTimeNode(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="FormattedIssueDateTime"]/*[local-name()="DateTimeString"]', DateFormatCodeTok);
    end;

    local procedure ValidateCDVProfile(XmlDoc: XmlDocument)
    var
        XmlNode: XmlNode;
    begin
        RequireNodeText(XmlDoc, '//*[local-name()="BusinessProcessSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', RegulatedBusinessProcessTok);
        if XmlDoc.SelectSingleNode('//*[local-name()="SenderTradeParty" or local-name()="RecipientTradeParty"]', XmlNode) then
            Error(UnexpectedProfileNodeErr, CDVInvoiceProfileTok);
    end;

    local procedure RequireTradeParty(XmlDoc: XmlDocument; PartyName: Text; ExpectedSchemeID: Text; ExpectedID: Text; ExpectedRoleCode: Text)
    var
        GlobalIDNode: XmlNode;
        SchemeNode: XmlNode;
        RoleNode: XmlNode;
        PartyPath: Text;
    begin
        PartyPath := '/*[local-name()="CrossDomainAcknowledgementAndResponse"]/*[local-name()="ExchangedDocument"]/*[local-name()="' + PartyName + '"]';
        if not XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="GlobalID"]', GlobalIDNode) then
            Error(RequiredProfileNodeErr, PartyPath + '/*[local-name()="GlobalID"]');
        if GlobalIDNode.AsXmlElement().InnerText() = '' then
            Error(EmptyProfileNodeErr, PartyPath + '/*[local-name()="GlobalID"]');
        if (ExpectedID <> '') and (GlobalIDNode.AsXmlElement().InnerText() <> ExpectedID) then
            Error(ProfileValueErr, PartyPath + '/*[local-name()="GlobalID"]', ExpectedID, GlobalIDNode.AsXmlElement().InnerText());
        if not XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="GlobalID"]/@schemeID', SchemeNode) then
            Error(RequiredProfileNodeErr, PartyPath + '/*[local-name()="GlobalID"]/@schemeID');
        if (ExpectedSchemeID <> '') and (SchemeNode.AsXmlAttribute().Value() <> ExpectedSchemeID) then
            Error(ProfileValueErr, PartyPath + '/*[local-name()="GlobalID"]/@schemeID', ExpectedSchemeID, SchemeNode.AsXmlAttribute().Value());
        if not XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="RoleCode"]', RoleNode) then
            Error(RequiredProfileNodeErr, PartyPath + '/*[local-name()="RoleCode"]');
        if RoleNode.AsXmlElement().InnerText() <> ExpectedRoleCode then
            Error(ProfileValueErr, PartyPath + '/*[local-name()="RoleCode"]', ExpectedRoleCode, RoleNode.AsXmlElement().InnerText());
    end;

    local procedure RequireDateTimeNode(XmlDoc: XmlDocument; XPath: Text; ExpectedFormat: Text)
    var
        FormatNode: XmlNode;
    begin
        RequireNode(XmlDoc, XPath);
        if not XmlDoc.SelectSingleNode(XPath + '/@format', FormatNode) then
            Error(RequiredProfileNodeErr, XPath + '/@format');
        if FormatNode.AsXmlAttribute().Value() <> ExpectedFormat then
            Error(ProfileValueErr, XPath + '/@format', ExpectedFormat, FormatNode.AsXmlAttribute().Value());
    end;

    local procedure RequireNode(XmlDoc: XmlDocument; XPath: Text)
    var
        XmlNode: XmlNode;
    begin
        if not XmlDoc.SelectSingleNode(XPath, XmlNode) then
            Error(RequiredProfileNodeErr, XPath);
        if XmlNode.IsXmlElement() then
            if XmlNode.AsXmlElement().InnerText() = '' then
                Error(EmptyProfileNodeErr, XPath);
    end;

    local procedure RequireNodeText(XmlDoc: XmlDocument; XPath: Text; ExpectedValue: Text)
    var
        XmlNode: XmlNode;
    begin
        if not XmlDoc.SelectSingleNode(XPath, XmlNode) then
            Error(RequiredProfileNodeErr, XPath);
        if XmlNode.AsXmlElement().InnerText() <> ExpectedValue then
            Error(ProfileValueErr, XPath, ExpectedValue, XmlNode.AsXmlElement().InnerText());
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100', Locked = true;
        RegulatedBusinessProcessTok: Label 'REGULATED', Locked = true;
        CDVInvoiceProfileTok: Label 'urn.cpro.gouv.fr:1p0:CDV:invoice', Locked = true;
        PPFInvoiceProfileTok: Label 'urn.cpro.gouv.fr:1p0:CDV:einvoicingF2', Locked = true;
        InformationTypeCodeTok: Label '23', Locked = true;
        DateTimeFormatCodeTok: Label '204', Locked = true;
        DateFormatCodeTok: Label '102', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        InvoiceTypeCodeTok: Label '380', Locked = true;
        SenderRoleCodeTok: Label 'WK', Locked = true;
        SellerRoleCodeTok: Label 'SE', Locked = true;
        SIRENSchemeTok: Label '0002', Locked = true;
        PPFIdentifierTok: Label '9998', Locked = true;
        PPFIdentifierSchemeTok: Label '0238', Locked = true;
        PPFRoleCodeTok: Label 'DFH', Locked = true;
        AcceptedStatusCodeTok: Label '205', Locked = true;
        AcceptedStatusNameTok: Label 'Approuvée', Locked = true;
        RefusedStatusCodeTok: Label '210', Locked = true;
        RefusedStatusNameTok: Label 'Refusée', Locked = true;
        CollectedStatusCodeTok: Label '212', Locked = true;
        CollectedStatusNameTok: Label 'Encaissée', Locked = true;
        CollectedAmountTypeCodeTok: Label 'MEN', Locked = true;
        FalseIndicatorTok: Label 'false', Locked = true;
        RequiredProfileNodeErr: Label 'The French invoice lifecycle payload does not contain required profile node %1.', Comment = '%1 = XPath of the required XML node';
        EmptyProfileNodeErr: Label 'The French invoice lifecycle payload contains an empty profile node %1.', Comment = '%1 = XPath of the empty XML node';
        ProfileValueErr: Label 'French invoice lifecycle profile node %1 must have value %2 instead of %3.', Comment = '%1 = XPath, %2 = expected value, %3 = actual value';
        UnexpectedProfileNodeErr: Label 'The French invoice lifecycle payload contains a trade-party node that is not allowed by profile %1.', Comment = '%1 = profile identifier';
        UnsupportedLifecycleStatusErr: Label 'French invoice lifecycle status code %1 is not supported for an outgoing CDAR message.', Comment = '%1 = lifecycle status code';
}