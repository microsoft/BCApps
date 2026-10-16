// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using System.TestLibraries.Utilities;
using System.Upgrade;

codeunit 135978 "Direct Transfer Upgrade Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Transfer Order] [Upgrade]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeDirectTransferWithNoOrdersDoesNotRequireInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
        TransferHeader: Record "Transfer Header";
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        // [SCENARIO] An uninitialized company without direct transfer orders can be upgraded.
        InventorySetup.DeleteAll();
        TransferHeader.SetRange("Direct Transfer", true);
        TransferHeader.DeleteAll();
        RemoveUpgradeTag(UpgradeTagDefinitions.GetDirectTransferOnTransferOrderUpgradeTag());

        // [WHEN] Direct transfer orders are upgraded.
        UpgradeBaseApp.UpgradeDirectTransferOnTransferHeader();

        // [THEN] The upgrade completes without creating Inventory Setup and is marked complete.
        Assert.IsTrue(InventorySetup.IsEmpty(), 'Inventory Setup must not be required or created.');
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDirectTransferOnTransferOrderUpgradeTag()),
            'The direct transfer order upgrade must be marked as complete.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeDirectTransferUsesInventorySetupPostingType()
    var
        InventorySetup: Record "Inventory Setup";
        TransferHeader: Record "Transfer Header";
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        // [SCENARIO] Existing direct transfer orders retain the posting behavior from Inventory Setup.
        InventorySetup.DeleteAll();
        InventorySetup.Init();
        InventorySetup."Direct Transfer Posting Type" := InventorySetup."Direct Transfer Posting Type"::"Direct Transfer";
        InventorySetup.Insert();

        TransferHeader.SetRange("No.", 'UPG-DIRECT-TRANSFER');
        TransferHeader.DeleteAll();
        TransferHeader.Init();
        TransferHeader."No." := 'UPG-DIRECT-TRANSFER';
        TransferHeader."Direct Transfer" := true;
        TransferHeader.Insert();
        RemoveUpgradeTag(UpgradeTagDefinitions.GetDirectTransferOnTransferOrderUpgradeTag());

        // [WHEN] Direct transfer orders are upgraded.
        UpgradeBaseApp.UpgradeDirectTransferOnTransferHeader();

        // [THEN] The order uses the posting type configured before the upgrade.
        TransferHeader.Get('UPG-DIRECT-TRANSFER');
        Assert.AreEqual(
            TransferHeader."Direct Transfer Posting"::"Direct Transfer",
            TransferHeader."Direct Transfer Posting",
            'The direct transfer posting type must be copied from Inventory Setup.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeDirectTransferWithoutInventorySetupUsesDefaultPostingType()
    var
        InventorySetup: Record "Inventory Setup";
        TransferHeader: Record "Transfer Header";
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        // [SCENARIO] A direct transfer order can be upgraded when Inventory Setup is missing.
        InventorySetup.DeleteAll();

        TransferHeader.SetRange("No.", 'UPG-DIRECT-TRANSFER');
        TransferHeader.DeleteAll();
        TransferHeader.Init();
        TransferHeader."No." := 'UPG-DIRECT-TRANSFER';
        TransferHeader."Direct Transfer" := true;
        TransferHeader.Insert();
        RemoveUpgradeTag(UpgradeTagDefinitions.GetDirectTransferOnTransferOrderUpgradeTag());

        // [WHEN] Direct transfer orders are upgraded.
        UpgradeBaseApp.UpgradeDirectTransferOnTransferHeader();

        // [THEN] The order uses the default posting type.
        TransferHeader.Get('UPG-DIRECT-TRANSFER');
        Assert.AreEqual(
            TransferHeader."Direct Transfer Posting"::"Shipment and Receipt",
            TransferHeader."Direct Transfer Posting",
            'The direct transfer posting type must use the default when Inventory Setup is missing.');
    end;

    local procedure RemoveUpgradeTag(UpgradeTag: Code[250])
    var
        UpgradeTagRecordRef: RecordRef;
        UpgradeTagFieldRef: FieldRef;
    begin
        UpgradeTagRecordRef.Open(9999);
        UpgradeTagFieldRef := UpgradeTagRecordRef.Field(1);
        UpgradeTagFieldRef.SetRange(UpgradeTag);
        UpgradeTagFieldRef := UpgradeTagRecordRef.Field(3);
        UpgradeTagFieldRef.SetRange(CompanyName());
        UpgradeTagRecordRef.DeleteAll();
    end;
}
