// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Analysis;
#if not CLEAN28
using Microsoft.Finance.GeneralLedger.Reports;
#endif
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

/// <summary>
/// List page for managing G/L Budget Names with dimension configuration and budget administration capabilities.
/// Primary interface for creating, configuring, and managing budget templates with multi-dimensional support.
/// </summary>
/// <remarks>
/// Key features: Budget name management, dimension configuration, budget copying, and Excel integration access.
/// Navigation: Links to budget entries, Excel import/export, and budget analysis workflows.
/// Extensibility: Support for custom budget actions through page extensions and event subscribers.
/// </remarks>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
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
                }
                field("Budget Dimension 2 Code"; Rec."Budget Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Budget Dimension 3 Code"; Rec."Budget Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Budget Dimension 4 Code"; Rec."Budget Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Suite;
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
#if not CLEAN28
                action(ReportTrialBalance)
                {
                    ApplicationArea = Suite;
                    Caption = 'Trial Balance/Budget (Obsolete)';
                    Image = "Report";
                    ToolTip = 'View budget details for the specified period.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Trial Balance/Budget (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';

                    trigger OnAction()
                    begin
                        REPORT.Run(REPORT::"Trial Balance/Budget");
                    end;
                }
#endif
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
#if not CLEAN28
                actionref(ReportTrialBalance_Promoted; ReportTrialBalance)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Trial Balance/Budget (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
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

    /// <summary>
    /// Returns a selection filter string based on the currently selected budget names in the page.
    /// Used for filtering operations on selected budget records.
    /// </summary>
    /// <returns>Filter string containing selected budget names.</returns>
    procedure GetSelectionFilter(): Text
    var
        GLBudgetName: Record "G/L Budget Name";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(GLBudgetName);
        exit(SelectionFilterManagement.GetSelectionFilterForGLBudgetName(GLBudgetName));
    end;
}

