// ------------------------------------------------------------------------------------------------
// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information.
// ------------------------------------------------------------------------------------------------

namespace OpenSource.Shopify.ExternalURL;

using Microsoft.Integration.Shopify;

tableextension 50101 "Shpfy Variant Ext." extends "Shpfy Variant"
{
    fields
    {
        field(50101; "Product URL"; Text[500])
        {
            Caption = 'Product URL';
            DataClassification = CustomerContent;
        }
    }
}
