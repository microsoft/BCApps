// ------------------------------------------------------------------------------------------------
// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information.
// ------------------------------------------------------------------------------------------------

namespace OpenSource.Shopify.ExternalURL;

using Microsoft.Integration.Shopify;

tableextension 50100 "Shpfy Shop Ext." extends "Shpfy Shop"
{
    fields
    {
        field(50100; "Product URL Template"; Text[250])
        {
            Caption = 'Product URL Template';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                MustStartWithSchemeLbl: Label 'The URL template must start with https:// or http://';
            begin
                if "Product URL Template" <> '' then
                    if not "Product URL Template".StartsWith('https://') and not "Product URL Template".StartsWith('http://') then
                        Error(MustStartWithSchemeLbl);
            end;
        }
    }
}
