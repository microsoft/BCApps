// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7113 "Analysis Column Templates"
{
    Caption = 'Analysis Column Templates';
    DataCaptionFields = "Analysis Area";
    PageType = List;
    SourceTable = "Analysis Column Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the name of the analysis column template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a description of the analysis column template.';
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
            action(Columns)
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = '&Columns';
                Image = Column;
                ToolTip = 'Species the columns on which the analysis view shows data.';

                trigger OnAction()
                var
                    AnalysisLine: Record "Analysis Line";
                    AnalysisReportMgt: Codeunit "Analysis Report Management";
                begin
                    AnalysisLine.FilterGroup := 2;
                    AnalysisLine.SetRange("Analysis Area", Rec.GetRangeMax("Analysis Area"));
                    AnalysisLine.FilterGroup := 0;
                    AnalysisReportMgt.OpenAnalysisColumnsForm(AnalysisLine, Rec.Name);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Columns_Promoted; Columns)
                {
                }
            }
        }
    }
}

