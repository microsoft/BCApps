codeunit 101291 "Create Shipping Agent"
{

    trigger OnRun()
    begin
        InsertData(XOWNLOG, XOwnLogistics, '');
        InsertData('DHL', 'DHL Systems, Inc. AU', 'www.dhl.com/en/express/tracking.html?AWB=%1&brand=DHL');
        InsertData('FEDEX', 'Federal Express Corporation AU', 'www.fedex.com/apps/fedextrack/?action=track&trackingnumber=%1');
        InsertData('UPS', 'UPS Australia P/L', 'wwwapps.ups.com/tracking/tracking.cgi?tracknum=%1');
        InsertData('AUPOST', 'AU Post Express Courier International', 'ice.auspost.com.au');
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

