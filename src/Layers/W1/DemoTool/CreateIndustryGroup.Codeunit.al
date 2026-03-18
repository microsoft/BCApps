codeunit 101557 "Create Industry Group"
{

    trigger OnRun()
    begin
        InsertData(XADVERT, XAdvertising);
        InsertData(XLAWYER, XLawyerorAccountant);
        InsertData(XMAN, XManufacturer);
        InsertData(XPRESS, XTVstationRadioorPress);
        InsertData(XRET, XRetail);
        InsertData(XWHOLE, XWholesale);
    end;

    var
        "Industry Group": Record "Industry Group";
        XADVERT: Label 'ADVERT';
        XAdvertising: Label 'Advertising';
        XLAWYER: Label 'LAWYER';
        XLawyerorAccountant: Label 'Lawyer or Accountant';
        XManufacturer: Label 'Manufacturer';
        XMAN: Label 'MAN';
        XPRESS: Label 'PRESS';
        XTVstationRadioorPress: Label 'TV-station, Radio or Press';
        XRET: Label 'RET';
        XRetail: Label 'Retail';
        XWHOLE: Label 'WHOLE';
        XWholesale: Label 'Wholesale';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Industry Group".Init();
        "Industry Group".Validate(Code, Code);
        "Industry Group".Validate(Description, Description);
        "Industry Group".Insert();
    end;
}

