// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Agents;

table 4331 "Agent Creation Control Lookup"
{
    Access = Internal;
    Caption = 'Agent Creation Control Lookup';
    DataClassification = CustomerContent;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    TableType = Temporary;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Key"; Text[250])
        {
            Caption = 'Key';
            ToolTip = 'Specifies the key.';
        }
        field(3; Value; Text[2048])
        {
            Caption = 'Value';
            ToolTip = 'Specifies the value.';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Key")
        {
        }
        fieldgroup(Brick; "Key", Value)
        {
        }
    }
}

