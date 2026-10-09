namespace Microsoft.Test.DemoTool;

using Microsoft.DemoData.Common;
using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 148048 "DemoTool Dependency Test"
{
    Subtype = Test;

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
    procedure ManufacturingSetupRefreshesCommonGLAccounts()
    var
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
        CommonDemoDataModule: Record "Contoso Demo Data Module";
        GLAccount: Record "G/L Account";
        CommonGLAccount: Codeunit "Create Common GL Account";
        ContosoDemoTool: Codeunit "Contoso Demo Tool";
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ExpectedAccountNo: Code[20];
        ExistingAccountId: Guid;
    begin
        // [SCENARIO] Manufacturing refreshes Common mappings even when its dependency is already generated.
        ContosoDemoTool.RefreshModules();
        ContosoDemoDataModule.SetRange(Module, Enum::"Contoso Demo Data Module"::"Manufacturing Module");
        ContosoDemoDataModule.FindFirst();
        ContosoDemoDataModule."Data Level" := Enum::"Contoso Demo Data Level"::" ";
        ContosoDemoDataModule.Modify();
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");

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
        ContosoDemoDataModule.FindFirst();
        ContosoDemoDataModule."Data Level" := Enum::"Contoso Demo Data Level"::" ";
        ContosoDemoDataModule.Modify();

        // [WHEN] Manufacturing setup runs again through the normal localized generation flow.
        ContosoDemoTool.CreateDemoData(ContosoDemoDataModule, Enum::"Contoso Demo Data Level"::"Setup Data");

        // [THEN] The mapping is refreshed, including localizations which deliberately use no account.
        Assert.AreEqual(ExpectedAccountNo, CommonGLAccount.RawMaterials(), 'Manufacturing must refresh the Common account mapping.');
        ContosoDemoDataModule.FindFirst();
        ContosoDemoDataModule.TestField("Data Level", Enum::"Contoso Demo Data Level"::"Setup Data");
        if ExpectedAccountNo <> '' then begin
            GLAccount.Get(ExpectedAccountNo);
            Assert.AreEqual(ExistingAccountId, GLAccount.SystemId, 'The existing account must not be replaced.');
            GLAccount.TestField(Name, 'Keep existing raw materials');
        end;
    end;
}