// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.WithholdingTax;

table 7059 "WHT Exp. Report Buffer"
{
    Caption = 'Expense Report Withholding Tax Buffer';
    Access = Internal;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Wthldg. Tax Bus. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Bus. Posting Group';
            TableRelation = "Wthldg. Tax Bus. Post. Group";
            DataClassification = SystemMetadata;
        }
        field(11; "Wthldg. Tax Prod. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Prod. Posting Group';
            TableRelation = "Wthldg. Tax Prod. Post. Group";
            DataClassification = SystemMetadata;
        }
        field(12; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            DataClassification = SystemMetadata;
        }
        field(20; "WHT Base Amount (LCY)"; Decimal)
        {
            Caption = 'Withholding Tax Base Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(21; "WHT Amount (LCY)"; Decimal)
        {
            Caption = 'Withholding Tax Amount (LCY)';
            DataClassification = SystemMetadata;
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