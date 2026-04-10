// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using System.Globalization;

page 7502 "Item Attribute Translations"
{
    Caption = 'Item Attribute Translations';
    DataCaptionFields = "Attribute ID";
    PageType = List;
    SourceTable = "Item Attribute Translation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Languages;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

