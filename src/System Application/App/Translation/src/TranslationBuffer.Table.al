// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Globalization;

table 3713 "Translation Buffer"
{
    Access = Public;
    Caption = 'Translation Buffer';
    InherentEntitlements = X;
    InherentPermissions = X;
    TableType = Temporary;

    fields
    {
        field(1; "Language ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Language ID';
            TableRelation = Language."Windows Language ID";
        }
        field(2; "System ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'System ID';
            Editable = false;
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            Editable = false;
        }
        field(4; "Field ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field ID';
            Editable = false;
        }
        field(5; Value; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Value';
        }
    }

    keys
    {
        key(Key1; "Language ID", "System ID", "Field ID")
        {
            Clustered = true;
        }
        key(Key2; "Table ID", "Field ID")
        {
        }
    }
}