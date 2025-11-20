// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;

table 367 "Dimension Code Buffer"
{
    Caption = 'Dimension Code Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; Totaling; Text[250])
        {
            Caption = 'Totaling';
            DataClassification = SystemMetadata;
        }
        field(4; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = SystemMetadata;
        }
        field(5; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(6; Visible; Boolean)
        {
            Caption = 'Visible';
            DataClassification = SystemMetadata;
            InitValue = true;
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            DataClassification = SystemMetadata;
        }
        field(8; "Show in Bold"; Boolean)
        {
            Caption = 'Show in Bold';
            DataClassification = SystemMetadata;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = const(''),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Value Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Value Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Value Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Value Filter")));
            Caption = 'Amount';
            FieldClass = FlowField;
        }
        field(10; "Dimension 1 Value Filter"; Code[20])
        {
            Caption = 'Dimension 1 Value Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Dimension 2 Value Filter"; Code[20])
        {
            Caption = 'Dimension 2 Value Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Dimension 3 Value Filter"; Code[20])
        {
            Caption = 'Dimension 3 Value Filter';
            FieldClass = FlowFilter;
        }
        field(13; "Dimension 4 Value Filter"; Code[20])
        {
            Caption = 'Dimension 4 Value Filter';
            FieldClass = FlowFilter;
        }
        field(7101; Quantity; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = const(''),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Value Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Value Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Value Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Value Filter")));
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Period Start")
        {
        }
    }

    fieldgroups
    {
    }
}
