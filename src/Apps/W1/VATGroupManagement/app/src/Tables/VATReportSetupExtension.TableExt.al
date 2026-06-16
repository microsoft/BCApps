// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Group;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Reporting;
using System.Environment;
using System.Telemetry;

tableextension 4701 "VAT Report Setup Extension" extends "VAT Report Setup"
{
    fields
    {
        field(4700; "VAT Group Role"; Enum "VAT Group Role")
        {
            DataClassification = SystemMetadata;
            Caption = 'VAT Group Role';

            trigger OnValidate()
            var
                AuditLog: Codeunit "Audit Log";
            begin
                if "VAT Group Role" <> xRec."VAT Group Role" then
                    Session.LogSecurityAudit(
                        VATGroupServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditRoleChangedTxt, xRec."VAT Group Role", "VAT Group Role"),
                        AuditCategory::ApplicationManagement);
                if (xRec."VAT Group Role" = xRec."VAT Group Role"::" ") and ("VAT Group Role" <> "VAT Group Role"::" ") then
                    AuditLog.LogAuditMessage(
                        StrSubstNo(VATGroupConfiguredLbl, UserSecurityId()),
                        SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
            end;
        }
        field(4701; "Approved Members"; Integer)
        {
            Caption = 'Approved Members';
            FieldClass = FlowField;
            CalcFormula = count("VAT Group Approved Member");
        }
        field(4702; "Group Member ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Group Member ID';
            Editable = false;
        }
        field(4703; "Group Representative API URL"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'Group Representative API URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                EnvironmentInformation: Codeunit "Environment Information";
            begin
                if EnvironmentInformation.IsSaaSInfrastructure() then
                    if not ValidateGroupRepresentativeAPIURL() then
                        Error(InvalidURLErr);
                if "Group Representative API URL" <> xRec."Group Representative API URL" then
                    Session.LogSecurityAudit(
                        VATGroupServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditApiUrlChangedTxt, xRec."Group Representative API URL", "Group Representative API URL"),
                        AuditCategory::ApplicationManagement);
            end;
        }
#if not CLEANSCHEMA25
#pragma warning disable AL0432
#pragma warning disable AS0105
        field(4704; "Authentication Type"; Enum "VAT Group Authentication Type OnPrem")
#pragma warning restore
#pragma warning restore AS0105
        {
            DataClassification = CustomerContent;
            Caption = 'Authentication Type';
            ObsoleteReason = 'Replaced by field "VAT Group Authentication Type" as the value Enum is being renamed.';
            ObsoleteTag = '25.0';
            ObsoleteState = Removed;
        }
#endif
        field(4719; "VAT Group Authentication Type"; Enum "VAT Group Auth Type OnPrem")
        {
            DataClassification = CustomerContent;
            Caption = 'Authentication Type';
        }
        field(4705; "User Name Key"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'User Name Key';
            ExtendedDatatype = Masked;

            trigger OnValidate()
            begin
                if "User Name Key" <> xRec."User Name Key" then
                    Session.LogSecurityAudit(
                        VATGroupServiceNameTxt, SecurityOperationResult::Success,
                        SecurityAuditUserNameChangedTxt,
                        AuditCategory::UserManagement);
            end;
        }
        field(4706; "Web Service Access Key Key"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Web Service Access Key Key';
            ExtendedDatatype = Masked;

            trigger OnValidate()
            begin
                if "Web Service Access Key Key" <> xRec."Web Service Access Key Key" then
                    Session.LogSecurityAudit(
                        VATGroupServiceNameTxt, SecurityOperationResult::Success,
                        SecurityAuditWebSvcKeyChangedTxt,
                        AuditCategory::UserManagement);
            end;
        }
        field(4707; "Group Representative Company"; Text[30])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'Group Representative Company';
        }
        field(4708; "Client ID Key"; Guid)
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'Client ID Key';
            ExtendedDatatype = Masked;

            trigger OnValidate()
            begin
                if "Client ID Key" <> xRec."Client ID Key" then
                    Session.LogSecurityAudit(
                        VATGroupServiceNameTxt, SecurityOperationResult::Success,
                        SecurityAuditClientIdChangedTxt,
                        AuditCategory::UserManagement);
            end;
        }
        field(4709; "Client Secret Key"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Client Secret Key';
            ExtendedDatatype = Masked;

            trigger OnValidate()
            begin
                if "Client Secret Key" <> xRec."Client Secret Key" then
                    Session.LogSecurityAudit(
                        VATGroupServiceNameTxt, SecurityOperationResult::Success,
                        SecurityAuditClientSecretChangedTxt,
                        AuditCategory::UserManagement);
            end;
        }
        field(4710; "Authority URL"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'OAuth 2.0 Authority URL';
            ExtendedDatatype = URL;
        }
        field(4711; "Resource URL"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'OAuth 2.0 Resource URL';
            ExtendedDatatype = URL;
        }
        field(4712; "Redirect URL"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'OAuth 2.0 Redirect URL';
            ExtendedDatatype = URL;
        }
        field(4713; "Group Representative On SaaS"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Group Representative Uses Business Central Online';
            InitValue = true;
        }
        field(4714; "Group Settlement Account"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Group Settlement Account';
            TableRelation = "G/L Account"."No.";
        }
        field(4715; "VAT Settlement Account"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Settlement Account';
            TableRelation = "G/L Account"."No.";
        }
        field(4716; "VAT Due Box No."; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Due Box No.';
        }
        field(4717; "Group Settle. Gen. Jnl. Templ."; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Group Settlement General Journal Template';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(4718; "VAT Group BC Version"; Enum "VAT Group BC Version")
        {
            DataClassification = CustomerContent;
            Caption = 'Group Representative Product Version';
        }
    }

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetSecret(SecretKey: Guid; ClientSecretText: SecretText): Guid
    var
        NewSecretKey: Guid;
    begin
        if not IsNullGuid(SecretKey) then
            if not IsolatedStorage.Delete(SecretKey, DataScope::Company) then;

        NewSecretKey := CreateGuid();

        if (not EncryptionEnabled() or (StrLen(ClientSecretText.Unwrap()) > 215)) then
            IsolatedStorage.Set(NewSecretKey, ClientSecretText, DataScope::Company)
        else
            IsolatedStorage.SetEncrypted(NewSecretKey, ClientSecretText, DataScope::Company);

        exit(NewSecretKey);
    end;


    [Scope('OnPrem')]
    procedure GetSecretAsSecretText(SecretKey: Guid): SecretText
    var
        ClientSecretText: SecretText;
    begin
        if not IsNullGuid(SecretKey) then
            if not IsolatedStorage.Get(SecretKey, DataScope::Company, ClientSecretText) then;

        exit(ClientSecretText);
    end;

    procedure IsGroupRepresentative(): Boolean
    begin
        exit("VAT Group Role" = "VAT Group Role"::Representative);
    end;

    procedure IsGroupMember(): Boolean
    begin
        exit("VAT Group Role" = "VAT Group Role"::Member);
    end;

    procedure GetGroupRepresentativeURL(): Text[250]
    var
        EnvironmentInformation: Codeunit "Environment Information";
        GroupRepAPIURL: Text[250];
    begin
        GroupRepAPIURL := Rec."Group Representative API URL";
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not ValidateGroupRepresentativeAPIURL() then
                Error(InvalidURLErr);
        exit(GroupRepAPIURL);
    end;

    internal procedure ValidateGroupRepresentativeAPIURL(): Boolean
    begin
        if Rec."Group Representative API URL" <> '' then
            if not Lowercase(Rec."Group Representative API URL").StartsWith('https://api.businesscentral.dynamics.com') then
                if not Lowercase(Rec."Group Representative API URL").StartsWith('https://api.businesscentral.dynamics-tie.com') then
                    exit(false);

        exit(true);
    end;

    var
        InvalidURLErr: Label 'The Group Representative API URL must start with https://api.businesscentral.dynamics.com or https://api.businesscentral.dynamics-tie.com';
        VATGroupServiceNameTxt: Label 'VAT Group Management', Locked = true;
        SecurityAuditRoleChangedTxt: Label 'VAT Group Role was changed from %1 to %2.', Locked = true, Comment = '%1 - old role, %2 - new role';
        SecurityAuditApiUrlChangedTxt: Label 'Group Representative API URL was changed from %1 to %2.', Locked = true, Comment = '%1 - old URL, %2 - new URL';
        SecurityAuditUserNameChangedTxt: Label 'VAT Group representative User Name was changed.', Locked = true;
        SecurityAuditWebSvcKeyChangedTxt: Label 'VAT Group representative Web Service Access Key was changed.', Locked = true;
        SecurityAuditClientIdChangedTxt: Label 'VAT Group OAuth Client ID was changed.', Locked = true;
        SecurityAuditClientSecretChangedTxt: Label 'VAT Group OAuth Client Secret was changed.', Locked = true;
        VATGroupConfiguredLbl: Label 'VAT Group Management has been set up by UserSecurityId %1.', Locked = true;
}