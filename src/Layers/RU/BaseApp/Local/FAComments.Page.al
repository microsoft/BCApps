#pragma warning disable AA0247
page 12495 "FA Comments"
{
    AutoSplitKey = true;
    Caption = 'FA Comments';
    DataCaptionFields = "Document Type", "Document No.";
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "FA Comment";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the type of comment line associated with this fixed asset act.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the text of the comment associated with this fixed asset act.';
                }
            }
        }
    }

    actions
    {
    }
}

