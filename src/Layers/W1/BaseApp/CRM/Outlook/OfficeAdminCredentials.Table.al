// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Security.Encryption;

table 1612 "Office Admin. Credentials"
{
    Caption = 'Office Admin. Credentials';
    DataClassification = CustomerContent;
    Permissions = TableData "Office Admin. Credentials" = r;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; Email; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            NotBlank = true;
        }
        field(3; Password; Text[250])
        {
            Caption = 'Password';
            ExtendedDatatype = Masked;
            NotBlank = true;
        }
        field(4; Endpoint; Text[250])
        {
            Caption = 'Endpoint';
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
        if Endpoint = '' then
            Validate(Endpoint, DefaultEndpoint());
    end;

    trigger OnModify()
    begin
        if Endpoint = '' then
            Validate(Endpoint, DefaultEndpoint());
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    procedure DefaultEndpoint(): Text[250]
    begin
        exit('https://ps.outlook.com/powershell-liveid');
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SavePassword(PasswordText: Text)
    var
        PasswordAsSecretText: SecretText;
    begin
        PasswordText := DelChr(PasswordText, '=', ' ');
        if Password = '' then
            Password := CreateGuid();

        PasswordAsSecretText := PasswordText;
        IsolatedStorageManagement.Set(Password, PasswordAsSecretText, DATASCOPE::Company);
        Modify();
    end;

#if not CLEAN25
    [NonDebuggable]
    [Obsolete('Replaced by GetPasswordAsSecretText.', '25.0')]
    [Scope('OnPrem')]
    procedure GetPassword(): Text
    begin
        exit(GetPasswordAsSecretText().Unwrap());
    end;
#endif

    [Scope('OnPrem')]
    procedure GetPasswordAsSecretText(): SecretText
    var
        Value: SecretText;
    begin
        if Password <> '' then
            IsolatedStorageManagement.Get(Password, DATASCOPE::Company, Value);

        exit(Value);
    end;
}

