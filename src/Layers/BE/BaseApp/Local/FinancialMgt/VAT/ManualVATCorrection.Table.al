// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Security.AccessControl;

table 11301 "Manual VAT Correction"
{
    Caption = 'Manual VAT Correction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Statement Template Name"; Code[10])
        {
            Caption = 'Statement Template Name';
        }
        field(2; "Statement Name"; Code[10])
        {
            Caption = 'Statement Name';
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestField("Posting Date");
            end;
        }
        field(6; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                TestField(Amount);
                CalculateAddCurrencyAmount();
            end;
        }
        field(7; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(8; "Row No."; Code[10])
        {
            CalcFormula = lookup("VAT Statement Line"."Row No." where("Statement Template Name" = field("Statement Template Name"),
                                                                       "Statement Name" = field("Statement Name"),
                                                                       "Line No." = field("Statement Line No.")));
            Caption = 'Row No.';
            FieldClass = FlowField;
        }
        field(9; "Additional-Currency Amount"; Decimal)
        {
            Caption = 'Additional-Currency Amount';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Statement Template Name", "Statement Name", "Statement Line No.", "Posting Date")
        {
            Clustered = true;
            SumIndexFields = Amount, "Additional-Currency Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Posting Date");
        TestField(Amount);
        "User ID" := UserId;
    end;

    trigger OnModify()
    begin
        "User ID" := UserId;
    end;

    local procedure CalculateAddCurrencyAmount()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        AddCurrencyFactor: Decimal;
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            ;
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            AddCurrencyFactor :=
              CurrencyExchRate.ExchangeRate("Posting Date", GLSetup."Additional Reporting Currency");
            "Additional-Currency Amount" :=
              Round(
                CurrencyExchRate.ExchangeAmtLCYToFCY(
                  "Posting Date", GLSetup."Additional Reporting Currency",
                  Amount, AddCurrencyFactor),
                Currency."Amount Rounding Precision");
        end;
    end;
}

