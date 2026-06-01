namespace Microsoft.eServices.EDocument.Extensions;

using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Vendor;

tableextension 6108 "E-Document Vendor Template" extends "Vendor Templ."
{
    fields
    {
        field(6101; "Receive E-Document To"; Enum "E-Document Type")
        {
            Caption = 'Receive E-Document To';
            InitValue = "Purchase Order";
            ValuesAllowed = "Purchase Order", "Purchase Invoice";
            DataClassification = CustomerContent;
        }
    }
}
