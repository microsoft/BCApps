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

page 154 "G/L Account Balance/Budget"
{
    Caption = 'G/L Account Balance/Budget';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
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
                        UpdateSubForm();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
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
            }
            part(GLBalanceLines; "G/L Acc. Balance/Budget Lines")
            {
                ApplicationArea = Suite;
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    begin
                        if DateFilter = '' then
                            Rec.SetRange("Date Filter")
                        else
                            Rec.SetFilter("Date Filter", DateFilter);
                        UpdateSubForm();
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
                        UpdateSubForm();
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
                        UpdateSubForm();
                    end;
                }
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
                group("C&reate Budget")
                {
                    Caption = 'C&reate Budget';
                    Image = CreateLedgerBudget;
                    action("Amount by Period")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amount by Period';
                        Ellipsis = true;
                        Image = AmountByPeriod;
                        ToolTip = 'View the balance amounts by the defined periods.';

                        trigger OnAction()
                        begin
                            GLAcc.Copy(Rec);
                            GLAcc.SetRange("No.", Rec."No.");
                            GLAcc.SetRange("Date Filter");
                            REPORT.Run(REPORT::"Budget Amount by Period", true, false, GLAcc);
                        end;
                    }
                    action("From History")
                    {
                        ApplicationArea = Suite;
                        Caption = 'From History';
                        Ellipsis = true;
                        Image = CopyLedgerToBudget;
                        ToolTip = 'View budget amounts based on an existing budget for the period, so that amounts created will not replace the existing amounts, but instead will be added to the existing budget amounts.';

                        trigger OnAction()
                        begin
                            GLAcc.Copy(Rec);
                            GLAcc.SetRange("No.", Rec."No.");
                            GLAcc.SetRange("Date Filter");
                            REPORT.Run(REPORT::"Budget from History", true, false, GLAcc);
                        end;
                    }
                }
            }
        }
        area(Promoted)
        {
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm();
    end;

    trigger OnOpenPage()
    var
        GLBudgetOpen: Codeunit "GLBudget-Open";
    begin
        GLSetup.Get();
        GLBudgetOpen.Run(Rec);
        GLBudgetOpen.SetupFiltersOnGLAccBudgetPage(
          GlobalDim1Filter, GlobalDim2Filter, GlobalDim1FilterEnable, GlobalDim2FilterEnable,
          PeriodType, DateFilter, Rec);
    end;

    var
        GLAcc: Record "G/L Account";
        GLSetup: Record "General Ledger Setup";
        GlobalDim1FilterEnable: Boolean;
        GlobalDim2FilterEnable: Boolean;
        DateFilter: Text;
        GlobalDim1Filter: Text;
        GlobalDim2Filter: Text;

    protected var
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        ClosingEntryFilter: Option Include,Exclude;

    local procedure UpdateSubForm()
    begin
        CurrPage.GLBalanceLines.PAGE.SetLines(Rec, PeriodType, AmountType, ClosingEntryFilter);
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure AccountingPerioPeriodTypOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        UpdateSubForm();
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush();
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush();
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush();
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush();
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush();
    end;

    local procedure AccountingPerioPeriodTypeOnVal()
    begin
        AccountingPerioPeriodTypOnPush();
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush();
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush();
    end;
}

