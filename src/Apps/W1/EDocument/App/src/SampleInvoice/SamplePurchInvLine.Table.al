// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;

/// <summary>
/// Temporary table for sample purchase invoice line data used in PDF generation.
/// </summary>
table 6119 "Sample Purch. Inv. Line"
{
    Caption = 'Sample Purch. Inv. Line';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;
        }
        field(8; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            AutoFormatType = 0;
        }
        field(9; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(29; "Amount"; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
