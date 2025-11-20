// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

table 6305 "Power BI Chart Buffer"
{
    Caption = 'Power BI Chart Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(20; "Row No."; Code[20])
        {
            Caption = 'Row No.';
            DataClassification = SystemMetadata;
        }
        field(30; Value; Decimal)
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(40; "Period Type"; Option)
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period";
        }
        field(50; Date; Text[30])
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(60; "Measure Name"; Text[120])
        {
            Caption = 'Measure Name';
            DataClassification = SystemMetadata;
        }
        field(70; "Date Filter"; Text[50])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(80; "Date Sorting"; Integer)
        {
            Caption = 'Date Sorting';
            DataClassification = SystemMetadata;
        }
        field(90; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Line,StepLine,Column,StackedColumn';
            OptionMembers = " ",Line,StepLine,Column,StackedColumn;
        }
        field(100; "Measure No."; Code[20])
        {
            Caption = 'Measure No.';
            DataClassification = SystemMetadata;
        }
        field(110; "Period Type Sorting"; Integer)
        {
            Caption = 'Period Type Sorting';
            DataClassification = SystemMetadata;
        }
        field(120; "Show Orders"; Text[50])
        {
            Caption = 'Show Orders';
            DataClassification = SystemMetadata;
        }
        field(130; "Values to Calculate"; Text[50])
        {
            Caption = 'Values to Calculate';
            DataClassification = SystemMetadata;
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
    }
}

