namespace Microsoft.eServices.EDocument.Extensions;

using Microsoft.Purchases.Vendor;

pageextension 6108 "E-Document Vendor Templ. Card" extends "Vendor Templ. Card"
{
    layout
    {
        addlast(Receiving)
        {
            field("Receive E-Document To"; Rec."Receive E-Document To")
            {
                ApplicationArea = All;
                Caption = 'Receive E-Document To';
                ToolTip = 'Specifies the default purchase document to be generated from received E-document. Users can select either a Purchase Invoice or Purchase Order. This selection does not affect the creation of corrective documents; in both scenarios, the system will generate a Credit Memo.';
            }
        }
    }
}
