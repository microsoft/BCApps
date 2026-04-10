codeunit 132462 "Test Price Calculation Switch"
{
    EventSubscriberInstance = Manual;

    var
        DisabledNative: Boolean;
        DisabledBestPrice: Boolean;

    procedure IsNativeDisabled(): Boolean;
    begin
        exit(DisabledNative);
    end;

    procedure IsBestPriceDisabled(): Boolean;
    begin
        exit(DisabledBestPrice)
    end;

    procedure DisableNative()
    begin
        DisabledNative := true;
    end;

    procedure DisableBestPrice()
    begin
        DisabledBestPrice := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V15", 'OnIsDisabled', '', false, false)]
    local procedure DisablePriceCalcNative(var Disabled: Boolean)
    begin
        Disabled := DisabledNative;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Calculation - V16", 'OnIsDisabled', '', false, false)]
    local procedure DisablePriceCalcBestPrice(var Disabled: Boolean)
    begin
        Disabled := DisabledBestPrice;
    end;
}