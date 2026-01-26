codeunit 101222 "Create Ship-to Address"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('10000', XCALGARY, X6455MacleodTrailSW, XBrynPaulDunton, XEXW, XBLUE, 'CA-AB T2H 0K8');
        InsertData('10000', XEDMONTON, X17238882170Street, XJamesvanEaton, XEXW, XBLUE, 'CA-AB T5T 4J2');
        InsertData('20000', XVANCOUVER, X701WestGeorgiaStreet, XKatieMcAskillWhite, XEXW, XBLUE, 'CA-BC V7Y 1GS');
        InsertData('20000', XTORONTO, X220YongeStreet, XJohnFredericksen, XEXW, XBLUE, 'CA-ON M5B 2H1');
    end;

    var
        "Ship-to Address": Record "Ship-to Address";
        DemoDataSetup: Record "Demo Data Setup";
        CreatePostCode: Codeunit "Create Post Code";
        XCALGARY: Label 'CALGARY';
        X6455MacleodTrailSW: Label '6455 Macleod Trail SW';
        XBrynPaulDunton: Label 'Bryn Paul Dunton';
        XEXW: Label 'EXW';
        XBLUE: Label 'BLUE';
        XEDMONTON: Label 'EDMONTON';
        X17238882170Street: Label '1723,  8882 170 Street';
        XJamesvanEaton: Label 'James van Eaton';
        XVANCOUVER: Label 'VANCOUVER';
        X701WestGeorgiaStreet: Label '701 West Georgia Street';
        XKatieMcAskillWhite: Label 'Katie McAskill-White';
        XTORONTO: Label 'TORONTO';
        X220YongeStreet: Label '220 Yonge Street';
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
        InsertData('10000', XCALGARY, X6455MacleodTrailSW, XBrynPaulDunton, XEXW, '', 'CA-AB T2H 0K8');
        InsertData('10000', XEDMONTON, X17238882170Street, XJamesvanEaton, XEXW, '', 'CA-AB T5T 4J2');
        InsertData('20000', XVANCOUVER, X701WestGeorgiaStreet, XKatieMcAskillWhite, XEXW, '', 'CA-BC V7Y 1GS');
        InsertData('20000', XTORONTO, X220YongeStreet, XJohnFredericksen, XEXW, '', 'CA-ON M5B 2H1');
    end;
}

