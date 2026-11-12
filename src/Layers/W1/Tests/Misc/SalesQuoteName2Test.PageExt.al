namespace Microsoft.Sales.Test;

using Microsoft.Sales.Document;

pageextension 134093 "Sales Quote Name 2 Test" extends "Sales Quote"
{
    layout
    {
        modify("Bill-to Name 2")
        {
            Visible = true;
        }
    }
}
