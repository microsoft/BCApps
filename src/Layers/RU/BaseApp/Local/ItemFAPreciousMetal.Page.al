#pragma warning disable AA0247
page 12487 "Item/FA Precious Metal"
{
    Caption = 'Item/FA Precious Metal';
    PageType = List;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Item/FA Precious Metal";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Precious Metals Code"; Rec."Precious Metals Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code associated with this precious metal asset.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the precious metal asset.';
                }
                field(Kind; Rec.Kind)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies and describes the precious metal.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the quantity of units of the precious metal asset.';
                }
                field(Mass; Rec.Mass)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the weight of the precious metal asset.';
                }
                field("Nomenclature No."; Rec."Nomenclature No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code used in technical literature to refer to alloy names or alloy designations.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related document.';
                }
            }
        }
    }

    actions
    {
    }
}

