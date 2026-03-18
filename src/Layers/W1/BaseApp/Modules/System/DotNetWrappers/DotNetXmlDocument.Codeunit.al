namespace System.Xml;

using System;

codeunit 3013 DotNet_XmlDocument
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetXmlDocument: DotNet XmlDocument;

    procedure InitXmlDocument()
    begin
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
    end;

    procedure PreserveWhitespace(PreserveWhitespace: Boolean)
    begin
        DotNetXmlDocument.PreserveWhitespace := PreserveWhitespace
    end;

    procedure Load(InStream: InStream)
    begin
        DotNetXmlDocument.Load(InStream)
    end;

    procedure OuterXml(): Text
    begin
        exit(DotNetXmlDocument.OuterXml)
    end;

    [Scope('OnPrem')]
    procedure GetXmlDocument(var DotNetXmlDocument2: DotNet XmlDocument)
    begin
        DotNetXmlDocument2 := DotNetXmlDocument
    end;

    [Scope('OnPrem')]
    procedure SetXmlDocument(DotNetXmlDocument2: DotNet XmlDocument)
    begin
        DotNetXmlDocument := DotNetXmlDocument2
    end;
}

