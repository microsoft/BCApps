namespace System.Xml;

using System;

codeunit 3038 DotNet_XslCompiledTransform
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetXslCompiledTransform: DotNet XslCompiledTransform;

    procedure XslCompiledTransform()
    begin
        DotNetXslCompiledTransform := DotNetXslCompiledTransform.XslCompiledTransform();
    end;

    procedure Load(var DotNet_XmlDocument: Codeunit DotNet_XmlDocument)
    var
        DotNetXPathNavigatable: DotNet IXPathNavigable;
    begin
        DotNet_XmlDocument.GetXmlDocument(DotNetXPathNavigatable);
        DotNetXslCompiledTransform.Load(DotNetXPathNavigatable);
    end;

    procedure Transform(var DotNet_XmlDocument: Codeunit DotNet_XmlDocument; DotNet_XsltArgumentList: Codeunit DotNet_XsltArgumentList; var DestinationStream: OutStream)
    var
        DotNetXPathNavigatable: DotNet IXPathNavigable;
        DotNetXsltArgumentList: DotNet XsltArgumentList;
    begin
        DotNet_XmlDocument.GetXmlDocument(DotNetXPathNavigatable);
        DotNet_XsltArgumentList.GetXsltArgumentList(DotNetXsltArgumentList);
        DotNetXslCompiledTransform.Transform(DotNetXPathNavigatable, DotNetXsltArgumentList, DestinationStream);
    end;

    [Scope('OnPrem')]
    procedure GetXslCompiledTransform(var DotNetXslCompiledTransform2: DotNet XslCompiledTransform)
    begin
        DotNetXslCompiledTransform2 := DotNetXslCompiledTransform;
    end;

    [Scope('OnPrem')]
    procedure SetXslCompiledTransform(DotNetXslCompiledTransform2: DotNet XslCompiledTransform)
    begin
        DotNetXslCompiledTransform := DotNetXslCompiledTransform2;
    end;
}

