namespace Microsoft.API.Upgrade;

using Microsoft.Purchases.History;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 5517 "API Fix Purch Rcpt Line"
{
    trigger OnRun()
    begin
        UpdateAPIPurchRcptLines();
    end;

    local procedure UpdateAPIPurchRcptLines()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptLine2: Record "Purch. Rcpt. Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        NullGuid: Guid;
        CommitCount: Integer;
    begin
        PurchRcptLine.SetCurrentKey("Document No.");
        PurchRcptLine.Ascending(true);
        PurchRcptLine.SetLoadFields("Document No.", "Document Id");
        PurchRcptLine.SetRange("Document Id", NullGuid);
        if not PurchRcptLine.FindFirst() then
            exit;

        PurchRcptHeader.SetLoadFields(PurchRcptHeader."No.", PurchRcptHeader.SystemId);
        repeat
            PurchRcptHeader.Get(PurchRcptLine."Document No.");
            PurchRcptLine2.SetRange("Document No.", PurchRcptLine."Document No.");
            PurchRcptLine2.ModifyAll("Document Id", PurchRcptHeader.SystemId);
            CommitCount += 1;

            if CommitCount > 100 then begin
                CommitCount := 0;
                Commit();
            end;
            PurchRcptLine.SetFilter("Document No.", '>%1', PurchRcptHeader."No.");
        until (not PurchRcptLine.FindFirst());

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetNewPurchRcptLineUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetNewPurchRcptLineUpgradeTag());
    end;
}