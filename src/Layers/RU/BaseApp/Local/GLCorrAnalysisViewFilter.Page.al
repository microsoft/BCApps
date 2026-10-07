#pragma warning disable AA0247
page 14943 "G/L Corr. Analysis View Filter"
{
    Caption = 'G/L Corr. Analysis View Filter';
    DataCaptionFields = "G/L Corr. Analysis View Code";
    PageType = List;
    SourceTable = "G/L Corr. Analysis View Filter";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Filter Group"; Rec."Filter Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this filter pertains to debit or credit entries.';
                }
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension code associated with the dimension value filter for a general ledger correspondence analysis view.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value that the data is filtered by.';
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
    }
}

