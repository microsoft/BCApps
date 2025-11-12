// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Utilities;
using System.Integration;
using System.Security.AccessControl;
using System.Security.Encryption;

table 6700 "Exchange Sync"
{
    Caption = 'Exchange Sync';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Exchange Service URI"; Text[250])
        {
            Caption = 'Exchange Service URI';
            DataClassification = SystemMetadata;
        }
        field(4; "Exchange Account Password Key"; Guid)
        {
            Caption = 'Exchange Account Password Key';
        }
        field(5; "Last Sync Date Time"; DateTime)
        {
            Caption = 'Last Sync Date Time';
            Editable = false;
        }
        field(7; "Folder ID"; Text[30])
        {
            Caption = 'Folder ID';
        }
        field(9; "Filter"; BLOB)
        {
            Caption = 'Filter';
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeletePassword("Exchange Account Password Key");
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

        EncryptionIsNotActivatedQst: Label 'Data encryption is not activated. It is recommended that you encrypt data. \Do you want to open the Data Encryption Management window?';
        IsDefaultProdEndpointTxt: Label 'Configured Exchange endpoint is the BC default: %1', Locked = true;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SetExchangeAccountPassword(PasswordText: Text)
    var
        PasswordSecretText: SecretText;
    begin
        PasswordText := DelChr(PasswordText, '=', ' ');
        if PasswordText <> '' then
            CheckEncryption();

        if IsNullGuid("Exchange Account Password Key") then
            "Exchange Account Password Key" := CreateGuid();

        PasswordSecretText := PasswordText;
        IsolatedStorageManagement.Set("Exchange Account Password Key", PasswordSecretText, DATASCOPE::Company);
    end;

    procedure GetExchangeEndpoint() Endpoint: Text[250]
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        O365SyncManagement: Codeunit "O365 Sync. Management";
    begin
        Endpoint := "Exchange Service URI";
        if Endpoint = '' then
            Endpoint := CopyStr(ExchangeWebServicesServer.GetEndpoint(), 1, 250);

        Session.LogMessage('0000GP0', StrSubstNo(IsDefaultProdEndpointTxt, ExchangeWebServicesServer.IsDefaultProdEndpoint(Endpoint)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
    end;

    local procedure CheckEncryption()
    begin
        if not EncryptionEnabled() then
            if Confirm(EncryptionIsNotActivatedQst) then
                PAGE.Run(PAGE::"Data Encryption Management");
    end;

    [Scope('OnPrem')]
    local procedure DeletePassword(PasswordKey: Guid)
    begin
        IsolatedStorageManagement.Delete(PasswordKey, DATASCOPE::Company);
    end;

    procedure SaveFilter(FilterText: Text)
    var
        WriteStream: OutStream;
    begin
        Clear(Filter);
        Filter.CreateOutStream(WriteStream);
        WriteStream.WriteText(FilterText);
    end;

    procedure GetSavedFilter() FilterText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields(Filter);
        Filter.CreateInStream(ReadStream);
        ReadStream.ReadText(FilterText);
    end;

    procedure DeleteActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange("Record ID", Rec.RecordId);
        ActivityLog.DeleteAll();
    end;
}

