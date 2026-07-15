codeunit 50021 "CWM Shipping Charge"
{
    // Anti-pattern: every call site must 'case' over the enum. Each new shipping
    // method forces a synchronized edit to each of these blocks instead of a
    // single new interface implementation.
    procedure GetRate(Method: Enum "CWM Shipping Method"; Weight: Decimal): Decimal
    begin
        case Method of
            Method::Standard:
                exit(Weight * 1.5);
            Method::Express:
                exit((Weight * 1.5) + 25);
        end;
    end;

    procedure GetDeliveryDays(Method: Enum "CWM Shipping Method"): Integer
    begin
        case Method of
            Method::Standard:
                exit(5);
            Method::Express:
                exit(1);
        end;
    end;

    procedure GetCarrierName(Method: Enum "CWM Shipping Method"): Text
    begin
        case Method of
            Method::Standard:
                exit('Ground');
            Method::Express:
                exit('Air');
        end;
    end;
}
