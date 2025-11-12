codeunit 119002 "Setup Manufacturing on Item"
{

    trigger OnRun()
    begin
        ModifyItem('1000', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1001', 10, '', 0, 3, false, 1, 0, 0, 0, 0, 0, '', 0, 1, 0.001, '<>', 0, 0);
        ModifyItem('1100', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1200', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1150', 10, '', 5, 1, true, 0, 0, 10, 100, 0, 10, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1250', 10, '', 5, 1, true, 0, 0, 10, 100, 0, 10, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1300', 10, '', 5, 1, true, 0, 0, 10, 100, 0, 10, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1700', 10, '', 5, 1, true, 0, 0, 10, 100, 0, 10, '', 0, 1, 0.001, '<1W>', 100, 0);
        ModifyItem('1110', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 1.05);
        ModifyItem('1120', 10, '', 5, 1, true, 0, 10, 5, 0, 5, 2, '', 1, 0, 0.001, '<1M>', 10000, 2);
        ModifyItem('1150', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 1, 0.001, '<1M>', 100, 0.5);
        ModifyItem('1151', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 0.45);
        ModifyItem('1155', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 0.77);
        ModifyItem('1251', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 0.33);
        ModifyItem('1255', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 0.9);
        ModifyItem('1160', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 1.23);
        ModifyItem('1170', 10, '', 5, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 1.75);
        ModifyItem('1310', 10, '', 0, 1, true, 0, 10, 5, 100, 5, 2, '', 0, 0, 0.001, '<1M>', 100, 1.99);
        ModifyItem('1320', 10, '', 0, 1, true, 0, 10, 5, 100, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 4.66);
        ModifyItem('1330', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 5.88);
        ModifyItem('1400', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 3.9);
        ModifyItem('1450', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 3.9);
        ModifyItem('1500', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 5.2);
        ModifyItem('1600', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 2.7);
        ModifyItem('1710', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 4.5);
        ModifyItem('1720', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 4.8);
        ModifyItem('1800', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 2.12);
        ModifyItem('1850', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 7.2);
        ModifyItem('1900', 10, '', 0, 1, true, 0, 0, 0, 0, 0, 0, '', 0, 0, 0.001, '<1M>', 100, 15.7);

        LowLevelCodeCalculator.Calculate(false);
    end;

    var
        Item: Record Item;
        LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";

    procedure ModifyItem(ItemNo: Code[20]; CostingLotSize: Decimal; LastSerialNo: Code[10]; ScrapPct: Decimal; ReorderingPolicy: Option " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot"; IncludeInventory: Boolean; ManufacturingPolicy: Option "Make-to-Stock","Make-to-Order"; DiscrOrderQty: Decimal; MinimumLotSize: Decimal; MaximumLotSize: Decimal; SafetyStock: Decimal; LotMultiple: Decimal; SafetyLeadTime: Text[20]; ConsumpCalculation: Option "None",Manual,Released,Finished,"Operation Input","Operation Output"; ReplenishmentSystem: Option Purchase,"Prod. Order"; RoundPrecision: Decimal; TimeBucket: Code[20]; ReorderQty: Decimal; UnitCost: Decimal)
    begin
        Item.Get(ItemNo);
        Item.Validate("Lot Size", CostingLotSize);
        Item.Validate("Serial Nos.", LastSerialNo);
        Item.Validate("Scrap %", ScrapPct);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Discrete Order Quantity", DiscrOrderQty);
        Item.Validate("Minimum Order Quantity", MinimumLotSize);
        Item.Validate("Maximum Order Quantity", MaximumLotSize);
        Item.Validate("Safety Stock Quantity", SafetyStock);
        Item.Validate("Order Multiple", LotMultiple);
        Evaluate(Item."Safety Lead Time", SafetyLeadTime);
        Item.Validate("Safety Lead Time");
        Item.Validate("Flushing Method", ConsumpCalculation);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Rounding Precision", RoundPrecision);
        Evaluate(Item."Time Bucket", TimeBucket);
        Item.Validate("Time Bucket");
        Item.Validate("Reorder Quantity", ReorderQty);
        Item.Validate("Standard Cost", UnitCost);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify();
    end;
}

