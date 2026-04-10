// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Upgrade;

table 9999 "Upgrade Tags"
{
    Access = Internal;
    InherentEntitlements = rimdX;
    InherentPermissions = rimdX;
    Caption = 'Upgrade Tags';
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Tag; Code[250])
        {
            Caption = 'Tag';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the tag that is used to identify the upgrade.';
        }
        field(2; "Tag Timestamp"; DateTime)
        {
            Caption = 'Tag Timestamp';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the date and time when the upgrade is executed.';
        }
        field(3; Company; Code[30])
        {
            Caption = 'Company';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the company where the upgrade is executed.';
        }

        field(4; "Skipped Upgrade"; Boolean)
        {
            Caption = 'Skipped Upgrade';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the upgrade is skipped.';
        }
    }

    keys
    {
        key(Key1; Tag, Company)
        {
            Clustered = true;
        }
    }

}

