#pragma warning disable AA0247
page 17285 "Tax Reg. Norm Accum. Lines"
{
    Caption = 'Norm Accumulat. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Reg. Norm Accumulation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Norm Group Code"; Rec."Norm Group Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the norm group code associated with the norm accumulation information.';
                }
                field("Template Line Code"; Rec."Template Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template line code associated with the norm accumulation information.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the norm accumulation information.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount associated with the norm accumulation information.';

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

