codeunit 118841 "Create Dist. Item Variants"
{

    trigger OnRun()
    begin
        InsertData('LS-75', 'LS-75-B', XBlack, '');
        InsertData('LS-10PC', 'LS-10PC-B', XBlack, '');
    end;

    var
        ItemSpec: Record "Item Variant";
        XBlack: Label 'Black';

    procedure InsertData(ItemNo: Code[20]; "Code": Code[10]; Description: Text[30]; Description2: Text[30])
    begin
        ItemSpec.Validate(Code, Code);
        ItemSpec.Validate("Item No.", ItemNo);
        ItemSpec.Validate(Description, Description);
        ItemSpec.Validate("Description 2", Description2);
        ItemSpec.Insert();
    end;
}

