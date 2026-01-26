// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Vendor;

table 12185 "Vendor Bill Withholding Tax"
{
    Caption = 'Vendor Bill Withholding Tax';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(2; "Invoice No."; Code[20])
        {
            Caption = 'Invoice No.';
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
        field(10; "Total Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Amount';

            trigger OnValidate()
            begin
                ValidateWithhSocSec();
            end;
        }
        field(11; "Original Total Amount"; Decimal)
        {
            Caption = 'Original Total Amount';
            AutoFormatType = 1;
        }
        field(13; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';

            trigger OnValidate()
            begin
                ValidateWithhSocSec();
            end;
        }
        field(16; "Non Taxable Amount By Treaty"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount By Treaty';

            trigger OnValidate()
            begin
                ValidateWithhSocSec();
            end;
        }
        field(30; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code".Code;

            trigger OnValidate()
            begin
                ValidateWithhSocSec();
            end;
        }
        field(31; "Related Date"; Date)
        {
            Caption = 'Related Date';
        }
        field(32; "Payment Date"; Date)
        {
            Caption = 'Payment Date';

            trigger OnValidate()
            begin
                ValidateWithhSocSec();
            end;
        }
        field(34; "Non Taxable %"; Decimal)
        {
            Caption = 'Non Taxable %';
            DecimalPlaces = 0 : 3;
        }
        field(35; "Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount';
        }
        field(36; "Taxable Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Taxable Base';
        }
        field(37; "Withholding Tax %"; Decimal)
        {
            Caption = 'Withholding Tax %';
            DecimalPlaces = 0 : 3;
        }
        field(38; "Withholding Tax Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Withholding Tax Amount';
        }
        field(50; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));

            trigger OnValidate()
            begin
                CalculateSocialSecurity("Taxable Base");
            end;
        }
        field(51; "Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Gross Amount';

            trigger OnValidate()
            begin
                CalculateSocialSecurity("Gross Amount");
            end;
        }
        field(52; "Soc.Sec.Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Soc.Sec.Non Taxable Amount';

            trigger OnValidate()
            begin
                GetCurrency("Currency Code");
                "Contribution Base" := "Gross Amount" - "Soc.Sec.Non Taxable Amount";
                "Total Social Security Amount" := Round("Contribution Base" * "Social Security %" / 100, Currency."Amount Rounding Precision");
                Validate("Free-Lance Amount", Round("Total Social Security Amount" * "Free-Lance %" / 100, Currency."Amount Rounding Precision"));

                if "Contribution Base" < 0 then
                    Error(Text12100, FieldCaption("Contribution Base"));
            end;
        }
        field(54; "Contribution Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Contribution Base';
        }
        field(55; "Social Security %"; Decimal)
        {
            Caption = 'Social Security %';
            DecimalPlaces = 0 : 4;
        }
        field(56; "Total Social Security Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Social Security Amount';
        }
        field(57; "Free-Lance %"; Decimal)
        {
            Caption = 'Free-Lance %';
            DecimalPlaces = 0 : 4;
        }
        field(58; "Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Free-Lance Amount';

            trigger OnValidate()
            begin
                "Company Amount" := "Total Social Security Amount" - "Free-Lance Amount";
            end;
        }
        field(59; "Company Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Company Amount';
        }
        field(70; "Withholding Account"; Code[20])
        {
            Caption = 'Withholding Account';
        }
        field(71; "Social Security Acc."; Code[20])
        {
            Caption = 'Social Security Acc.';
        }
        field(72; "Social Security Charges Acc."; Code[20])
        {
            Caption = 'Social Security Charges Acc.';
        }
        field(75; "Old Withholding Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Old Withholding Amount';
        }
        field(76; "Old Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Old Free-Lance Amount';
        }
        field(80; "Payment Line-Withholding"; Integer)
        {
            Caption = 'Payment Line-Withholding';
        }
        field(81; "Payment Line-Soc. Sec."; Integer)
        {
            Caption = 'Payment Line-Soc. Sec.';
        }
        field(82; "Payment Line-Company"; Integer)
        {
            Caption = 'Payment Line-Company';
        }
        field(83; Reason; Option)
        {
            Caption = 'Reason';
            OptionCaption = ' ,A,B,C,D,E,G,H,I,L,L1,M,M1,M2,N,O,O1,P,Q,R,S,T,U,V,V1,V2,W,X,Y,ZO,K';
            OptionMembers = " ",A,B,C,D,E,G,H,I,L,L1,M,M1,M2,N,O,O1,P,Q,R,S,T,U,V,V1,V2,W,X,Y,ZO,K;
        }
        field(100; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(103; "Vendor Bill List No."; Code[20])
        {
            Caption = 'Vendor Bill List No.';
        }
        field(111; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
    }

    keys
    {
        key(Key1; "Vendor Bill List No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text12100: Label '%1 must be greater than 0.';
        Text12101: Label '%1 %2 does not exist in table %3.';
        Currency: Record Currency;

    [Scope('OnPrem')]
    procedure CalculateWithholdingTax()
    var
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
        WithholdingSocSec: Codeunit "Withholding - Contribution";
        TotalAmount: Decimal;
    begin
        if not WithholdCode.Get("Withholding Tax Code") then
            Error(Text12101, WithholdCode.FieldCaption(Code), "Withholding Tax Code", WithholdCode.TableCaption());
        WithholdingSocSec.WithholdLineFilter(WithholdCodeLine, "Withholding Tax Code", "Payment Date");
        "Withholding Account" := WithholdCode."Withholding Taxes Payable Acc.";
        "Withholding Tax %" := WithholdCodeLine."Withholding Tax %";
        "Non Taxable %" := 100 - WithholdCodeLine."Taxable Base %";
        if "Original Total Amount" = 0 then
            TotalAmount := "Total Amount"
        else
            TotalAmount := "Original Total Amount";
        "Taxable Base" :=
          Round(
            ((TotalAmount - "Base - Excluded Amount" - "Non Taxable Amount By Treaty") * WithholdCodeLine."Taxable Base %") / 100);
        "Non Taxable Amount" :=
          "Total Amount" - "Base - Excluded Amount" - "Non Taxable Amount By Treaty" - "Taxable Base";
        GetCurrency("Currency Code");
        "Withholding Tax Amount" := Round("Taxable Base" * "Withholding Tax %" / 100, Currency."Amount Rounding Precision");
        OnCalculateWithholdingTaxOnAfterAssignWithholdingTaxAmount(Rec);
        if "Taxable Base" < 0 then
            Error(Text12100, FieldCaption("Taxable Base"));
    end;

    [Scope('OnPrem')]
    procedure CalculateSocialSecurity(GrossAmount: Decimal)
    var
        Vend: Record Vendor;
        SocialSecurityCode: Record "Contribution Code";
        SocSecCodeLine: Record "Contribution Code Line";
        SocSecBracketLine: Record "Contribution Bracket Line";
        WithholdingSocSec: Codeunit "Withholding - Contribution";
        CompPartiesBase: Decimal;
        Difference: Decimal;
    begin
        if not SocialSecurityCode.Get("Social Security Code", SocSecBracketLine."Contribution Type"::INPS) then
            Error(Text12101, SocialSecurityCode.FieldCaption(Code), "Social Security Code", SocialSecurityCode.TableCaption());
        "Social Security Acc." := SocialSecurityCode."Social Security Payable Acc.";
        "Social Security Charges Acc." := SocialSecurityCode."Social Security Charges Acc.";
        WithholdingSocSec.SetSocSecLineFilters(
          SocSecCodeLine, "Social Security Code", "Payment Date", SocSecCodeLine."Contribution Type"::INPS);
        "Social Security %" := SocSecCodeLine."Social Security %";
        "Free-Lance %" := SocSecCodeLine."Free-Lance Amount %";

        Vend.Get("Vendor No.");
        Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY("Payment Date", 3)), DMY2Date(31, 12, Date2DMY("Payment Date", 3)));
        Vend.CalcFields("Soc. Sec. Company Base");
        CompPartiesBase := Vend."Soc. Sec. Company Base" + Vend."Soc. Sec. 3 Parties Base";
        WithholdingSocSec.SetSocSecBracketFilters(
            SocSecBracketLine, SocSecCodeLine."Social Security Bracket Code",
            SocSecCodeLine."Contribution Type"::INPS, SocialSecurityCode.Code);
        if SocSecBracketLine.Amount - CompPartiesBase > GrossAmount then
            "Gross Amount" := GrossAmount
        else
            "Gross Amount" := SocSecBracketLine.Amount - CompPartiesBase;
        if "Gross Amount" < 0 then
            "Gross Amount" := 0;
        GrossAmount := "Gross Amount";
        "Soc.Sec.Non Taxable Amount" := 0;
        SocSecBracketLine.SetFilter(Amount, '>%1', CompPartiesBase);

        if SocSecBracketLine.FindSet() then
            repeat
                Difference := SocSecBracketLine.Amount - CompPartiesBase;
                if Difference < GrossAmount then begin
                    "Soc.Sec.Non Taxable Amount" :=
                      "Soc.Sec.Non Taxable Amount" + Round(Difference *
                        (100 - SocSecBracketLine."Taxable Base %") / 100, Currency."Amount Rounding Precision");
                    GrossAmount := GrossAmount - Difference;
                    CompPartiesBase := CompPartiesBase + Difference;
                end else begin
                    "Soc.Sec.Non Taxable Amount" :=
                      "Soc.Sec.Non Taxable Amount" +
                      Round(GrossAmount * (100 - SocSecBracketLine."Taxable Base %") / 100, Currency."Amount Rounding Precision");
                    CompPartiesBase := CompPartiesBase + GrossAmount;
                    GrossAmount := 0;
                end;
            until (SocSecBracketLine.Next() = 0) or (GrossAmount = 0);
        Validate("Soc.Sec.Non Taxable Amount", "Soc.Sec.Non Taxable Amount" + GrossAmount);
    end;

    [Scope('OnPrem')]
    procedure GetCurrency(CurrencyCode: Code[20])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);
    end;

    procedure ValidateWithhSocSec()
    begin
        CalculateWithholdingTax();
        if "Social Security Code" <> '' then
            CalculateSocialSecurity("Total Amount");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxOnAfterAssignWithholdingTaxAmount(var VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax")
    begin
    end;
}

