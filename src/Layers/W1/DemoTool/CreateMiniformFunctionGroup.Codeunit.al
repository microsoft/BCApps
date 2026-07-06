codeunit 118856 "Create Miniform Function Group"
{

    trigger OnRun()
    begin
        InsertData(XCode, XDescription, ADCSFunction.KeyDef::Code);
        InsertData('ESC', XEscape, ADCSFunction.KeyDef::Esc);
        InsertData('FIRST', XFirstLine, ADCSFunction.KeyDef::First);
        InsertData('LAST', XLastLine, ADCSFunction.KeyDef::Last);
        InsertData('LNDN', XLinedown, ADCSFunction.KeyDef::LnDn);
        InsertData('LNUP', XLineup, ADCSFunction.KeyDef::LnUp);
        InsertData('PGDN', XPagedown, ADCSFunction.KeyDef::PgDn);
        InsertData('PGUP', XPageup, ADCSFunction.KeyDef::PgUp);
        InsertData('REGISTER', XRegisterWarehouseDocument, ADCSFunction.KeyDef::Register);
        InsertData('RESET', XResetQtytoNull, ADCSFunction.KeyDef::Reset);
    end;

    var
        ADCSFunction: Record "Miniform Function Group";
        XCode: Label 'Code';
        XDescription: Label 'Description';
        XEscape: Label 'Escape';
        XFirstLine: Label 'First Line';
        XLastLine: Label 'Last Line';
        XLinedown: Label 'Line down';
        XLineup: Label 'Line up';
        XPagedown: Label 'Page down';
        XPageup: Label 'Page up';
        XRegisterWarehouseDocument: Label 'Register Warehouse Document';
        XResetQtytoNull: Label 'Reset Qty. to Null';

    procedure InsertData("Code": Code[20]; Description: Text[30]; KeyDef: Option)
    begin
        ADCSFunction.Init();
        ADCSFunction.Validate(Code, Code);
        ADCSFunction.Validate(Description, Description);
        ADCSFunction.Validate(KeyDef, KeyDef);
        ADCSFunction.Insert(true);
    end;
}

