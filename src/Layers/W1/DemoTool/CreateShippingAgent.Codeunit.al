codeunit 101291 "Create Shipping Agent"
{

    trigger OnRun()
    begin
        InsertData('DHL', 'DHL Systems, Inc.', 'www.dhl.com/en/express/tracking.html?AWB=%1&brand=DHL');
        InsertData('FEDEX', 'Federal Express Corporation', 'www.fedex.com/apps/fedextrack/?action=track&trackingnumber=%1');
        InsertData('UPS', 'United Parcel Service of America, Inc.', 'wwwapps.ups.com/tracking/tracking.cgi?tracknum=%1');
        InsertData(XOWNLOG, XOwnLogistics, '');
    end;

    var
        "Shipping Agent": Record "Shipping Agent";
        XOWNLOG: Label 'OWN LOG.';
        XOwnLogistics: Label 'Own Logistics';

    procedure InsertData("Code": Code[10]; Name: Text[50]; "Internet Address": Text[250])
    begin
        "Shipping Agent".Init();
        "Shipping Agent".Validate(Code, Code);
        "Shipping Agent".Validate(Name, Name);
        "Shipping Agent".Validate("Internet Address", "Internet Address");
        "Shipping Agent".Insert();
    end;
}

