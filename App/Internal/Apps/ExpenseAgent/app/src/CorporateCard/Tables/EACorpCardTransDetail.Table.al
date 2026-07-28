// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7219 EACorpCardTransDetail
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
            TableRelation = EACorpCardTrans."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(6; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(7; "Tax Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Tax Amount';
        }
        field(8; "Tax Code"; Code[20])
        {
            Caption = 'Tax Code';
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