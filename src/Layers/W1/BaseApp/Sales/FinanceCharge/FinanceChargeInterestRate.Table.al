// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

table 572 "Finance Charge Interest Rate"
{
    Caption = 'Fin. Charge Interest Rate';
    DataCaptionFields = "Fin. Charge Terms Code", "Start Date";
    LookupPageID = "Finance Charge Interest Rates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            NotBlank = true;
            TableRelation = "Finance Charge Terms".Code;
        }
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
            NotBlank = true;
        }
        field(3; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            MaxValue = 100;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(4; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
    }

    keys
    {
        key(Key1; "Fin. Charge Terms Code", "Start Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

