// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Payables;
using System.Environment.Configuration;

codeunit 8846 "Purchase Installment Mgt."
{
    Permissions = tabledata "Purchase Installment Plan" = RIMD,
                  tabledata "Purchase Installment Plan Line" = RIMD;

    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
        InvoiceOnlyErr: Label 'Global installments currently support standalone purchase invoices only.';
        TemporaryHeaderErr: Label 'An installment schedule requires a saved purchase invoice.';
        TemporaryResultErr: Label 'Installment preview requires a temporary plan line record.';
        EmptyPlanErr: Label 'The installment rule snapshot is empty.';
        HeaderConditionsErr: Label 'The due date is the first installment summary, and header payment discount conditions must be zero. Use the Installment Schedule to view the conditions.';
        ViewScheduleLbl: Label 'View Installment Schedule';
        PlanLinkErr: Label 'The installment plan must belong to this invoice and match its payment terms. Change the payment terms to replace or remove the plan.';
        DiscountPolicyErr: Label 'Installment preview with payment discounts does not yet support Pmt. Disc. Excl. VAT or Adjust for Payment Disc. in General Ledger Setup.';

    procedure ShowSchedule(var PurchaseHeader: Record "Purchase Header")
    var
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
        Schedule: Page "Purchase Installment Schedule";
    begin
        CalculatePreview(PurchaseHeader, TempPlanLine);
        Schedule.SetSchedule(PurchaseHeader, TempPlanLine);
        Schedule.Run();
    end;

    procedure ShowScheduleFromError(ErrorInfo: ErrorInfo)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderRef: RecordRef;
    begin
        PurchaseHeaderRef := ErrorInfo.RecordId.GetRecord();
        PurchaseHeaderRef.SetTable(PurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ShowSchedule(PurchaseHeader);
    end;

    procedure CalculatePreview(var PurchaseHeader: Record "Purchase Header"; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    var
        Plan: Record "Purchase Installment Plan";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        TempPurchaseLine: Record "Purchase Line" temporary;
        TotalPurchaseLine: Record "Purchase Line";
        TotalPurchaseLineLCY: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        VATAmount: Decimal;
        VATAmountText: Text[30];

    begin
        FeatureKeyManagement.CheckPaymentInstallmentsEnabled();
        if not TempPlanLine.IsTemporary() then
            Error(TemporaryResultErr);
        if PurchaseHeader.IsTemporary() or not IsSaved(PurchaseHeader) then
            Error(TemporaryHeaderErr);
        GetOwnedDraft(PurchaseHeader, Plan);
        CheckHeaderConditions(PurchaseHeader);
        LoadRules(Plan.ID, TempPlanLine);
        GLSetup.Get();
        TempPlanLine.SetFilter("Discount %", '<>0');
        if not TempPlanLine.IsEmpty() then
            if GLSetup."Pmt. Disc. Excl. VAT" or GLSetup."Adjust for Payment Disc." then
                Error(DiscountPolicyErr);
        TempPlanLine.Reset();
        Currency.Initialize(PurchaseHeader."Currency Code", true);
        GLSetup.TestField("Amount Rounding Precision");

        // Use the statistics totals path, including temporary invoice rounding.
        // Do not call PrepareOpeningDocumentStatistics, which commits.
        PurchaseHeader.CalcInvDiscForHeader();
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        Clear(PurchPost);
        PurchPost.SumPurchLinesTemp(
            PurchaseHeader, TempPurchaseLine, 0, TotalPurchaseLine, TotalPurchaseLineLCY,
            VATAmount, VATAmountText);
        Calculate(
            TempPlanLine, PurchaseHeader."Document Date", PurchaseHeader."Posting Date",
            TotalPurchaseLine."Amount Including VAT", TotalPurchaseLineLCY."Amount Including VAT",
            Currency."Amount Rounding Precision", GLSetup."Amount Rounding Precision", GLSetup."Payment Discount Grace Period");
    end;

    local procedure UpdatePaymentTerms(var PurchaseHeader: Record "Purchase Header"; UpdateDocumentDate: Boolean): Boolean
    var
        Plan: Record "Purchase Installment Plan";
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
    begin
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then
            exit(false);
        if PurchaseHeader.IsTemporary() then
            exit(false);
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then begin
            if not IsNullGuid(PurchaseHeader."Installment Plan ID") or
               ((PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Credit Memo") and
                not UpdateDocumentDate and HasRules(PurchaseHeader."Payment Terms Code"))
            then
                Error(InvoiceOnlyErr);
            exit(false);
        end;

        if not IsNullGuid(PurchaseHeader."Installment Plan ID") then begin
            Plan.Get(PurchaseHeader."Installment Plan ID");
            if Plan."Source SystemId" = PurchaseHeader.SystemId then
                Plan.TestField(Status, Plan.Status::Draft);
            if Plan."Payment Terms Code" = PurchaseHeader."Payment Terms Code" then begin
                LoadRules(Plan.ID, TempPlanLine);
                if IsSaved(PurchaseHeader) and (Plan."Source SystemId" <> PurchaseHeader.SystemId) then
                    StoreSnapshot(PurchaseHeader, TempPlanLine);
                SetHeaderSummary(PurchaseHeader, TempPlanLine);
                exit(true);
            end;
        end else
            if UpdateDocumentDate then
                exit(false);

        if not HasRules(PurchaseHeader."Payment Terms Code") then begin
            DeleteOwnedDraft(PurchaseHeader);
            Clear(PurchaseHeader."Installment Plan ID");
            exit(false);
        end;
        CopyPaymentTerms(PurchaseHeader."Payment Terms Code", CreateGuid(), TempPlanLine);
        if PurchaseHeader."Document Date" <> 0D then
            CalculateDates(TempPlanLine, PurchaseHeader."Document Date");
        if IsSaved(PurchaseHeader) then
            StoreSnapshot(PurchaseHeader, TempPlanLine);
        SetHeaderSummary(PurchaseHeader, TempPlanLine);
        exit(true);
    end;

    local procedure StoreSnapshot(var PurchaseHeader: Record "Purchase Header"; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    var
        SavedHeader: Record "Purchase Header";
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
    begin
        DeleteOwnedDraft(PurchaseHeader);
        SavedHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        DeleteOwnedDraft(SavedHeader);
        Plan.Init();
        Plan.ID := CreateGuid();
        Plan."Payment Terms Code" := PurchaseHeader."Payment Terms Code";
        SetPlanSource(Plan, PurchaseHeader);
        Plan.Insert(true);
        TempPlanLine.Reset();
        if TempPlanLine.FindSet() then
            repeat
                PlanLine.Init();
                PlanLine."Plan ID" := Plan.ID;
                PlanLine.CopyRulesFromPlanLine(TempPlanLine);
                PlanLine.Insert(true);
            until TempPlanLine.Next() = 0;
        PurchaseHeader."Installment Plan ID" := Plan.ID;
    end;

    local procedure LoadRules(PlanID: Guid; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    var
        PlanLine: Record "Purchase Installment Plan Line";
    begin
        TempPlanLine.Reset();
        TempPlanLine.DeleteAll();
        PlanLine.SetRange("Plan ID", PlanID);
        if not PlanLine.FindSet() then
            Error(EmptyPlanErr);
        repeat
            TempPlanLine.Init();
            TempPlanLine."Plan ID" := PlanID;
            TempPlanLine.CopyRulesFromPlanLine(PlanLine);
            TempPlanLine.Insert();
        until PlanLine.Next() = 0;
        ValidateRules(TempPlanLine);
    end;

    local procedure SetHeaderSummary(var PurchaseHeader: Record "Purchase Header"; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    begin
        PurchaseHeader."Due Date" := 0D;
        if PurchaseHeader."Document Date" <> 0D then begin
            CalculateDates(TempPlanLine, PurchaseHeader."Document Date");
            TempPlanLine.FindFirst();
            PurchaseHeader."Due Date" := TempPlanLine."Due Date";
        end;
        PurchaseHeader."Pmt. Discount Date" := 0D;
        if (PurchaseHeader."Payment Discount %" <> 0) or (PurchaseHeader."VAT Base Discount %" <> 0) then
            if IsSaved(PurchaseHeader) then
                PurchaseHeader.Validate("Payment Discount %", 0)
            else begin
                PurchaseHeader."Payment Discount %" := 0;
                PurchaseHeader."VAT Base Discount %" := 0;
            end;
    end;

    local procedure CheckHeaderConditions(PurchaseHeader: Record "Purchase Header")
    var
        Plan: Record "Purchase Installment Plan";
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
        DueDate: Date;
    begin
        if PurchaseHeader.IsTemporary() or IsNullGuid(PurchaseHeader."Installment Plan ID") then
            exit;
        Plan.Get(PurchaseHeader."Installment Plan ID");
        if Plan.Status = Plan.Status::Posted then
            CheckPostedSource(PurchaseHeader, Plan)
        else
            GetOwnedDraft(PurchaseHeader, Plan);
        LoadRules(Plan.ID, TempPlanLine);
        if PurchaseHeader."Document Date" <> 0D then begin
            CalculateDates(TempPlanLine, PurchaseHeader."Document Date");
            TempPlanLine.FindFirst();
            DueDate := TempPlanLine."Due Date";
        end;
        if (PurchaseHeader."Due Date" <> DueDate) or (PurchaseHeader."Payment Discount %" <> 0) or
           (PurchaseHeader."Pmt. Discount Date" <> 0D) or (PurchaseHeader."VAT Base Discount %" <> 0)
        then
            RaiseHeaderConditionsError(PurchaseHeader);
    end;

    local procedure RaiseHeaderConditionsError(PurchaseHeader: Record "Purchase Header")
    var
        HeaderConditionsErrorInfo: ErrorInfo;
    begin
        HeaderConditionsErrorInfo := ErrorInfo.Create(HeaderConditionsErr);
        HeaderConditionsErrorInfo.RecordId(PurchaseHeader.RecordId());
        HeaderConditionsErrorInfo.AddAction(ViewScheduleLbl, Codeunit::"Purchase Installment Mgt.", 'ShowScheduleFromError');
        Error(HeaderConditionsErrorInfo);
    end;

    local procedure GetOwnedDraft(PurchaseHeader: Record "Purchase Header"; var Plan: Record "Purchase Installment Plan")
    begin
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.TestField("Installment Plan ID");
        Plan.Get(PurchaseHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        if (Plan."Source SystemId" <> PurchaseHeader.SystemId) or
           (Plan."Source Record ID" <> PurchaseHeader.RecordId()) or
           (Plan."Payment Terms Code" <> PurchaseHeader."Payment Terms Code")
        then
            Error(PlanLinkErr);
    end;

    local procedure CheckPostedSource(PurchaseHeader: Record "Purchase Header"; Plan: Record "Purchase Installment Plan")
    var
        PostedInvoice: Record "Purch. Inv. Header";
    begin
        if (Plan."Source SystemId" <> PurchaseHeader.SystemId) or
           (Plan."Source Record ID" <> PurchaseHeader.RecordId()) or
           (Plan."Payment Terms Code" <> PurchaseHeader."Payment Terms Code") or
           (Plan."Document Date" <> PurchaseHeader."Document Date") or
           (Plan."Currency Code" <> PurchaseHeader."Currency Code") or
           (Plan."Posting Date" <> PurchaseHeader."Posting Date")
        then
            Error(PlanLinkErr);
        PostedInvoice.Get(Plan."Posted Invoice No.");
        PostedInvoice.TestField(SystemId, Plan."Posted Invoice SystemId");
        PostedInvoice.TestField("Installment Plan ID", Plan.ID);
    end;

    local procedure DeleteOwnedDraft(PurchaseHeader: Record "Purchase Header")
    var
        Plan: Record "Purchase Installment Plan";
    begin
        if PurchaseHeader.IsTemporary() or IsNullGuid(PurchaseHeader."Installment Plan ID") or IsNullGuid(PurchaseHeader.SystemId) then
            exit;
        if Plan.Get(PurchaseHeader."Installment Plan ID") then
            if (Plan.Status = Plan.Status::Draft) and (Plan."Source SystemId" = PurchaseHeader.SystemId) and
               (Plan."Source Record ID" = PurchaseHeader.RecordId())
            then
                Plan.Delete(true);
    end;

    local procedure SetPlanSource(var Plan: Record "Purchase Installment Plan"; PurchaseHeader: Record "Purchase Header")
    begin
        Plan."Source SystemId" := PurchaseHeader.SystemId;
        Plan."Source Record ID" := PurchaseHeader.RecordId();
        Plan."Source Document No." := PurchaseHeader."No.";
        Plan."Document Date" := PurchaseHeader."Document Date";
        Plan."Currency Code" := PurchaseHeader."Currency Code";
    end;

    local procedure CopyPaymentTerms(PaymentTermsCode: Code[10]; PlanID: Guid; var TempPlanLine: Record "Purchase Installment Plan Line" temporary): Boolean
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        if not InstallmentCalculation.CopyPaymentTerms(PaymentTermsCode, PlanID, TempCalculationLine) then
            exit(false);
        CopyFromCalculationLines(TempCalculationLine, TempPlanLine);
        exit(true);
    end;

    local procedure ValidateRules(var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        CopyToCalculationLines(TempPlanLine, TempCalculationLine);
        InstallmentCalculation.ValidateRules(TempCalculationLine);
    end;

    local procedure CalculateDates(var TempPlanLine: Record "Purchase Installment Plan Line" temporary; DocumentDate: Date)
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        CopyToCalculationLines(TempPlanLine, TempCalculationLine);
        InstallmentCalculation.CalculateDates(TempCalculationLine, DocumentDate);
        CopyFromCalculationLines(TempCalculationLine, TempPlanLine);
    end;

    local procedure Calculate(var TempPlanLine: Record "Purchase Installment Plan Line" temporary; DocumentDate: Date; PostingDate: Date; Amount: Decimal; AmountLCY: Decimal; AmountRoundingPrecision: Decimal; LCYAmountRoundingPrecision: Decimal; PaymentDiscountGracePeriod: DateFormula)
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        CopyToCalculationLines(TempPlanLine, TempCalculationLine);
        InstallmentCalculation.Calculate(
            TempCalculationLine, DocumentDate, PostingDate, Amount, AmountLCY,
            AmountRoundingPrecision, LCYAmountRoundingPrecision, PaymentDiscountGracePeriod);
        CopyFromCalculationLines(TempCalculationLine, TempPlanLine);
    end;

    local procedure CopyToCalculationLines(var TempPlanLine: Record "Purchase Installment Plan Line" temporary; var TempCalculationLine: Record "Installment Calculation Line" temporary)
    begin
        TempCalculationLine.Reset();
        TempCalculationLine.DeleteAll();
        TempPlanLine.Reset();
        if TempPlanLine.FindSet() then
            repeat
                TempCalculationLine.Init();
                TempPlanLine.CopyToCalculationLine(TempCalculationLine);
                TempCalculationLine.Insert();
            until TempPlanLine.Next() = 0;
    end;

    local procedure CopyFromCalculationLines(var TempCalculationLine: Record "Installment Calculation Line" temporary; var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    begin
        TempPlanLine.Reset();
        TempPlanLine.DeleteAll();
        TempCalculationLine.Reset();
        if TempCalculationLine.FindSet() then
            repeat
                TempPlanLine.Init();
                TempPlanLine.CopyFromCalculationLine(TempCalculationLine);
                TempPlanLine.Insert();
            until TempCalculationLine.Next() = 0;
    end;

    local procedure IsSaved(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        SavedHeader: Record "Purchase Header";
    begin
        if not SavedHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then
            exit(false);
        exit(not IsNullGuid(PurchaseHeader.SystemId) and (SavedHeader.SystemId = PurchaseHeader.SystemId));
    end;

    local procedure HasRules(PaymentTermsCode: Code[10]): Boolean
    var
        Rule: Record "Payment Term Installment";
    begin
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then
            exit(false);
        Rule.SetRange("Payment Terms Code", PaymentTermsCode);
        exit(not Rule.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeValidatePaymentTermsCode', '', false, false)]
    local procedure OnBeforeValidatePaymentTermsCode(var PurchaseHeader: Record "Purchase Header"; UpdateDocumentDate: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        if UpdatePaymentTerms(PurchaseHeader, UpdateDocumentDate) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertPurchaseHeader(var Rec: Record "Purchase Header")
    begin
        if Rec.IsTemporary() then
            exit;
        if IsNullGuid(Rec."Installment Plan ID") and not HasRules(Rec."Payment Terms Code") then
            exit;
        Rec.Validate("Payment Terms Code");
        Rec.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyPurchaseHeader(var Rec: Record "Purchase Header")
    var
        SavedHeader: Record "Purchase Header";
        Plan: Record "Purchase Installment Plan";
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
        SavedPlanExists: Boolean;
    begin
        if Rec.IsTemporary() then
            exit;
        if not FeatureKeyManagement.IsPaymentInstallmentsEnabled() then begin
            if not IsNullGuid(Rec."Installment Plan ID") then
                FeatureKeyManagement.CheckPaymentInstallmentsEnabled();
            exit;
        end;
        SavedHeader.Get(Rec."Document Type", Rec."No.");
        if not IsNullGuid(SavedHeader."Installment Plan ID") then begin
            SavedPlanExists := Plan.Get(SavedHeader."Installment Plan ID");
            // Term validation may already have replaced or removed the owned draft.
            if not SavedPlanExists then
                if not IsNullGuid(Rec."Installment Plan ID") then
                    GetOwnedDraft(Rec, Plan)
                else
                    if Rec."Payment Terms Code" = SavedHeader."Payment Terms Code" then
                        Error(PlanLinkErr);
            if SavedPlanExists and (Plan.Status = Plan.Status::Posted) then begin
                Rec.TestField("Installment Plan ID", SavedHeader."Installment Plan ID");
                CheckPostedSource(Rec, Plan);
                CheckHeaderConditions(Rec);
                exit;
            end;
        end;
        if IsNullGuid(Rec."Installment Plan ID") then begin
            if not IsNullGuid(SavedHeader."Installment Plan ID") then begin
                if Rec."Payment Terms Code" = SavedHeader."Payment Terms Code" then
                    Error(PlanLinkErr);
                DeleteOwnedDraft(SavedHeader);
            end;
            if Rec."Payment Terms Code" <> SavedHeader."Payment Terms Code" then
                UpdatePaymentTerms(Rec, false);
            if IsNullGuid(Rec."Installment Plan ID") then
                exit;
        end;
        if Rec."Document Type" <> Rec."Document Type"::Invoice then
            Error(InvoiceOnlyErr);
        Plan.Get(Rec."Installment Plan ID");
        if Plan."Source SystemId" = Rec.SystemId then
            Plan.TestField(Status, Plan.Status::Draft);
        if Plan."Payment Terms Code" <> Rec."Payment Terms Code" then begin
            UpdatePaymentTerms(Rec, false);
            if IsNullGuid(Rec."Installment Plan ID") then
                exit;
            Plan.Get(Rec."Installment Plan ID");
        end;
        if Plan."Source SystemId" <> Rec.SystemId then begin
            LoadRules(Plan.ID, TempPlanLine);
            StoreSnapshot(Rec, TempPlanLine);
            SetHeaderSummary(Rec, TempPlanLine);
            Plan.Get(Rec."Installment Plan ID");
        end;
        if SavedHeader."Installment Plan ID" <> Rec."Installment Plan ID" then
            DeleteOwnedDraft(SavedHeader);
        if (Rec."Payment Discount %" <> 0) or (Rec."Pmt. Discount Date" <> 0D) or (Rec."VAT Base Discount %" <> 0) then
            RaiseHeaderConditionsError(Rec);
        if SavedHeader."Document Date" <> Rec."Document Date" then begin
            LoadRules(Plan.ID, TempPlanLine);
            SetHeaderSummary(Rec, TempPlanLine);
        end;
        CheckHeaderConditions(Rec);
        SetPlanSource(Plan, Rec);
        Plan.Modify(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeletePurchaseHeader(var Rec: Record "Purchase Header")
    begin
        DeleteOwnedDraft(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenamePurchaseHeader(var Rec: Record "Purchase Header")
    var
        Plan: Record "Purchase Installment Plan";
    begin
        if Rec.IsTemporary() or IsNullGuid(Rec."Installment Plan ID") then
            exit;
        Plan.Get(Rec."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        Plan.TestField("Source SystemId", Rec.SystemId);
        SetPlanSource(Plan, Rec);
        Plan.Modify(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Due Date', false, false)]
    local procedure OnAfterValidateDueDate(var Rec: Record "Purchase Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Payment Discount %', false, false)]
    local procedure OnAfterValidatePaymentDiscount(var Rec: Record "Purchase Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Pmt. Discount Date', false, false)]
    local procedure OnAfterValidateDiscountDate(var Rec: Record "Purchase Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'VAT Base Discount %', false, false)]
    local procedure OnAfterValidateVATBaseDiscount(var Rec: Record "Purchase Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
        PurchaseInstallmentPosting: Codeunit "Purchase Installment Posting";
    begin
        if IsNullGuid(PurchaseHeader."Installment Plan ID") then
            exit;
        PurchaseInstallmentPosting.CheckPurchasePosting(PurchaseHeader);
        CalculatePreview(PurchaseHeader, TempPlanLine);
    end;
}
