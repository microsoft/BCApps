codeunit 101222 "Create Ship-to Address"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('10000', XLEWESROAD, X2LewesRoad, XBrynPaulDunton, XEXW, XBLUE, 'US-GA 31772');
        InsertData('10000', XPARKROAD, X10ParkRoad, XJamesvanEaton, XEXW, XBLUE, 'US-GA 31772');
        InsertData('20000', XCHICAGO, X53EastActonRoad, XKatieMcAskillWhite, XEXW, XBLUE, 'US-IL 61236');
        InsertData('20000', XMIAMI, X55CrossCourt, XJohnFredericksen, XEXW, XBLUE, 'US-FL 37125');
    end;

    var
        "Ship-to Address": Record "Ship-to Address";
        DemoDataSetup: Record "Demo Data Setup";
        CreatePostCode: Codeunit "Create Post Code";
        XLEWESROAD: Label 'LEWES ROAD';
        X2LewesRoad: Label '2 Lewes Road';
        XBrynPaulDunton: Label 'Bryn Paul Dunton';
        XEXW: Label 'EXW';
        XBLUE: Label 'BLUE';
        XPARKROAD: Label 'PARK ROAD';
        X10ParkRoad: Label '10 Park Road';
        XJamesvanEaton: Label 'James van Eaton';
        XCHICAGO: Label 'CHICAGO';
        X53EastActonRoad: Label '53 East Acton Road';
        XKatieMcAskillWhite: Label 'Katie McAskill-White';
        XMIAMI: Label 'MIAMI';
        X55CrossCourt: Label '55 Cross Court';
        XJohnFredericksen: Label 'John Fredericksen';

    procedure InsertData("Customer No.": Code[20]; "Code": Code[10]; Address: Text[30]; Contact: Text[30]; "Shipment Method Code": Code[10]; "Location Code": Code[10]; "Post Code": Code[20])
    begin
        "Ship-to Address".Init();
        "Ship-to Address".Validate("Customer No.", "Customer No.");
        "Ship-to Address".Validate(Code, Code);
        "Ship-to Address".Validate(Address, Address);
        "Ship-to Address".Validate(Contact, Contact);
        "Ship-to Address".Validate("Shipment Method Code", "Shipment Method Code");
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Evaluation then
            "Ship-to Address".Validate("Location Code", "Location Code");
        "Ship-to Address"."Post Code" := CreatePostCode.FindPostCode("Post Code");
        "Ship-to Address".City := CreatePostCode.FindCity("Post Code");
        "Ship-to Address".Validate(
          County, CreatePostCode.GetCounty("Ship-to Address"."Post Code", "Ship-to Address".City));
        "Ship-to Address".Insert(true);
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData('10000', XLEWESROAD, X2LewesRoad, XBrynPaulDunton, XEXW, '', 'US-GA 31772');
        InsertData('10000', XPARKROAD, X10ParkRoad, XJamesvanEaton, XEXW, '', 'US-GA 31772');
        InsertData('20000', XCHICAGO, X53EastActonRoad, XKatieMcAskillWhite, XEXW, '', 'US-IL 61236');
        InsertData('20000', XMIAMI, X55CrossCourt, XJohnFredericksen, XEXW, '', 'US-FL 37125');
    end;
}

