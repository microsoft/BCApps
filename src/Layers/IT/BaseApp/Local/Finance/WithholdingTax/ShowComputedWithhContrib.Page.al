// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;

page 12111 "Show Computed Withh. Contrib."
{
    Caption = 'Show-Computed Withh-Contrib';
    PageType = Card;
    SourceTable = "Tmp Withholding Contribution";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Related Date"; Rec."Related Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the transaction date of the purchase that generated the payment journal entry.';
                }
                field("Payment Date"; Rec."Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that the taxes are paid to the tax authority.';
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code.';
                }
            }
            group("Withholding Tax")
            {
                Caption = 'Withholding Tax';
                field("Withholding Tax Code"; Rec."Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the withholding tax code that was applied to the original purchase.';
                }
                field("Total Amount"; Rec."Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to withholding tax.';
                }
                field("Base - Excluded Amount"; Rec."Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation based on exclusions allowed by law.';
                }
                field("Non Taxable Amount By Treaty"; Rec."Non Taxable Amount By Treaty")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from withholding tax based on residency.';
                }
                field("Non Taxable %"; Rec."Non Taxable %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percent of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Non Taxable Amount"; Rec."Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is not taxable due to provisions in the law.';
                }
                field("Taxable Base"; Rec."Taxable Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to withholding tax after nontaxable and excluded amounts have been subtracted.';

                    trigger OnValidate()
                    begin
                        Error('');
                    end;
                }
                field("Withholding Tax %"; Rec."Withholding Tax %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to withholding tax.';
                }
                field("Withholding Tax Amount"; Rec."Withholding Tax Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount of withholding tax that is due for this payment journal entry.';
                }
            }
            group("Social Security")
            {
                Caption = 'Social Security';
                field("Social Security Code"; Rec."Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Social Security code that is applied to the payment.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to Social Security withholding tax.';
                }
                field("Soc.Sec.Non Taxable Amount"; Rec."Soc.Sec.Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability based on provisions in the law.';
                }
                field("Contribution Base"; Rec."Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax after the nontaxable amount has been subtracted.';
                }
                field("Social Security %"; Rec."Social Security %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to Social Security tax.';
                }
                field("Total Social Security Amount"; Rec."Total Social Security Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of Social Security tax that is due for the purchase.';
                }
                field("Free-Lance %"; Rec."Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("Free-Lance Amount"; Rec."Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("Company Amount"; Rec."Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the amount of Social Security tax from the purchase that your company is liable for.';
                }
            }
            group(INAIL)
            {
                Caption = 'INAIL';
                field("INAIL Code"; Rec."INAIL Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the INAIL withholding tax code that is applied to this purchase for workers compensation insurance.';
                }
                field("INAIL Gross Amount"; Rec."INAIL Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to INAIL withholding tax.';
                }
                field("INAIL Non Taxable Amount"; Rec."INAIL Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase excluded from the INAIL withholding tax based on provisions in the law.';
                }
                field("INAIL Contribution Base"; Rec."INAIL Contribution Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to INAIL withholding tax, after non-taxable amounts have been subtracted.';
                }
                field("INAIL Per Mil"; Rec."INAIL Per Mil")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the purchase that is subject to INAIL withholding tax for workers compensation insurance.';
                }
                field("INAIL Total Amount"; Rec."INAIL Total Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of the INAIL withholding tax that is due for this purchase.';
                }
                field("INAIL Free-Lance %"; Rec."INAIL Free-Lance %")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the percentage of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("INAIL Free-Lance Amount"; Rec."INAIL Free-Lance Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("INAIL Company Amount"; Rec."INAIL Company Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Italian Workers'' Compensation Authority (INAIL) tax amount that your company is liable for.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Vend.Get(Rec."Vendor No.");
        CurrPage.Caption := Text1033 + Rec."Vendor No." + ' - ' + Vend.Name + ' - ' + Rec."Invoice No.";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush();
    end;

    var
        Text1033: Label 'INPS AND WITHH. TAXES - Vendor - ';
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        TmpGenJnlLine: Record "Gen. Journal Line" temporary;
        Vend: Record Vendor;
        PurchSetup: Integer;

    local procedure OKOnPush()
    var
        IsHandled: Boolean;
        LineExists: Boolean;
    begin
        IsHandled := false;
        OnBeforeOKOnPush(Rec, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine2.Reset();
        GenJnlLine2.SetRange("Journal Template Name", Rec."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        GenJnlLine2.SetRange("Line No.", Rec."Line No.");

        if GenJnlLine2.FindFirst() then begin
            if GenJnlLine2."Document Type" = GenJnlLine2."Document Type"::Payment then
                GenJnlLine2.Validate(Amount, GenJnlLine2.Amount - Rec."Withholding Tax Amount" + Rec."Old Withholding Amount" -
                  Rec."Free-Lance Amount" + Rec."Old Free-Lance Amount" -
                  Rec."INAIL Free-Lance Amount" + Rec."Old INAIL Free-Lance Amount")
            else
                GenJnlLine2.Validate(Amount, GenJnlLine2.Amount + Rec."Withholding Tax Amount" - Rec."Old Withholding Amount" +
                  Rec."Free-Lance Amount" - Rec."Old Free-Lance Amount" +
                  Rec."INAIL Free-Lance Amount" - Rec."Old INAIL Free-Lance Amount");
            GenJnlLine2.Modify();
            GenJnlLine2.SetRange("Line No.");
            TmpGenJnlLine.Copy(GenJnlLine2);

            if Rec."Withholding Tax Code" <> '' then begin
                if Rec."Payment Line-Withholding" = 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine.Copy(GenJnlLine2);
                    GenJnlLine2.Reset();
                    GenJnlLine2.SetRange("Journal Template Name", Rec."Journal Template Name");
                    GenJnlLine2.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    if GenJnlLine2.FindLast() then
                        PurchSetup := GenJnlLine2."Line No.";
                    GenJnlLine."Line No." := PurchSetup + 10000;
                    GenJnlLine."System-Created Entry" := true;
                end else begin
                    GenJnlLine.Reset();
                    GenJnlLine.SetRange("Journal Template Name", TmpGenJnlLine."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", TmpGenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Line No.", Rec."Payment Line-Withholding");
                    LineExists := GenJnlLine.FindFirst();
                    ClearFilters();
                end;
                GenJnlLine.Validate("Account No.");
                if Rec.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.") then;
                if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment then
                    GenJnlLine.Validate(Amount, Rec."Withholding Tax Amount")
                else
                    GenJnlLine.Validate(Amount, -Rec."Withholding Tax Amount");

                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine.Validate("Bal. Account No.", Rec."Withholding Account");

                if Rec."Payment Line-Withholding" = 0 then begin
                    if not LineExists then
                        GenJnlLine.Insert()
                    else
                        GenJnlLine.Modify();

                    Rec."Payment Line-Withholding" := GenJnlLine."Line No.";
                    Rec.Modify();
                end else
                    GenJnlLine.Modify();
            end;

            if (Rec."Social Security Code" <> '') and
               (Rec."Free-Lance Amount" <> 0)
            then begin
                if Rec."Payment Line-Soc. Sec." = 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine.Copy(TmpGenJnlLine);
                    if GenJnlLine2.FindLast() then
                        PurchSetup := GenJnlLine2."Line No.";
                    GenJnlLine."Line No." := PurchSetup + 10000;
                    GenJnlLine."System-Created Entry" := true;
                end else begin
                    GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
                    GenJnlLine.SetRange("Journal Template Name", TmpGenJnlLine."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", TmpGenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Line No.", Rec."Payment Line-Soc. Sec.");
                    GenJnlLine.FindFirst();
                    ClearFilters();
                end;

                GenJnlLine.Validate(Amount, Rec."Free-Lance Amount");
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine."Bal. Account No." := Rec."Social Security Acc.";
                if Rec."Payment Line-Soc. Sec." = 0 then begin
                    GenJnlLine.Insert();
                    Rec."Payment Line-Soc. Sec." := GenJnlLine."Line No.";
                    Rec.Modify();
                end else
                    GenJnlLine.Modify();
            end;

            if (Rec."Social Security Code" <> '') and
               (Rec."Company Amount" <> 0)
            then begin
                if Rec."Payment Line-Company" = 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine.Copy(TmpGenJnlLine);
                    if GenJnlLine2.FindLast() then
                        PurchSetup := GenJnlLine2."Line No.";
                    GenJnlLine."Line No." := PurchSetup + 10000;
                    GenJnlLine."System-Created Entry" := true;
                end else begin
                    GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
                    GenJnlLine.SetRange("Journal Template Name", TmpGenJnlLine."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", TmpGenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Line No.", Rec."Payment Line-Company");
                    GenJnlLine.FindFirst();
                    ClearFilters();
                end;
                GenJnlLine.Validate(Amount, Rec."Company Amount");
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine."Bal. Account No." := Rec."Social Security Acc.";

                GenJnlLine.Validate("Account No.", Rec."Social Security Charges Acc.");
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
                GenJnlLine."Applies-to Doc. No." := '';

                if Rec."Payment Line-Company" = 0 then begin
                    GenJnlLine.Insert();
                    Rec."Payment Line-Company" := GenJnlLine."Line No.";
                    Rec.Modify();
                end else
                    GenJnlLine.Modify();
            end;
            Rec."Old Withholding Amount" := Rec."Withholding Tax Amount";
            Rec."Old Free-Lance Amount" := Rec."Free-Lance Amount";
            Rec.Modify();

            if (Rec."INAIL Code" <> '') and
               (Rec."INAIL Free-Lance Amount" <> 0)
            then begin
                if Rec."INAIL Payment Line" = 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine.Copy(TmpGenJnlLine);
                    if GenJnlLine2.FindLast() then
                        PurchSetup := GenJnlLine2."Line No.";
                    GenJnlLine."Line No." := PurchSetup + 10000;
                    GenJnlLine."System-Created Entry" := true;
                end else begin
                    GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
                    GenJnlLine.SetRange("Journal Template Name", TmpGenJnlLine."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", TmpGenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Line No.", Rec."INAIL Payment Line");
                    GenJnlLine.FindFirst();
                    ClearFilters();
                end;
                GenJnlLine.Validate(Amount, Rec."INAIL Free-Lance Amount");
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine."Bal. Account No." := Rec."INAIL Debit Account";
                if Rec."INAIL Payment Line" = 0 then begin
                    GenJnlLine.Insert();
                    Rec."INAIL Payment Line" := GenJnlLine."Line No.";
                    Rec.Modify();
                end else
                    GenJnlLine.Modify();
            end;

            if (Rec."INAIL Code" <> '') and
               (Rec."INAIL Company Amount" <> 0)
            then begin
                if Rec."INAIL Company Payment Line" = 0 then begin
                    GenJnlLine.Init();
                    GenJnlLine.Copy(TmpGenJnlLine);
                    if GenJnlLine2.FindLast() then
                        PurchSetup := GenJnlLine2."Line No.";
                    GenJnlLine."Line No." := PurchSetup + 10000;
                    GenJnlLine."System-Created Entry" := true;
                end else begin
                    GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
                    GenJnlLine.SetRange("Journal Template Name", TmpGenJnlLine."Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", TmpGenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Line No.", Rec."Payment Line-Company");
                    GenJnlLine.FindFirst();
                    ClearFilters();
                end;
                GenJnlLine.Validate(Amount, Rec."INAIL Company Amount");
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                GenJnlLine."Bal. Account No." := Rec."INAIL Debit Account";

                GenJnlLine.Validate("Account No.", Rec."INAIL Charge Account");
                GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::" ";
                GenJnlLine."Applies-to Doc. No." := '';

                if Rec."INAIL Company Payment Line" = 0 then begin
                    GenJnlLine.Insert();
                    Rec."INAIL Company Payment Line" := GenJnlLine."Line No.";
                    Rec.Modify();
                end else
                    GenJnlLine.Modify();
            end;
            Rec."Old Free-Lance Amount" := Rec."INAIL Free-Lance Amount";
            Rec.Modify();
        end;
    end;

    local procedure ClearFilters()
    begin
        GenJnlLine.SetRange("Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name");
        GenJnlLine.SetRange("Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOKOnPush(var TmpWithholdingContribution: Record "Tmp Withholding Contribution"; var IsHandled: Boolean)
    begin
    end;
}

