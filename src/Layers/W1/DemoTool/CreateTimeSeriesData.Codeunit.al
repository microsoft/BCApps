codeunit 119300 "Create Time Series Data"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        ItemSalesData: Record "Item Sales Data" temporary;
        ItemSalesPath: Text;
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Path to Picture Folder" = '' then
            ItemSalesPath := TemporaryPath() + '\..\MachineLearning\itemsales.xml'
        else
            ItemSalesPath := DemoDataSetup."Path to Picture Folder" + 'MachineLearning\itemsales.xml';

        CreateEvaluationData.SetSeed(582);
        ReadItemSalesData(ItemSalesData, ItemSalesPath);
        ProcessItemSalesData(ItemSalesData);
    end;

    var
        CreateEvaluationData: Codeunit "Interface Evaluation Data";
        Periods: Integer;
        MaxNumberOfInvoices: Integer;

    local procedure ProcessItemSalesData(var ItemSalesData: Record "Item Sales Data" temporary)
    var
        TempInQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary;
        TempOutQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary;
        TempItemLineBuffer: Record "Item Line Buffer" temporary;
        MakeAdjustments: Codeunit "Make Adjustments";
        Period: Integer;
    begin
        CreateEvaluationData.CreateInventory(MakeAdjustments.AdjustDate(GetFirstPostingDate(1)));
        for Period := 1 to Periods do begin
            CreateEvaluationData.SetFirstPostingDate(CalcDate('<+7D>', GetFirstPostingDate(Period)));
            CreateEvaluationData.SetLastPostingDate(GetLastPostingDate(Period));
            CalculatePurchSalesQty(TempInQuantityAllocationBuffer, ItemSalesData, Period);
            CreateEvaluationData.AllocateQty(TempInQuantityAllocationBuffer, TempOutQuantityAllocationBuffer, MaxNumberOfInvoices);
            CreateEvaluationData.AllocateQtyToDocuments(TempOutQuantityAllocationBuffer, TempItemLineBuffer, 0);
            CreateEvaluationData.CreatePurchSalesDocuments(TempItemLineBuffer);
            TempInQuantityAllocationBuffer.Reset();
            TempOutQuantityAllocationBuffer.Reset();
            TempItemLineBuffer.Reset();
            TempInQuantityAllocationBuffer.DeleteAll();
            TempOutQuantityAllocationBuffer.DeleteAll();
            TempItemLineBuffer.DeleteAll();
        end;
    end;

    local procedure ReadItemSalesData(var ItemSalesData: Record "Item Sales Data" temporary; Filename: Text)
    var
        TempXMLBufferSales: Record "XML Buffer" temporary;
        TempXMLBufferPeriods: Record "XML Buffer" temporary;
        ItemNo: Code[10];
        Quantity: Decimal;
        Period: Integer;
        ScaleToAverageQuantity: Decimal;
        ItemSalesFile: File;
        InStr: InStream;
    begin
        ItemSalesFile.Open(Filename);
        ItemSalesFile.CreateInStream(InStr);
        TempXMLBufferSales.Load(InStr);
        Evaluate(MaxNumberOfInvoices, TempXMLBufferSales.GetAttributeValueAsText('MaxNumberOfInvoicesPerPeriod'));
        Evaluate(Periods, TempXMLBufferSales.GetAttributeValueAsText('Periods'));
        TempXMLBufferSales.FindChildElements(TempXMLBufferSales);
        if TempXMLBufferSales.FindSet() then
            repeat
                TempXMLBufferSales.FindChildElements(TempXMLBufferPeriods);
                ItemNo := CopyStr(TempXMLBufferSales.GetAttributeValueAsText('item'), 1, MaxStrLen(ItemNo));
                Evaluate(ScaleToAverageQuantity, TempXMLBufferSales.GetAttributeValueAsText('ScaleToAverageQuantity'));
                Period := 1;
                if TempXMLBufferPeriods.FindSet() then
                    repeat
                        Evaluate(Quantity, TempXMLBufferPeriods.GetAttributeValueAsText('OriginalQuantity'));
                        ItemSalesData.Validate("Item No.", ItemNo);
                        ItemSalesData.Validate(Quantity, Quantity);
                        ItemSalesData.Validate(Period, Period);
                        ItemSalesData.Validate("Scale to Average Quantity", ScaleToAverageQuantity);
                        ItemSalesData.Insert();
                        Period += 1;
                    until TempXMLBufferPeriods.Next() = 0;
            until TempXMLBufferSales.Next() = 0;
    end;

    local procedure CalculatePurchSalesQty(var TempQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary; var ItemSalesData: Record "Item Sales Data" temporary; Period: Integer)
    var
        Item: Record Item;
        SalesQty: Decimal;
        AverageSales: Decimal;
        ScaleFactor: Decimal;
    begin
        CreateEvaluationData.SetSeed(0);
        TempQuantityAllocationBuffer.DeleteAll();
        Item.SetFilter("No.", '*-S');
        if Item.FindSet() then
            repeat
                ItemSalesData.Reset();
                ItemSalesData.SetRange("Item No.", Item."No.");
                ItemSalesData.CalcSums(Quantity);
                AverageSales := ItemSalesData.Quantity / ItemSalesData.Count();
                ItemSalesData.SetRange(Period, Period);
                if ItemSalesData.FindSet() then begin
                    ScaleFactor := ItemSalesData."Scale to Average Quantity" / AverageSales;
                    repeat
                        SalesQty := Round(ItemSalesData.Quantity * ScaleFactor, 1);
                        AllocateQuantities(TempQuantityAllocationBuffer, Item."No.", SalesQty, 1); // Purchases
                        AllocateQuantities(TempQuantityAllocationBuffer, Item."No.", SalesQty, 2); // Sales
                    until ItemSalesData.Next() = 0;
                end;
            until Item.Next() = 0;
    end;

    local procedure GetLastPostingDate(Period: Integer): Date
    begin
        exit(CalcDate('<CM>', GetFirstPostingDate(Period)));
    end;

    local procedure GetFirstPostingDate(Period: Integer): Date
    begin
        exit(CalcDate('<+' + Format(Period - 1) + 'M>', GetMinPostingDate()));
    end;

    local procedure GetMinPostingDate(): Date
    begin
        exit(CalcDate('<-15M>', CreateEvaluationData.GetCurrentDay()));
    end;

    local procedure AllocateQuantities(var TempQuantityAllocationBuffer: Record "Quantity Allocation Buffer" temporary; ItemNo: Code[20]; Quantity: Decimal; Index: Integer)
    begin
        TempQuantityAllocationBuffer.Validate("Item No.", ItemNo);
        TempQuantityAllocationBuffer.Index := Index;
        TempQuantityAllocationBuffer.Quantity := Quantity;
        TempQuantityAllocationBuffer.Insert();
    end;
}

