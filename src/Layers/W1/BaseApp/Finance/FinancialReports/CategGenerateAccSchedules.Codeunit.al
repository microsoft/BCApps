// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

codeunit 571 "Categ. Generate Acc. Schedules"
{

    trigger OnRun()
    begin
        CreateBalanceSheet();
        CreateIncomeStatement();
        CreateCashFlowStatement();
        CreateRetainedEarningsStatement();
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";

        TotalingTxt: Label 'Total %1', Comment = '%1 = Account category, e.g. Assets';
        Totaling2Txt: Label 'Total %1 & %2', Comment = '%1 and %2 = Account category, e.g. Assets';
        GrossProfitTxt: Label 'Gross Profit';
        NetIncomeTxt: Label 'Net Income';
        AdjustmentsTxt: Label 'Adjustments to reconcile Net Income to net cash provided by operations:';
        NetCashProviededTxt: Label 'Net Cash Provided by %1', Comment = '%1=Operating Activities or Investing Activities';
        NetCashIncreaseTxt: Label 'Net Cash Increase for the Period';
        CashAtPeriodStartTxt: Label 'Cash at Beginning of the Period';
        CashAtPeriodEndTxt: Label 'Cash at End of the Period';
        DistribToShareholdersTxt: Label 'Distributions to Shareholders';
        RetainedEarningsPrimoTxt: Label 'Retained Earnings, Period Start';
        RetainedEarningsUltimoTxt: Label 'Retained Earnings, Period End';

    [Scope('OnPrem')]
    procedure CreateBalanceSheet()
    var
        FinancialReport: Record "Financial Report";
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        RowNo: Integer;
        LiabilitiesRowNo: Code[10];
        EquityRowNo: Code[10];
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GeneralLedgerSetup.TestField("Fin. Rep. for Balance Sheet");
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        AccScheduleName.Get(FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.DeleteAll();
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;

        AddAccSchedLineGroup(AccScheduleLine, RowNo, GLAccountCategory."Account Category"::Assets);
        AddBlankLine(AccScheduleLine, RowNo);
        AddAccSchedLineGroup(AccScheduleLine, RowNo, GLAccountCategory."Account Category"::Liabilities);
        LiabilitiesRowNo := AccScheduleLine."Row No.";
        AddBlankLine(AccScheduleLine, RowNo);
        AddAccSchedLineGroup(AccScheduleLine, RowNo, GLAccountCategory."Account Category"::Equity);
        EquityRowNo := AccScheduleLine."Row No.";
        AddBlankLine(AccScheduleLine, RowNo);
        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
          StrSubstNo(Totaling2Txt, GLAccountCategory."Account Category"::Liabilities, GLAccountCategory."Account Category"::Equity),
          StrSubstNo('%1+%2', LiabilitiesRowNo, EquityRowNo),
          true, true, true, 0);

        OnAfterCreateBalanceSheet(AccScheduleName, LiabilitiesRowNo, EquityRowNo);
    end;

    [Scope('OnPrem')]
    procedure CreateIncomeStatement()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        RowNo: Integer;
        TurnoverRownNo: Integer;
        COGSRowNo: Integer;
        GrossProfitRowNo: Integer;
        ExpensesRowNo: Integer;
        IsHandled: Boolean;
        COGSPrefix: Boolean;
        GrossProfitPrefix: Boolean;
        ExpensesPrefix: Boolean;
        TurnoverPrefix: Boolean;
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GeneralLedgerSetup.TestField("Fin. Rep. for Income Stmt.");
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Income Stmt.");
        AccScheduleName.Get(FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.DeleteAll();
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;

        AddAccSchedLineGroup(AccScheduleLine, RowNo, GLAccountCategory."Account Category"::Income);
        TurnoverRownNo := RowNo;
        TurnoverPrefix := AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Formula;
        AddBlankLine(AccScheduleLine, RowNo);
        AddAccSchedLineGroup(AccScheduleLine, RowNo, GLAccountCategory."Account Category"::"Cost of Goods Sold");
        COGSRowNo := RowNo;
        COGSPrefix := AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Formula;

        OnCreateIncomeStatementOnAfterCreateCOGSGroup(AccScheduleLine, IsHandled);
        if IsHandled then
            exit;

        AddBlankLine(AccScheduleLine, RowNo);
        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula, GrossProfitTxt,
          StrSubstNo('%1+%2', FormatRowNo(TurnoverRownNo, TurnoverPrefix), FormatRowNo(COGSRowNo, COGSPrefix)),
          true, false, true, 0);
        GrossProfitRowNo := RowNo;
        GrossProfitPrefix := AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Formula;
        AddBlankLine(AccScheduleLine, RowNo);
        AddAccSchedLineGroup(AccScheduleLine, RowNo, GLAccountCategory."Account Category"::Expense);
        ExpensesRowNo := RowNo;
        ExpensesPrefix := AccScheduleLine."Totaling Type" = AccScheduleLine."Totaling Type"::Formula;
        AddBlankLine(AccScheduleLine, RowNo);
        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula, NetIncomeTxt,
          StrSubstNo('%1+%2', FormatRowNo(GrossProfitRowNo, GrossProfitPrefix), FormatRowNo(ExpensesRowNo, ExpensesPrefix)),
          true, true, true, 0);
    end;

    [Scope('OnPrem')]
    procedure CreateCashFlowStatement()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        PartStartRowNo: Integer;
        RowNo: Integer;
        OperatingActRowNo: Code[10];
        InvestingActRowNo: Code[10];
        FinancingActRowNo: Code[10];
        NetCashIncreaseRowNo: Code[10];
        CashBeginningRowNo: Code[10];
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GeneralLedgerSetup.TestField("Fin. Rep. for Cash Flow Stmt");
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt");
        AccScheduleName.Get(FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.DeleteAll();
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          Format(GLAccountCategory."Additional Report Definition"::"Operating Activities"), '', true, false, true, 0);
        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          NetIncomeTxt, GetIncomeStmtAccFilter(), false, false, true, 0);
        PartStartRowNo := RowNo;
        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          AdjustmentsTxt, '', false, false, false, 0);

        CreateCashFlowActivityPart(AccScheduleLine, RowNo, GLAccountCategory."Additional Report Definition"::"Operating Activities", false);
        AccScheduleLine.Totaling := StrSubstNo('%1+%2', FormatRowNo(PartStartRowNo, false), AccScheduleLine.Totaling);
        AccScheduleLine.Modify();
        OperatingActRowNo := AccScheduleLine."Row No.";

        AddBlankLine(AccScheduleLine, RowNo);

        CreateCashFlowActivityPart(AccScheduleLine, RowNo, GLAccountCategory."Additional Report Definition"::"Investing Activities", true);
        InvestingActRowNo := AccScheduleLine."Row No.";

        AddBlankLine(AccScheduleLine, RowNo);

        CreateCashFlowActivityPart(AccScheduleLine, RowNo, GLAccountCategory."Additional Report Definition"::"Financing Activities", true);
        FinancingActRowNo := AccScheduleLine."Row No.";

        AddBlankLine(AccScheduleLine, RowNo);

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
          NetCashIncreaseTxt,
          StrSubstNo('%1+%2+%3', OperatingActRowNo, InvestingActRowNo, FinancingActRowNo),
          false, false, true, 0);
        NetCashIncreaseRowNo := AccScheduleLine."Row No.";

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          CashAtPeriodStartTxt,
          GetAccFilterForReportingDefinition(GLAccountCategory."Additional Report Definition"::"Cash Accounts"),
          false, true, false, 0);
        AccScheduleLine."Row Type" := AccScheduleLine."Row Type"::"Beginning Balance";
        AccScheduleLine.Modify();
        CashBeginningRowNo := AccScheduleLine."Row No.";

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
          CashAtPeriodEndTxt,
          StrSubstNo('-%1+%2', NetCashIncreaseRowNo, CashBeginningRowNo),
          true, true, false, 0);
    end;

    local procedure CreateCashFlowActivityPart(var AccScheduleLine: Record "Acc. Schedule Line"; var RowNo: Integer; AddReportDef: Option; IncludeHeader: Boolean)
    var
        GLAccountCategory: Record "G/L Account Category";
        FirstRangeRowNo: Integer;
    begin
        GLAccountCategory."Additional Report Definition" := AddReportDef;
        if IncludeHeader then
            AddAccShedLine(
              AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
              Format(GLAccountCategory."Additional Report Definition"), '', true, false, false, 0);

        FirstRangeRowNo := RowNo;
        if AddReportDef = GLAccountCategory."Additional Report Definition"::"Financing Activities" then
            GLAccountCategory.SetFilter(
              "Additional Report Definition", '%1|%2',
              GLAccountCategory."Additional Report Definition"::"Financing Activities",
              GLAccountCategory."Additional Report Definition"::"Distribution to Shareholders")
        else
            GLAccountCategory.SetRange("Additional Report Definition", AddReportDef);
        if GLAccountCategory.FindSet() then begin
            repeat
                AddAccShedLine(
                  AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
                  GLAccountCategory.Description, GLAccountCategory.GetTotaling(), false, false, false, 1);
            until GLAccountCategory.Next() = 0;
            // Last line in group should be underlined
            AccScheduleLine.Underline := true;
            AccScheduleLine.Modify();

            AddAccShedLine(
              AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
              StrSubstNo(NetCashProviededTxt, GLAccountCategory."Additional Report Definition"),
              StrSubstNo('%1..%2', FormatRowNo(FirstRangeRowNo, false), FormatRowNo(RowNo, false)),
              true, false, false, 0);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateRetainedEarningsStatement()
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReport: Record "Financial Report";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        RowNo: Integer;
        RetainedEarningsPrimoRowNo: Code[10];
        GrossRetainedEarningsRowNo: Code[10];
        DistributionRowNo: Code[10];
    begin
        GLAccountCategoryMgt.GetGLSetup(GeneralLedgerSetup);
        GeneralLedgerSetup.TestField("Fin. Rep. for Retained Earn.");
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Retained Earn.");
        AccScheduleName.Get(FinancialReport."Financial Report Row Group");
        AccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
        AccScheduleLine.DeleteAll();
        AccScheduleLine."Schedule Name" := AccScheduleName.Name;

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          RetainedEarningsPrimoTxt,
          GetAccFilterForReportingDefinition(GLAccountCategory."Additional Report Definition"::"Retained Earnings"),
          false, false, true, 0);
        AccScheduleLine."Row Type" := AccScheduleLine."Row Type"::"Beginning Balance";
        AccScheduleLine.Modify();
        RetainedEarningsPrimoRowNo := AccScheduleLine."Row No.";

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          NetIncomeTxt, GetIncomeStmtAccFilter(), false, true, true, 0);

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
          '',
          StrSubstNo('%1+%2', RetainedEarningsPrimoRowNo, AccScheduleLine."Row No."),
          false, false, true, 0);
        GrossRetainedEarningsRowNo := AccScheduleLine."Row No.";

        AddBlankLine(AccScheduleLine, RowNo);

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          DistribToShareholdersTxt,
          GetAccFilterForReportingDefinition(GLAccountCategory."Additional Report Definition"::"Distribution to Shareholders"),
          false, false, false, 0);
        DistributionRowNo := AccScheduleLine."Row No.";

        AddBlankLine(AccScheduleLine, RowNo);
        AccScheduleLine.Underline := true;
        AccScheduleLine.Modify();

        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
          RetainedEarningsUltimoTxt,
          StrSubstNo('%1-%2', GrossRetainedEarningsRowNo, DistributionRowNo),
          true, true, true, 0);
        AccScheduleLine."Row Type" := AccScheduleLine."Row Type"::"Balance at Date";
        AccScheduleLine.Modify();
    end;

    local procedure AddAccSchedLineGroup(var AccScheduleLine: Record "Acc. Schedule Line"; var RowNo: Integer; Category: Option)
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange(Indentation, 0);
        GLAccountCategory.SetAutoCalcFields("Has Children");
        GLAccountCategory.SetCurrentKey("Presentation Order");
        if GLAccountCategory.FindSet() then
            repeat
                AddAccSchedLinesDetail(AccScheduleLine, RowNo, GLAccountCategory, 0);
            until GLAccountCategory.Next() = 0;
    end;

    local procedure AddAccSchedLinesDetail(var AccScheduleLine: Record "Acc. Schedule Line"; var RowNo: Integer; ParentGLAccountCategory: Record "G/L Account Category"; Indentation: Integer)
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        AccScheduleTotType: Enum "Acc. Schedule Line Totaling Type";
        FromRowNo: Integer;
        TotalingFilter: Text;
    begin
        if ParentGLAccountCategory."Has Children" then begin
            AddAccShedLine(
              AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
              ParentGLAccountCategory.Description, ParentGLAccountCategory.GetTotaling(), true, false,
              not ParentGLAccountCategory.PositiveNormalBalance(), Indentation);
            OnAfterAddParentAccSchedLineTotalingTypePostingAccounts(AccScheduleLine, ParentGLAccountCategory);
            FromRowNo := RowNo;
            GLAccountCategory.SetRange("Parent Entry No.", ParentGLAccountCategory."Entry No.");
            GLAccountCategory.SetCurrentKey("Presentation Order");
            GLAccountCategory.SetAutoCalcFields("Has Children");
            if GLAccountCategory.FindSet() then
                repeat
                    AddAccSchedLinesDetail(AccScheduleLine, RowNo, GLAccountCategory, Indentation + 1);
                until GLAccountCategory.Next() = 0;
            AddAccShedLine(
              AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::Formula,
              StrSubstNo(TotalingTxt, ParentGLAccountCategory.Description),
              StrSubstNo('%1..%2', FormatRowNo(FromRowNo, false), FormatRowNo(RowNo, false)), true, false,
              not ParentGLAccountCategory.PositiveNormalBalance(), Indentation);
            OnAfterAddParentAccSchedLine(AccScheduleLine, ParentGLAccountCategory);
        end else begin
            // Retained Earnings element of Equity must include non-closed income statement.
            TotalingFilter := ParentGLAccountCategory.GetTotaling();
            if ParentGLAccountCategory."Additional Report Definition" =
               ParentGLAccountCategory."Additional Report Definition"::"Retained Earnings"
            then begin
                if TotalingFilter <> '' then
                    TotalingFilter += '|';
                TotalingFilter += GetIncomeStmtAccFilter();
            end;

            AccScheduleTotType := AccScheduleLine."Totaling Type"::"Posting Accounts";
            if (StrPos(TotalingFilter, '..') = 0) and (StrPos(TotalingFilter, '|') = 0) then begin
                GLAccount.SetRange("No.", TotalingFilter);
                GLAccount.SetRange("Account Type", GLAccount."Account Type"::Total);
                if not GLAccount.IsEmpty() then
                    AccScheduleTotType := AccScheduleLine."Totaling Type"::"Total Accounts";
            end;

            AddAccShedLine(
              AccScheduleLine, RowNo, AccScheduleTotType,
              ParentGLAccountCategory.Description, CopyStr(TotalingFilter, 1, 250),
              Indentation = 0, false, not ParentGLAccountCategory.PositiveNormalBalance(), Indentation);
            OnAfterAddAccSchedLine(AccScheduleLine, ParentGLAccountCategory, RowNo);
            AccScheduleLine.Show := AccScheduleLine.Show::"If Any Column Not Zero";
            AccScheduleLine.Modify();
        end;
    end;

    local procedure AddAccShedLine(var AccScheduleLine: Record "Acc. Schedule Line"; var RowNo: Integer; TotalingType: Enum "Acc. Schedule Line Totaling Type"; Description: Text[80]; Totaling: Text[250]; Bold: Boolean; Underline: Boolean; ShowOppositeSign: Boolean; Indentation: Integer)
    begin
        if AccScheduleLine.FindLast() then;
        AccScheduleLine.Init();
        AccScheduleLine."Line No." += 10000;
        RowNo += 1;
        AccScheduleLine."Row No." := FormatRowNo(RowNo, TotalingType = AccScheduleLine."Totaling Type"::Formula);
        AccScheduleLine."Totaling Type" := TotalingType;
        AccScheduleLine.Description := Description;
        AccScheduleLine.Totaling := Totaling;
        AccScheduleLine."Show Opposite Sign" := ShowOppositeSign;
        AccScheduleLine.Bold := Bold;
        AccScheduleLine.Underline := Underline;
        AccScheduleLine.Indentation := Indentation;
        AccScheduleLine.Insert();
    end;

    local procedure FormatRowNo(RowNo: Integer; AddPrefix: Boolean): Text[5]
    var
        Prefix: Text[1];
    begin
        if AddPrefix then
            Prefix := 'F'
        else
            Prefix := 'P';
        exit(Prefix + CopyStr(Format(10000 + RowNo), 2, 4));
    end;

    local procedure AddBlankLine(var AccScheduleLine: Record "Acc. Schedule Line"; var RowNo: Integer)
    begin
        AddAccShedLine(
          AccScheduleLine, RowNo, AccScheduleLine."Totaling Type"::"Posting Accounts",
          '', '', false, false, false, 0);
    end;

    local procedure GetAccFilterForReportingDefinition(AdditionalReportingDefinition: Option): Text[250]
    var
        GLAccountCategory: Record "G/L Account Category";
        Totaling: Text;
        AccFilter: Text;
    begin
        GLAccountCategory.SetRange("Additional Report Definition", AdditionalReportingDefinition);
        if GLAccountCategory.FindSet() then
            repeat
                Totaling := GLAccountCategory.GetTotaling();
                if (AccFilter <> '') and (Totaling <> '') then
                    AccFilter += '|';
                AccFilter += Totaling;
            until GLAccountCategory.Next() = 0;
        exit(CopyStr(AccFilter, 1, 250));
    end;

    local procedure GetIncomeStmtAccFilter(): Text[250]
    var
        GLAccount: Record "G/L Account";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        GLAccount.Reset();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        exit(CopyStr(SelectionFilterManagement.GetSelectionFilterForGLAccount(GLAccount), 1, 250));
    end;

    procedure RunGenerateAccSchedules(var AccSchedUpdateNeededNotification: Notification)
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        GLAccountCategoryMgt.ConfirmAndRunGenerateAccountSchedules();
    end;

    procedure HideAccSchedUpdateNeededNotificationForCurrentUser(var AccSchedUpdateNeededNotification: Notification)
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.DontNotifyCurrentUserAgain(AccSchedUpdateNeededNotification.Id);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddAccSchedLine(var AccScheduleLine: Record "Acc. Schedule Line"; ParentGLAccountCategory: Record "G/L Account Category"; var RowNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddParentAccSchedLine(var AccScheduleLine: Record "Acc. Schedule Line"; ParentGLAccountCategory: Record "G/L Account Category")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateBalanceSheet(AccScheduleName: Record "Acc. Schedule Name"; LiabilitiesRowNo: Code[10]; EquityRowNo: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateIncomeStatementOnAfterCreateCOGSGroup(var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddParentAccSchedLineTotalingTypePostingAccounts(var AccScheduleLine: Record "Acc. Schedule Line"; ParentGLAccountCategory: Record "G/L Account Category")
    begin
    end;
}

