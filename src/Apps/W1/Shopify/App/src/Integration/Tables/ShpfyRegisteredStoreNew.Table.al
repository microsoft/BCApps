// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Table Shpfy Registered Store (ID 30136).
/// </summary>
table 30138 "Shpfy Registered Store New"
{
    Access = Internal;
    Caption = 'Shopify Registered Store';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Store; Text[250])
        {
            Caption = 'Store';
            DataClassification = SystemMetadata;
        }
        field(2; "Requested Scope"; Text[1024])
        {
            Caption = 'Requested Scope';
            DataClassification = SystemMetadata;
        }
        field(3; "Actual Scope"; Text[1024])
        {
            Caption = 'Actual Scope';
            DataClassification = SystemMetadata;
        }
        field(4; "Review Prompt Date"; Date)
        {
            Caption = 'Review Prompt Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Review Completed"; Boolean)
        {
            Caption = 'Review Completed';
            DataClassification = SystemMetadata;
        }
        field(6; "Token Expires At"; DateTime)
        {
            Caption = 'Token Expires At';
            DataClassification = SystemMetadata;
        }
        field(7; "Refresh Token Expires At"; DateTime)
        {
            Caption = 'Refresh Token Expires At';
            DataClassification = SystemMetadata;
        }
        field(8; "Last Migration Attempt"; DateTime)
        {
            Caption = 'Last Migration Attempt';
            DataClassification = SystemMetadata;
        }
        field(9; "Last Force Refresh At"; DateTime)
        {
            Caption = 'Last Force Refresh At';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; Store)
        {
            Clustered = true;
        }
    }

    internal procedure SetAccessToken(AccessToken: SecretText)
    begin
        // Encrypt at rest when encryption is configured; fall back to unencrypted storage otherwise
        // (e.g. on-prem without an encryption key), matching the base app OAuth token pattern.
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted('AccessToken(' + Rec.SystemId + ')', AccessToken, DataScope::Module)
        else
            IsolatedStorage.Set('AccessToken(' + Rec.SystemId + ')', AccessToken, DataScope::Module);
    end;

    internal procedure GetAccessToken() Result: SecretText
    begin
        if not IsolatedStorage.Get('AccessToken(' + Rec.SystemId + ')', DataScope::Module, Result) then;
    end;

    internal procedure SetRefreshToken(RefreshToken: SecretText)
    begin
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted('RefreshToken(' + Rec.SystemId + ')', RefreshToken, DataScope::Module)
        else
            IsolatedStorage.Set('RefreshToken(' + Rec.SystemId + ')', RefreshToken, DataScope::Module);
    end;

    internal procedure GetRefreshToken() Result: SecretText
    begin
        if not IsolatedStorage.Get('RefreshToken(' + Rec.SystemId + ')', DataScope::Module, Result) then;
    end;

    internal procedure HasRefreshToken(): Boolean
    begin
        exit(not GetRefreshToken().IsEmpty());
    end;
}
