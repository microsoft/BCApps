// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

table 9656 "Report Layout Update Log"
{
    Caption = 'Report Layout Update Log';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; Status; Option)
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the report layout update.';
            OptionCaption = 'None,NoUpgradeApplied,UpgradeSuccess,UpgradeIgnoreSuccess,UpgradeWarnings,UpgradeErrors';
            OptionMembers = "None",NoUpgradeApplied,UpgradeSuccess,UpgradeIgnoreSuccess,UpgradeWarnings,UpgradeErrors;
        }
        field(3; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the field or element in the report layout that the update pertains to.';
        }
        field(4; Message; Text[250])
        {
            Caption = 'Message';
            ToolTip = 'Specifies detailed information about the update to the report layout. This information is useful when an error occurs to help you fix the error.';
        }
        field(5; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            ToolTip = 'Specifies the ID of the report object that uses the custom report layout.';
        }
        field(6; "Layout Description"; Text[80])
        {
            Caption = 'Layout Description';
            ToolTip = 'Specifies a description of the report layout.';
        }
        field(7; "Layout Type"; Option)
        {
            Caption = 'Layout Type';
            ToolTip = 'Specifies the file type of the report layout. The following table includes the types that are available:';
            OptionCaption = 'RDLC,Word';
            OptionMembers = RDLC,Word;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

