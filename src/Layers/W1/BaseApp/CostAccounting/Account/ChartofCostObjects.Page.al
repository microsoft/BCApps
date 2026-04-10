// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Reports;
using Microsoft.CostAccounting.Setup;
using System.Text;

page 1123 "Chart of Cost Objects"
{
    AdditionalSearchTerms = 'cost accounting allocation objects';
    ApplicationArea = CostAccounting;
    Caption = 'Chart of Cost Objects';
    CardPageID = "Cost Object Card";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Cost Object";
    SourceTableView = sorting("Sorting Order");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control16)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the code for the cost object.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the cost object.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the purpose of the cost object, such as Cost Object, Heading, or Begin-Total. Newly created cost objects are automatically assigned the Cost Object type, but you can change this.';
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';
                }
                field("Sorting Order"; Rec."Sorting Order")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the sorting order of the cost objects.';
                }
                field("Balance at Date"; Rec."Balance at Date")
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the cost type balance on the last date that is included in the Date Filter field. The contents of the field are calculated by using the entries in the Amount field in the Cost Entry table.';
                }
                field("Net Change"; Rec."Net Change")
                {
                    ApplicationArea = CostAccounting;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a description that applies.';
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cost Object")
            {
                Caption = '&Cost Object';
                Image = Costs;
                action("Cost E&ntries")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost E&ntries';
                    Image = CostEntries;
                    RunObject = Page "Cost Entries";
                    RunPageLink = "Cost Object Code" = field(Code);
                    RunPageView = sorting("Cost Object Code", "Cost Type No.", Allocated, "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View cost entries, which can come from sources such as automatic transfer of general ledger entries to cost entries, manual posting for pure cost entries, internal charges, and manual allocations, and automatic allocation postings for actual costs.';
                }
                separator(Action4)
                {
                }
                action("&Balance")
                {
                    ApplicationArea = CostAccounting;
                    Caption = '&Balance';
                    Image = Balance;
                    ShortCutKey = 'F7';
                    ToolTip = 'View a summary of the balance at date or the net change for different time periods for the cost object that you select. You can select different time intervals and set filters on the cost centers and cost objects that you want to see.';

                    trigger OnAction()
                    begin
                        if Rec.Totaling = '' then
                            CostType.SetFilter("Cost Object Filter", Rec.Code)
                        else
                            CostType.SetFilter("Cost Object Filter", Rec.Totaling);

                        PAGE.Run(PAGE::"Cost Type Balance", CostType);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("I&ndent Cost Objects")
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'I&ndent Cost Objects';
                    Image = IndentChartOfAccounts;
                    ToolTip = 'Indent the selected lines.';

                    trigger OnAction()
                    begin
                        CostAccountMgt.IndentCostObjectsYN();
                    end;
                }
                action("Get Cost Objects From Dimension")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Get Cost Objects From Dimension';
                    Image = ChangeTo;
                    ToolTip = 'Transfer dimension values to the chart of cost centers.';

                    trigger OnAction()
                    begin
                        CostAccountMgt.CreateCostObjects();
                    end;
                }
            }
            action(PageDimensionValues)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimension Values';
                Image = Dimensions;
                ToolTip = 'View or edit the dimension values for the current dimension.';

                trigger OnAction()
                begin
                    CostAccountMgt.OpenDimValueListFiltered(CostAccSetup.FieldNo("Cost Object Dimension"));
                end;
            }
        }
        area(reporting)
        {
            action("Cost Object with Budget")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Cost Object with Budget';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Cost Acctg. Balance/Budget";
                ToolTip = 'View a comparison of the balance to the budget figures and calculates the variance and the percent variance in the current accounting period, the accumulated accounting period, and the fiscal year.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Get Cost Objects From Dimension_Promoted"; "Get Cost Objects From Dimension")
                {
                }
                actionref(PageDimensionValues_Promoted; PageDimensionValues)
                {
                }
                actionref("I&ndent Cost Objects_Promoted"; "I&ndent Cost Objects")
                {
                }
                group("Category_Cost Object")
                {
                    Caption = 'Cost Object';

                    actionref("&Balance_Promoted"; "&Balance")
                    {
                    }
                    actionref("Cost E&ntries_Promoted"; "Cost E&ntries")
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        CodeOnFormat();
        NameOnFormat();
        BalanceatDateOnFormat();
        NetChangeOnFormat();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SetSelectionFilter(Rec);
        Rec.ConfirmDeleteIfEntriesExist(Rec, false);
        Rec.Reset();
    end;

    var
        CostType: Record "Cost Type";
        CostAccSetup: Record "Cost Accounting Setup";
        CostAccountMgt: Codeunit "Cost Account Mgt";
        Emphasize: Boolean;
        NameIndent: Integer;

    local procedure CodeOnFormat()
    begin
        Emphasize := Rec."Line Type" <> Rec."Line Type"::"Cost Object";
    end;

    local procedure NameOnFormat()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Line Type" <> Rec."Line Type"::"Cost Object";
    end;

    local procedure BalanceatDateOnFormat()
    begin
        Emphasize := Rec."Line Type" <> Rec."Line Type"::"Cost Object";
    end;

    local procedure NetChangeOnFormat()
    begin
        Emphasize := Rec."Line Type" <> Rec."Line Type"::"Cost Object";
    end;

    procedure GetSelectionFilter(): Text
    var
        CostObject: Record "Cost Object";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CostObject);
        exit(SelectionFilterManagement.GetSelectionFilterForCostObject(CostObject));
    end;
}

