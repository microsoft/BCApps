// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;

table 11300 "VAT VIES Correction"
{
    Caption = 'VAT VIES Correction';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionCaption = 'Quarter,Month';
            OptionMembers = Quarter,Month;
        }
        field(2; "Declaration Period No."; Integer)
        {
            Caption = 'Declaration Period No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                ValidatePeriodNo();
            end;
        }
        field(3; "Declaration Period Year"; Integer)
        {
            Caption = 'Declaration Period Year';
            NotBlank = true;

            trigger OnValidate()
            begin
                ValidateYear();
            end;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(5; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                Cust.Get("Customer No.");
                "Country/Region Code" := Cust."Country/Region Code";
                Validate("VAT Registration No.", Cust."VAT Registration No.");
            end;
        }
        field(6; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            NotBlank = true;

            trigger OnValidate()
            begin
                GLSetup.Get();
                if GLSetup."Additional Reporting Currency" <> '' then begin
                    AddCurrencyFactor :=
                      CurrencyExchRate.ExchangeRate("Correction Date", GLSetup."Additional Reporting Currency");
                    Currency.Get(GLSetup."Additional Reporting Currency");
                    Currency.TestField("Amount Rounding Precision");
                    "Additional-Currency Amount" :=
                      Round(
                        CurrencyExchRate.ExchangeAmtLCYToFCY(
                          "Correction Date", GLSetup."Additional Reporting Currency",
                          Amount, AddCurrencyFactor),
                        Currency."Amount Rounding Precision");
                end;
            end;
        }
        field(7; "Correction Date"; Date)
        {
            Caption = 'Correction Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                // Correction logic needs to be fixed.
                // add simple logic that the correction date should not be greater than reporting end date
                ValidateCorrectionDate();
            end;
        }
        field(9; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
        }
        field(10; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
            begin
                TestField("Country/Region Code");
                VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", '', DATABASE::"VAT VIES Correction");
            end;
        }
        field(11; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(12; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                Validate("VAT Registration No.");
            end;
        }
        field(13; "Correction Period No."; Integer)
        {
            Caption = 'Correction Period No.';
            Editable = false;
        }
        field(14; "Correction Period Year"; Integer)
        {
            Caption = 'Correction Period Year';
            Editable = false;
        }
        field(15; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
        }
    }

    keys
    {
        key(Key1; "Period Type", "Declaration Period No.", "Declaration Period Year", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Period Type", "Declaration Period No.", "Declaration Period Year", "VAT Registration No.", "EU 3-Party Trade", "Correction Period Year", "Correction Period No.")
        {
            SumIndexFields = Amount, "Additional-Currency Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        ValidateCorrectionDate();
    end;

    trigger OnRename()
    begin
        ValidateCorrectionDate();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        Cust: Record Customer;
        AddCurrencyFactor: Decimal;
        Text001: Label 'You cannot make a correction on %1 in period %2: %3, %4.', Comment = '1 parameter - date, 2 - period type (Quarter,Month), 3 and 4 - integer.';
        Text002: Label 'Quarter must be between 1 and 4.';
        Text003: Label 'Year must be between 1997 and 2050.';
        Text004: Label 'Month must be between 1 and 12.';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;

    [Scope('OnPrem')]
    procedure ValidatePeriodNo()
    begin
        if "Period Type" = "Period Type"::Quarter then begin
            if not ("Declaration Period No." in [1 .. 4]) then
                Error(Text002);
        end else
            if not ("Declaration Period No." in [1 .. 12]) then
                Error(Text004);
    end;

    [Scope('OnPrem')]
    procedure ValidateYear()
    begin
        if not ("Declaration Period Year" in [1997 .. 2050]) then
            Error(Text003);
    end;

    [Scope('OnPrem')]
    procedure ValidateCorrectionDate()
    var
        MonthNo: Integer;
        PeriodEndingDate: Date;
    begin
        if "Period Type" = "Period Type"::Quarter then
            MonthNo := "Declaration Period No." * 3
        else
            MonthNo := "Declaration Period No.";
        PeriodEndingDate := DMY2Date(1, MonthNo, "Declaration Period Year");
        PeriodEndingDate := CalcDate('<CM>', PeriodEndingDate);
        if "Correction Date" > PeriodEndingDate then
            Error(Text001, Format("Correction Date"), Format("Period Type"),
              Format("Declaration Period No."), Format("Declaration Period Year"));

        if "Period Type" = "Period Type"::Quarter then
            "Correction Period No." := Round(Date2DMY("Correction Date", 2) / 3, 1, '>')
        else
            "Correction Period No." := Date2DMY("Correction Date", 2);

        "Correction Period Year" := Date2DMY("Correction Date", 3);
    end;
}

