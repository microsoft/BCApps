// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;

codeunit 8841 "Sales Installment Mgt."
{
    Permissions = tabledata "Sales Installment Plan" = RIMD,
                  tabledata "Sales Installment Plan Line" = RIMD;

    var
        InvoiceOnlyErr: Label 'Global installments currently support standalone sales invoices only.';
        TemporaryHeaderErr: Label 'An installment schedule requires a saved sales invoice.';
        TemporaryResultErr: Label 'Installment preview requires a temporary plan line record.';
        EmptyPlanErr: Label 'The installment rule snapshot is empty.';
        HeaderConditionsErr: Label 'The due date is the first installment summary, and header payment discount conditions must be zero. Use the Installment Schedule to view the conditions.';
        ViewScheduleLbl: Label 'View Installment Schedule';
        PlanLinkErr: Label 'The installment plan must belong to this invoice and match its payment terms. Change the payment terms to replace or remove the plan.';
        DiscountPolicyErr: Label 'Installment preview with payment discounts does not yet support Pmt. Disc. Excl. VAT or Adjust for Payment Disc. in General Ledger Setup.';

    procedure ShowSchedule(var SalesHeader: Record "Sales Header")
    var
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
        Schedule: Page "Sales Installment Schedule";
    begin
        CalculatePreview(SalesHeader, TempPlanLine);
        Schedule.SetSchedule(SalesHeader, TempPlanLine);
        Schedule.Run();
    end;

    procedure ShowScheduleFromError(ErrorInfo: ErrorInfo)
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderRef: RecordRef;
    begin
        SalesHeaderRef := ErrorInfo.RecordId.GetRecord();
        SalesHeaderRef.SetTable(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        ShowSchedule(SalesHeader);
    end;

    procedure CalculatePreview(var SalesHeader: Record "Sales Header"; var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    var
        Plan: Record "Sales Installment Plan";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        TempSalesLine: Record "Sales Line" temporary;
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        VATAmount: Decimal;
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
    begin
        if not TempPlanLine.IsTemporary() then
            Error(TemporaryResultErr);
        if SalesHeader.IsTemporary() or not IsSaved(SalesHeader) then
            Error(TemporaryHeaderErr);
        GetOwnedDraft(SalesHeader, Plan);
        CheckHeaderConditions(SalesHeader);
        LoadRules(Plan.ID, TempPlanLine);
        GLSetup.Get();
        TempPlanLine.SetFilter("Discount %", '<>0');
        if not TempPlanLine.IsEmpty() then
            if GLSetup."Pmt. Disc. Excl. VAT" or GLSetup."Adjust for Payment Disc." then
                Error(DiscountPolicyErr);
        TempPlanLine.Reset();
        Currency.Initialize(SalesHeader."Currency Code", true);
        GLSetup.TestField("Amount Rounding Precision");

        // Use the statistics totals path, including temporary invoice rounding.
        // Do not call PrepareOpeningDocumentStatistics, which commits.
        SalesHeader.CalcInvDiscForHeader();
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 0, true, true);
        Clear(SalesPost);
        SalesPost.SumSalesLinesTemp(
            SalesHeader, TempSalesLine, 0, TotalSalesLine, TotalSalesLineLCY,
            VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY, true, true);
        Calculate(
            TempPlanLine, SalesHeader."Document Date", SalesHeader."Posting Date",
            TotalSalesLine."Amount Including VAT", TotalSalesLineLCY."Amount Including VAT",
            Currency."Amount Rounding Precision", GLSetup."Amount Rounding Precision", GLSetup."Payment Discount Grace Period");
    end;

    local procedure UpdatePaymentTerms(var SalesHeader: Record "Sales Header"; UpdateDocumentDate: Boolean): Boolean
    var
        Plan: Record "Sales Installment Plan";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
    begin
        if SalesHeader.IsTemporary() then
            exit(false);
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then begin
            if not IsNullGuid(SalesHeader."Installment Plan ID") or
               ((SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo") and
                not UpdateDocumentDate and HasRules(SalesHeader."Payment Terms Code"))
            then
                Error(InvoiceOnlyErr);
            exit(false);
        end;

        if not IsNullGuid(SalesHeader."Installment Plan ID") then begin
            Plan.Get(SalesHeader."Installment Plan ID");
            if Plan."Source SystemId" = SalesHeader.SystemId then
                Plan.TestField(Status, Plan.Status::Draft);
            if Plan."Payment Terms Code" = SalesHeader."Payment Terms Code" then begin
                LoadRules(Plan.ID, TempPlanLine);
                if IsSaved(SalesHeader) and (Plan."Source SystemId" <> SalesHeader.SystemId) then
                    StoreSnapshot(SalesHeader, TempPlanLine);
                SetHeaderSummary(SalesHeader, TempPlanLine);
                exit(true);
            end;
        end else
            if UpdateDocumentDate then
                exit(false);

        if not HasRules(SalesHeader."Payment Terms Code") then begin
            DeleteOwnedDraft(SalesHeader);
            Clear(SalesHeader."Installment Plan ID");
            exit(false);
        end;
        CopyPaymentTerms(SalesHeader."Payment Terms Code", CreateGuid(), TempPlanLine);
        if SalesHeader."Document Date" <> 0D then
            CalculateDates(TempPlanLine, SalesHeader."Document Date");
        if IsSaved(SalesHeader) then
            StoreSnapshot(SalesHeader, TempPlanLine);
        SetHeaderSummary(SalesHeader, TempPlanLine);
        exit(true);
    end;

    local procedure StoreSnapshot(var SalesHeader: Record "Sales Header"; var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    var
        SavedHeader: Record "Sales Header";
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
    begin
        DeleteOwnedDraft(SalesHeader);
        SavedHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        DeleteOwnedDraft(SavedHeader);
        Plan.Init();
        Plan.ID := CreateGuid();
        Plan."Payment Terms Code" := SalesHeader."Payment Terms Code";
        SetPlanSource(Plan, SalesHeader);
        Plan.Insert(true);
        TempPlanLine.Reset();
        if TempPlanLine.FindSet() then
            repeat
                PlanLine.Init();
                PlanLine."Plan ID" := Plan.ID;
                PlanLine.CopyRulesFromPlanLine(TempPlanLine);
                PlanLine.Insert(true);
            until TempPlanLine.Next() = 0;
        SalesHeader."Installment Plan ID" := Plan.ID;
    end;

    local procedure LoadRules(PlanID: Guid; var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    var
        PlanLine: Record "Sales Installment Plan Line";
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

    local procedure SetHeaderSummary(var SalesHeader: Record "Sales Header"; var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    begin
        SalesHeader."Due Date" := 0D;
        if SalesHeader."Document Date" <> 0D then begin
            CalculateDates(TempPlanLine, SalesHeader."Document Date");
            TempPlanLine.FindFirst();
            SalesHeader."Due Date" := TempPlanLine."Due Date";
        end;
        SalesHeader."Pmt. Discount Date" := 0D;
        if (SalesHeader."Payment Discount %" <> 0) or (SalesHeader."VAT Base Discount %" <> 0) then
            if IsSaved(SalesHeader) then
                SalesHeader.Validate("Payment Discount %", 0)
            else begin
                SalesHeader."Payment Discount %" := 0;
                SalesHeader."VAT Base Discount %" := 0;
            end;
    end;

    local procedure CheckHeaderConditions(SalesHeader: Record "Sales Header")
    var
        Plan: Record "Sales Installment Plan";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
        DueDate: Date;
    begin
        if SalesHeader.IsTemporary() or IsNullGuid(SalesHeader."Installment Plan ID") then
            exit;
        Plan.Get(SalesHeader."Installment Plan ID");
        if Plan.Status = Plan.Status::Posted then
            CheckPostedSource(SalesHeader, Plan)
        else
            GetOwnedDraft(SalesHeader, Plan);
        LoadRules(Plan.ID, TempPlanLine);
        if SalesHeader."Document Date" <> 0D then begin
            CalculateDates(TempPlanLine, SalesHeader."Document Date");
            TempPlanLine.FindFirst();
            DueDate := TempPlanLine."Due Date";
        end;
        if (SalesHeader."Due Date" <> DueDate) or (SalesHeader."Payment Discount %" <> 0) or
           (SalesHeader."Pmt. Discount Date" <> 0D) or (SalesHeader."VAT Base Discount %" <> 0)
        then
            RaiseHeaderConditionsError(SalesHeader);
    end;

    local procedure RaiseHeaderConditionsError(SalesHeader: Record "Sales Header")
    var
        HeaderConditionsErrorInfo: ErrorInfo;
    begin
        HeaderConditionsErrorInfo := ErrorInfo.Create(HeaderConditionsErr);
        HeaderConditionsErrorInfo.RecordId(SalesHeader.RecordId());
        HeaderConditionsErrorInfo.AddAction(ViewScheduleLbl, Codeunit::"Sales Installment Mgt.", 'ShowScheduleFromError');
        Error(HeaderConditionsErrorInfo);
    end;

    local procedure GetOwnedDraft(SalesHeader: Record "Sales Header"; var Plan: Record "Sales Installment Plan")
    begin
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.TestField("Installment Plan ID");
        Plan.Get(SalesHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        if (Plan."Source SystemId" <> SalesHeader.SystemId) or
           (Plan."Source Record ID" <> SalesHeader.RecordId()) or
           (Plan."Payment Terms Code" <> SalesHeader."Payment Terms Code")
        then
            Error(PlanLinkErr);
    end;

    local procedure CheckPostedSource(SalesHeader: Record "Sales Header"; Plan: Record "Sales Installment Plan")
    var
        PostedInvoice: Record "Sales Invoice Header";
    begin
        if (Plan."Source SystemId" <> SalesHeader.SystemId) or
           (Plan."Source Record ID" <> SalesHeader.RecordId()) or
           (Plan."Payment Terms Code" <> SalesHeader."Payment Terms Code") or
           (Plan."Document Date" <> SalesHeader."Document Date") or
           (Plan."Currency Code" <> SalesHeader."Currency Code") or
           (Plan."Posting Date" <> SalesHeader."Posting Date")
        then
            Error(PlanLinkErr);
        PostedInvoice.Get(Plan."Posted Invoice No.");
        PostedInvoice.TestField(SystemId, Plan."Posted Invoice SystemId");
        PostedInvoice.TestField("Installment Plan ID", Plan.ID);
    end;

    local procedure DeleteOwnedDraft(SalesHeader: Record "Sales Header")
    var
        Plan: Record "Sales Installment Plan";
    begin
        if SalesHeader.IsTemporary() or IsNullGuid(SalesHeader."Installment Plan ID") or IsNullGuid(SalesHeader.SystemId) then
            exit;
        if Plan.Get(SalesHeader."Installment Plan ID") then
            if (Plan.Status = Plan.Status::Draft) and (Plan."Source SystemId" = SalesHeader.SystemId) and
               (Plan."Source Record ID" = SalesHeader.RecordId())
            then
                Plan.Delete(true);
    end;

    local procedure SetPlanSource(var Plan: Record "Sales Installment Plan"; SalesHeader: Record "Sales Header")
    begin
        Plan."Source SystemId" := SalesHeader.SystemId;
        Plan."Source Record ID" := SalesHeader.RecordId();
        Plan."Source Document No." := SalesHeader."No.";
        Plan."Document Date" := SalesHeader."Document Date";
        Plan."Currency Code" := SalesHeader."Currency Code";
    end;

    local procedure CopyPaymentTerms(PaymentTermsCode: Code[10]; PlanID: Guid; var TempPlanLine: Record "Sales Installment Plan Line" temporary): Boolean
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        if not InstallmentCalculation.CopyPaymentTerms(PaymentTermsCode, PlanID, TempCalculationLine) then
            exit(false);
        CopyFromCalculationLines(TempCalculationLine, TempPlanLine);
        exit(true);
    end;

    local procedure ValidateRules(var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        CopyToCalculationLines(TempPlanLine, TempCalculationLine);
        InstallmentCalculation.ValidateRules(TempCalculationLine);
    end;

    local procedure CalculateDates(var TempPlanLine: Record "Sales Installment Plan Line" temporary; DocumentDate: Date)
    var
        TempCalculationLine: Record "Installment Calculation Line" temporary;
        InstallmentCalculation: Codeunit "Installment Calculation";
    begin
        CopyToCalculationLines(TempPlanLine, TempCalculationLine);
        InstallmentCalculation.CalculateDates(TempCalculationLine, DocumentDate);
        CopyFromCalculationLines(TempCalculationLine, TempPlanLine);
    end;

    local procedure Calculate(var TempPlanLine: Record "Sales Installment Plan Line" temporary; DocumentDate: Date; PostingDate: Date; Amount: Decimal; AmountLCY: Decimal; AmountRoundingPrecision: Decimal; LCYAmountRoundingPrecision: Decimal; PaymentDiscountGracePeriod: DateFormula)
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

    local procedure CopyToCalculationLines(var TempPlanLine: Record "Sales Installment Plan Line" temporary; var TempCalculationLine: Record "Installment Calculation Line" temporary)
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

    local procedure CopyFromCalculationLines(var TempCalculationLine: Record "Installment Calculation Line" temporary; var TempPlanLine: Record "Sales Installment Plan Line" temporary)
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

    local procedure IsSaved(SalesHeader: Record "Sales Header"): Boolean
    var
        SavedHeader: Record "Sales Header";
    begin
        if not SavedHeader.Get(SalesHeader."Document Type", SalesHeader."No.") then
            exit(false);
        exit(not IsNullGuid(SalesHeader.SystemId) and (SavedHeader.SystemId = SalesHeader.SystemId));
    end;

    local procedure HasRules(PaymentTermsCode: Code[10]): Boolean
    var
        Rule: Record "Payment Term Installment";
    begin
        Rule.SetRange("Payment Terms Code", PaymentTermsCode);
        exit(not Rule.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeValidatePaymentTermsCode', '', false, false)]
    local procedure OnBeforeValidatePaymentTermsCode(var SalesHeader: Record "Sales Header"; UpdateDocumentDate: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        if UpdatePaymentTerms(SalesHeader, UpdateDocumentDate) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertSalesHeader(var Rec: Record "Sales Header")
    begin
        if Rec.IsTemporary() then
            exit;
        if IsNullGuid(Rec."Installment Plan ID") and not HasRules(Rec."Payment Terms Code") then
            exit;
        Rec.Validate("Payment Terms Code");
        Rec.Modify(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifySalesHeader(var Rec: Record "Sales Header")
    var
        SavedHeader: Record "Sales Header";
        Plan: Record "Sales Installment Plan";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
        SavedPlanExists: Boolean;
    begin
        if Rec.IsTemporary() then
            exit;
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

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header")
    begin
        DeleteOwnedDraft(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameSalesHeader(var Rec: Record "Sales Header")
    var
        Plan: Record "Sales Installment Plan";
    begin
        if Rec.IsTemporary() or IsNullGuid(Rec."Installment Plan ID") then
            exit;
        Plan.Get(Rec."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        Plan.TestField("Source SystemId", Rec.SystemId);
        SetPlanSource(Plan, Rec);
        Plan.Modify(true);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Due Date', false, false)]
    local procedure OnAfterValidateDueDate(var Rec: Record "Sales Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Payment Discount %', false, false)]
    local procedure OnAfterValidatePaymentDiscount(var Rec: Record "Sales Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Pmt. Discount Date', false, false)]
    local procedure OnAfterValidateDiscountDate(var Rec: Record "Sales Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'VAT Base Discount %', false, false)]
    local procedure OnAfterValidateVATBaseDiscount(var Rec: Record "Sales Header")
    begin
        CheckHeaderConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    var
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
        InstallmentPosting: Codeunit "Installment Posting";
    begin
        if IsNullGuid(SalesHeader."Installment Plan ID") then
            exit;
        InstallmentPosting.CheckSalesPosting(SalesHeader);
        CalculatePreview(SalesHeader, TempPlanLine);
    end;
}
