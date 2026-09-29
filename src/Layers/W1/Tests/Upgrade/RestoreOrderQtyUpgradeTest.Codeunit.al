codeunit 135978 "Restore Order Qty Upgrade Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRestoreOrderQtyOnReturnUpgrade()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
        RestoreOrderQtyOnReturnUpgradeTag: Code[250];
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        RestoreOrderQtyOnReturnUpgradeTag := UpgradeTagDefinitions.GetRestoreOrderQtyOnReturnInSalesAndPurchasesSetupUpgradeTag();
        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(RestoreOrderQtyOnReturnUpgradeTag) then
            exit;

        SalesReceivablesSetup.Get();
        PurchasesPayablesSetup.Get();
        Assert.IsTrue(SalesReceivablesSetup."Restore Order qty. on return", 'Restore Order qty. on return must be enabled in Sales & Receivables Setup.');
        Assert.IsTrue(PurchasesPayablesSetup."Restore Order qty. on return", 'Restore Order qty. on return must be enabled in Purchases & Payables Setup.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(RestoreOrderQtyOnReturnUpgradeTag), 'The Restore Order qty. on return upgrade tag must be registered.');

        SalesReceivablesSetup.Validate("Restore Order qty. on return", false);
        SalesReceivablesSetup.Modify();
        PurchasesPayablesSetup.Validate("Restore Order qty. on return", false);
        PurchasesPayablesSetup.Modify();

        UpgradeBaseApp.UpgradeRestoreOrderQtyOnReturnInSalesAndPurchasesSetup();

        SalesReceivablesSetup.Get();
        PurchasesPayablesSetup.Get();
        Assert.IsFalse(SalesReceivablesSetup."Restore Order qty. on return", 'The sales setting must not change after the upgrade tag is registered.');
        Assert.IsFalse(PurchasesPayablesSetup."Restore Order qty. on return", 'The purchase setting must not change after the upgrade tag is registered.');
    end;
}
