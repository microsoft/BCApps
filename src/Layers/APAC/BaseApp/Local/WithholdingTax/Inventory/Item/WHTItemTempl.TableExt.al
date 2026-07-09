// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Inventory.Item;

tableextension 28023 WHTItemTempl extends "Item Templ."
{
    fields
    {
        field(28040; "WHT Product Posting Group"; Code[20])
        {
            Caption = 'WHT Product Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "WHT Product Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("WHT Product Posting Group"));
            end;
        }
    }
}
