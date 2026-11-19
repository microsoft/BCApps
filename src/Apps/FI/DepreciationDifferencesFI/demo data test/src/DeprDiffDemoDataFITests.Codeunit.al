namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.FixedAsset;
using Microsoft.DemoTool;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using System.Environment.Configuration;

codeunit 148172 "Depr. Diff. Demo Data FI Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TestCU: Codeunit "Depr. Diff. Calculation FI";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContosoDemoGeneratorInitializesExtensionAccounts()
    var
        ContosoDemoToolPage: TestPage "Contoso Demo Tool";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 659561] Contoso setup generation initializes the extension accounts for all five FI posting groups.
        Initialize();
#if not CLEAN30
        SetFeatureEnabled(true);
#endif

        // [GIVEN] Fixed asset setup has not been generated.
        PrepareContosoFixedAssetSetup(ContosoDemoToolPage);

        // [WHEN] Setup data is generated through the public Contoso Demo Tool page.
        ContosoDemoToolPage.GenerateSetup.Invoke();
        ContosoDemoToolPage.Close();
#if not CLEAN30
        UnbindSubscription(TestCU);
#endif

        // [THEN] All five posting groups have extension accounts instead of legacy accounts.
        VerifyContosoPostingGroupAccounts(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContosoDemoGeneratorInitializesLegacyAccountsWhenFeatureDisabled()
    var
        ContosoDemoToolPage: TestPage "Contoso Demo Tool";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 659561] Contoso setup generation retains legacy FI accounts when the feature is disabled.
        Initialize();
        SetFeatureEnabled(false);

        // [GIVEN] Fixed asset setup has not been generated.
        PrepareContosoFixedAssetSetup(ContosoDemoToolPage);

        // [WHEN] Setup data is generated through the public Contoso Demo Tool page.
        ContosoDemoToolPage.GenerateSetup.Invoke();
        ContosoDemoToolPage.Close();
        UnbindSubscription(TestCU);

        // [THEN] All five posting groups have legacy accounts and empty extension accounts.
        VerifyContosoPostingGroupAccounts(false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;
#endif

    local procedure Initialize()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        FinanceModuleSetup: Record "Finance Module Setup";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Depr. Diff. Demo Data FI Tests");
        ContosoCoffeeDemoDataSetup.InitRecord();
        ContosoDemoDataModule.DeleteAll();
        ContosoDemoTool.RefreshModules();
        MarkFixedAssetDependenciesGenerated();
        // Prepare the localized chart without regenerating unrelated shared-company setup.
        FinanceModuleSetup.InitRecord();
        Codeunit.Run(Codeunit::"Create VAT Posting Groups");
        Codeunit.Run(Codeunit::"Create Posting Groups");
        Codeunit.Run(Codeunit::"Create G/L Account");
    end;

    local procedure MarkFixedAssetDependenciesGenerated()
    var
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        FAModule: Codeunit "FA Module";
        ContosoModuleDependency: Codeunit "Contoso Module Dependency";
        Dependencies: List of [Enum "Contoso Demo Data Module"];
        SortedDependencies: List of [Enum "Contoso Demo Data Module"];
        Module: Enum "Contoso Demo Data Module";
    begin
        Dependencies := FAModule.GetDependencies();
        ContosoModuleDependency.BuildSortedDependencyList(SortedDependencies, Dependencies);
        foreach Module in SortedDependencies do begin
            ContosoDemoDataModule.Get(Module);
            ContosoDemoDataModule."Data Level" := Enum::"Contoso Demo Data Level"::"Setup Data";
            ContosoDemoDataModule.Modify();
        end;
    end;

    local procedure PrepareContosoFixedAssetSetup(var ContosoDemoToolPage: TestPage "Contoso Demo Tool")
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        FAPostingGroup: Record "FA Posting Group";
        PostingGroupCode: Code[20];
    begin
        foreach PostingGroupCode in GetContosoPostingGroupCodes() do
            if FAPostingGroup.Get(PostingGroupCode) then
                FAPostingGroup.Delete(false);

        ContosoDemoToolPage.OpenView();
        ContosoDemoToolPage.Filter.SetFilter(Module, Format(Enum::"Contoso Demo Data Module"::"Fixed Asset Module"));
        ContosoCoffeeDemoDataSetup.Get();
        ContosoCoffeeDemoDataSetup.Validate("Language ID", 0);
        ContosoCoffeeDemoDataSetup.Modify(true);
    end;

    local procedure GetContosoPostingGroupCodes() PostingGroupCodes: List of [Code[20]]
    var
        CreateFAPostingGroup: Codeunit "Create FA Posting Group";
    begin
        PostingGroupCodes.Add(CreateFAPostingGroup.Equipment());
        PostingGroupCodes.Add(CreateFAPostingGroup.Goodwill());
        PostingGroupCodes.Add(CreateFAPostingGroup.Plant());
        PostingGroupCodes.Add(CreateFAPostingGroup.Property());
        PostingGroupCodes.Add(CreateFAPostingGroup.Vehicles());
    end;

    local procedure VerifyContosoPostingGroupAccounts(UseExtensionFields: Boolean)
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        CreateGLAccountFI: Codeunit "Create FI GL Accounts";
        CreateGLAccount: Codeunit "Create G/L Account";
        DeprDifferenceAccount: Code[20];
        DeprDifferenceBalAccount: Code[20];
        PostingGroupCode: Code[20];
    begin
        DeprDifferenceAccount := CreateGLAccountFI.Changeindepreciationreserve4();
        DeprDifferenceBalAccount := CreateGLAccountFI.Depreciationdifference3();
        Assert.AreNotEqual('', DeprDifferenceAccount, 'The depreciation difference account must be generated.');
        Assert.AreNotEqual('', DeprDifferenceBalAccount, 'The depreciation difference balancing account must be generated.');
        GLAccount.Get(DeprDifferenceAccount);
        GLAccount.Get(DeprDifferenceBalAccount);

        foreach PostingGroupCode in GetContosoPostingGroupCodes() do begin
            FAPostingGroup.Get(PostingGroupCode);
            Assert.AreEqual(CreateGLAccount.DerogatoryAccount(), FAPostingGroup."Derogatory Acc.", 'The derogatory account must remain initialized.');
            Assert.AreEqual(CreateGLAccount.DerogatoryAccount(), FAPostingGroup."Derogatory Account (Decrease)", 'The derogatory decrease account must remain initialized.');
            Assert.AreEqual(CreateGLAccount.DerogExpenseAccForCredit(), FAPostingGroup."Derog. Bal. Account (Decrease)", 'The derogatory balancing account must remain initialized.');
            Assert.AreEqual(CreateGLAccount.DerogExpenseAccForDebit(), FAPostingGroup."Derogatory Expense Acc.", 'The derogatory expense account must remain initialized.');
            TestCU.VerifyDemoPostingGroupAccounts(FAPostingGroup, DeprDifferenceAccount, DeprDifferenceBalAccount, UseExtensionFields);
        end;
    end;

#if not CLEAN30
    local procedure SetFeatureEnabled(Enabled: Boolean)
    begin
        UnbindSubscription(TestCU);
        TestCU.SetFeatureEnabledValue(Enabled);
        BindSubscription(TestCU);
    end;
#endif
}
