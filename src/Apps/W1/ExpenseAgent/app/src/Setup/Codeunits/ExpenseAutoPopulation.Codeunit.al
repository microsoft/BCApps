// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using System.Utilities;

codeunit 6912 "Expense Auto Population"
{
    Access = Internal;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        DailyRateConditionMissingForRangeErr: Label 'Daily Rate condition is missing for Per Diem rule.';
        PerDiemForLbl: Label 'Per Diem for: %1', Comment = '%1 = Date';
        RuleUpdateQst: Label 'Your recent change in Expense Document No. %1 is aligned to a different rule. Do you want to update the expense based on the new rule?', Comment = '%1 = Expense No.';

    procedure FindRuleAndUpdateExpense(var Expense: Record Expense)
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        RemoveNonRelevantExpenseDetailFromExpense(Expense);

        ApplyDefaultExpenseCalculations(Expense);
        if not ExpenseRuleValidation.ShouldApplyRule(Expense."Expense Detail Required") then
            exit;

        if not ExpenseRuleHeader.FindApplicableRule(Expense) then
            exit;

        ConfirmAndUpdateRuleOnExpense(Expense, ExpenseRuleHeader);
        UpdateFromRule(Expense, ExpenseRuleHeader);
    end;

    local procedure UpdatePerDiemRange(var Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header"; StartDate: Date; EndDate: Date)
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePerDiem: Record "Expense Per Diem";
        ExpensePerDiemCalculation: Codeunit "Expense Per Diem Calculation";
        CurrentDate: Date;
        BaseRate: Decimal;
        TotalAmount: Decimal;
        DayPerDiemAmount: Decimal;
        ExpenseLineNo: Integer;
    begin
        ExpensePerDiemCalculation.SetExpenseAgentSetup(ExpenseAgentSetup);

        ExpenseRuleCondition.SetRange("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", ExpenseRuleHeader."Effective Date");
        ExpenseRuleCondition.SetRange("Condition Type", ExpenseRuleCondition."Condition Type"::"Daily Rate");

        if not ExpenseRuleCondition.FindFirst() then
            Error(DailyRateConditionMissingForRangeErr);

        BaseRate := ExpenseRuleCondition.Value;

        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        ExpensePerDiem.DeleteAll();

        Expense.CheckExpensePrerequisitesBeforeUsing();

        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            ExpenseLineNo += 10000;

            DayPerDiemAmount := ExpensePerDiemCalculation.CalculatePerDiemForSingleDay(CurrentDate, BaseRate, Expense."Starting Date and Time", Expense."Ending Date and Time");

            ExpensePerDiem.Init();
            ExpensePerDiem."Expense No." := Expense."No.";
            ExpensePerDiem."Expense Category Code" := Expense."Expense Category";
            ExpensePerDiem."Expense Subcategory Code" := Expense."Expense Subcategory";
            ExpensePerDiem."Expense Location" := Expense."Expense Location";
            ExpensePerDiem."Line No." := ExpenseLineNo;
            ExpensePerDiem.Description := StrSubstNo(PerDiemForLbl, Format(CurrentDate));
            ExpensePerDiem.Date := CurrentDate;
            ExpensePerDiem."Per Diem Amount" := DayPerDiemAmount;
            ExpensePerDiem."Original Per Diem Amount" := DayPerDiemAmount;
            ExpensePerDiem."Breakfast Reduction Percent" := ExpenseAgentSetup."Reduction for Breakfast %";
            ExpensePerDiem."Lunch Reduction Percent" := ExpenseAgentSetup."Reduction for Lunch %";
            ExpensePerDiem."Dinner Reduction Percent" := ExpenseAgentSetup."Reduction for Dinner %";
            ExpensePerDiem.Insert(true);

            TotalAmount += DayPerDiemAmount;
            CurrentDate := CalcDate('<+1D>', CurrentDate);
        end;

        Expense.Validate(Amount, TotalAmount);
    end;

    procedure FindRuleAndUpdateExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        RemoveNonRelevantExpenseDetailFromExpenseReportLine(ExpenseReportLine);

        ApplyDefaultExpenseReportCalculations(ExpenseReportLine);
        if not ExpenseRuleValidation.ShouldApplyRule(ExpenseReportLine."Expense Detail Required") then
            exit;

        if not ExpenseRuleHeader.FindApplicableRule(ExpenseReportLine) then
            exit;

        ConfirmAndUpdateRuleOnExpenseReportLine(ExpenseReportLine, ExpenseRuleHeader);
        UpdateFromRuleForReportLine(ExpenseReportLine, ExpenseRuleHeader);
    end;

    local procedure UpdatePerDiemRangeForReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header"; StartDate: Date; EndDate: Date)
    var
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ExpensePerDiemCalculation: Codeunit "Expense Per Diem Calculation";
        CurrentDate: Date;
        BaseRate: Decimal;
        TotalAmount: Decimal;
        DayPerDiemAmount: Decimal;
        ExpenseLineNo: Integer;
    begin
        ExpensePerDiemCalculation.SetExpenseAgentSetup(ExpenseAgentSetup);

        ExpenseRuleCondition.SetRange("Expense Category Code", ExpenseRuleHeader."Expense Category Code");
        ExpenseRuleCondition.SetRange("Expense Location", ExpenseRuleHeader."Expense Location");
        ExpenseRuleCondition.SetRange("Effective Date", ExpenseRuleHeader."Effective Date");
        ExpenseRuleCondition.SetRange("Condition Type", ExpenseRuleCondition."Condition Type"::"Daily Rate");

        if not ExpenseRuleCondition.FindFirst() then
            Error(DailyRateConditionMissingForRangeErr);

        BaseRate := ExpenseRuleCondition.Value;

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLinePerDiem.IsEmpty() then
            ExpenseReportLinePerDiem.DeleteAll();

        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            ExpenseLineNo += 10000;

            DayPerDiemAmount := ExpensePerDiemCalculation.CalculatePerDiemForSingleDay(CurrentDate, BaseRate, ExpenseReportLine."Starting Date and Time", ExpenseReportLine."Ending Date and Time");

            ExpenseReportLinePerDiem.Init();
            ExpenseReportLinePerDiem."Expense Report No." := ExpenseReportLine."Document No.";
            ExpenseReportLinePerDiem."Expense Report Line No." := ExpenseReportLine."Line No.";
            ExpenseReportLinePerDiem."Line No." := ExpenseLineNo;
            ExpenseReportLinePerDiem."Expense Category Code" := ExpenseReportLine."Expense Category";
            ExpenseReportLinePerDiem."Expense Subcategory Code" := ExpenseReportLine."Expense Subcategory Code";
            ExpenseReportLinePerDiem."Expense Location" := ExpenseReportLine."Expense Location";
            ExpenseReportLinePerDiem.Description := StrSubstNo(PerDiemForLbl, Format(CurrentDate));
            ExpenseReportLinePerDiem.Date := CurrentDate;
            ExpenseReportLinePerDiem."Per Diem Amount" := DayPerDiemAmount;
            ExpenseReportLinePerDiem."Original Per Diem Amount" := DayPerDiemAmount;
            ExpenseReportLinePerDiem."Breakfast Reduction Percent" := ExpenseAgentSetup."Reduction for Breakfast %";
            ExpenseReportLinePerDiem."Lunch Reduction Percent" := ExpenseAgentSetup."Reduction for Lunch %";
            ExpenseReportLinePerDiem."Dinner Reduction Percent" := ExpenseAgentSetup."Reduction for Dinner %";
            ExpenseReportLinePerDiem.Insert(true);

            TotalAmount += DayPerDiemAmount;
            CurrentDate := CalcDate('<+1D>', CurrentDate);
        end;

        ExpenseReportLine.Validate(Amount, TotalAmount);
    end;

    local procedure ConfirmAndUpdateRuleOnExpense(var Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not GuiAllowed then
            exit;

        if IsNullGuid(Expense."Applied Rule Id") then
            exit;

        if Expense."Applied Rule Id" = ExpenseRuleHeader.SystemId then
            exit;

        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(RuleUpdateQst, Expense."No."), true) then begin
            Expense."Applied Rule Id" := ExpenseRuleHeader.SystemId;
            exit;
        end;

        Error('');
    end;

    local procedure ConfirmAndUpdateRuleOnExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not GuiAllowed then
            exit;

        if IsNullGuid(ExpenseReportLine."Applied Rule Id") then
            exit;

        if ExpenseReportLine."Applied Rule Id" = ExpenseRuleHeader.SystemId then
            exit;

        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(RuleUpdateQst, ExpenseReportLine."Document No."), true) then begin
            ExpenseReportLine."Applied Rule Id" := ExpenseRuleHeader.SystemId;
            ExpenseReportLine.Modify(true);
            exit;
        end;

        Error('');
    end;

    local procedure RemoveNonRelevantExpenseDetailFromExpense(var Expense: Record Expense)
    begin
        if Expense."Expense Detail Required" <> Expense."Expense Detail Required"::Mileage then begin
            Expense.Validate(Mileage, 0);
            Expense."Round Trip" := false;
            Expense."Starting Point" := '';
            Expense."Ending Point" := '';
        end;

        if Expense."Expense Detail Required" = Expense."Expense Detail Required"::"Per Diem" then
            Expense.Validate(Amount, 0);

        case Expense."Expense Detail Required" of
            "Expense Detail Needed"::" ":
                begin
                    DeleteItemization(Expense);
                    DeletePerDiem(Expense);
                    DeleteParticipants(Expense);
                end;
            "Expense Detail Needed"::Itemize:
                begin
                    DeletePerDiem(Expense);
                    DeleteParticipants(Expense);
                end;
            "Expense Detail Needed"::Participants:
                begin
                    DeleteItemization(Expense);
                    DeletePerDiem(Expense);
                end;
            "Expense Detail Needed"::"Per Diem":
                begin
                    DeleteItemization(Expense);
                    DeleteParticipants(Expense);
                end;
        end;
    end;

    local procedure RemoveNonRelevantExpenseDetailFromExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line")
    begin
        if ExpenseReportLine."Expense Detail Required" <> ExpenseReportLine."Expense Detail Required"::Mileage then begin
            ExpenseReportLine.Validate(Mileage, 0);
            ExpenseReportLine."Round Trip" := false;
            ExpenseReportLine."Starting Point" := '';
            ExpenseReportLine."Ending Point" := '';
        end;

        if ExpenseReportLine."Expense Detail Required" = ExpenseReportLine."Expense Detail Required"::"Per Diem" then
            ExpenseReportLine.Validate(Amount, 0);

        case ExpenseReportLine."Expense Detail Required" of
            "Expense Detail Needed"::" ":
                begin
                    DeleteItemization(ExpenseReportLine);
                    DeletePerDiem(ExpenseReportLine);
                    DeleteParticipants(ExpenseReportLine);
                end;
            "Expense Detail Needed"::Itemize:
                begin
                    DeletePerDiem(ExpenseReportLine);
                    DeleteParticipants(ExpenseReportLine);
                end;
            "Expense Detail Needed"::Participants:
                begin
                    DeleteItemization(ExpenseReportLine);
                    DeletePerDiem(ExpenseReportLine);
                end;
            "Expense Detail Needed"::"Per Diem":
                begin
                    DeleteItemization(ExpenseReportLine);
                    DeleteParticipants(ExpenseReportLine);
                end;
        end;
    end;

    local procedure DeleteItemization(Expense: Record Expense)
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        if not ExpenseItemization.IsEmpty() then
            ExpenseItemization.DeleteAll();
    end;

    local procedure DeleteItemization(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineItem: Record "Expense Report Line Item";
    begin
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineItem.IsEmpty() then
            ExpenseReportLineItem.DeleteAll();
    end;

    local procedure DeletePerDiem(Expense: Record Expense)
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        if not ExpensePerDiem.IsEmpty() then
            ExpensePerDiem.DeleteAll();
    end;

    local procedure DeletePerDiem(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseExpenseReportLineItemPerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseExpenseReportLineItemPerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseExpenseReportLineItemPerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseExpenseReportLineItemPerDiem.IsEmpty() then
            ExpenseExpenseReportLineItemPerDiem.DeleteAll();
    end;

    local procedure DeleteParticipants(Expense: Record Expense)
    var
        ExpenseParticipant: Record "Expense Participant";
    begin
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        if not ExpenseParticipant.IsEmpty() then
            ExpenseParticipant.DeleteAll();
    end;

    local procedure DeleteParticipants(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
    begin
        ExpenseReportLineParticip.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineParticip.IsEmpty() then
            ExpenseReportLineParticip.DeleteAll();
    end;

    local procedure UpdateFromRule(var Expense: Record Expense; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        Expense."Applied Rule Id" := ExpenseRuleHeader.SystemId;

        if Expense."Expense Detail Required" = Expense."Expense Detail Required"::"Per Diem" then
            Expense.Validate("Currency Code", ExpenseRuleHeader."Currency Code");

        if Expense."Expense Detail Required" = Expense."Expense Detail Required"::"Per Diem" then
            UpdatePerDiemRange(Expense, ExpenseRuleHeader, DT2Date(Expense."Starting Date and Time"), DT2Date(Expense."Ending Date and Time"));

        Expense.UpdateAmount();
    end;

    local procedure ApplyDefaultExpenseCalculations(var Expense: Record Expense)
    var
        ExpenseCurrency: Record Currency;
    begin
        if Expense."Expense Detail Required" = Expense."Expense Detail Required"::Mileage then begin
            if Expense."Currency Code" = '' then
                ExpenseCurrency.InitRoundingPrecision()
            else
                ExpenseCurrency.Get(Expense."Currency Code");

            Expense.Validate(Amount, Round(GetEffectiveDistance(Expense.Mileage, Expense."Round Trip") * GetStandardRateOfMileage(Expense."Expense Date", Expense."Currency Code", Expense."Currency Factor", ExpenseAgentSetup."Standard Rate of Mileage"), ExpenseCurrency."Amount Rounding Precision"));
            if Expense."Unit of Measure Code" = '' then
                Expense.Validate("Unit of Measure Code", ExpenseAgentSetup."Default Mileage UOM");
        end;

        if Expense."Expense Detail Required" = Expense."Expense Detail Required"::Itemize then
            UpdateItemizationInformationOnExpense(Expense);

        Expense.UpdateAmount();
    end;

    local procedure UpdateItemizationInformationOnExpense(var Expense: Record Expense)
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        ExpenseItemization.SetRange(Refundable, false);
        ExpenseItemization.CalcSums(Amount);

        Expense."Non-Refundable Amount" := ExpenseItemization.Amount;
    end;

    local procedure UpdateItemizationInformationOnExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineItemization: Record "Expense Report Line Item";
    begin
        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineItemization.SetRange(Refundable, false);
        ExpenseReportLineItemization.CalcSums(Amount);

        ExpenseReportLine."Non-Refundable Amount" := ExpenseReportLineItemization.Amount;
    end;

    local procedure UpdateFromRuleForReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseRuleHeader: Record "Expense Rule Header")
    begin
        ExpenseReportLine."Applied Rule Id" := ExpenseRuleHeader.SystemId;

        if ExpenseReportLine."Expense Detail Required" = ExpenseReportLine."Expense Detail Required"::"Per Diem" then
            ExpenseReportLine.Validate("Expense Currency Code", ExpenseRuleHeader."Currency Code");

        if ExpenseReportLine."Expense Detail Required" = ExpenseReportLine."Expense Detail Required"::"Per Diem" then
            UpdatePerDiemRangeForReportLine(ExpenseReportLine, ExpenseRuleHeader, DT2Date(ExpenseReportLine."Starting Date and Time"), DT2Date(ExpenseReportLine."Ending Date and Time"));

        ExpenseReportLine.UpdateAmounts();
    end;

    local procedure ApplyDefaultExpenseReportCalculations(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCurrency: Record Currency;
    begin
        if IsMileageRule(ExpenseReportLine."Expense Detail Required") then begin
            if ExpenseReportLine."Expense Currency Code" = '' then
                ExpenseCurrency.InitRoundingPrecision()
            else
                ExpenseCurrency.Get(ExpenseReportLine."Expense Currency Code");

            ExpenseReportLine.Validate(Amount, Round(GetEffectiveDistance(ExpenseReportLine.Mileage, ExpenseReportLine."Round Trip") * GetStandardRateOfMileage(ExpenseReportLine."Expense Date", ExpenseReportLine."Expense Currency Code", ExpenseReportLine."Expense Currency Factor", ExpenseAgentSetup."Standard Rate of Mileage"), ExpenseCurrency."Amount Rounding Precision"));
            if ExpenseReportLine."Unit of Measure Code" = '' then
                ExpenseReportLine.Validate("Unit of Measure Code", ExpenseAgentSetup."Default Mileage UOM");
        end;

        if ExpenseReportLine."Expense Detail Required" = ExpenseReportLine."Expense Detail Required"::Itemize then
            UpdateItemizationInformationOnExpenseReportLine(ExpenseReportLine);

        ExpenseReportLine.UpdateAmounts();
    end;

    local procedure IsMileageRule(ExpenseDetailRequired: Enum "Expense Detail Needed"): Boolean
    begin
        exit(ExpenseDetailRequired = ExpenseDetailRequired::Mileage);
    end;

    procedure GetEffectiveDistance(Mileage: Decimal; RoundTrip: Boolean): Decimal
    begin
        if RoundTrip then
            exit(Mileage * 2);

        exit(Mileage);
    end;

    procedure GetStandardRateOfMileage(ExpenseDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal; StandardRateOfMileage: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpenseCurrency: Record Currency;
    begin
        if CurrencyCode = '' then
            exit(StandardRateOfMileage);

        if CurrencyCode = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(CurrencyCode);

        exit(Round(CurrencyExchangeRate.ExchangeAmtLCYToFCY(ExpenseDate, CurrencyCode, StandardRateOfMileage, CurrencyFactor), ExpenseCurrency."Unit-Amount Rounding Precision"));
    end;
}