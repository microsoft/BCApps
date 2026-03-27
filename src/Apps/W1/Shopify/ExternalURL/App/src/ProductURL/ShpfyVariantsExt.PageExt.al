// ------------------------------------------------------------------------------------------------
// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information.
// ------------------------------------------------------------------------------------------------

namespace OpenSource.Shopify.ExternalURL;

using Microsoft.Integration.Shopify;

pageextension 50101 "Shpfy Variants Ext." extends "Shpfy Variants"
{
    layout
    {
        addlast(General)
        {
            field("Product URL"; Rec."Product URL")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies an override URL for this variant. When set, this URL is used instead of the template-based URL from the Agentic Setup.';
            }
        }
    }
}
