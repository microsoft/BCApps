// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Market Catalog Relations (ID 30173).
/// </summary>
page 30173 "Shpfy Market Catalog Relations"
{
    ApplicationArea = All;
    Caption = 'Shopify Market Catalog Relations';
    PageType = ListPart;
    SourceTable = "Shpfy Market Catalog Relation";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Market Name"; Rec."Market Name") { }
            }
        }
    }
}
