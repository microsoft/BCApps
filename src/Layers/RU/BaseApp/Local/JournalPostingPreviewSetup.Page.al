#pragma warning disable AA0247
page 14939 "Journal Posting Preview Setup"
{
    Caption = 'Journal Posting Preview Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Journal Posting Preview Setup";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Journal Type"; Rec."Journal Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of journal posting.';
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("Enable Posting Preview"; Rec."Enable Posting Preview")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether or not to post the journal.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("S&etup")
            {
                Caption = 'S&etup';
                Image = Setup;
                action(Enable)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enable';
                    Image = Apply;
                    ToolTip = 'Enable the report selection.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(JnlPostSetup);
                        if JnlPostSetup.FindSet() then
                            repeat
                                JnlPostSetup."Enable Posting Preview" := true;
                                JnlPostSetup.Modify();
                            until JnlPostSetup.Next() = 0;
                    end;
                }
                action(Disable)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Disable';
                    Image = UnApply;

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(JnlPostSetup);
                        if JnlPostSetup.FindSet() then
                            repeat
                                JnlPostSetup."Enable Posting Preview" := false;
                                JnlPostSetup.Modify();
                            until JnlPostSetup.Next() = 0;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.GetRangeMin("User ID") = Rec.GetRangeMax("User ID") then
            Rec.Initialize(Rec.GetRangeMin("User ID"));
    end;

    var
        JnlPostSetup: Record "Journal Posting Preview Setup";
}

