#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 139993 "Subc. Feature Flag Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting] [Feature Toggle]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPurchase: Codeunit "Library - Purchase";
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AppAreaSetWhenSubcontractingEnabled()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [SCENARIO] ApplicationAreaSetup."Subcontracting" is true when Legacy Subcontracting toggle is disabled (Subcontracting enabled)
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false (Subcontracting app is active)
        SetLegacySubcontracting(false);

        // [WHEN] Application areas are reloaded
        RefreshApplicationAreas();

        // [THEN] ApplicationAreaSetup."Subcontracting" = true
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsTrue(ApplicationAreaSetup."Subcontracting", 'Subcontracting application area should be true when Legacy Subcontracting flag is disabled.');
        Assert.IsTrue(ApplicationAreaMgmtFacade.GetApplicationAreaSetup().Contains('#Subcontracting'), 'Subcontracting string should be present in application area setup when enabled and on premium tier.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppAreaClearedWhenSubcontractingDisabled()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [SCENARIO] ApplicationAreaSetup."Subcontracting" is false when Legacy Subcontracting toggle is enabled (Subcontracting disabled)
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true (Legacy mode active, Subcontracting app inactive)
        SetLegacySubcontracting(true);

        // [WHEN] Application areas are reloaded
        RefreshApplicationAreas();

        // [THEN] ApplicationAreaSetup."Subcontracting" = false
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsFalse(ApplicationAreaSetup."Subcontracting", 'Subcontracting application area should be false when Legacy Subcontracting is enabled.');
        Assert.IsFalse(ApplicationAreaMgmtFacade.GetApplicationAreaSetup().Contains('#Subcontracting'), 'Subcontracting string must not be present when disabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppAreaNotSetForEssentialExperienceTier()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [SCENARIO] ApplicationAreaSetup."Subcontracting" is NOT set for Essential tier even when Legacy Subcontracting is disabled
        // The subscriber only fires for OnGetPremiumExperienceAppAreas, not for Essential
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false (Subcontracting would be active for Premium)
        SetLegacySubcontracting(false);

        // [WHEN] Essential experience tier is activated
        LibraryApplicationArea.EnableEssentialSetup();

        // [THEN] ApplicationAreaSetup."Subcontracting" = false (subscriber does not fire for Essential)
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsFalse(ApplicationAreaSetup."Subcontracting", 'Subcontracting app area must not be set for Essential experience tier.');
        Assert.IsFalse(ApplicationAreaMgmtFacade.GetApplicationAreaSetup().Contains('#Subcontracting'), 'Subcontracting string must not be present when on essential tier.');

        // Restore to Premium Setup
        LibraryApplicationArea.EnablePremiumSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GuardReturnsTrueWhenEnabled()
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
    begin
        // [SCENARIO] IsSubcontractingEnabled returns true when Legacy Subcontracting toggle is OFF
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false
        SetLegacySubcontracting(false);

        // [WHEN] Call IsSubcontractingEnabled
        // [THEN] Returns true
#pragma warning disable AL0432
        Assert.IsTrue(SubcFeatureFlagHandler.IsSubcontractingEnabled(), 'Guard should return true when Legacy Subcontracting is disabled.');
#pragma warning restore AL0432
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GuardReturnsFalseWhenDisabled()
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
    begin
        // [SCENARIO] IsSubcontractingEnabled returns false when Legacy Subcontracting toggle is ON
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [WHEN] Call IsSubcontractingEnabled
        // [THEN] Returns false
#pragma warning disable AL0432
        Assert.IsFalse(SubcFeatureFlagHandler.IsSubcontractingEnabled(), 'Guard should return false when Legacy Subcontracting is enabled.');
#pragma warning restore AL0432
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GuardReturnsFalseWhenSetupNotExists()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        TempManufacturingSetupBackup: Record "Manufacturing Setup" temporary;
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
    begin
        // [SCENARIO] IsSubcontractingEnabled returns false when no ManufacturingSetup record exists
        Initialize();

        ManufacturingSetup.Get();
        TempManufacturingSetupBackup.Copy(ManufacturingSetup);
        ManufacturingSetup.Delete();

        // [WHEN] Call IsSubcontractingEnabled
        // [THEN] Returns false
#pragma warning disable AL0432
        Assert.IsFalse(SubcFeatureFlagHandler.IsSubcontractingEnabled(), 'Guard should return false when ManufacturingSetup does not exist.');
#pragma warning restore AL0432

        // Restore ManufacturingSetup
        ManufacturingSetup.Init();
        ManufacturingSetup.Copy(TempManufacturingSetupBackup);
        ManufacturingSetup.Insert();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardSubcFieldsVisibleWhenEnabled()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] Subcontracting fields on Vendor Card are visible when Subcontracting app area is active
        Initialize();

        // [GIVEN] Legacy Subcontracting is disabled (Subcontracting enabled) and Premium experience is activated
        SetLegacySubcontracting(false);
        RefreshApplicationAreas();

        // [GIVEN] A vendor exists
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Open the Vendor Card
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Subcontracting fields are visible
        Assert.IsTrue(VendorCard."Subcr. Location Code".Visible(), '"Subcr. Location Code" should be visible when Subcontracting is enabled.');
        Assert.IsTrue(VendorCard."Subc. Linked to Work Center".Visible(), '"Subc. Linked to Work Center" should be visible when Subcontracting is enabled.');
        Assert.IsTrue(VendorCard."Subc. Work Center No.".Visible(), '"Subc. Work Center No." should be visible when Subcontracting is enabled.');

        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardSubcFieldsNotVisibleWhenDisabled()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] Subcontracting fields on Vendor Card are NOT accessible when Subcontracting app area is inactive
        Initialize();

        // [GIVEN] Legacy Subcontracting is enabled (Subcontracting disabled) and Premium experience is activated
        SetLegacySubcontracting(true);
        RefreshApplicationAreas();

        // [GIVEN] A vendor exists
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Open the Vendor Card
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Subcontracting fields are not accessible (accessing them raises an error)
        asserterror Assert.IsFalse(VendorCard."Subcr. Location Code".Visible(), '"Subcr. Location Code" should not be visible when Subcontracting is disabled.');
        asserterror Assert.IsFalse(VendorCard."Subc. Linked to Work Center".Visible(), '"Subc. Linked to Work Center" should not be visible when Subcontracting is disabled.');
        asserterror Assert.IsFalse(VendorCard."Subc. Work Center No.".Visible(), '"Subc. Work Center No." should not be visible when Subcontracting is disabled.');

        VendorCard.Close();
    end;

    local procedure Initialize()
    var
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Feature Flag Test");

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Feature Flag Test");
        LibraryApplicationArea.EnablePremiumSetup();
        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Feature Flag Test");
    end;

    local procedure SetLegacySubcontracting(Enabled: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
#pragma warning disable AL0432
        ManufacturingSetup."Legacy Subcontracting" := Enabled;
#pragma warning restore AL0432
        ManufacturingSetup.Modify();
    end;

    local procedure RefreshApplicationAreas()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;
}
#endif
