namespace Microsoft.Purchases.Test;

using Microsoft.Purchases.Document;

pageextension 138695 "Purchase Order Pay-to Test" extends "Purchase Order"
{
    layout
    {
        modify("Pay-to Name 2")
        {
            Visible = true;
        }
    }
}
