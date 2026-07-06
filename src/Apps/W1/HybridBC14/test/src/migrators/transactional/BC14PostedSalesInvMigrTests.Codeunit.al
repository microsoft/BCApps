// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.Test;

using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

codeunit 148910 "BC14 PostedSalesInvMigr Tests"
{
    // [FEATURE] [BC14 Posted Sales Invoice Migrator]

    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        IsHandledFlag: Boolean;

    [Test]
    procedure TestGetDisplayName_ReturnsExpectedLabel()
    var
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] GetDisplayName returns the migrator's display name.
        Assert.AreEqual('Posted Sales Invoice Migrator', BC14PostedSalesInvMigr.GetDisplayName(), 'Unexpected display name.');
    end;

    [Test]
    procedure TestIsEnabled_ReceivablesDisabled_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] When Receivables module is disabled, IsEnabled returns false even if buffer has records.
        Initialize();
        SetReceivablesEnabled(false);
        InsertSalesInvHeader('INV-001');

        Assert.IsFalse(BC14PostedSalesInvMigr.IsEnabled(), 'IsEnabled should return false when receivables disabled.');

        BC14PostedSalesInvHeader.DeleteAll();
        BC14CompanySettings.DeleteAll();
    end;

    [Test]
    procedure TestIsEnabled_BufferEmpty_ReturnsFalse()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] When buffer is empty, IsEnabled returns false even if receivables enabled.
        Initialize();
        SetReceivablesEnabled(true);
        BC14PostedSalesInvHeader.DeleteAll();

        Assert.IsFalse(BC14PostedSalesInvMigr.IsEnabled(), 'IsEnabled should return false when buffer is empty.');

        BC14CompanySettings.DeleteAll();
    end;

    [Test]
    procedure TestIsEnabled_ReceivablesEnabledAndBufferHasRecords_ReturnsTrue()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] When receivables enabled and buffer non-empty, IsEnabled returns true.
        Initialize();
        SetReceivablesEnabled(true);
        InsertSalesInvHeader('INV-002');

        Assert.IsTrue(BC14PostedSalesInvMigr.IsEnabled(), 'IsEnabled should return true.');

        BC14PostedSalesInvHeader.DeleteAll();
        BC14CompanySettings.DeleteAll();
    end;

    [Test]
    procedure TestGetRemainingPercentage_NoRecords_ReturnsZero()
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] When buffer is empty, GetRemainingPercentage returns 0.
        Initialize();
        BC14PostedSalesInvHeader.DeleteAll();

        Assert.AreEqual(0, BC14PostedSalesInvMigr.GetRemainingPercentage(), 'Expected 0% remaining when buffer empty.');
    end;

    [Test]
    procedure TestGetRemainingPercentage_WithRecords_Returns100()
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] When buffer has records and no archive yet, GetRemainingPercentage returns 100.
        Initialize();
        InsertSalesInvHeader('INV-003');
        InsertSalesInvHeader('INV-004');

        Assert.AreEqual(100, BC14PostedSalesInvMigr.GetRemainingPercentage(), 'Expected 100% remaining when nothing archived.');

        BC14PostedSalesInvHeader.DeleteAll();
    end;

    [Test]
    procedure TestMigrate_HandledByEvent_ReturnsTrue()
    var
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] When OnMigratePostedSalesInvoices sets IsMigrated, Migrate exits true without performing transfer.
        Initialize();
        IsHandledFlag := true;
        BindSubscription(this);

        Assert.IsTrue(BC14PostedSalesInvMigr.Migrate(), 'Migrate should return true when handled by event.');

        UnbindSubscription(this);
    end;

    [Test]
    procedure TestMigrate_FallbackPath_CopiesHeadersAndLinesIntoArchive()
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line";
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
        BC14ArchSalesInvLine: Record "BC14 Arch. Sales Inv. Line";
        BC14PostedSalesInvMigr: Codeunit "BC14 Posted Sales Inv Migr.";
    begin
        // [SCENARIO] Outside Intelligent Cloud migration scope DataTransfer is rejected, so the
        // migrator must fall back to a per-record TransferFields copy. The test session has IC
        // disabled by default, so calling Migrate exercises that fallback path end-to-end.
        Initialize();
        InsertSalesInvHeader('INV-FB-1');
        InsertSalesInvHeader('INV-FB-2');
        InsertSalesInvLine('INV-FB-1', 10000);
        InsertSalesInvLine('INV-FB-1', 20000);
        InsertSalesInvLine('INV-FB-2', 10000);

        Assert.IsTrue(BC14PostedSalesInvMigr.Migrate(), 'Migrate should succeed via the AL fallback path when IC is disabled.');

        Assert.AreEqual(2, BC14ArchSalesInvHeader.Count(), 'Both source headers should be present in the archive.');
        Assert.AreEqual(3, BC14ArchSalesInvLine.Count(), 'All source lines should be present in the archive.');

        BC14ArchSalesInvHeader.FindFirst();
        Assert.AreNotEqual(0DT, BC14ArchSalesInvHeader."Migrated On", 'Migrated On should be stamped by the fallback path.');

        BC14PostedSalesInvHeader.DeleteAll();
        BC14PostedSalesInvLine.DeleteAll();
        BC14ArchSalesInvHeader.DeleteAll();
        BC14ArchSalesInvLine.DeleteAll();
    end;

    local procedure Initialize()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line";
    begin
        BC14PostedSalesInvHeader.DeleteAll();
        BC14PostedSalesInvLine.DeleteAll();
        BC14CompanySettings.DeleteAll();
    end;

    local procedure SetReceivablesEnabled(Enabled: Boolean)
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        CurrentCompanyName: Text;
    begin
        CurrentCompanyName := CompanyName();
        if not BC14CompanySettings.Get(CurrentCompanyName) then begin
            BC14CompanySettings.Init();
            BC14CompanySettings.Name := CopyStr(CurrentCompanyName, 1, MaxStrLen(BC14CompanySettings.Name));
            BC14CompanySettings.Insert();
        end;
        BC14CompanySettings."Migrate Receivables Module" := Enabled;
        BC14CompanySettings.Modify();
    end;

    local procedure InsertSalesInvHeader(DocNo: Code[20])
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
    begin
        BC14PostedSalesInvHeader.Init();
        BC14PostedSalesInvHeader."No." := DocNo;
        BC14PostedSalesInvHeader.Insert();
    end;

    local procedure InsertSalesInvLine(DocNo: Code[20]; LineNo: Integer)
    var
        BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line";
    begin
        BC14PostedSalesInvLine.Init();
        BC14PostedSalesInvLine."Document No." := DocNo;
        BC14PostedSalesInvLine."Line No." := LineNo;
        BC14PostedSalesInvLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Posted Sales Inv Migr.", 'OnMigratePostedSalesInvoices', '', false, false)]
    local procedure OnMigrateSubscriber(var IsMigrated: Boolean)
    begin
        IsMigrated := IsHandledFlag;
    end;
}
