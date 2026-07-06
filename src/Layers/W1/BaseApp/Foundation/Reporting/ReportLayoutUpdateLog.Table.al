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
            OptionCaption = 'None,NoUpgradeApplied,UpgradeSuccess,UpgradeIgnoreSuccess,UpgradeWarnings,UpgradeErrors';
            OptionMembers = "None",NoUpgradeApplied,UpgradeSuccess,UpgradeIgnoreSuccess,UpgradeWarnings,UpgradeErrors;
        }
        field(3; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
        }
        field(4; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(5; "Report ID"; Integer)
        {
            Caption = 'Report ID';
        }
        field(6; "Layout Description"; Text[80])
        {
            Caption = 'Layout Description';
        }
        field(7; "Layout Type"; Option)
        {
            Caption = 'Layout Type';
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

