namespace Microsoft.Sales.Test;

using Microsoft.Sales.Document;

pageextension 134449 "Blanket Sales Name 2 Test" extends "Blanket Sales Order"
{
    layout
    {
        modify("Bill-to Name 2")
        {
            Visible = true;
        }
    }
}
