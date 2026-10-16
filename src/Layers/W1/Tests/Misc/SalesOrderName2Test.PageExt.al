namespace Microsoft.Sales.Test;

using Microsoft.Sales.Document;

pageextension 134118 "Sales Order Name 2 Test" extends "Sales Order"
{
    layout
    {
        modify("Bill-to Name 2")
        {
            Visible = true;
        }
    }
}
