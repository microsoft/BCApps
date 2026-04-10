// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using System.Utilities;

codeunit 7019 "Price Helper - V15"
{
    SingleInstance = true;

    var
        WantUpdatePriceQst: Label 'You have set %1 to %2. Do you want to update the %3 price list accordingly?',
            Comment = '%1 - a field caption, %2 - a field value, %3 - a table caption';

    local procedure CopyJobPrices(SourceJob: Record Job; TargetJob: Record Job)
    var
        SourceJobItemPrice: Record "Job Item Price";
        SourceJobResourcePrice: Record "Job Resource Price";
        SourceJobGLAccountPrice: Record "Job G/L Account Price";
        TargetJobItemPrice: Record "Job Item Price";
        TargetJobResourcePrice: Record "Job Resource Price";
        TargetJobGLAccountPrice: Record "Job G/L Account Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            exit;
        SourceJobItemPrice.SetRange("Job No.", SourceJob."No.");
        if SourceJobItemPrice.FindSet() then
            repeat
                TargetJobItemPrice.TransferFields(SourceJobItemPrice, true);
                TargetJobItemPrice."Job No." := TargetJob."No.";
                TargetJobItemPrice.Insert(true);
            until SourceJobItemPrice.Next() = 0;

        SourceJobResourcePrice.SetRange("Job No.", SourceJob."No.");
        if SourceJobResourcePrice.FindSet() then
            repeat
                TargetJobResourcePrice.TransferFields(SourceJobResourcePrice, true);
                TargetJobResourcePrice."Job No." := TargetJob."No.";
                TargetJobResourcePrice.Insert(true);
            until SourceJobResourcePrice.Next() = 0;

        SourceJobGLAccountPrice.SetRange("Job No.", SourceJob."No.");
        if SourceJobGLAccountPrice.FindSet() then
            repeat
                TargetJobGLAccountPrice.TransferFields(SourceJobGLAccountPrice, true);
                TargetJobGLAccountPrice."Job No." := TargetJob."No.";
                TargetJobGLAccountPrice.Insert(true);
            until SourceJobGLAccountPrice.Next() = 0;
    end;

    local procedure RenameCustomerPriceGroupPrices(xCode: Code[20]; NewCode: Code[20])
    var
        SalesPrice: Record "Sales Price";
        NewSalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", xCode);
        if SalesPrice.FindSet() then
            repeat
                NewSalesPrice := SalesPrice;
                NewSalesPrice."Sales Code" := NewCode;
                NewSalesPrice.Insert(true);
            until SalesPrice.Next() = 0;
        SalesPrice.DeleteAll(true);
    end;

    local procedure DeleteJobPrices(JobNo: Code[20])
    var
        JobResPrice: Record "Job Resource Price";
        JobItemPrice: Record "Job Item Price";
        JobGLAccPrice: Record "Job G/L Account Price";
    begin
        JobResPrice.SetRange("Job No.", JobNo);
        if not JobResPrice.IsEmpty() then
            JobResPrice.DeleteAll();

        JobItemPrice.SetRange("Job No.", JobNo);
        if not JobItemPrice.IsEmpty() then
            JobItemPrice.DeleteAll();

        JobGLAccPrice.SetRange("Job No.", JobNo);
        if not JobGLAccPrice.IsEmpty() then
            JobGLAccPrice.DeleteAll();
    end;

    local procedure DeletePurchasePrices(VendorNo: Code[20])
    var
        PurchPrice: Record "Purchase Price";
        PurchLineDiscount: Record "Purchase Line Discount";
    begin
        PurchPrice.SetCurrentKey("Vendor No.");
        PurchPrice.SetRange("Vendor No.", VendorNo);
        if not PurchPrice.IsEmpty() then
            PurchPrice.DeleteAll(true);

        PurchLineDiscount.SetCurrentKey("Vendor No.");
        PurchLineDiscount.SetRange("Vendor No.", VendorNo);
        if not PurchLineDiscount.IsEmpty() then
            PurchLineDiscount.DeleteAll(true);
    end;

    local procedure DeletePurchasePricesForItem(ItemNo: Code[20]; VariantCode: Code[10])
    var
        PurchPrice: Record "Purchase Price";
        PurchLineDiscount: Record "Purchase Line Discount";
    begin
        PurchPrice.SetRange("Item No.", ItemNo);
        if VariantCode <> '' then
            PurchPrice.SetRange("Variant Code", VariantCode);
        if not PurchPrice.IsEmpty() then
            PurchPrice.DeleteAll(true);

        PurchLineDiscount.SetRange("Item No.", ItemNo);
        if VariantCode <> '' then
            PurchLineDiscount.SetRange("Variant Code", VariantCode);
        if not PurchLineDiscount.IsEmpty() then
            PurchLineDiscount.DeleteAll(true);
    end;

    local procedure DeleteResourcePrices(Type: Option; ResourceNo: Code[20])
    var
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
    begin
        ResourceCost.SetRange(Type, Type);
        ResourceCost.SetRange(Code, ResourceNo);
        if not ResourceCost.IsEmpty() then
            ResourceCost.DeleteAll();

        ResourcePrice.SetRange(Type, Type);
        ResourcePrice.SetRange(Code, ResourceNo);
        if not ResourcePrice.IsEmpty() then
            ResourcePrice.DeleteAll();
    end;

    local procedure DeleteSalesPrices(SalesType: Enum "Sales Price Type"; SalesCode: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Sales Type", SalesType);
        SalesPrice.SetRange("Sales Code", SalesCode);
        if not SalesPrice.IsEmpty() then
            SalesPrice.DeleteAll();
    end;

    local procedure DeleteSalesPricesForItem(ItemNo: Code[20]; VariantCode: Code[10])
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Item No.", ItemNo);
        if VariantCode <> '' then
            SalesPrice.SetRange("Variant Code", VariantCode);
        if not SalesPrice.IsEmpty() then
            SalesPrice.DeleteAll();
    end;

    local procedure DeleteSalesDiscounts(SalesType: Option; SalesCode: Code[20])
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        SalesLineDisc.SetRange("Sales Type", SalesType);
        SalesLineDisc.SetRange("Sales Code", SalesCode);
        if not SalesLineDisc.IsEmpty() then
            SalesLineDisc.DeleteAll();
    end;

    local procedure DeleteSalesDiscountsForType(Type: Enum "Sales Line Discount Type"; Code: Code[20]; VariantCode: Code[10])
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        SalesLineDisc.SetRange(Type, Type);
        SalesLineDisc.SetRange(Code, Code);
        if VariantCode <> '' then
            SalesLineDisc.SetRange("Variant Code", VariantCode);
        if not SalesLineDisc.IsEmpty() then
            SalesLineDisc.DeleteAll();
    end;

    local procedure UpdateDates(Campaign: Record Campaign)
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
        SalesPrice2: Record "Sales Price";
        SalesLineDisc2: Record "Sales Line Discount";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
        SalesPrice.SetRange("Sales Code", Campaign."No.");
        if not SalesPrice.IsEmpty() then begin
            SalesPrice.LockTable();
            if SalesPrice.FindSet() then
                repeat
                    SalesPrice2 := SalesPrice;
                    SalesPrice.Delete();
                    SalesPrice2.Validate("Starting Date", Campaign."Starting Date");
                    SalesPrice2.Insert(true);
                    SalesPrice2.Validate("Ending Date", Campaign."Ending Date");
                    SalesPrice2.Modify();
                until SalesPrice.Next() = 0;
        end;

        SalesLineDisc.SetRange("Sales Type", SalesLineDisc."Sales Type"::Campaign);
        SalesLineDisc.SetRange("Sales Code", Campaign."No.");
        SalesLineDisc.LockTable();
        if not SalesLineDisc.IsEmpty() then
            if SalesLineDisc.FindSet() then
                repeat
                    SalesLineDisc2 := SalesLineDisc;
                    SalesLineDisc.Delete();
                    SalesLineDisc2.Validate("Starting Date", Campaign."Starting Date");
                    SalesLineDisc2.Insert(true);
                    SalesLineDisc2.Validate("Ending Date", Campaign."Ending Date");
                    SalesLineDisc2.Modify();
                until SalesLineDisc.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'Prices Including VAT', false, false)]
    local procedure AfterValidatePricesIncludingVATOnVendor(var Rec: Record Vendor; var xRec: Record Vendor; CurrFieldNo: Integer)
    var
        PurchPrice: Record "Purchase Price";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        PurchPrice.SetCurrentKey("Vendor No.");
        PurchPrice.SetRange("Vendor No.", Rec."No.");
        if PurchPrice.FindSet() then begin
            if VATPostingSetup.Get('', '') then;
            if ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(
                    WantUpdatePriceQst,
                    Rec.FieldCaption("Prices Including VAT"), Rec."Prices Including VAT", PurchPrice.TableCaption()), true)
            then
                repeat
                    if PurchPrice."Item No." <> Item."No." then
                        Item.Get(PurchPrice."Item No.");
                    if (Rec."VAT Bus. Posting Group" <> VATPostingSetup."VAT Bus. Posting Group") or
                        (Item."VAT Prod. Posting Group" <> VATPostingSetup."VAT Prod. Posting Group")
                    then
                        VATPostingSetup.Get(Rec."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
                    Rec.ValidatePricesIncludingVATOnAfterGetVATPostingSetup(VATPostingSetup);
                    if PurchPrice."Currency Code" = '' then
                        Currency.InitRoundingPrecision()
                    else
                        if PurchPrice."Currency Code" <> Currency.Code then
                            Currency.Get(PurchPrice."Currency Code");
                    if VATPostingSetup."VAT %" <> 0 then begin
                        if Rec."Prices Including VAT" then
                            PurchPrice."Direct Unit Cost" :=
                                Round(
                                PurchPrice."Direct Unit Cost" * (1 + VATPostingSetup."VAT %" / 100),
                                Currency."Unit-Amount Rounding Precision")
                        else
                            PurchPrice."Direct Unit Cost" :=
                                Round(
                                PurchPrice."Direct Unit Cost" / (1 + VATPostingSetup."VAT %" / 100),
                                Currency."Unit-Amount Rounding Precision");
                        PurchPrice.Modify();
                    end;
                until PurchPrice.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCustomer(var Rec: Record Customer; RunTrigger: Boolean);
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then begin
            DeleteSalesPrices(SalesPrice."Sales Type"::Customer, Rec."No.");
            DeleteSalesDiscounts(SalesLineDisc."Sales Type"::Customer, Rec."No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Discount Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCustomerDiscountGroup(var Rec: Record "Customer Discount Group"; RunTrigger: Boolean);
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeleteSalesDiscounts(SalesLineDisc."Sales Type"::"Customer Disc. Group", Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Price Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCustomerPriceGroup(var Rec: Record "Customer Price Group"; RunTrigger: Boolean);
    var
        SalesPrice: Record "Sales Price";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeleteSalesPrices(SalesPrice."Sales Type"::"Customer Price Group", Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Price Group", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRenameCustomerPriceGroup(var Rec: Record "Customer Price Group"; var xRec: Record "Customer Price Group"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            RenameCustomerPriceGroupPrices(xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::Campaign, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteCampaign(var Rec: Record Campaign; RunTrigger: Boolean);
    var
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then begin
            DeleteSalesPrices(SalesPrice."Sales Type"::Campaign, Rec."No.");
            DeleteSalesDiscounts(SalesLineDisc."Sales Type"::Campaign, Rec."No.");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean);
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then begin
            DeleteSalesPricesForItem(Rec."No.", '');
            DeleteSalesDiscountsForType(SalesLineDisc.Type::Item, Rec."No.", '');
            DeletePurchasePricesForItem(Rec."No.", '');
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Discount Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteItemDiscountGroup(var Rec: Record "Item Discount Group"; RunTrigger: Boolean);
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeleteSalesDiscountsForType(SalesLineDisc.Type::"Item Disc. Group", Rec.Code, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteItemVariant(var Rec: Record "Item Variant"; RunTrigger: Boolean);
    var
        SalesLineDisc: Record "Sales Line Discount";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then begin
            DeleteSalesPricesForItem(Rec."Item No.", Rec.Code);
            DeleteSalesDiscountsForType(SalesLineDisc.Type::Item, Rec."Item No.", Rec.Code);
            DeletePurchasePricesForItem(Rec."Item No.", Rec.Code);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteJob(var Rec: Record Job; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeleteJobPrices(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteResource(var Rec: Record Resource; RunTrigger: Boolean);
    var
        ResourcePrice: Record "Resource Price";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeleteResourcePrices(ResourcePrice.Type::Resource, Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Resource Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteResourceGroup(var Rec: Record "Resource Group"; RunTrigger: Boolean);
    var
        ResourcePrice: Record "Resource Price";
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeleteResourcePrices(ResourcePrice.Type::"Group(Resource)", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            DeletePurchasePrices(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Campaign, 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModifyCampaign(var Rec: Record Campaign; var xRec: Record Campaign; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary() then
            exit;

        if RunTrigger then
            if (Rec."Starting Date" <> xRec."Starting Date") or (Rec."Ending Date" <> xRec."Ending Date") then
                UpdateDates(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Job", 'OnBeforeCopyJobPrices', '', false, false)]
    local procedure BeforeCopyJobPrices(var SourceJob: Record Job; var TargetJob: Record Job);
    begin
        CopyJobPrices(SourceJob, TargetJob);
    end;
}
