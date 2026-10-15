#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Upgrade;
using System.Upgrade;

codeunit 148006 "Sales FR Report Layouts Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit Assert;
        SalesFRReportLayouts: Codeunit "Sales FR Report Layouts";
        EmptyGuid: Guid;
        BaseApplicationAppIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        SalesFRAppIdTok: Label '8df591a3-d767-4475-8bff-44b8b5527477', Locked = true;

    [Test]
    procedure SelectsFRWordDefaultsWhenNoSelectionExists()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
    begin
        Initialize();

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertCompanyDefault(Report::"Standard Sales - Invoice", 'StandardSalesInvoiceFR.docx');
        AssertCompanyDefault(Report::"Standard Sales - Credit Memo", 'StandardSalesCreditMemoFR.docx');
        AssertCompanyDefault(Report::"Standard Sales - Draft Invoice", 'StandardSalesDraftInvoiceFR.docx');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag()), 'Layout migration must be marked complete after the defaults are initialized.');
    end;

    [Test]
    procedure PreservesEveryShippedBaseAppLayoutSelection()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        LayoutCount: Integer;
    begin
        ReportLayoutList.SetFilter("Report ID", '%1|%2|%3',
            Report::"Standard Sales - Invoice", Report::"Standard Sales - Credit Memo", Report::"Standard Sales - Draft Invoice");
        ReportLayoutList.SetRange("Application ID", BaseApplicationAppIdTok);
        ReportLayoutList.SetFilter("Layout Format", '%1|%2', ReportLayoutList."Layout Format"::RDLC, ReportLayoutList."Layout Format"::Word);
        Assert.RecordIsNotEmpty(ReportLayoutList);
        ReportLayoutList.FindSet();
        repeat
            Initialize();
            InsertTenantSelection(ReportLayoutList."Report ID", GetCompanyName(), EmptyGuid, BaseApplicationAppIdTok, ReportLayoutList.Name);

            SalesFRReportLayouts.SetDefaultReportLayouts();

            TenantReportLayoutSelection.Get(ReportLayoutList."Report ID", GetCompanyName(), EmptyGuid);
            TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
            TenantReportLayoutSelection.TestField("Layout Name", ReportLayoutList.Name);
            Assert.IsFalse(ReportLayoutSelection.Get(ReportLayoutList."Report ID", GetCompanyName()), 'An existing tenant selection must not acquire a new legacy selection.');
            LayoutCount += 1;
        until ReportLayoutList.Next() = 0;
        Assert.AreEqual(15, LayoutCount, 'All shipped invoice, credit memo, and draft invoice variants must be covered.');
    end;

    [Test]
    procedure PreservesLegacyRDLCSelectionWithoutNamedLayout()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        ReportLayoutSelection."Report ID" := Report::"Standard Sales - Invoice";
        ReportLayoutSelection."Company Name" := GetCompanyName();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
        ReportLayoutSelection.Insert(true);

        SalesFRReportLayouts.SetDefaultReportLayouts();

        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"RDLC (built-in)");
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid), 'An explicit built-in selection must not acquire a new tenant default.');
    end;

    [Test]
    procedure PreservesExistingRestoredDefaultSelection()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        // Restore Default Selection removes the tenant selection but persists a built-in legacy row.
        ReportLayoutSelection."Report ID" := Report::"Standard Sales - Invoice";
        ReportLayoutSelection."Company Name" := GetCompanyName();
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.GetDefaultType(ReportLayoutSelection."Report ID"));
        ReportLayoutSelection.Insert(true);

        SalesFRReportLayouts.SetDefaultReportLayouts();

        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"Word (built-in)");
        ReportLayoutSelection.TestField("Custom Report Layout Code", '');
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid), 'An existing reset-to-default choice must remain in effect.');
    end;

    [Test]
    procedure PreservesTenantCustomLayout()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        InsertTenantSelection(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid, EmptyGuid, 'Customer invoice layout');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", EmptyGuid);
        TenantReportLayoutSelection.TestField("Layout Name", 'Customer invoice layout');
    end;

    [Test]
    procedure PreservesLayoutFromAnotherExtensionWithSameName()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        OtherAppId: Guid;
    begin
        Initialize();
        OtherAppId := CreateGuid();
        InsertTenantSelection(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid, OtherAppId, 'StandardSalesInvoice.docx');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", OtherAppId);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoice.docx');
    end;

    [Test]
    procedure PreservesLegacyCustomLayoutSelection()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        CustomLayoutCode: Code[20];
    begin
        Initialize();
        CustomLayoutCode := CustomReportLayout.InitBuiltInLayout(Report::"Standard Sales - Invoice", CustomReportLayout.Type::Word.AsInteger());
        ReportLayoutSelection."Report ID" := Report::"Standard Sales - Invoice";
        ReportLayoutSelection."Company Name" := GetCompanyName();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
        ReportLayoutSelection."Custom Report Layout Code" := CustomLayoutCode;
        ReportLayoutSelection.Insert(true);

        SalesFRReportLayouts.SetDefaultReportLayouts();

        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"Custom Layout");
        ReportLayoutSelection.TestField("Custom Report Layout Code", CustomLayoutCode);
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid), 'A legacy custom layout must not be replaced by a company default.');
    end;

    [Test]
    procedure PreservesBuiltInSelectionWithStaleCustomLayoutCode()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        CustomLayoutCode: Code[20];
    begin
        Initialize();
        CustomLayoutCode := CustomReportLayout.InitBuiltInLayout(Report::"Standard Sales - Invoice", CustomReportLayout.Type::Word.AsInteger());
        ReportLayoutSelection."Report ID" := Report::"Standard Sales - Invoice";
        ReportLayoutSelection."Company Name" := GetCompanyName();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Word (built-in)";
        ReportLayoutSelection."Custom Report Layout Code" := CustomLayoutCode;
        ReportLayoutSelection.Insert(true);
        InsertTenantSelection(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid, BaseApplicationAppIdTok, 'StandardSalesInvoiceBlueSimple.docx');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoiceBlueSimple.docx');
        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"Word (built-in)");
        ReportLayoutSelection.TestField("Custom Report Layout Code", CustomLayoutCode);
    end;

    [Test]
    procedure PreservesUnknownBaseAppLayout()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        InsertTenantSelection(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid, BaseApplicationAppIdTok, 'Another base application layout');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'Another base application layout');
    end;

    [Test]
    procedure PreservesPerUserSelection()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SelectedUserId: Guid;
    begin
        Initialize();
        SelectedUserId := CreateGuid();
        InsertTenantSelection(Report::"Standard Sales - Invoice", GetCompanyName(), SelectedUserId, BaseApplicationAppIdTok, 'StandardSalesInvoiceBlueSimple.docx');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertNoCompanyDefault(Report::"Standard Sales - Invoice");
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), SelectedUserId);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoiceBlueSimple.docx');
    end;

    [Test]
    procedure PreservesCompanylessDefaultsAndMarksInitializationComplete()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
    begin
        Initialize();
        InsertTenantSelection(Report::"Standard Sales - Invoice", '', EmptyGuid, BaseApplicationAppIdTok, 'StandardSalesInvoice.docx');
        InsertTenantSelection(Report::"Standard Sales - Credit Memo", '', EmptyGuid, BaseApplicationAppIdTok, 'StandardSalesCreditMemo.docx');
        InsertTenantSelection(Report::"Standard Sales - Draft Invoice", '', EmptyGuid, BaseApplicationAppIdTok, 'StandardSalesDraftInvoice.docx');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertNoCompanyDefault(Report::"Standard Sales - Invoice");
        AssertNoCompanyDefault(Report::"Standard Sales - Credit Memo");
        AssertNoCompanyDefault(Report::"Standard Sales - Draft Invoice");
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", '', EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoice.docx');
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Credit Memo", '', EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesCreditMemo.docx');
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Draft Invoice", '', EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesDraftInvoice.docx');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag()), 'Preserving existing choices must also complete initialization.');
    end;

    [Test]
    procedure PreservesCompanylessPerUserSelection()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SelectedUserId: Guid;
    begin
        Initialize();
        SelectedUserId := CreateGuid();
        InsertTenantSelection(Report::"Standard Sales - Invoice", '', SelectedUserId, BaseApplicationAppIdTok, 'StandardSalesInvoiceBlueSimple.docx');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertNoCompanyDefault(Report::"Standard Sales - Invoice");
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", '', SelectedUserId);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoiceBlueSimple.docx');
        AssertCompanyDefault(Report::"Standard Sales - Credit Memo", 'StandardSalesCreditMemoFR.docx');
        AssertCompanyDefault(Report::"Standard Sales - Draft Invoice", 'StandardSalesDraftInvoiceFR.docx');
    end;

    [Test]
    procedure PreservesOtherCompanySelection()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        OtherCompanyName: Text[30];
    begin
        Initialize();
        OtherCompanyName := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompanyName));
        InsertTenantSelection(Report::"Standard Sales - Invoice", OtherCompanyName, EmptyGuid, BaseApplicationAppIdTok, 'StandardSalesInvoiceBlueSimple.docx');

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertCompanyDefault(Report::"Standard Sales - Invoice", 'StandardSalesInvoiceFR.docx');
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", OtherCompanyName, EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoiceBlueSimple.docx');
    end;

    [Test]
    procedure RepeatedMigrationPreservesSelectedFRVariant()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        SalesFRReportLayouts.SetDefaultReportLayouts();
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection."Layout Name" := 'StandardSalesInvoiceBlueSimpleFR.docx';
        TenantReportLayoutSelection.Modify(true);

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertCompanyDefault(Report::"Standard Sales - Invoice", 'StandardSalesInvoiceBlueSimpleFR.docx');
        TenantReportLayoutSelection.SetRange("Company Name", GetCompanyName());
        TenantReportLayoutSelection.SetFilter("Report ID", '%1|%2|%3',
            Report::"Standard Sales - Invoice", Report::"Standard Sales - Credit Memo", Report::"Standard Sales - Draft Invoice");
        Assert.AreEqual(3, TenantReportLayoutSelection.Count(), 'Repeated migration must not create duplicate selections.');
    end;

    [Test]
    procedure RepeatedMigrationPreservesSelectedBaseAppLayout()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        SalesFRReportLayouts.SetDefaultReportLayouts();
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection."App ID" := BaseApplicationAppIdTok;
        TenantReportLayoutSelection."Layout Name" := 'StandardSalesInvoiceBlueSimple.docx';
        TenantReportLayoutSelection.Modify(true);

        SalesFRReportLayouts.SetDefaultReportLayouts();

        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", BaseApplicationAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", 'StandardSalesInvoiceBlueSimple.docx');
        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"Word (built-in)");
    end;

    [Test]
    procedure RepeatedMigrationPreservesResetToReportDefault()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Initialize();
        SalesFRReportLayouts.SetDefaultReportLayouts();
        TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.Delete(true);
        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.GetDefaultType(ReportLayoutSelection."Report ID"));
        ReportLayoutSelection.Modify(true);

        SalesFRReportLayouts.SetDefaultReportLayouts();

        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName(), EmptyGuid), 'A later upgrade must preserve the reset to the report default.');
        ReportLayoutSelection.Get(Report::"Standard Sales - Invoice", GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"Word (built-in)");
        ReportLayoutSelection.TestField("Custom Report Layout Code", '');
    end;

    [Test]
    procedure LayoutMigrationTagIsNotPreseededForNewCompanies()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
        PerCompanyUpgradeTags: List of [Code[250]];
    begin
        Initialize();

        UpgradeTag.GetPerCompanyUpgradeTags(PerCompanyUpgradeTags);

        Assert.IsFalse(PerCompanyUpgradeTags.Contains(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag()), 'New companies must initialize their layouts before receiving the layout migration tag.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag()), 'Collecting registered tags must not mark layout initialization complete.');
    end;

    [Test]
    procedure SelectsLayoutsWhenFieldMigrationTagAlreadyExists()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
    begin
        Initialize();
        if not UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag());

        SalesFRReportLayouts.SetDefaultReportLayouts();

        AssertCompanyDefault(Report::"Standard Sales - Invoice", 'StandardSalesInvoiceFR.docx');
        AssertCompanyDefault(Report::"Standard Sales - Credit Memo", 'StandardSalesCreditMemoFR.docx');
        AssertCompanyDefault(Report::"Standard Sales - Draft Invoice", 'StandardSalesDraftInvoiceFR.docx');
    end;

    local procedure Initialize()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
    begin
        ReportLayoutSelection.SetRange("Company Name", GetCompanyName());
        ReportLayoutSelection.SetFilter("Report ID", '%1|%2|%3',
            Report::"Standard Sales - Invoice", Report::"Standard Sales - Credit Memo", Report::"Standard Sales - Draft Invoice");
        ReportLayoutSelection.DeleteAll(true);
        TenantReportLayoutSelection.SetRange("Company Name", GetCompanyName());
        TenantReportLayoutSelection.SetFilter("Report ID", '%1|%2|%3',
            Report::"Standard Sales - Invoice", Report::"Standard Sales - Credit Memo", Report::"Standard Sales - Draft Invoice");
        TenantReportLayoutSelection.DeleteAll(true);
        TenantReportLayoutSelection.SetRange("Company Name", '');
        TenantReportLayoutSelection.DeleteAll(true);

        if UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag(), GetCompanyName());
    end;

    local procedure InsertTenantSelection(ReportID: Integer; SelectedCompany: Text[30]; SelectedUserId: Guid; AppId: Guid; LayoutName: Text[250])
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection."Report ID" := ReportID;
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."User ID" := SelectedUserId;
        TenantReportLayoutSelection."App ID" := AppId;
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection.Insert(true);
    end;

    local procedure AssertCompanyDefault(ReportID: Integer; LayoutName: Text[250])
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
    begin
        TenantReportLayoutSelection.Get(ReportID, GetCompanyName(), EmptyGuid);
        TenantReportLayoutSelection.TestField("App ID", SalesFRAppIdTok);
        TenantReportLayoutSelection.TestField("Layout Name", LayoutName);
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange("Application ID", SalesFRAppIdTok);
        ReportLayoutList.SetRange(Name, LayoutName);
        Assert.RecordIsNotEmpty(ReportLayoutList);
        ReportLayoutList.FindFirst();
        ReportLayoutList.TestField("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutSelection.Get(ReportID, GetCompanyName());
        ReportLayoutSelection.TestField(Type, ReportLayoutSelection.Type::"Word (built-in)");
    end;

    local procedure AssertNoCompanyDefault(ReportID: Integer)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        Assert.IsFalse(TenantReportLayoutSelection.Get(ReportID, GetCompanyName(), EmptyGuid), 'An existing selection must not be shadowed by a new company-wide tenant default.');
        Assert.IsFalse(ReportLayoutSelection.Get(ReportID, GetCompanyName()), 'An existing tenant selection must not acquire a new legacy default.');
    end;

    local procedure GetCompanyName(): Text[30]
    begin
        exit(CopyStr(CompanyName(), 1, 30));
    end;
}
#endif
