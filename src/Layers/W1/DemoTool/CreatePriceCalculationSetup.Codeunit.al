codeunit 101703 "Create Price Calculation Setup"
{

    trigger OnRun()
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
    begin
        PriceCalculationMgt.Run();
        SetCodeunitAsDefault(Codeunit::"Price Calculation - V15");
    end;

    local procedure SetCodeunitAsDefault(NewImplementation: Integer)
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange(Default, true);
        PriceCalculationSetup.ModifyAll(Default, false);
        PriceCalculationSetup.Reset();
        PriceCalculationSetup.SetRange(Implementation, NewImplementation);
        PriceCalculationSetup.ModifyAll(Default, true);
    end;
}

