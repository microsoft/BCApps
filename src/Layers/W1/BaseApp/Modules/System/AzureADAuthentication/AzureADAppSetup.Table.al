namespace System.Azure.Identity;

table 6300 "Azure AD App Setup"
{
    Caption = 'Microsoft Entra App Setup';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "App ID"; Guid)
        {
            Caption = 'App ID';
            NotBlank = true;
        }
#if not CLEANSCHEMA28
        field(2; "Secret Key"; BLOB)
        {
            Caption = 'Secret Key';
            ObsoleteReason = 'The Secret Key has been moved to Isolated Storage. Use GetSecretKeyFromIsolatedStorage/SetSecretKeyToIsolatedStorage to retrieve or set the Secret Key.';
#if CLEAN25
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '17.0';
#endif
        }
#endif
        field(3; "Primary Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Primary Key';
        }
        field(4; "Redirect URL"; Text[150])
        {
            Caption = 'Redirect URL';
        }
        field(5; "Isolated Storage Secret Key"; Guid)
        {
            Caption = 'Isolated Storage Secret Key';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if Count > 1 then
            Error(OnlyOneRecordErr);
    end;

    var
        OnlyOneRecordErr: Label 'There should be only one record for Microsoft Entra App Setup.';
#if not CLEAN25

    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('Replaced by GetSecretKeyFromIsolatedStorageAsSecretText', '25.0')]
    procedure GetSecretKeyFromIsolatedStorage(): Text
    begin
        exit(GetSecretKeyFromIsolatedStorageAsSecretText().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetSecretKeyFromIsolatedStorageAsSecretText() SecretKey: SecretText
    begin
        if not IsNullGuid("Isolated Storage Secret Key") then
            if not IsolatedStorage.Get("Isolated Storage Secret Key", DataScope::Module, SecretKey) then;

        exit(SecretKey);
    end;

    [NonDebuggable]
    local procedure StringToEncryptCanBeEncrypted(ToEncrypt: SecretText): Boolean
    begin
        exit(StrLen(ToEncrypt.Unwrap()) <= 215);
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [Obsolete('Replaced by SetSecretKeyToIsolatedStorage(SecretKey: SecretText)', '25.0')]
    [NonDebuggable]
    procedure SetSecretKeyToIsolatedStorage(SecretKey: Text)
    var
        SecretKeyAsSecretText: SecretText;
    begin
        SecretKeyAsSecretText := SecretKey;
        SetSecretKeyToIsolatedStorage(SecretKeyAsSecretText);
    end;
#endif

    [Scope('OnPrem')]
    procedure SetSecretKeyToIsolatedStorage(SecretKey: SecretText)
    var
        NewSecretGuid: Guid;
    begin
        if not IsNullGuid("Isolated Storage Secret Key") then
            if not IsolatedStorage.Delete("Isolated Storage Secret Key", DataScope::Module) then;

        NewSecretGuid := CreateGuid();

        if (not EncryptionEnabled() or (not StringToEncryptCanBeEncrypted(SecretKey))) then
            IsolatedStorage.Set(NewSecretGuid, SecretKey, DataScope::Module)
        else
            IsolatedStorage.SetEncrypted(NewSecretGuid, SecretKey, DataScope::Module);

        Rec."Isolated Storage Secret Key" := NewSecretGuid;
    end;
}

