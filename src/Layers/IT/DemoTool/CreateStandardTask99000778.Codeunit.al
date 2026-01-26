codeunit 161390 "Create Standard Task-99000778"
{

    trigger OnRun()
    begin
        InsertData('1', XPriceDressing);
        InsertData('2', XPricePainting);
    end;

    var
        XPriceDressing: Label 'Price for dressing - Vendor 70000 - WorkCenter 500';
        XPricePainting: Label 'Price for painting - Vendor 70000 - WorkCenter 500';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        StandardTask: Record "Standard Task";
    begin
        StandardTask.Init();
        StandardTask.Code := Code;
        StandardTask.Description := Description;
        StandardTask.Insert();
    end;
}

