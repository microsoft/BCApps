// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.Encryption;

codeunit 3750 DotNetHelper_SecureString
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        SecureStringSizeLimitErr: Label 'SecureString exceeds size limitation, check documentation on dotnet 4.7.2.';

    procedure SecureStringFromString(var DotNet_SecureString: Codeunit DotNet_SecureString; String: Text)
    var
        I: Integer;
        Length: Integer;
    begin
        Length := StrLen(String);
        if Length > 65536 then
            Error(SecureStringSizeLimitErr);

        DotNet_SecureString.SecureString();
        for I := 1 to Length do
            DotNet_SecureString.AppendChar(String[I]);
    end;
}

