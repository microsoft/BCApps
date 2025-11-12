namespace System.Security.Encryption;

using System;

codeunit 3042 DotNet_X509ContentType
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetX509ContentType: DotNet X509ContentType;

    [Scope('OnPrem')]
    procedure Pkcs12()
    begin
        DotNetX509ContentType := DotNetX509ContentType.Pkcs12;
    end;

    [Scope('OnPrem')]
    procedure GetX509ContentType(var DotNetX509ContentType2: DotNet X509ContentType)
    begin
        DotNetX509ContentType2 := DotNetX509ContentType;
    end;

    [Scope('OnPrem')]
    procedure SetX509ContentType(var DotNetX509ContentType2: DotNet X509ContentType)
    begin
        DotNetX509ContentType := DotNetX509ContentType2;
    end;
}

