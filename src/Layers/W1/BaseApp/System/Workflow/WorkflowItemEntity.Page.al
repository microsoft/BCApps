namespace System.Automation;

using Microsoft.Inventory.Item;

page 6409 "Workflow - Item Entity"
{
    Caption = 'workflowItems', Locked = true;
    DelayedInsert = true;
    SourceTable = Item;
    PageType = List;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(number2; Rec."No. 2")
                {
                    ApplicationArea = All;
                    Caption = 'No. 2', Locked = true;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(searchDescription; Rec."Search Description")
                {
                    ApplicationArea = All;
                    Caption = 'Search Description', Locked = true;
                }
                field(description2; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Caption = 'Description 2', Locked = true;
                }
                field(assemblyBom; Rec."Assembly BOM")
                {
                    ApplicationArea = All;
                    Caption = 'Assembly BOM', Locked = true;
                }
                field(baseUnitOfMeasure; Rec."Base Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Base Unit of Measure', Locked = true;
                }
                field(priceUnitConversion; Rec."Price Unit Conversion")
                {
                    ApplicationArea = All;
                    Caption = 'Price Unit Conversion', Locked = true;
                }
                field(type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', Locked = true;
                }
                field(inventoryPostingGroup; Rec."Inventory Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Posting Group', Locked = true;
                }
                field(shelfNumber; Rec."Shelf No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shelf No.', Locked = true;
                }
                field(itemDiscGroup; Rec."Item Disc. Group")
                {
                    ApplicationArea = All;
                    Caption = 'Item Disc. Group', Locked = true;
                }
                field(allowInvoiceDisc; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Invoice Disc.', Locked = true;
                }
                field(statisticsGroup; Rec."Statistics Group")
                {
                    ApplicationArea = All;
                    Caption = 'Statistics Group', Locked = true;
                }
                field(commissionGroup; Rec."Commission Group")
                {
                    ApplicationArea = All;
                    Caption = 'Commission Group', Locked = true;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price', Locked = true;
                }
                field(priceProfitCalculation; Rec."Price/Profit Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Price/Profit Calculation', Locked = true;
                }
                field(profitPercent; Rec."Profit %")
                {
                    ApplicationArea = All;
                    Caption = 'Profit %', Locked = true;
                }
                field(costingMethod; Rec."Costing Method")
                {
                    ApplicationArea = All;
                    Caption = 'Costing Method', Locked = true;
                }
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost', Locked = true;
                }
                field(standardCost; Rec."Standard Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Standard Cost', Locked = true;
                }
                field(lastDirectCost; Rec."Last Direct Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Last Direct Cost', Locked = true;
                }
                field(indirectCostPercent; Rec."Indirect Cost %")
                {
                    ApplicationArea = All;
                    Caption = 'Indirect Cost %', Locked = true;
                }
                field(costIsAdjusted; Rec."Cost is Adjusted")
                {
                    ApplicationArea = All;
                    Caption = 'Cost is Adjusted', Locked = true;
                }
                field(allowOnlineAdjustment; Rec."Allow Online Adjustment")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Online Adjustment', Locked = true;
                }
                field(vendorNumber; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor No.', Locked = true;
                }
                field(vendorItemNumber; Rec."Vendor Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Item No.', Locked = true;
                }
                field(leadTimeCalculation; Rec."Lead Time Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time Calculation', Locked = true;
                }
                field(reorderPoint; Rec."Reorder Point")
                {
                    ApplicationArea = All;
                    Caption = 'Reorder Point', Locked = true;
                }
                field(maximumInventory; Rec."Maximum Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Maximum Inventory', Locked = true;
                }
                field(reorderQuantity; Rec."Reorder Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Reorder Quantity', Locked = true;
                }
                field(alternativeItemNumber; Rec."Alternative Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Alternative Item No.', Locked = true;
                }
                field(unitListPrice; Rec."Unit List Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit List Price', Locked = true;
                }
                field(dutyDuePercent; Rec."Duty Due %")
                {
                    ApplicationArea = All;
                    Caption = 'Duty Due %', Locked = true;
                }
                field(dutyCode; Rec."Duty Code")
                {
                    ApplicationArea = All;
                    Caption = 'Duty Code', Locked = true;
                }
                field(grossWeight; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Gross Weight', Locked = true;
                }
                field(netWeight; Rec."Net Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Net Weight', Locked = true;
                }
                field(unitsPerParcel; Rec."Units per Parcel")
                {
                    ApplicationArea = All;
                    Caption = 'Units per Parcel', Locked = true;
                }
                field(unitVolume; Rec."Unit Volume")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Volume', Locked = true;
                }
                field(durability; Rec.Durability)
                {
                    ApplicationArea = All;
                    Caption = 'Durability', Locked = true;
                }
                field(freightType; Rec."Freight Type")
                {
                    ApplicationArea = All;
                    Caption = 'Freight Type', Locked = true;
                }
                field(tariffNumber; Rec."Tariff No.")
                {
                    ApplicationArea = All;
                    Caption = 'Tariff No.', Locked = true;
                }
                field(dutyUnitConversion; Rec."Duty Unit Conversion")
                {
                    ApplicationArea = All;
                    Caption = 'Duty Unit Conversion', Locked = true;
                }
                field(countryRegionPurchasedCode; Rec."Country/Region Purchased Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Purchased Code', Locked = true;
                }
                field(budgetQuantity; Rec."Budget Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Budget Quantity', Locked = true;
                }
                field(budgetedAmount; Rec."Budgeted Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted Amount', Locked = true;
                }
                field(budgetProfit; Rec."Budget Profit")
                {
                    ApplicationArea = All;
                    Caption = 'Budget Profit', Locked = true;
                }
                field(comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;
                }
                field(costIsPostedToGL; Rec."Cost is Posted to G/L")
                {
                    ApplicationArea = All;
                    Caption = 'Cost is Posted to G/L', Locked = true;
                }
                field(blockReason; Rec."Block Reason")
                {
                    ApplicationArea = All;
                    Caption = 'Block Reason', Locked = true;
                }
                field(lastDatetimeModified; Rec."Last DateTime Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last DateTime Modified', Locked = true;
                }
                field(lastDateModified; Rec."Last Date Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last Date Modified', Locked = true;
                }
                field(lastTimeModified; Rec."Last Time Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last Time Modified', Locked = true;
                }
                field(dateFilter; Rec."Date Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Date Filter', Locked = true;
                }
                field(globalDimension1Filter; Rec."Global Dimension 1 Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 1 Filter', Locked = true;
                }
                field(globalDimension2Filter; Rec."Global Dimension 2 Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 2 Filter', Locked = true;
                }
                field(locationFilter; Rec."Location Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Location Filter', Locked = true;
                }
                field(inventory; Rec.Inventory)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory', Locked = true;
                }
                field(netInvoicedQty; Rec."Net Invoiced Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'Net Invoiced Qty.', Locked = true;
                }
                field(netChange; Rec."Net Change")
                {
                    ApplicationArea = All;
                    Caption = 'Net Change', Locked = true;
                }
                field(purchasesQty; Rec."Purchases (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Purchases (Qty.)', Locked = true;
                }
                field(salesQty; Rec."Sales (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales (Qty.)', Locked = true;
                }
                field(positiveAdjmtQty; Rec."Positive Adjmt. (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Positive Adjmt. (Qty.)', Locked = true;
                }
                field(negativeAdjmtQty; Rec."Negative Adjmt. (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Negative Adjmt. (Qty.)', Locked = true;
                }
                field(purchasesLcy; Rec."Purchases (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Purchases (LCY)', Locked = true;
                }
                field(salesLcy; Rec."Sales (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales (LCY)', Locked = true;
                }
                field(positiveAdjmtLcy; Rec."Positive Adjmt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Positive Adjmt. (LCY)', Locked = true;
                }
                field(negativeAdjmtLcy; Rec."Negative Adjmt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Negative Adjmt. (LCY)', Locked = true;
                }
                field(cogsLcy; Rec."COGS (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'COGS (LCY)', Locked = true;
                }
                field(qtyOnPurchOrder; Rec."Qty. on Purch. Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Purch. Order', Locked = true;
                }
                field(qtyOnSalesOrder; Rec."Qty. on Sales Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Sales Order', Locked = true;
                }
                field(priceIncludesVat; Rec."Price Includes VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Price Includes VAT', Locked = true;
                }
                field(dropShipmentFilter; Rec."Drop Shipment Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Drop Shipment Filter', Locked = true;
                }
                field(vatBusPostingGrPrice; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Bus. Posting Gr. (Price)', Locked = true;
                }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Prod. Posting Group', Locked = true;
                }
                field(picture; Rec.Picture)
                {
                    ApplicationArea = All;
                    Caption = 'Picture', Locked = true;
                }
                field(transferredQty; Rec."Transferred (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Transferred (Qty.)', Locked = true;
                }
                field(transferredLcy; Rec."Transferred (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Transferred (LCY)', Locked = true;
                }
                field(countryRegionOfOriginCode; Rec."Country/Region of Origin Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region of Origin Code', Locked = true;
                }
                field(automaticExtTexts; Rec."Automatic Ext. Texts")
                {
                    ApplicationArea = All;
                    Caption = 'Automatic Ext. Texts', Locked = true;
                }
                field(numberSeries; Rec."No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
                }
                field(taxGroupCode; Rec."Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Group Code', Locked = true;
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Prod. Posting Group', Locked = true;
                }
                field(reserve; Rec.Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
                }
                field(reservedQtyOnInventory; Rec."Reserved Qty. on Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Inventory', Locked = true;
                }
                field(reservedQtyOnPurchOrders; Rec."Reserved Qty. on Purch. Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Purch. Orders', Locked = true;
                }
                field(reservedQtyOnSalesOrders; Rec."Reserved Qty. on Sales Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. on Sales Orders', Locked = true;
                }
                field(globalDimension1Code; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 1 Code', Locked = true;
                }
                field(globalDimension2Code; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 2 Code', Locked = true;
                }
                field(resQtyOnOutboundTransfer; Rec."Res. Qty. on Outbound Transfer")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Outbound Transfer', Locked = true;
                }
                field(resQtyOnInboundTransfer; Rec."Res. Qty. on Inbound Transfer")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Inbound Transfer', Locked = true;
                }
                field(resQtyOnSalesReturns; Rec."Res. Qty. on Sales Returns")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Sales Returns', Locked = true;
                }
                field(resQtyOnPurchReturns; Rec."Res. Qty. on Purch. Returns")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Purch. Returns', Locked = true;
                }
                field(stockoutWarning; Rec."Stockout Warning")
                {
                    ApplicationArea = All;
                    Caption = 'Stockout Warning', Locked = true;
                }
                field(preventNegativeInventory; Rec."Prevent Negative Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Prevent Negative Inventory', Locked = true;
                }
                field(applicationWkshUserId; Rec."Application Wksh. User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Application Wksh. User ID', Locked = true;
                }
                field(assemblyPolicy; Rec."Assembly Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Assembly Policy', Locked = true;
                }
                field(resQtyOnAssemblyOrder; Rec."Res. Qty. on Assembly Order")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Assembly Order', Locked = true;
                }
                field(resQtyOnAsmComp; Rec."Res. Qty. on  Asm. Comp.")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on  Asm. Comp.', Locked = true;
                }
                field(qtyOnAssemblyOrder; Rec."Qty. on Assembly Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Assembly Order', Locked = true;
                }
                field(qtyOnAsmComponent; Rec."Qty. on Asm. Component")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Asm. Component', Locked = true;
                }
                field(qtyOnJobOrder; Rec."Qty. on Job Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Job Order', Locked = true;
                }
                field(resQtyOnJobOrder; Rec."Res. Qty. on Job Order")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Job Order', Locked = true;
                }
                field(gtin; Rec.GTIN)
                {
                    ApplicationArea = All;
                    Caption = 'GTIN', Locked = true;
                }
                field(defaultDeferralTemplateCode; Rec."Default Deferral Template Code")
                {
                    ApplicationArea = All;
                    Caption = 'Default Deferral Template Code', Locked = true;
                }
                field(lowLevelCode; Rec."Low-Level Code")
                {
                    ApplicationArea = All;
                    Caption = 'Low-Level Code', Locked = true;
                }
                field(lotSize; Rec."Lot Size")
                {
                    ApplicationArea = All;
                    Caption = 'Lot Size', Locked = true;
                }
                field(serialNos; Rec."Serial Nos.")
                {
                    ApplicationArea = All;
                    Caption = 'Serial Nos.', Locked = true;
                }
                field(lastUnitCostCalcDate; Rec."Last Unit Cost Calc. Date")
                {
                    ApplicationArea = All;
                    Caption = 'Last Unit Cost Calc. Date', Locked = true;
                }
                field(rolledUpMaterialCost; Rec."Rolled-up Material Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Material Cost', Locked = true;
                }
                field(rolledUpCapacityCost; Rec."Rolled-up Capacity Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Capacity Cost', Locked = true;
                }
                field(scrapPercent; Rec."Scrap %")
                {
                    ApplicationArea = All;
                    Caption = 'Scrap %', Locked = true;
                }
                field(inventoryValueZero; Rec."Inventory Value Zero")
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Value Zero', Locked = true;
                }
                field(discreteOrderQuantity; Rec."Discrete Order Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Discrete Order Quantity', Locked = true;
                }
                field(minimumOrderQuantity; Rec."Minimum Order Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Minimum Order Quantity', Locked = true;
                }
                field(maximumOrderQuantity; Rec."Maximum Order Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Maximum Order Quantity', Locked = true;
                }
                field(safetyStockQuantity; Rec."Safety Stock Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Safety Stock Quantity', Locked = true;
                }
                field(orderMultiple; Rec."Order Multiple")
                {
                    ApplicationArea = All;
                    Caption = 'Order Multiple', Locked = true;
                }
                field(safetyLeadTime; Rec."Safety Lead Time")
                {
                    ApplicationArea = All;
                    Caption = 'Safety Lead Time', Locked = true;
                }
                field(flushingMethod; Rec."Flushing Method")
                {
                    ApplicationArea = All;
                    Caption = 'Flushing Method', Locked = true;
                }
                field(replenishmentSystem; Rec."Replenishment System")
                {
                    ApplicationArea = All;
                    Caption = 'Replenishment System', Locked = true;
                }
                field(roundingPrecision; Rec."Rounding Precision")
                {
                    ApplicationArea = All;
                    Caption = 'Rounding Precision', Locked = true;
                }
                field(binFilter; Rec."Bin Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Bin Filter', Locked = true;
                }
                field(variantFilter; Rec."Variant Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Filter', Locked = true;
                }
                field(salesUnitOfMeasure; Rec."Sales Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Unit of Measure', Locked = true;
                }
                field(purchUnitOfMeasure; Rec."Purch. Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Unit of Measure', Locked = true;
                }
                field(timeBucket; Rec."Time Bucket")
                {
                    ApplicationArea = All;
                    Caption = 'Time Bucket', Locked = true;
                }
                field(resQtyOnReqLine; Rec."Res. Qty. on Req. Line")
                {
                    ApplicationArea = All;
                    Caption = 'Res. Qty. on Req. Line', Locked = true;
                }
                field(reorderingPolicy; Rec."Reordering Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Reordering Policy', Locked = true;
                }
                field(includeInventory; Rec."Include Inventory")
                {
                    ApplicationArea = All;
                    Caption = 'Include Inventory', Locked = true;
                }
                field(manufacturingPolicy; Rec."Manufacturing Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Manufacturing Policy', Locked = true;
                }
                field(reschedulingPeriod; Rec."Rescheduling Period")
                {
                    ApplicationArea = All;
                    Caption = 'Rescheduling Period', Locked = true;
                }
                field(lotAccumulationPeriod; Rec."Lot Accumulation Period")
                {
                    ApplicationArea = All;
                    Caption = 'Lot Accumulation Period', Locked = true;
                }
                field(dampenerPeriod; Rec."Dampener Period")
                {
                    ApplicationArea = All;
                    Caption = 'Dampener Period', Locked = true;
                }
                field(dampenerQuantity; Rec."Dampener Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Dampener Quantity', Locked = true;
                }
                field(overflowLevel; Rec."Overflow Level")
                {
                    ApplicationArea = All;
                    Caption = 'Overflow Level', Locked = true;
                }
                field(planningTransferShipQty; Rec."Planning Transfer Ship. (Qty).")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Transfer Ship. (Qty).', Locked = true;
                }
                field(planningWorksheetQty; Rec."Planning Worksheet (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Worksheet (Qty.)', Locked = true;
                }
                field(stockkeepingUnitExists; Rec."Stockkeeping Unit Exists")
                {
                    ApplicationArea = All;
                    Caption = 'Stockkeeping Unit Exists', Locked = true;
                }
                field(manufacturerCode; Rec."Manufacturer Code")
                {
                    ApplicationArea = All;
                    Caption = 'Manufacturer Code', Locked = true;
                }
                field(itemCategoryCode; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Category Code', Locked = true;
                }
                field(createdFromNonstockItem; Rec."Created From Nonstock Item")
                {
                    ApplicationArea = All;
                    Caption = 'Created From Catalog Item', Locked = true;
                }
                field(substitutesExist; Rec."Substitutes Exist")
                {
                    ApplicationArea = All;
                    Caption = 'Substitutes Exist', Locked = true;
                }
                field(qtyInTransit; Rec."Qty. in Transit")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. in Transit', Locked = true;
                }
                field(transOrdReceiptQty; Rec."Trans. Ord. Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Trans. Ord. Receipt (Qty.)', Locked = true;
                }
                field(transOrdShipmentQty; Rec."Trans. Ord. Shipment (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Trans. Ord. Shipment (Qty.)', Locked = true;
                }
                field(qtyAssignedToShip; Rec."Qty. Assigned to ship")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Assigned to ship', Locked = true;
                }
                field(qtyPicked; Rec."Qty. Picked")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Picked', Locked = true;
                }
                field(itemTrackingCode; Rec."Item Tracking Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Tracking Code', Locked = true;
                }
                field(lotNos; Rec."Lot Nos.")
                {
                    ApplicationArea = All;
                    Caption = 'Lot Nos.', Locked = true;
                }
                field(expirationCalculation; Rec."Expiration Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Expiration Calculation', Locked = true;
                }
                field(lotNumberFilter; Rec."Lot No. Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Lot No. Filter', Locked = true;
                }
                field(serialNumberFilter; Rec."Serial No. Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Serial No. Filter', Locked = true;
                }
                field(qtyOnPurchReturn; Rec."Qty. on Purch. Return")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Purch. Return', Locked = true;
                }
                field(qtyOnSalesReturn; Rec."Qty. on Sales Return")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. on Sales Return', Locked = true;
                }
                field(numberOfSubstitutes; Rec."No. of Substitutes")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Substitutes', Locked = true;
                }
                field(warehouseClassCode; Rec."Warehouse Class Code")
                {
                    ApplicationArea = All;
                    Caption = 'Warehouse Class Code', Locked = true;
                }
                field(specialEquipmentCode; Rec."Special Equipment Code")
                {
                    ApplicationArea = All;
                    Caption = 'Special Equipment Code', Locked = true;
                }
                field(putAwayTemplateCode; Rec."Put-away Template Code")
                {
                    ApplicationArea = All;
                    Caption = 'Put-away Template Code', Locked = true;
                }
                field(putAwayUnitOfMeasureCode; Rec."Put-away Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Put-away Unit of Measure Code', Locked = true;
                }
                field(physInvtCountingPeriodCode; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = All;
                    Caption = 'Phys Invt Counting Period Code', Locked = true;
                }
                field(lastCountingPeriodUpdate; Rec."Last Counting Period Update")
                {
                    ApplicationArea = All;
                    Caption = 'Last Counting Period Update', Locked = true;
                }
                field(lastPhysInvtDate; Rec."Last Phys. Invt. Date")
                {
                    ApplicationArea = All;
                    Caption = 'Last Phys. Invt. Date', Locked = true;
                }
                field(useCrossDocking; Rec."Use Cross-Docking")
                {
                    ApplicationArea = All;
                    Caption = 'Use Cross-Docking', Locked = true;
                }
                field(nextCountingStartDate; Rec."Next Counting Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'Next Counting Start Date', Locked = true;
                }
                field(nextCountingEndDate; Rec."Next Counting End Date")
                {
                    ApplicationArea = All;
                    Caption = 'Next Counting End Date', Locked = true;
                }
                field(identifierCode; Rec."Identifier Code")
                {
                    ApplicationArea = All;
                    Caption = 'Identifier Code', Locked = true;
                }
                field(unitOfMeasureId; Rec."Unit of Measure Id")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure Id', Locked = true;
                }
                field(taxGroupId; Rec."Tax Group Id")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Group Id', Locked = true;
                }
                field(singleLevelMaterialCost; Rec."Single-Level Material Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Material Cost', Locked = true;
                }
                field(singleLevelCapacityCost; Rec."Single-Level Capacity Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Capacity Cost', Locked = true;
                }
                field(singleLevelSubcontrdCost; Rec."Single-Level Subcontrd. Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Subcontrd. Cost', Locked = true;
                }
                field(singleLevelCapOvhdCost; Rec."Single-Level Cap. Ovhd Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Cap. Ovhd Cost', Locked = true;
                }
                field(singleLevelMfgOvhdCost; Rec."Single-Level Mfg. Ovhd Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Single-Level Mfg. Ovhd Cost', Locked = true;
                }
                field(overheadRate; Rec."Overhead Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Overhead Rate', Locked = true;
                }
                field(rolledUpSubcontractedCost; Rec."Rolled-up Subcontracted Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Subcontracted Cost', Locked = true;
                }
                field(rolledUpMfgOvhdCost; Rec."Rolled-up Mfg. Ovhd Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Mfg. Ovhd Cost', Locked = true;
                }
                field(rolledUpCapOverheadCost; Rec."Rolled-up Cap. Overhead Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Rolled-up Cap. Overhead Cost', Locked = true;
                }
                field(planningIssuesQty; Rec."Planning Issues (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Issues (Qty.)', Locked = true;
                }
                field(planningReceiptQty; Rec."Planning Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Receipt (Qty.)', Locked = true;
                }
                field(planningReleaseQty; Rec."Planning Release (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Release (Qty.)', Locked = true;
                }
                field(purchReqReceiptQty; Rec."Purch. Req. Receipt (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Req. Receipt (Qty.)', Locked = true;
                }
                field(purchReqReleaseQty; Rec."Purch. Req. Release (Qty.)")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Req. Release (Qty.)', Locked = true;
                }
                field(orderTrackingPolicy; Rec."Order Tracking Policy")
                {
                    ApplicationArea = All;
                    Caption = 'Order Tracking Policy', Locked = true;
                }
                field(prodForecastQuantityBase; Rec."Prod. Forecast Quantity (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Prod. Forecast Quantity (Base)', Locked = true;
                }
                field(productionForecastName; Rec."Production Forecast Name")
                {
                    ApplicationArea = All;
                    Caption = 'Demand Forecast Name', Locked = true;
                }
                field(componentForecast; Rec."Component Forecast")
                {
                    ApplicationArea = All;
                    Caption = 'Component Forecast', Locked = true;
                }
                field(critical; Rec.Critical)
                {
                    ApplicationArea = All;
                    Caption = 'Critical', Locked = true;
                }
                field(commonItemNumber; Rec."Common Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Common Item No.', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}

