codeunit 101702 "Create Purchase Price"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('70000', '30000', 148);
        InsertData('70001', '30000', 194);
        InsertData('70002', '30000', 138);
        InsertData('70003', '30000', 142);
        InsertData('70010', '30000', 250);
        InsertData('70011', '30000', 348);
        InsertData('70040', '30000', 520);
        InsertData('70041', '30000', 113);
        InsertData('70060', '30000', 63);
        InsertData('70100', '30000', 14);
        InsertData('70101', '30000', 14);
        InsertData('70102', '30000', 14);
        InsertData('70103', '30000', 14);
        InsertData('70104', '30000', 14);
        InsertData('70200', '30000', 7);
        InsertData('70201', '30000', 6);
    end;

    var
        PurchPrice: Record "Purchase Price";
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Item No.": Code[20]; "Vendor No.": Code[20]; "Direct Unit Cost": Decimal)
    begin
        PurchPrice.Init();
        PurchPrice.Validate("Item No.", "Item No.");
        PurchPrice.Validate("Vendor No.", "Vendor No.");
        PurchPrice.Validate("Direct Unit Cost",
          Round("Direct Unit Cost" * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));
        PurchPrice.Insert(true);
    end;
}
