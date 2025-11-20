// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Period;
using System.Text;
using System.Utilities;

page 422 "G/L Balance/Budget"
{
    Caption = 'G/L Balance/Budget';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "G/L Account";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ClosingEntryFilter; ClosingEntryFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Closing Entries';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the balance shown will include closing entries. If you want to see the amounts on income statement accounts in closed years, you must exclude closing entries.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        ClosingEntryFilterOnAfterValid();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        OnBeforeValidatePeriodType(PeriodType);

                        if PeriodType = PeriodType::"Accounting Period" then
                            AccountingPerioPeriodTypeOnVal();
                        if PeriodType = PeriodType::Year then
                            YearPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Quarter then
                            QuarterPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Month then
                            MonthPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Week then
                            WeekPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Day then
                            DayPeriodTypeOnValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid();
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                        DateFilter2: Text;
                    begin
                        if DateFilter = '' then
                            Rec.SetRange("Date Filter")
                        else begin
                            DateFilter2 := DateFilter;
                            FilterTokens.MakeDateFilter(DateFilter2);
                            DateFilter := CopyStr(DateFilter2, 1, MaxStrLen(DateFilter));
                            Rec.SetFilter("Date Filter", DateFilter);
                        end;

                        CurrPage.Update();
                    end;
                }
                field(GLAccFilter; GLAccFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Filter';
                    ToolTip = 'Specifies the G/L accounts for which you will see information in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GLAccList: Page "G/L Account List";
                    begin
                        GLAccList.LookupMode(true);
                        if not (GLAccList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := GLAccList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if GLAccFilter = '' then
                            Rec.SetRange("No.")
                        else
                            Rec.SetFilter("No.", GLAccFilter);
                        CurrPage.Update();
                    end;
                }
                field(GLAccCategory; GLAccCategoryFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Category Filter';
                    ToolTip = 'Specifies the category of the G/L account for which you will see information in the window.';

                    trigger OnValidate()
                    begin
                        if GLAccCategoryFilter = GLAccCategoryFilter::" " then
                            Rec.SetRange("Account Category")
                        else
                            Rec.SetRange("Account Category", GLAccCategoryFilter);
                        CurrPage.Update();
                    end;
                }
                field(IncomeBalGLAccFilter; IncomeBalanceGLAccFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Income/Balance G/L Account Filter';
                    OptionCaption = ' ,Income Statement,Balance Sheet';
                    ToolTip = 'Specifies the type of the G/L account for which you will see information in the window.';

                    trigger OnValidate()
                    begin
                        case IncomeBalanceGLAccFilter of
                            IncomeBalanceGLAccFilter::" ":
                                Rec.SetRange("Income/Balance");
                            IncomeBalanceGLAccFilter::"Balance Sheet":
                                Rec.SetRange("Income/Balance", Rec."Income/Balance"::"Balance Sheet");
                            IncomeBalanceGLAccFilter::"Income Statement":
                                Rec.SetRange("Income/Balance", Rec."Income/Balance"::"Income Statement");
                        end;
                        IncomeBalanceVisible := Rec.GetFilter("Income/Balance") = '';
                        CurrPage.Update();
                    end;
                }
                field(GlobalDim1Filter; GlobalDim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,1';
                    Caption = 'Global Dimension 1 Filter';
                    Enabled = GlobalDim1FilterEnable;
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if GlobalDim1Filter = '' then
                            Rec.SetRange("Global Dimension 1 Filter")
                        else
                            Rec.SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
                        CurrPage.Update();
                    end;
                }
                field(GlobalDim2Filter; GlobalDim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,3,2';
                    Caption = 'Global Dimension 2 Filter';
                    Enabled = GlobalDim2FilterEnable;
                    ToolTip = 'Specifies by which global dimension data is shown. Global dimensions are the dimensions that you analyze most frequently. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        if GlobalDim2Filter = '' then
                            Rec.SetRange("Global Dimension 2 Filter")
                        else
                            Rec.SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);
                        CurrPage.Update();
                    end;
                }
            }
            repeater(Control5)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the general ledger account.';
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                    Visible = IncomeBalanceVisible;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Suite;
                    BlankNumbers = BlankNegAndZero;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Suite;
                    BlankNumbers = BlankNegAndZero;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                }
                field("Net Change"; Rec."Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                    Visible = false;
                }
                field("Budgeted Debit Amount"; Rec."Budgeted Debit Amount")
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the Budgeted Debit Amount for the account.';

                    trigger OnValidate()
                    begin
                        CalcFormFields();
                        BudgetedDebitAmountOnAfterVali();
                    end;
                }
                field("Budgeted Credit Amount"; Rec."Budgeted Credit Amount")
                {
                    ApplicationArea = Suite;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the Budgeted Credit Amount for the account.';

                    trigger OnValidate()
                    begin
                        CalcFormFields();
                        BudgetedCreditAmountOnAfterVal();
                    end;
                }
                field("Budgeted Amount"; Rec."Budgeted Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies either the G/L account''s total budget or, if you have specified a name in the Budget Name field, a specific budget.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CalcFormFields();
                        BudgetedAmountOnAfterValidate();
                    end;
                }
                field(BudgetPct; BudgetPct)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Balance/Budget (%)';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies a summary of the debit and credit balances and the budgeted amounts for different time periods for the account that you select in the chart of accounts.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Budget Filter" = field("Budget Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the G/L account card for the selected record.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("No.");
                    RunPageView = sorting("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(15),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View additional information that has been added to the description for the current account.';
                }
            }
        }
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Copy Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Budget';
                    Ellipsis = true;
                    Image = CopyBudget;
                    RunObject = Report "Copy G/L Budget";
                    ToolTip = 'Create a copy of the current budget.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        CalcFormFields();
        FormatLine();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewGLAcc(xRec, BelowxRec);
    end;

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenPage(Rec, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        InitDefaultFilters();
        CODEUNIT.Run(CODEUNIT::"GLBudget-Open", Rec);
        FindPeriod('');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAccCategoryFilter: Enum "G/L Account Category";
        IncomeBalanceGLAccFilter: Option " ","Income Statement","Balance Sheet";
        BudgetPct: Decimal;
        Emphasize: Boolean;
        IncomeBalanceVisible: Boolean;
        GlobalDim1FilterEnable: Boolean;
        GlobalDim2FilterEnable: Boolean;
        NameIndent: Integer;
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;
        GLAccFilter: Text;

    protected var
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        ClosingEntryFilter: Option Include,Exclude;
        DateFilter: Text;

    procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        AccountingPeriod: Record "Accounting Period";
        PeriodPageMgt: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageMgt.FindDate('+', Calendar, PeriodType) then
                PeriodPageMgt.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageMgt.FindDate(SearchText, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then
            if Calendar."Period Start" = Calendar."Period End" then
                Rec.SetRange("Date Filter", Calendar."Period Start")
            else
                Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End")
        else
            Rec.SetRange("Date Filter", 0D, Calendar."Period End");
        if ClosingEntryFilter = ClosingEntryFilter::Exclude then begin
            AccountingPeriod.SetCurrentKey("New Fiscal Year");
            AccountingPeriod.SetRange("New Fiscal Year", true);
            if Rec.GetRangeMin("Date Filter") = 0D then
                AccountingPeriod.SetRange("Starting Date", 0D, Rec.GetRangeMax("Date Filter"))
            else
                AccountingPeriod.SetRange(
                  "Starting Date",
                  Rec.GetRangeMin("Date Filter") + 1,
                  Rec.GetRangeMax("Date Filter"));
            if AccountingPeriod.Find('-') then
                repeat
                    Rec.SetFilter(
                      "Date Filter", Rec.GetFilter("Date Filter") + '&<>%1',
                      ClosingDate(AccountingPeriod."Starting Date" - 1));
                until AccountingPeriod.Next() = 0;
        end else
            Rec.SetRange(
              "Date Filter",
              Rec.GetRangeMin("Date Filter"),
              ClosingDate(Rec.GetRangeMax("Date Filter")));
        DateFilter := Rec.GetFilter("Date Filter");
    end;

    local procedure CalcFormFields()
    begin
        Rec.CalcFields("Net Change", "Budgeted Amount");
        if Rec."Net Change" >= 0 then begin
            Rec."Debit Amount" := Rec."Net Change";
            Rec."Credit Amount" := 0;
        end else begin
            Rec."Debit Amount" := 0;
            Rec."Credit Amount" := -Rec."Net Change";
        end;
        if Rec."Budgeted Amount" >= 0 then begin
            Rec."Budgeted Debit Amount" := Rec."Budgeted Amount";
            Rec."Budgeted Credit Amount" := 0;
        end else begin
            Rec."Budgeted Debit Amount" := 0;
            Rec."Budgeted Credit Amount" := -Rec."Budgeted Amount";
        end;
        if Rec."Budgeted Amount" = 0 then
            BudgetPct := 0
        else
            BudgetPct := Rec."Net Change" / Rec."Budgeted Amount" * 100;
    end;

    local procedure BudgetedDebitAmountOnAfterVali()
    begin
        CurrPage.Update();
    end;

    local procedure BudgetedCreditAmountOnAfterVal()
    begin
        CurrPage.Update();
    end;

    local procedure BudgetedAmountOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure DayPeriodTypeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure WeekPeriodTypeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure MonthPeriodTypeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure QuarterPeriodTypeOnAfterValida()
    begin
        CurrPage.Update();
    end;

    local procedure YearPeriodTypeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure AccountingPerioPeriodTypeOnAft()
    begin
        CurrPage.Update();
    end;

    local procedure ClosingEntryFilterOnAfterValid()
    begin
        CurrPage.Update();
    end;

    local procedure NetChangeAmountTypeOnAfterVali()
    begin
        CurrPage.Update();
    end;

    local procedure BalanceatDateAmountTypeOnAfter()
    begin
        CurrPage.Update();
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure AccountingPerioPeriodTypOnPush()
    begin
        FindPeriod('');
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure FormatLine()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush();
        DayPeriodTypeOnAfterValidate();
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush();
        WeekPeriodTypeOnAfterValidate();
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush();
        MonthPeriodTypeOnAfterValidate();
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush();
        QuarterPeriodTypeOnAfterValida();
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush();
        YearPeriodTypeOnAfterValidate();
    end;

    local procedure AccountingPerioPeriodTypeOnVal()
    begin
        AccountingPerioPeriodTypOnPush();
        AccountingPerioPeriodTypeOnAft();
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush();
        NetChangeAmountTypeOnAfterVali();
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush();
        BalanceatDateAmountTypeOnAfter();
    end;

    local procedure InitDefaultFilters()
    var
        TempGLAccount: Record "G/L Account" temporary;
        GLBudgetOpen: Codeunit "GLBudget-Open";
    begin
        GLBudgetOpen.SetupFiltersOnGLAccBudgetPage(
          GlobalDim1Filter, GlobalDim2Filter, GlobalDim1FilterEnable, GlobalDim2FilterEnable,
          PeriodType, DateFilter, Rec);
        IncomeBalanceVisible := Rec.GetFilter("Income/Balance") = '';
        GLAccFilter := Rec.GetFilter("No.");

        if Evaluate(TempGLAccount."Account Category", Rec.GetFilter("Account Category")) then
            GLAccCategoryFilter := TempGLAccount."Account Category"
        else
            GLAccCategoryFilter := GLAccCategoryFilter::" ";

        if Evaluate(TempGLAccount."Income/Balance", Rec.GetFilter("Income/Balance")) then
            case TempGLAccount."Income/Balance" of
                TempGLAccount."Income/Balance"::"Income Statement":
                    IncomeBalanceGLAccFilter := IncomeBalanceGLAccFilter::"Income Statement";
                TempGLAccount."Income/Balance"::"Balance Sheet":
                    IncomeBalanceGLAccFilter := IncomeBalanceGLAccFilter::"Balance Sheet";
            end
        else
            IncomeBalanceGLAccFilter := IncomeBalanceGLAccFilter::" ";

        OnAfterInitDefaultFilters(GlobalDim1Filter, GlobalDim2Filter, DateFilter);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePeriodType(var PeriodType: Enum "Analysis Period Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPage(var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitDefaultFilters(var GlobalDim1Filter: Text; var GlobalDim2Filter: Text; var DateFilter: Text)
    begin
    end;
}

