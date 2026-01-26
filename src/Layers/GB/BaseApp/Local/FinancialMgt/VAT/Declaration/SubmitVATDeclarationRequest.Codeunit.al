#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System;
using System.IO;
using System.Xml;

codeunit 10522 "Submit VAT Declaration Request"
{
    TableNo = "VAT Report Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to GovTalk app';
    ObsoleteTag = '27.0';
    trigger OnRun()
    var
        GovTalkMessage: Record GovTalkMessage;
        BodyXMLNode: DotNet XmlNode;
        GovTalkRequestXMLNode: DotNet XmlNode;
        IRMarkXMLNode: DotNet XmlNode;
    begin
        GovTalkMessage.Get(Rec."VAT Report Config. Code", Rec."No.");
        if GovTalkMessageManagement.CreateBlankGovTalkXmlMessage(GovTalkMessageXMLNode, BodyXMLNode, Rec, 'request', 'submit', true) then begin
            InsertVATDeclarationRequestIRHeader(GovTalkMessage, BodyXMLNode, GovTalkRequestXMLNode, IRMarkXMLNode);
            InsertVATDeclarationRequestDetails(GovTalkMessage, GovTalkRequestXMLNode, IRMarkXMLNode);
            if not GovTalkMessageManagement.SubmitGovTalkRequest(Rec, GovTalkMessageXMLNode) then
                Error(SubmissionFailedErr);
        end;
    end;

    var
        GovTalkMessageManagement: Codeunit GovTalkMessageManagement;
        VATDeclarationNameSpaceTxt: Label 'http://www.govtalk.gov.uk/taxation/vat/vatdeclaration/2', Locked = true;
        XMLDOMManagement: Codeunit "XML DOM Management";
        GovTalkMessageXMLNode: DotNet XmlNode;
        GovTalkNameSpaceTxt: Label 'http://www.govtalk.gov.uk/CM/envelope', Locked = true;
        SubmissionFailedErr: Label 'Could not submit the report to the GovTalk service. This might be because the URL to the service is incorrect, or the service is unavailable right now.';

    local procedure InsertVATDeclarationRequestIRHeader(GovTalkMessage: Record GovTalkMessage; var BodyXMLNode: DotNet XmlNode; var GovTalkRequestXMLNode: DotNet XmlNode; var IRmarkXMLNode: DotNet XmlNode)
    var
        CompanyInformation: Record "Company Information";
        IREnvelopeXMLNode: DotNet XmlNode;
        IRHeaderXMLNode: DotNet XmlNode;
        KeysXMLNode: DotNet XmlNode;
        VATRegNoXMLNode: DotNet XmlNode;
        DummyXMLNode: DotNet XmlNode;
    begin
        CompanyInformation.FindFirst();
        XMLDOMManagement.AddElementWithPrefix(BodyXMLNode, 'IRenvelope', '', 'vat', VATDeclarationNameSpaceTxt, IREnvelopeXMLNode);
        XMLDOMManagement.AddElementWithPrefix(IREnvelopeXMLNode, 'IRheader', '', 'vat', VATDeclarationNameSpaceTxt, IRHeaderXMLNode);
        XMLDOMManagement.AddElementWithPrefix(IRHeaderXMLNode, 'Keys', '', 'vat', VATDeclarationNameSpaceTxt, KeysXMLNode);
        XMLDOMManagement.AddElementWithPrefix(KeysXMLNode, 'Key',
          GovTalkMessageManagement.FormatVATRegNo(CompanyInformation."Country/Region Code", CompanyInformation."VAT Registration No."),
          'vat', VATDeclarationNameSpaceTxt, VATRegNoXMLNode);
        XMLDOMManagement.AddAttribute(VATRegNoXMLNode, 'Type', 'VATRegNo');
        XMLDOMManagement.AddElementWithPrefix(IRHeaderXMLNode, 'PeriodID', GovTalkMessage.PeriodID, 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
        XMLDOMManagement.AddElementWithPrefix(IRHeaderXMLNode, 'PeriodStart',
          Format(GovTalkMessage.PeriodStart, 0, 9), 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
        XMLDOMManagement.AddElementWithPrefix(IRHeaderXMLNode, 'PeriodEnd',
          Format(GovTalkMessage.PeriodEnd, 0, 9), 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
        XMLDOMManagement.AddElementWithPrefix(IRHeaderXMLNode, 'IRmark', '', 'vat', VATDeclarationNameSpaceTxt, IRmarkXMLNode);
        XMLDOMManagement.AddAttribute(IRmarkXMLNode, 'Type', 'generic');
        XMLDOMManagement.AddElementWithPrefix(IRHeaderXMLNode, 'Sender', 'Individual', 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
        XMLDOMManagement.AddElementWithPrefix(IREnvelopeXMLNode, 'VATDeclarationRequest', '', 'vat', VATDeclarationNameSpaceTxt, GovTalkRequestXMLNode);
    end;

    local procedure InsertVATDeclarationRequestDetails(GovTalkMessage: Record GovTalkMessage; var GovTalkRequestXMLNode: DotNet XmlNode; var IRmarkXMLNode: DotNet XmlNode)
    var
        ChildXMLBuffer: Record "XML Buffer";
        HMRCSubmissionHelpers: Codeunit HMRCSubmissionHelpers;
        DummyXMLNode: DotNet XmlNode;
        XmlDoc: DotNet XmlDocument;
    begin
        ChildXMLBuffer.SetRange("Parent Entry No.", GovTalkMessage.RootXMLBuffer);
        if ChildXMLBuffer.FindSet() then
            repeat
                XMLDOMManagement.AddElementWithPrefix(GovTalkRequestXMLNode,
                  ChildXMLBuffer.Name, ChildXMLBuffer.Value, 'vat', VATDeclarationNameSpaceTxt, DummyXMLNode);
            until ChildXMLBuffer.Next() = 0;
        XmlDoc := GovTalkMessageXMLNode.ParentNode;
        XmlDoc.PreserveWhitespace := true;
        IRmarkXMLNode.InnerText := HMRCSubmissionHelpers.CreateIRMark(XmlDoc, GovTalkNameSpaceTxt, VATDeclarationNameSpaceTxt);
    end;
}
#endif

