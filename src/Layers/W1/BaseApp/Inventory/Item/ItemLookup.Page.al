// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

page 32 "Item Lookup"
{
    Caption = 'Items';
    CardPageID = "Item Card";
    Editable = false;
    PageType = List;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("No. 2"; Rec."No. 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the alternative number of the item.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit in which the item is held in inventory. The base unit of measure also serves as the conversion basis for alternate units of measure.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the price for one unit of the item.';
                }
                field(InventoryCtrl; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity in stock for this item.';
                }
                field("Created From Nonstock Item"; Rec."Created From Nonstock Item")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Stockkeeping Unit Exists"; Rec."Stockkeeping Unit Exists")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Costing Method"; Rec."Costing Method")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Cost is Adjusted"; Rec."Cost is Adjusted")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Standard Cost"; Rec."Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost per unit of the item.';
                }
                field("Last Direct Cost"; Rec."Last Direct Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the most recent direct unit cost that was paid for the item.';
                    Visible = false;
                }
                field("Price/Profit Calculation"; Rec."Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Profit %"; Rec."Profit %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Inventory Posting Group"; Rec."Inventory Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item Disc. Group"; Rec."Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Alternative Item No."; Rec."Alternative Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternative number for the item.';
                    Visible = false;
                }
                field("Common Item No."; Rec."Common Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a commonly used number for the item.';
                    Visible = false;
                }
                field("Tariff No."; Rec."Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(SalesBlocked; Rec."Sales Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(PurchasingBlocked; Rec."Purchasing Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that transactions with the item cannot be purchased.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Sales Unit of Measure"; Rec."Sales Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Purch. Unit of Measure"; Rec."Purch. Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Manufacturing Policy"; Rec."Manufacturing Policy")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Assembly Policy"; Rec."Assembly Policy")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Item Tracking Code"; Rec."Item Tracking Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies how items are tracked in the supply chain.';
                    Visible = false;
                }
                field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Default Deferral Template';
                    Importance = Additional;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(ItemList)
            {
                ApplicationArea = All;
                Caption = 'Advanced View';
                Image = CustomerList;
                ToolTip = 'Open the Items page showing all possible columns.';

                trigger OnAction()
                var
                    ItemList: Page "Item List";
                begin
                    ItemList.SetTableView(Rec);
                    ItemList.SetRecord(Rec);
                    ItemList.LookupMode := true;

                    Commit();
                    if ItemList.RunModal() = ACTION::LookupOK then begin
                        ItemList.GetRecord(Rec);
                        CurrPage.Close();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ItemList_Promoted; ItemList)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange(Blocked, false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindRecord(Rec, Which, CrossColumnSearchFilter, Found, IsHandled);
        if IsHandled then
            exit(Found);

        exit(Rec.Find(Which));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(var Rec: Record Item; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    var
        CrossColumnSearchFilter: Text;
}

