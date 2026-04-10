#if not CLEANSCHEMA28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.FieldService;

table 6418 "FS Connection Setup"
{
    Caption = 'Field Service Integration Setup';
    Permissions = tabledata "FS Connection Setup" = r;
    InherentEntitlements = rX;
    InherentPermissions = rX;
    DataClassification = CustomerContent;
    ReplicateData = true;
    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; "Server Address"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'Field Service URL';
        }
        field(3; "User Name"; Text[250])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "User Password Key"; Guid)
        {
            Caption = 'User Password Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(59; "Restore Connection"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Restore Connection';
        }
        field(60; "Is Enabled"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Is Enabled';
        }
        field(63; "FS Version"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Field Service Version';
        }
        field(67; "Is FS Solution Installed"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Is CRM Solution Installed';
        }
        field(76; "Proxy Version"; Integer)
        {
            Caption = 'Proxy Version';
            DataClassification = SystemMetadata;
        }
        field(118; CurrencyDecimalPrecision; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Currency Decimal Precision';
            Description = 'Number of decimal places that can be used for currency.';
        }
        field(124; BaseCurrencyId; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Currency';
            Description = 'Unique identifier of the base currency of the organization.';
        }
        field(133; BaseCurrencyPrecision; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Base Currency Precision';
            Description = 'Number of decimal places that can be used for the base currency.';
            MaxValue = 4;
            MinValue = 0;
        }
        field(134; BaseCurrencySymbol; Text[5])
        {
            DataClassification = SystemMetadata;
            Caption = 'Base Currency Symbol';
            Description = 'Symbol used for the base currency.';
        }
        field(135; "Authentication Type"; Option)
        {
            DataClassification = SystemMetadata;
            Caption = 'Authentication Type';
            OptionCaption = 'OAuth 2.0,AD,IFD,OAuth';
            OptionMembers = Office365,AD,IFD,OAuth;
        }
        field(136; "Connection String"; Text[250])
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'Connection String';
        }
        field(137; Domain; Text[250])
        {
            Caption = 'Domain';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
        }
        field(138; "Server Connection String"; BLOB)
        {
            DataClassification = OrganizationIdentifiableInformation;
            Caption = 'Server Connection String';
        }
        field(139; "Disable Reason"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Disable Reason';
        }
        field(200; "Job Journal Template"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Project Journal Template';
        }
        field(201; "Job Journal Batch"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Project Journal Batch';
        }
        field(202; "Hour Unit of Measure"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Hour Unit of Measure';
        }
        field(203; "Line Synch. Rule"; Enum "FS Work Order Line Synch. Rule")
        {
            DataClassification = SystemMetadata;
            Caption = 'Synchronize work order products/services';
        }
        field(204; "Line Post Rule"; Enum "FS Work Order Line Post Rule")
        {
            DataClassification = SystemMetadata;
            Caption = 'Automatically post project journal lines';
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
}
#endif