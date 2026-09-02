pageextension 3305 FixedAssetsPageExt extends "Fixed Asset Card"
{
    layout
    {
        addlast("Electronic Document")
        {
            field("Property tax account No"; Rec."Property tax account No")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the property tax account number for the fixed asset.';
            }
        }
    }
}