codeunit 118006 "Create Shipping Agent Service"
{

    trigger OnRun()
    begin
        InsertData(XDHL, XOVERNIGHT, XOvernightdelivery, '<1D>');
        InsertData(XDHL, XSTANDARD, XStandarddelivery, '<2D>');
        InsertData(XFEDEX, XNEXTDAY, XNextdaydelivery, '<1D>');
        InsertData(XFEDEX, XSTANDARD, XStandarddelivery, '<2D>');
        InsertData(XOWNLOG, XNEXTDAY, XNextdaydelivery, '<1D>');
    end;

    var
        ShippingService: Record "Shipping Agent Services";
        XDHL: Label 'DHL';
        XOVERNIGHT: Label 'OVERNIGHT';
        XOvernightdelivery: Label 'Overnight delivery';
        XSTANDARD: Label 'STANDARD';
        XStandarddelivery: Label 'Standard delivery';
        XFEDEX: Label 'FEDEX';
        XNEXTDAY: Label 'NEXT DAY';
        XNextdaydelivery: Label 'Next day delivery';
        XOWNLOG: Label 'OWN LOG.';

    procedure InsertData(ShippingAgentCode: Code[10]; ShippingServiceCode: Code[10]; Description: Text[50]; ShippingTime: Code[10])
    begin
        ShippingService.Init();
        ShippingService.Validate("Shipping Agent Code", ShippingAgentCode);
        ShippingService.Validate(Code, ShippingServiceCode);
        ShippingService.Validate(Description, Description);
        Evaluate(ShippingService."Shipping Time", ShippingTime);
        ShippingService.Validate("Shipping Time");
        ShippingService.Insert();
    end;

    procedure AddDHLOvernightShippingAgentInfo(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Shipping Agent Code", XDHL);
        SalesHeader.Validate("Shipping Agent Service Code", XOVERNIGHT);
        SalesHeader.Validate("Package Tracking No.",
          XDHL + '_' + Format(CurrentDateTime, 0, '<Year><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>'));
        SalesHeader.Modify(true);
    end;

    procedure AddFedExNextDayShippingAgentInfo(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Shipping Agent Code", XFEDEX);
        SalesHeader.Validate("Shipping Agent Service Code", XNEXTDAY);
        SalesHeader.Validate("Package Tracking No.",
          XFEDEX + '_' + Format(CurrentDateTime, 0, '<Year><Month,2><Day,2><Hours24><Minutes,2><Seconds,2>'));
        SalesHeader.Modify(true);
    end;
}

