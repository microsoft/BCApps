codeunit 101100 "Create Purch. Line Discount"
{

    trigger OnRun()
    begin
        InsertData('1924-W', '20000', 25, 3);
        InsertData('1924-W', '20000', 50, 4);
        InsertData('1924-W', '20000', 100, 5);
    end;

    var
        PurchLineDisc: Record "Purchase Line Discount";

    procedure InsertData("Item No.": Code[20]; "Vendor No.": Code[20]; "Minimum Quantity": Decimal; "Discount %": Decimal)
    begin
        PurchLineDisc.Init();
        PurchLineDisc.Validate("Item No.", "Item No.");
        PurchLineDisc.Validate("Vendor No.", "Vendor No.");
        PurchLineDisc.Validate("Minimum Quantity", "Minimum Quantity");
        PurchLineDisc.Validate("Line Discount %", "Discount %");
        PurchLineDisc.Insert(true);
    end;
}
