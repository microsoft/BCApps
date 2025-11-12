codeunit 101222 "Create Ship-to Address"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('10000', XDUDLEY, X2LewesRoad, '', XBrynPaulDunton, XEXW, XBLUE, CreatePostCode.Convert('GB-DY5 4DJ'));
        InsertData('10000', XPARKROAD, X10ParkRoad, '', XJamesvanEaton, XEXW, XBLUE, CreatePostCode.Convert('GB-B27 4KT'));
        InsertData('20000', XEASTACTON, X53EastActonRoad, '', XKatieMcAskillWhite, XEXW, XBLUE, CreatePostCode.Convert('GB-CV6 1GY'));
        InsertData('20000', XMANCHESTER, X55CrossCourt, '', XJohnFredericksen, XEXW, XBLUE, CreatePostCode.Convert('GB-MO2 4RT'));
    end;

    var
        "Ship-to Address": Record "Ship-to Address";
        DemoDataSetup: Record "Demo Data Setup";
        CreatePostCode: Codeunit "Create Post Code";
        XDUDLEY: Label 'DUDLEY';
        X2LewesRoad: Label '2 Lewes Road';
        XBrynPaulDunton: Label 'Bryn Paul Dunton';
        XEXW: Label 'EXW';
        XBLUE: Label 'BLUE';
        XPARKROAD: Label 'PARK ROAD';
        X10ParkRoad: Label '10 Park Road';
        XJamesvanEaton: Label 'James van Eaton';
        XEASTACTON: Label 'EAST ACTON';
        X53EastActonRoad: Label '53 East Acton Road';
        XKatieMcAskillWhite: Label 'Katie McAskill-White';
        XMANCHESTER: Label 'MANCHESTER';
        X55CrossCourt: Label '55 Cross Court';
        XJohnFredericksen: Label 'John Fredericksen';
        XCHELTENHAM: Label 'CHELTENHAM';
        XLONDON: Label 'LONDON';
        XFLEET: Label 'FLEET';
        XTWYCROSS: Label 'Twycross';
        XMontpellierHouse: Label 'Montpellier House';
        XMontpellierDrive: Label 'Montpellier Drive';
        X2KingdomStreet: Label 'Kingdom Street, 2';
        XPaddington: Label 'Paddington';
        XBeaconHillRoad: Label 'Beacon Hill Road';
        XChurchCrookham: Label 'Church Crookham';
        XManorPark: Label 'Manor Park';

    procedure InsertData("Customer No.": Code[20]; "Code": Code[10]; Address: Text[30]; Address2: Text[30]; Contact: Text[30]; "Shipment Method Code": Code[10]; "Location Code": Code[10]; "Post Code": Code[20])
    begin
        "Ship-to Address".Init();
        "Ship-to Address".Validate("Customer No.", "Customer No.");
        "Ship-to Address".Validate(Code, Code);
        "Ship-to Address".Validate(Address, Address);
        "Ship-to Address".Validate("Address 2", Address2);
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
        InsertData('10000', XCHELTENHAM, XMontpellierHouse, XMontpellierDrive, '', XEXW, XBLUE, CreatePostCode.Convert('GB-GL50 1TY'));
        InsertData('10000', XLONDON, X2KingdomStreet, XPaddington, '', XEXW, XBLUE, CreatePostCode.Convert('GB-W2 6BD'));
        InsertData('20000', XFLEET, XBeaconHillRoad, XChurchCrookham, '', XEXW, XBLUE, CreatePostCode.Convert('GB-GU52 8DY'));
        InsertData('20000', UpperCase(XTWYCROSS), XManorPark, XTWYCROSS, '', XEXW, XBLUE, CreatePostCode.Convert('GB-CV9 3QN'));
    end;
}

