codeunit 119076 "Make Mfg. Order from Sales"
{

    trigger OnRun()
    begin
        InsertData('109005', '1001', "Production Order Status"::"Firm Planned", "Create Production Order Type"::ItemOrder);
    end;

    var
        Item: Record Item;
        SalesOrderLine: Record "Sales Line";
        ProdOrderFromSale: Codeunit "Create Prod. Order from Sale";

    procedure InsertData(SalesNo: Code[20]; ItemNo: Code[20]; NewStatus: Enum "Production Order Status"; NewOrderType: Enum "Create Production Order Type")
    begin
        ProdOrderFromSale.SetHideValidationDialog(true);

        SalesOrderLine.SetCurrentKey("Document Type", Type, "No.");
        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
        SalesOrderLine.SetRange("Document No.", SalesNo);
        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Item);
        SalesOrderLine.SetRange("No.", ItemNo);

        if SalesOrderLine.Find('-') then
            repeat
                Item.Get(ItemNo);
                if Item."Replenishment System" = Item."Replenishment System"::"Prod. Order" then
                    ProdOrderFromSale.CreateProductionOrder(
                      SalesOrderLine,
                      NewStatus,
                      NewOrderType);
            until SalesOrderLine.Next() = 0;
    end;
}

