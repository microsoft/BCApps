codeunit 101014 "Create Location"
{

    trigger OnRun()
    begin
        InsertData(
          XYELLOW, XYellowWarehouse, '',
          XMainBristolStreet10, '',
          CreatePostCode.Convert('GB-BS3 6KL'), XGB,
          X4401052144987, X4401052140000,
          '', '',
          XJeanneBosworth,
          false,
          false,
          false,
          false);

        InsertData(
          XGREEN, XGreenWarehouse, '',
          XMainLiverpoolStreet5, '',
          CreatePostCode.Convert('GB-L18 6SA'), XGB,
          X4403098741299, X4403098741200,
          '', '',
          XChrisPreston,
          false,
          false,
          false,
          false);

        InsertData(
          XBLUE, XBlueWarehouse, '',
          XSouthEastStreet3, '',
          CreatePostCode.Convert('GB-B27 4KT'), XGB,
          X4402082074533, X4402082075000,
          '', '',
          XJeffSmith,
          false,
          false,
          false,
          false);

        InsertData(
          XRED, XRedWarehouse, '',
          XMainAshfordStreet2, '',
          CreatePostCode.Convert('GB-TN27 6YD'), XGB,
          X4405014240001, X4405014240002,
          '', '',
          XCarolePoland,
          false,
          false,
          false,
          false);

        InsertData(
          XWHITE, XWhiteWarehouse, '',
          XMerrilyGroveAvenue62, '',
          CreatePostCode.Convert('GB-WC1 2GS'), XGB,
          X4405045679771, X4405045679772,
          '', '',
          '',
          false,
          false,
          false,
          false);

        InsertData(
          XSilver, XSilverWarehouse, '',
          XPier102, '',
          CreatePostCode.Convert('GB-WC1 2GS'), XGB,
          X4405045679771, X4405045679772, '', '',
          '',
          false,
          false,
          false,
          false);

        ModifyData(XGREEN, '<1D>', '<2D>');
        ModifyData(XYELLOW, '<1D>', '<1D>');
    end;

    var
        Location: Record Location;
        CreatePostCode: Codeunit "Create Post Code";
        XMAIN: Label 'MAIN';
        XMainWarehouse: Label 'Main Warehouse';
        XEAST: Label 'EAST';
        XEastWarehouse: Label 'East Warehouse';
        XWEST: Label 'WEST';
        XWestWarehouse: Label 'West Warehouse';
        XYELLOW: Label 'YELLOW';
        XYellowWarehouse: Label 'Yellow Warehouse';
        XMainBristolStreet10: Label 'Main Bristol Street, 10';
        XGB: Label 'GB';
        X4401052144987: Label '+44-(0)10 5214 4987';
        X4401052140000: Label '+44-(0)10 5214 0000';
        XJeanneBosworth: Label 'Jeanne Bosworth';
        XGREEN: Label 'GREEN';
        XGreenWarehouse: Label 'Green Warehouse';
        XMainLiverpoolStreet5: Label 'Main Liverpool Street, 5';
        X4403098741299: Label '+44-(0)30 9874 1299';
        X4403098741200: Label '+44-(0)30 9874 1200';
        XChrisPreston: Label 'Chris Preston';
        XBLUE: Label 'BLUE';
        XBlueWarehouse: Label 'Blue Warehouse';
        XSouthEastStreet3: Label 'South East Street, 3';
        X4402082074533: Label '+44-(0)20 8207 4533';
        X4402082075000: Label '+44-(0)20 8207 5000';
        XJeffSmith: Label 'Jeff Smith';
        XRED: Label 'RED';
        XRedWarehouse: Label 'Red Warehouse';
        XMainAshfordStreet2: Label 'Main Ashford Street, 2';
        X4405014240001: Label '+44-(0)50 1424 0001';
        X4405014240002: Label '+44-(0)50 1424 0002';
        XCarolePoland: Label 'Carole Poland';
        XWHITE: Label 'WHITE';
        XWhiteWarehouse: Label 'White Warehouse';
        XMerrilyGroveAvenue62: Label 'Merrily Grove Avenue 6, 2';
        X4405045679771: Label '+44-(0)50 4567 9771';
        X4405045679772: Label '+44-(0)50 4567 9772';
        XSilver: Label 'Silver';
        XSilverWarehouse: Label 'Silver Warehouse';
        XPier102: Label 'Pier 10, 2';
        X80GreatEasternStreet: Label 'Great Eastern Street, 80';
        XUKCampusBldg5: Label 'UK Campus Bldg 5';
        XThamesValleyPark: Label 'Thames Valley Park';
        XCelticWay: Label 'Celtic Way';
        XJackPotter: Label 'Jack Potter';
        XEleanorFaulkner: Label 'Eleanor Faulkner';
        XOscarGreenwood: Label 'Oscar Greenwood';

    procedure InsertData("Code": Code[10]; Name: Text[30]; Name2: Text[30]; Address: Text[30]; Address2: Text[30]; PostCode: Code[20]; CountryCode: Code[10]; PhoneNo: Text[30]; FaxNo: Text[30]; EMail: Text[30]; HomePage: Text[30]; Contact: Text[30]; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        Location.Init();
        Location.Validate(Code, Code);
        Location.Validate(Name, Name);
        Location.Validate("Name 2", Name2);
        Location.Validate(Address, Address);
        Location.Validate("Address 2", Address2);
        Location.Validate("Country/Region Code", CountryCode);
        Location."Post Code" := CreatePostCode.FindPostCode(PostCode);
        Location.City := CreatePostCode.FindCity(PostCode);
        Location.Validate(Contact, Contact);
        Location.Validate("Phone No.", PhoneNo);
        Location.Validate("Fax No.", FaxNo);
        Location.Validate("E-Mail", EMail);
        Location.Validate("Home Page", HomePage);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Pick", RequirePick);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate(County, CreatePostCode.GetCounty(Location."Post Code", Location.City));
        Location.Insert();
    end;

    procedure ModifyData(LocationCode: Code[10]; OutboundWhseHandlingTime: Code[10]; InboundWhseHandlingTime: Code[10])
    begin
        if Location.Get(LocationCode) then begin
            Evaluate(Location."Outbound Whse. Handling Time", OutboundWhseHandlingTime);
            Location.Validate("Outbound Whse. Handling Time");

            Evaluate(Location."Inbound Whse. Handling Time", InboundWhseHandlingTime);
            Location.Validate("Inbound Whse. Handling Time");
            Location.Modify();
        end;
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(
          XMAIN, XMainWarehouse, '',
          XUKCampusBldg5, XThamesValleyPark,
          CreatePostCode.Convert('GB-RG6 1WG'), XGB,
          X4401052144987, X4401052140000,
          '', '',
          XEleanorFaulkner,
          false,
          false,
          false,
          false);

        InsertData(
          XEAST, XEastWarehouse, '',
          X80GreatEasternStreet, '',
          CreatePostCode.Convert('GB-EC2A 3JL'), XGB,
          X4403098741299, X4403098741200,
          '', '',
          XJackPotter,
          false,
          false,
          false,
          false);

        InsertData(
          XWEST, XWestWarehouse, '',
          XCelticWay, '',
          CreatePostCode.Convert('GB-NP10 8BE'), XGB,
          X4402082074533, X4402082075000,
          '', '',
          XOscarGreenwood,
          false,
          false,
          false,
          false);
    end;

    procedure GetLocationCode(LocationCode: Text): Code[10]
    begin
        case UpperCase(LocationCode) of
            'XMAIN':
                exit(XMAIN);
            'XEAST':
                exit(XEAST);
            'XWEST':
                exit(XWEST);
            'XYELLOW':
                exit(XYELLOW);
            'XGREEN':
                exit(XGREEN);
            'XBLUE':
                exit(XBLUE);
            'XRED':
                exit(XRED);
            'XWHITE':
                exit(XWHITE);
            'XSILVER':
                exit(XSilver);
            else
                Error('Unknown Location Code %1.', LocationCode);
        end;
    end;
}
