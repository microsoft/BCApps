// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8134 "Report Filename Setup"
{
    Caption = 'Report Filename Setup';
    PageType = Card;
    SourceTable = "Report Filename Setup";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'file name, file names, file name setup, document name, PDF name, attachment name, report naming';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                }
                field("Enabled Patterns"; Rec."Enabled Patterns")
                {
                    trigger OnDrillDown()
                    var
                        Pattern: Record "Report Filename Pattern";
                    begin
                        Pattern.SetRange(Enabled, true);
                        ShowPatterns(Pattern);
                    end;
                }
                field("Max. File Name Length"; Rec."Max. File Name Length")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Patterns)
            {
                Caption = 'Report Filename Patterns';
                ToolTip = 'Opens the list of file name patterns.';
                Image = List;

                trigger OnAction()
                var
                    Pattern: Record "Report Filename Pattern";
                begin
                    ShowPatterns(Pattern);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Patterns_Promoted; Patterns)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        // The setup row is created only here, never while a report is being named.
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    /// <summary>
    /// Runs the list modally so Enabled Patterns can be recounted when it closes.
    /// </summary>
    local procedure ShowPatterns(var Pattern: Record "Report Filename Pattern")
    begin
        Page.RunModal(Page::"Report Filename Patterns", Pattern);
        CurrPage.Update(false);
    end;
}
