// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;

table 12112 "Computed Contribution"
{
    Caption = 'Computed Contribution';
    LookupPageID = "Computed Contribution";
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
        field(5; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            TableRelation = "Contribution Code" where("Contribution Type" = filter(INPS));
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(10; "Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Gross Amount';
        }
        field(11; "Soc.Sec.Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Soc.Sec.Non Taxable Amount';
        }
        field(12; "Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Free-Lance Amount';
        }
        field(13; "Remaining Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Gross Amount';
        }
        field(14; "Remaining Soc.Sec. Non Taxable"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Soc.Sec. Non Taxable';
        }
        field(15; "Remaining Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Free-Lance Amount';
        }
        field(20; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(25; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
            TableRelation = "Contribution Code" where("Contribution Type" = filter(INAIL));
        }
        field(26; "INAIL Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Gross Amount';
        }
        field(27; "INAIL Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Non Taxable Amount';
        }
        field(28; "INAIL Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Free-Lance Amount';
        }
        field(29; "INAIL Remaining Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Remaining Gross Amount';
        }
        field(30; "INAIL Rem. Non Tax. Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Rem. Non Tax. Amount';
        }
        field(31; "INAIL Rem. Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Rem. Free-Lance Amount';
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

