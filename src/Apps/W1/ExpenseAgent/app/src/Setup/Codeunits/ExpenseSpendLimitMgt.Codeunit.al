// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Period;

codeunit 6914 "Expense Spend Limit Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Accounting Period" = R,
                  tabledata Expense = R,
                  tabledata "Expense Spend Limit" = R,
                  tabledata "Expense Report Line" = R,
                  tabledata "Expense User" = R,
                  tabledata "Posted Expense Report Line" = R;

    var
        NoAccountingPeriodErr: Label 'No accounting period is defined for %1.', Comment = '%1 = date';

    internal procedure UpdatePeriodDates(var ExpenseSpendLimit: Record "Expense Spend Limit")
    var
        StartDate: Date;
        EndDate: Date;
    begin
        if ExpenseSpendLimit."Start Date" = 0D then
            exit;

        GetPeriodDates(ExpenseSpendLimit."Period Type", ExpenseSpendLimit."Start Date", StartDate, EndDate);
        ExpenseSpendLimit."Start Date" := StartDate;
        ExpenseSpendLimit."End Date" := EndDate;
    end;

    internal procedure GetExpenseUserSpendLimitInfo(ExpenseUser: Record "Expense User"; var AvailableSpendLimitLCY: Decimal; var CurrentSpendingLCY: Decimal; var AvailableToUseLCY: Decimal; var PaymentMethodCode: Code[10])
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        RemainingLCY: Decimal;
        HasSpendLimit: Boolean;
    begin
        ClearSpendLimitInfo(AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode);

        SelectTightestActiveLimit(Enum::"Exp. Spend Limit Type"::User, ExpenseUser."No.", ExpenseSpendLimit, CurrentSpendingLCY, RemainingLCY, HasSpendLimit);
        if ExpenseUser."Expense Team Code" <> '' then
            SelectTightestActiveLimit(Enum::"Exp. Spend Limit Type"::Team, ExpenseUser."Expense Team Code", ExpenseSpendLimit, CurrentSpendingLCY, RemainingLCY, HasSpendLimit);
        SelectTightestActiveLimit(Enum::"Exp. Spend Limit Type"::Company, '', ExpenseSpendLimit, CurrentSpendingLCY, RemainingLCY, HasSpendLimit);

        if HasSpendLimit then
            SetSpendLimitInfo(ExpenseSpendLimit, CurrentSpendingLCY, AvailableSpendLimitLCY, AvailableToUseLCY, PaymentMethodCode);
    end;

    internal procedure GetExpenseTeamSpendLimitInfo(ExpenseTeam: Record "Expense Team"; var AvailableSpendLimitLCY: Decimal; var CurrentSpendingLCY: Decimal; var AvailableToUseLCY: Decimal; var PaymentMethodCode: Code[10])
    var
        ExpenseSpendLimit: Record "Expense Spend Limit";
        RemainingLCY: Decimal;
        HasSpendLimit: Boolean;
    begin
        ClearSpendLimitInfo(AvailableSpendLimitLCY, CurrentSpendingLCY, AvailableToUseLCY, PaymentMethodCode);

        SelectTightestActiveLimit(Enum::"Exp. Spend Limit Type"::Team, ExpenseTeam.Code, ExpenseSpendLimit, CurrentSpendingLCY, RemainingLCY, HasSpendLimit);
        SelectTightestActiveLimit(Enum::"Exp. Spend Limit Type"::Company, '', ExpenseSpendLimit, CurrentSpendingLCY, RemainingLCY, HasSpendLimit);

        if HasSpendLimit then
            SetSpendLimitInfo(ExpenseSpendLimit, CurrentSpendingLCY, AvailableSpendLimitLCY, AvailableToUseLCY, PaymentMethodCode);
    end;

    local procedure SelectTightestActiveLimit(SpendLimitType: Enum "Exp. Spend Limit Type"; LimitFor: Code[20]; var SelectedSpendLimit: Record "Expense Spend Limit"; var SelectedCurrentSpendingLCY: Decimal; var SelectedRemainingLCY: Decimal; var HasSelectedLimit: Boolean)
    var
        CandidateSpendLimit: Record "Expense Spend Limit";
        CandidateCurrentSpendingLCY: Decimal;
        CandidateRemainingLCY: Decimal;
    begin
        CandidateSpendLimit.SetRange("Spend Limit Type", SpendLimitType);
        CandidateSpendLimit.SetRange("Limit For", LimitFor);
        CandidateSpendLimit.SetFilter("Start Date", '..%1', WorkDate());
        CandidateSpendLimit.SetFilter("End Date", '%1..', WorkDate());
        CandidateSpendLimit.SetCurrentKey("Spend Limit Type", "Limit For", "Start Date", "End Date");
        if not CandidateSpendLimit.FindSet() then
            exit;

        repeat
            CandidateCurrentSpendingLCY := GetCurrentSpendingLCY(CandidateSpendLimit);
            CandidateRemainingLCY := CandidateSpendLimit."Amount (LCY)" - CandidateCurrentSpendingLCY;
            if not HasSelectedLimit or (CandidateRemainingLCY < SelectedRemainingLCY) then begin
                SelectedSpendLimit := CandidateSpendLimit;
                SelectedCurrentSpendingLCY := CandidateCurrentSpendingLCY;
                SelectedRemainingLCY := CandidateRemainingLCY;
                HasSelectedLimit := true;
            end;
        until CandidateSpendLimit.Next() = 0;
    end;

    local procedure GetCurrentSpendingLCY(ExpenseSpendLimit: Record "Expense Spend Limit"): Decimal
    var
        ExpenseUser: Record "Expense User";
        CurrentSpendingLCY: Decimal;
    begin
        case ExpenseSpendLimit."Spend Limit Type" of
            Enum::"Exp. Spend Limit Type"::User:
                exit(GetCurrentSpendingForUser(ExpenseSpendLimit, ExpenseSpendLimit."Limit For"));
            Enum::"Exp. Spend Limit Type"::Team:
                begin
                    ExpenseUser.SetRange("Expense Team Code", ExpenseSpendLimit."Limit For");
                    if ExpenseUser.FindSet() then
                        repeat
                            CurrentSpendingLCY += GetCurrentSpendingForUser(ExpenseSpendLimit, ExpenseUser."No.");
                        until ExpenseUser.Next() = 0;
                end;
            Enum::"Exp. Spend Limit Type"::Company:
                exit(GetCurrentCompanySpending(ExpenseSpendLimit));
        end;

        exit(CurrentSpendingLCY);
    end;

    local procedure GetCurrentSpendingForUser(ExpenseSpendLimit: Record "Expense Spend Limit"; ExpenseUserNo: Code[20]): Decimal
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CurrentSpendingLCY: Decimal;
    begin
        Expense.SetRange("Expense User No.", ExpenseUserNo);
        ApplyExpenseFilters(Expense, ExpenseSpendLimit);
        if not Expense.IsEmpty() then begin
            Expense.CalcSums("Amount (LCY)");
            CurrentSpendingLCY += Expense."Amount (LCY)";
        end;

        ExpenseReportLine.SetRange("Expense User No.", ExpenseUserNo);
        ApplyExpenseReportLineFilters(ExpenseReportLine, ExpenseSpendLimit);
        if not ExpenseReportLine.IsEmpty() then begin
            ExpenseReportLine.CalcSums("Amount (LCY)");
            CurrentSpendingLCY += ExpenseReportLine."Amount (LCY)";
        end;

        PostedExpenseReportLine.SetRange("Expense User No.", ExpenseUserNo);
        ApplyPostedLineFilters(PostedExpenseReportLine, ExpenseSpendLimit);
        if not PostedExpenseReportLine.IsEmpty() then begin
            PostedExpenseReportLine.CalcSums("Amount (LCY)");
            CurrentSpendingLCY += PostedExpenseReportLine."Amount (LCY)";
        end;

        exit(CurrentSpendingLCY);
    end;

    local procedure GetCurrentCompanySpending(ExpenseSpendLimit: Record "Expense Spend Limit"): Decimal
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CurrentSpendingLCY: Decimal;
    begin
        ApplyExpenseFilters(Expense, ExpenseSpendLimit);
        if not Expense.IsEmpty() then begin
            Expense.CalcSums("Amount (LCY)");
            CurrentSpendingLCY += Expense."Amount (LCY)";
        end;

        ApplyExpenseReportLineFilters(ExpenseReportLine, ExpenseSpendLimit);
        if not ExpenseReportLine.IsEmpty() then begin
            ExpenseReportLine.CalcSums("Amount (LCY)");
            CurrentSpendingLCY += ExpenseReportLine."Amount (LCY)";
        end;

        ApplyPostedLineFilters(PostedExpenseReportLine, ExpenseSpendLimit);
        if not PostedExpenseReportLine.IsEmpty() then begin
            PostedExpenseReportLine.CalcSums("Amount (LCY)");
            CurrentSpendingLCY += PostedExpenseReportLine."Amount (LCY)";
        end;

        exit(CurrentSpendingLCY);
    end;

    local procedure ApplyExpenseFilters(var Expense: Record Expense; ExpenseSpendLimit: Record "Expense Spend Limit")
    begin
        Expense.SetRange("Expense Date", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date");
        Expense.SetRange("Expense Report No.", '');
        Expense.SetRange("Posted Expense Report No.", '');
        if ExpenseSpendLimit."Payment Method Code" <> '' then
            Expense.SetRange("Payment Method Code", ExpenseSpendLimit."Payment Method Code");
    end;

    local procedure ApplyExpenseReportLineFilters(var ExpenseReportLine: Record "Expense Report Line"; ExpenseSpendLimit: Record "Expense Spend Limit")
    begin
        ExpenseReportLine.SetRange("Expense Date", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date");
        if ExpenseSpendLimit."Payment Method Code" <> '' then
            ExpenseReportLine.SetRange("Payment Method Code", ExpenseSpendLimit."Payment Method Code");
    end;

    local procedure ApplyPostedLineFilters(var PostedExpenseReportLine: Record "Posted Expense Report Line"; ExpenseSpendLimit: Record "Expense Spend Limit")
    begin
        PostedExpenseReportLine.SetRange("Expense Date", ExpenseSpendLimit."Start Date", ExpenseSpendLimit."End Date");
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        if ExpenseSpendLimit."Payment Method Code" <> '' then
            PostedExpenseReportLine.SetRange("Payment Method Code", ExpenseSpendLimit."Payment Method Code");
    end;

    local procedure SetSpendLimitInfo(ExpenseSpendLimit: Record "Expense Spend Limit"; CurrentSpendingLCY: Decimal; var AvailableSpendLimitLCY: Decimal; var AvailableToUseLCY: Decimal; var PaymentMethodCode: Code[10])
    begin
        AvailableSpendLimitLCY := ExpenseSpendLimit."Amount (LCY)";
        if CurrentSpendingLCY >= AvailableSpendLimitLCY then
            AvailableToUseLCY := 0
        else
            AvailableToUseLCY := AvailableSpendLimitLCY - CurrentSpendingLCY;
        PaymentMethodCode := ExpenseSpendLimit."Payment Method Code";
    end;

    local procedure ClearSpendLimitInfo(var AvailableSpendLimitLCY: Decimal; var CurrentSpendingLCY: Decimal; var AvailableToUseLCY: Decimal; var PaymentMethodCode: Code[10])
    begin
        Clear(AvailableSpendLimitLCY);
        Clear(CurrentSpendingLCY);
        Clear(AvailableToUseLCY);
        Clear(PaymentMethodCode);
    end;

    local procedure GetPeriodDates(PeriodType: Enum "Exp. Spend Limit Period"; ReferenceDate: Date; var StartDate: Date; var EndDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        case PeriodType of
            Enum::"Exp. Spend Limit Period"::Month:
                begin
                    StartDate := CalcDate('<-CM>', ReferenceDate);
                    EndDate := CalcDate('<CM>', ReferenceDate);
                end;
            Enum::"Exp. Spend Limit Period"::Quarter:
                begin
                    StartDate := CalcDate('<-CQ>', ReferenceDate);
                    EndDate := CalcDate('<CQ>', ReferenceDate);
                end;
            Enum::"Exp. Spend Limit Period"::Year:
                begin
                    StartDate := CalcDate('<-CY>', ReferenceDate);
                    EndDate := CalcDate('<CY>', ReferenceDate);
                end;
            Enum::"Exp. Spend Limit Period"::"Accounting Period":
                begin
                    AccountingPeriod.SetFilter("Starting Date", '..%1', ReferenceDate);
                    if not AccountingPeriod.FindLast() then
                        Error(NoAccountingPeriodErr, ReferenceDate);
                    StartDate := AccountingPeriod."Starting Date";

                    AccountingPeriod.Reset();
                    AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
                    if AccountingPeriod.FindFirst() then
                        EndDate := CalcDate('<-1D>', AccountingPeriod."Starting Date")
                    else
                        EndDate := DMY2Date(31, 12, 9999);
                end;
        end;
    end;
}