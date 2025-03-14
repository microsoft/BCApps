// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Media;

using System.Apps;

table 1470 "Product Video Buffer"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Product Video Buffer';
    ReplicateData = false;
#pragma warning disable AS0034
    InherentEntitlements = rX;
    InherentPermissions = rX;
#pragma warning restore AS0034
    //TableType = Temporary; // need to fix AS0034 and AS0039 first

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; Title; Text[250])
        {
            Caption = 'Title';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Video Url"; Text[2048])
        {
            Caption = 'Video Url';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6; "Table Num"; Integer)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "System ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "Extension Name"; Text[250])
        {
            Caption = 'Extension Name';
            FieldClass = FlowField;
            CalcFormula = lookup("Published Application".Name where(ID = field("App ID"), "Tenant Visible" = const(true)));
            Editable = false;
        }
        field(10; Category; Enum "Video Category")
        {
            Caption = 'Category';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
}
