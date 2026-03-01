namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;

codeunit 8067 "Customer Deferrals Mngmt."
{
    SingleInstance = true;
    Permissions =
        tabledata "Sales Invoice Line" = r;

    var
        GLSetup: Record "General Ledger Setup";
        DeferralEntryNo: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnPrepareLineOnBeforeSetAccount, '', false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not SalesLine.IsLineAttachedToBillingLine() then
            exit;

        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        if SalesLine.CreateContractDeferrals() then begin
            GeneralPostingSetup.TestField("Cust. Sub. Contr. Def Account");
            SalesAccount := GeneralPostingSetup."Cust. Sub. Contr. Def Account";
        end else begin
            GeneralPostingSetup.TestField("Cust. Sub. Contract Account");
            SalesAccount := GeneralPostingSetup."Cust. Sub. Contract Account";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnPrepareLineOnBeforeSetLineDiscAccount, '', false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        if SalesLine.CreateContractDeferrals() then begin
            InvDiscAccount := GenPostingSetup."Cust. Sub. Contr. Def Account";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnPostSalesLineOnBeforeInsertInvoiceLine, '', false, false)]
    local procedure InsertCustomerDeferralsFromSalesInvoice(SalesHeader: Record "Sales Header"; xSalesLine: Record "Sales Line"; SalesInvHeader: Record "Sales Invoice Header")
    begin
        InsertContractDeferrals(SalesHeader, xSalesLine, SalesInvHeader."No.");
    end;

    local procedure InsertContractDeferrals(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        CustContractHeader: Record "Customer Subscription Contract";
        CustContractLine: Record "Cust. Sub. Contract Line";
        CustomerContractDeferral: Record "Cust. Sub. Contract Deferral";
        CurrExchRate: Record "Currency Exchange Rate";
        BillingLine: Record "Billing Line";
        Sign: Integer;
    begin
        if DocumentNo = '' then
            exit;
        if SalesLine.Quantity = 0 then
            exit;
        if SalesLine.Amount = 0 then
            exit;
        if SalesLine."Recurring Billing from" > SalesLine."Recurring Billing to" then
            exit;
        if not (SalesLine."Document Type" in [Enum::"Sales Document Type"::Invoice, Enum::"Sales Document Type"::"Credit Memo"]) then
            exit;
        if not SalesLine.CreateContractDeferrals() then
            exit;

        BillingLine.FilterBillingLineOnDocumentLine(BillingLine.GetBillingDocumentTypeFromSalesDocumentType(SalesLine."Document Type"), SalesLine."Document No.", SalesLine."Line No.");
        BillingLine.FindFirst();
        CustContractHeader.Get(BillingLine."Subscription Contract No.");
        GLSetup.Get();

        CustomerContractDeferral.Init();
        CustomerContractDeferral.InitFromSalesLine(SalesLine, Sign);
        CustomerContractDeferral."Document No." := DocumentNo;
        CustomerContractDeferral."Subscription Contract Type" := CustContractHeader."Contract Type";
        CustomerContractDeferral."User ID" := CopyStr(UserId(), 1, MaxStrLen(CustomerContractDeferral."User ID"));
        CustomerContractDeferral."Document Posting Date" := SalesHeader."Posting Date";
        CustContractLine.Get(CustContractHeader."No.", BillingLine."Subscription Contract Line No.");
        CustomerContractDeferral."Subscription Line Description" := CustContractLine."Subscription Line Description";
        CustomerContractDeferral."Subscription Description" := CustContractLine."Subscription Description";
        CustomerContractDeferral."Subscription Contract No." := CustContractLine."Subscription Contract No.";
        CustomerContractDeferral."Subscription Contract Line No." := CustContractLine."Line No.";

        if SalesHeader."Prices Including VAT" then
            if SalesLine."Line Discount Amount" <> 0 then
                SalesLine."Line Discount Amount" := Round(SalesLine."Line Discount Amount" / (1 + SalesLine."VAT %" / 100), GLSetup."Amount Rounding Precision");
        if SalesHeader."Currency Code" <> '' then begin
            SalesLine.Amount := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    SalesHeader."Posting Date",
                    SalesHeader."Currency Code",
                    SalesLine.Amount,
                    SalesHeader."Currency Factor"),
                GLSetup."Amount Rounding Precision");
            if SalesLine."Line Discount Amount" <> 0 then
                SalesLine."Line Discount Amount" := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        SalesHeader."Posting Date",
                        SalesHeader."Currency Code",
                        SalesLine."Line Discount Amount",
                        SalesHeader."Currency Factor"),
                    GLSetup."Amount Rounding Precision")
        end;
        SalesLine.Amount := Sign * SalesLine.Amount;
        CustomerContractDeferral."Deferral Base Amount" := SalesLine.Amount;
        SalesLine."Line Discount Amount" := Sign * SalesLine."Line Discount Amount";

        InsertContractDeferralPeriods(CustomerContractDeferral, SalesLine);
    end;

    local procedure GetNumberOfDeferralPeriods(FirstDayOfBillingPeriod: Date; LastDayOfBillingPeriod: Date) NumberOfPeriods: Integer
    var
        LoopDate: Date;
    begin
        LoopDate := FirstDayOfBillingPeriod;
        repeat
            NumberOfPeriods += 1;
            LoopDate := CalcDate('<1M>', LoopDate);
        until LoopDate > CalcDate('<CM>', LastDayOfBillingPeriod);
    end;

    local procedure InsertContractDeferralPeriods(var CustomerContractDeferral: Record "Cust. Sub. Contract Deferral"; SalesLine: Record "Sales Line")
    var
        NumberOfPeriods: Integer;
        i: Integer;
        NextPostingDate: Date;
        FirstDayOfBillingPeriod: Date;
        LineAmountPerDay: Decimal;
        LineDiscountAmountPerDay: Decimal;
        FullMonthLineAmount: Decimal;
        FullMonthLineDiscountAmount: Decimal;
        PartialFirstMonthAmount: Decimal;
        PartialFirstMonthDiscountAmount: Decimal;
        PartialLastMonthAmount: Decimal;
        PartialLastMonthDiscountAmount: Decimal;
        PeriodLineAmount: Decimal;
        PeriodLineDiscountAmount: Decimal;
        RunningLineAmount: Decimal;
        RunningLineDiscountAmount: Decimal;
        NumberOfDaysInSchedule: Integer;
        FirstMonthDays: Integer;
        LastMonthDays: Integer;
        FullMonthCount: Integer;
        FirstMonthIsPartial: Boolean;
        LastMonthIsPartial: Boolean;
    begin
        FirstDayOfBillingPeriod := SalesLine."Recurring Billing from";
        NumberOfPeriods := GetNumberOfDeferralPeriods(FirstDayOfBillingPeriod, SalesLine."Recurring Billing to");

        // Determine which months are partial (not covering the entire calendar month)
        FirstMonthIsPartial := FirstDayOfBillingPeriod <> CalcDate('<-CM>', FirstDayOfBillingPeriod);
        LastMonthIsPartial := SalesLine."Recurring Billing to" <> CalcDate('<CM>', SalesLine."Recurring Billing to");

        // Calculate daily rate for day-proportioning partial months
        NumberOfDaysInSchedule := SalesLine."Recurring Billing to" - FirstDayOfBillingPeriod + 1;
        LineAmountPerDay := SalesLine.Amount / NumberOfDaysInSchedule;
        LineDiscountAmountPerDay := SalesLine."Line Discount Amount" / NumberOfDaysInSchedule;
        FirstMonthDays := CalcDate('<CM>', FirstDayOfBillingPeriod) - FirstDayOfBillingPeriod + 1;
        LastMonthDays := Date2DMY(SalesLine."Recurring Billing to", 1);

        // Calculate partial month amounts and determine how many full months remain
        FullMonthCount := NumberOfPeriods;
        if FirstMonthIsPartial then begin
            // When first month is partial, day-proportion both first and last months
            CalcPartialMonthAmounts(FirstMonthDays, LineAmountPerDay, LineDiscountAmountPerDay, PartialFirstMonthAmount, PartialFirstMonthDiscountAmount);
            CalcPartialMonthAmounts(LastMonthDays, LineAmountPerDay, LineDiscountAmountPerDay, PartialLastMonthAmount, PartialLastMonthDiscountAmount);
            FullMonthCount -= 2;
        end else
            if LastMonthIsPartial and (NumberOfPeriods > 1) then begin
                // When only last month is partial, day-proportion just that month
                CalcPartialMonthAmounts(LastMonthDays, LineAmountPerDay, LineDiscountAmountPerDay, PartialLastMonthAmount, PartialLastMonthDiscountAmount);
                FullMonthCount -= 1;
            end;

        // Equal share for full months from the remaining amount after partial months
        if FullMonthCount > 0 then begin
            FullMonthLineAmount := Round((SalesLine.Amount - PartialFirstMonthAmount - PartialLastMonthAmount) / FullMonthCount, GLSetup."Amount Rounding Precision");
            FullMonthLineDiscountAmount := Round((SalesLine."Line Discount Amount" - PartialFirstMonthDiscountAmount - PartialLastMonthDiscountAmount) / FullMonthCount, GLSetup."Amount Rounding Precision");
        end;

        // Insert deferral records for each period
        NextPostingDate := FirstDayOfBillingPeriod;
        RunningLineAmount := 0;
        RunningLineDiscountAmount := 0;

        for i := 1 to NumberOfPeriods do begin
            CustomerContractDeferral."Posting Date" := NextPostingDate;
            NextPostingDate := CalcDate('<1M-CM>', NextPostingDate);

            // Determine period amount: last period absorbs rounding, first partial is day-proportioned, rest are equal
            if i = NumberOfPeriods then begin
                PeriodLineAmount := SalesLine.Amount - RunningLineAmount;
                PeriodLineDiscountAmount := SalesLine."Line Discount Amount" - RunningLineDiscountAmount;
            end else
                if (i = 1) and FirstMonthIsPartial then begin
                    PeriodLineAmount := PartialFirstMonthAmount;
                    PeriodLineDiscountAmount := PartialFirstMonthDiscountAmount;
                end else begin
                    PeriodLineAmount := FullMonthLineAmount;
                    PeriodLineDiscountAmount := FullMonthLineDiscountAmount;
                end;

            // Determine number of days: partial months use actual day count, full months use calendar month days
            if (i = NumberOfPeriods) and (NumberOfPeriods > 1) and (FirstMonthIsPartial or LastMonthIsPartial) then
                CustomerContractDeferral."Number of Days" := LastMonthDays
            else
                if (i = 1) and FirstMonthIsPartial then
                    CustomerContractDeferral."Number of Days" := FirstMonthDays
                else
                    CustomerContractDeferral."Number of Days" := Date2DMY(CalcDate('<CM>', CustomerContractDeferral."Posting Date"), 1);

            RunningLineAmount += PeriodLineAmount;
            RunningLineDiscountAmount += PeriodLineDiscountAmount;

            CustomerContractDeferral.Amount := PeriodLineAmount;
            CustomerContractDeferral."Discount Amount" := PeriodLineDiscountAmount;
            CustomerContractDeferral."Entry No." := 0;
