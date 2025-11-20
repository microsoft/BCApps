// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Posting;

page 262 "Item Journal Batches"
{
    Caption = 'Item Journal Batches';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "Item Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item journal you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a brief description of the item journal batch you are creating.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series code used to assign document numbers to ledger entries that are posted from this journal batch.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Item Tracking on Lines"; Rec."Item Tracking on Lines")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies if item tracking can be selected directly on the item journal lines.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    ItemJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintItemJnlBatch(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post selected journal batches.';

                    trigger OnAction()
                    var
                        ItemJournalBatch: Record "Item Journal Batch";
                        ItemJnlBPost: Codeunit "Item Jnl.-B.Post";
                    begin
                        PrepareForPosting(Rec, ItemJournalBatch);
                        ItemJnlBPost.Run(ItemJournalBatch);
                        if ItemJnlBPost.JournalWithPostingErrors() then
                            SetSelectionFilterOnRecord(ItemJournalBatch, Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post and print selected journal batches.';

                    trigger OnAction()
                    var
                        ItemJournalBatch: Record "Item Journal Batch";
                        ItemJnlBPostPrint: Codeunit "Item Jnl.-B.Post+Print";
                    begin
                        PrepareForPosting(Rec, ItemJournalBatch);
                        ItemJnlBPostPrint.Run(ItemJournalBatch);
                        if ItemJnlBPostPrint.JournalWithPostingErrors() then
                            SetSelectionFilterOnRecord(ItemJournalBatch, Rec);
                    end;
                }
                action(FailedToPostOnOff)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Failed to Post On/Off';
                    Image = Change;
                    ToolTip = 'Toggle between showing all journal batches and only those that failed to post.';

                    trigger OnAction()
                    begin
                        Rec.MarkedOnly(not Rec.MarkedOnly);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Edit Journal_Promoted"; "Edit Journal")
                {
                }
                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Journal Template Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewBatch();
    end;

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemJnlMgt.OpenJnlBatch(Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        ItemJnlMgt: Codeunit ItemJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if ItemJnlTemplate.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(ItemJnlTemplate.Name + ' ' + ItemJnlTemplate.Description);
    end;

    local procedure PrepareForPosting(var FromItemJournalBatch: Record "Item Journal Batch"; var ItemJournalBatchToBePosted: Record "Item Journal Batch")
    begin
        ItemJournalBatchToBePosted := FromItemJournalBatch;
        ItemJournalBatchToBePosted.CopyFilters(FromItemJournalBatch);
        CurrPage.SetSelectionFilter(ItemJournalBatchToBePosted);
    end;

    local procedure SetSelectionFilterOnRecord(var PostedItemJournalBatch: Record "Item Journal Batch"; var ToItemJournalBatch: Record "Item Journal Batch")
    begin
        if PostedItemJournalBatch.FindSet() then
            repeat
                if ToItemJournalBatch.Get(PostedItemJournalBatch."Journal Template Name", PostedItemJournalBatch.Name) then
                    ToItemJournalBatch.Mark(true);
            until PostedItemJournalBatch.Next() = 0;
        ToItemJournalBatch.MarkedOnly(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var ItemJournalBatch: Record "Item Journal Batch"; var IsHandled: Boolean)
    begin
    end;
}

