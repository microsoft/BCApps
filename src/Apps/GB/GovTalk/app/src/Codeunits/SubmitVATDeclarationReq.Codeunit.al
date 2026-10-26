// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Company;
using System.IO;

codeunit 10586 "Submit VAT Declaration Req."
{
    TableNo = "VAT Report Header";
    trigger OnRun()
    var
        GovTalkMessageXmlElement: XmlElement;
    begin
        if CreateVATDeclarationRequestMessage(Rec, GovTalkMessageXmlElement) then begin
            // The IRmark is calculated over the unindented message, so it must be submitted without indentation.
            if not GovTalkMessageManagement.SubmitGovTalkRequest(Rec, GovTalkMessageXmlElement, true) then
                Error(SubmissionFailedErr);
            Session.LogSecurityAudit(GovTalkServiceNameTxt, SecurityOperationResult::Success, StrSubstNo(SecurityAuditVATSubmittedTxt, Rec."No."), AuditCategory::CustomerFacing);
        end;
    end;

    var
        GovTalkMessageManagement: Codeunit "GovTalk Message Management";
        GovTalkXMLHelper: Codeunit "GovTalk XML Helper";
        VATDeclarationNameSpaceTxt: Label 'http://www.govtalk.gov.uk/taxation/vat/vatdeclaration/2', Locked = true;
        GovTalkNameSpaceTxt: Label 'http://www.govtalk.gov.uk/CM/envelope', Locked = true;
        SubmissionFailedErr: Label 'Could not submit the report to the GovTalk service. This might be because the URL to the service is incorrect, or the service is unavailable right now.';
        GovTalkServiceNameTxt: Label 'GovTalk', Locked = true;
        SecurityAuditVATSubmittedTxt: Label 'VAT Declaration %1 was submitted to HMRC via the GovTalk service.', Locked = true, Comment = '%1 - VAT Report No.';

    internal procedure CreateVATDeclarationRequestMessage(VATReportHeader: Record "VAT Report Header"; var GovTalkMessageXmlElement: XmlElement): Boolean
    var
        GovTalkMessage: Record "GovTalk Message";
        BodyXmlElement: XmlElement;
        GovTalkRequestXmlElement: XmlElement;
        IRMarkXmlElement: XmlElement;
    begin
        GovTalkMessage.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.");
        if not GovTalkMessageManagement.CreateBlankGovTalkXmlMessage(GovTalkMessageXmlElement, BodyXmlElement, VATReportHeader, 'request', 'submit', true) then
            exit(false);
        InsertVATDeclarationRequestIRHeader(GovTalkMessage, BodyXmlElement, GovTalkRequestXmlElement, IRMarkXmlElement);
        InsertVATDeclarationRequestDetails(GovTalkMessage, GovTalkMessageXmlElement, GovTalkRequestXmlElement, IRMarkXmlElement);
        exit(true);
    end;

    local procedure InsertVATDeclarationRequestIRHeader(GovTalkMessage: Record "GovTalk Message"; var BodyXmlElement: XmlElement; var GovTalkRequestXmlElement: XmlElement; var IRmarkXmlElement: XmlElement)
    var
        CompanyInformation: Record "Company Information";
        IREnvelopeXmlElement: XmlElement;
        IRHeaderXmlElement: XmlElement;
        KeysXmlElement: XmlElement;
        VATRegNoXmlElement: XmlElement;
        DummyXmlElement: XmlElement;
    begin
        CompanyInformation.FindFirst();
        GovTalkXMLHelper.AddElement(BodyXmlElement, 'IRenvelope', '', VATDeclarationNameSpaceTxt, IREnvelopeXmlElement);
        GovTalkXMLHelper.AddNamespaceDeclaration(IREnvelopeXmlElement, 'vat', VATDeclarationNameSpaceTxt);
        GovTalkXMLHelper.AddElement(IREnvelopeXmlElement, 'IRheader', '', VATDeclarationNameSpaceTxt, IRHeaderXmlElement);
        GovTalkXMLHelper.AddElement(IRHeaderXmlElement, 'Keys', '', VATDeclarationNameSpaceTxt, KeysXmlElement);
        GovTalkXMLHelper.AddElement(KeysXmlElement, 'Key',
          GovTalkMessageManagement.FormatVATRegNo(CompanyInformation."Country/Region Code", CompanyInformation."VAT Registration No."),
          VATDeclarationNameSpaceTxt, VATRegNoXmlElement);
        VATRegNoXmlElement.SetAttribute('Type', 'VATRegNo');
        GovTalkXMLHelper.AddElement(IRHeaderXmlElement, 'PeriodID', GovTalkMessage.PeriodID, VATDeclarationNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(IRHeaderXmlElement, 'PeriodStart',
          Format(GovTalkMessage.PeriodStart, 0, 9), VATDeclarationNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(IRHeaderXmlElement, 'PeriodEnd',
          Format(GovTalkMessage.PeriodEnd, 0, 9), VATDeclarationNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(IRHeaderXmlElement, 'IRmark', '', VATDeclarationNameSpaceTxt, IRmarkXmlElement);
        IRmarkXmlElement.SetAttribute('Type', 'generic');
        GovTalkXMLHelper.AddElement(IRHeaderXmlElement, 'Sender', 'Individual', VATDeclarationNameSpaceTxt, DummyXmlElement);
        GovTalkXMLHelper.AddElement(IREnvelopeXmlElement, 'VATDeclarationRequest', '', VATDeclarationNameSpaceTxt, GovTalkRequestXmlElement);
    end;

    local procedure InsertVATDeclarationRequestDetails(GovTalkMessage: Record "GovTalk Message"; GovTalkMessageXmlElement: XmlElement; var GovTalkRequestXmlElement: XmlElement; var IRmarkXmlElement: XmlElement)
    var
        ChildXMLBuffer: Record "XML Buffer";
        HMRCSubmissionHelpers: Codeunit "HMRC Submission Helpers";
        DummyXmlElement: XmlElement;
        GovTalkXmlDocument: XmlDocument;
    begin
        ChildXMLBuffer.SetRange("Parent Entry No.", GovTalkMessage.RootXMLBuffer);
        if ChildXMLBuffer.FindSet() then
            repeat
                GovTalkXMLHelper.AddElement(GovTalkRequestXmlElement,
                  ChildXMLBuffer.Name, ChildXMLBuffer.Value, VATDeclarationNameSpaceTxt, DummyXmlElement);
            until ChildXMLBuffer.Next() = 0;
        GovTalkMessageXmlElement.GetDocument(GovTalkXmlDocument);
        GovTalkXMLHelper.SetInnerText(IRmarkXmlElement, HMRCSubmissionHelpers.CreateIRMark(GovTalkXmlDocument, GovTalkNameSpaceTxt, VATDeclarationNameSpaceTxt));
    end;
}
