namespace System.IO;

using System;

codeunit 3039 DotNet_SeekOrigin
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        DotNetSeekOrigin: DotNet SeekOrigin;

    procedure SeekBegin()
    begin
        DotNetSeekOrigin := DotNetSeekOrigin."Begin";
    end;

    procedure SeekCurrent()
    begin
        DotNetSeekOrigin := DotNetSeekOrigin.Current;
    end;

    procedure SeekEnd()
    begin
        DotNetSeekOrigin := DotNetSeekOrigin."End";
    end;

    [Scope('OnPrem')]
    procedure GetSeekOrigin(var DotNetSeekOrigin2: DotNet SeekOrigin)
    begin
        DotNetSeekOrigin2 := DotNetSeekOrigin;
    end;

    [Scope('OnPrem')]
    procedure SetSeekOrigin(var DotNetSeekOrigin2: DotNet SeekOrigin)
    begin
        DotNetSeekOrigin := DotNetSeekOrigin2;
    end;
}

