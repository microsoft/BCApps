// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;

table 1114 "Cost Budget Buffer"
{
    Caption = 'Cost Budget Buffer';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Cost Type No."; Code[20])
        {
            Caption = 'Cost Type No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cost Type";
        }
        field(2; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            DataClassification = SystemMetadata;
            TableRelation = "Cost Budget Name";
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
            ClosingDates = true;
            DataClassification = SystemMetadata;
        }
        field(4; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            DataClassification = SystemMetadata;
            TableRelation = "Cost Center";
        }
        field(5; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            DataClassification = SystemMetadata;
            TableRelation = "Cost Object";
        }
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Cost Type No.", "Cost Center Code", "Cost Object Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
