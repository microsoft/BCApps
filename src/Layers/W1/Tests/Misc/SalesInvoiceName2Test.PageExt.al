namespace Microsoft.Sales.Test;

using Microsoft.Sales.Document;

pageextension 134124 "Sales Invoice Name 2 Test" extends "Sales Invoice"
{
    layout
    {
        modify("Bill-to Name 2")
        {
            Visible = true;
        }
    }
}
