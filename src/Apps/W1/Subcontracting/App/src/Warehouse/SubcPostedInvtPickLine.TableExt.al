namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.InventoryDocument;

tableextension 99001574 "Subc. Posted Invt. Pick Line" extends "Posted Invt. Pick Line"
{
    fields
    {
        field(99001549; "Subc. Purchase Line Type"; Enum "Subc. Purchase Line Type")
        {
            Caption = 'Subcontracting Line Type';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the subcontracting purchase line type associated with the posted inventory pick line.';
        }
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this posted inventory pick line represents a WIP item transfer.';
        }
    }
}