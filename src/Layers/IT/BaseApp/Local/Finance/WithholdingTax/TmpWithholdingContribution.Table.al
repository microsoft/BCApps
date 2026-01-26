// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;

table 12113 "Tmp Withholding Contribution"
{
    Caption = 'Tmp Withholding Contribution';
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
                CalculateWithholdingTax();
                if "Social Security Code" <> '' then begin
                    CalculateSocialSecurity("Taxable Base");
                    CalculateSocialSecurity("Total Amount");
                end;

                // INAIL START
                if "INAIL Code" <> '' then
                    CalcolaINAIL("Taxable Base");
                // INAIL END
            end;
        }
        field(13; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';

            trigger OnValidate()
            begin
                CalculateAll(Rec.FieldNo("Base - Excluded Amount"));
            end;
        }
        field(16; "Non Taxable Amount By Treaty"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount By Treaty';

            trigger OnValidate()
            begin
                CalculateAll(Rec.FieldNo("Non Taxable Amount By Treaty"));
            end;
        }
        field(30; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code".Code;

            trigger OnValidate()
            begin
                CalculateAll(Rec.FieldNo("Withholding Tax Code"));
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
                CalculateAll(Rec.FieldNo("Payment Date"));
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSocialSecurityCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CalculateSocialSecurity("Taxable Base");
            end;
        }
        field(51; "Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Gross Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateGrossAmount(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

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
                "Contribution Base" := "Gross Amount" - "Soc.Sec.Non Taxable Amount";
                "Total Social Security Amount" := Round("Contribution Base" * "Social Security %" / 100);
                Validate("Free-Lance Amount", Round("Total Social Security Amount" * "Free-Lance %" / 100));

                if "Contribution Base" < 0 then
                    Error(NegativeContributionBaseErr);
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
        field(83; Reason; Enum "Withholding Tax Reason")
        {
            Caption = 'Reason';
        }
        field(100; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(101; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(102; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(111; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(115; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INAIL));

            trigger OnValidate()
            begin
                if "INAIL Code" <> '' then
                    CalcolaINAIL("Taxable Base");
            end;
        }
        field(116; "INAIL Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Gross Amount';

            trigger OnValidate()
            begin
                if "INAIL Code" <> '' then
                    CalcolaINAIL("INAIL Gross Amount");
            end;
        }
        field(117; "INAIL Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Non Taxable Amount';

            trigger OnValidate()
            begin
                "INAIL Contribution Base" := "INAIL Gross Amount" - "INAIL Non Taxable Amount";
                "INAIL Total Amount" := Round("INAIL Contribution Base" * "INAIL Per Mil" / 1000);
                Validate("INAIL Free-Lance Amount", Round("INAIL Total Amount" * "INAIL Free-Lance %" / 1000));

                if "INAIL Contribution Base" < 0 then
                    Error(NegativeINAILContributionBaseErr);
            end;
        }
        field(118; "INAIL Contribution Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Contribution Base';
        }
        field(119; "INAIL Per Mil"; Decimal)
        {
            Caption = 'INAIL Per Mil';
            DecimalPlaces = 0 : 4;
        }
        field(120; "INAIL Total Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Total Amount';
        }
        field(121; "INAIL Free-Lance %"; Decimal)
        {
            Caption = 'INAIL Free-Lance %';
            DecimalPlaces = 0 : 4;
        }
        field(122; "INAIL Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Free-Lance Amount';

            trigger OnValidate()
            begin
                "INAIL Company Amount" := "INAIL Total Amount" - "INAIL Free-Lance Amount";
            end;
        }
        field(123; "INAIL Company Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Company Amount';
        }
        field(124; "INAIL Debit Account"; Code[20])
        {
            Caption = 'INAIL Debit Account';
        }
        field(125; "INAIL Charge Account"; Code[20])
        {
            Caption = 'INAIL Charge Account';
        }
        field(126; "INAIL Payment Line"; Integer)
        {
            Caption = 'INAIL Payment Line';
        }
        field(127; "INAIL Company Payment Line"; Integer)
        {
            Caption = 'INAIL Company Payment Line';
        }
        field(128; "Old INAIL Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Old INAIL Free-Lance Amount';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NegativeContributionBaseErr: Label 'The Contribution Base must be greater than 0.';
        NegativeTaxableBaseErr: Label 'The Taxable Base must be greater than 0.';
        NegativeINAILContributionBaseErr: Label 'The INAIL Contribution Base must be greater than 0.';
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
        SocialSecurityCode: Record "Contribution Code";
        SocSecCodeLine: Record "Contribution Code Line";
        SocSecBracketLine: Record "Contribution Bracket Line";
        Vend: Record Vendor;
        WithholdingSocSec: Codeunit "Withholding - Contribution";

    local procedure CalculateAll(CallingFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateAll(Rec, xRec, CallingFieldNo, IsHandled);
        if IsHandled then
            exit;

        CalculateWithholdingTax();
        if "Social Security Code" <> '' then
            CalculateSocialSecurity("Taxable Base");

        // INAIL START
        if "INAIL Code" <> '' then
            CalcolaINAIL("Taxable Base");
        // INAIL END
    end;

    procedure CalculateWithholdingTax()
    begin
        WithholdCode.Get("Withholding Tax Code");

        WithholdingSocSec.WithholdLineFilter(WithholdCodeLine, "Withholding Tax Code",
          "Payment Date");

        "Withholding Account" := WithholdCode."Withholding Taxes Payable Acc.";
        "Withholding Tax %" := WithholdCodeLine."Withholding Tax %";
        "Non Taxable %" := 100 - WithholdCodeLine."Taxable Base %";
        "Taxable Base" := Round(((
                                  "Total Amount" -
                                  "Base - Excluded Amount" -
                                  "Non Taxable Amount By Treaty") *
                                 WithholdCodeLine."Taxable Base %") / 100);
        "Non Taxable Amount" := "Total Amount" -
          "Base - Excluded Amount" -
          "Non Taxable Amount By Treaty" -
          "Taxable Base";

        "Withholding Tax Amount" := Round("Taxable Base" * "Withholding Tax %" / 100);
        OnCalculateWithholdingTaxOnAfterAssignWithholdingTaxAmount(Rec);

        if "Taxable Base" < 0 then
            Error(NegativeTaxableBaseErr);
    end;

    [Scope('OnPrem')]
    procedure CalculateSocialSecurity(GrossAmount: Decimal)
    var
        Assoggettato: Decimal;
        Gap: Decimal;
    begin
        SocialSecurityCode.Get("Social Security Code", SocSecBracketLine."Contribution Type"::INPS);

        "Social Security Acc." := SocialSecurityCode."Social Security Payable Acc.";
        "Social Security Charges Acc." := SocialSecurityCode."Social Security Charges Acc.";

        WithholdingSocSec.SetSocSecLineFilters(
            SocSecCodeLine, "Social Security Code", "Payment Date", SocSecCodeLine."Contribution Type"::INPS);
        "Social Security %" := SocSecCodeLine."Social Security %";
        "Free-Lance %" := SocSecCodeLine."Free-Lance Amount %";

        Vend.Get("Vendor No.");
        Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY("Payment Date", 3)),
          DMY2Date(31, 12, Date2DMY("Payment Date", 3)));
        Vend.CalcFields("Soc. Sec. Company Base");

        Assoggettato := Vend."Soc. Sec. Company Base" + Vend."Soc. Sec. 3 Parties Base" +
          WithholdingSocSec.GetCompContribRemGrossAmtForVendorInPeriod(
            "Vendor No.",
            CalcDate('<-CY>', "Payment Date"),
            CalcDate('<CY>', "Payment Date"));

        WithholdingSocSec.SetSocSecBracketFilters(
            SocSecBracketLine, SocSecCodeLine."Social Security Bracket Code",
            SocSecCodeLine."Contribution Type"::INPS, SocSecBracketLine.Code);
        if SocSecBracketLine.Amount - Assoggettato > GrossAmount then
            "Gross Amount" := GrossAmount
        else
            "Gross Amount" := SocSecBracketLine.Amount - Assoggettato;

        if "Gross Amount" < 0 then
            "Gross Amount" := 0;

        GrossAmount := "Gross Amount";
        "Soc.Sec.Non Taxable Amount" := 0;

        SocSecBracketLine.SetFilter(Amount, '>%1', Assoggettato);

        if SocSecBracketLine.FindSet() then
            repeat
                Gap := SocSecBracketLine.Amount - Assoggettato;
                if Gap < GrossAmount then begin
                    "Soc.Sec.Non Taxable Amount" :=
                      "Soc.Sec.Non Taxable Amount" + Round(Gap * (100 - SocSecBracketLine."Taxable Base %") / 100)
                      ;
                    GrossAmount := GrossAmount - Gap;
                    Assoggettato := Assoggettato + Gap;
                end else begin
                    "Soc.Sec.Non Taxable Amount" := "Soc.Sec.Non Taxable Amount" +
                      Round(GrossAmount * (100 - SocSecBracketLine."Taxable Base %") / 100);
                    Assoggettato := Assoggettato + GrossAmount;
                    GrossAmount := 0;
                end;
            until (SocSecBracketLine.Next() = 0) or (GrossAmount = 0);

        Validate("Soc.Sec.Non Taxable Amount", "Soc.Sec.Non Taxable Amount" + GrossAmount);
    end;

    [Scope('OnPrem')]
    procedure CalcolaINAIL(GrossAmount: Decimal)
    var
        Assoggettato: Decimal;
        Gap: Decimal;
    begin
        // START INAIL
        SocialSecurityCode.Get("INAIL Code", SocSecBracketLine."Contribution Type"::INAIL);

        "INAIL Debit Account" := SocialSecurityCode."Social Security Payable Acc.";
        "INAIL Charge Account" := SocialSecurityCode."Social Security Charges Acc.";

        WithholdingSocSec.SetSocSecLineFilters(
            SocSecCodeLine, "INAIL Code", "Payment Date", SocSecCodeLine."Contribution Type"::INAIL);

        "INAIL Per Mil" := SocSecCodeLine."Social Security %";
        "INAIL Free-Lance %" := SocSecCodeLine."Free-Lance Amount %";

        Vend.Get("Vendor No.");
        Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY("Payment Date", 3)),
          DMY2Date(31, 12, Date2DMY("Payment Date", 3)));
        Vend.CalcFields("INAIL Company Base");
        Assoggettato := Vend."INAIL Company Base" + Vend."INAIL 3 Parties Base";

        WithholdingSocSec.SetSocSecBracketFilters(
            SocSecBracketLine,
            SocSecCodeLine."Social Security Bracket Code",
            SocSecCodeLine."Contribution Type"::INAIL, SocSecCodeLine.Code);

        if SocSecBracketLine.Amount - Assoggettato > GrossAmount then
            "INAIL Gross Amount" := GrossAmount
        else
            "INAIL Gross Amount" := SocSecBracketLine.Amount - Assoggettato;

        if "INAIL Gross Amount" < 0 then
            "INAIL Gross Amount" := 0;

        GrossAmount := "INAIL Gross Amount";
        "INAIL Non Taxable Amount" := 0;

        SocSecBracketLine.SetFilter(Amount, '>%1', Assoggettato);

        if SocSecBracketLine.FindSet() then
            repeat
                Gap := SocSecBracketLine.Amount - Assoggettato;
                if Gap < GrossAmount then begin
                    "INAIL Non Taxable Amount" := "INAIL Non Taxable Amount" + Round(Gap * (100 - SocSecBracketLine."Taxable Base %") / 100);
                    GrossAmount := GrossAmount - Gap;
                    Assoggettato := Assoggettato + Gap;
                end else begin
                    "INAIL Non Taxable Amount" := "INAIL Non Taxable Amount" +
                      Round(GrossAmount * (100 - SocSecBracketLine."Taxable Base %") / 100);

                    Assoggettato := Assoggettato + GrossAmount;
                    GrossAmount := 0;
                end;
            until (SocSecBracketLine.Next() = 0) or (GrossAmount = 0);

        Validate("INAIL Non Taxable Amount", "INAIL Non Taxable Amount" + GrossAmount);
        // END INAIL
    end;

    procedure ClearDeletedLineNos(GeneralJournalLine: Record "Gen. Journal Line")
    begin
        SetRange("Journal Template Name", GeneralJournalLine."Journal Template Name");
        SetRange("Journal Batch Name", GeneralJournalLine."Journal Batch Name");

        SetRange("Payment Line-Withholding", GeneralJournalLine."Line No.");
        if FindFirst() then begin
            Validate("Payment Line-Withholding", 0);
            Modify(true);
        end;
        SetRange("Payment Line-Withholding");

        SetRange("Payment Line-Soc. Sec.", GeneralJournalLine."Line No.");
        if FindFirst() then begin
            Validate("Payment Line-Soc. Sec.", 0);
            Modify(true);
        end;
        SetRange("Payment Line-Soc. Sec.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAll(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; var xTmpWithholdingContribution: Record "Tmp Withholding Contribution"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGrossAmount(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; var xTmpWithholdingContribution: Record "Tmp Withholding Contribution"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSocialSecurityCode(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; var xTmpWithholdingContribution: Record "Tmp Withholding Contribution"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateWithholdingTaxOnAfterAssignWithholdingTaxAmount(var TmpWithholdingContribution: Record "Tmp Withholding Contribution")
    begin
    end;
}

