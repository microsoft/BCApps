codeunit 119071 "Create Mfg. Order"
{

    trigger OnRun()
    begin
        InsertData(1, 0, '1000', 19031203D, 2);
        InsertData(2, 0, '1000', 19030910D, 5);
        InsertData(2, 0, '1000', 19030914D, 27);
        InsertData(2, 0, '1000', 19030920D, 16);
        InsertData(2, 0, '1000', 19030923D, 10);
        InsertData(2, 0, '1000', 19030925D, 16);
    end;

    var
        ProductionOrder: Record "Production Order";
        CA: Codeunit "Make Adjustments";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";

    procedure InsertData(DocumentType: Integer; SourceType: Integer; SourceNo: Code[20]; DueDate: Date; Quantity: Decimal)
    begin
        Clear(ProductionOrder);
        ProductionOrder.Validate(Status, DocumentType);
        ProductionOrder.Insert(true);
        ProductionOrder.Validate("Source Type", SourceType);
        ProductionOrder.Validate("Source No.", SourceNo);
        ProductionOrder.Validate("Due Date", CA.AdjustDate(DueDate));
        ProductionOrder.Validate(Quantity, Quantity);
        ProductionOrder.Modify();
        CreateProdOrderLines.Copy(ProductionOrder, 1, '', true);
    end;
}