#pragma warning disable AL0432
            if FirstMonthIsPartial then
                OnBeforeInsertCustomerContractDeferralWhenNotStartingOnFirstDayInMonth(CustomerContractDeferral, SalesLine, i, NumberOfPeriods)
            else
                OnBeforeInsertCustomerContractDeferralWhenStartingOnFirstDayInMonth(CustomerContractDeferral, SalesLine, i, NumberOfPeriods);
#pragma warning restore AL0432
            OnBeforeInsertCustomerContractDeferral(CustomerContractDeferral, SalesLine, i, NumberOfPeriods);
            CustomerContractDeferral.Insert(false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterSalesCrMemoLineInsert, '', false, false)]
    local procedure InsertCustomerDeferralsFromSalesCrMemo(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
        ProcessCreditMemoContractDeferrals(SalesHeader, SalesCrMemoLine, SalesLine);
    end;

    local procedure ProcessCreditMemoContractDeferrals(SalesHeader: Record "Sales Header"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesLine: Record "Sales Line")
    var
        InvoiceCustContractDeferral: Record "Cust. Sub. Contract Deferral";
        CreditMemoCustContractDeferral: Record "Cust. Sub. Contract Deferral";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ContractDeferralRelease: Report "Contract Deferrals Release";
        SalesDocuments: Codeunit "Sales Documents";
        AppliesToDocNo: Code[20];
    begin
        AppliesToDocNo := SalesDocuments.GetAppliesToDocNo(SalesHeader);
        if AppliesToDocNo = '' then begin
            InsertContractDeferrals(SalesHeader, SalesLine, SalesCrMemoLine."Document No.");
            exit;
        end;
        if SalesDocuments.IsInvoiceCredited(AppliesToDocNo) then
            exit;
        InvoiceCustContractDeferral.FilterOnDocumentTypeAndDocumentNo(Enum::"Rec. Billing Document Type"::Invoice, AppliesToDocNo);
        InvoiceCustContractDeferral.SetRange("Subscription Contract No.", SalesCrMemoLine."Subscription Contract No.");
        InvoiceCustContractDeferral.SetRange("Subscription Contract Line No.", SalesCrMemoLine."Subscription Contract Line No.");
        if InvoiceCustContractDeferral.FindSet() then begin
            ContractDeferralRelease.GetAndTestSourceCode();
            ContractDeferralRelease.GetGeneralLedgerSetupAndCheckJournalTemplateAndBatch();
            ContractDeferralRelease.SetAllowGUI(false);
            repeat
                CreditMemoCustContractDeferral := InvoiceCustContractDeferral;
                CreditMemoCustContractDeferral."Document Type" := Enum::"Rec. Billing Document Type"::"Credit Memo";
                CreditMemoCustContractDeferral."Document No." := SalesCrMemoLine."Document No.";
                CreditMemoCustContractDeferral."Document Line No." := SalesCrMemoLine."Line No.";
                CreditMemoCustContractDeferral."Posting Date" := InvoiceCustContractDeferral."Posting Date";
                CreditMemoCustContractDeferral."Document Posting Date" := SalesCrMemoLine."Posting Date";
                CreditMemoCustContractDeferral."Deferral Base Amount" := InvoiceCustContractDeferral."Deferral Base Amount" * -1;
                CreditMemoCustContractDeferral.Amount := InvoiceCustContractDeferral.Amount * -1;
                CreditMemoCustContractDeferral."Discount Amount" := InvoiceCustContractDeferral."Discount Amount" * -1;
                CreditMemoCustContractDeferral."Release Posting Date" := 0D;
                CreditMemoCustContractDeferral.Released := false;
                CreditMemoCustContractDeferral."G/L Entry No." := 0;
                CreditMemoCustContractDeferral."Entry No." := 0;
                CreditMemoCustContractDeferral.Insert(false);
                SalesInvoiceLine.Get(InvoiceCustContractDeferral."Document No.", InvoiceCustContractDeferral."Document Line No.");
                if not InvoiceCustContractDeferral.Released then begin
                    ContractDeferralRelease.SetRequestPageParameters(InvoiceCustContractDeferral."Posting Date", SalesCrMemoLine."Posting Date");
                    ContractDeferralRelease.ReleaseCustomerContractDeferralAndInsertTempGenJournalLine(InvoiceCustContractDeferral);
                    ContractDeferralRelease.PostTempGenJnlLineBufferForCustomerDeferrals();
                end;
                ContractDeferralRelease.SetRequestPageParameters(CreditMemoCustContractDeferral."Posting Date", SalesCrMemoLine."Posting Date");
                ContractDeferralRelease.ReleaseCustomerContractDeferralAndInsertTempGenJournalLine(CreditMemoCustContractDeferral);
                ContractDeferralRelease.PostTempGenJnlLineBufferForCustomerDeferrals();
            until InvoiceCustContractDeferral.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnAfterNavigateFindRecords, '', false, false)]
    local procedure OnAfterFindEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text)
    var
        CustomerContractDeferral: Record "Cust. Sub. Contract Deferral";
    begin
        CustomerContractDeferral.SetFilter("Document No.", DocNoFilter);
        DocumentEntry.InsertIntoDocEntry(Database::"Cust. Sub. Contract Deferral", CustomerContractDeferral."Document Type", CustomerContractDeferral.TableCaption, CustomerContractDeferral.Count);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnBeforeShowRecords, '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text)
    var
        CustomerContractDeferral: Record "Cust. Sub. Contract Deferral";
    begin
        if TempDocumentEntry."Table ID" <> Database::"Cust. Sub. Contract Deferral" then
            exit;
        CustomerContractDeferral.SetFilter("Document No.", DocNoFilter);
        Page.Run(Page::"Customer Contract Deferrals", CustomerContractDeferral);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterGLFinishPosting, '', false, false)]
    local procedure GetEntryNo(GLEntry: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        CustomerContractDeferrals: Record "Cust. Sub. Contract Deferral";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if SourceCodeSetup."Sub. Contr. Deferrals Release" <> GLEntry."Source Code" then
            exit;
        //Update Contract Deferrals while releasing
        if DeferralEntryNo <> 0 then begin
            CustomerContractDeferrals.Get(DeferralEntryNo);
            CustomerContractDeferrals."G/L Entry No." := GLEntry."Entry No.";
            CustomerContractDeferrals.Modify(false);
        end
        else begin
            //Update related invoice deferrals with GL Entry No.
            CustomerContractDeferrals.FilterOnDocumentTypeAndDocumentNo(Enum::"Rec. Billing Document Type"::Invoice, GenJnlLine."Applies-to Doc. No.");
            CustomerContractDeferrals.SetRange(Released, true);
            CustomerContractDeferrals.SetRange("G/L Entry No.", 0);
            CustomerContractDeferrals.ModifyAll("G/L Entry No.", GLEntry."Entry No.", false);
            //Update Credit memo deferrals with GL Entry No.
            CustomerContractDeferrals.FilterOnDocumentTypeAndDocumentNo(Enum::"Rec. Billing Document Type"::"Credit Memo", GLEntry."Document No.");
            CustomerContractDeferrals.ModifyAll("G/L Entry No.", GLEntry."Entry No.", false);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforePostGenJnlLine, '', false, false)]
    local procedure SetContractNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        CustomerContractDeferrals: Record "Cust. Sub. Contract Deferral";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if DeferralEntryNo = 0 then
            exit;
        SourceCodeSetup.Get();
        if SourceCodeSetup."Sub. Contr. Deferrals Release" <> GenJournalLine."Source Code" then
            exit;
        CustomerContractDeferrals.Get(DeferralEntryNo);
        GenJournalLine."Subscription Contract No." := CustomerContractDeferrals."Subscription Contract No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeInsertGlobalGLEntry, '', false, false)]
    local procedure TransferContractNoToGLEntry(var GlobalGLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Subscription Contract No." = '' then
            exit;
        GlobalGLEntry."Subscription Contract No." := GenJournalLine."Subscription Contract No.";
    end;

    internal procedure SetDeferralNo(NewDeferralNo: Integer)
    begin
        DeferralEntryNo := NewDeferralNo;
    end;

    local procedure CalcPartialMonthAmounts(MonthDays: Integer; LineAmountPerDay: Decimal; LineDiscountAmountPerDay: Decimal; var PartialMonthAmount: Decimal; var PartialMonthDiscountAmount: Decimal)
    begin
        PartialMonthAmount := CalcDaysAmount(MonthDays, LineAmountPerDay);
        PartialMonthDiscountAmount := CalcDaysAmount(MonthDays, LineDiscountAmountPerDay);
    end;

    local procedure CalcDaysAmount(MonthDays: Integer; AmountPerDay: Decimal): Decimal
    begin
        exit(Round(MonthDays * AmountPerDay, GLSetup."Amount Rounding Precision"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCustomerContractDeferral(var CustSubContractDeferral: Record "Cust. Sub. Contract Deferral"; SalesLine: Record "Sales Line"; PeriodNo: Integer; NumberOfPeriods: Integer)
    begin
    end;

    [Obsolete('Replaced by OnBeforeInsertCustomerContractDeferral.', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCustomerContractDeferralWhenStartingOnFirstDayInMonth(var CustSubContractDeferral: Record "Cust. Sub. Contract Deferral"; SalesLine: Record "Sales Line"; PeriodNo: Integer; NumberOfPeriods: Integer)
    begin
    end;

    [Obsolete('Replaced by OnBeforeInsertCustomerContractDeferral.', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCustomerContractDeferralWhenNotStartingOnFirstDayInMonth(var CustSubContractDeferral: Record "Cust. Sub. Contract Deferral"; SalesLine: Record "Sales Line"; PeriodNo: Integer; NumberOfPeriods: Integer)
    begin
    end;
}
