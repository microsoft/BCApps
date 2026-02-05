// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.UOM;
using Microsoft.Sustainability.ExciseTax;

tableextension 7414 "Excise Taxes Trans. Log Ext" extends "Sust. Excise Taxes Trans. Log"
{
    fields
    {
        field(7412; "Excise Tax Type"; Code[20])
        {
            Caption = 'Excise Tax Type';
            TableRelation = "Excise Tax Type".Code;
            DataClassification = CustomerContent;
        }
        field(7413; "Tax Rate %"; Decimal)
        {
            Caption = 'Tax Rate %';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            MaxValue = 100;
            DataClassification = CustomerContent;
        }
        field(7414; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
            DataClassification = CustomerContent;
        }
        field(7415; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;
        }
        field(7416; "Excise Tax UOM"; Code[10])
        {
            Caption = 'Excise Tax UOM';
            TableRelation = "Unit of Measure".Code;
            DataClassification = CustomerContent;
        }
        field(7417; "Excise Entry Type"; Enum "Excise Entry Type")
        {
            Caption = 'Excise Entry Type';
            DataClassification = CustomerContent;
        }
        field(7418; "FA Ledger Entry No."; Integer)
        {
            Caption = 'FA Ledger Entry No.';
            TableRelation = "FA Ledger Entry"."Entry No.";
            DataClassification = CustomerContent;
        }
    }
}