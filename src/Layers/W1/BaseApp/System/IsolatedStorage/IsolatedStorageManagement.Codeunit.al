namespace System.Security.Encryption;

codeunit 1293 "Isolated Storage Management"
{

    trigger OnRun()
    begin
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure Get("Key": Text; Datascope: DataScope; var Value: Text): Boolean
    begin
        Value := '';
        exit(ISOLATEDSTORAGE.Get(CopyStr(Key, 1, 200), Datascope, Value));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure Set("Key": Text; Value: Text; Datascope: DataScope): Boolean
    begin
        if not EncryptionEnabled() then
            exit(ISOLATEDSTORAGE.Set(CopyStr(Key, 1, 200), Value, Datascope));

        exit(ISOLATEDSTORAGE.SetEncrypted(CopyStr(Key, 1, 200), Value, Datascope));
    end;

    [Scope('OnPrem')]
    procedure Delete("Key": Text; Datascope: DataScope): Boolean
    begin
        if not ISOLATEDSTORAGE.Contains(CopyStr(Key, 1, 200), Datascope) then
            exit(false);

        exit(ISOLATEDSTORAGE.Delete(CopyStr(Key, 1, 200), Datascope));
    end;

    [Scope('OnPrem')]
    procedure Contains("Key": Text; Datascope: DataScope): Boolean
    begin
        exit(ISOLATEDSTORAGE.Contains(CopyStr(Key, 1, 200), Datascope));
    end;

    [Scope('OnPrem')]
    procedure Get("Key": Text; Datascope: DataScope; var Value: SecretText): Boolean
    begin
        Clear(Value);
        exit(ISOLATEDSTORAGE.Get(CopyStr(Key, 1, 200), Datascope, Value));
    end;

    [Scope('OnPrem')]
    procedure Set("Key": Text; Value: SecretText; Datascope: DataScope): Boolean
    begin
        if not EncryptionEnabled() then
            exit(ISOLATEDSTORAGE.Set(CopyStr(Key, 1, 200), Value, Datascope));

        exit(ISOLATEDSTORAGE.SetEncrypted(CopyStr(Key, 1, 200), Value, Datascope));
    end;
}

