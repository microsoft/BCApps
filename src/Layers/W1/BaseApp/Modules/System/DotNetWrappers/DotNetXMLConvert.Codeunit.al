namespace System.Xml;

using System;
using System.DateTime;

codeunit 3005 DotNet_XMLConvert
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetXMLConvert: DotNet XmlConvert;

    procedure ToDateTimeOffset(DateText: Text; var DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset)
    begin
        DotNet_DateTimeOffset.SetDateTimeOffset(DotNetXMLConvert.ToDateTimeOffset(DateText))
    end;

    [Scope('OnPrem')]
    procedure GetXMLConvert(var DotNetXMLConvert2: DotNet XmlConvert)
    begin
        DotNetXMLConvert2 := DotNetXMLConvert
    end;

    [Scope('OnPrem')]
    procedure SetXMLConvert(DotNetXMLConvert2: DotNet XmlConvert)
    begin
        DotNetXMLConvert := DotNetXMLConvert2
    end;
}

