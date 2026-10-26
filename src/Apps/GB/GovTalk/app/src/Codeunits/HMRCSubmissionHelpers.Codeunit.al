// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using System;

codeunit 10547 "HMRC Submission Helpers"
{
    trigger OnRun()
    begin
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use CreateIRMark with an XmlDocument parameter instead.', '30.0')]
    procedure CreateIRMark(XMLDocument: DotNet XmlDocument; GovTalkNameSpace: Text; TaxNameSpace: Text): Text
    begin
        XMLDocument.PreserveWhitespace := true;
        exit(CreateIRMark(XMLDocument.OuterXml, GovTalkNameSpace, TaxNameSpace));
    end;
#endif

    [Scope('OnPrem')]
    procedure CreateIRMark(GovTalkXmlDocument: XmlDocument; GovTalkNameSpace: Text; TaxNameSpace: Text): Text
    var
        GovTalkXMLHelper: Codeunit "GovTalk XML Helper";
        RootXmlElement: XmlElement;
    begin
        GovTalkXmlDocument.GetRoot(RootXmlElement);
        exit(CreateIRMark(GovTalkXMLHelper.GetXmlAsText(RootXmlElement), GovTalkNameSpace, TaxNameSpace));
    end;

    local procedure CreateIRMark(XmlText: Text; GovTalkNameSpace: Text; TaxNameSpace: Text): Text
    var
        XMLNSMgr: DotNet XmlNamespaceManager;
        XMLDummyNode: DotNet XmlNode;
        XmlC14NTransform: DotNet XmlDsigC14NTransform;
        HashingAlgorithm: DotNet SHA1;
        Convert: DotNet Convert;
        TempXMLDocument: DotNet XmlDocument;
        CRCharacter: Char;
    begin
        CRCharacter := 13;
        TempXMLDocument := TempXMLDocument.XmlDocument();
        TempXMLDocument.PreserveWhitespace := true;
        TempXMLDocument.LoadXml(XmlText);
        TempXMLDocument.PreserveWhitespace := true;
        TempXMLDocument.InnerXml := DelChr(TempXMLDocument.InnerXml, '=', Format(CRCharacter));

        XMLNSMgr := XMLNSMgr.XmlNamespaceManager(TempXMLDocument.NameTable);
        XMLNSMgr.AddNamespace('GovTalk', GovTalkNameSpace);
        XMLNSMgr.AddNamespace('Tax', TaxNameSpace);

        XMLDummyNode := TempXMLDocument.SelectSingleNode('//GovTalk:Body', XMLNSMgr);
        TempXMLDocument.LoadXml(XMLDummyNode.OuterXml);

        XMLDummyNode := TempXMLDocument.SelectSingleNode('//Tax:IRmark', XMLNSMgr);
        XMLDummyNode.ParentNode.RemoveChild(XMLDummyNode);

        XmlC14NTransform := XmlC14NTransform.XmlDsigC14NTransform();
        XmlC14NTransform.LoadInput(TempXMLDocument);

        HashingAlgorithm := HashingAlgorithm.Create();
        exit(Convert.ToBase64String(XmlC14NTransform.GetDigestedOutput(HashingAlgorithm)));
    end;

    [Scope('OnPrem')]
    procedure HashPassword(Password: Text): Text
    var
        Encoding: DotNet Encoding;
        HashingAlgorithm: DotNet MD5;
        Convert: DotNet Convert;
    begin
        Password := LowerCase(Password);
        Password := Encoding.UTF8.GetString(Encoding.GetEncoding(0).GetBytes(Password));
        HashingAlgorithm := HashingAlgorithm.Create();
        exit(Convert.ToBase64String(HashingAlgorithm.ComputeHash(Encoding.GetEncoding(0).GetBytes(Password))));
    end;
}
