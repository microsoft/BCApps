codeunit 118862 "Add WMS BOM Component"
{

    trigger OnRun()
    begin
        InsertData('LS-100', 10000, 'LSU-15', 1);
        InsertData('LS-100', 20000, 'LSU-8', 1);
        InsertData('LS-100', 30000, 'LSU-4', 1);
        InsertData('LS-100', 40000, 'FF-100', 1);
        InsertData('LS-100', 50000, 'C-100', 1);
        InsertData('LS-100', 60000, 'HS-100', 1);
        InsertData('LS-100', 70000, 'SPK-100', 4);
    end;

    var
        "Bom Component": Record "BOM Component";

    procedure InsertData("Parent Item No.": Code[20]; "Line No.": Integer; "No.": Code[20]; "Quantity per": Decimal)
    begin
        "Bom Component".Init();
        "Bom Component".Validate("Parent Item No.", "Parent Item No.");
        "Bom Component".Validate("Line No.", "Line No.");
        "Bom Component".Validate(Type, "Bom Component".Type::Item);
        "Bom Component".Validate("No.", "No.");
        "Bom Component".Validate("Quantity per", "Quantity per");
        "Bom Component".Insert(true);
    end;
}

