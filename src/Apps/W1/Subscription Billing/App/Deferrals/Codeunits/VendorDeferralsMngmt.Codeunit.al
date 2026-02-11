namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;

codeunit 8068 "Vendor Deferrals Mngmt."
{
    SingleInstance = true;
    Access = Internal;
    Permissions =
        tabledata "Purch. Inv. Line" = r;

    var
        TempVendorContractDeferral: Record "Vend. Sub. Contract Deferral" temporary;
        GLSetup: Record "General Ledger Setup";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DeferralEntryNo: Integer;
        VendorContractDeferralLinePosting: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforePostPurchaseDoc, '', false, false)]
    local procedure ClearGlobals()
    begin
        TempVendorContractDeferral.Reset();
        TempVendorContractDeferral.DeleteAll(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnPrepareLineOnBeforeSetAccount, '', false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(PurchLine: Record "Purchase Line"; var SalesAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not PurchLine.IsLineAttachedToBillingLine() then
            exit;

        GeneralPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        if PurchLine.CreateContractDeferrals() then begin
            GeneralPostingSetup.TestField("Vend. Sub. Contr. Def. Account");
            SalesAccount := GeneralPostingSetup."Vend. Sub. Contr. Def. Account";
        end else begin
            GeneralPostingSetup.TestField("Vend. Sub. Contract Account");
            SalesAccount := GeneralPostingSetup."Vend. Sub. Contract Account";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnAfterInitTotalAmounts, '', false, false)]
    local procedure SetVendorContractDeferralLinePosting(PurchLine: Record "Purchase Line")
    begin
        VendorContractDeferralLinePosting := false;
        Clear(TempPurchaseLine);
        if PurchLine.CreateContractDeferrals() then begin
            VendorContractDeferralLinePosting := true;
            TempPurchaseLine := PurchLine;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Posting Setup", OnBeforeGetPurchLineDiscAccount, '', false, false)]
    local procedure SetLineDiscAccountForVendorContractDeferrals(var AccountNo: Code[20]; var IsHandled: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if VendorContractDeferralLinePosting then begin
            GeneralPostingSetup.Get(TempPurchaseLine."Gen. Bus. Posting Group", TempPurchaseLine."Gen. Prod. Posting Group");
            AccountNo := GeneralPostingSetup."Vend. Sub. Contr. Def. Account";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforePurchInvLineInsert, '', false, false)]
    local procedure InsertVendorDeferralsFromPurchaseInvoiceOnBeforePurchInvLineInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseLine: Record "Purchase Line")
    begin
        InsertContractDeferrals(PurchaseLine.GetPurchHeader(), PurchaseLine, PurchInvHeader."No.");
    end;

    local procedure InsertContractDeferrals(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    var
        VendContractHeader: Record "Vendor Subscription Contract";
        VendContractLine: Record "Vend. Sub. Contract Line";
        VendorContractDeferral: Record "Vend. Sub. Contract Deferral";
        BillingLine: Record "Billing Line";
        Sign: Integer;
    begin
        if DocumentNo = '' then
            exit;
        if PurchaseLine.Quantity = 0 then
            exit;
        if PurchaseLine.Amount = 0 then
            exit;
        if PurchaseLine."Recurring Billing from" > PurchaseLine."Recurring Billing to" then
            exit;
        if not (PurchaseLine."Document Type" in [Enum::"Purchase Document Type"::Invoice, Enum::"Purchase Document Type"::"Credit Memo"]) then
            exit;
        if not PurchaseLine.CreateContractDeferrals() then
            exit;

        BillingLine.FilterBillingLineOnDocumentLine(BillingLine.GetBillingDocumentTypeFromPurchaseDocumentType(PurchaseLine."Document Type"), PurchaseLine."Document No.", PurchaseLine."Line No.");
        BillingLine.FindFirst();
        VendContractHeader.Get(BillingLine."Subscription Contract No.");
        GLSetup.Get();

        VendorContractDeferral.Init();
        VendorContractDeferral.InitFromPurchaseLine(PurchaseLine, Sign);
        VendorContractDeferral."Document No." := DocumentNo;
        VendorContractDeferral."Subscription Contract Type" := VendContractHeader."Contract Type";
        VendorContractDeferral."User ID" := CopyStr(UserId(), 1, MaxStrLen(VendorContractDeferral."User ID"));
        VendorContractDeferral."Document Posting Date" := PurchaseHeader."Posting Date";
        VendContractLine.Get(VendContractHeader."No.", BillingLine."Subscription Contract Line No.");
        VendorContractDeferral."Subscription Line Description" := VendContractLine."Subscription Line Description";
        VendorContractDeferral."Subscription Description" := VendContractLine."Subscription Description";
        VendorContractDeferral."Subscription Contract No." := VendContractLine."Subscription Contract No.";
        VendorContractDeferral."Subscription Contract Line No." := VendContractLine."Line No.";

        if PurchaseHeader."Prices Including VAT" then
            if PurchaseLine."Line Discount Amount" <> 0 then
                PurchaseLine."Line Discount Amount" := Round(PurchaseLine."Line Discount Amount" / (1 + PurchaseLine."VAT %" / 100), GLSetup."Amount Rounding Precision");

        //Amount in LCY is calculated inside PostPurchLine function in CU Purch.-Post; PurchLine.RoundAmount
        PurchaseLine.Amount := Sign * PurchaseLine.Amount;
        VendorContractDeferral."Deferral Base Amount" := PurchaseLine.Amount;
        PurchaseLine."Line Discount Amount" := Sign * PurchaseLine."Line Discount Amount";

        InsertContractDeferralPeriods(VendorContractDeferral, PurchaseLine);
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

    local procedure InsertContractDeferralPeriods(var VendorContractDeferral: Record "Vend. Sub. Contract Deferral"; PurchaseLine: Record "Purchase Line")
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
        FirstDayOfBillingPeriod := PurchaseLine."Recurring Billing from";
        NumberOfPeriods := GetNumberOfDeferralPeriods(FirstDayOfBillingPeriod, PurchaseLine."Recurring Billing to");

        // Determine which months are partial (not covering the entire calendar month)
        FirstMonthIsPartial := FirstDayOfBillingPeriod <> CalcDate('<-CM>', FirstDayOfBillingPeriod);
        LastMonthIsPartial := PurchaseLine."Recurring Billing to" <> CalcDate('<CM>', PurchaseLine."Recurring Billing to");

        // Calculate daily rate for day-proportioning partial months
        NumberOfDaysInSchedule := PurchaseLine."Recurring Billing to" - FirstDayOfBillingPeriod + 1;
        LineAmountPerDay := PurchaseLine.Amount / NumberOfDaysInSchedule;
        LineDiscountAmountPerDay := PurchaseLine."Line Discount Amount" / NumberOfDaysInSchedule;
        FirstMonthDays := CalcDate('<CM>', FirstDayOfBillingPeriod) - FirstDayOfBillingPeriod + 1;
        LastMonthDays := Date2DMY(PurchaseLine."Recurring Billing to", 1);

        // Calculate partial month amounts and determine how many full months remain
        FullMonthCount := NumberOfPeriods;
        if FirstMonthIsPartial then begin
            // When first month is partial, day-proportion both first and last months
            PartialFirstMonthAmount := Round(FirstMonthDays * LineAmountPerDay, GLSetup."Amount Rounding Precision");
            PartialFirstMonthDiscountAmount := Round(FirstMonthDays * LineDiscountAmountPerDay, GLSetup."Amount Rounding Precision");
            PartialLastMonthAmount := Round(LastMonthDays * LineAmountPerDay, GLSetup."Amount Rounding Precision");
            PartialLastMonthDiscountAmount := Round(LastMonthDays * LineDiscountAmountPerDay, GLSetup."Amount Rounding Precision");
            FullMonthCount -= 2;
        end else
            if LastMonthIsPartial and (NumberOfPeriods > 1) then begin
                // When only last month is partial, day-proportion just that month
                PartialLastMonthAmount := Round(LastMonthDays * LineAmountPerDay, GLSetup."Amount Rounding Precision");
                PartialLastMonthDiscountAmount := Round(LastMonthDays * LineDiscountAmountPerDay, GLSetup."Amount Rounding Precision");
                FullMonthCount -= 1;
            end;

        // Equal share for full months from the remaining amount after partial months
        if FullMonthCount > 0 then begin
            FullMonthLineAmount := Round((PurchaseLine.Amount - PartialFirstMonthAmount - PartialLastMonthAmount) / FullMonthCount, GLSetup."Amount Rounding Precision");
            FullMonthLineDiscountAmount := Round((PurchaseLine."Line Discount Amount" - PartialFirstMonthDiscountAmount - PartialLastMonthDiscountAmount) / FullMonthCount, GLSetup."Amount Rounding Precision");
        end;

        // Insert deferral records for each period
        NextPostingDate := FirstDayOfBillingPeriod;
        RunningLineAmount := 0;
        RunningLineDiscountAmount := 0;

        for i := 1 to NumberOfPeriods do begin
            VendorContractDeferral."Posting Date" := NextPostingDate;
            NextPostingDate := CalcDate('<1M-CM>', NextPostingDate);

            // Determine period amount: last period absorbs rounding, first partial is day-proportioned, rest are equal
            if i = NumberOfPeriods then begin
                PeriodLineAmount := PurchaseLine.Amount - RunningLineAmount;
                PeriodLineDiscountAmount := PurchaseLine."Line Discount Amount" - RunningLineDiscountAmount;
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
                VendorContractDeferral."Number of Days" := LastMonthDays
            else
                if (i = 1) and FirstMonthIsPartial then
                    VendorContractDeferral."Number of Days" := FirstMonthDays
                else
                    VendorContractDeferral."Number of Days" := Date2DMY(CalcDate('<CM>', VendorContractDeferral."Posting Date"), 1);

            RunningLineAmount += PeriodLineAmount;
            RunningLineDiscountAmount += PeriodLineDiscountAmount;

            VendorContractDeferral.Amount := PeriodLineAmount;
            VendorContractDeferral."Discount Amount" := PeriodLineDiscountAmount;
            VendorContractDeferral."Entry No." := 0;
            OnBeforeInsertVendorContractDeferral(VendorContractDeferral, PurchaseLine, i, NumberOfPeriods);
            VendorContractDeferral.Insert(false);
            TempVendorContractDeferral := VendorContractDeferral;
            TempVendorContractDeferral.Insert(false); //Used for Preview Posting
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnAfterPurchCrMemoLineInsert, '', false, false)]
    local procedure InsertVendorDeferralsFromPurchaseCrMemo(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
        ProcessCreditMemoContractDeferrals(PurchaseHeader, PurchCrMemoLine, PurchLine);
    end;

    local procedure ProcessCreditMemoContractDeferrals(PurchaseHeader: Record "Purchase Header"; var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var PurchaseLine: Record "Purchase Line")
    var
        InvoiceVendorContractDeferral: Record "Vend. Sub. Contract Deferral";
        CreditMemoVendorContractDeferral: Record "Vend. Sub. Contract Deferral";
        PurchInvLine: Record "Purch. Inv. Line";
        ContractDeferralRelease: Report "Contract Deferrals Release";
        PurchaseDocuments: Codeunit "Purchase Documents";
        AppliesToDocNo: Code[20];
    begin
        AppliesToDocNo := GetAppliesToDocNo(PurchaseHeader);
        if AppliesToDocNo = '' then begin
            InsertContractDeferrals(PurchaseHeader, PurchaseLine, PurchCrMemoLine."Document No.");
            exit;
        end;
        if PurchaseDocuments.HasInvoiceBeenCredited(AppliesToDocNo) then
            exit;
        InvoiceVendorContractDeferral.FilterOnDocumentTypeAndDocumentNo(Enum::"Rec. Billing Document Type"::Invoice, AppliesToDocNo);
        InvoiceVendorContractDeferral.SetRange("Subscription Contract No.", PurchCrMemoLine."Subscription Contract No.");
        InvoiceVendorContractDeferral.SetRange("Subscription Contract Line No.", PurchCrMemoLine."Subscription Contract Line No.");
        if InvoiceVendorContractDeferral.FindSet() then begin
            ContractDeferralRelease.GetAndTestSourceCode();
            ContractDeferralRelease.GetGeneralLedgerSetupAndCheckJournalTemplateAndBatch();
            ContractDeferralRelease.SetAllowGUI(false);
            repeat
                CreditMemoVendorContractDeferral := InvoiceVendorContractDeferral;
                CreditMemoVendorContractDeferral."Document Type" := Enum::"Rec. Billing Document Type"::"Credit Memo";
                CreditMemoVendorContractDeferral."Document No." := PurchCrMemoLine."Document No.";
                CreditMemoVendorContractDeferral."Document Line No." := PurchCrMemoLine."Line No.";
                CreditMemoVendorContractDeferral."Posting Date" := InvoiceVendorContractDeferral."Posting Date";
                CreditMemoVendorContractDeferral."Document Posting Date" := PurchCrMemoLine."Posting Date";
                CreditMemoVendorContractDeferral."Deferral Base Amount" := InvoiceVendorContractDeferral."Deferral Base Amount" * -1;
                CreditMemoVendorContractDeferral.Amount := InvoiceVendorContractDeferral.Amount * -1;
                CreditMemoVendorContractDeferral."Discount Amount" := InvoiceVendorContractDeferral."Discount Amount" * -1;
                CreditMemoVendorContractDeferral."Release Posting Date" := 0D;
                CreditMemoVendorContractDeferral.Released := false;
                CreditMemoVendorContractDeferral."G/L Entry No." := 0;
                CreditMemoVendorContractDeferral."Entry No." := 0;
                CreditMemoVendorContractDeferral.Insert(false);

                PurchInvLine.Get(InvoiceVendorContractDeferral."Document No.", InvoiceVendorContractDeferral."Document Line No.");
                if not InvoiceVendorContractDeferral.Released then begin
                    ContractDeferralRelease.SetRequestPageParameters(InvoiceVendorContractDeferral."Posting Date", PurchCrMemoLine."Posting Date");
                    ContractDeferralRelease.ReleaseVendorContractDeferralsAndInsertTempGenJournalLines(InvoiceVendorContractDeferral);
                    ContractDeferralRelease.PostTempGenJnlLineBufferForVendorDeferrals();
                end;
                ContractDeferralRelease.SetRequestPageParameters(CreditMemoVendorContractDeferral."Posting Date", PurchCrMemoLine."Posting Date");
                ContractDeferralRelease.ReleaseVendorContractDeferralsAndInsertTempGenJournalLines(CreditMemoVendorContractDeferral);
                ContractDeferralRelease.PostTempGenJnlLineBufferForVendorDeferrals();

                TempVendorContractDeferral := CreditMemoVendorContractDeferral;
                TempVendorContractDeferral.Insert(false); //Used for Preview Posting
            until InvoiceVendorContractDeferral.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterFillDocumentEntry, '', false, false)]
    local procedure OnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
    begin
        PostingPreviewEventHandler.InsertDocumentEntry(TempVendorContractDeferral, DocumentEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterShowEntries, '', false, false)]
    local procedure OnAfterShowEntries(TableNo: Integer)
    begin
        if TableNo = Database::"Vend. Sub. Contract Deferral" then
            Page.Run(Page::"Vendor Contract Deferrals", TempVendorContractDeferral);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnAfterNavigateFindRecords, '', false, false)]
    local procedure OnAfterFindEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text)
    var
        VendorContractDeferral: Record "Vend. Sub. Contract Deferral";
    begin
        VendorContractDeferral.SetFilter("Document No.", DocNoFilter);
        DocumentEntry.InsertIntoDocEntry(Database::"Vend. Sub. Contract Deferral", VendorContractDeferral."Document Type", VendorContractDeferral.TableCaption, VendorContractDeferral.Count);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnBeforeShowRecords, '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text)
    var
        VendorContractDeferral: Record "Vend. Sub. Contract Deferral";
    begin
        if TempDocumentEntry."Table ID" <> Database::"Vend. Sub. Contract Deferral" then
            exit;

        VendorContractDeferral.SetFilter("Document No.", DocNoFilter);
        Page.Run(Page::"Vendor Contract Deferrals", VendorContractDeferral);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforePostGenJnlLine, '', false, false)]
    local procedure SetContractNo(var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean)
    var
        VendorContractDeferrals: Record "Vend. Sub. Contract Deferral";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if DeferralEntryNo = 0 then
            exit;
        SourceCodeSetup.Get();
        if SourceCodeSetup."Sub. Contr. Deferrals Release" <> GenJournalLine."Source Code" then
            exit;
        VendorContractDeferrals.Get(DeferralEntryNo);
        GenJournalLine."Subscription Contract No." := VendorContractDeferrals."Subscription Contract No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterGLFinishPosting, '', false, false)]
    local procedure GetEntryNo(GLEntry: Record "G/L Entry"; var GenJnlLine: Record "Gen. Journal Line")
    var
        VendorContractDeferrals: Record "Vend. Sub. Contract Deferral";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if SourceCodeSetup."Sub. Contr. Deferrals Release" <> GLEntry."Source Code" then
            exit;   //Update Contract Deferrals while releasing
        if DeferralEntryNo <> 0 then begin
            VendorContractDeferrals.Get(DeferralEntryNo);
            VendorContractDeferrals."G/L Entry No." := GLEntry."Entry No.";
            VendorContractDeferrals.Modify(false);
        end else begin
            //Update related invoice deferrals with GL Entry No.
            VendorContractDeferrals.FilterOnDocumentTypeAndDocumentNo(Enum::"Rec. Billing Document Type"::Invoice, GenJnlLine."Applies-to Doc. No.");
            VendorContractDeferrals.SetRange(Released, true);
            VendorContractDeferrals.SetRange("G/L Entry No.", 0);
            VendorContractDeferrals.ModifyAll("G/L Entry No.", GLEntry."Entry No.", false);
            //Update Credit memo deferrals with GL Entry No.
            VendorContractDeferrals.FilterOnDocumentTypeAndDocumentNo(Enum::"Rec. Billing Document Type"::"Credit Memo", GLEntry."Document No.");
            VendorContractDeferrals.ModifyAll("G/L Entry No.", GLEntry."Entry No.", false);
        end;
    end;

    internal procedure SetDeferralNo(NewDeferralNo: Integer)
    begin
        DeferralEntryNo := NewDeferralNo;
    end;

    local procedure GetAppliesToDocNo(PurchHeader: Record "Purchase Header"): Code[20]
    var
        BillingLine: Record "Billing Line";
    begin
        if PurchHeader."Applies-to Doc. No." <> '' then
            exit(PurchHeader."Applies-to Doc. No.");
        exit(BillingLine.GetCorrectionDocumentNo("Service Partner"::Vendor, PurchHeader."No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVendorContractDeferral(var VendSubContractDeferral: Record "Vend. Sub. Contract Deferral"; PurchaseLine: Record "Purchase Line"; PeriodNo: Integer; NumberOfPeriods: Integer)
    begin
    end;
}
