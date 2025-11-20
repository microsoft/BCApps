// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Inventory.Item;

page 5390 "Product Item Availability"
{
    Caption = 'Product Item Availability';
    PageType = List;
    SourceTable = "CRM Integration Record";
    SourceTableView = where("Table ID" = const(27));
    ObsoleteState = Pending;
    ObsoleteReason = 'This functionality is replaced with new item availability job queue entry.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("CRM ID"; Rec."CRM ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the unique identifier (GUID) of the record in Dynamics 365 Sales that is coupled to a record in Business Central that is associated with the Integration ID.';
                }
                field("Integration ID"; Rec."Integration ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the identifier (GUID) for a record that can be used by Dynamics 365 Sales to locate item records in Business Central.';
                    Visible = false;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the table that the entry is stored in.';
                    Visible = false;
                }
                field(ItemNo; Item."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'ItemNo';
                    ToolTip = 'Specifies the item number.';
                }
                field(UOM; Item."Base Unit of Measure")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'UOM';
                    ToolTip = 'Specifies Unit of Measure';
                }
                field(Inventory; Item.Inventory)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies the inventory level of an item.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(Item);
        if IsNullGuid(Rec."Integration ID") or (Rec."Table ID" <> DATABASE::Item) then
            exit;

        if Item.GetBySystemId(Rec."Integration ID") then
            Item.CalcFields(Inventory);
    end;

    var
        Item: Record Item;
}

