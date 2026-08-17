codeunit 119028 "Update Routing Headers"
{

    trigger OnRun()
    begin
        UpdateItems('1000', '1000');
        UpdateItems('1001', '1000');
        UpdateItems('1100', '1100');
        UpdateItems('1150', '1150');
        UpdateItems('1250', '1150');
        UpdateItems('1200', '1200');

        CloseRouting('1000', '');
        CloseRouting('1100', '');
        CloseRouting('1150', '');
        CloseRouting('1200', '');
    end;

    procedure UpdateItems(ItemNo: Code[20]; RoutingNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify();
    end;

    procedure CloseRouting(RoutingNo: Code[20]; VersionCode: Code[10])
    var
        Routing: Record "Routing Header";
        RtngVersion: Record "Routing Version";
    begin
        if VersionCode <> '' then begin
            RtngVersion.Get(RoutingNo, VersionCode);
            RtngVersion.Validate(Status, RtngVersion.Status::Certified);
            RtngVersion.Modify();
        end else begin
            Routing.Get(RoutingNo);
            Routing.Validate(Status, Routing.Status::Certified);
            Routing.Modify();
        end;
    end;
}

