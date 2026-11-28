// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
using Microsoft.Foundation.Registration;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;

codeunit 139936 "Registration Migration BE Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        RegistrationNoFeature: Codeunit "Registration No. Feature";

    [Test]
    procedure MigrationRequiresReviewAndDoesNotOverwriteConflicts()
    var
        Customer: Record Customer;
        Migration: Record "Registration No. Migration";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        DisableFeature();
        CreateCustomer(Customer);
        RegistrationNoFeature.RefreshMigration();
        Migration.Get(Customer.RecordId);
        Assert.AreEqual(Migration.Resolution::Pending, Migration.Resolution, 'Different values must not be approved automatically.');
        FeatureDataUpdateStatus."Feature Key" := RegistrationNoFeature.GetFeatureKey();
        FeatureDataUpdateStatus."Task Id" := CreateGuid();
        Commit();

        asserterror RegistrationNoFeature.UpdateData(FeatureDataUpdateStatus);
        Assert.ExpectedError('choose a resolution before activating');
        Customer.Get(Customer."No.");
        Assert.AreEqual('Existing W1', Customer."Registration Number", 'Pending migration must not overwrite existing W1 data.');

        Migration.Get(Customer.RecordId);
        Migration.Resolution := Migration.Resolution::"Keep W1";
        Migration.Modify();
        Customer."Enterprise No." := 'Changed since review';
        Customer.Modify(false);
        RegistrationNoFeature.RefreshMigration();
        Migration.Get(Customer.RecordId);
        Assert.AreEqual(Migration.Resolution::Pending, Migration.Resolution, 'Changing the local value must invalidate its earlier approval.');
    end;

    [Test]
    procedure ExplicitMigrationPreservesLocalAndTaxValuesAndCanBeRepeated()
    var
        Customer: Record Customer;
        Migration: Record "Registration No. Migration";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        LocalRegistrationNo: Text[50];
    begin
        DisableFeature();
        CreateCustomer(Customer);
        LocalRegistrationNo := Customer."Enterprise No.";
        RegistrationNoFeature.RefreshMigration();
        Migration.ModifyAll(Resolution, Migration.Resolution::"Keep W1");
        Migration.Get(Customer.RecordId);
        Migration.Resolution := Migration.Resolution::"Use Local";
        Migration.Modify();
        FeatureDataUpdateStatus."Feature Key" := RegistrationNoFeature.GetFeatureKey();
        FeatureDataUpdateStatus."Task Id" := CreateGuid();

        RegistrationNoFeature.UpdateData(FeatureDataUpdateStatus);
        RegistrationNoFeature.UpdateData(FeatureDataUpdateStatus);

        Customer.Get(Customer."No.");
        Assert.AreEqual(LocalRegistrationNo, Customer."Registration Number", 'Explicit migration must preserve all 50 characters.');
        Assert.AreEqual(LocalRegistrationNo, Customer."Enterprise No.", 'Migration must not change or revalidate local enterprise storage.');
        Assert.AreEqual('Existing VAT', Customer."VAT Registration No.", 'Legal-registration migration must not change VAT identity.');
        Assert.IsFalse(RegistrationNoFeature.IsEnabled(), 'Migrating data must not itself enable the environment feature key.');
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), Database::Customer);
        Customer."Enterprise No." := PadStr('Local 0012-/ ', 50, 'x');
        Customer."Registration Number" := 'Existing W1';
        Customer."VAT Registration No." := 'Existing VAT';
        Customer.Insert(false);
    end;

    local procedure DisableFeature()
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if not FeatureKey.Get(RegistrationNoFeature.GetFeatureKey()) then begin
            FeatureKey.Init();
            FeatureKey.ID := RegistrationNoFeature.GetFeatureKey();
            FeatureKey.Insert();
        end;
        FeatureKey.Enabled := FeatureKey.Enabled::None;
        FeatureKey."Data Update Required" := true;
        FeatureKey.Modify();
        if FeatureDataUpdateStatus.Get(FeatureKey.ID, CompanyName()) then begin
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
            FeatureDataUpdateStatus.Modify();
        end;
    end;
}
