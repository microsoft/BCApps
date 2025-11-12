// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

page 121 "G/L Budget Names"
{
    AdditionalSearchTerms = 'general ledger budgets,general ledger forecast';
    ApplicationArea = Suite;
    Caption = 'G/L Budgets';
    PageType = List;
    SourceTable = "G/L Budget Name";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the general ledger budget.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the general ledger budget name.';
                }
                field("Global Dimension 1 Code"; GLSetup."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Global Dimension 1 Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; GLSetup."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Global Dimension 2 Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Budget Dimension 1 Code"; Rec."Budget Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
                }
                field("Budget Dimension 2 Code"; Rec."Budget Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
                }
                field("Budget Dimension 3 Code"; Rec."Budget Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
                }
                field("Budget Dimension 4 Code"; Rec."Budget Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a code for a budget dimension. You can specify four additional dimensions on each budget that you create.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
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
        area(processing)
        {
            action(EditBudget)
            {
                ApplicationArea = Suite;
                Caption = 'Edit Budget';
                Image = EditLines;
                ShortCutKey = 'Return';
                ToolTip = 'Specify budgets that you can create in the general ledger application area. If you need several different budgets, you can create several budget names.';

                trigger OnAction()
                var
                    Budget: Page Budget;
                begin
                    Budget.SetBudgetName(Rec.Name);
                    Budget.Run();
                end;
            }
            group(ReportGroup)
            {
                Caption = 'Report';
                Image = "Report";
                action(ReportTrialBalance)
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial Balance/Budget';
                    Image = "Report";
                    ToolTip = 'View budget details for the specified period.';

                    trigger OnAction()
                    begin
                        REPORT.Run(REPORT::"Trial Balance/Budget");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(EditBudget_Promoted; EditBudget)
                {
                }
                actionref(ReportTrialBalance_Promoted; ReportTrialBalance)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

            }
        }
    }

    trigger OnOpenPage()
    begin
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";

    procedure GetSelectionFilter(): Text
    var
        GLBudgetName: Record "G/L Budget Name";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(GLBudgetName);
        exit(SelectionFilterManagement.GetSelectionFilterForGLBudgetName(GLBudgetName));
    end;
}

