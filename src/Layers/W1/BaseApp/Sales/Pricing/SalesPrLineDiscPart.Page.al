// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

/// <summary>
/// Displays sales prices and line discounts as a factbox part for items or customers.
/// </summary>
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
                }
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = All;
                    Enabled = SalesCodeIsVisible;
                    Visible = SalesCodeIsVisible;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    Enabled = CodeIsVisible;
                    Visible = CodeIsVisible;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec."Line Type" = 1;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec."Line Type" = 2;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
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
                    Visible = false;
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
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

    /// <summary>
    /// Initializes the page layout based on whether it is displayed for an item or a customer.
    /// </summary>
    /// <param name="ForItem">True if the page is being displayed for an item, false for a customer.</param>
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

    /// <summary>
    /// Loads price and line discount data for the specified item.
    /// </summary>
    /// <param name="Item">The item record to load prices and discounts for.</param>
    procedure LoadItem(Item: Record Item)
    begin
        Clear(Rec);
        loadedItemNo := Item."No.";
        loadedDiscGroup := Item."Item Disc. Group";
        loadedPriceGroup := '';

        Rec.LoadDataForItem(Item);
    end;

    /// <summary>
    /// Loads price and line discount data for the specified customer.
    /// </summary>
    /// <param name="Customer">The customer record to load prices and discounts for.</param>
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

    /// <summary>
    /// Gets the item number that was loaded for this page.
    /// </summary>
    /// <returns>The loaded item number.</returns>
    procedure GetLoadedItemNo(): Code[20]
    begin
        exit(loadedItemNo)
    end;

    /// <summary>
    /// Sets the loaded customer number and clears existing data if it differs from the current value.
    /// </summary>
    /// <param name="NewCustomerNo">The new customer number to set.</param>
    procedure SetLoadedCustno(NewCustomerNo: Code[20]);
    begin
        if loadedCustNo = NewCustomerNo then
            exit;
        loadedCustNo := NewCustomerNo;
        Rec.Reset();
        Rec.DeleteAll();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Gets the customer number that was loaded for this page.
    /// </summary>
    /// <returns>The loaded customer number.</returns>
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

    /// <summary>
    /// Updates the price includes VAT flag and recalculates prices for the loaded item.
    /// </summary>
    /// <param name="IncludesVat">True if prices should include VAT, otherwise false.</param>
    procedure RunUpdatePriceIncludesVatAndPrices(IncludesVat: Boolean)
    var
        Item: Record Item;
    begin
        Item.Get(loadedItemNo);
        Rec.UpdatePriceIncludesVatAndPrices(Item, IncludesVat);
    end;
}
