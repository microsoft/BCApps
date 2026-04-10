#pragma warning disable AA0247
page 17248 "Tax Register Norm Details"
{
    Caption = 'Norm Details';
    DataCaptionExpression = Rec.FormTitle();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Register Norm Detail";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Norm Jurisdiction Code"; Rec."Norm Jurisdiction Code")
                {
                    ToolTip = 'Specifies the norm jurisdiction code associated with the norm details.';
                    Visible = false;
                }
                field("Effective Date"; Rec."Effective Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the effective date associated with the norm details.';
                }
                field(Norm; Rec.Norm)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the norm value that is used to calculate tax differences.';
                }
                field("Norm Type"; Rec."Norm Type")
                {
                    ToolTip = 'Specifies the norm type associated with the norm details.';
                    Visible = false;
                }
                field(Maximum; Rec.Maximum)
                {
                    ToolTip = 'Specifies the maximum amount associated with the norm details.';
                    Visible = false;
                }
                field("Norm Above Maximum"; Rec."Norm Above Maximum")
                {
                    ToolTip = 'Specifies the norm above maximum amount associated with the norm details.';
                    Visible = false;
                }
                field(LineDescription; Rec.LineDescription())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the record or entry.';
                }
            }
        }
    }

    actions
    {
    }
}

