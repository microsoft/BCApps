// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.Finance.Currency;

table 5 "Finance Charge Terms"
{
    Caption = 'Finance Charge Terms';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Finance Charge Terms";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Interest Rate"; Decimal)
        {
            Caption = 'Interest Rate';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                FinChrgInterestRate.Reset();
                FinChrgInterestRate.SetRange("Fin. Charge Terms Code", Code);
                if not FinChrgInterestRate.IsEmpty() then
                    Message(InterestRateNotificationMsg);
            end;
        }
        field(3; "Minimum Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Minimum Amount (LCY)';
            MinValue = 0;
        }
        field(5; "Additional Fee (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional Fee (LCY)';
            MinValue = 0;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Interest Calculation Method"; Enum "Interest Calculation Method")
        {
            Caption = 'Interest Calculation Method';
        }
        field(9; "Interest Period (Days)"; Integer)
        {
            Caption = 'Interest Period (Days)';
        }
        field(10; "Grace Period"; DateFormula)
        {
            Caption = 'Grace Period';
        }
        field(11; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(12; "Interest Calculation"; Option)
        {
            Caption = 'Interest Calculation';
            OptionCaption = 'Open Entries,Closed Entries,All Entries';
            OptionMembers = "Open Entries","Closed Entries","All Entries";
        }
        field(13; "Post Interest"; Boolean)
        {
            Caption = 'Post Interest';
            InitValue = true;
        }
        field(14; "Post Additional Fee"; Boolean)
        {
            Caption = 'Post Additional Fee';
            InitValue = true;
        }
        field(15; "Line Description"; Text[100])
        {
            Caption = 'Line Description';
        }
        field(16; "Add. Line Fee in Interest"; Boolean)
        {
            Caption = 'Add. Line Fee in Interest';
        }
        field(30; "Detailed Lines Description"; Text[100])
        {
            Caption = 'Detailed Lines Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Interest Rate")
        {
        }
    }

    trigger OnDelete()
    begin
        FinChrgText.SetRange("Fin. Charge Terms Code", Code);
        FinChrgText.DeleteAll();

        CurrForFinChrgTerms.SetRange("Fin. Charge Terms Code", Code);
        CurrForFinChrgTerms.DeleteAll();

        FinChrgInterestRate.SetRange("Fin. Charge Terms Code", Code);
        FinChrgInterestRate.DeleteAll();
    end;

    var
        FinChrgText: Record "Finance Charge Text";
        CurrForFinChrgTerms: Record "Currency for Fin. Charge Terms";
        FinChrgInterestRate: Record "Finance Charge Interest Rate";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrFinChargeTerms: Record "Currency for Fin. Charge Terms";
        TotalFinChargesAmt: Decimal;
        Initialized: Boolean;

        InterestRateNotificationMsg: Label 'This interest rate will only be used if no relevant interest rate per date has been entered.';

    procedure CalcFinChargesAmt(PostDate: Date; Code2: Code[10]; CurrCode: Code[10]; Amount: Decimal; NoOfDays: Integer)
    var
        DocFinChargeAmt: Decimal;
        CurrMinAmt: Decimal;
        CurrAddFee: Decimal;
    begin
        if not Get(Code2) then
            exit;

        if NoOfDays < 1 then
            exit;

        if CurrCode = '' then begin
            Currency.InitRoundingPrecision();
            Initialized := true;
            CurrMinAmt := "Minimum Amount (LCY)";
            CurrAddFee := "Additional Fee (LCY)";
        end else begin
            Currency.Get(CurrCode);
            Currency.TestField(Currency."Amount Rounding Precision");
            CurrFinChargeTerms.SetRange("Fin. Charge Terms Code", Code2);
            CurrFinChargeTerms.SetRange("Currency Code", CurrCode);
            if CurrFinChargeTerms.Find('-') then
                CurrAddFee := CurrFinChargeTerms."Additional Fee"
            else
                CurrAddFee := 0;

            CurrMinAmt := CurrExchRate.ExchangeAmtLCYToFCY(
              PostDate,
              CurrCode,
              "Minimum Amount (LCY)",
              CurrExchRate.ExchangeRate(PostDate, CurrCode));
        end;
        DocFinChargeAmt :=
           CurrAddFee +
          Amount * "Interest Rate" * NoOfDays / 36000;
        if DocFinChargeAmt > CurrMinAmt then
            TotalFinChargesAmt := TotalFinChargesAmt + DocFinChargeAmt
        else
            TotalFinChargesAmt := TotalFinChargesAmt + CurrMinAmt;

        TotalFinChargesAmt := Round(TotalFinChargesAmt, Currency."Amount Rounding Precision");
    end;

    procedure GetTotalFinChargesAmt(): Decimal
    begin
        exit(TotalFinChargesAmt);
    end;
}

