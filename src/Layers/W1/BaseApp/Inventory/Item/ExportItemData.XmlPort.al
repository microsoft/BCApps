// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;

xmlport 5801 "Export Item Data"
{
    Caption = 'Export/Import Item Data';
    DefaultFieldsValidation = false;
    FieldDelimiter = '<~>';
    FieldSeparator = '<;>';
    Format = VariableText;
    TextEncoding = UTF16;
    UseRequestPage = true;
    Direction = Both;
    FormatEvaluate = Xml;

    Permissions = tabledata "Item Ledger Entry" = rimd,
                  tabledata "Item Application Entry" = rimd,
                  tabledata "Value Entry" = rimd,
                  tabledata "Item Application Entry History" = rimd,
                  tabledata Microsoft.Manufacturing.Capacity."Capacity Ledger Entry" = rimd,
                  tabledata "Avg. Cost Adjmt. Entry Point" = rimd,
                  tabledata "Item Tracking Code" = rimd,
                  tabledata "Post Value Entry to G/L" = rimd,
                  tabledata "Inventory Period" = rimd,
                  tabledata "Item Register" = rimd,
                  tabledata "Inventory Adjmt. Entry (Order)" = rimd;

    schema
    {
        textelement(root)
        {
            XmlName = 'Root';
            tableelement(item; Item)
            {
                AutoSave = false;
                AutoUpdate = false;
                RequestFilterFields = "No.";
                XmlName = 'Item';
                fieldelement(Item_No; Item."No.")
                {
                }
                fieldelement(Item_No2; Item."No. 2")
                {
                }
                fieldelement(Item_BaseUnitofMeasure; Item."Base Unit of Measure")
                {
                }
                fieldelement(Item_PriceUnitConversion; Item."Price Unit Conversion")
                {
                }
                textelement(ItemType)
                {
                    XmlName = 'Item_Type';
                }
                fieldelement(Item_InventoryPostingGroup; Item."Inventory Posting Group")
                {
                }
                fieldelement(Item_UnitPrice; Item."Unit Price")
                {
                }
                fieldelement(Item_PriceProfitCalculation; Item."Price/Profit Calculation")
                {
                }
                fieldelement(Item_Profit; Item."Profit %")
                {
                }
                fieldelement(Item_CostingMethod; Item."Costing Method")
                {
                }
                fieldelement(Item_UnitCost; Item."Unit Cost")
                {
                }
                fieldelement(Item_StandardCost; Item."Standard Cost")
                {
                }
                fieldelement(Item_LastDirectCost; Item."Last Direct Cost")
                {
                }
                fieldelement(Item_IndirectCost; Item."Indirect Cost %")
                {
                }
                fieldelement(Item_CostisAdjusted; Item."Cost is Adjusted")
                {
                }
                fieldelement(Item_AllowOnlineAdjustment; Item."Allow Online Adjustment")
                {
                }
                fieldelement(Item_VendorNo; Item."Vendor No.")
                {
                }
                fieldelement(Item_VendorItemNo; Item."Vendor Item No.")
                {
                }
                fieldelement(Item_LeadTimeCalculation; Item."Lead Time Calculation")
                {
                }
                fieldelement(Item_ReorderPoint; Item."Reorder Point")
                {
                }
                fieldelement(Item_MaximumInventory; Item."Maximum Inventory")
                {
                }
                fieldelement(Item_ReorderQuantity; Item."Reorder Quantity")
                {
                }
                fieldelement(Item_UnitListPrice; Item."Unit List Price")
                {
                }
                fieldelement(Item_DutyDue; Item."Duty Due %")
                {
                }
                fieldelement(Item_DutyCode; Item."Duty Code")
                {
                }
                fieldelement(Item_GrossWeight; Item."Gross Weight")
                {
                }
                fieldelement(Item_NetWeight; Item."Net Weight")
                {
                }
                fieldelement(Item_UnitsperParcel; Item."Units per Parcel")
                {
                }
                fieldelement(Item_UnitVolume; Item."Unit Volume")
                {
                }
                fieldelement(Item_Durability; Item.Durability)
                {
                }
                fieldelement(Item_FreightType; Item."Freight Type")
                {
                }
                fieldelement(Item_TariffNo; Item."Tariff No.")
                {
                }
                fieldelement(Item_DutyUnitConversion; Item."Duty Unit Conversion")
                {
                }
                fieldelement(Item_CountryRegionPurchasedCode; Item."Country/Region Purchased Code")
                {
                }
                fieldelement(Item_BudgetQuantity; Item."Budget Quantity")
                {
                }
                fieldelement(Item_BudgetedAmount; Item."Budgeted Amount")
                {
                }
                fieldelement(Item_BudgetProfit; Item."Budget Profit")
                {
                }
                fieldelement(Item_Blocked; Item.Blocked)
                {
                }
                fieldelement(Item_SalesBlocked; Item."Sales Blocked")
                {
                }
                fieldelement(Item_ServiceBlocked; Item."Service Blocked")
                {
                }
                fieldelement(Item_PurchasingBlocked; Item."Purchasing Blocked")
                {
                }
                fieldelement(Item_LastDateModified; Item."Last Date Modified")
                {
                }
                fieldelement(Item_PriceIncludesVAT; Item."Price Includes VAT")
                {
                }
                fieldelement(Item_VATBusPostingGrPrice; Item."VAT Bus. Posting Gr. (Price)")
                {
                }
                fieldelement(Item_GenProdPostingGroup; Item."Gen. Prod. Posting Group")
                {
                }
                fieldelement(Item_CountryRegionofOriginCode; Item."Country/Region of Origin Code")
                {
                }
                fieldelement(Item_AutomaticExtTexts; Item."Automatic Ext. Texts")
                {
                }
                fieldelement(Item_NoSeries; Item."No. Series")
                {
                }
                fieldelement(Item_TaxGroupCode; Item."Tax Group Code")
                {
                }
                fieldelement(Item_VATProdPostingGroup; Item."VAT Prod. Posting Group")
                {
                }
                fieldelement(Item_Reserve; Item.Reserve)
                {
                }
                fieldelement(Item_GlobalDimension1Code; Item."Global Dimension 1 Code")
                {
                }
                fieldelement(Item_GlobalDimension2Code; Item."Global Dimension 2 Code")
                {
                }
                fieldelement(Item_AssemblyPolicy; Item."Assembly Policy")
                {
                }
                fieldelement(Item_LowLevelCode; Item."Low-Level Code")
                {
                }
                fieldelement(Item_LotSize; Item."Lot Size")
                {
                }
                fieldelement(Item_SerialNos; Item."Serial Nos.")
                {
                }
                fieldelement(Item_LastUnitCostCalcDate; Item."Last Unit Cost Calc. Date")
                {
                }
                fieldelement(Item_RolledupMaterialCost; Item."Rolled-up Material Cost")
                {
                }
                fieldelement(Item_RolledupCapacityCost; Item."Rolled-up Capacity Cost")
                {
                }
                fieldelement(Item_Scrap; Item."Scrap %")
                {
                }
                fieldelement(Item_InventoryValueZero; Item."Inventory Value Zero")
                {
                }
                fieldelement(Item_DiscreteOrderQuantity; Item."Discrete Order Quantity")
                {
                }
                fieldelement(Item_MinimumOrderQuantity; Item."Minimum Order Quantity")
                {
                }
                fieldelement(Item_MaximumOrderQuantity; Item."Maximum Order Quantity")
                {
                }
                fieldelement(Item_SafetyStockQuantity; Item."Safety Stock Quantity")
                {
                }
                fieldelement(Item_OrderMultiple; Item."Order Multiple")
                {
                }
                fieldelement(Item_SafetyLeadTime; Item."Safety Lead Time")
                {
                }
                fieldelement(Item_FlushingMethod; Item."Flushing Method")
                {
                }
                fieldelement(Item_ReplenishmentSystem; Item."Replenishment System")
                {
                }
                fieldelement(Item_RoundingPrecision; Item."Rounding Precision")
                {
                }
                fieldelement(Item_SalesUnitofMeasure; Item."Sales Unit of Measure")
                {
                }
                fieldelement(Item_PurchUnitofMeasure; Item."Purch. Unit of Measure")
                {
                }
                fieldelement(Item_TimeBucket; Item."Time Bucket")
                {
                }
                fieldelement(Item_LotAccumulationPeriod; Item."Lot Accumulation Period")
                {
                }
                fieldelement(Item_ReschedulingPeriod; Item."Rescheduling Period")
                {
                }
                fieldelement(Item_DampenerPeriod; Item."Dampener Period")
                {
                }
                fieldelement(Item_DampenerQuantity; Item."Dampener Quantity")
                {
                }
                fieldelement(Item_OverflowLevel; Item."Overflow Level")
                {
                }
                fieldelement(Item_ReorderingPolicy; Item."Reordering Policy")
                {
                }
                fieldelement(Item_IncludeInventory; Item."Include Inventory")
                {
                }
                fieldelement(Item_ManufacturingPolicy; Item."Manufacturing Policy")
                {
                }
                fieldelement(Item_ManufacturerCode; Item."Manufacturer Code")
                {
                }
                fieldelement(Item_ItemCategoryCode; Item."Item Category Code")
                {
                }
                fieldelement(Item_CreatedFromNonstockItem; Item."Created From Nonstock Item")
                {
                }
#if not CLEAN25
                fieldelement(Item_ServiceItemGroup; Item."Service Item Group")
                {
                }
#endif
                fieldelement(Item_ItemTrackingCode; Item."Item Tracking Code")
                {
                }
                fieldelement(Item_LotNos; Item."Lot Nos.")
                {
                }
                fieldelement(Item_ExpirationCalculation; Item."Expiration Calculation")
                {
                }
                fieldelement(Item_SpecialEquipmentCode; Item."Special Equipment Code")
                {
                }
                fieldelement(Item_PutawayTemplateCode; Item."Put-away Template Code")
                {
                }
                fieldelement(Item_PutawayUnitofMeasureCode; Item."Put-away Unit of Measure Code")
                {
                }
                fieldelement(Item_PhysInvtCountingPeriodCode; Item."Phys Invt Counting Period Code")
                {
                }
                fieldelement(Item_LastCountingPeriodUpdate; Item."Last Counting Period Update")
                {
                }
                fieldelement(Item_UseCrossDocking; Item."Use Cross-Docking")
                {
                }
                fieldelement(Item_SingleLevelMaterialCost; Item."Single-Level Material Cost")
                {
                }
                fieldelement(Item_SingleLevelCapacityCost; Item."Single-Level Capacity Cost")
                {
                }
                fieldelement(Item_SingleLevelSubcontrdCost; Item."Single-Level Subcontrd. Cost")
                {
                }
                fieldelement(Item_SingleLevelCapOvhdCost; Item."Single-Level Cap. Ovhd Cost")
                {
                }
                fieldelement(Item_SingleLevelMfgOvhdCost; Item."Single-Level Mfg. Ovhd Cost")
                {
                }
                fieldelement(Item_OverheadRate; Item."Overhead Rate")
                {
                }
                fieldelement(Item_OrderTrackingPolicy; Item."Order Tracking Policy")
                {
                }
                fieldelement(Item_ProdForecastQuantityBase; Item."Prod. Forecast Quantity (Base)")
                {
                }
                fieldelement(Item_ProductionForecastName; Item."Production Forecast Name")
                {
                }
                fieldelement(Item_ComponentForecast; Item."Component Forecast")
                {
                }
                fieldelement(Item_Critical; Item.Critical)
                {
                }
                fieldelement(Item_CommonItemNo; Item."Common Item No.")
                {
                }
                fieldelement(Item_VariantMandatoryIfExists; Item."Variant Mandatory if Exists")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Item.Description := CopyStr(Item.Description, 1, MaxStrLen(Item.Description));
                    Item."Search Description" := CopyStr(Item."Search Description", 1, MaxStrLen(Item."Search Description"));

                    if ItemTypeFieldExists then begin
                        ItemRecRef.GetTable(Item);
                        TypeFieldRef := ItemRecRef.Field(10);
                        ItemTypeInt := TypeFieldRef.Value();
                        ItemType := Format(ItemTypeInt);
                        Clear(ItemRecRef);
                    end;
                end;

                trigger OnPreXmlItem()
                begin
                    if not currXMLport.ImportFile() then begin
                        if Item.Count <> 1 then
                            Error(SingleItemExportOnlyErr);

                        Item.FindFirst();
                        Item.Reset();
                        Item.SetRecFilter();
                        FilteredItem.Copy(Item);
                    end;
                end;

                trigger OnAfterInsertRecord()
                begin
                    if not Item.Insert() then
                        Item.Modify();
                end;

                trigger OnBeforeInsertRecord()
                begin
                    if currXMLport.ImportFile() then begin
                        Item.Reset();
                        Item.SetRecFilter();
                        FilteredItem.Copy(Item);
                    end;

                    if ItemTypeFieldExists and (ItemType <> '') then begin
                        ItemRecRef.GetTable(Item);
                        TypeFieldRef := ItemRecRef.Field(10);
                        Evaluate(ItemTypeInt, ItemType);
                        TypeFieldRef.Value := ItemTypeInt;
                        ItemRecRef.SetTable(Item);
                        Clear(ItemRecRef);
                    end;
                end;
            }
            tableelement(unitofmeasure; "Unit of Measure")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'UnitOfMeasure';
                SourceTableView = sorting(Code);
                fieldelement(UnitOfMeasure_Code; UnitOfMeasure.Code)
                {
                }
                fieldelement(UnitOfMeasure_Description; UnitOfMeasure.Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not ItemUnitOfMeasure.Get(FilteredItem."No.", UnitOfMeasure.Code) then
                        currXMLport.Skip();
                end;
            }
            tableelement(itemunitofmeasure; "Item Unit of Measure")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'ItemUnitOfMeasure';
                SourceTableView = sorting("Item No.", Code);
                fieldelement(ItemUnitOfMeasure_ItemNo; ItemUnitOfMeasure."Item No.")
                {
                }
                fieldelement(ItemUnitOfMeasure_Code; ItemUnitOfMeasure.Code)
                {
                }
                fieldelement(ItemUnitOfMeasure_QtyperUnitofMeasure; ItemUnitOfMeasure."Qty. per Unit of Measure")
                {
                }
                fieldelement(ItemUnitOfMeasure_Length; ItemUnitOfMeasure.Length)
                {
                }
                fieldelement(ItemUnitOfMeasure_Width; ItemUnitOfMeasure.Width)
                {
                }
                fieldelement(ItemUnitOfMeasure_Height; ItemUnitOfMeasure.Height)
                {
                }
                fieldelement(ItemUnitOfMeasure_Cubage; ItemUnitOfMeasure.Cubage)
                {
                }
                fieldelement(ItemUnitOfMeasure_Weight; ItemUnitOfMeasure.Weight)
                {
                }

                trigger OnPreXmlItem()
                begin
                    ItemUnitOfMeasure.SetRange("Item No.", FilteredItem."No.");
                end;
            }
            tableelement(genprodpostinggroup; "Gen. Product Posting Group")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'GenProdPostingGroup';
                SourceTableView = sorting(Code);
                fieldelement(GenProdPostingGroup_Code; GenProdPostingGroup.Code)
                {
                }
                fieldelement(GenProdPostingGroup_Description; GenProdPostingGroup.Description)
                {
                }
                fieldelement(GenProdPostingGroup_DefVATProdPostingGroup; GenProdPostingGroup."Def. VAT Prod. Posting Group")
                {
                }
                fieldelement(GenProdPostingGroup_AutoInsertDefault; GenProdPostingGroup."Auto Insert Default")
                {
                }
            }
            tableelement(genpostingsetup; "General Posting Setup")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'GenPostingSetup';
                SourceTableView = sorting("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                fieldelement(GenPostingSetup_GenBusPostingGroup; GenPostingSetup."Gen. Bus. Posting Group")
                {
                }
                fieldelement(GenPostingSetup_GenProdPostingGroup; GenPostingSetup."Gen. Prod. Posting Group")
                {
                }
            }
            tableelement(genbuspostinggroup; "Gen. Business Posting Group")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'GenBusPostingGroup';
                SourceTableView = sorting(Code);
                fieldelement(GenBusPostingGroup_Code; GenBusPostingGroup.Code)
                {
                }
                fieldelement(GenBusPostingGroup_Description; GenBusPostingGroup.Description)
                {
                }
                fieldelement(GenBusPostingGroup_DefVATBusPostingGroup; GenBusPostingGroup."Def. VAT Bus. Posting Group")
                {
                }
                fieldelement(GenBusPostingGroup_AutoInsertDefault; GenBusPostingGroup."Auto Insert Default")
                {
                }
            }
            tableelement(vatprodpostinggroup; "VAT Product Posting Group")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'VatProdPostingGroup';
                SourceTableView = sorting(Code);
                fieldelement(VatProdPostingGroup_Code; VATProdPostingGroup.Code)
                {
                }
                fieldelement(VatProdPostingGroup_Description; VATProdPostingGroup.Description)
                {
                }
            }
            tableelement(vatpostingsetup; "VAT Posting Setup")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'VATPostingSetup';
                SourceTableView = sorting("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                fieldelement(VATPostingSetup_VATBusPostingGroup; VATPostingSetup."VAT Bus. Posting Group")
                {
                }
                fieldelement(VATPostingSetup_VATProdPostingGroup; VATPostingSetup."VAT Prod. Posting Group")
                {
                }
            }
            tableelement(inventorypostinggroup; "Inventory Posting Group")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'InventoryPostingGroup';
                SourceTableView = sorting(Code);
                fieldelement(InventoryPostingGroup_Code; InventoryPostingGroup.Code)
                {
                }
                fieldelement(InventoryPostingGroup_Description; InventoryPostingGroup.Description)
                {
                }
            }
            tableelement(inventorypostingsetup; "Inventory Posting Setup")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'InventoryPostingSetup';
                SourceTableView = sorting("Location Code", "Invt. Posting Group Code");
                fieldelement(InventoryPostingSetup_LocationCode; InventoryPostingSetup."Location Code")
                {
                }
                fieldelement(InventoryPostingSetup_InvtPostingGroupCode; InventoryPostingSetup."Invt. Posting Group Code")
                {
                }

                trigger OnAfterGetRecord()
                var
                    ItemLedgEntry2: Record "Item Ledger Entry";
                begin
                    ItemLedgEntry2.SetCurrentKey("Item No.");
                    ItemLedgEntry2.SetRange("Item No.", FilteredItem."No.");
                    ItemLedgEntry2.SetRange("Location Code", InventoryPostingSetup."Location Code");
                    if ItemLedgEntry2.IsEmpty() then
                        currXMLport.Skip();
                end;
            }
            tableelement(itemledgentry; "Item Ledger Entry")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'ItemLedgEntry';
                SourceTableView = sorting("Item No.");
                fieldelement(ItemLedgEntry_EntryNo; ItemLedgEntry."Entry No.")
                {
                }
                fieldelement(ItemLedgEntry_ItemNo; ItemLedgEntry."Item No.")
                {
                }
                fieldelement(ItemLedgEntry_PostingDate; ItemLedgEntry."Posting Date")
                {
                }
                fieldelement(ItemLedgEntry_EntryType; ItemLedgEntry."Entry Type")
                {
                }
                fieldelement(ItemLedgEntry_SourceNo; ItemLedgEntry."Source No.")
                {
                }
                fieldelement(ItemLedgEntry_DocumentNo; ItemLedgEntry."Document No.")
                {
                }
                fieldelement(ItemLedgEntry_Description; ItemLedgEntry.Description)
                {
                }
                fieldelement(ItemLedgEntry_LocationCode; ItemLedgEntry."Location Code")
                {
                }
                fieldelement(ItemLedgEntry_Quantity; ItemLedgEntry.Quantity)
                {
                }
                fieldelement(ItemLedgEntry_RemainingQuantity; ItemLedgEntry."Remaining Quantity")
                {
                }
                fieldelement(ItemLedgEntry_InvoicedQuantity; ItemLedgEntry."Invoiced Quantity")
                {
                }
                fieldelement(ItemLedgEntry_AppliestoEntry; ItemLedgEntry."Applies-to Entry")
                {
                }
                fieldelement(ItemLedgEntry_Open; ItemLedgEntry.Open)
                {
                }
                fieldelement(ItemLedgEntry_GlobalDimension1Code; ItemLedgEntry."Global Dimension 1 Code")
                {
                }
                fieldelement(ItemLedgEntry_GlobalDimension2Code; ItemLedgEntry."Global Dimension 2 Code")
                {
                }
                fieldelement(ItemLedgEntry_Positive; ItemLedgEntry.Positive)
                {
                }
                fieldelement(ItemLedgEntry_SourceType; ItemLedgEntry."Source Type")
                {
                }
                fieldelement(ItemLedgEntry_DropShipment; ItemLedgEntry."Drop Shipment")
                {
                }
                fieldelement(ItemLedgEntry_TransactionType; ItemLedgEntry."Transaction Type")
                {
                }
                fieldelement(ItemLedgEntry_TransportMethod; ItemLedgEntry."Transport Method")
                {
                }
                fieldelement(ItemLedgEntry_CountryRegionCode; ItemLedgEntry."Country/Region Code")
                {
                }
                fieldelement(ItemLedgEntry_EntryExitPoint; ItemLedgEntry."Entry/Exit Point")
                {
                }
                fieldelement(ItemLedgEntry_DocumentDate; ItemLedgEntry."Document Date")
                {
                }
                fieldelement(ItemLedgEntry_ExternalDocumentNo; ItemLedgEntry."External Document No.")
                {
                }
                fieldelement(ItemLedgEntry_Area; ItemLedgEntry."Area")
                {
                }
                fieldelement(ItemLedgEntry_TransactionSpecification; ItemLedgEntry."Transaction Specification")
                {
                }
                fieldelement(ItemLedgEntry_NoSeries; ItemLedgEntry."No. Series")
                {
                }
                fieldelement(ItemLedgEntry_ReservedQuantity; ItemLedgEntry."Reserved Quantity")
                {
                }
                fieldelement(ItemLedgEntry_DocumentType; ItemLedgEntry."Document Type")
                {
                }
                fieldelement(ItemLedgEntry_DocumentLineNo; ItemLedgEntry."Document Line No.")
                {
                }
                fieldelement(ItemLedgEntry_OrderType; ItemLedgEntry."Order Type")
                {
                }
                fieldelement(ItemLedgEntry_OrderNo; ItemLedgEntry."Order No.")
                {
                }
                fieldelement(ItemLedgEntry_OrderLineNo; ItemLedgEntry."Order Line No.")
                {
                }
                fieldelement(ItemLedgEntry_AssembleToOrder; ItemLedgEntry."Assemble to Order")
                {
                }
                fieldelement(ItemLedgEntry_VariantCode; ItemLedgEntry."Variant Code")
                {
                }
                fieldelement(ItemLedgEntry_QtyperUnitofMeasure; ItemLedgEntry."Qty. per Unit of Measure")
                {
                }
                fieldelement(ItemLedgEntry_UnitofMeasureCode; ItemLedgEntry."Unit of Measure Code")
                {
                }
                fieldelement(ItemLedgEntry_DerivedfromBlanketOrder; ItemLedgEntry."Derived from Blanket Order")
                {
                }
                fieldelement(ItemLedgEntry_ItemReferenceNo; ItemLedgEntry."Item Reference No.")
                {
                }
                fieldelement(ItemLedgEntry_OriginallyOrderedNo; ItemLedgEntry."Originally Ordered No.")
                {
                }
                fieldelement(ItemLedgEntry_OriginallyOrderedVarCode; ItemLedgEntry."Originally Ordered Var. Code")
                {
                }
                fieldelement(ItemLedgEntry_OutofStockSubstitution; ItemLedgEntry."Out-of-Stock Substitution")
                {
                }
                fieldelement(ItemLedgEntry_ItemCategoryCode; ItemLedgEntry."Item Category Code")
                {
                }
                fieldelement(ItemLedgEntry_Nonstock; ItemLedgEntry.Nonstock)
                {
                }
                fieldelement(ItemLedgEntry_PurchasingCode; ItemLedgEntry."Purchasing Code")
                {
                }
                fieldelement(ItemLedgEntry_CompletelyInvoiced; ItemLedgEntry."Completely Invoiced")
                {
                }
                fieldelement(ItemLedgEntry_LastInvoiceDate; ItemLedgEntry."Last Invoice Date")
                {
                }
                fieldelement(ItemLedgEntry_AppliedEntrytoAdjust; ItemLedgEntry."Applied Entry to Adjust")
                {
                }
                fieldelement(ItemLedgEntry_Correction; ItemLedgEntry.Correction)
                {
                }
                fieldelement(ItemLedgEntry_ProdOrderCompLineNo; ItemLedgEntry."Prod. Order Comp. Line No.")
                {
                }
                fieldelement(ItemLedgEntry_SerialNo; ItemLedgEntry."Serial No.")
                {
                }
                fieldelement(ItemLedgEntry_LotNo; ItemLedgEntry."Lot No.")
                {
                }
                fieldelement(ItemLedgEntry_WarrantyDate; ItemLedgEntry."Warranty Date")
                {
                }
                fieldelement(ItemLedgEntry_ExpirationDate; ItemLedgEntry."Expiration Date")
                {
                }
                fieldelement(ItemLedgEntry_ReturnReasonCode; ItemLedgEntry."Return Reason Code")
                {
                }
                fieldelement(ItemLedgEntry_DocumentType; ItemLedgEntry."Document Type")
                {
                }
                fieldelement(ItemLedgEntry_DocumentLineNo; ItemLedgEntry."Document Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CollectItemApplnEntry(ItemLedgEntry."Entry No.");
                    CollectItemApplnEntryHist(ItemLedgEntry."Entry No.");
                end;

                trigger OnPreXmlItem()
                begin
                    ItemLedgEntry.SetRange("Item No.", FilteredItem."No.");
                end;

                trigger OnBeforeInsertRecord()
                var
                    ItemLedgEntry2: Record "Item Ledger Entry";
                begin
                    if ItemLedgEntry2.Get(ItemLedgEntry."Entry No.") and (ItemLedgEntry2."Item No." <> ItemLedgEntry."Item No.") then
                        Error(ItemLedgEntryNoExistErr, ItemLedgEntry."Entry No.");
                end;
            }
            tableelement(tempitemapplnentry; "Item Application Entry")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'ItemApplnEntry';
                SourceTableView = sorting("Entry No.");
                UseTemporary = true;
                fieldelement(ItemApplnEntry_EntryNo; TempItemApplnEntry."Entry No.")
                {
                }
                fieldelement(ItemApplnEntry_ItemLedgerEntryNo; TempItemApplnEntry."Item Ledger Entry No.")
                {
                }
                fieldelement(ItemApplnEntry_InboundItemEntryNo; TempItemApplnEntry."Inbound Item Entry No.")
                {
                }
                fieldelement(ItemApplnEntry_OutboundItemEntryNo; TempItemApplnEntry."Outbound Item Entry No.")
                {
                }
                fieldelement(ItemApplnEntry_Quantity; TempItemApplnEntry.Quantity)
                {
                }
                fieldelement(ItemApplnEntry_PostingDate; TempItemApplnEntry."Posting Date")
                {
                }
                fieldelement(ItemApplnEntry_TransferredFromEntryNo; TempItemApplnEntry."Transferred-from Entry No.")
                {
                }
                fieldelement(ItemApplnEntry_CreationDate; TempItemApplnEntry."Creation Date")
                {
                }
                fieldelement(ItemApplnEntry_LastModifiedDate; TempItemApplnEntry."Last Modified Date")
                {
                }
                fieldelement(ItemApplnEntry_CostApplication; TempItemApplnEntry."Cost Application")
                {
                }
                fieldelement(ItemApplnEntry_OutputCompletelyInvdDate; TempItemApplnEntry."Output Completely Invd. Date")
                {
                }
                fieldelement(ItemApplnEntry_OutputEntryIsUpdated; TempItemApplnEntry."Outbound Entry is Updated")
                {
                }

                trigger OnAfterInsertRecord()
                var
                    ItemApplnEntry2: Record "Item Application Entry";
                begin
                    ItemApplnEntry2 := TempItemApplnEntry;
                    if not ItemApplnEntry2.Insert() then
                        ItemApplnEntry2.Modify();
                end;
            }
            tableelement(valueentry; "Value Entry")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'ValueEntry';
                SourceTableView = sorting("Item No.");
                fieldelement(ValueEntry_EntryNo; ValueEntry."Entry No.")
                {
                }
                fieldelement(ValueEntry_ItemNo; ValueEntry."Item No.")
                {
                }
                fieldelement(ValueEntry_PostingDate; ValueEntry."Posting Date")
                {
                }
                fieldelement(ValueEntry_ItemLedgerEntryType; ValueEntry."Item Ledger Entry Type")
                {
                }
                fieldelement(ValueEntry_SourceNo; ValueEntry."Source No.")
                {
                }
                fieldelement(ValueEntry_DocumentNo; ValueEntry."Document No.")
                {
                }
                fieldelement(ValueEntry_Description; ValueEntry.Description)
                {
                }
                fieldelement(ValueEntry_LocationCode; ValueEntry."Location Code")
                {
                }
                fieldelement(ValueEntry_InventoryPostingGroup; ValueEntry."Inventory Posting Group")
                {
                }
                fieldelement(ValueEntry_SourcePostingGroup; ValueEntry."Source Posting Group")
                {
                }
                fieldelement(ValueEntry_ItemLedgerEntryNo; ValueEntry."Item Ledger Entry No.")
                {
                }
                fieldelement(ValueEntry_ValuedQuantity; ValueEntry."Valued Quantity")
                {
                }
                fieldelement(ValueEntry_ItemLedgerEntryQuantity; ValueEntry."Item Ledger Entry Quantity")
                {
                }
                fieldelement(ValueEntry_InvoicedQuantity; ValueEntry."Invoiced Quantity")
                {
                }
                fieldelement(ValueEntry_CostperUnit; ValueEntry."Cost per Unit")
                {
                }
                fieldelement(ValueEntry_SalesAmountActual; ValueEntry."Sales Amount (Actual)")
                {
                }
                fieldelement(ValueEntry_DiscountAmount; ValueEntry."Discount Amount")
                {
                }
                fieldelement(ValueEntry_SourceCode; ValueEntry."Source Code")
                {
                }
                fieldelement(ValueEntry_AppliestoEntry; ValueEntry."Applies-to Entry")
                {
                }
                fieldelement(ValueEntry_GlobalDimension1Code; ValueEntry."Global Dimension 1 Code")
                {
                }
                fieldelement(ValueEntry_GlobalDimension2Code; ValueEntry."Global Dimension 2 Code")
                {
                }
                fieldelement(ValueEntry_SourceType; ValueEntry."Source Type")
                {
                }
                fieldelement(ValueEntry_CostAmountActual; ValueEntry."Cost Amount (Actual)")
                {
                }
                fieldelement(ValueEntry_CostPostedtoGL; ValueEntry."Cost Posted to G/L")
                {
                }
                fieldelement(ValueEntry_ReasonCode; ValueEntry."Reason Code")
                {
                }
                fieldelement(ValueEntry_DropShipment; ValueEntry."Drop Shipment")
                {
                }
                fieldelement(ValueEntry_JournalBatchName; ValueEntry."Journal Batch Name")
                {
                }
                fieldelement(ValueEntry_GenBusPostingGroup; ValueEntry."Gen. Bus. Posting Group")
                {
                }
                fieldelement(ValueEntry_GenProdPostingGroup; ValueEntry."Gen. Prod. Posting Group")
                {
                }
                fieldelement(ValueEntry_DocumentDate; ValueEntry."Document Date")
                {
                }
                fieldelement(ValueEntry_ExternalDocumentNo; ValueEntry."External Document No.")
                {
                }
                fieldelement(ValueEntry_CostAmountActualACY; ValueEntry."Cost Amount (Actual) (ACY)")
                {
                }
                fieldelement(ValueEntry_CostPostedtoGLACY; ValueEntry."Cost Posted to G/L (ACY)")
                {
                }
                fieldelement(ValueEntry_CostperUnitACY; ValueEntry."Cost per Unit (ACY)")
                {
                }
                fieldelement(ValueEntry_DocumentType; ValueEntry."Document Type")
                {
                }
                fieldelement(ValueEntry_DocumentLineNo; ValueEntry."Document Line No.")
                {
                }
                fieldelement(ValueEntry_OrderType; ValueEntry."Order Type")
                {
                }
                fieldelement(ValueEntry_OrderNo; ValueEntry."Order No.")
                {
                }
                fieldelement(ValueEntry_OrderLineNo; ValueEntry."Order Line No.")
                {
                }
                fieldelement(ValueEntry_ExpectedCost; ValueEntry."Expected Cost")
                {
                }
                fieldelement(ValueEntry_ItemChargeNo; ValueEntry."Item Charge No.")
                {
                }
                fieldelement(ValueEntry_ValuedByAverageCost; ValueEntry."Valued By Average Cost")
                {
                }
                fieldelement(ValueEntry_PartialRevaluation; ValueEntry."Partial Revaluation")
                {
                }
                fieldelement(ValueEntry_Inventoriable; ValueEntry.Inventoriable)
                {
                }
                fieldelement(ValueEntry_ValuationDate; ValueEntry."Valuation Date")
                {
                }
                fieldelement(ValueEntry_EntryType; ValueEntry."Entry Type")
                {
                }
                fieldelement(ValueEntry_VarianceType; ValueEntry."Variance Type")
                {
                }
                fieldelement(ValueEntry_PurchaseAmountActual; ValueEntry."Purchase Amount (Actual)")
                {
                }
                fieldelement(ValueEntry_PurchaseAmountExpected; ValueEntry."Purchase Amount (Expected)")
                {
                }
                fieldelement(ValueEntry_SalesAmountExpected; ValueEntry."Sales Amount (Expected)")
                {
                }
                fieldelement(ValueEntry_CostAmountExpected; ValueEntry."Cost Amount (Expected)")
                {
                }
                fieldelement(ValueEntry_CostAmountNonInvtbl; ValueEntry."Cost Amount (Non-Invtbl.)")
                {
                }
                fieldelement(ValueEntry_CostAmountExpectedACY; ValueEntry."Cost Amount (Expected) (ACY)")
                {
                }
                fieldelement(ValueEntry_CostAmountNonInvtblACY; ValueEntry."Cost Amount (Non-Invtbl.)(ACY)")
                {
                }
                fieldelement(ValueEntry_ExpectedCostPostedtoGL; ValueEntry."Expected Cost Posted to G/L")
                {
                }
                fieldelement(ValueEntry_ExpCostPostedtoGLACY; ValueEntry."Exp. Cost Posted to G/L (ACY)")
                {
                }
                fieldelement(ValueEntry_VariantCode; ValueEntry."Variant Code")
                {
                }
                fieldelement(ValueEntry_Adjustment; ValueEntry.Adjustment)
                {
                }
                fieldelement(ValueEntry_CapacityLedgerEntryNo; ValueEntry."Capacity Ledger Entry No.")
                {
                }
                fieldelement(ValueEntry_Type; ValueEntry.Type)
                {
                    trigger OnAfterAssignField()
                    begin
                        if ValueEntry.Type = ValueEntry.Type::"Work Center" then
                            if not (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Output,
                                                                            ValueEntry."Item Ledger Entry Type"::" "])
                            then
                                ValueEntry.Type := ValueEntry.Type::" ";
                    end;
                }
                fieldelement(ValueEntry_No; ValueEntry."No.")
                {
                }
                fieldelement(ValueEntry_ReturnReasonCode; ValueEntry."Return Reason Code")
                {
                }
                fieldelement(ValueEntry_DocumentType; ValueEntry."Document Type")
                {
                }
                fieldelement(ValueEntry_DocumentLineNo; ValueEntry."Document Line No.")
                {
                }
                fieldelement(ValueEntry_CapacityLedgerEntryNo; ValueEntry."Capacity Ledger Entry No.")
                {
                }

                trigger OnPreXmlItem()
                begin
                    ValueEntry.SetRange("Item No.", FilteredItem."No.");
                end;
            }
            tableelement(location; Location)
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'Location';
                SourceTableView = sorting(Code);
                fieldelement(Location_Code; Location.Code)
                {
                }
                fieldelement(Location_Name; Location.Name)
                {
                }
                fieldelement(Location_CountryRegionCode; Location."Country/Region Code")
                {
                }
                fieldelement(Location_UseAsInTransit; Location."Use As In-Transit")
                {
                }
                fieldelement(Location_RequirePutaway; Location."Require Put-away")
                {
                }
                fieldelement(Location_RequirePick; Location."Require Pick")
                {
                }
                fieldelement(Location_CrossDockDueDateCalc; Location."Cross-Dock Due Date Calc.")
                {
                }
                fieldelement(Location_UseCrossDocking; Location."Use Cross-Docking")
                {
                }
                fieldelement(Location_RequireReceive; Location."Require Receive")
                {
                }
                fieldelement(Location_RequireShipment; Location."Require Shipment")
                {
                }
                fieldelement(Location_BinMandatory; Location."Bin Mandatory")
                {
                }
                fieldelement(Location_DirectedPutawayandPick; Location."Directed Put-away and Pick")
                {
                }
                fieldelement(Location_DefaultBinSelection; Location."Default Bin Selection")
                {
                }
                fieldelement(Location_OutboundWhseHandlingTime; Location."Outbound Whse. Handling Time")
                {
                }
                fieldelement(Location_InboundWhseHandlingTime; Location."Inbound Whse. Handling Time")
                {
                }

                trigger OnAfterGetRecord()
                var
                    ItemLedgEntry2: Record "Item Ledger Entry";
                begin
                    ItemLedgEntry2.SetCurrentKey("Item No.");
                    ItemLedgEntry2.SetRange("Item No.", FilteredItem."No.");
                    ItemLedgEntry2.SetRange("Location Code", Location.Code);
                    if ItemLedgEntry2.IsEmpty() then
                        currXMLport.Skip();
                end;
            }
            tableelement(itemvariant; "Item Variant")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'ItemVariant';
                SourceTableView = sorting("Item No.", Code);
                fieldelement(ItemVariant_Code; ItemVariant.Code)
                {
                }
                fieldelement(ItemVariant_ItemNo; ItemVariant."Item No.")
                {
                }
                fieldelement(ItemVariant_Description; ItemVariant.Description)
                {
                }
                fieldelement(ItemVariant_Blocked; ItemVariant.Blocked)
                {
                }
                fieldelement(ItemVariant_SalesBlocked; ItemVariant."Sales Blocked")
                {
                }
                fieldelement(ItemVariant_ServiceBlocked; ItemVariant."Service Blocked")
                {
                }
                fieldelement(ItemVariant_PurchasingBlocked; ItemVariant."Purchasing Blocked")
                {
                }

                trigger OnPreXmlItem()
                begin
                    ItemVariant.SetRange("Item No.", FilteredItem."No.");
                end;
            }
            tableelement(avgcostadjmtentrypoint; "Avg. Cost Adjmt. Entry Point")
            {
                AutoSave = false;
                AutoUpdate = false;
                MinOccurs = Zero;
                XmlName = 'AvgCostAdjmtEntryPoint';
                SourceTableView = sorting("Item No.");
                fieldelement(AvgCostAdjmtEntryPoint_ItemNo; AvgCostAdjmtEntryPoint."Item No.")
                {
                }
                fieldelement(AvgCostAdjmtEntryPoint_VariantCode; AvgCostAdjmtEntryPoint."Variant Code")
                {
                }
                fieldelement(AvgCostAdjmtEntryPoint_LocationCode; AvgCostAdjmtEntryPoint."Location Code")
                {
                }
                fieldelement(AvgCostAdjmtEntryPoint_ValuationDate; AvgCostAdjmtEntryPoint."Valuation Date")
                {
                }
                fieldelement(AvgCostAdjmtEntryPoint_CostIsAdjusted; AvgCostAdjmtEntryPoint."Cost Is Adjusted")
                {
                }

                trigger OnPreXmlItem()
                begin
                    AvgCostAdjmtEntryPoint.SetRange("Item No.", FilteredItem."No.");
                end;

                trigger OnBeforeInsertRecord()
                begin
                    if not AvgCostAdjmtEntryPoint.Insert() then
                        AvgCostAdjmtEntryPoint.Modify();
                end;
            }
            tableelement(itemtrackingcode; "Item Tracking Code")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'ItemTrackingCode';
                SourceTableView = sorting(Code);
                fieldelement(ItemTrackingCode_Code; ItemTrackingCode.Code)
                {
                }
                fieldelement(ItemTrackingCode_Description; ItemTrackingCode.Description)
                {
                }
                fieldelement(ItemTrackingCode_WarrantyDateFormula; ItemTrackingCode."Warranty Date Formula")
                {
                }
                fieldelement(ItemTrackingCode_ManWarrantyDateEntryReqd; ItemTrackingCode."Man. Warranty Date Entry Reqd.")
                {
                }
                fieldelement(ItemTrackingCode_ManExpirDateEntryReqd; ItemTrackingCode."Man. Expir. Date Entry Reqd.")
                {
                }
                fieldelement(ItemTrackingCode_StrictExpirationPosting; ItemTrackingCode."Strict Expiration Posting")
                {
                }
                fieldelement(ItemTrackingCode_SNSpecificTracking; ItemTrackingCode."SN Specific Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNInfoInboundMustExist; ItemTrackingCode."SN Info. Inbound Must Exist")
                {
                }
                fieldelement(ItemTrackingCode_SNInfoOutboundMustExist; ItemTrackingCode."SN Info. Outbound Must Exist")
                {
                }
                fieldelement(ItemTrackingCode_SNWarehouseTracking; ItemTrackingCode."SN Warehouse Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNPurchaseInboundTracking; ItemTrackingCode."SN Purchase Inbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNPurchaseOutboundTracking; ItemTrackingCode."SN Purchase Outbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNSalesInboundTracking; ItemTrackingCode."SN Sales Inbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNSalesOutboundTracking; ItemTrackingCode."SN Sales Outbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNPosAdjmtInbTracking; ItemTrackingCode."SN Pos. Adjmt. Inb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNPosAdjmtOutbTracking; ItemTrackingCode."SN Pos. Adjmt. Outb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNNegAdjmtInbTracking; ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNNegAdjmtOutbTracking; ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNTransferTracking; ItemTrackingCode."SN Transfer Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNAssemblyInboundTracking; ItemTrackingCode."SN Assembly Inbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_SNAssemblyOutboundTracking; ItemTrackingCode."SN Assembly Outbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotSpecificTracking; ItemTrackingCode."Lot Specific Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotInfoInboundMustExist; ItemTrackingCode."Lot Info. Inbound Must Exist")
                {
                }
                fieldelement(ItemTrackingCode_LotInfoOutboundMustExist; ItemTrackingCode."Lot Info. Outbound Must Exist")
                {
                }
                fieldelement(ItemTrackingCode_LotWarehouseTracking; ItemTrackingCode."Lot Warehouse Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotPurchaseInboundTracking; ItemTrackingCode."Lot Purchase Inbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotPurchaseOutboundTracking; ItemTrackingCode."Lot Purchase Outbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotSalesInboundTracking; ItemTrackingCode."Lot Sales Inbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotSalesOutboundTracking; ItemTrackingCode."Lot Sales Outbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotPosAdjmtInbTracking; ItemTrackingCode."Lot Pos. Adjmt. Inb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotPosAdjmtOutbTracking; ItemTrackingCode."Lot Pos. Adjmt. Outb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotNegAdjmtInbTracking; ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotNegAdjmtOutbTracking; ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotTransferTracking; ItemTrackingCode."Lot Transfer Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotAssemblyInboundTracking; ItemTrackingCode."Lot Assembly Inbound Tracking")
                {
                }
                fieldelement(ItemTrackingCode_LotAssemblyOutboundTracking; ItemTrackingCode."Lot Assembly Outbound Tracking")
                {
                }

                trigger OnPreXmlItem()
                begin
                    ItemTrackingCode.SetRange(Code, FilteredItem."Item Tracking Code");
                end;
            }
            tableelement(inventorysetup; "Inventory Setup")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'InventorySetup';
                SourceTableView = sorting("Primary Key");
                fieldelement(InventorySetup_PrimaryKey; InventorySetup."Primary Key")
                {
                }
                fieldelement(InventorySetup_AutomaticCostPosting; InventorySetup."Automatic Cost Posting")
                {
                }
                fieldelement(InventorySetup_LocationMandatory; InventorySetup."Location Mandatory")
                {
                }
                fieldelement(InventorySetup_VariantMandatoryIfExists; InventorySetup."Variant Mandatory if Exists")
                {
                }
                fieldelement(InventorySetup_AutomaticCostAdjustment; InventorySetup."Automatic Cost Adjustment")
                {
                }
                fieldelement(InventorySetup_OutboundWhseHandlingTime; InventorySetup."Outbound Whse. Handling Time")
                {
                }
                fieldelement(InventorySetup_InboundWhseHandlingTime; InventorySetup."Inbound Whse. Handling Time")
                {
                }
                fieldelement(InventorySetup_ExpectedCostPostingtoGL; InventorySetup."Expected Cost Posting to G/L")
                {
                }
                fieldelement(InventorySetup_AverageCostCalcType; InventorySetup."Average Cost Calc. Type")
                {
                }
                fieldelement(InventorySetup_AverageCostPeriod; InventorySetup."Average Cost Period")
                {
                }
            }
            tableelement(capledgentry; Microsoft.Manufacturing.Capacity."Capacity Ledger Entry")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'CapLedgEntry';
                SourceTableView = sorting("Entry No.");
                fieldelement(CapLedgEntry_EntryNo; CapLedgEntry."Entry No.")
                {
                }
                fieldelement(CapLedgEntry_No; CapLedgEntry."No.")
                {
                }
                fieldelement(CapLedgEntry_PostingDate; CapLedgEntry."Posting Date")
                {
                }
                fieldelement(CapLedgEntry_Type; CapLedgEntry.Type)
                {
                }
                fieldelement(CapLedgEntry_DocumentNo; CapLedgEntry."Document No.")
                {
                }
                fieldelement(CapLedgEntry_Description; CapLedgEntry.Description)
                {
                }
                fieldelement(CapLedgEntry_Quantity; CapLedgEntry.Quantity)
                {
                }
                fieldelement(CapLedgEntry_InvoicedQuantity; CapLedgEntry."Invoiced Quantity")
                {
                }
                fieldelement(CapLedgEntry_CapUnitofMeasureCode; CapLedgEntry."Cap. Unit of Measure Code")
                {
                }
                fieldelement(CapLedgEntry_QtyperCapUnitofMeasure; CapLedgEntry."Qty. per Cap. Unit of Measure")
                {
                }
                fieldelement(CapLedgEntry_GlobalDimension1Code; CapLedgEntry."Global Dimension 1 Code")
                {
                }
                fieldelement(CapLedgEntry_GlobalDimension2Code; CapLedgEntry."Global Dimension 2 Code")
                {
                }
                fieldelement(CapLedgEntry_CompletelyInvoiced; CapLedgEntry."Completely Invoiced")
                {
                }
                fieldelement(CapLedgEntry_ItemNo; CapLedgEntry."Item No.")
                {
                }
                fieldelement(CapLedgEntry_VariantCode; CapLedgEntry."Variant Code")
                {
                }
                fieldelement(CapLedgEntry_UnitofMeasureCode; CapLedgEntry."Unit of Measure Code")
                {
                }
                fieldelement(CapLedgEntry_QtyperUnitofMeasure; CapLedgEntry."Qty. per Unit of Measure")
                {
                }
                fieldelement(CapLedgEntry_DocumentDate; CapLedgEntry."Document Date")
                {
                }
                fieldelement(CapLedgEntry_ExternalDocumentNo; CapLedgEntry."External Document No.")
                {
                }
                fieldelement(CapLedgEntry_DirectCost; CapLedgEntry."Direct Cost")
                {
                }
                fieldelement(CapLedgEntry_OverheadCost; CapLedgEntry."Overhead Cost")
                {
                }
                fieldelement(CapLedgEntry_DirectCostACY; CapLedgEntry."Direct Cost (ACY)")
                {
                }
                fieldelement(CapLedgEntry_OverheadCostACY; CapLedgEntry."Overhead Cost (ACY)")
                {
                }
                fieldelement(CapLedgEntry_Subcontracting; CapLedgEntry.Subcontracting)
                {
                }
                fieldelement(CapLedgEntry_OrderType; CapLedgEntry."Order Type")
                {
                }
                fieldelement(CapLedgEntry_OrderNo; CapLedgEntry."Order No.")
                {
                }
                fieldelement(CapLedgEntry_OrderLineNo; CapLedgEntry."Order Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CollectCapValueEntry(CapLedgEntry."Entry No.");
                end;

                trigger OnPreXmlItem()
                begin
                    CapLedgEntry.SetRange("Item No.", FilteredItem."No.");
                end;
            }
            tableelement(tempcapvalueentry; "Value Entry")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'CapValueEntry';
                SourceTableView = sorting("Entry No.");
                UseTemporary = true;
                fieldelement(CapValueEntry_EntryNo; TempCapValueEntry."Entry No.")
                {
                }
                fieldelement(CapValueEntry_ItemNo; TempCapValueEntry."Item No.")
                {
                }
                fieldelement(CapValueEntry_PostingDate; TempCapValueEntry."Posting Date")
                {
                }
                fieldelement(CapValueEntry_ItemLedgerEntryType; TempCapValueEntry."Item Ledger Entry Type")
                {
                }
                fieldelement(CapValueEntry_SourceNo; TempCapValueEntry."Source No.")
                {
                }
                fieldelement(CapValueEntry_DocumentNo; TempCapValueEntry."Document No.")
                {
                }
                fieldelement(CapValueEntry_Description; TempCapValueEntry.Description)
                {
                }
                fieldelement(CapValueEntry_LocationCode; TempCapValueEntry."Location Code")
                {
                }
                fieldelement(CapValueEntry_InventoryPostingGroup; TempCapValueEntry."Inventory Posting Group")
                {
                }
                fieldelement(CapValueEntry_SourcePostingGroup; TempCapValueEntry."Source Posting Group")
                {
                }
                fieldelement(CapValueEntry_ItemLedgerEntryNo; TempCapValueEntry."Item Ledger Entry No.")
                {
                }
                fieldelement(CapValueEntry_ValuedQuantity; TempCapValueEntry."Valued Quantity")
                {
                }
                fieldelement(CapValueEntry_ItemLedgerEntryQuantity; TempCapValueEntry."Item Ledger Entry Quantity")
                {
                }
                fieldelement(CapValueEntry_InvoicedQuantity; TempCapValueEntry."Invoiced Quantity")
                {
                }
                fieldelement(CapValueEntry_CostperUnit; TempCapValueEntry."Cost per Unit")
                {
                }
                fieldelement(CapValueEntry_SalesAmountActual; TempCapValueEntry."Sales Amount (Actual)")
                {
                }
                fieldelement(CapValueEntry_DiscountAmount; TempCapValueEntry."Discount Amount")
                {
                }
                fieldelement(CapValueEntry_SourceCode; TempCapValueEntry."Source Code")
                {
                }
                fieldelement(CapValueEntry_AppliestoEntry; TempCapValueEntry."Applies-to Entry")
                {
                }
                fieldelement(CapValueEntry_GlobalDimension1Code; TempCapValueEntry."Global Dimension 1 Code")
                {
                }
                fieldelement(CapValueEntry_GlobalDimension2Code; TempCapValueEntry."Global Dimension 2 Code")
                {
                }
                fieldelement(CapValueEntry_SourceType; TempCapValueEntry."Source Type")
                {
                }
                fieldelement(CapValueEntry_CostAmountActual; TempCapValueEntry."Cost Amount (Actual)")
                {
                }
                fieldelement(CapValueEntry_CostPostedtoGL; TempCapValueEntry."Cost Posted to G/L")
                {
                }
                fieldelement(CapValueEntry_ReasonCode; TempCapValueEntry."Reason Code")
                {
                }
                fieldelement(CapValueEntry_DropShipment; TempCapValueEntry."Drop Shipment")
                {
                }
                fieldelement(CapValueEntry_JournalBatchName; TempCapValueEntry."Journal Batch Name")
                {
                }
                fieldelement(CapValueEntry_GenBusPostingGroup; TempCapValueEntry."Gen. Bus. Posting Group")
                {
                }
                fieldelement(CapValueEntry_GenProdPostingGroup; TempCapValueEntry."Gen. Prod. Posting Group")
                {
                }
                fieldelement(CapValueEntry_DocumentDate; TempCapValueEntry."Document Date")
                {
                }
                fieldelement(CapValueEntry_ExternalDocumentNo; TempCapValueEntry."External Document No.")
                {
                }
                fieldelement(CapValueEntry_CostAmountActualACY; TempCapValueEntry."Cost Amount (Actual) (ACY)")
                {
                }
                fieldelement(CapValueEntry_CostPostedtoGLACY; TempCapValueEntry."Cost Posted to G/L (ACY)")
                {
                }
                fieldelement(CapValueEntry_CostperUnitACY; TempCapValueEntry."Cost per Unit (ACY)")
                {
                }
                fieldelement(CapValueEntry_DocumentType; TempCapValueEntry."Document Type")
                {
                }
                fieldelement(CapValueEntry_DocumentLineNo; TempCapValueEntry."Document Line No.")
                {
                }
                fieldelement(CapValueEntry_OrderType; TempCapValueEntry."Order Type")
                {
                }
                fieldelement(CapValueEntry_OrderNo; TempCapValueEntry."Order No.")
                {
                }
                fieldelement(CapValueEntry_OrderLineNo; TempCapValueEntry."Order Line No.")
                {
                }
                fieldelement(CapValueEntry_ExpectedCost; TempCapValueEntry."Expected Cost")
                {
                }
                fieldelement(CapValueEntry_ItemChargeNo; TempCapValueEntry."Item Charge No.")
                {
                }
                fieldelement(CapValueEntry_ValuedByAverageCost; TempCapValueEntry."Valued By Average Cost")
                {
                }
                fieldelement(CapValueEntry_PartialRevaluation; TempCapValueEntry."Partial Revaluation")
                {
                }
                fieldelement(CapValueEntry_Inventoriable; TempCapValueEntry.Inventoriable)
                {
                }
                fieldelement(CapValueEntry_ValuationDate; TempCapValueEntry."Valuation Date")
                {
                }
                fieldelement(CapValueEntry_EntryType; TempCapValueEntry."Entry Type")
                {
                }
                fieldelement(CapValueEntry_VarianceType; TempCapValueEntry."Variance Type")
                {
                }
                fieldelement(CapValueEntry_PurchaseAmountActual; TempCapValueEntry."Purchase Amount (Actual)")
                {
                }
                fieldelement(CapValueEntry_PurchaseAmountExpected; TempCapValueEntry."Purchase Amount (Expected)")
                {
                }
                fieldelement(CapValueEntry_SalesAmountExpected; TempCapValueEntry."Sales Amount (Expected)")
                {
                }
                fieldelement(CapValueEntry_CostAmountExpected; TempCapValueEntry."Cost Amount (Expected)")
                {
                }
                fieldelement(CapValueEntry_CostAmountNonInvtbl; TempCapValueEntry."Cost Amount (Non-Invtbl.)")
                {
                }
                fieldelement(CapValueEntry_CostAmountExpectedACY; TempCapValueEntry."Cost Amount (Expected) (ACY)")
                {
                }
                fieldelement(CapValueEntry_CostAmountNonInvtblACY; TempCapValueEntry."Cost Amount (Non-Invtbl.)(ACY)")
                {
                }
                fieldelement(CapValueEntry_ExpectedCostPostedtoGL; TempCapValueEntry."Expected Cost Posted to G/L")
                {
                }
                fieldelement(CapValueEntry_ExpCostPostedtoGLACY; TempCapValueEntry."Exp. Cost Posted to G/L (ACY)")
                {
                }
                fieldelement(CapValueEntry_VariantCode; TempCapValueEntry."Variant Code")
                {
                }
                fieldelement(CapValueEntry_Adjustment; TempCapValueEntry.Adjustment)
                {
                }
                fieldelement(CapValueEntry_CapacityLedgerEntryNo; TempCapValueEntry."Capacity Ledger Entry No.")
                {
                }
                fieldelement(CapValueEntry_Type; TempCapValueEntry.Type)
                {
                }
                fieldelement(CapValueEntry_No; TempCapValueEntry."No.")
                {
                }
                fieldelement(CapValueEntry_ReturnReasonCode; TempCapValueEntry."Return Reason Code")
                {
                }
                fieldelement(CapValueEntry_DocumentType; TempCapValueEntry."Document Type")
                {
                }
                fieldelement(CapValueEntry_DocumentLineNo; TempCapValueEntry."Document Line No.")
                {
                }
                fieldelement(CapValueEntry_CapacityLedgerEntryNo; TempCapValueEntry."Capacity Ledger Entry No.")
                {
                }

                trigger OnPreXmlItem()
                begin
                    ValueEntry.SetRange("Item No.", FilteredItem."No.");
                end;

                trigger OnAfterInsertRecord()
                var
                    CapValueEntry2: Record "Value Entry";
                begin
                    CapValueEntry2 := TempCapValueEntry;
                    CapValueEntry2."Item Ledger Entry Type" := CapValueEntry2."Item Ledger Entry Type"::" "; // otherwise Capacity Value entries state Purchase as ILE Type
                    if not CapValueEntry2.Insert() then
                        CapValueEntry2.Modify();
                end;
            }
            tableelement(generalledgsetup; "General Ledger Setup")
            {
                AutoSave = true;
                AutoUpdate = true;
                XmlName = 'GeneralLedgSetup';
                SourceTableView = sorting("Primary Key");
                fieldelement(GeneralLedgSetup_PrimaryKey; GeneralLedgSetup."Primary Key")
                {
                }
                fieldelement(GeneralLedgSetup_AllowPostingFrom; GeneralLedgSetup."Allow Posting From")
                {
                }
                fieldelement(GeneralLedgSetup_AllowPostingTo; GeneralLedgSetup."Allow Posting To")
                {
                }
                fieldelement(GeneralLedgSetup_RegisterTime; GeneralLedgSetup."Register Time")
                {
                }
                fieldelement(GeneralLedgSetup_PmtDiscExclVAT; GeneralLedgSetup."Pmt. Disc. Excl. VAT")
                {
                }
                fieldelement(GeneralLedgSetup_DateFilter; GeneralLedgSetup."Date Filter")
                {
                }
                fieldelement(GeneralLedgSetup_GlobalDimension1Filter; GeneralLedgSetup."Global Dimension 1 Filter")
                {
                }
                fieldelement(GeneralLedgSetup_GlobalDimension2Filter; GeneralLedgSetup."Global Dimension 2 Filter")
                {
                }
                fieldelement(GeneralLedgSetup_CustBalancesDue; GeneralLedgSetup."Cust. Balances Due")
                {
                }
                fieldelement(GeneralLedgSetup_VendorBalancesDue; GeneralLedgSetup."Vendor Balances Due")
                {
                }
                fieldelement(GeneralLedgSetup_UnrealizedVAT; GeneralLedgSetup."Unrealized VAT")
                {
                }
                fieldelement(GeneralLedgSetup_AdjustforPaymentDisc; GeneralLedgSetup."Adjust for Payment Disc.")
                {
                }
                fieldelement(GeneralLedgSetup_InvRoundingPrecisionLCY; GeneralLedgSetup."Inv. Rounding Precision (LCY)")
                {
                }
                fieldelement(GeneralLedgSetup_InvRoundingTypeLCY; GeneralLedgSetup."Inv. Rounding Type (LCY)")
                {
                }
                fieldelement(GeneralLedgSetup_LocalContAddrFormat; GeneralLedgSetup."Local Cont. Addr. Format")
                {
                }
                fieldelement(GeneralLedgSetup_AmountDecimalPlaces; GeneralLedgSetup."Amount Decimal Places")
                {
                }
                fieldelement(GeneralLedgSetup_UnitAmountDecimalPlaces; GeneralLedgSetup."Unit-Amount Decimal Places")
                {
                }
                fieldelement(GeneralLedgSetup_AdditionalReportingCurrency; GeneralLedgSetup."Additional Reporting Currency")
                {
                }
                fieldelement(GeneralLedgSetup_AmountRoundingPrecision; GeneralLedgSetup."Amount Rounding Precision")
                {
                }
                fieldelement(GeneralLedgSetup_UnitAmountRoundingPrecision; GeneralLedgSetup."Unit-Amount Rounding Precision")
                {
                }
                fieldelement(GeneralLedgSetup_ApplnRoundingPrecision; GeneralLedgSetup."Appln. Rounding Precision")
                {
                }
                fieldelement(GeneralLedgSetup_GlobalDimension1Code; GeneralLedgSetup."Global Dimension 1 Code")
                {
                }
                fieldelement(GeneralLedgSetup_GlobalDimension2Code; GeneralLedgSetup."Global Dimension 2 Code")
                {
                }
            }
            tableelement(accountingperiod; "Accounting Period")
            {
                AutoSave = false;
                AutoUpdate = false;
                XmlName = 'AccountingPeriod';
                SourceTableView = sorting("Starting Date");
                fieldelement(AccountingPeriod_StartingDate; AccountingPeriod."Starting Date")
                {
                }
                fieldelement(AccountingPeriod_Name; AccountingPeriod.Name)
                {
                }
                fieldelement(AccountingPeriod_NewFiscalYear; AccountingPeriod."New Fiscal Year")
                {
                }
                fieldelement(AccountingPeriod_Closed; AccountingPeriod.Closed)
                {
                }
                fieldelement(AccountingPeriod_DateLocked; AccountingPeriod."Date Locked")
                {
                }
                fieldelement(AccountingPeriod_AverageCostCalcType; AccountingPeriod."Average Cost Calc. Type")
                {
                }
                fieldelement(AccountingPeriod_AverageCostPeriod; AccountingPeriod."Average Cost Period")
                {
                }

                trigger OnBeforeInsertRecord()
                begin
                    if not AccountingPeriod.Insert() then
                        AccountingPeriod.Modify();
                end;
            }
            tableelement(postvalueentrytogl; "Post Value Entry to G/L")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'PostValueEntryToGl';
                SourceTableView = sorting("Item No.", "Posting Date");
                fieldelement(PostValueEntryToGl_ValueEntryNo; PostValueEntryToGl."Value Entry No.")
                {
                }
                fieldelement(PostValueEntryToGl_ItemNo; PostValueEntryToGl."Item No.")
                {
                }
                fieldelement(PostValueEntryToGl_PostingDate; PostValueEntryToGl."Posting Date")
                {
                }

                trigger OnPreXmlItem()
                begin
                    PostValueEntryToGl.SetRange("Item No.", FilteredItem."No.");
                end;
            }
            tableelement(tempitemapplnentryhistory; "Item Application Entry History")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'ItemApplnEntryHistory';
                SourceTableView = sorting("Primary Entry No.");
                UseTemporary = true;
                fieldelement(ItemApplnEntryHist_EntryNo; TempItemApplnEntryHistory."Entry No.")
                {
                }
                fieldelement(ItemApplnEntryHist_ItemLedgerEntryNo; TempItemApplnEntryHistory."Item Ledger Entry No.")
                {
                }
                fieldelement(ItemApplnEntryHist_InboundItemEntryNo; TempItemApplnEntryHistory."Inbound Item Entry No.")
                {
                }
                fieldelement(ItemApplnEntryHist_OutboundItemEntryNo; TempItemApplnEntryHistory."Outbound Item Entry No.")
                {
                }
                fieldelement(ItemApplnEntryHist_Quantity; TempItemApplnEntryHistory.Quantity)
                {
                }
                fieldelement(ItemApplnEntryHist_PostingDate; TempItemApplnEntryHistory."Posting Date")
                {
                }
                fieldelement(ItemApplnEntryHist_TransferredFromEntryNo; TempItemApplnEntryHistory."Transferred-from Entry No.")
                {
                }
                fieldelement(ItemApplnEntryHist_CreationDate; TempItemApplnEntryHistory."Creation Date")
                {
                }
                fieldelement(ItemApplnEntryHist_LastModifiedDate; TempItemApplnEntryHistory."Last Modified Date")
                {
                }
                fieldelement(ItemApplnEntryHist_DeletedDate; TempItemApplnEntryHistory."Deleted Date")
                {
                }
                fieldelement(ItemApplnEntryHist_CostApplication; TempItemApplnEntryHistory."Cost Application")
                {
                }
                fieldelement(ItemApplnEntryHist_OutputCompletelyInvdDate; TempItemApplnEntryHistory."Output Completely Invd. Date")
                {
                }
                fieldelement(ItemApplnEntryHist_OutputEntryIsUpdated; TempItemApplnEntryHistory."Primary Entry No.")
                {
                }

                trigger OnAfterInsertRecord()
                var
                    ItemApplnEntryHistory2: Record "Item Application Entry History";
                begin
                    ItemApplnEntryHistory2 := TempItemApplnEntryHistory;
                    if not ItemApplnEntryHistory2.Insert() then
                        ItemApplnEntryHistory2.Modify();
                end;
            }
            tableelement(inventoryperiod; "Inventory Period")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'InventoryPeriod';
                SourceTableView = sorting("Ending Date");
                fieldelement(InventoryPeriod_EndingDate; InventoryPeriod."Ending Date")
                {
                }
                fieldelement(InventoryPeriod_Name; InventoryPeriod.Name)
                {
                }
                fieldelement(InventoryPeriod_Closed; InventoryPeriod.Closed)
                {
                }
            }
            tableelement(itemregister; "Item Register")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'ItemRegister';
                SourceTableView = sorting("Source Code");
                fieldelement(ItemRegister_No; ItemRegister."No.")
                {
                }
                fieldelement(ItemRegister_FromEntryNo; ItemRegister."From Entry No.")
                {
                }
                fieldelement(ItemRegister_ToEntryNo; ItemRegister."To Entry No.")
                {
                }
                fieldelement(ItemRegister_CreationDate; ItemRegister."Creation Date")
                {
                }
                fieldelement(ItemRegister_SourceCode; ItemRegister."Source Code")
                {
                }
                fieldelement(ItemRegister_JournalBatchName; ItemRegister."Journal Batch Name")
                {
                }
                fieldelement(ItemRegister_FromPhysInventoryEntryNo; ItemRegister."From Phys. Inventory Entry No.")
                {
                }
                fieldelement(ItemRegister_ToPhysInventoryEntryNo; ItemRegister."To Phys. Inventory Entry No.")
                {
                }
                fieldelement(ItemRegister_FromValueEntryNo; ItemRegister."From Value Entry No.")
                {
                }
                fieldelement(ItemRegister_ToValueEntryNo; ItemRegister."To Value Entry No.")
                {
                }
                fieldelement(ItemRegister_FromCapacityEntryNo; ItemRegister."From Capacity Entry No.")
                {
                }
                fieldelement(ItemRegister_ToCapacityEntryNo; ItemRegister."To Capacity Entry No.")
                {
                }

                trigger OnPreXmlItem()
                var
                    SourceCodeSetup: Record "Source Code Setup";
                begin
                    SourceCodeSetup.Get();
                    ItemRegister.SetRange("Source Code", SourceCodeSetup."Adjust Cost");
                end;
            }
            tableelement(stockkeepingunit; "Stockkeeping Unit")
            {
                AutoSave = true;
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'StockkeepingUnit';
                SourceTableView = sorting("Item No.");
                fieldelement(StockkeepingUnit_ItemNo; StockkeepingUnit."Item No.")
                {
                }
                fieldelement(StockkeepingUnit_VariantCode; StockkeepingUnit."Variant Code")
                {
                }
                fieldelement(StockkeepingUnit_LocationCode; StockkeepingUnit."Location Code")
                {
                }
                fieldelement(StockkeepingUnit_ShelfNo; StockkeepingUnit."Shelf No.")
                {
                }
                fieldelement(StockkeepingUnit_UnitCost; StockkeepingUnit."Unit Cost")
                {
                }
                fieldelement(StockkeepingUnit_StandardCost; StockkeepingUnit."Standard Cost")
                {
                }
                fieldelement(StockkeepingUnit_LastDirectCost; StockkeepingUnit."Last Direct Cost")
                {
                }
                fieldelement(StockkeepingUnit_VendorNo; StockkeepingUnit."Vendor No.")
                {
                }
                fieldelement(StockkeepingUnit_VendorItemNo; StockkeepingUnit."Vendor Item No.")
                {
                }
                fieldelement(StockkeepingUnit_LeadTimeCalculation; StockkeepingUnit."Lead Time Calculation")
                {
                }
                fieldelement(StockkeepingUnit_ReorderPoint; StockkeepingUnit."Reorder Point")
                {
                }
                fieldelement(StockkeepingUnit_MaximumInventory; StockkeepingUnit."Maximum Inventory")
                {
                }
                fieldelement(StockkeepingUnit_ReorderQuantity; StockkeepingUnit."Reorder Quantity")
                {
                }
                fieldelement(StockkeepingUnit_AssemblyPolicy; StockkeepingUnit."Assembly Policy")
                {
                }
                fieldelement(StockkeepingUnit_TransferLevelCode; StockkeepingUnit."Transfer-Level Code")
                {
                }
                fieldelement(StockkeepingUnit_LotSize; StockkeepingUnit."Lot Size")
                {
                }
                fieldelement(StockkeepingUnit_DiscreteOrderQuantity; StockkeepingUnit."Discrete Order Quantity")
                {
                }
                fieldelement(StockkeepingUnit_MinimumOrderQuantity; StockkeepingUnit."Minimum Order Quantity")
                {
                }
                fieldelement(StockkeepingUnit_MaximumOrderQuantity; StockkeepingUnit."Maximum Order Quantity")
                {
                }
                fieldelement(StockkeepingUnit_SafetyStockQuantity; StockkeepingUnit."Safety Stock Quantity")
                {
                }
                fieldelement(StockkeepingUnit_OrderMultiple; StockkeepingUnit."Order Multiple")
                {
                }
                fieldelement(StockkeepingUnit_SafetyLeadTime; StockkeepingUnit."Safety Lead Time")
                {
                }
                fieldelement(StockkeepingUnit_ComponentsatLocation; StockkeepingUnit."Components at Location")
                {
                }
                fieldelement(StockkeepingUnit_FlushingMethod; StockkeepingUnit."Flushing Method")
                {
                }
                fieldelement(StockkeepingUnit_ReplenishmentSystem; StockkeepingUnit."Replenishment System")
                {
                }
                fieldelement(StockkeepingUnit_TimeBucket; StockkeepingUnit."Time Bucket")
                {
                }
                fieldelement(StockkeepingUnit_ReorderingPolicy; StockkeepingUnit."Reordering Policy")
                {
                }
                fieldelement(StockkeepingUnit_IncludeInventory; StockkeepingUnit."Include Inventory")
                {
                }
                fieldelement(StockkeepingUnit_ManufacturingPolicy; StockkeepingUnit."Manufacturing Policy")
                {
                }
                fieldelement(StockkeepingUnit_LotAccumulationPeriod; StockkeepingUnit."Lot Accumulation Period")
                {
                }
                fieldelement(StockkeepingUnit_ReschedulingPeriod; StockkeepingUnit."Rescheduling Period")
                {
                }
                fieldelement(StockkeepingUnit_DampenerPeriod; StockkeepingUnit."Dampener Period")
                {
                }
                fieldelement(StockkeepingUnit_DampenerQuantity; StockkeepingUnit."Dampener Quantity")
                {
                }
                fieldelement(StockkeepingUnit_OverflowLevel; StockkeepingUnit."Overflow Level")
                {
                }
                fieldelement(StockkeepingUnit_TransferfromCode; StockkeepingUnit."Transfer-from Code")
                {
                }
                fieldelement(StockkeepingUnit_PutawayTemplateCode; StockkeepingUnit."Put-away Template Code")
                {
                }
                fieldelement(StockkeepingUnit_PutawayUnitofMeasureCode; StockkeepingUnit."Put-away Unit of Measure Code")
                {
                }
                fieldelement(StockkeepingUnit_PhysInvtCountingPeriodCode; StockkeepingUnit."Phys Invt Counting Period Code")
                {
                }

                trigger OnPreXmlItem()
                begin
                    StockkeepingUnit.SetRange("Item No.", FilteredItem."No.");
                end;
            }
            tableelement(invadjmentry; "Inventory Adjmt. Entry (Order)")
            {
                AutoUpdate = true;
                MinOccurs = Zero;
                XmlName = 'InvAdjmEntry';
                SourceTableView = sorting("Order Type", "Order No.", "Order Line No.");
                fieldelement(InvAdjmEntry_OrderType; InvAdjmEntry."Order Type")
                {
                }
                fieldelement(InvAdjmEntry_OrderNo; InvAdjmEntry."Order No.")
                {
                }
                fieldelement(InvAdjmEntry_OrderLineNo; InvAdjmEntry."Order Line No.")
                {
                }
                fieldelement(InvAdjmEntry_ItemNo; InvAdjmEntry."Item No.")
                {
                }
                fieldelement(InvAdjmEntry_IndirectCostPercentage; InvAdjmEntry."Indirect Cost %")
                {
                }
                fieldelement(InvAdjmEntry_OverheadRate; InvAdjmEntry."Overhead Rate")
                {
                }
                fieldelement(InvAdjmEntry_CostisAdjusted; InvAdjmEntry."Cost is Adjusted")
                {
                }
                fieldelement(InvAdjmEntry_AllowOnlineAdjustment; InvAdjmEntry."Allow Online Adjustment")
                {
                }
                fieldelement(InvAdjmEntry_UnitCost; InvAdjmEntry."Unit Cost")
                {
                }
                fieldelement(InvAdjmEntry_DirectCost; InvAdjmEntry."Direct Cost")
                {
                }
                fieldelement(InvAdjmEntry_IndirectCost; InvAdjmEntry."Indirect Cost")
                {
                }
                fieldelement("InvAdjmEntry_Single-LevelMaterialCost"; InvAdjmEntry."Single-Level Material Cost")
                {
                }
                fieldelement("InvAdjmEntry_Single-LevelCapacityCost"; InvAdjmEntry."Single-Level Capacity Cost")
                {
                }
                fieldelement("InvAdjmEntry_Single-LevelSubcontrd.Cost"; InvAdjmEntry."Single-Level Subcontrd. Cost")
                {
                }
                fieldelement("InvAdjmEntry_Single-LevelCap.OvhdCost"; InvAdjmEntry."Single-Level Cap. Ovhd Cost")
                {
                }
                fieldelement("InvAdjmEntry_Single-LevelMfg.OvhdCost"; InvAdjmEntry."Single-Level Mfg. Ovhd Cost")
                {
                }
                fieldelement(InvAdjmEntry_CompletelyInvoiced; InvAdjmEntry."Completely Invoiced")
                {
                }
                fieldelement(InvAdjmEntry_IsFinished; InvAdjmEntry."Is Finished")
                {
                }

                trigger OnPreXmlItem()
                begin
                    InvAdjmEntry.SetRange("Item No.", FilteredItem."No.");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnPostXmlPort()
    begin
        if currXMLport.ImportFile() then begin
            FinishImport();
            Message(ImportOKMsg, FilteredItem."No.", Format(CurrentDateTime - StartTime));
        end else
            Message(ExportOKMsg, FilteredItem."No.", Format(CurrentDateTime - StartTime));
    end;

    trigger OnPreXmlPort()
    begin
        StartTime := CurrentDateTime();

        ItemRecRef.Open(Database::Item);
        ItemTypeFieldExists := ItemRecRef.FieldExist(10);
        ItemRecRef.Close();
    end;

    var
        FilteredItem: Record Item;
        ItemRecRef: RecordRef;
        TypeFieldRef: FieldRef;
        StartTime: DateTime;
        ItemTypeFieldExists: Boolean;
        ItemTypeInt: Integer;
        SingleItemExportOnlyErr: Label 'Select just one item to export.';
        ItemLedgEntryNoExistErr: Label 'Item Ledger Entry %1 already exists in the database.\You must delete all entries before continue.', Comment = '%1 = Entry No.';
        ExportOKMsg: Label 'Item %1 has been successfully exported in %2.', Comment = '%1 = Item No., %2 = Duration';
        ImportOKMsg: Label 'Item %1 has been successfully imported in %2.', Comment = '%1 = Item No., %2 = Duration';

    procedure FinishImport()
    var
        GenPostingSetup2: Record "General Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvtPostingSetup2: Record "Inventory Posting Setup";
        BusinessGroupCode: Code[20];
        ProductGroupCode: Code[20];
        LocationCode: Code[10];
    begin
        GenPostingSetup2.SetFilter("Sales Account", '<>%1', '');
        GenPostingSetup2.SetFilter("COGS Account", '<>%1', '');
        if GenPostingSetup2.FindFirst() then;

        VATPostingSetup2.SetFilter("Sales VAT Account", '<>%1', '');
        if VATPostingSetup2.FindFirst() then;

        InvtPostingSetup2.SetFilter("Inventory Account", '<>%1', '');
        if InvtPostingSetup2.FindFirst() then;

        GenPostingSetup.FindSet();
        repeat
            if (GenPostingSetup."Sales Account" = '') and (GenPostingSetup."COGS Account" = '') then begin
                BusinessGroupCode := GenPostingSetup."Gen. Bus. Posting Group";
                ProductGroupCode := GenPostingSetup."Gen. Prod. Posting Group";
                GenPostingSetup.TransferFields(GenPostingSetup2);
                GenPostingSetup."Gen. Bus. Posting Group" := BusinessGroupCode;
                GenPostingSetup."Gen. Prod. Posting Group" := ProductGroupCode;
                GenPostingSetup.Modify();
            end;
        until GenPostingSetup.Next() = 0;

        VatPostingSetup.FindSet();
        repeat
            if VatPostingSetup."VAT Identifier" = '' then begin
                BusinessGroupCode := VatPostingSetup."VAT Bus. Posting Group";
                ProductGroupCode := VatPostingSetup."VAT Prod. Posting Group";
                VatPostingSetup.TransferFields(VATPostingSetup2);
                VatPostingSetup."VAT Bus. Posting Group" := BusinessGroupCode;
                VatPostingSetup."VAT Prod. Posting Group" := ProductGroupCode;
                VatPostingSetup.Modify();
            end;
        until VatPostingSetup.Next() = 0;

        InventoryPostingSetup.FindSet();
        repeat
            if InventoryPostingSetup."Inventory Account" = '' then begin
                LocationCode := InventoryPostingSetup."Location Code";
                ProductGroupCode := InventoryPostingSetup."Invt. Posting Group Code";
                InventoryPostingSetup.TransferFields(InvtPostingSetup2);
                InventoryPostingSetup."Location Code" := LocationCode;
                InventoryPostingSetup."Invt. Posting Group Code" := ProductGroupCode;
                InventoryPostingSetup.Modify();
            end;
        until InventoryPostingSetup.Next() = 0;
    end;

    procedure CollectItemApplnEntry(ItemLedgEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemApplnEntry.SetCurrentKey("Item Ledger Entry No.");
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ItemApplnEntry.FindSet() then
            repeat
                TempItemApplnEntry := ItemApplnEntry;
                TempItemApplnEntry.Insert();
            until ItemApplnEntry.Next() = 0;
    end;

    procedure CollectItemApplnEntryHist(ItemLedgEntryNo: Integer)
    var
        ItemApplnEntryHistory: Record "Item Application Entry History";
    begin
        ItemApplnEntryHistory.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ItemApplnEntryHistory.FindSet() then
            repeat
                TempItemApplnEntryHistory := ItemApplnEntryHistory;
                TempItemApplnEntryHistory.Insert();
            until ItemApplnEntryHistory.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('Use xml port MfgExportItemData instead', '27.0')]
    procedure CollectProdOrder(ProdOrderNo: Code[20])
    begin
        if ProdOrderNo = '' then
            exit;
    end;
#endif

    procedure CollectCapValueEntry(CapEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Capacity Ledger Entry No.");
        ValueEntry.SetRange("Capacity Ledger Entry No.", CapEntryNo);
        if ValueEntry.FindSet() then
            repeat
                TempCapValueEntry := ValueEntry;
                TempCapValueEntry.Insert();
            until ValueEntry.Next() = 0;
    end;
}
