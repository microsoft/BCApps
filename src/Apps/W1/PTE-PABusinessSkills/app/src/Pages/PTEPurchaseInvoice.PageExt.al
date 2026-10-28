pageextension 50100 "PTE Purchase Invoice" extends "Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            field("PTE Purchase Purpose"; Rec."PTE Purchase Purpose")
            {
                ApplicationArea = All;
            }
        }
    }
}
