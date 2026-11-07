codeunit 118844 "Create Dist. Prod. Order"
{

    trigger OnRun()
    begin
        InsertData(3, 0, 'LS-100', 19031203D, 15);
        InsertData(3, 0, 'LS-100', 19031203D, 12);
        InsertData(3, 0, 'LS-100', 19031203D, 10);
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

