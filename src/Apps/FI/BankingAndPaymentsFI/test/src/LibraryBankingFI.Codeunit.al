// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Setup;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 148238 "Library - Banking FI"
{
    EventSubscriberInstance = Manual;

    var
        Enabled: Boolean;

    procedure SetFeatureEnabled(NewEnabled: Boolean)
    begin
        Enabled := NewEnabled;
    end;

    procedure SetInvoiceReferenceSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if not SalesSetup.Get() then
            SalesSetup.Insert();
        SalesSetup."Use Invoice No. in Reference" := true;
        SalesSetup."Use Customer No. in Reference" := false;
        SalesSetup."Use Date in Reference" := false;
        SalesSetup."Payment Reference Nos." := '';
        SalesSetup."Default Reference Number" := '';
        SalesSetup."Print Payment Reference" := true;
        SalesSetup.Modify();
    end;

    procedure SetCompletedFeatureFixture()
#if not CLEAN30
    var
        FeatureKey: Record "Feature Key";
        Status: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
#endif
    begin
#if not CLEAN30
        // Functional fixture only: this does not execute or prove data migration.
        FeatureKey.Get('BankingAndPaymentsFI');
        FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
        FeatureKey.Modify();
        FeatureKey.TestField("Data Update Required", true);
        FeatureManagementFacade.GetFeatureDataUpdateStatus(FeatureKey, Status);
        Status."Data Update Required" := true;
        Status."Feature Status" := Status."Feature Status"::Complete;
        Status.Modify();
        if not UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            UpgradeTag.SetUpgradeTag(Tags.GetMigrationTag());
#endif
    end;

#if not CLEAN30
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Banking Payments Feature FI", 'OnAfterCheckFeatureEnabled', '', false, false)]
    local procedure OverrideFeature(var IsEnabled: Boolean)
    begin
        IsEnabled := Enabled;
    end;
#endif
}
