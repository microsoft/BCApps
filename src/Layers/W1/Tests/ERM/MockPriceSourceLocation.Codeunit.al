codeunit 134199 "Mock Price Source - Location" implements "Price Source"
{
    var
        Location: Record Location;

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Location.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := Location.Code;
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Location.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := Location.SystemId;
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    var
        xPriceSource: Record "Price Source";
    begin
        xPriceSource := PriceSource;
        if Location.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Location List", Location) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", Location.Code);
            PriceSource := xPriceSource;
            exit(true);
        end;
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        Result := true; // requires parent
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
        exit(PriceSource."Source No.");
    end;

    local procedure FillAdditionalFields(var PriceSource: Record "Price Source")
    begin
        PriceSource.Description := Location.Name;
    end;
}