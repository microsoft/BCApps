// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

table 5487 "Balance Sheet Buffer"
{
    Caption = 'Balance Sheet Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the Line No..';
            DataClassification = SystemMetadata;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the Description.';
            DataClassification = SystemMetadata;
        }
        field(3; Balance; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Balance';
            ToolTip = 'Specifies the Balance.';
            DataClassification = SystemMetadata;
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ToolTip = 'Specifies the Date Filter.';
            DataClassification = SystemMetadata;
        }
        field(6; "Line Type"; Text[30])
        {
            Caption = 'Line Type';
            ToolTip = 'Specifies the Line Type.';
            DataClassification = SystemMetadata;
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            ToolTip = 'Specifies the Indentation';
            DataClassification = SystemMetadata;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Id)
        {
        }
    }

    fieldgroups
    {
    }
}

