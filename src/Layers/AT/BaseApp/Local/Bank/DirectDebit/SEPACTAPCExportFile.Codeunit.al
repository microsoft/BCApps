// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;
using System.Utilities;

codeunit 11100 "SEPA CT APC-Export File"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAccount: Record "Bank Account";
    begin
        Rec.LockTable();
        BankAccount.Get(Rec."Bal. Account No.");
        if Export(Rec, BankAccount.GetPaymentExportXMLPortID()) then
            Rec.ModifyAll("Exported to Payment File", true);
    end;

    local procedure Export(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer): Boolean
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, GenJnlLine);
        PostProcessXMLDocument(TempBlob, XMLPortID);
        CreditTransferRegister.FindLast();
        exit(FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', CreditTransferRegister.Identifier), true) <> '');
    end;

    [Scope('OnPrem')]
    procedure PostProcessXMLDocument(var TempBlob: Codeunit "Temp Blob"; XMLPortID: Integer)
    var
        XMLDoc: XmlDocument;
        XMLNsMgr: XmlNamespaceManager;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);

        XmlDocument.ReadFrom(InStr, XMLDoc);
        XMLNsMgr.NameTable(XMLDoc.NameTable());
        case XMLPortID of
            XMLPort::"SEPA CT pain.001.001.09":
                XMLNsMgr.AddNamespace('ns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09');
            else
                XMLNsMgr.AddNamespace('ns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03');
        end;
        ApplyApcRequirements(XMLDoc, XMLNsMgr);
        RemoveWhitespaceNodes(XMLDoc);

        Clear(TempBlob);
        WriteXMLDocument(XMLDoc, TempBlob);
    end;

    local procedure ApplyApcRequirements(var XMLDoc: XmlDocument; XMLNsMgr: XmlNamespaceManager)
    var
        NodeList: XmlNodeList;
        XMLNode: XmlNode;
    begin
        // Remove all PstlAdr nodes
        if XMLDoc.SelectNodes('//ns:PstlAdr', XMLNsMgr, NodeList) then
            foreach XMLNode in NodeList do
                XMLNode.Remove();

        // Remove Nm from InitgPty
        if XMLDoc.SelectSingleNode('//ns:InitgPty/ns:Nm', XMLNsMgr, XMLNode) then
            XMLNode.Remove();
    end;

    local procedure RemoveWhitespaceNodes(var XMLDoc: XmlDocument)
    var
        NodeList: XmlNodeList;
        XMLNode: XmlNode;
        WhitespaceChars: Text[4];
    begin
        // The document is written with indentation, so the whitespace-only text nodes kept by ReadFrom are dropped first.
        WhitespaceChars[1] := 32;
        WhitespaceChars[2] := 9;
        WhitespaceChars[3] := 10;
        WhitespaceChars[4] := 13;
        if XMLDoc.SelectNodes('//text()', NodeList) then
            foreach XMLNode in NodeList do
                RemoveIfWhitespace(XMLNode, WhitespaceChars);
        NodeList := XMLDoc.GetChildNodes();
        foreach XMLNode in NodeList do
            RemoveIfWhitespace(XMLNode, WhitespaceChars);
    end;

    local procedure RemoveIfWhitespace(var XMLNode: XmlNode; WhitespaceChars: Text)
    begin
        if XMLNode.IsXmlText() then
            if DelChr(XMLNode.AsXmlText().Value(), '=', WhitespaceChars) = '' then
                XMLNode.Remove();
    end;

    local procedure WriteXMLDocument(var XMLDoc: XmlDocument; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        XMLDoc.WriteTo(OutStr);
    end;
}
