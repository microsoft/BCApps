// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Text;
using System.Utilities;

/// <summary>
/// Holds the information for all file accounts that are registered via the SFTP connector
/// </summary>
table 4621 "Ext. SFTP Account"
{
    Caption = 'SFTP Account';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[250])
        {
            Caption = 'Account Name';
            ToolTip = 'Specifies a descriptive name for this SFTP storage account connection.';
        }
        field(4; Hostname; Text[2048])
        {
            Caption = 'Hostname';
            ToolTip = 'Specifies the hostname of the SFTP server.';
        }
        field(5; Port; Integer)
        {
            Caption = 'Port';
            ToolTip = 'Specifies the port number of the SFTP server.';
            InitValue = 22;
            MinValue = 1;
            MaxValue = 65535;
        }
        field(6; "Base Relative Folder Path"; Text[2048])
        {
            Caption = 'Base Relative Folder Path';
            ToolTip = 'Specifies the base folder path on the SFTP server. Use an absolute path starting with / (e.g., /home/user/files or /data/uploads). All file operations will be relative to this path.';
        }
        field(7; Username; Text[256])
        {
            Access = Internal;
            Caption = 'Username';
            ToolTip = 'Specifies the username for authenticating with the SFTP server.';
        }
        field(9; "Password Key"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(10; Disabled; Boolean)
        {
            Caption = 'Disabled';
            ToolTip = 'Specifies if the account is disabled. Accounts are automatically disabled when a sandbox environment is created from production.';
        }
        field(11; "Certificate Key"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(12; "Certificate Password Key"; Guid)
        {
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(13; Fingerprints; Text[1024])
        {
            Caption = 'Fingerprints';
            ToolTip = 'Specifies the known host fingerprints for this SFTP account. Each fingerprint must be prefixed with sha256: or md5:. Multiple fingerprints can be separated with commas.';
            Access = Internal;
            DataClassification = SystemMetadata;
        }
        field(14; "Authentication Type"; Enum "Ext. SFTP Auth Type")
        {
            Caption = 'Authentication Type';
            ToolTip = 'Specifies the authentication method used for this SFTP account. Password uses username and password authentication. Certificate uses SSH key-based authentication.';
            InitValue = Password;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    var
        UnableToGetPasswordMsg: Label 'Unable to get SFTP Account Password.';
        UnableToSetPasswordMsg: Label 'Unable to set SFTP Password.';
        UnableToGetCertificateMsg: Label 'Unable to get SFTP Certificate.';
        UnableToSetCertificateMsg: Label 'Unable to set SFTP Certificate.';
        UnableToGetCertificatePasswordMsg: Label 'Unable to get SFTP Account Certificate Password.';
        UnableToSetCertificatePasswordMsg: Label 'Unable to set SFTP Certificate Password.';

    trigger OnDelete()
    begin
        TryDeleteIsolatedStorageValue(Rec."Password Key");
        TryDeleteIsolatedStorageValue(Rec."Certificate Key");
        TryDeleteIsolatedStorageValue(Rec."Certificate Password Key");
    end;

    internal procedure SetPassword(Password: SecretText)
    begin
        if IsNullGuid(Rec."Password Key") then
            Rec."Password Key" := CreateGuid();

        SetIsolatedStorageValue(Rec."Password Key", Password, UnableToSetPasswordMsg);

        // When setting password, clear certificate authentication 
        // as only one authentication method can be active
        ClearCertificateAuthentication();
    end;

    local procedure ClearCertificateAuthentication()
    begin
        if not IsNullGuid(Rec."Certificate Key") then begin
            TryDeleteIsolatedStorageValue(Rec."Certificate Key");
            Clear(Rec."Certificate Key");
        end;

        if not IsNullGuid(Rec."Certificate Password Key") then begin
            TryDeleteIsolatedStorageValue(Rec."Certificate Password Key");
            Clear(Rec."Certificate Password Key");
        end;
    end;

    internal procedure GetPassword(PasswordKey: Guid): SecretText
    begin
        exit(GetIsolatedStorageValue(PasswordKey, UnableToGetPasswordMsg));
    end;

    [NonDebuggable]
    internal procedure SetCertificate(Certificate: Text)
    begin
        if IsNullGuid(Rec."Certificate Key") then
            Rec."Certificate Key" := CreateGuid();

        if not IsolatedStorage.Set(Format(Rec."Certificate Key"), Certificate, DataScope::Company) then
            Error(UnableToSetCertificateMsg);

        // When setting certificate, clear client secret authentication
        // as only one authentication method can be active
        ClearPasswordAuthentication();
    end;

    local procedure ClearPasswordAuthentication()
    begin
        if IsNullGuid(Rec."Password Key") then
            exit;

        TryDeleteIsolatedStorageValue(Rec."Password Key");
        Clear(Rec."Password Key");
    end;

    [NonDebuggable]
    internal procedure GetCertificate(CertificateKey: Guid) TempBlob: Codeunit "Temp Blob"
    var
        Base64Convert: Codeunit "Base64 Convert";
        CertificateBase64: Text;
        Stream: OutStream;
    begin
        if not IsolatedStorage.Get(Format(CertificateKey), DataScope::Company, CertificateBase64) then
            Error(UnableToGetCertificateMsg);

        TempBlob.CreateOutStream(Stream);
        Base64Convert.FromBase64(CertificateBase64, Stream);
    end;

    internal procedure SetCertificatePassword(CertificatePassword: SecretText)
    begin
        if CertificatePassword.IsEmpty() then begin
            TryDeleteIsolatedStorageValue(Rec."Certificate Password Key");
            Clear(Rec."Certificate Password Key");
            exit;
        end;

        if IsNullGuid(Rec."Certificate Password Key") then
            Rec."Certificate Password Key" := CreateGuid();

        SetIsolatedStorageValue(Rec."Certificate Password Key", CertificatePassword, UnableToSetCertificatePasswordMsg);
    end;

    internal procedure GetCertificatePassword(CertificatePasswordKey: Guid): SecretText
    begin
        exit(GetIsolatedStorageValue(CertificatePasswordKey, UnableToGetCertificatePasswordMsg));
    end;

    local procedure TryDeleteIsolatedStorageValue(StorageKey: Guid)
    begin
        if IsNullGuid(StorageKey) then
            exit;

        if not IsolatedStorage.Contains(Format(StorageKey), DataScope::Company) then
            exit;

        IsolatedStorage.Delete(StorageKey, DataScope::Company);
    end;

    local procedure SetIsolatedStorageValue(StorageKey: Guid; Value: SecretText; ErrorMessage: Text)
    begin
        if not IsolatedStorage.Set(Format(StorageKey), Value, DataScope::Company) then
            Error(ErrorMessage);
    end;

    local procedure GetIsolatedStorageValue(StorageKey: Guid; ErrorMessage: Text) Value: SecretText
    begin
        if not IsolatedStorage.Get(Format(StorageKey), DataScope::Company, Value) then
            Error(ErrorMessage);
    end;

    internal procedure UploadCertificateFile() CertificateBase64: Text
    var
        Base64Convert: Codeunit System.Text."Base64 Convert";
        UploadResult: Boolean;
        InStr: InStream;
        CertificateFilterTxt: Label 'Key Files (*.pk;*.ppk;*.pub)|*.pk;*.ppk;*.pub|All Files (*.*)|*.*';
        FileNotUploadedErr: Label 'Key file was not uploaded.';
    begin
        UploadResult := UploadIntoStream(CertificateFilterTxt, InStr);

        if not UploadResult then
            Error(FileNotUploadedErr);

        CertificateBase64 := Base64Convert.ToBase64(InStr);
        exit(CertificateBase64);
    end;
}