namespace Microsoft.Test.DemoTool;

using Microsoft.DemoData.Common;
using Microsoft.DemoData.Finance;
using Microsoft.DemoData.Manufacturing;
using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;

codeunit 148048 "DemoTool Dependency Test"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        CircularDependencyErr: Label 'The demo data module cannot be added. Adding this demo data module %1 would cause a circular dependency with %2', Comment = '%1 = Module Name, %2 = Dependency Name';

    [Test]
    procedure TestDependenciesAreCorrectlyGenerated()
    var
        ContosoModuleDependency: Codeunit "Contoso Module Dependency";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
        DemoDataModulesList, SortedModulesList : List of [Enum "Contoso Demo Data Module"];
    begin
        // [SCENARIO] There are 3 modules in the list, testing the dependency order.
        ContosoDemoTool.RefreshModules();

        // [GIVEN] The "Contoso Test 1" module is taken dependencies on by the other 2 modules.
        DemoDataModulesList.Add(Enum::"Contoso Demo Data Module"::"Contoso Test 3");
        DemoDataModulesList.Add(Enum::"Contoso Demo Data Module"::"Contoso Test 2");
        DemoDataModulesList.Add(Enum::"Contoso Demo Data Module"::"Contoso Test 1");

        // [WHEN] The dependencies list is generated.
        ContosoModuleDependency.BuildSortedDependencyList(SortedModulesList, DemoDataModulesList);

        // [THEN] The list should contain 3 modules.
        Assert.AreEqual(3, SortedModulesList.Count(), 'There should only be 3 modules in the list');

        // [THEN] The "Contoso Test 1" module should be first in the list.
        Assert.AreEqual(1, SortedModulesList.IndexOf(Enum::"Contoso Demo Data Module"::"Contoso Test 1"), 'The module that is taken dependencies on should be first');
    end;

    [Test]
    procedure TestCircularDependency()
    var
        ContosoModuleDependency: Codeunit "Contoso Module Dependency";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
    begin
        // [SCENARIO] There are 3 modules in the list (dependency is defined in the implementations), testing the circular dependency.
        ContosoDemoTool.RefreshModules();

        // [GIVEN] Faking a circular dependency
        asserterror ContosoModuleDependency.AddDependency(Enum::"Contoso Demo Data Module"::"Contoso Test 1", Enum::"Contoso Demo Data Module"::"Contoso Test 2");

        // [THEN] Expect a circular dependency error
        Assert.ExpectedError(StrSubstNo(CircularDependencyErr, Enum::"Contoso Demo Data Module"::"Contoso Test 1", Enum::"Contoso Demo Data Module"::"Contoso Test 2"));
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ManufacturingSetupRefreshesCommonGLAccounts()
    var
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        CommonDemoDataModule: Record "Contoso Demo Data Module";
        GLAccount: Record "G/L Account";
        CommonGLAccount: Codeunit "Create Common GL Account";
        ContosoGLAccount: Codeunit "Contoso GL Account";
        MappingFixture: Codeunit "DemoTool Dependency Test";
        ExpectedAccountNo: Code[20];
        ExistingAccountId: Guid;
    begin
        // [SCENARIO] Manufacturing refreshes Common mappings even when its dependency is already generated.
        InitializeMappingFixture();
        BindSubscription(MappingFixture);
        GenerateModuleSetup(Enum::"Contoso Demo Data Module"::"Common Module");

        // [GIVEN] Common setup is persisted, and the localized raw-material account is customized.
        CommonDemoDataModule.Get(Enum::"Contoso Demo Data Module"::"Common Module");
        Assert.IsTrue(CommonDemoDataModule."Data Level".AsInteger() >= Enum::"Contoso Demo Data Level"::"Setup Data".AsInteger(), 'Common setup must already be generated.');
        ExpectedAccountNo := CommonGLAccount.RawMaterials();
        if ExpectedAccountNo <> '' then begin
            GLAccount.Get(ExpectedAccountNo);
            GLAccount.Name := 'Keep existing raw materials';
            GLAccount.Modify();
            ExistingAccountId := GLAccount.SystemId;
        end;

        // [GIVEN] A stale session mapping cannot be used by Manufacturing.
        ContosoGLAccount.AddAccountForLocalization(CommonGLAccount.RawMaterialsName(), 'STALE-635852');
        Assert.AreEqual('STALE-635852', CommonGLAccount.RawMaterials(), 'The fixture must have a stale Common mapping.');

        // [WHEN] Manufacturing setup runs through the normal localized generation flow, skipping generated dependencies.
        GenerateModuleSetup(Enum::"Contoso Demo Data Module"::"Manufacturing Module");
        UnbindSubscription(MappingFixture);

        // [THEN] The mapping is refreshed, including localizations which deliberately use no account.
        Assert.AreEqual(ExpectedAccountNo, CommonGLAccount.RawMaterials(), 'Manufacturing must refresh the Common account mapping.');
        ContosoDemoDataModule.Get(Enum::"Contoso Demo Data Module"::"Manufacturing Module");
        ContosoDemoDataModule.TestField("Data Level", Enum::"Contoso Demo Data Level"::"Setup Data");
        if ExpectedAccountNo <> '' then begin
            GLAccount.Get(ExpectedAccountNo);
            Assert.AreEqual(ExistingAccountId, GLAccount.SystemId, 'The existing account must not be replaced.');
            GLAccount.TestField(Name, 'Keep existing raw materials');
        end;
    end;

    local procedure InitializeMappingFixture()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        FinanceModuleSetup: Record "Finance Module Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ContosoPostingGroup: Codeunit "Contoso Posting Group";
        ContosoPostingSetup: Codeunit "Contoso Posting Setup";
        CommonPostingGroup: Codeunit "Create Common Posting Group";
        MfgPostingGroup: Codeunit "Create Mfg Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        ContosoDemoTool.RefreshModules();
        ContosoCoffeeDemoDataSetup.Get();
        ContosoCoffeeDemoDataSetup."Language ID" := GlobalLanguage();
        ContosoCoffeeDemoDataSetup.Modify();
        ContosoGLAccount.SetOverwriteData(false);

        // Model already-generated upstream setup without regenerating Finance in the shared test company.
        MarkCommonDependenciesGenerated();
        FinanceModuleSetup.InitRecord();
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        FinanceModuleSetup.Get();
        FinanceModuleSetup."VAT Prod. Post Grp. Standard" := VATProductPostingGroup.Code;
        FinanceModuleSetup.Modify();
        ContosoPostingGroup.InsertGenProductPostingGroup(CommonPostingGroup.Retail(), CommonPostingGroup.Retail(), VATProductPostingGroup.Code);
        ContosoPostingGroup.InsertGenProductPostingGroup(CommonPostingGroup.RawMaterial(), CommonPostingGroup.RawMaterial(), VATProductPostingGroup.Code);
        ContosoPostingGroup.InsertGenBusinessPostingGroup(CommonPostingGroup.Domestic(), CommonPostingGroup.Domestic(), '');

        // Existing inventory posting rows do not require regenerating a localization's entire chart.
        ContosoPostingGroup.InsertInventoryPostingGroup(CommonPostingGroup.RawMaterial(), CommonPostingGroup.RawMaterial());
        ContosoPostingGroup.InsertInventoryPostingGroup(MfgPostingGroup.Finished(), MfgPostingGroup.Finished());
        ContosoPostingSetup.InsertInventoryPostingSetup('', CommonPostingGroup.RawMaterial(), '', '');
        ContosoPostingSetup.InsertInventoryPostingSetup('', MfgPostingGroup.Finished(), '', '');

        LibraryERM.CreateSourceCode(SourceCode);
        SourceCodeSetup.Get();
        SourceCodeSetup."Item Journal" := SourceCode.Code;
        SourceCodeSetup."Consumption Journal" := SourceCode.Code;
        SourceCodeSetup."Output Journal" := SourceCode.Code;
        SourceCodeSetup."Capacity Journal" := SourceCode.Code;
        SourceCodeSetup.Modify();
    end;

    local procedure MarkCommonDependenciesGenerated()
    var
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        CommonModule: Codeunit "Common Module";
        ContosoModuleDependency: Codeunit "Contoso Module Dependency";
        Dependencies: List of [Enum "Contoso Demo Data Module"];
        SortedDependencies: List of [Enum "Contoso Demo Data Module"];
        Module: Enum "Contoso Demo Data Module";
    begin
        Dependencies := CommonModule.GetDependencies();
        ContosoModuleDependency.BuildSortedDependencyList(SortedDependencies, Dependencies);
        foreach Module in SortedDependencies do begin
            ContosoDemoDataModule.Get(Module);
            if ContosoDemoDataModule."Data Level".AsInteger() < Enum::"Contoso Demo Data Level"::"Setup Data".AsInteger() then begin
                ContosoDemoDataModule."Data Level" := Enum::"Contoso Demo Data Level"::"Setup Data";
                ContosoDemoDataModule.Modify();
            end;
        end;
    end;

    local procedure GenerateModuleSetup(Module: Enum "Contoso Demo Data Module")
    var
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
    begin
        ContosoDemoDataModule.SetRange(Module, Module);
        ContosoDemoDataModule.FindFirst();
        ContosoDemoDataModule."Data Level" := Enum::"Contoso Demo Data Level"::" ";
        ContosoDemoDataModule.Modify();
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"G/L Account-Indent", 'OnBeforeIndent', '', false, false)]
    local procedure SkipChartIndentForMappingFixture(var GLAcc: Record "G/L Account"; var IsHandled: Boolean)
    begin
        // Only bound in the mapping regression: unrelated shared-company chart validation is not under test.
        IsHandled := true;
    end;
}