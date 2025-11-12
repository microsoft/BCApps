// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

page 1347 "Sales Pr. & Line Disc. Part"
{
    Caption = 'Sales Prices';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Sales Price and Line Disc Buff";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the line is for a sales price or a sales line discount.';
                }
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales type of the price or discount. The sales type defines whether the sales price or discount is for an individual customer, a customer discount group, or for all customers.';
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = All;
                    Enabled = SalesCodeIsVisible;
                    ToolTip = 'Specifies the sales code of the price or discount. The sales code depends on the value in the Sales Type field. The code can represent an individual customer, a customer discount group, or for all customers.';
                    Visible = SalesCodeIsVisible;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the discount is valid for an item or for an item discount group.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Enabled = CodeIsVisible;
                    ToolTip = 'Specifies a code for the sales line price or discount.';
                    Visible = CodeIsVisible;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity that must be entered on the sales document to warrant the sales price or discount.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec."Line Type" = 1;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec."Line Type" = 2;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the sales line discount is valid.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date to which the sales line discount is valid.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency that must be used on the sales document line to warrant the sales price or discount.';
                    Visible = false;
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the price that is granted includes VAT.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the sales price is offered.';
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group for customers who you want to apply the sales price to. This price includes VAT.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the variant that must be used on the sales document line to warrant the sales price or discount.';
                    Visible = false;
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if line discounts are allowed.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Filtering)
            {
                Caption = 'Filtering';
            }
            action("Show Current Only")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Current Only';
                Image = ActivateDiscounts;
                ToolTip = 'Show only valid price and discount agreements that have ending dates later than today''s date.';

                trigger OnAction()
                begin
                    Rec.FilterToActualRecords();
                end;
            }
            action("Show All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show All';
                Image = DeactivateDiscounts;
                ToolTip = 'Show all price and discount agreements, including those with ending dates earlier than today''s date.';

                trigger OnAction()
                begin
                    Rec.Reset();
                end;
            }
            action("Refresh Data")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Data';
                Image = RefreshLines;
                ToolTip = 'Update sales prices or sales line discounts with values that other users may have added for the customer since you opened the window.';

                trigger OnAction()
                var
                    Customer: Record Customer;
                    Item: Record Item;
                begin
                    if GetLoadedItemNo() <> '' then
                        if Item.Get(GetLoadedItemNo()) then begin
                            Rec.LoadDataForItem(Item);
                            exit;
                        end;
                    if Customer.Get(GetLoadedCustNo()) then
                        Rec.LoadDataForCustomer(Customer)
                end;
            }
            action("Set Special Prices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Special Prices';
                Enabled = SalesPriceIsEnabled;
                Image = Price;
                ToolTip = 'Set up different prices for items that you sell to the customer. An item price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                trigger OnAction()
                var
                    SalesPrice: Record "Sales Price";
                begin
                    SalesPrice.SetCurrentKey("Sales Type", "Sales Code", "Item No.");
                    SalesPrice.SetRange("Sales Type", Rec."Sales Type");
                    SalesPrice.SetRange("Sales Code", Rec."Sales Code");
                    SalesPrice.SetRange("Item No.", Rec.Code);
                    Page.Run(Page::"Sales Prices", SalesPrice);
                end;
            }
            action("Set Special Discounts")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Special Discounts';
                Image = LineDiscount;
                ToolTip = 'Set up different discounts for items that you sell to the customer. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                trigger OnAction()
                var
                    SalesLineDiscount: Record "Sales Line Discount";
                begin
                    SalesLineDiscount.SetCurrentKey("Sales Type", "Sales Code", Type, Code);
                    SalesLineDiscount.SetRange("Sales Type", Rec."Sales Type");
                    SalesLineDiscount.SetRange("Sales Code", Rec."Sales Code");
                    SalesLineDiscount.SetRange(Type, Rec.Type);
                    SalesLineDiscount.SetRange(Code, Rec.Code);
                    Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RefreshOnFind();
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SalesPriceIsEnabled := (Rec."Line Type" = Rec."Line Type"::"Sales Price");
    end;

    local procedure RefreshOnFind()
    var
        Customer: Record Customer;
        Item: Record Item;
        DummySalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff";
        CurrFilterGroup: Integer;
        SalesCode: Code[20];
        SalesTypeAsText: Text;
        ContextIsCustomer: Boolean;
    begin
        // Read the filter sent through SubPageLink. The filter that is expected is on 'Sales Type' and 'Sales Code'.
        // If 'Sales Type' is Customer, then the context is Customer, if it is not Customer or it is not defined, then
        // it is assumed that the context is Item. The filter is removed after reading.
        currFilterGroup := Rec.FilterGroup;
        Rec.FilterGroup(4);
        if Rec.GetFilters = '' then begin
            Rec.FilterGroup(CurrFilterGroup);
            exit;
        end;

        SalesCode := Rec.GetRangeMax("Sales Code");
        SalesTypeAsText := Rec.GetFilter("Sales Type");

        if Evaluate(DummySalesPriceAndLineDiscBuff."Sales Type", SalesTypeAsText) then
            if (DummySalesPriceAndLineDiscBuff."Sales Type" = DummySalesPriceAndLineDiscBuff."Sales Type"::Customer) then
                ContextIsCustomer := true;

        if ContextIsCustomer then begin
            if loadedCustNo <> SalesCode then begin

                if MoreRowsNotificationActive then
                    if MoreRowsNotification.Recall() then;
                MoreRowsNotificationActive := false;

                InitPage(false);
                Customer.SetLoadFields("No.", "Customer Disc. Group", "Customer Price Group");
                if Customer.Get(SalesCode) then
                    LoadCustomer(Customer);
            end
        end else
            if loadedItemNo <> SalesCode then begin
                InitPage(true);
                if Item.Get(SalesCode) then
                    LoadItem(Item);
            end;
        Rec.Reset();
        Rec.FilterGroup(CurrFilterGroup);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if (Rec."Loaded Customer No." = GetLoadedCustNo()) and (Rec."Loaded Item No." = GetLoadedItemNo()) then
            exit;

        Rec."Loaded Item No." := GetLoadedItemNo();
        Rec."Loaded Customer No." := GetLoadedCustNo();
        Rec."Loaded Price Group" := GetLoadedPriceGroup();
        Rec."Loaded Disc. Group" := GetLoadedDiscGroup();
    end;

    var
        MoreRowsNotification: Notification;
        MoreRowsNotificationActive: Boolean;
        loadedItemNo: Code[20];
        loadedCustNo: Code[20];
        loadedPriceGroup: Code[20];
        loadedDiscGroup: Code[20];
        CodeIsVisible: Boolean;
        SalesCodeIsVisible: Boolean;
        SalesPriceIsEnabled: Boolean;
        MaxRowsLoadedMsg: Label 'Showing the first %1 prices and discounts. To view all prices and discounts, choose Refresh Data.', Comment = '%1=a number, e.g. 50';

    procedure InitPage(ForItem: Boolean)
    begin
        if ForItem then begin
            CodeIsVisible := false;
            SalesCodeIsVisible := true;
        end else begin
            CodeIsVisible := true;
            SalesCodeIsVisible := false;
        end;
    end;

    procedure LoadItem(Item: Record Item)
    begin
        Clear(Rec);
        loadedItemNo := Item."No.";
        loadedDiscGroup := Item."Item Disc. Group";
        loadedPriceGroup := '';

        Rec.LoadDataForItem(Item);
    end;

    procedure LoadCustomer(var Customer: Record Customer)
    var
        MaxNoOfLinesToLoad: Integer;
        NoOfLinesLoaded: Integer;
    begin
        Clear(Rec);
        loadedCustNo := Customer."No.";
        loadedPriceGroup := Customer."Customer Price Group";
        loadedDiscGroup := Customer."Customer Disc. Group";
        if GuiAllowed then
            MaxNoOfLinesToLoad := 50; // to prevent loading of 1000's of entries.
        NoOfLinesLoaded := Rec.LoadDataForCustomer(Customer, MaxNoOfLinesToLoad);
        if (MaxNoOfLinesToLoad > 0) and (NoOfLinesLoaded >= MaxNoOfLinesToLoad) then begin
            MoreRowsNotification.Message := StrSubstNo(MaxRowsLoadedMsg, MaxNoOfLinesToLoad);
            MoreRowsNotification.Scope := NotificationScope::LocalScope;
            MoreRowsNotification.Send();
            MoreRowsNotificationActive := true;
        end;
    end;

    procedure GetLoadedItemNo(): Code[20]
    begin
        exit(loadedItemNo)
    end;

    procedure SetLoadedCustno(NewCustomerNo: Code[20]);
    begin
        if loadedCustNo = NewCustomerNo then
            exit;
        loadedCustNo := NewCustomerNo;
        Rec.Reset();
        Rec.DeleteAll();
        CurrPage.Update(false);
    end;

    procedure GetLoadedCustNo(): Code[20]
    begin
        exit(loadedCustNo)
    end;

    local procedure GetLoadedDiscGroup(): Code[20]
    begin
        exit(loadedDiscGroup)
    end;

    local procedure GetLoadedPriceGroup(): Code[20]
    begin
        exit(loadedPriceGroup)
    end;

    procedure RunUpdatePriceIncludesVatAndPrices(IncludesVat: Boolean)
    var
        Item: Record Item;
    begin
        Item.Get(loadedItemNo);
        Rec.UpdatePriceIncludesVatAndPrices(Item, IncludesVat);
    end;
}
