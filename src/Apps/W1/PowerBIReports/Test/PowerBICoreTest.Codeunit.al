// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.PowerBIReports.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.PowerBIReports;
using Microsoft.PowerBIReports;
using Microsoft.PowerBIReports.Test;
using System.TestLibraries.Security.AccessControl;


codeunit 139875 "PowerBI Core Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    Access = Internal;

    var
        Assert: Codeunit Assert;
        PermissionsMock: Codeunit "Permissions Mock";
        PowerBIAPIRequests: Codeunit "PowerBI API Requests";
        LibERM: Codeunit "Library - ERM";
        FilterScenario: Enum "PowerBI Filter Scenarios";
        FieldHiddenMsg: Label '''%1'' field should be hidden.', Comment = '%1 - field caption';
        FieldShownMsg: Label '''%1'' field should be shown.', Comment = '%1 - field caption';

    [Test]
    procedure TestGenerateItemSalesReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateItemSalesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Sales Load Date Type" := PBISetup."Item Sales Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Item Sales Start Date" := Today();
        PBISetup."Item Sales End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(Today()) + '..' + Format(Today() + 10);

        // [WHEN] GenerateItemSalesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Sales Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Item Sales Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Item Sales End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Item Sales Date Formula".Visible();

        // [THEN] A filter text of format "%1..%2" should be created
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] The Start Date & End Date fields should be shown.
        Assert.IsTrue(IsStartDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales Start Date".Caption()));
        Assert.IsTrue(IsEndDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales End Date".Caption()));
        Assert.IsFalse(IsDateFormulaVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Sales Date Formula".Caption()));
    end;

    [Test]
    procedure TestGenerateItemSalesReportDateFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateItemSalesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Sales Load Date Type" := PBISetup."Item Sales Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Item Sales Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CalcDate(PBISetup."Item Sales Date Formula")) + '..';

        // [WHEN] GenerateItemSalesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Sales Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Item Sales Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Item Sales End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Item Sales Date Formula".Visible();

        // [THEN] A filter text of format "%1.." should be created
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] The Date Formula field should be shown
        Assert.IsFalse(IsStartDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales Start Date".Caption()));
        Assert.IsFalse(IsEndDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales End Date".Caption()));
        Assert.IsTrue(IsDateFormulaVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales Date Formula".Caption()));
    end;

    [Test]
    procedure TestGenerateItemSalesReportDateFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateItemSalesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Sales Load Date Type" := PBISetup."Item Sales Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateItemSalesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Sales Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Item Sales Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Item Sales End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Item Sales Date Formula".Visible();

        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] All date setup fields must be hidden.
        Assert.IsFalse(IsStartDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales Start Date".Caption()));
        Assert.IsFalse(IsEndDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales End Date".Caption()));
        Assert.IsFalse(IsDateFormulaVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Sales Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateItemPurchasesReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateItemPurchasesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Purch. Load Date Type" := PBISetup."Item Purch. Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Item Purch. Start Date" := Today();
        PBISetup."Item Purch. End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(Today()) + '..' + Format(Today() + 10);

        // [WHEN] GenerateItemPurchasesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Purchases Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Item Purch. Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Item Purch. End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Item Purch. Date Formula".Visible();

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] The Start Date & End Date fields should be shown.
        Assert.IsTrue(IsStartDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Purch. Start Date".Caption()));
        Assert.IsTrue(IsEndDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Purch. End Date".Caption()));
        Assert.IsFalse(IsDateFormulaVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Purch. Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateItemPurchasesReportDateFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateItemPurchasesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Purch. Load Date Type" := PBISetup."Item Purch. Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Item Purch. Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CalcDate(PBISetup."Item Purch. Date Formula")) + '..';

        // [WHEN] GenerateItemPurchasesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Purchases Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Item Purch. Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Item Purch. End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Item Purch. Date Formula".Visible();

        // [THEN] A filter text of format "%1.." should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] The Date Formula field should be shown.
        Assert.IsFalse(IsStartDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Purch. Start Date".Caption()));
        Assert.IsFalse(IsEndDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Purch. End Date".Caption()));
        Assert.IsTrue(IsDateFormulaVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Item Purch. Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateItemPurchasesReportDateFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateItemPurchasesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Purch. Load Date Type" := PBISetup."Item Purch. Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateItemPurchasesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Purchases Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Item Purch. Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Item Purch. End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Item Purch. Date Formula".Visible();

        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] All date setup fields should be hidden.
        Assert.IsFalse(IsStartDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Purch. Start Date".Caption()));
        Assert.IsFalse(IsEndDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Purch. End Date".Caption()));
        Assert.IsFalse(IsDateFormulaVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Item Purch. Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateManufacturingReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Manufacturing Start Date" := Today();
        PBISetup."Manufacturing End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(Today()) + '..' + Format(Today() + 10);

        // [WHEN] GenerateManufacturingReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Manufacturing Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Manufacturing End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Manufacturing Date Formula".Visible();

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] The Start Date & End Date fields should be shown.
        Assert.IsTrue(IsStartDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Manufacturing Start Date".Caption()));
        Assert.IsTrue(IsEndDateVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Manufacturing End Date".Caption()));
        Assert.IsFalse(IsDateFormulaVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Manufacturing Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateManufacturingReportDateFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Manufacturing Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CalcDate(PBISetup."Manufacturing Date Formula")) + '..';

        // [WHEN] GenerateManufacturingReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Manufacturing Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Manufacturing End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Manufacturing Date Formula".Visible();

        // [THEN] A filter text of format "%1.." should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] The Date Formula field should be shown.
        Assert.IsFalse(IsStartDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Manufacturing Start Date".Caption()));
        Assert.IsFalse(IsEndDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Manufacturing End Date".Caption()));
        Assert.IsTrue(IsDateFormulaVisible, StrSubstNo(FieldShownMsg, PowerBIReportsSetup."Manufacturing Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateManufacturingReportDateFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        PowerBIReportsSetup: TestPage "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        IsStartDateVisible: Boolean;
        IsEndDateVisible: Boolean;
        IsDateFormulaVisible: Boolean;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateManufacturingReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date");

        // [WHEN] The Power BI Reports Setup page opens
        PowerBIReportsSetup.OpenEdit();
        IsStartDateVisible := PowerBIReportsSetup."Manufacturing Start Date".Visible();
        IsEndDateVisible := PowerBIReportsSetup."Manufacturing End Date".Visible();
        IsDateFormulaVisible := PowerBIReportsSetup."Manufacturing Date Formula".Visible();


        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');

        // [THEN] All date setup fields should be hidden.
        Assert.IsFalse(IsStartDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Manufacturing Start Date".Caption()));
        Assert.IsFalse(IsEndDateVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Manufacturing End Date".Caption()));
        Assert.IsFalse(IsDateFormulaVisible, StrSubstNo(FieldHiddenMsg, PowerBIReportsSetup."Manufacturing Date Formula".Caption()));
    end;

    [Test]
    procedure GenerateManufacturingReportDateTimeFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateTimeFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Manufacturing Start Date" := Today();
        PBISetup."Manufacturing End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CreateDateTime(Today(), 0T)) + '..' + Format(CreateDateTime(Today() + 10, 0T));

        // [WHEN] GenerateManufacturingReportDateTimeFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date Time");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure GenerateManufacturingReportDateTimeFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateTimeFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Manufacturing Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CreateDateTime(CalcDate(PBISetup."Manufacturing Date Formula"), 0T)) + '..';

        // [WHEN] GenerateManufacturingReportDateTimeFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date Time");

        // [THEN] A filter text of format "%1.." should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure GenerateManufacturingReportDateTimeFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateTimeFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateManufacturingReportDateTimeFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date Time");

        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure GenerateFinanceReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
        ExpectedFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateFinanceReportDateFilter
        // [GIVEN] Power BI setup record is created
        AssignAdminPermissionSet();
        RecreatePBISetup();

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Finance Start Date" := Today();
        PBISetup."Finance End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(Today()) + '..' + Format(Today() + 10);

        // [WHEN] GenerateFinanceReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Finance Date");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure GenerateFinanceReportDateFilter_Blank()
    var
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateFinanceReportDateFilter
        // [GIVEN] Power BI setup record is created with blank start & end dates
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateFinanceReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Finance Date");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    local procedure RecreatePBISetup()
    var
        PBISetup: Record "PowerBI Reports Setup";
    begin
        if PBISetup.Get() then
            PBISetup.Delete();
        PBISetup.Init();
        PBISetup.Insert();
    end;

    procedure AssignAdminPermissionSet()
    begin
        PermissionsMock.Assign('PowerBI Report Admin');
        PermissionsMock.Assign('D365 BUS FULL ACCESS');
    end;



    [Test]
    procedure TestGenerateFinanceReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateFinanceReportDateFilter
        // [GIVEN] Power BI setup record is created
        AssignAdminPermissionSet();
        RecreatePBISetup();

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Finance Start Date" := Today();
        PBISetup."Finance End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := StrSubstNo(Format(Today()) + '..' + Format(Today() + 10));

        // [WHEN] GenerateFinanceReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Finance Date");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateFinanceReportDateFilter_Blank()
    var
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateFinanceReportDateFilter
        // [GIVEN] Power BI setup record is created with blank start & end dates
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateFinanceReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Finance Date");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure VerifyEditingPowerBIAccCategoryWhenGLAccCategoryContainsSpecialCharacter()
    var
        GLAccountCategory: Record "G/L Account Category";
        AccountCategories: TestPage "Account Categories";
    begin
        // [SCENARIO 572645] Verify editing of Power BI account categories when the G/L account category contains the special character ')', and ensure the update is successful without errors.
        // Permission Set.
        PermissionsMock.Assign('SUPER');
        AssignAdminPermissionSet();
        RecreatePBISetup();

        // [GIVEN] Create G/L Account Category.
        LibERM.CreateGLAccountCategory(GLAccountCategory);

        // [GIVEN] Change the G/L account category description and add a special character to the description.
        GLAccountCategory.Validate(Description, '');
        GLAccountCategory.Validate(Description, '3)Cash');
        GLAccountCategory.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] Account Category page is open
        AccountCategories.OpenEdit();
        AccountCategories.First();

        // [THEN] Edit the Power BI account categories and add the G/L account category that contains the special character.The system did not display any errors, and the category was successfully changed.
        AccountCategories.AccountCategoryDescription.SetValue(GLAccountCategory.Description);
    end;

    [Test]
    procedure TestGenerateManufacturingReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Manufacturing Start Date" := Today();
        PBISetup."Manufacturing End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(Today()) + '..' + Format(Today() + 10);

        // [WHEN] GenerateManufacturingReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateManufacturingReportDateFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Manufacturing Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CalcDate(PBISetup."Manufacturing Date Formula")) + '..';

        // [WHEN] GenerateManufacturingReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date");

        // [THEN] A filter text of format "%1.." should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateManufacturingReportDateFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateManufacturingReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date");

        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateManufacturingReportDateTimeFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateTimeFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Manufacturing Start Date" := Today();
        PBISetup."Manufacturing End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CreateDateTime(Today(), 0T)) + '..' + Format(CreateDateTime(Today() + 10, 0T));

        // [WHEN] GenerateManufacturingReportDateTimeFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date Time");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateManufacturingReportDateTimeFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateTimeFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Manufacturing Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CreateDateTime(CalcDate(PBISetup."Manufacturing Date Formula"), 0T)) + '..';

        // [WHEN] GenerateManufacturingReportDateTimeFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date Time");

        // [THEN] A filter text of format "%1.." should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateManufacturingReportDateTimeFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateManufacturingReportDateTimeFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Manufacturing Load Date Type" := PBISetup."Manufacturing Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateManufacturingReportDateTimeFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Manufacturing Date Time");

        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateItemPurchasesReportDateFilter_StartEndDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateItemPurchasesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Start/End Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Purch. Load Date Type" := PBISetup."Item Purch. Load Date Type"::"Start/End Date";

        // [GIVEN] Mock start & end date values are entered 
        PBISetup."Item Purch. Start Date" := Today();
        PBISetup."Item Purch. End Date" := Today() + 10;
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(Today()) + '..' + Format(Today() + 10);

        // [WHEN] GenerateItemPurchasesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Purchases Date");

        // [THEN] A filter text of format "%1..%2" should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateItemPurchasesReportDateFilter_RelativeDate()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ExpectedFilterTxt: Text;
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateItemPurchasesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = "Relative Date"
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Purch. Load Date Type" := PBISetup."Item Purch. Load Date Type"::"Relative Date";

        // [GIVEN] A mock date formula value
        Evaluate(PBISetup."Item Purch. Date Formula", '30D');
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        ExpectedFilterTxt := Format(CalcDate(PBISetup."Item Purch. Date Formula")) + '..';

        // [WHEN] GenerateItemPurchasesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Purchases Date");

        // [THEN] A filter text of format "%1.." should be created 
        Assert.AreEqual(ExpectedFilterTxt, ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

    [Test]
    procedure TestGenerateItemPurchasesReportDateFilter_Blank()
    var
        PBISetup: Record "PowerBI Reports Setup";
        ActualFilterTxt: Text;
    begin
        // [SCENARIO] Test GenerateItemPurchasesReportDateFilter
        // [GIVEN] Power BI setup record is created with Load Date Type = " "
        AssignAdminPermissionSet();
        RecreatePBISetup();
        PBISetup."Item Purch. Load Date Type" := PBISetup."Item Purch. Load Date Type"::" ";
        PBISetup.Modify();
        PermissionsMock.ClearAssignments();

        // [WHEN] GenerateItemPurchasesReportDateFilter executes 
        ActualFilterTxt := PowerBIAPIRequests.GetFilterForQueryScenario(FilterScenario::"Purchases Date");

        // [THEN] A blank filter text should be created 
        Assert.AreEqual('', ActualFilterTxt, 'The expected & actual filter text did not match.');
    end;

}
