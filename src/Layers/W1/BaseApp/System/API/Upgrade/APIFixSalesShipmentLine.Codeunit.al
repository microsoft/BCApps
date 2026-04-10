namespace Microsoft.API.Upgrade;

using Microsoft.Sales.History;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 5516 "API Fix Sales Shipment Line"
{
    trigger OnRun()
    begin
        UpdateAPISalesShipmentLines();
    end;

    local procedure UpdateAPISalesShipmentLines()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesShipmentLine2: Record "Sales Shipment Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        NullGuid: Guid;
        CommitCount: Integer;
    begin
        SalesShipmentLine.SetCurrentKey("Document No.");
        SalesShipmentLine.Ascending(true);
        SalesShipmentLine.SetLoadFields("Document No.", "Document Id");
        SalesShipmentLine.SetRange("Document Id", NullGuid);
        if not SalesShipmentLine.FindFirst() then
            exit;

        SalesShipmentHeader.SetLoadFields(SalesShipmentHeader."No.", SalesShipmentHeader.SystemId);
        repeat
            SalesShipmentHeader.Get(SalesShipmentLine."Document No.");
            SalesShipmentLine2.SetRange("Document No.", SalesShipmentLine."Document No.");
            SalesShipmentLine2.ModifyAll("Document Id", SalesShipmentHeader.SystemId);
            CommitCount += 1;

            if CommitCount > 100 then begin
                CommitCount := 0;
                Commit();
            end;
            SalesShipmentLine.SetFilter("Document No.", '>%1', SalesShipmentHeader."No.");
        until (not SalesShipmentLine.FindFirst());


        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewSalesShipmentLineUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewSalesShipmentLineUpgradeTag());
    end;
}