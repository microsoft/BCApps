#pragma warning disable AA0247
page 12486 "Precious Metal"
{
    ApplicationArea = FixedAssets;
    Caption = 'Precious Metal';
    PageType = List;
    SourceTable = "Precious Metal";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code associated with this precious metal asset.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the precious metal asset.';
                }
            }
        }
    }

    actions
    {
    }
}

