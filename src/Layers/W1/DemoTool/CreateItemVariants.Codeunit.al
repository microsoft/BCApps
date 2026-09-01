codeunit 119004 "Create Item Variants"
{

    trigger OnRun()
    begin
    end;

    var
        ItemSpec: Record "Item Variant";

    procedure InsertData(ItemNo: Code[20]; "Code": Code[10]; Description: Text[30]; Description2: Text[30])
    begin
        ItemSpec.Validate(Code, Code);
        ItemSpec.Validate("Item No.", ItemNo);
        ItemSpec.Validate(Description, Description);
        ItemSpec.Validate("Description 2", Description2);
        ItemSpec.Insert();
    end;
}

