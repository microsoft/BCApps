// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7219 "EA Corp Card Trans Detail"
{
    Access = Internal;
    Caption = 'Corp Card Transaction Detail';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Trans Entry No."; Integer)
        {
            Caption = 'Transaction Entry No.';
            TableRelation = "EA Corp Card Trans"."Entry No.";
            ToolTip = 'Specifies the transaction entry number for the corporate card transaction detail.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number for the corporate card transaction detail.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description for the corporate card transaction detail.';
        }
        field(4; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity for the corporate card transaction detail.';
        }
        field(5; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the unit cost for the corporate card transaction detail.';
        }
        field(6; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            ToolTip = 'Specifies the VAT amount for the corporate card transaction detail.';
        }
        field(7; "Tax Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Tax Amount';
            ToolTip = 'Specifies the tax amount for the corporate card transaction detail.';
        }
        field(8; "Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
            ToolTip = 'Specifies the tax code for the corporate card transaction detail.';
        }
    }

    keys
    {
        key(PK; "Trans Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }
}