// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
///  Generic table to define custom codes for any lookup
/// </summary>
table 20408 "Qlty. Lookup Code"
{
    Caption = 'Quality Lookup Code';
    DrillDownPageID = "Qlty. Lookup Code List";
    LookupPageID = "Qlty. Lookup Code List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Group Code"; Code[20])
        {
            Caption = 'Group Code';
            ToolTip = 'Specifies a group code provides the ability to map common codes together.';
            NotBlank = true;
        }
        field(2; "Code"; Code[100])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies a unique code within a given group.';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a human readable description of the custom lookup code.';
        }
        field(4; "Custom 1"; Text[250])
        {
            Caption = 'Custom 1';
            ToolTip = 'Specifies a custom value.';
        }
        field(5; "Custom 2"; Text[250])
        {
            Caption = 'Custom 2';
            ToolTip = 'Specifies a custom value.';
        }
        field(6; "Custom 3"; Text[250])
        {
            Caption = 'Custom 3';
            ToolTip = 'Specifies a custom value.';
        }
        field(7; "Custom 4"; Text[250])
        {
            Caption = 'Custom 4';
            ToolTip = 'Specifies a custom value.';
        }
    }

    keys
    {
        key(Key1; "Group Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Group Code", "Custom 1", "Code")
        {
        }
        key(Key3; "Group Code", "Custom 2", "Code")
        {
        }
        key(Key4; "Group Code", "Custom 3", "Code")
        {
        }
        key(Key5; "Group Code", "Custom 4", "Code")
        {
        }
        key(Key6; "Group Code", Description, "Code")
        {
        }
    }
}
