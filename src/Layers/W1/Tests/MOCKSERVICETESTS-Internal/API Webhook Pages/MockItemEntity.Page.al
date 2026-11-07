page 135186 "Mock - Item Entity"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'items', Locked = true;
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    EntityName = 'item';
    EntitySetName = 'items';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                    Editable = false;
                }
                field(number; "No.")
                {
                    ApplicationArea = All;
                    Caption = 'Number', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                    ToolTip = 'Specifies the Description for the Item.';
                }
                field(type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', Locked = true;
                    ToolTip = 'Specifies the Type for the Item. Possible values are Inventory and Service.';
                }
                field(itemCategoryId; "Item Category Id")
                {
                    ApplicationArea = All;
                    Caption = 'ItemCategoryId', Locked = true;
                }
                field(itemCategoryCode; "Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'ItemCategoryCode', Locked = true;
                }
                field(blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;
                    ToolTip = 'Specifies whether the item is blocked.';
                }
                field(gtin; GTIN)
                {
                    ApplicationArea = All;
                    Caption = 'GTIN', Locked = true;
                }
                field(unitPrice; "Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'UnitPrice', Locked = true;
                }
                field(priceIncludesTax; "Price Includes VAT")
                {
                    ApplicationArea = All;
                    Caption = 'PriceIncludesTax', Locked = true;
                }
                field(unitCost; "Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'UnitCost', Locked = true;
                }
                field(taxGroupId; "Tax Group Id")
                {
                    ApplicationArea = All;
                    Caption = 'TaxGroupId', Locked = true;
                    ToolTip = 'Specifies the ID of the tax group.';
                }
                field(taxGroupCode; "Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'TaxGroupCode', Locked = true;
                }
                field(lastModifiedDateTime; "Last DateTime Modified")
                {
                    ApplicationArea = All;
                    Caption = 'LastModifiedDateTime', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }
}
