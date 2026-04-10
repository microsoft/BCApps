codeunit 135973 "Upg Refs To Rem. Tables Tests"
{
    Subtype = Test;

    [Test]
    procedure ChangeLogSetupCleanUpTest()
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        UpgradeStatus: Codeunit "Upgrade Status";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        Assert.AreEqual(2, ChangeLogSetupTable.Count(), 'There are references to removed tables left.');

        ChangeLogSetupTable.FindSet();
        repeat
            Assert.IsTrue(ChangeLogSetupTable."Table No." in [Database::Customer, Database::Item], 'References to the removed tables have stayed.');
        until ChangeLogSetupTable.Next() = 0;
    end;
}