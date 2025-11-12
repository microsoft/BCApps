namespace System.Xml;

using System;

codeunit 3040 DotNet_XsltArgumentList
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetXsltArgumentList: DotNet XsltArgumentList;

    [Scope('OnPrem')]
    procedure GetXsltArgumentList(var DotNetXsltArgumentList2: DotNet XsltArgumentList)
    begin
        DotNetXsltArgumentList2 := DotNetXsltArgumentList;
    end;

    [Scope('OnPrem')]
    procedure SetXsltArgumentList(var DotNetXsltArgumentList2: DotNet XsltArgumentList)
    begin
        DotNetXsltArgumentList := DotNetXsltArgumentList2
    end;
}

