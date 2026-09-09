namespace Microsoft.FabricExport;

using Microsoft.Utilities;

#if not PTE
page 150009 "Fabric Platform Name Lookup"
#else
page 50109 "Fabric Platform Name Lookup"
#endif
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
