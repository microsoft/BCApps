// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7112 "Analysis Line Templates"
{
    Caption = 'Analysis Line Templates';
    DataCaptionFields = "Analysis Area";
    PageType = List;
    SourceTable = "Analysis Line Template";

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
                    ToolTip = 'Specifies the name of the analysis line template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a description of the analysis line template.';
                }
                field("Default Column Template Name"; Rec."Default Column Template Name")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the column template name that you have set up for this analysis report.';
                    Visible = false;
                }
                field("Item Analysis View Code"; Rec."Item Analysis View Code")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the name of the analysis view that the analysis report is based on.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemAnalysisView: Record "Item Analysis View";
                    begin
                        ItemAnalysisView.FilterGroup := 2;
                        ItemAnalysisView.SetRange("Analysis Area", Rec."Analysis Area");
                        ItemAnalysisView.FilterGroup := 0;
                        ItemAnalysisView."Analysis Area" := Rec."Analysis Area";
                        ItemAnalysisView.Code := Text;
                        if PAGE.RunModal(0, ItemAnalysisView) = ACTION::LookupOK then begin
                            Text := ItemAnalysisView.Code;
                            exit(true);
                        end;
                    end;
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
            action(Lines)
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                Caption = '&Lines';
                Image = AllLines;
                ToolTip = 'Specifies the lines in the analysis view that shows data.';

                trigger OnAction()
                var
                    AnalysisLine: Record "Analysis Line";
                    AnalysisReportMngt: Codeunit "Analysis Report Management";
                begin
                    AnalysisLine.FilterGroup := 2;
                    AnalysisLine.SetRange("Analysis Area", Rec."Analysis Area");
                    AnalysisLine.FilterGroup := 0;
                    AnalysisReportMngt.OpenAnalysisLinesForm(AnalysisLine, Rec.Name);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Lines_Promoted; Lines)
                {
                }
            }
        }
    }
}

