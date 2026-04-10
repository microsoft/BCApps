#pragma warning disable AA0247
page 17213 "Tax Register Accumulat. Lines"
{
    Caption = 'Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Register Accumulation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Register No."; Rec."Tax Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax register number associated with the tax register accumulation.';
                }
                field("Template Line Code"; Rec."Template Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template line code associated with the tax register accumulation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register accumulation.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount associated with the tax register accumulation.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownAmount();
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

