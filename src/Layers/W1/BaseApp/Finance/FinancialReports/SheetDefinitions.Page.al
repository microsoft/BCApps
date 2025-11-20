// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8364 "Sheet Definitions"
{
    ApplicationArea = Basic, Suite;
    AnalysisModeEnabled = false;
    DataCaptionFields = Name;
    Caption = 'Financial Report Sheet Definitions';
    PageType = List;
    SourceTable = "Sheet Definition Name";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name) { }
                field(Description; Rec.Description) { }
                field("Analysis View"; Rec."Analysis View Name") { }
                field("Internal Description"; Rec."Internal Description") { }
            }
        }
        area(factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditDefinition)
            {
                Caption = 'Edit Definition';
                Enabled = Rec.Name <> '';
                Image = EditList;
                Scope = Repeater;
                ToolTip = 'View or edit the financial report sheet definition.';

                trigger OnAction()
                var
                    SheetDefLine: Record "Sheet Definition Line";
                begin
                    SheetDefLine.SetRange(Name, Rec.Name);
                    Page.Run(0, SheetDefLine);
                end;
            }
            action(WhereUsed)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Where-Used';
                Enabled = Rec.Name <> '';
                Image = Track;
                Scope = Repeater;
                ToolTip = 'View or edit financial reports in which the sheet definition is used.';

                trigger OnAction()
                var
                    FinancialReport: Record "Financial Report";
                begin
                    FinancialReport.SetRange(SheetDefinition, Rec.Name);
                    Page.Run(0, FinancialReport);
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(EditDefinition_Promoted; EditDefinition) { }
                actionref(WhereUsed_Promoted; WhereUsed) { }
            }
        }
    }
}