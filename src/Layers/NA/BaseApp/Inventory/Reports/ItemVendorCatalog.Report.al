// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Vendor;

// NA local report with same name as in W1
report 10164 "Item/Vendor Catalog"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemVendorCatalog.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item/Vendor Catalog';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Vendor"; "Item Vendor")
        {
            RequestFilterFields = "Item No.", "Vendor No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(Item_Vendor__TABLECAPTION__________ItemVendorFilter; "Item Vendor".TableCaption + ': ' + ItemVendorFilter)
            {
            }
            column(ItemVendorFilter; ItemVendorFilter)
            {
            }
            column(SortingOrder2; SortingOrder2)
            {
            }
            column(SortingOrder; SortingOrder)
            {
            }
            column(Item_Vendor__Vendor_No__; "Vendor No.")
            {
            }
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor__Phone_No__; Vendor."Phone No.")
            {
            }
            column(Vendor_Contact; Vendor.Contact)
            {
            }
            column(Item_Vendor__Item_No__; "Item No.")
            {
            }
            column(Item_Description; Item.Description)
            {
            }
            column(Item_Vendor__Item_No___Control11; "Item No.")
            {
            }
            column(Item_Description_Control13; Item.Description)
            {
            }
            column(Item_Vendor__Lead_Time_Calculation_; "Lead Time Calculation")
            {
            }
            column(Item_Vendor__Vendor_Item_No__; "Vendor Item No.")
            {
            }
            column(PurchPrice__Starting_Date_; StartingDate)
            {
            }
            column(PurchPrice__Direct_Unit_Cost_; DirectUnitCost)
            {
            }
            column(Item_Vendor__Vendor_No___Control23; "Vendor No.")
            {
            }
            column(Vendor_Name_Control25; Vendor.Name)
            {
            }
            column(Vendor__Phone_No___Control27; Vendor."Phone No.")
            {
            }
            column(Item_Vendor__Lead_Time_Calculation__Control31; "Lead Time Calculation")
            {
            }
            column(Item_Vendor__Vendor_Item_No___Control35; "Vendor Item No.")
            {
            }
            column(PurchPrice__Starting_Date__Control1020004; StartingDate)
            {
            }
            column(PurchPrice__Direct_Unit_Cost__Control1020006; DirectUnitCost)
            {
            }
            column(Item_Vendor_Variant_Code; "Variant Code")
            {
            }
            column(Item_Vendor_CatalogCaption; Item_Vendor_CatalogCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_Vendor__Item_No___Control11Caption; FieldCaption("Item No."))
            {
            }
            column(Item_Description_Control13Caption; Item_Description_Control13CaptionLbl)
            {
            }
            column(Item_Vendor__Lead_Time_Calculation_Caption; FieldCaption("Lead Time Calculation"))
            {
            }
            column(Item_Vendor__Vendor_Item_No__Caption; FieldCaption("Vendor Item No."))
            {
            }
            column(PurchPrice__Starting_Date_Caption; PurchPrice__Starting_Date_CaptionLbl)
            {
            }
            column(PurchPrice__Direct_Unit_Cost_Caption; PurchPrice__Direct_Unit_Cost_CaptionLbl)
            {
            }
            column(Item_Vendor__Vendor_No___Control23Caption; FieldCaption("Vendor No."))
            {
            }
            column(Vendor_Name_Control25Caption; Vendor_Name_Control25CaptionLbl)
            {
            }
            column(Vendor__Phone_No___Control27Caption; Vendor__Phone_No___Control27CaptionLbl)
            {
            }
            column(Item_Vendor__Lead_Time_Calculation__Control31Caption; FieldCaption("Lead Time Calculation"))
            {
            }
            column(Item_Vendor__Vendor_Item_No___Control35Caption; FieldCaption("Vendor Item No."))
            {
            }
            column(PurchPrice__Starting_Date__Control1020004Caption; PurchPrice__Starting_Date__Control1020004CaptionLbl)
            {
            }
            column(PurchPrice__Direct_Unit_Cost__Control1020006Caption; PurchPrice__Direct_Unit_Cost__Control1020006CaptionLbl)
            {
            }
            column(Vendor__Phone_No__Caption; Vendor__Phone_No__CaptionLbl)
            {
            }
            column(Vendor_ContactCaption; Vendor_ContactCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                case SortOrder of
                    SortOrder::"By Vendor":
                        if not Item.Get("Item No.") then begin
                            Item.Init();
                            Item.Description := Text003;
                        end;
                    SortOrder::"By Item":
                        if not Vendor.Get("Vendor No.") then begin
                            Vendor.Init();
                            Vendor.Name := Text004;
                        end;
                end;

                if Vendor."No." <> "Vendor No." then
                    if not Vendor.Get("Vendor No.") then begin
                        Vendor.Init();
                        Vendor.Name := Text004;
                    end;
                if Item."No." <> "Item No." then
                    if not Item.Get("Item No.") then begin
                        Item.Init();
                        Item.Description := Text003;
                    end;

                GetPriceData();
            end;

            trigger OnPreDataItem()
            begin
                SortingString := "Item Vendor".CurrentKey;
                if CopyStr(SortingString, 1, StrLen("Item Vendor".FieldCaption("Vendor No.")))
                   = "Item Vendor".FieldCaption("Vendor No.")
                then begin
                    if CopyStr(SortingString, StrLen("Item Vendor".FieldCaption("Vendor No.")) + 1,
                         StrLen("Item Vendor".FieldCaption("Item No.")))
                       = "Item Vendor".FieldCaption("Item No.")
                    then
                        SortingOrder2 := 1
                    else
                        SortingOrder2 := 3
                end else
                    SortingOrder2 := 2;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        CompanyInformation.Get();
        SortOrder := WhichOrder();
        case SortOrder of
            SortOrder::"By Vendor":
                SubTitle := Text001;
            SortOrder::"By Item":
                SubTitle := Text002;
        end;
        ItemVendorFilter := "Item Vendor".GetFilters();

        case SortOrder of
            SortOrder::"By Vendor":
                SortingOrder := 1;
            SortOrder::"By Item":
                SortingOrder := 0;
        end;
    end;

    var
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        ExtendedPriceEnabled: Boolean;
        StartingDate: Date;
        DirectUnitCost: Decimal;
        SortOrder: Option "By Vendor","By Item";
        SubTitle: Text[132];
        ItemVendorFilter: Text;
        Text000: Label 'You must select a sort order for %1 which starts with either %2 or %3.';
        Text001: Label 'Items for each Vendor';
        Text002: Label 'Vendors for each Item';
        Text003: Label '<invalid item>';
        Text004: Label '<invalid vendor>';
        SortingOrder: Integer;
        SortingString: Text[300];
        SortingOrder2: Integer;
        Item_Vendor_CatalogCaptionLbl: Label 'Item/Vendor Catalog';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_Description_Control13CaptionLbl: Label 'Item Description';
        PurchPrice__Starting_Date_CaptionLbl: Label 'Starting Date';
        PurchPrice__Direct_Unit_Cost_CaptionLbl: Label 'Direct Unit Cost';
        Vendor_Name_Control25CaptionLbl: Label 'Vendor Name';
        Vendor__Phone_No___Control27CaptionLbl: Label 'Phone No.';
        PurchPrice__Starting_Date__Control1020004CaptionLbl: Label 'Starting Date';
        PurchPrice__Direct_Unit_Cost__Control1020006CaptionLbl: Label 'Direct Unit Cost';
        Vendor__Phone_No__CaptionLbl: Label 'Phone No.';
        Vendor_ContactCaptionLbl: Label 'Contact';

    local procedure GetPriceData();
    var
        PriceListLine: Record "Price List Line";
    begin
        StartingDate := 0D;
        DirectUnitCost := 0.0;
        if ExtendedPriceEnabled then begin
            PriceListLine.SetRange(Status, PriceListLine.Status::Active);
            PriceListLine.SetRange("Price Type", PriceListLine."Price Type"::Purchase);
            PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
            PriceListLine.SetRange("Asset No.", "Item Vendor"."Item No.");
            PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Vendor);
            PriceListLine.SetRange("Source No.", "Item Vendor"."Vendor No.");
            PriceListLine.SetFilter("Starting Date", '%1..%2', 0D, WorkDate());
            if PriceListLine.FindLast() then begin
                StartingDate := PriceListLine."Starting Date";
                DirectUnitCost := PriceListLine."Direct Unit Cost";
            end;
        end;
    end;

    procedure WhichOrder() "Order": Integer
    var
        KeyString: Text[250];
    begin
        KeyString := "Item Vendor".CurrentKey;
        if CopyStr(KeyString, 1, StrLen("Item Vendor".FieldCaption("Item No."))) = "Item Vendor".FieldCaption("Item No.") then
            exit(1);
        if CopyStr(KeyString, 1, StrLen("Item Vendor".FieldCaption("Vendor No."))) = "Item Vendor".FieldCaption("Vendor No.") then
            exit(0);

        Error(Text000,
          "Item Vendor".TableCaption(),
          "Item Vendor".FieldCaption("Item No."),
          "Item Vendor".FieldCaption("Vendor No."));
    end;
}

