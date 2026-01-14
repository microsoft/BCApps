// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

table 30163 "Shpfy Product Collection"
{
    Caption = 'Shopify Product Collection';
    DataClassification = CustomerContent;
    DrillDownPageId = "Shpfy Product Collections";
    LookupPageId = "Shpfy Product Collections";

    fields
    {
        field(1; Id; BigInteger)
        {
            Caption = 'Id';
            Editable = false;
            ToolTip = 'Specifies the unique identifier of the product collection.';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
            ToolTip = 'Specifies the name of the product collection.';
        }
        field(3; "Shop Code"; Code[20])
        {
            Caption = 'Shop Code';
            Editable = false;
            ToolTip = 'Specifies the code of the shop.';
        }
        field(4; Default; Boolean)
        {
            Caption = 'Assign';
            ToolTip = 'Specifies if the product collection is assigned to new products.';
        }
        field(5; "Item Filter"; Blob)
        {
            Caption = 'Item Filter';
            ToolTip = 'Specifies the filter criteria for the items in the product collection.';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    procedure SetItemFilter(ItemFilter: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Item Filter");
        "Item Filter".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(ItemFilter);
    end;

    procedure GetItemFilter() ItemFilter: Text
    var
        InStream: InStream;
    begin
        CalcFields("Item Filter");
        if not "Item Filter".HasValue() then
            exit('');
        "Item Filter".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(ItemFilter);
    end;
}