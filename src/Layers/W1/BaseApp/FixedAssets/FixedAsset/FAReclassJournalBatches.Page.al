// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

page 5640 "FA Reclass. Journal Batches"
{
    Caption = 'FA Reclass. Journal Batches';
    DataCaptionExpression = DataCaption();
    Editable = true;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "FA Reclass. Journal Batch";
    AnalysisModeEnabled = false;
    AboutTitle = 'About FA Reclass Journal Batches';
    AboutText = 'With the **FA Reclass Journal Batches** you can setup multiple batches, which are individual journals for each FA ReclassJnl Template.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the journal batch you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the journal batch that you are creating.';
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
            action("Edit Journal")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    FAReclassJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Journal_Promoted"; "Edit Journal")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Journal Template Name");
    end;

    trigger OnOpenPage()
    begin
        FAReclassJnlMgt.OpenJnlBatch(Rec);
    end;

    var
        FAReclassJnlMgt: Codeunit FAReclassJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        ReclassJnlTempl: Record "FA Reclass. Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if ReclassJnlTempl.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(ReclassJnlTempl.Name + ' ' + ReclassJnlTempl.Description);
    end;
}

