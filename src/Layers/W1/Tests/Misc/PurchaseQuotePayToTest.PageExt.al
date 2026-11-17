namespace Microsoft.Purchases.Test;

using Microsoft.Purchases.Document;

pageextension 134482 "Purchase Quote Pay-to Test" extends "Purchase Quote"
{
    layout
    {
        modify("Pay-to Name 2")
        {
            Visible = true;
        }
    }
}
