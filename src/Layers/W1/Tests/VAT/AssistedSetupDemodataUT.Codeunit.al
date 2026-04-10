codeunit 132556 "Assisted Setup Demodata UT"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Assisted Setup] [VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure AssistedVatInitDemoData()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // [SCENARIO 0] Populate setup table from VAT setup table.
        // [GIVEN] VAT business/product tables are populated from demo data.
        // [WHEN] Demodata is applied.
        LibraryLowerPermissions.SetO365Setup();
        VATAssistedSetupBusGrp.SetRange(Default, true);
        VATSetupPostingGroups.SetRange(Default, true);

        Assert.AreEqual(VATAssistedSetupBusGrp.Count, VATBusinessPostingGroup.Count,
          'Expected that default values for VAT assisted setup are initialized');
        Assert.AreEqual(VATSetupPostingGroups.Count, VATProductPostingGroup.Count,
          'Expected that default values for VAT assisted setup are initialized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDemoDataVATBusPostingGrp()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        // [SCENARIO 1] Populate setup table from VAT business table.
        // [GIVEN] VAT business table populated from demo data.
        // [WHEN] Demodata is applied and VAT bus assisted table is populated.
        LibraryLowerPermissions.SetO365Setup();
        VATAssistedSetupBusGrp.SetRange(Default, true);

        // [THEN] All records in VAT Assisted Setup Bus. Group are present in VAT Bus. Posting Group
        if VATAssistedSetupBusGrp.FindSet() then
            repeat
                Assert.IsTrue(VATBusinessPostingGroup.Get(VATAssistedSetupBusGrp.Code), 'VAT business code does not exist');
                Assert.AreEqual(VATBusinessPostingGroup.Description, VATAssistedSetupBusGrp.Description
                  , 'VAT business description is not correct');
            until VATAssistedSetupBusGrp.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDemoDataVATProductPostingGrp()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        // [SCENARIO 2] Populate setup table from VAT Product table.
        // [GIVEN] VAT product table populated from demo data.
        // [WHEN] Demodata is applied and VAT bus assisted table is populated
        LibraryLowerPermissions.SetO365Setup();
        VATSetupPostingGroups.SetRange(Default, true);

        // [THEN] All records in VAT Assisted Setup product Group are present in VAT product Posting Group
        if VATSetupPostingGroups.FindSet() then
            repeat
                Assert.IsTrue(VATProductPostingGroup.Get(VATSetupPostingGroups."VAT Prod. Posting Group"), 'VAT product code does not exist');
            until VATSetupPostingGroups.Next() = 0;
    end;
}

