// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Finance.Currency;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

table 12137 "Purch. Withh. Contribution"
{
    Caption = 'Purch. Withh. Contribution';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "Total Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Amount';

            trigger OnValidate()
            begin
                GetHeader();
                ValorizzaRitenute();
                if "Social Security Code" <> '' then
                    ValorizzaINPS("Total Amount");

                if "INAIL Code" <> '' then
                    ValorizzaINAIL("Total Amount");

                if "Total Amount" = 0 then begin
                    "Base - Excluded Amount" := 0;
                    "Non Taxable Amount By Treaty" := 0;
                end;
            end;
        }
        field(6; "Base - Excluded Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Base - Excluded Amount';

            trigger OnValidate()
            begin
                CheckBaseExcludedAmount();

                GetHeader();

                ValorizzaRitenute();
                if "Social Security Code" <> '' then
                    ValorizzaINPS("Total Amount");

                // INAIL START
                if "INAIL Code" <> '' then
                    ValorizzaINAIL("Taxable Base");
                // INAIL END
            end;
        }
        field(7; "Non Taxable Amount By Treaty"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount By Treaty';

            trigger OnValidate()
            begin
                CheckNonTaxableAmountByTreaty();

                GetHeader();

                if Vend.Resident = Vend.Resident::Resident then
                    if not Confirm(ResidentVendorWarningQst, false, Vend."No.") then
                        "Non Taxable Amount By Treaty" := xRec."Non Taxable Amount By Treaty";

                ValorizzaRitenute();
                if "Social Security Code" <> '' then
                    ValorizzaINPS("Total Amount");

                // INAIL START
                if "INAIL Code" <> '' then
                    ValorizzaINAIL("Taxable Base");
                // INAIL END
            end;
        }
        field(8; "Non Taxable Amount %"; Decimal)
        {
            Caption = 'Non Taxable Amount %';
            DecimalPlaces = 3 : 3;
        }
        field(9; "Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Non Taxable Amount';
        }
        field(10; "Taxable Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Taxable Base';
        }
        field(11; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code".Code;

            trigger OnValidate()
            begin
                GetHeader();
                ValorizzaRitenute();
                if "Social Security Code" <> '' then
                    ValorizzaINPS("Total Amount");

                // INAIL START
                if "INAIL Code" <> '' then
                    ValorizzaINAIL("Taxable Base");
                // INAIL END
            end;
        }
        field(12; "Withholding Tax %"; Decimal)
        {
            Caption = 'Withholding Tax %';
            DecimalPlaces = 3 : 3;
        }
        field(13; "Withholding Tax Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Withholding Tax Amount';

            trigger OnValidate()
            begin
                "Payable Amount" := PurchHeader."Check Total" - "Withholding Tax Amount" - "Free-Lance Amount" - "INAIL Free-Lance Amount";
            end;
        }
        field(14; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));

            trigger OnValidate()
            begin
                GetHeader();

                if "Social Security Code" <> '' then
                    ValorizzaINPS("Total Amount")
                else begin
                    "Gross Amount" := 0;
                    "Social Security %" := 0;
                    "Free-Lance %" := 0;
                    Validate("Soc.Sec.Non Taxable Amount", 0);
                end;
            end;
        }
        field(15; "Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Gross Amount';

            trigger OnValidate()
            begin
                GetHeader();
                ValorizzaINPS("Gross Amount");
            end;
        }
        field(16; "Soc.Sec.Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Soc.Sec.Non Taxable Amount';

            trigger OnValidate()
            begin
                GetHeader();
                "Contribution Base" := "Gross Amount" - "Soc.Sec.Non Taxable Amount";
                "Total Social Security Amount" := Round("Contribution Base" * "Social Security %" / 100, Curr.
                    "Amount Rounding Precision");
                Validate("Free-Lance Amount", Round("Total Social Security Amount" * "Free-Lance %" / 100, Curr.
                    "Amount Rounding Precision"));
            end;
        }
        field(17; "Contribution Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Contribution Base';
        }
        field(18; "Social Security %"; Decimal)
        {
            Caption = 'Social Security %';
            DecimalPlaces = 3 : 3;
        }
        field(19; "Total Social Security Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Social Security Amount';
        }
        field(20; "Free-Lance %"; Decimal)
        {
            Caption = 'Free-Lance %';
            DecimalPlaces = 4 : 4;
        }
        field(21; "Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Free-Lance Amount';

            trigger OnValidate()
            begin
                GetHeader();
                "Company Amount" := "Total Social Security Amount" - "Free-Lance Amount";

                // INAIL START
                /*Orig.*/
                "Payable Amount" := PurchHeader."Check Total" - "Withholding Tax Amount" - "Free-Lance Amount";
                "Payable Amount" := PurchHeader."Check Total" -
                  "Withholding Tax Amount" -
                  "Free-Lance Amount" -
                  "INAIL Free-Lance Amount";
                // INAIL END

            end;
        }
        field(22; "Company Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Company Amount';
        }
        field(25; "Date Related"; Date)
        {
            Caption = 'Date Related';
        }
        field(26; "Payable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Payable Amount';
        }
        field(27; "Payment Date"; Date)
        {
            Caption = 'Payment Date';

            trigger OnValidate()
            begin
                GetHeader();
                ValorizzaRitenute();
                if "Social Security Code" <> '' then
                    ValorizzaINPS("Total Amount");

                // INAIL START
                if "INAIL Code" <> '' then
                    ValorizzaINAIL("Taxable Base");
                // INAIL END
            end;
        }
        field(28; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(30; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INAIL));

            trigger OnValidate()
            begin
                GetHeader();

                if "INAIL Code" <> '' then
                    ValorizzaINAIL("Taxable Base")
                else begin
                    "INAIL Gross Amount" := 0;
                    "INAIL Per Mil" := 0;
                    "INAIL Free-Lance %" := 0;
                    Validate("INAIL Non Taxable Amount", 0);
                end;
            end;
        }
        field(31; "INAIL Gross Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Gross Amount';

            trigger OnValidate()
            begin
                GetHeader();
                ValorizzaINAIL("INAIL Gross Amount");
            end;
        }
        field(32; "INAIL Non Taxable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Non Taxable Amount';

            trigger OnValidate()
            begin
                GetHeader();
                "INAIL Contribution Base" := "INAIL Gross Amount" - "INAIL Non Taxable Amount";
                "INAIL Total Amount" := Round("INAIL Contribution Base" * "INAIL Per Mil" / 1000, Curr.
                    "Amount Rounding Precision");
                Validate("INAIL Free-Lance Amount", Round("INAIL Total Amount" * "INAIL Free-Lance %" / 100, Curr.
                    "Amount Rounding Precision"));
            end;
        }
        field(33; "INAIL Contribution Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Contribution Base';
        }
        field(34; "INAIL Per Mil"; Decimal)
        {
            Caption = 'INAIL Per Mil';
            DecimalPlaces = 3 : 3;
        }
        field(35; "INAIL Total Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Total Amount';
        }
        field(36; "INAIL Free-Lance %"; Decimal)
        {
            Caption = 'INAIL Free-Lance %';
            DecimalPlaces = 4 : 4;
        }
        field(37; "INAIL Free-Lance Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Free-Lance Amount';

            trigger OnValidate()
            begin
                GetHeader();
                "INAIL Company Amount" := "INAIL Total Amount" - "INAIL Free-Lance Amount";

                "Payable Amount" := PurchHeader."Check Total" -
                  "Withholding Tax Amount" -
                  "Free-Lance Amount" -
                  "INAIL Free-Lance Amount";
            end;
        }
        field(38; "INAIL Company Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'INAIL Company Amount';
        }
        field(39; "WHT Amount Manual"; Decimal)
        {
            Caption = 'WHT Amount Manual';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("Withholding Tax Amount");
                if "WHT Amount Manual" = "Withholding Tax Amount" then
                    Error(
                      StrSubstNo(WHTAmtManualEqWHTAmtErr, FieldCaption("WHT Amount Manual"), FieldCaption("Withholding Tax Amount"), TableCaption));

                GetHeader();
                if "WHT Amount Manual" <> 0 then begin
                    "WHT Amount Manual" := Round("WHT Amount Manual", Curr."Amount Rounding Precision");
                    if "Taxable Base" <> 0 then
                        "Withholding Tax %" := Round(("WHT Amount Manual" / "Taxable Base") * 100, Curr."Amount Rounding Precision");
                    Validate("Withholding Tax Amount", "WHT Amount Manual");
                end else begin
                    if "Payment Date" <> 0D then
                        SocSecBracketLine.WithholdLineFilter(PurchSetup, "Withholding Tax Code", "Payment Date")
                    else
                        SocSecBracketLine.WithholdLineFilter(PurchSetup, "Withholding Tax Code", PurchHeader."Document Date");

                    "Withholding Tax %" := PurchSetup."Withholding Tax %";
                    Validate("Withholding Tax Amount", Round("Taxable Base" * "Withholding Tax %" / 100, Curr."Amount Rounding Precision"));
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        InvalidBaseExcludedAmountErr: Label 'The Base - Excluded Amount must not be greater than %1.';
        BaseExcludedAmtGreaterThanTotalErr: Label 'The Base - Excluded Amount must not be greater than Total Amount.';
        InvalidNonTaxableAmountByTreatyErr: Label 'The Non Taxable Amount By Treaty must not be greater than %1.';
        ResidentVendorWarningQst: Label 'Vendor %1 is resident. Do you want to continue?';
        Curr: Record Currency;
        Vend: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchSetup: Record "Withhold Code Line";
        WithholdCodeLine: Record "Contribution Code Line";
        SocSecCodeLine: Record "Contribution Bracket Line";
        WithholdFilter: Record "Contribution Code Line";
        RigheScaglioniINAIL: Record "Contribution Bracket Line";
        SocSecBracketLine: Codeunit "Withholding - Contribution";
        WHTAmtManualEqWHTAmtErr: Label '%1 must not be equal to %2 in %3.', Comment = '%1=FIELDCAPTION("WHT Amount Manual"),%2=FIELDCAPTION("Withholding Tax Amount"),%3=TABLECAPTION("Purch. Withh. Contribution")';

    procedure ValorizzaRitenute()
    begin
        if "Payment Date" <> 0D then
            SocSecBracketLine.WithholdLineFilter(PurchSetup, "Withholding Tax Code", "Payment Date")
        else
            SocSecBracketLine.WithholdLineFilter(PurchSetup, "Withholding Tax Code", PurchHeader."Document Date");

        "Withholding Tax %" := PurchSetup."Withholding Tax %";
        "Non Taxable Amount %" := 100 - PurchSetup."Taxable Base %";

        "Taxable Base" := Round(((
                                  "Total Amount" -
                                  "Base - Excluded Amount" -
                                  "Non Taxable Amount By Treaty") *
                                 PurchSetup."Taxable Base %") / 100);
        "Non Taxable Amount" := "Total Amount" -
          "Base - Excluded Amount" -
          "Non Taxable Amount By Treaty" -
          "Taxable Base";

        OnValorizzaRitenuteOnBeforeValidateWithholdingTaxAmount(Rec);

        Validate("Withholding Tax Amount", Round("Taxable Base" * "Withholding Tax %" / 100, Curr."Amount Rounding Precision"));
    end;

    procedure ValorizzaINPS(GrossAmount: Decimal)
    var
        Assoggettato: Decimal;
        Gap: Decimal;
    begin
        if "Payment Date" <> 0D then begin
            SocSecBracketLine.SetSocSecLineFilters(
                WithholdCodeLine, "Social Security Code", "Payment Date", WithholdCodeLine."Contribution Type"::INPS);

            Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY("Payment Date", 3)),
              DMY2Date(31, 12, Date2DMY("Payment Date", 3)));
        end else begin
            SocSecBracketLine.SetSocSecLineFilters(
                WithholdCodeLine, "Social Security Code", PurchHeader."Document Date", WithholdCodeLine."Contribution Type"::INPS);

            Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY(PurchHeader."Document Date", 3)),
              DMY2Date(31, 12, Date2DMY(PurchHeader."Document Date", 3)));
        end;

        SocSecBracketLine.SetSocSecBracketFilters(
            SocSecCodeLine,
            WithholdCodeLine."Social Security Bracket Code",
            WithholdCodeLine."Contribution Type"::INPS, WithholdCodeLine.Code);

        "Social Security %" := WithholdCodeLine."Social Security %";
        "Free-Lance %" := WithholdCodeLine."Free-Lance Amount %";

        Vend.CalcFields("Soc. Sec. Company Base");

        Assoggettato := Vend."Soc. Sec. Company Base" + Vend."Soc. Sec. 3 Parties Base" +
          SocSecBracketLine.GetCompContribRemGrossAmtForVendorInPeriod(
            Vend."No.",
            CalcDate('<-CY>', "Date Related"),
            CalcDate('<CY>', "Date Related"));

        if SocSecCodeLine.Amount - Assoggettato > GrossAmount then
            "Gross Amount" := GrossAmount
        else
            "Gross Amount" := SocSecCodeLine.Amount - Assoggettato;

        if "Gross Amount" > 0 then begin
            // "Importo Lordo Sogg. a Contrib." := 0;

            GrossAmount := "Gross Amount";

            "Soc.Sec.Non Taxable Amount" := 0;
            SocSecCodeLine.SetFilter(Amount, '>%1', Assoggettato);
            if SocSecCodeLine.FindSet() then
                repeat
                    Gap := SocSecCodeLine.Amount - Assoggettato;
                    if Gap < GrossAmount then begin
                        "Soc.Sec.Non Taxable Amount" := "Soc.Sec.Non Taxable Amount" +
                          Round(Gap * (100 - SocSecCodeLine."Taxable Base %") / 100, Curr."Amount Rounding Precision");
                        GrossAmount := GrossAmount - Gap;
                        Assoggettato := Assoggettato + Gap;
                    end else begin
                        "Soc.Sec.Non Taxable Amount" := "Soc.Sec.Non Taxable Amount" +
                          Round(GrossAmount * (100 - SocSecCodeLine."Taxable Base %") / 100, Curr."Amount Rounding Precision");
                        Assoggettato := Assoggettato + GrossAmount;
                        GrossAmount := 0;
                    end;
                until (SocSecCodeLine.Next() = 0) or (GrossAmount = 0);

            Validate("Soc.Sec.Non Taxable Amount", "Soc.Sec.Non Taxable Amount" + GrossAmount);
        end;
    end;

    local procedure CheckBaseExcludedAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBaseExcludedAmount(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Base - Excluded Amount" > (Rec."Total Amount" - Rec."Non Taxable Amount By Treaty") then
            Error(InvalidBaseExcludedAmountErr, Rec."Total Amount" - Rec."Non Taxable Amount By Treaty");

        if Rec."Base - Excluded Amount" > Rec."Total Amount" then
            Error(BaseExcludedAmtGreaterThanTotalErr);
    end;

    local procedure CheckNonTaxableAmountByTreaty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNonTaxableAmountByTreaty(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Non Taxable Amount By Treaty" > (Rec."Total Amount" - Rec."Base - Excluded Amount") then
            Error(InvalidNonTaxableAmountByTreatyErr, Rec."Total Amount" - Rec."Base - Excluded Amount");
    end;

    procedure GetHeader()
    begin
        PurchHeader.Get("Document Type", "No.");
        Vend.Get(PurchHeader."Buy-from Vendor No.");
        if "Currency Code" = '' then
            Curr.InitRoundingPrecision()
        else
            Curr.Get("Currency Code");
    end;

    procedure ValorizzaINAIL(GrossAmountINAIL: Decimal)
    var
        AssoggettatoINAIL: Decimal;
        GapINAIL: Decimal;
    begin
        // INAIL START
        if "Payment Date" <> 0D then begin
            SocSecBracketLine.SetSocSecLineFilters(
                WithholdFilter, "INAIL Code", "Payment Date", WithholdFilter."Contribution Type"::INAIL);

            Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY("Payment Date", 3)),
              DMY2Date(31, 12, Date2DMY("Payment Date", 3)));
        end else begin
            SocSecBracketLine.SetSocSecLineFilters(
                WithHoldFilter, "INAIL Code", PurchHeader."Document Date", WithholdFilter."Contribution Type"::INAIL);

            Vend.SetFilter("Date Filter", '%1..%2', DMY2Date(1, 1, Date2DMY(PurchHeader."Document Date", 3)),
              DMY2Date(31, 12, Date2DMY(PurchHeader."Document Date", 3)));
        end;

        SocSecBracketLine.SetSocSecBracketFilters(
            RigheScaglioniINAIL,
            WithholdFilter."Social Security Bracket Code",
            WithholdFilter."Contribution Type"::INAIL, WithholdFilter.Code);

        "INAIL Per Mil" := WithholdFilter."Social Security %";
        "INAIL Free-Lance %" := WithholdFilter."Free-Lance Amount %";

        Vend.CalcFields("INAIL Company Base");
        AssoggettatoINAIL := Vend."INAIL Company Base" + Vend."INAIL 3 Parties Base";

        if RigheScaglioniINAIL.Amount - AssoggettatoINAIL > GrossAmountINAIL then
            "INAIL Gross Amount" := GrossAmountINAIL
        else
            "INAIL Gross Amount" := RigheScaglioniINAIL.Amount - AssoggettatoINAIL;

        if "INAIL Gross Amount" > 0 then begin
            // "Imp. Lordo Sogg. a Contr.INAIL" := 0;

            GrossAmountINAIL := "Gross Amount";

            "INAIL Non Taxable Amount" := 0;
            RigheScaglioniINAIL.SetFilter(Amount, '>%1', AssoggettatoINAIL);
            if RigheScaglioniINAIL.FindSet() then
                repeat
                    GapINAIL := RigheScaglioniINAIL.Amount - AssoggettatoINAIL;
                    if GapINAIL < GrossAmountINAIL then begin
                        "INAIL Non Taxable Amount" := "INAIL Non Taxable Amount" +
                          Round(GapINAIL * (100 - RigheScaglioniINAIL."Taxable Base %") / 100, Curr."Amount Rounding Precision");
                        GrossAmountINAIL := GrossAmountINAIL - GapINAIL;
                        AssoggettatoINAIL := AssoggettatoINAIL + GapINAIL;
                    end else begin
                        "INAIL Non Taxable Amount" := "INAIL Non Taxable Amount" +
                          Round(GrossAmountINAIL * (100 - RigheScaglioniINAIL."Taxable Base %") / 100, Curr."Amount Rounding Precision");
                        AssoggettatoINAIL := AssoggettatoINAIL + GrossAmountINAIL;
                        GrossAmountINAIL := 0;
                    end;
                until (RigheScaglioniINAIL.Next() = 0) or (GrossAmountINAIL = 0);

            Validate("INAIL Non Taxable Amount", "INAIL Non Taxable Amount" + GrossAmountINAIL);
            // INAIL END
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateRecord(PurchaseHeader: Record "Purchase Header"; Vend: Record Vendor)
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        if PurchaseHeader."No." = '' then
            exit;

        DeleteRecByPurchHeader(PurchaseHeader);

        if Vend."Withholding Tax Code" <> '' then begin
            PurchWithhContribution.Init();
            PurchWithhContribution.Validate("Document Type", PurchaseHeader."Document Type");
            PurchWithhContribution.Validate("No.", PurchaseHeader."No.");
            PurchWithhContribution.Validate("Date Related", PurchaseHeader."Document Date");
            PurchWithhContribution."Withholding Tax Code" := Vend."Withholding Tax Code";
            PurchWithhContribution."Social Security Code" := Vend."Social Security Code";
            PurchWithhContribution."INAIL Code" := Vend."INAIL Code";
            PurchWithhContribution.Validate("Currency Code", Vend."Currency Code");
            PurchWithhContribution.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateDateRelatedWithPurchHeaderDocDate(PurchaseHeader: Record "Purchase Header")
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        if PurchaseHeader."No." = '' then
            exit;

        if PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
            PurchWithhContribution.Validate("Date Related", PurchaseHeader."Document Date");
            PurchWithhContribution.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteRecByPurchHeader(PurchaseHeader: Record "Purchase Header")
    var
        PurchWithhContribution: Record "Purch. Withh. Contribution";
    begin
        if PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then
            PurchWithhContribution.Delete(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBaseExcludedAmount(var PurchWithhContribution: Record "Purch. Withh. Contribution"; xPurchWithhContribution: Record "Purch. Withh. Contribution"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNonTaxableAmountByTreaty(var PurchWithhContribution: Record "Purch. Withh. Contribution"; xPurchWithhContribution: Record "Purch. Withh. Contribution"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValorizzaRitenuteOnBeforeValidateWithholdingTaxAmount(var PurchWithhContribution: Record "Purch. Withh. Contribution")
    begin
    end;
}

