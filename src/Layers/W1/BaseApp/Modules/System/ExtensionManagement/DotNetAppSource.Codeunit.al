namespace System.Apps;

codeunit 3021 DotNet_AppSource
{

    trigger OnRun()
    begin
    end;

    var
        [RunOnClient]
        DotNetAppSource: DotNet AppSource;

    [Scope('OnPrem')]
    procedure IsAvailable(): Boolean
    begin
        // do not make external
        exit(DotNetAppSource.IsAvailable())
    end;

    [Scope('OnPrem')]
    procedure Create()
    begin
        // do not make external
        DotNetAppSource := DotNetAppSource.Create();
    end;

    [Scope('OnPrem')]
    procedure ShowAppSource()
    begin
        // do not make external
        DotNetAppSource.ShowAppSource();
    end;

    [Scope('OnPrem')]
    procedure GetAppSource(var DotNetAppSource2: DotNet AppSource)
    begin
        DotNetAppSource2 := DotNetAppSource;
    end;

    [Scope('OnPrem')]
    procedure SetAppSource(DotNetAppSource2: DotNet AppSource)
    begin
        DotNetAppSource := DotNetAppSource2
    end;
}

