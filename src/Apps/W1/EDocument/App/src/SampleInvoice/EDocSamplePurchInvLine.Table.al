// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.Document;

/// <summary>
/// Temporary table for sample purchase invoice line data used in PDF generation.
/// </summary>
table 6119 "E-Doc Sample Purch. Inv. Line"
{
    InherentEntitlements = RMX;
    InherentPermissions = RMX;
    TableType = Temporary;
    Caption = 'E-Doc Sample Purch. Inv. Line';
    DataClassification = SystemMetadata;

    fields
    {
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';
        }
        field(6; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            AutoFormatType = 0;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(9900; "Amount"; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
        field(9901; "Amount Including VAT"; Decimal)
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
