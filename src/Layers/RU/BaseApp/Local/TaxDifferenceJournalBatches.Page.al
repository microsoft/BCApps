#pragma warning disable AA0247
page 17305 "Tax Difference Journal Batches"
{
    Caption = 'Tax Difference Journal Batches';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "Tax Diff. Journal Batch";

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
                    ToolTip = 'Specifies the name associated with the tax differences journal batch.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax differences journal batch.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
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
                Image = EditJournal;
                ShortCutKey = 'Return';

                trigger OnAction()
                begin
                    TaxDiffJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        TaxDiffJnlMgt.JnlBatchPost(Rec);
                        CurrPage.Update();
                    end;
                }
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
                actionref("P&ost_Promoted"; "P&ost")
                {
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewBatch();
    end;

    var
        TaxDiffJnlMgt: Codeunit TaxDiffJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        GenJnlTemplate: Record "Tax Diff. Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if GenJnlTemplate.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(GenJnlTemplate.Name + ' ' + GenJnlTemplate.Description);
    end;
}

