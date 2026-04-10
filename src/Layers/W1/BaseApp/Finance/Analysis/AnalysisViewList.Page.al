// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Lists all analysis views with quick access to analysis view cards and matrix reporting.
/// Provides overview of analysis view configurations and enables launching analysis reports.
/// </summary>
page 556 "Analysis View List"
{
    ApplicationArea = Dimensions;
    Caption = 'Analysis Views';
    CardPageID = "Analysis View Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Analysis Views';
    AboutText = 'Create, manage, and update analysis views to organize and filter general ledger data by selected dimensions, enabling flexible financial analysis and reporting in a matrix format.';
    SourceTable = "Analysis View";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                }
                field("Account Source"; Rec."Account Source")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies an account that you can use as a filter to define what is displayed in the Analysis by Dimensions window. ';
                }
                field("Include Budgets"; Rec."Include Budgets")
                {
                    ApplicationArea = Suite;
                    Visible = IncludeBudgets;
                }
                field("Last Date Updated"; Rec."Last Date Updated")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
                field("Dimension 1 Code"; Rec."Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 2 Code"; Rec."Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 3 Code"; Rec."Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 4 Code"; Rec."Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
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
            action(EditAnalysis)
            {
                ApplicationArea = Dimensions;
                Caption = 'Analysis by Dimensions';
                Image = Edit;
                ToolTip = 'View amounts in G/L accounts by their dimension values and other filters that you define in an analysis view and then show in a matrix window.';

                trigger OnAction()
                begin
                    Rec.RunAnalysisByDimensionPage();
                end;
            }
            action("&Update")
            {
                ApplicationArea = Suite;
                Caption = '&Update';
                Image = Refresh;
                RunObject = Codeunit "Update Analysis View";
                ToolTip = 'Get the latest entries into the analysis view.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(EditAnalysis_Promoted; EditAnalysis)
                {
                }
                actionref("&Update_Promoted"; "&Update")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IncludeBudgets := Rec."Account Source" = Rec."Account Source"::"G/L Account";
    end;

    var
        IncludeBudgets: Boolean;
}

