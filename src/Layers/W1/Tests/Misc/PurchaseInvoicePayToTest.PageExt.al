namespace Microsoft.Purchases.Test;

using Microsoft.Purchases.Document;

pageextension 138696 "Purchase Invoice Pay-to Test" extends "Purchase Invoice"
{
    layout
    {
        modify("Pay-to Name 2")
        {
            Visible = true;
        }
    }
}
