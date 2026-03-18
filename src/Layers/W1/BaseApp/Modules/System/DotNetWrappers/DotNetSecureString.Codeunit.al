namespace System.Security.Encryption;

using System;

codeunit 3044 DotNet_SecureString
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DotNetSecureString: DotNet SecureString;
        String: Text;

    procedure SecureString()
    begin
        DotNetSecureString := DotNetSecureString.SecureString();
    end;

    procedure AppendChar(C: Char)
    begin
        DotNetSecureString.AppendChar(C);
        String += C;
    end;

    [Scope('OnPrem')]
    procedure GetSecureString(var DotNetSecureString2: DotNet SecureString)
    begin
        DotNetSecureString2 := DotNetSecureString;
    end;

    [Scope('OnPrem')]
    procedure SetSecureString(var DotNetSecureString2: DotNet SecureString)
    begin
        DotNetSecureString := DotNetSecureString2;
    end;

    [Scope('OnPrem')]
    procedure GetPlainText(): Text
    begin
        exit(String);
    end;

}

