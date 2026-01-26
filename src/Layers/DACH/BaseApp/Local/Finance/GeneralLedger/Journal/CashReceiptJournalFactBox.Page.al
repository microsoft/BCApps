// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

page 35516 "Cash Receipt Journal FactBox"
{
    Caption = 'Cash Receipt Journal Details';
    PageType = CardPart;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            field(AccName; AccName)
            {
                ApplicationArea = All;
                Caption = 'Name';
                Editable = false;
                ToolTip = 'Specifies the name of the payment recipient.';
            }
            field(CustPaymtTerm; CustPaymtTerm)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Terms';
                Editable = false;
                ToolTip = 'Specifies the payment terms of the customer.';
            }
            field(OeRemainAmountFC; OeRemainAmountFC)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Amt.';
                Editable = false;
                ToolTip = 'Specifies the remaining amount for the open entry.';
            }
            field(PaymentAmt; PaymentAmt)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment';
                Editable = false;
                ToolTip = 'Specifies the payment amount of the actual line.';
            }
            field(RemainAfterPaymentText; RemainAfterPaymentText)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = Format(RemainAfterPaymentCaption);
                Caption = 'Remaining after Payment';
                Editable = false;
                ToolTip = 'Specifies how much remains to be paid.';
            }
            field(PMTDiscount; PMTDiscount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pmt. Discount';
                Editable = false;
                ToolTip = 'Specifies the possible payment discount.';
            }
            field(PaymDiscDeductAmount; PaymDiscDeductAmount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deduction';
                Editable = false;
                ToolTip = 'Specifies the accepted payment discount deduction.';
            }
            field(AcceptedPaymentTol; AcceptedPaymentTol)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pmt. Tolerance';
                Editable = false;
                ToolTip = 'Specifies the accepted payment tolerance.';
            }
            field(PostingDate; PostingDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Age';
                Editable = false;
                ToolTip = 'Specifies the posting date of the open entry.';
            }
            field(AgeDays; AgeDays)
            {
                ApplicationArea = Basic, Suite;
                BlankZero = true;
                Caption = 'Age Days';
                Editable = false;
                ToolTip = 'Specifies the number of days since the posting date of the open entry.';
            }
            field(DueDate; DueDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Due';
                Editable = false;
                ToolTip = 'Specifies the due date of the open entry.';
            }
            field(DueDays; DueDays)
            {
                ApplicationArea = Basic, Suite;
                BlankZero = true;
                Caption = 'Due Days';
                Editable = false;
                ToolTip = 'Specifies the number of days until the due date of the open entry.';
            }
            field(PmtDiscDate; PmtDiscDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Discount';
                Editable = false;
                ToolTip = 'Specifies the payment discount date of the open entry.';
            }
            field(PaymDiscDays; PaymDiscDays)
            {
                ApplicationArea = Basic, Suite;
                BlankZero = true;
                Caption = 'Cash Discount Days';
                Editable = false;
                ToolTip = 'Specifies the number of days to the payment discount date.';
            }
            field(TotalPayment; TotalPayAmount)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Payments';
                Editable = false;
                ToolTip = 'Specifies the total of payments in LCY.';
            }
            field(Balance; Balance)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Balance';
                Editable = false;
                ToolTip = 'Specifies the balance on the actual line in LCY.';
            }
            field(TotalBalance; TotalBalance)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Total Balance';
                Editable = false;
                ToolTip = 'Specifies the total balance in LCY.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);

        Factor := 1;
        if Rec."Bal. Account Type" = Rec."Bal. Account Type"::Customer then
            Factor := -1;

        UpdateBalance();
        UpdateInfoBox();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then begin
            GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
            UpdateBalance();
            UpdateInfoBox();
        end else
            ClearGlobalsWhenNotFound(Which);
        exit(Rec.Find(Which));
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;
        AccName: Text[100];
        BalAccName: Text[100];
        RemainAfterPaymentCaption: Text[30];
        RemainAfterPaymentText: Text[30];
        Balance: Decimal;
        TotalBalance: Decimal;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        AgeDays: Integer;
        PaymDiscDays: Integer;
        DueDays: Integer;
        OeRemainAmountFC: Decimal;
        PaymDiscDeductAmount: Decimal;
        RemainAfterPayment: Decimal;
        TotalPayAmount: Decimal;
        PMTDiscount: Decimal;
        AcceptedPaymentTol: Decimal;
        Text001: Label 'Remaining after Payment';
        Text002: Label '<Precision,2:2><Standard Format,0>', Locked = true;
        PaymentAmt: Decimal;
        PostingDate: Date;
        DueDate: Date;
        PmtDiscDate: Date;
        CustPaymtTerm: Code[10];
        Factor: Integer;

    local procedure UpdateBalance()
    var
        GenJnlLine: Record "Gen. Journal Line";
        LineNo: Integer;
    begin
        Balance := 0;
        TotalBalance := 0;
        TotalPayAmount := 0;
        PaymentAmt := -Rec.Amount * Factor;

        LineNo := Rec."Line No.";

        GenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Account Type", "Document Type");
        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        GenJnlLine.CalcSums("Balance (LCY)");
        TotalBalance := GenJnlLine."Balance (LCY)";

        GenJnlLine.SetFilter("Line No.", '<=%1', LineNo);
        GenJnlLine.CalcSums("Balance (LCY)");
        Balance := GenJnlLine."Balance (LCY)";

        GenJnlLine.SetRange("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.SetFilter("Document Type", '%1|%2', GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::Refund);
        GenJnlLine.SetRange("Line No.");
        GenJnlLine.CalcSums("Amount (LCY)");
        TotalPayAmount := -GenJnlLine."Amount (LCY)";

        GenJnlLine.SetRange("Account Type");
        GenJnlLine.SetRange("Bal. Account Type", GenJnlLine."Bal. Account Type"::Customer);
        GenJnlLine.CalcSums("Amount (LCY)");
        TotalPayAmount += GenJnlLine."Amount (LCY)";
    end;

    local procedure ClearGlobalsWhenNotFound(Which: Text)
    begin
        PaymentAmt := 0;
        AccName := '';
        BalAccName := '';
        AgeDays := 0;
        PaymDiscDays := 0;
        DueDays := 0;
        OeRemainAmountFC := 0;
        PaymDiscDeductAmount := 0;
        RemainAfterPayment := 0;
        PMTDiscount := 0;
        AcceptedPaymentTol := 0;
        PostingDate := 0D;
        DueDate := 0D;
        PmtDiscDate := 0D;
        CustPaymtTerm := '';
        Balance := 0;
        TotalBalance := 0;
        TotalPayAmount := 0;

        OnAfterClearGlobalsWhenNotFound(Rec, Which);
    end;

    [Scope('OnPrem')]
    procedure UpdateInfoBox()
    var
        ExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        IsAppliedToOneEntry: Boolean;
        IsHandled: Boolean;
        CurrOeRemainAmountFC: Decimal;
        CurrPMTDiscount: Decimal;
        CurrPaymDiscDeductAmount: Decimal;
        CurrAcceptedPaymentTol: Decimal;
        CurrRemainAfterPayment: Decimal;
    begin
        OnBeforeUpdateInfoBox(Rec);

        AgeDays := 0;
        PaymDiscDays := 0;
        DueDays := 0;
        OeRemainAmountFC := 0;
        PaymDiscDeductAmount := 0;
        RemainAfterPayment := -Rec.Amount * Factor;
        PMTDiscount := 0;
        AcceptedPaymentTol := 0;
        RemainAfterPaymentCaption := Text001;
        RemainAfterPaymentText := Format(0.0, 0, Text002);
        PostingDate := 0D;
        DueDate := 0D;
        PmtDiscDate := 0D;
        CustPaymtTerm := '';

        CustLedgEntry.Reset();
        Cust.Init();

        case true of
            Rec."Applies-to ID" <> '':
                CustLedgEntry.SetRange("Applies-to ID", Rec."Applies-to ID");
            Rec."Applies-to Doc. No." <> '':
                begin
                    CustLedgEntry.SetRange("Document Type", Rec."Applies-to Doc. Type");
                    CustLedgEntry.SetRange("Document No.", Rec."Applies-to Doc. No.");
                end;
            else
                exit;
        end;

        IsHandled := false;
        OnUpdateInfoBoxOnAfterSetCustLedgEntryFilters(Rec, CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if not CustLedgEntry.FindSet() then
            exit;

        if Currency.ReadPermission then
            if not Currency.Get(Rec."Currency Code") then
                Currency.InitRoundingPrecision();

        if not Cust.Get(CustLedgEntry."Customer No.") then;
        IsAppliedToOneEntry := CustLedgEntry.Count = 1;
        CustPaymtTerm := Cust."Payment Terms Code";
        repeat
            CurrRemainAfterPayment := 0;
            // Calculate Days for Age, Payment Discount
            if (Rec."Posting Date" > 0D) and IsAppliedToOneEntry then begin
                PostingDate := CustLedgEntry."Posting Date";
                DueDate := CustLedgEntry."Due Date";
                PmtDiscDate := CustLedgEntry."Pmt. Discount Date";
                if CustLedgEntry."Posting Date" > 0D then
                    AgeDays := Rec."Posting Date" - CustLedgEntry."Posting Date";
                if CustLedgEntry."Pmt. Discount Date" > 0D then
                    PaymDiscDays := CustLedgEntry."Pmt. Discount Date" - Rec."Posting Date";
                if CustLedgEntry."Due Date" > 0D then
                    DueDays := CustLedgEntry."Due Date" - Rec."Posting Date";
            end;

            OnUpdateInfoBoxOnAFterCalculateDays(CustLedgEntry);

            CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            OnUpdateInfoBoxOnAfterCalcRemainingAmount(CustLedgEntry);

            CurrOeRemainAmountFC := CustLedgEntry."Remaining Amount";
            CurrPMTDiscount :=
              ExchRate.ExchangeAmtFCYToFCY(Rec."Posting Date", CustLedgEntry."Currency Code",
                Rec."Currency Code", CustLedgEntry."Remaining Pmt. Disc. Possible");
            CurrPMTDiscount := Round(CurrPMTDiscount, Currency."Amount Rounding Precision");
            OnUpdateInfoBoxOnAfterCalcCurrPMTDiscount(Rec."Posting Date", PostingDate, CustLedgEntry, PmtDiscDate, DueDate, AgeDays, PaymDiscDays, DueDays);

            // calculate FC-amount of open entries and remaining amount
            if CustLedgEntry."Currency Code" <> Rec."Currency Code" then begin
                CurrOeRemainAmountFC :=
                  ExchRate.ExchangeAmtLCYToFCY(Rec."Posting Date", Rec."Currency Code", CustLedgEntry."Remaining Amt. (LCY)", Rec."Currency Factor");
                CurrOeRemainAmountFC := Round(CurrOeRemainAmountFC, Currency."Amount Rounding Precision");
            end;

            if (CustLedgEntry."Pmt. Discount Date" >= Rec."Posting Date") or
               ((CustLedgEntry."Pmt. Disc. Tolerance Date" >= Rec."Posting Date") and
                CustLedgEntry."Accepted Pmt. Disc. Tolerance")
            then begin
                CurrPaymDiscDeductAmount := CustLedgEntry."Remaining Pmt. Disc. Possible";
                if CustLedgEntry."Currency Code" <> Rec."Currency Code" then
                    CurrPaymDiscDeductAmount :=
                      ExchRate.ExchangeAmtFCYToFCY(
                        Rec."Posting Date", CustLedgEntry."Currency Code", Rec."Currency Code", CurrPaymDiscDeductAmount);
            end;
            CurrPaymDiscDeductAmount := Round(CurrPaymDiscDeductAmount, Currency."Amount Rounding Precision");

            // Accepted Payment Tolerance
            CurrAcceptedPaymentTol := CustLedgEntry."Accepted Payment Tolerance";
            if CustLedgEntry."Currency Code" <> Rec."Currency Code" then
                CurrAcceptedPaymentTol :=
                  ExchRate.ExchangeAmtFCYToFCY(
                    Rec."Posting Date", CustLedgEntry."Currency Code", Rec."Currency Code", CurrAcceptedPaymentTol);
            CurrAcceptedPaymentTol := Round(CurrAcceptedPaymentTol, Currency."Amount Rounding Precision");

            CurrRemainAfterPayment := -CurrOeRemainAmountFC + CurrPaymDiscDeductAmount + CurrAcceptedPaymentTol;

            if (Rec."Currency Code" <> CustLedgEntry."Currency Code") and
               ((Rec."Currency Code" <> '') and (CustLedgEntry."Currency Code" <> ''))
            then begin
                RemainAfterPaymentCaption := '';
                RemainAfterPaymentText := '';
                exit;
            end;

            // Pmt. Disc is not applied if entry is not closed
            if CurrRemainAfterPayment > 0 then begin
                CurrRemainAfterPayment := CurrRemainAfterPayment - CurrPaymDiscDeductAmount;
                RemainAfterPaymentText := Format(CurrRemainAfterPayment, 0, Text002);
                CurrPaymDiscDeductAmount := 0;
            end;
            OeRemainAmountFC += CurrOeRemainAmountFC;
            PMTDiscount += CurrPMTDiscount;
            PaymDiscDeductAmount += CurrPaymDiscDeductAmount;
            AcceptedPaymentTol += CurrAcceptedPaymentTol;
            RemainAfterPayment += CurrRemainAfterPayment;
            RemainAfterPaymentText := Format(RemainAfterPayment, 0, Text002);
        until CustLedgEntry.Next() = 0;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterClearGlobalsWhenNotFound(var GenJournalLine: Record "Gen. Journal Line"; Which: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateInfoBox(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateInfoBoxOnAfterCalculateDays(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInfoBoxOnAfterCalcCurrPMTDiscount(PostingDateField: Date; PostingDate: Date; CustLedgEntry: Record "Cust. Ledger Entry"; PmtDiscDate: Date; DueDate: Date; AgeDays: Integer; PaymDiscDays: Integer; DueDays: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInfoBoxOnAfterSetCustLedgEntryFilters(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInfoBoxOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

