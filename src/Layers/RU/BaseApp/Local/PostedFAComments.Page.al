#pragma warning disable AA0247
page 12496 "Posted FA Comments"
{
    Caption = 'Posted FA Comments';
    DataCaptionFields = "Document Type", "Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Posted FA Comment";

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

