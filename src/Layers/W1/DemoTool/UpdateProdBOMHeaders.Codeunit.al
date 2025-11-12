codeunit 119025 "Update Prod. BOM Headers"
{

    trigger OnRun()
    begin
        UpdateItems('1000', '1000');
        UpdateItems('1001', '1000');
        UpdateItems('1100', '1100');
        UpdateItems('1150', '1150');
        UpdateItems('1200', '1200');
        UpdateItems('1250', '1250');
        UpdateItems('1300', '1300');
        UpdateItems('1700', '1700');

        CloseProdBOM('1000', '');
        CloseProdBOM('1100', '');
        CloseProdBOM('1150', '');
        CloseProdBOM('1200', '');
        CloseProdBOM('1250', '');
        CloseProdBOM('1300', '');
        CloseProdBOM('1700', '');
    end;

    procedure UpdateItems(ItemNo: Code[20]; ProdBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item."Production BOM No." := ProdBOMNo;
        Item.Modify();
    end;

    procedure CloseProdBOM(ProdBOMNo: Code[20]; VersionCode: Code[10])
    var
        ProdBOM: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if VersionCode <> '' then begin
            ProdBOMVersion.Get(ProdBOMNo, VersionCode);
            ProdBOMVersion.Validate(Status, ProdBOMVersion.Status::Certified);
            ProdBOMVersion.Modify();
        end else begin
            ProdBOM.Get(ProdBOMNo);
            ProdBOM.Validate(Status, ProdBOM.Status::Certified);
            ProdBOM.Modify();
        end;
    end;
}

