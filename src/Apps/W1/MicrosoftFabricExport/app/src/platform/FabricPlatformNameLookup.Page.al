namespace Microsoft.FabricExport;

using Microsoft.Utilities;

page 48516 "Fabric Platform Name Lookup"
{
    Caption = 'Select';
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the item to select.';
                }
            }
        }
    }

    procedure SetSource(var TempBuffer: Record "Name/Value Buffer" temporary)
    begin
        Rec.Copy(TempBuffer, true);
        if Rec.FindFirst() then;
    end;
}
