codeunit 118007 "Update Customer Ship. Service"
{

    trigger OnRun()
    begin
        ModifyData('49525252', XDHL, XOVERNIGHT, '<1D>');
        ModifyData('49633663', XFEDEX, XNEXTDAY, '<1D>');
        ModifyData('49858585', '', '', '<5D>');
        ModifyData('10000', XDHL, XOVERNIGHT, '<1D>');
        ModifyData('50000', XDHL, XSTANDARD, '<2D>');
    end;

    var
        Customer: Record Customer;
        XDHL: Label 'DHL';
        XOVERNIGHT: Label 'OVERNIGHT';
        XFEDEX: Label 'FEDEX';
        XNEXTDAY: Label 'NEXT DAY';
        XSTANDARD: Label 'STANDARD';

    procedure ModifyData("CustomerNo.": Code[20]; ShippingAgentCode: Code[10]; ShippingAgentService: Code[10]; ShippingTime: Code[10])
    begin
        if Customer.Get("CustomerNo.") then begin
            Customer.Validate("Shipping Agent Code", ShippingAgentCode);
            Customer.Validate("Shipping Agent Service Code", ShippingAgentService);
            Evaluate(Customer."Shipping Time", ShippingTime);
            Customer.Validate("Shipping Time");
            Customer.Modify();
        end;
    end;
}

