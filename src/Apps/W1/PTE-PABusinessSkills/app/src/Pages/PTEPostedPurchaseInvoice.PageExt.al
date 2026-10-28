pageextension 50101 "PTE Posted Purchase Invoice" extends "Posted Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            field("PTE Purchase Purpose"; Rec."PTE Purchase Purpose")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
}
