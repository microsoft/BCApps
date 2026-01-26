// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;

table 12111 "Computed Withholding Tax"
{
    Caption = 'Computed Withholding Tax';
    LookupPageID = "Computed Withholding Tax";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(4; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(10; "Total Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Amount';
        }
        field(12; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
        }
        field(13; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';
        }
        field(15; "Remaining - Excluded Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining - Excluded Amount';
        }
        field(20; "Non Taxable Amount By Treaty"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount By Treaty';
        }
        field(22; "Non Taxable Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Remaining Amount';
        }
        field(30; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code";
        }
        field(31; "Related Date"; Date)
        {
            Caption = 'Related Date';
        }
        field(32; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
        }
        field(40; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(41; "WHT Amount Manual"; Decimal)
        {
            Caption = 'WHT Amount Manual';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Document Date", "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

