// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Reports;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.GeneralLedger.Account;

page 1100 "Chart of Cost Types"
{
    AdditionalSearchTerms = 'cost accounting allocation types';
    ApplicationArea = CostAccounting;
    Caption = 'Chart of Cost Types';
    CardPageID = "Cost Type Card";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Cost Type";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control24)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the cost type.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the type of the cost type.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';
                }
                field("Cost Classification"; Rec."Cost Classification")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost type by variability.';
                }
                field("G/L Account Range"; Rec."G/L Account Range")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a general ledger account range to establish which general ledger account a cost type belongs to.';
                }
                field("Net Change"; Rec."Net Change")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                }
                field("Cost Center Code"; Rec."Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; Rec."Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Combine Entries"; Rec."Combine Entries")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the option to allow for general ledger entries to be posted individually or as a combined posting per day or month.';
                }
                field("Budget Amount"; Rec."Budget Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies either the cost type''s total budget or, if you have specified a filter in the Budget Filter field, a filtered budget. The contents of the field are calculated by using the entries in the Amount field in the Cost Budget Entry table.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = CostAccounting;
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the balance of the cost type.';
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if you want a new page to start immediately after this cost center when you print the chart of cash flow accounts.';
                }
                field("Blank Line"; Rec."Blank Line")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether you want a blank line to appear immediately after this cost center when you print the chart of cost centers. The New Page, Blank Line, and Indentation fields define the layout of the chart of cost centers.';
                }
                field("Balance to Allocate"; Rec."Balance to Allocate")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the net amount that can still be allocated. The entry in the Allocated field in the Cost Entry table determines whether a cost entry is a part of this field.';
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = CostAccounting;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost type balance on the last date that is included in the Date Filter field. The contents of the field are calculated by using the entries in the Amount field in the Cost Entry table.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cost Type")
            {
                Caption = '&Cost Type';
                Image = Costs;
                action("Cost E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost E&ntries';
                    Image = CostEntries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Type No." = field("No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View cost entries, which can come from sources such as automatic transfer of general ledger entries to cost entries, manual posting for pure cost entries, internal charges, and manual allocations, and automatic allocation postings for actual costs.';
                }
                action(CorrespondingGLAccounts)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Corresponding &G/L Accounts';
                    Image = CompareCosttoCOA;
                    ToolTip = 'View the G/L account for the selected line.';

                    trigger OnAction()
                    var
                        GLAccount: Record "G/L Account";
                    begin
                        if Rec."G/L Account Range" <> '' then
                            GLAccount.SetFilter("No.", Rec."G/L Account Range")
                        else
                            GLAccount.SetRange("No.", '');
                        OnCorrespondingGLAccountsActionOnAfterGLAccountSetFilter(Rec, GLAccount);
                        if PAGE.RunModal(PAGE::"Chart of Accounts", GLAccount) = ACTION::OK then;
                    end;
                }
                separator(Action6)
                {
                }
                action("&Balance")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Balance';
                    Image = Balance;
                    RunObject = Page "Cost Type Balance";
                    RunPageOnRec = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View a summary of the balance at date or the net change for different time periods for the cost types that you select. You can select different time intervals and set filters on the cost centers and cost objects that you want to see.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(IndentCostType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'I&ndent Cost Types';
                    Image = IndentChartOfAccounts;
                    ToolTip = 'Indent the selected lines.';

                    trigger OnAction()
                    begin
                        CostAccMgt.ConfirmIndentCostTypes();
                    end;
                }
                action(GetCostTypesFromChartOfAccounts)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Get Cost Types from &Chart of Accounts';
                    Image = CopyFromChartOfAccounts;
                    ToolTip = 'Transfer all income statement accounts from the chart of accounts to the chart of cost types.';

                    trigger OnAction()
                    begin
                        CostAccMgt.GetCostTypesFromChartOfAccount();
                    end;
                }
                action(RegCostTypeInChartOfCostType)
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Register Cost Types in Chart of Accounts';
                    Image = LinkAccount;
                    ToolTip = 'Update the relationship between the chart of accounts and the chart of cost types. The function runs automatically before transferring general ledger entries to cost accounting.';

                    trigger OnAction()
                    begin
                        CostAccMgt.LinkCostTypesToGLAccountsYN();
                    end;
                }
            }
            action("Cost Registers")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Registers';
                Image = GLRegisters;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Cost Registers";
                ToolTip = 'View all the transferred, posted, and allocated entries. A register is created every time that an entry is transferred, posted, or allocated.';
            }
            action("G/L Account")
            {
                ApplicationArea = CostAccounting;
                Caption = 'G/L Account';
                Image = ChartOfAccounts;
                RunObject = Page "Chart of Accounts";
                ToolTip = 'View the G/L account for the selected line.';
            }
        }
        area(reporting)
        {
            action("Cost Acctg. P/L Statement")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. P/L Statement';
                Image = "Report";
                RunObject = Report "Cost Acctg. Statement";
                ToolTip = 'View the cost accounting P/L statement.';
            }
            action("Cost Acctg. P/L Statement per Period")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. P/L Statement per Period';
                Image = "Report";
                RunObject = Report "Cost Acctg. Stmt. per Period";
                ToolTip = 'View profit and loss for cost types over two periods with the comparison as a percentage.';
            }
            action("Cost Acctg. P/L Statement with Budget")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. P/L Statement with Budget';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Cost Acctg. Statement/Budget";
                ToolTip = 'View a comparison of the balance to the budget figures and calculates the variance and the percent variance in the current accounting period, the accumulated accounting period, and the fiscal year.';
            }
            action("Cost Acctg. Analysis")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Acctg. Analysis';
                Image = "Report";
                RunObject = Report "Cost Acctg. Analysis";
                ToolTip = 'View balances per cost type with columns for seven fields for cost centers and cost objects. It is used as the cost distribution sheet in Cost accounting. The structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
            }
            action("Account Details")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Account Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Cost Types Details";
                ToolTip = 'View cost entries for each cost type. You can review the transactions for each cost type.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GetCostTypesFromChartOfAccounts_Promoted; GetCostTypesFromChartOfAccounts)
                {
                }
                actionref(IndentCostType_Promoted; IndentCostType)
                {
                }
                actionref(RegCostTypeInChartOfCostType_Promoted; RegCostTypeInChartOfCostType)
                {
                }
                actionref("G/L Account_Promoted"; "G/L Account")
                {
                }
                group(Category_Report)
                {
                    Caption = 'Reports';

                    actionref("Cost Acctg. P/L Statement_Promoted"; "Cost Acctg. P/L Statement")
                    {
                    }
                    actionref("Cost Acctg. P/L Statement per Period_Promoted"; "Cost Acctg. P/L Statement per Period")
                    {
                    }
                    actionref("Cost Acctg. Analysis_Promoted"; "Cost Acctg. Analysis")
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetEmphasis();
        SetIndent();
    end;

    var
        CostAccMgt: Codeunit "Cost Account Mgt";
        Emphasize: Boolean;
        NameIndent: Integer;

    local procedure SetEmphasis()
    begin
        Emphasize := Rec.Type <> Rec.Type::"Cost Type";
    end;

    local procedure SetIndent()
    begin
        NameIndent := Rec.Indentation;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrespondingGLAccountsActionOnAfterGLAccountSetFilter(var CostType: Record "Cost Type"; var GLAccount: Record "G/L Account")
    begin
    end;
}

