namespace System.Security.Encryption;

using System;

codeunit 3041 DotNet_X509KeyStorageFlags
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetX509KeyStorageFlags: DotNet X509KeyStorageFlags;

    procedure Exportable()
    begin
        DotNetX509KeyStorageFlags := DotNetX509KeyStorageFlags.Exportable;
    end;

    procedure GetX509KeyStorageFlags(var DotNetX509KeyStorageFlags2: DotNet X509KeyStorageFlags)
    begin
        DotNetX509KeyStorageFlags2 := DotNetX509KeyStorageFlags;
    end;

    procedure SetX509KeyStorageFlags(var DotNetX509KeyStorageFlags2: DotNet X509KeyStorageFlags)
    begin
        DotNetX509KeyStorageFlags := DotNetX509KeyStorageFlags2;
    end;
}

