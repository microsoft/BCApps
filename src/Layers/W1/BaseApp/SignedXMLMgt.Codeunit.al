// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Xml;

using System;

codeunit 6227 "Signed XML Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure CheckXmlStreamSignature(XmlStream: InStream; PublicKey: Text): Boolean
    var
        XmlDocument: DotNet XmlDocument;
    begin
        XmlDocument := XmlDocument.XmlDocument();
        XmlDocument.Load(XmlStream);
        exit(CheckXmlSignature(XmlDocument, PublicKey));
    end;

    procedure CheckXmlTextSignature(XmlText: Text; PublicKey: Text): Boolean
    var
        XmlDocument: DotNet XmlDocument;
    begin
        XmlDocument := XmlDocument.XmlDocument();
        XmlDocument.LoadXml(XmlText);
        exit(CheckXmlSignature(XmlDocument, PublicKey));
    end;

    [Scope('OnPrem')]
    procedure CheckXmlSignature(XmlDocument: DotNet XmlDocument; PublicKey: Text): Boolean
    var
        Convert: DotNet Convert;
        RSAKey: DotNet RSACryptoServiceProvider;
        SignedXml: DotNet SignedXml;
        SignatureNode: DotNet XmlNode;
        XmlNamespaceManager: DotNet XmlNamespaceManager;
    begin
        XmlNamespaceManager := XmlNamespaceManager.XmlNamespaceManager(XmlDocument.NameTable);
        XmlNamespaceManager.AddNamespace('xmlsig', 'http://www.w3.org/2000/09/xmldsig#');

        SignatureNode := XmlDocument.SelectSingleNode('//xmlsig:Signature', XmlNamespaceManager);
        if IsNull(SignatureNode) then
            exit(false);

        // Import key
        RSAKey := RSAKey.RSACryptoServiceProvider();
        RSAKey.ImportCspBlob(Convert.FromBase64String(PublicKey));

        SignedXml := SignedXml.SignedXml(XmlDocument);
        SignedXml.LoadXml(SignatureNode);
        exit(SignedXml.CheckSignature(RSAKey));
    end;

    procedure SignXmlText(XmlText: Text; PrivateKey: Text): Text
    var
        XmlDocument: DotNet XmlDocument;
        StringWiter: DotNet StringWriter;
        XmlWriter: DotNet XmlTextWriter;
    begin
        XmlDocument := XmlDocument.XmlDocument();
        XmlDocument.LoadXml(XmlText);
        SignXmlDocument(XmlDocument, PrivateKey);

        StringWiter := StringWiter.StringWriter();
        XmlWriter := XmlWriter.XmlTextWriter(StringWiter);
        XmlDocument.WriteTo(XmlWriter);

        exit(StringWiter.ToString());
    end;

    [Scope('OnPrem')]
    procedure SignXmlDocument(XmlDocument: DotNet XmlDocument; PrivateKey: Text)
    var
        Convert: DotNet Convert;
        RSAKey: DotNet RSACryptoServiceProvider;
        SignedXml: DotNet SignedXml;
        DocReference: DotNet Reference;
        Env: DotNet XmlDsigEnvelopedSignatureTransform;
    begin
        // Import key
        RSAKey := RSAKey.RSACryptoServiceProvider();
        RSAKey.ImportCspBlob(Convert.FromBase64String(PrivateKey));

        SignedXml := SignedXml.SignedXml(XmlDocument);
        SignedXml.SigningKey := RSAKey;

        DocReference := DocReference.Reference('');
        DocReference.AddTransform(Env.XmlDsigEnvelopedSignatureTransform());
        SignedXml.AddReference(DocReference);
        SignedXml.ComputeSignature();
        XmlDocument.DocumentElement.AppendChild(XmlDocument.ImportNode(SignedXml.GetXml(), true));
    end;
}

