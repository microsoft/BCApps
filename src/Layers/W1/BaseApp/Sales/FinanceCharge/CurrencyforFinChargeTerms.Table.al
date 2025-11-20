// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;

table 328 "Currency for Fin. Charge Terms"
{
    Caption = 'Currency for Fin. Charge Terms';
    DataCaptionFields = "Fin. Charge Terms Code";
    DrillDownPageID = "Currencies for Fin. Chrg Terms";
    LookupPageID = "Currencies for Fin. Chrg Terms";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Finance Charge Terms";
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            NotBlank = true;
            TableRelation = Currency;
        }
        field(4; "Additional Fee"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Additional Fee';
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Fin. Charge Terms Code", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

