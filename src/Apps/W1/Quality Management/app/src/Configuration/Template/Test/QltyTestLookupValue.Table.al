// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
///  Generic table to define custom lookup group values for any lookup
/// </summary>
table 20408 "Qlty. Test Lookup Value"
{
    Caption = 'Quality Test Lookup Value';
    DrillDownPageId = "Qlty. Test Lookup Values";
    LookupPageId = "Qlty. Test Lookup Values";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Lookup Group Code"; Code[20])
        {
            Caption = 'Lookup Group Code';
            ToolTip = 'Specifies a group code that provides the ability to link common values together.';
            NotBlank = true;
        }
        field(2; "Value"; Code[100])
        {
            Caption = 'Value';
            NotBlank = true;
            ToolTip = 'Specifies a unique value within a given lookup group.';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a human readable description of the custom lookup value.';
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
        key(Key1; "Lookup Group Code", "Value")
        {
            Clustered = true;
        }
        key(Key2; "Lookup Group Code", "Custom 1", "Value")
        {
        }
        key(Key3; "Lookup Group Code", "Custom 2", "Value")
        {
        }
        key(Key4; "Lookup Group Code", "Custom 3", "Value")
        {
        }
        key(Key5; "Lookup Group Code", "Custom 4", "Value")
        {
        }
        key(Key6; "Lookup Group Code", Description, "Value")
        {
        }
    }
}
