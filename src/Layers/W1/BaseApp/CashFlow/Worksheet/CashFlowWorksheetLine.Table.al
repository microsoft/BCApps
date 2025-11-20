// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

table 846 "Cash Flow Worksheet Line"
{
    Caption = 'Cash Flow Worksheet Line';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Cash Flow Forecast No."; Code[20])
        {
            Caption = 'Cash Flow Forecast No.';
            TableRelation = "Cash Flow Forecast";

            trigger OnValidate()
            var
                CashFlowForecast: Record "Cash Flow Forecast";
            begin
                if "Cash Flow Forecast No." = '' then
                    exit;

                CashFlowForecast.Get("Cash Flow Forecast No.");
                Description := CashFlowForecast.Description;
            end;
        }
        field(4; "Cash Flow Date"; Date)
        {
            Caption = 'Cash Flow Date';
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; "Cash Flow Account No."; Code[20])
        {
            Caption = 'Cash Flow Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            var
                CFAccount: Record "Cash Flow Account";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateCashFlowAccountNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;
                if "Cash Flow Account No." <> '' then begin
                    CFAccount.Get("Cash Flow Account No.");
                    CFAccount.TestField("Account Type", CFAccount."Account Type"::Entry);
                    CFAccount.TestField(Blocked, false);
                    if "Cash Flow Account No." <> xRec."Cash Flow Account No." then begin
                        Description := CFAccount.Name;
                        "Source Type" := CFAccount."Source Type";
                    end;
                end;
            end;
        }
        field(7; "Source Type"; Enum "Cash Flow Source Type")
        {
            Caption = 'Source Type';

            trigger OnValidate()
            begin
                if "Source Type" <> "Source Type"::"G/L Budget" then
                    "G/L Budget Name" := '';
            end;
        }
        field(8; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(9; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(10; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(11; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(12; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';
        }
        field(13; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(14; "Payment Discount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Payment Discount';
        }
        field(15; "Associated Entry No."; Integer)
        {
            Caption = 'Associated Entry No.';
        }
        field(16; Overdue; Boolean)
        {
            Caption = 'Overdue';
            Editable = false;
        }
        field(17; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(18; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(30; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(34; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const("Liquid Funds")) "G/L Account"
            else
            if ("Source Type" = const(Receivables)) "Cust. Ledger Entry"."Document No."
            else
            if ("Source Type" = const(Payables)) "Vendor Ledger Entry"."Document No."
            else
            if ("Source Type" = const("Fixed Assets Budget")) "Fixed Asset"
            else
            if ("Source Type" = const("Fixed Assets Disposal")) "Fixed Asset"
            else
            if ("Source Type" = const("Sales Orders")) "Sales Header"."No." where("Document Type" = const(Order))
            else
            if ("Source Type" = const("Purchase Orders")) "Purchase Header"."No." where("Document Type" = const(Order))
            else
            if ("Source Type" = const("Cash Flow Manual Expense")) "Cash Flow Manual Expense"
            else
            if ("Source Type" = const("Cash Flow Manual Revenue")) "Cash Flow Manual Revenue"
            else
            if ("Source Type" = const("G/L Budget")) "G/L Account"
            else
            if ("Source Type" = const(Job)) Job."No.";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
            begin
                case "Source Type" of
                    "Source Type"::"Liquid Funds":
                        MoveDefualtDimToJnlLineDim(DATABASE::"G/L Account", "Source No.", "Dimension Set ID");
                    "Source Type"::Receivables:
                        begin
                            CustLedgEntry.SetRange("Document No.", "Source No.");
                            if CustLedgEntry.FindFirst() then
                                "Dimension Set ID" := CustLedgEntry."Dimension Set ID";
                        end;
                    "Source Type"::Payables:
                        begin
                            VendLedgEntry.SetRange("Document No.", "Source No.");
                            if VendLedgEntry.FindFirst() then
                                "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
                        end;
                    "Source Type"::"Fixed Assets Disposal",
                  "Source Type"::"Fixed Assets Budget":
                        MoveDefualtDimToJnlLineDim(DATABASE::"Fixed Asset", "Source No.", "Dimension Set ID");
                end;
            end;
        }
        field(35; "G/L Budget Name"; Code[10])
        {
            Caption = 'G/L Budget Name';
            TableRelation = "G/L Budget Name";

            trigger OnValidate()
            begin
                TestField("Source Type", "Source Type"::"G/L Budget");
            end;
        }
        field(36; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Flow Forecast No.", "Document No.")
        {
            SumIndexFields = "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    procedure EmptyLine(): Boolean
    begin
        exit(("Cash Flow Forecast No." = '') and ("Cash Flow Account No." = ''));
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1', "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure MoveDefualtDimToJnlLineDim(TableID: Integer; No: Code[20]; var DimensionSetID: Integer)
    var
        Dimension: Code[20];
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        DimMgt.AddDimSource(DefaultDimSource, TableID, No);
        Dimension := '';
        DimensionSetID := DimMgt.GetRecDefaultDimID(Rec, CurrFieldNo, DefaultDimSource, '', Dimension, Dimension, 0, 0);

        OnAfterMoveDefualtDimToJnlLineDim(Rec, DimensionSetID, DefaultDimSource);
    end;

    procedure CalculateCFAmountAndCFDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        CashFlowForecast: Record "Cash Flow Forecast";
        DiscountDateCalculation: DateFormula;
        PaymentTermsToApply: Code[10];
        CFDiscountDate: Date;
        CheckCrMemo: Boolean;
        ApplyCFPaymentTerm: Boolean;
        IsHandled: Boolean;
    begin
        if "Document Date" = 0D then
            "Document Date" := WorkDate();
        if "Cash Flow Date" = 0D then
            "Cash Flow Date" := "Document Date";
        if "Amount (LCY)" = 0 then
            exit;

        case "Document Type" of
            "Document Type"::Invoice:
                CheckCrMemo := false;
            "Document Type"::"Credit Memo":
                CheckCrMemo := true;
            else
                exit;
        end;

        if not CashFlowForecast.Get("Cash Flow Forecast No.") then
            exit;

        PaymentTermsToApply := "Payment Terms Code";
        ApplyCFPaymentTerm := CashFlowForecast."Consider CF Payment Terms" and PaymentTerms.Get(PaymentTermsToApply);
        if "Source Type" in ["Source Type"::"Sales Orders", "Source Type"::"Purchase Orders", "Source Type"::Job] then
            ApplyCFPaymentTerm := true;

        IsHandled := false;
        OnCalculateCFAmountAndCFDateOnAfterAssignApplyCFPaymentTerm(Rec, ApplyCFPaymentTerm, CheckCrMemo, IsHandled);
        if IsHandled then
            exit;

        if not ApplyCFPaymentTerm then begin
            if not CashFlowForecast."Consider Discount" then
                exit;

            if CashFlowForecast."Consider Pmt. Disc. Tol. Date" then
                CFDiscountDate := "Pmt. Disc. Tolerance Date"
            else
                CFDiscountDate := "Pmt. Discount Date";

            if CFDiscountDate <> 0D then
                if CFDiscountDate >= WorkDate() then begin
                    "Cash Flow Date" := CFDiscountDate;
                    "Amount (LCY)" := "Amount (LCY)" - "Payment Discount";
                end else
                    "Payment Discount" := 0;
            exit;
        end;

        if not PaymentTerms.Get(PaymentTermsToApply) then
            exit;

        if CheckCrMemo and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
            exit;

        if CashFlowForecast."Consider Discount" then begin
            GeneralLedgerSetup.Get();

            DiscountDateCalculation := PaymentTerms."Discount Date Calculation";
            if Format(DiscountDateCalculation) = '' then
                DiscountDateCalculation := PaymentTerms."Due Date Calculation";
            CFDiscountDate := CalcDate(DiscountDateCalculation, "Document Date");
            if CashFlowForecast."Consider Pmt. Disc. Tol. Date" then
                CFDiscountDate := CalcDate(GeneralLedgerSetup."Payment Discount Grace Period", CFDiscountDate);

            IsHandled := false;
            OnCalculateCFAmountAndCFDateOnBeforeCalcPaymentDiscount(CFDiscountDate, PaymentTerms, IsHandled);
            if not IsHandled then
                if CFDiscountDate >= WorkDate() then begin
                    "Cash Flow Date" := CFDiscountDate;

                    "Payment Discount" := Round("Amount (LCY)" * PaymentTerms."Discount %" / 100);
                    "Amount (LCY)" := "Amount (LCY)" - "Payment Discount";
                end else begin
                    "Cash Flow Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                    "Payment Discount" := 0;
                end;
        end else
            "Cash Flow Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
    end;

    procedure ShowSource()
    var
        CFManagement: Codeunit "Cash Flow Management";
    begin
        CFManagement.ShowSource(Rec);
    end;

#if not CLEAN26
    [Obsolete('GetNumberOfSourceTypes() replaced with Enum::"Cash Flow Source Type".Ordinals().Count()', '26.0')]
    procedure GetNumberOfSourceTypes() Result: Integer
    begin
        Result := Enum::"Cash Flow Source Type".Ordinals().Count();

        OnAfterGetNumberOfSourceTypes(Rec, Result);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('GetNumberOfSourceTypes() replaced with Enum::"Cash Flow Source Type".Ordinals().Count()', '26.0')]
    local procedure OnAfterGetNumberOfSourceTypes(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var Result: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveDefualtDimToJnlLineDim(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var DimensionSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var xCashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var xCashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateCFAmountAndCFDateOnAfterAssignApplyCFPaymentTerm(CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var ApplyCFPaymentTerm: Boolean; var CheckCrMemo: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateCFAmountAndCFDateOnBeforeCalcPaymentDiscount(CFDiscountDate: Date; PaymentTerms: record "Payment Terms"; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateCashFlowAccountNo(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var xCashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; var IsHandled: Boolean)
    begin
    end;
}
