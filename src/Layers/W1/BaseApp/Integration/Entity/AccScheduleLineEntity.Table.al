// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

table 5503 "Acc. Schedule Line Entity"
{
    Caption = 'Acc. Schedule Line Entity';
    TableType = Temporary;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the Line No..';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the Description.';
        }
        field(3; "Net Change"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Change';
            ToolTip = 'Specifies the Net Change.';
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ToolTip = 'Specifies the Date Filter.';
        }
        field(6; "Line Type"; Text[30])
        {
            Caption = 'Line Type';
            ToolTip = 'Specifies the Line Type.';
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            ToolTip = 'Specifies the Indentation.';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
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

