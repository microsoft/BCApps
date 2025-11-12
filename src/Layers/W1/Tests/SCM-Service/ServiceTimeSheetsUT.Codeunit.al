namespace Microsoft.Service.Test;

using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.TimeSheet;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;

codeunit 136510 "Service Time Sheets UT"
{
    Permissions = TableData "Time Sheet Posting Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet]
    end;

    var
        LibraryHumanResource: Codeunit "Library - Human Resource";
        ServTimeSheetMgt: Codeunit "Serv. Time Sheet Mgt.";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVAriableStorage: Codeunit "Library - Variable Storage";
        GlobalWorkTypeCode: Code[10];
        GlobalChargeable: Boolean;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateServiceOrderLinesFromTS()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        // [FEATURE] [Time Sheet] [Service Order]
        // [SCENARIO] "Create lines from time sheets" for Service Order creates service order lines, after posting Service Order TS lines are posted.

        // test for function "Create lines from time sheets" for Service Order
        Initialize();

        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryService.CreateServiceOrder(ServiceHeader, CalcDate('<+3D>', TimeSheetHeader."Starting Date"));

        // create time sheet line with type Service
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Service, '', '', '', '');
        TimeSheetLine.Validate("Service Order No.", ServiceHeader."No.");
        TimeSheetLine.Modify();

        // create details for 2 days
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetHeader."Starting Date" + 1, LibraryTimeSheet.GetRandomDecimal());
        // submit and approve
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // create lines from time sheet
        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        TimeSheetLine.Find();
        // Posted should be Yes
        Assert.IsTrue(TimeSheetLine.Posted, 'Time sheet line has to be posted.');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateServiceOrderLinesFromFewTSLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: array[3] of Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        RowCount: Integer;
    begin
        // test for function "Create lines from time sheets" for Service Order for 3 lines in time sheet
        Initialize();

        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryService.CreateServiceOrder(ServiceHeader, CalcDate('<+3D>', TimeSheetHeader."Starting Date"));

        // create several time sheet line with type Service
        for RowCount := 1 to 3 do begin
            // create time sheet line with type Service
            LibraryTimeSheet.CreateTimeSheetLine(
              TimeSheetHeader, TimeSheetLine[RowCount], TimeSheetLine[RowCount].Type::Service, '', '', '', '');
            TimeSheetLine[RowCount].Validate("Service Order No.", ServiceHeader."No.");
            TimeSheetLine[RowCount].Modify();
            // create details for 2 days
            LibraryTimeSheet.CreateTimeSheetDetail(
              TimeSheetLine[RowCount], TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
            LibraryTimeSheet.CreateTimeSheetDetail(
              TimeSheetLine[RowCount], TimeSheetHeader."Starting Date" + 1, LibraryTimeSheet.GetRandomDecimal());
            // submit and approve
            TimeSheetApprovalMgt.Submit(TimeSheetLine[RowCount]);
            TimeSheetApprovalMgt.Approve(TimeSheetLine[RowCount]);
            // create lines from time sheet
            ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);
        end;

        VerifyServiceLinesQty(ServiceHeader."No.", TimeSheetHeader."No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateServiceOrderLinesFromFewTS()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        TimeSheetNo: array[2] of Code[20];
    begin
        Initialize();
        // test for function "Create lines from time sheets" for Service Order for few time sheets
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        TimeSheetNo[1] := TimeSheetHeader."No.";

        ServiceHeader.Find();

        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        TimeSheetNo[2] := TimeSheetHeader."No.";

        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        VerifyServiceLinesQtyForFewTS(ServiceHeader."No.", TimeSheetNo);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAutoCreateServiceOrderLinesFromFewTSLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        RowCount: Integer;
        NoOfTimeSheetLines: Integer;
    begin
        // test for function "Create lines from time sheets" for Service Order with 3 time sheet lines and auto create in service setup = true
        Initialize();
        ModifyCopyTimeSheetLinesinServiceSetup(true);

        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryService.CreateServiceOrder(ServiceHeader, CalcDate('<+3D>', TimeSheetHeader."Starting Date"));

        // create several time sheet line with type Service
        NoOfTimeSheetLines := LibraryRandom.RandIntInRange(2, 10);
        for RowCount := 1 to NoOfTimeSheetLines do begin
            // create time sheet line with type Service
            Clear(TimeSheetLine);
            LibraryTimeSheet.CreateTimeSheetLine(
              TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Service, '', '', '', '');
            TimeSheetLine.Validate("Service Order No.", ServiceHeader."No.");
            TimeSheetLine.Modify();
            // create details for 2 days
            LibraryTimeSheet.CreateTimeSheetDetail(
              TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
            LibraryTimeSheet.CreateTimeSheetDetail(
              TimeSheetLine, TimeSheetHeader."Starting Date" + 1, LibraryTimeSheet.GetRandomDecimal());
            // submit and approve
            TimeSheetApprovalMgt.Submit(TimeSheetLine);
            TimeSheetApprovalMgt.Approve(TimeSheetLine);
        end;

        VerifyServiceLinesQty(ServiceHeader."No.", TimeSheetHeader."No.");
        ModifyCopyTimeSheetLinesinServiceSetup(false);
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateServiceOrderLinesByTSLine()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
    begin
        Initialize();
        // test for function "CreateServDocLinesFromTSLine" for Service Order from mulitple few time sheets
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        ServiceHeader.Find();
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        ServTimeSheetMgt.CreateServDocLinesFromTSLine(ServiceHeader, TimeSheetLine);

        // Verify: only one timesheet header was added to the service order.
        VerifyServiceLinesQty(ServiceHeader."No.", TimeSheetHeader."No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApproveTSServiceLinesWithAutoCreateFalse()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        ServiceLinesCount: Integer;
    begin
        // test to approve time sheet lines with Service Order when the auto flag is set to false.
        Initialize();
        ModifyCopyTimeSheetLinesinServiceSetup(false);
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);
        LibraryService.CreateServiceOrder(ServiceHeader, CalcDate('<+3D>', TimeSheetHeader."Starting Date"));

        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceLinesCount := ServiceLine.Count();

        // create time sheet line with type Service
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Service, '', '', '', '');
        TimeSheetLine.Validate("Service Order No.", ServiceHeader."No.");
        TimeSheetLine.Modify();

        // create details for 2 days
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetHeader."Starting Date" + 1, LibraryTimeSheet.GetRandomDecimal());
        // submit and approve
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // verify: no service lines have been created by approval.
        Clear(ServiceLine);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        Assert.AreEqual(ServiceLinesCount, ServiceLine.Count, 'No service Lines have been added');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateServiceOrderLinesFromUnchargealeTS()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
    begin
        Initialize();
        // test for function "Create lines from time sheets" for line in time sheet with Chargeagle = No
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        TimeSheetLine.Validate(Chargeable, false);
        TimeSheetLine.Modify();

        // create lines from time sheet
        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);
        VerifyServiceLinesQty(ServiceHeader."No.", TimeSheetHeader."No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteAndCreateServiceOrderLinesFromTS()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        Initialize();
        // test for function "Create lines from time sheets" for Service Order
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        // create lines from time sheet
        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        // delete service order lines
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindFirst() then
            ServiceLine.Delete();

        // create lines from time sheet
        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        // verify Service Lines Qty.
        VerifyServiceLinesQty(ServiceHeader."No.", TimeSheetHeader."No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateServiceOrderLinesFromTSWithAllTypesOfLines()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        Initialize();
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        AddRowsWithDifferentTypes(TimeSheetHeader, TimeSheetLine);

        // set quantities for lines
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Open);
        if TimeSheetLine.FindSet() then
            repeat
                LibraryTimeSheet.CreateTimeSheetDetail(
                  TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
            until TimeSheetLine.Next() = 0;

        // submit and approve
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.Submit(TimeSheetLine);
                TimeSheetApprovalMgt.Approve(TimeSheetLine);
            until TimeSheetLine.Next() = 0;

        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        VerifyServiceLinesQty(ServiceHeader."No.", TimeSheetHeader."No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResourceDimensionWayFromTSToServiceOrder()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
    begin
        Initialize();

        // create time sheet
        LibraryTimeSheet.CreateTimeSheet(TimeSheetHeader, false);

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionResource(
          DefaultDimension, TimeSheetHeader."Resource No.", Dimension.Code, DimensionValue.Code);

        // create service order (or credit memo)
        LibraryService.CreateServiceOrder(ServiceHeader, CalcDate('<+3D>', TimeSheetHeader."Starting Date"));

        // create time sheet line with type Service
        LibraryTimeSheet.CreateTimeSheetLine(
          TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Service, '', '', ServiceHeader."No.", '');
        TimeSheetLine.Validate("Service Order No.", ServiceHeader."No.");
        TimeSheetLine.Modify();

        // set quantities for lines
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
        LibraryTimeSheet.CreateTimeSheetDetail(
          TimeSheetLine, TimeSheetHeader."Starting Date" + 1, LibraryTimeSheet.GetRandomDecimal());

        // submit and approve lines
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        VerifyDimensions(ServiceHeader."No.", TimeSheetHeader."Resource No.");

        TearDown();
    end;

    [Test]
    [HandlerFunctions('TimeSheetLineServDetailHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestWorkTypeChargChangingForServiceOrderApprove()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        Resource: Record Resource;
        WorkType: Record "Work Type";
        ManagerTimeSheet: TestPage "Manager Time Sheet";
    begin
        Initialize();
        LibraryService.InitScenarioWTForServiceOrder(TimeSheetHeader, ServiceHeader);

        // create work type
        Resource.Get(TimeSheetHeader."Resource No.");
        LibraryTimeSheet.CreateWorkType(WorkType, Resource."Base Unit of Measure");

        // change chargeable and work type on the manager page
        WorkDate := TimeSheetHeader."Starting Date";
        ManagerTimeSheet.OpenEdit();
        ManagerTimeSheet.CurrTimeSheetNo.Value := TimeSheetHeader."No.";
        ManagerTimeSheet.FILTER.SetFilter(Status, 'Submitted');
        ManagerTimeSheet.First();
        GlobalWorkTypeCode := WorkType.Code;
        GlobalChargeable := false;
        ManagerTimeSheet.Description.AssistEdit();
        ManagerTimeSheet.Approve.Invoke();

        // compare table and page results
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        TimeSheetLine.FindFirst();
        TimeSheetLine.TestField("Work Type Code", GlobalWorkTypeCode);
        TimeSheetLine.TestField(Chargeable, GlobalChargeable);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartAddColumnsTimeSheetApprover()
    begin
        // test verifies the resource list for manager-approver, not time sheet admin
        InitTimeSheetChartApprover(false);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartAddColumnsTimeSheetAdmin()
    begin
        // test verifies the resource list for manager-approver, time sheet admin
        InitTimeSheetChartApprover(true);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureIndex2MeasureType_Status()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        VerifyMeasureIndex2MeasureTypeTransformation(TimeSheetChartSetup."Show by"::Status);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureIndex2MeasureType_Type()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        VerifyMeasureIndex2MeasureTypeTransformation(TimeSheetChartSetup."Show by"::Type);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMeasureIndex2MeasureType_Posted()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        VerifyMeasureIndex2MeasureTypeTransformation(TimeSheetChartSetup."Show by"::Posted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartMeasuresName_Status()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
        VerifyFlowChartMeasures(TimeSheetChartSetup."Show by"::Status);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartMeasuresName_Type()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
        VerifyFlowChartMeasures(TimeSheetChartSetup."Show by"::Type);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowChartMeasuresName_Posted()
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
        VerifyFlowChartMeasures(TimeSheetChartSetup."Show by"::Posted);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTSLinesFromServiceLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        ServiceLine: Record "Service Line";
        Date: Date;
        DocumentNo: Code[20];
    begin
        // UT for TimeSheetMgt.CreateTSLineFromServiceLine

        // setup
        Date := WorkDate();
        DocumentNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentNo));
        InitUTScenario(Resource, TimeSheetHeader, Date);
        InitServiceLine(ServiceLine, Resource."No.", Date);

        // exercise
        ServTimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, DocumentNo, true);

        // verify
        VerifyCreatedTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetDetail, Date);

        TimeSheetLine.TestField(Description, ServiceLine.Description);
        TimeSheetLine.TestField("Service Order No.", ServiceLine."Document No.");
        TimeSheetLine.TestField("Service Order Line No.", ServiceLine."Line No.");
        TimeSheetLine.TestField("Work Type Code", ServiceLine."Work Type Code");
        TimeSheetLine.TestField(Chargeable, true);

        TimeSheetDetail.TestField(Quantity, -ServiceLine."Qty. to Ship");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTSLinesFromServiceShptLine()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        ServiceShipmentLine: Record "Service Shipment Line";
        Date: Date;
    begin
        // UT for TimeSheetMgt.CreateTSLineFromServiceShptLine

        // setup
        Date := WorkDate();
        InitUTScenario(Resource, TimeSheetHeader, Date);
        InitServiceShptLine(ServiceShipmentLine, Resource."No.", Date);

        // exercise
        ServTimeSheetMgt.CreateTSLineFromServiceShptLine(ServiceShipmentLine);

        // verify
        VerifyCreatedTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetDetail, Date);

        TimeSheetLine.TestField(Description, ServiceShipmentLine.Description);
        TimeSheetLine.TestField("Work Type Code", ServiceShipmentLine."Work Type Code");
        TimeSheetLine.TestField("Service Order No.", ServiceShipmentLine."Order No.");
        TimeSheetLine.TestField("Service Order Line No.", ServiceShipmentLine."Order Line No.");

        TimeSheetDetail.TestField(Quantity, -ServiceShipmentLine."Qty. Shipped Not Invoiced");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTSFromSL_notTSResource()
    var
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
    begin
        // UT for TimeSheetMgt.CreateTSLineFromServiceLine
        // if Resource."Use Time Sheet" = FALSE, then time sheet line should not be created

        // setup
        Resource.Init();
        Resource."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(Resource."No."));
        Resource.Insert();

        InitServiceLine(ServiceLine, Resource."No.", WorkDate());

        // exercise (Document Number is not needed in this case)
        ServTimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, '', true);

        // verify
        VerifyNoTSLineExistsForServiceDocLine(ServiceLine."Document No.", ServiceLine."Line No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTSFromSL_SLwithTSNo()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceLine: Record "Service Line";
        Date: Date;
        DocumentNo: Code[20];
    begin
        // UT for TimeSheetMgt.CreateTSLineFromServiceLine
        // if ServiceLine."Time Sheet No." is fileld in, then time sheet line should not be created

        // setup
        Date := WorkDate();
        DocumentNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentNo));
        InitUTScenario(Resource, TimeSheetHeader, Date);
        InitServiceLine(ServiceLine, Resource."No.", Date);
        ServiceLine."Time Sheet No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceLine."Time Sheet No."));

        // exercise
        ServTimeSheetMgt.CreateTSLineFromServiceLine(ServiceLine, DocumentNo, true);

        // verify
        VerifyNoTSLineExistsForServiceDocLine(ServiceLine."Document No.", ServiceLine."Line No.");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateTSFromSSL_SSLwithTSNo()
    var
        Resource: Record Resource;
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        Date: Date;
    begin
        // UT for TimeSheetMgt.CreateTSLineFromServiceShptLine
        // if ServiceShipmentLine."Time Sheet No." is fileld in, then time sheet line should not be created

        // setup
        Date := WorkDate();
        InitUTScenario(Resource, TimeSheetHeader, Date);
        InitServiceShptLine(ServiceShipmentLine, Resource."No.", Date);
        ServiceShipmentLine."Time Sheet No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceShipmentLine."Time Sheet No."));

        // exercise
        ServTimeSheetMgt.CreateTSLineFromServiceShptLine(ServiceShipmentLine);

        // verify
        VerifyNoTSLineExistsForServiceDocLine(ServiceShipmentLine."Order No.", ServiceShipmentLine."Order Line No.");

        TearDown();
    end;

    local procedure Initialize()
    var
        UserSetup: Record System.Security.User."User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Time Sheets UT");

        if IsInitialized then
            exit;

        IsInitialized := true;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Service Time Sheets UT");

        LibraryTimeSheet.Initialize();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        // create current user id setup for approver
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Service Time Sheets UT");
    end;

    local procedure TearDown()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        Resource: Record Resource;
    begin
        TimeSheetHeader.DeleteAll();
        TimeSheetLine.DeleteAll();

        TimeSheetDetail.DeleteAll();
        Resource.ModifyAll("Use Time Sheet", false);
        Resource.ModifyAll("Time Sheet Owner User ID", '');
        Resource.ModifyAll("Time Sheet Approver User ID", '');
    end;

    local procedure InitUTScenario(var Resource: Record Resource; var TimeSheetHeader: Record "Time Sheet Header"; Date: Date)
    begin
        Resource.Init();
        Resource."No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Resource.FieldNo("No."), DATABASE::Resource), 1, MaxStrLen(Resource."No."));
        Resource."Use Time Sheet" := true;
        Resource.Insert();

        TimeSheetHeader.Init();
        TimeSheetHeader."No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(TimeSheetHeader.FieldNo("No."), DATABASE::"Time Sheet Header"), 1,
            MaxStrLen(TimeSheetHeader."No."));
        TimeSheetHeader."Resource No." := Resource."No.";
        TimeSheetHeader."Starting Date" := CalcDate('<-CW>', Date);
        TimeSheetHeader."Ending Date" := CalcDate('<CW>', Date);
        TimeSheetHeader."Approver User ID" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(TimeSheetHeader."Approver User ID"));
        TimeSheetHeader.Insert();
    end;

    local procedure InitServiceLine(var ServiceLine: Record "Service Line"; ResourceNo: Code[20]; Date: Date)
    begin
        ServiceLine."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceLine."Document No."));
        ServiceLine."Line No." := Round(LibraryUtility.GenerateRandomFraction() * 10000, 1);
        ServiceLine."No." := ResourceNo;
        ServiceLine."Posting Date" := Date;
        ServiceLine."Work Type Code" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceLine."Work Type Code"));
        ServiceLine.Description := Format(CreateGuid());
        ServiceLine."Qty. to Ship" := LibraryUtility.GenerateRandomFraction() * 10;
    end;

    local procedure InitServiceShptLine(var ServiceShipmentLine: Record "Service Shipment Line"; ResourceNo: Code[20]; Date: Date)
    begin
        ServiceShipmentLine."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceShipmentLine."Document No."));
        ServiceShipmentLine."Line No." := Round(LibraryUtility.GenerateRandomFraction() * 10000, 1);
        ServiceShipmentLine."No." := ResourceNo;
        ServiceShipmentLine."Posting Date" := Date;
        ServiceShipmentLine."Work Type Code" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceShipmentLine."Work Type Code"));
        ServiceShipmentLine.Description := Format(CreateGuid());
        ServiceShipmentLine."Qty. Shipped Not Invoiced" := LibraryUtility.GenerateRandomFraction() * 10;
        ServiceShipmentLine."Order No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ServiceShipmentLine."Order No."));
        ServiceShipmentLine."Order Line No." := Round(LibraryUtility.GenerateRandomFraction() * 10000, 1);
    end;

    local procedure InitTimeSheetChartApprover(IsAdmin: Boolean)
    var
        UserSetup: Record System.Security.User."User Setup";
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        Resource: Record Resource;
        BusChartBuf: Record System.Visualization."Business Chart Buffer";
        BusChartMapColumn: Record System.Visualization."Business Chart Map";
    begin
        // setup for managers with different roles testing
        Initialize();

        // resource - person
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        if IsAdmin then
            Resource.Validate("Time Sheet Approver User ID", UserSetup."User ID")
        else
            Resource.Validate("Time Sheet Approver User ID", UserId);
        Resource.Modify();

        SetupTimeSheetChart(TimeSheetChartSetup, UserId, WorkDate());

        if IsAdmin then begin
            UserSetup.Get(UserId);
            UserSetup.Validate("Time Sheet Admin.", true);
            UserSetup.Modify();
        end;

        if not IsAdmin then
            Resource.SetRange("Time Sheet Approver User ID", UserId);
        Resource.SetRange("Use Time Sheet", true);

        ChangeTimeSheetChartShowBy(TimeSheetChartSetup, BusChartBuf, TimeSheetChartSetup."Show by"::Status);

        if BusChartBuf.FindFirstColumn(BusChartMapColumn) and Resource.FindSet() then
            repeat
                Assert.AreEqual(Resource."No.", BusChartMapColumn.Name, 'Incorrect time sheet chart column name.');
            until not BusChartBuf.NextColumn(BusChartMapColumn) and (Resource.Next() = 0);
    end;

    local procedure SetupTimeSheetChart(var TimeSheetChartSetup: Record "Time Sheet Chart Setup"; UID: Text; Date: Date)
    begin
        if not TimeSheetChartSetup.Get(UID) then begin
            TimeSheetChartSetup."User ID" := UID;
            TimeSheetChartSetup.Insert();
        end;
        TimeSheetChartSetup."Starting Date" := Date;
        TimeSheetChartSetup.Modify();
    end;

    local procedure VerifyCreatedTimeSheetLine(TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line"; var TimeSheetDetail: Record "Time Sheet Detail"; Date: Date)
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsTrue(TimeSheetLine.FindFirst(), 'Time sheet line is not created.');
        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.TestField(Posted, true);
        TimeSheetLine.TestField("Approver ID", TimeSheetHeader."Approver User ID");
        TimeSheetLine.TestField("Approved By", UserId);
        TimeSheetLine.TestField("Approval Date", Today);

        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        Assert.IsTrue(TimeSheetDetail.FindFirst(), 'Time sheet detail is not found.');
        TimeSheetDetail.TestField(Date, Date);
    end;

    local procedure VerifyNoTSLineExistsForServiceDocLine(ServiceOrderNo: Code[20]; ServiceOrderLineNo: Integer)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Service);
        TimeSheetLine.SetRange("Service Order No.", ServiceOrderNo);
        TimeSheetLine.SetRange("Service Order Line No.", ServiceOrderLineNo);
        Assert.IsTrue(TimeSheetLine.IsEmpty, 'Time sheet line must not be created.');
    end;

    local procedure AddRowsWithDifferentTypes(var TimeSheetHeader: Record "Time Sheet Header"; var TimeSheetLine: Record "Time Sheet Line")
    var
        CauseOfAbsence: Record "Cause of Absence";
        Job: Record Job;
        JobTask: Record "Job Task";
        Employee: Record Employee;
        Resource: Record Resource;
    begin
        // create time sheet line with type Resource
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Resource, '', '', '', '');
        TimeSheetLine.Description := 'simple resource line';
        TimeSheetLine.Modify();

        // create time sheet line with type Job
        // find job and task
        LibraryTimeSheet.FindJob(Job);
        LibraryTimeSheet.FindJobTask(Job."No.", JobTask);
        // job's responsible person (resource) must have Owner ID filled in
        Resource.Get(Job."Person Responsible");
        Resource."Time Sheet Owner User ID" := UserId;
        Resource.Modify();
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Job, Job."No.",
          JobTask."Job Task No.", '', '');

        // create time sheet line with type Absence
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."Resource No." := TimeSheetHeader."Resource No.";
        Employee.Modify();

        LibraryTimeSheet.FindCauseOfAbsence(CauseOfAbsence);
        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Absence, '', '', '',
          CauseOfAbsence.Code);
        TimeSheetLine.Chargeable := false;
        TimeSheetLine.Modify();
    end;

    local procedure VerifyDimensions(ServiceOrderNo: Code[20]; ResourceNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntryQty: Integer;
        EqualDimensionQty: Integer;
    begin
        // calc service order quantity
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.SetRange("No.", ResourceNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Resource);
        if ServiceLine.FindSet() then
            repeat
                // find resource's dimensions by service line
                DimensionSetEntry.SetRange("Dimension Set ID", ServiceLine."Dimension Set ID");
                if DimensionSetEntry.FindSet() then begin
                    DimensionSetEntryQty := 0;
                    EqualDimensionQty := 0;
                    repeat
                        // find resource's dimensions by resource no.
                        DefaultDimension.SetRange("Table ID", DATABASE::Resource);
                        DefaultDimension.SetRange("No.", ResourceNo);
                        if DefaultDimension.FindSet() then
                            repeat
                                if DefaultDimension."Dimension Code" = DimensionSetEntry."Dimension Code" then
                                    EqualDimensionQty := EqualDimensionQty + 1;
                            until DefaultDimension.Next() = 0;
                        DimensionSetEntryQty := DimensionSetEntryQty + 1;
                    until DimensionSetEntry.Next() = 0;
                    Assert.AreEqual(DimensionSetEntryQty, EqualDimensionQty, 'Dimensions are not the same.');
                end;
            until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLinesQty(ServiceOrderNo: Code[20]; TimeSheetNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        ServiceLineQty: Decimal;
        ServiceLineQtyCon: Decimal;
        TimeSheetCharQty: Decimal;
        TimeSheetUncharQty: Decimal;
        Chargable: Boolean;
    begin
        // calc service order quantity
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        // type
        if ServiceLine.FindSet() then
            repeat
                ServiceLineQtyCon := ServiceLineQtyCon + ServiceLine."Qty. to Consume";
                ServiceLineQty := ServiceLineQty + ServiceLine.Quantity;
            until ServiceLine.Next() = 0;

        // calc time sheet quantity
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        if TimeSheetLine.FindSet() then
            repeat
                Chargable := TimeSheetLine.Chargeable;
                TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
                TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
                TimeSheetDetail.SetRange("Service Order No.", ServiceOrderNo);
                if TimeSheetDetail.FindSet() then
                    repeat
                        if Chargable then
                            TimeSheetCharQty := TimeSheetCharQty + TimeSheetDetail.Quantity
                        else
                            TimeSheetUncharQty := TimeSheetUncharQty + TimeSheetDetail.Quantity
                    until TimeSheetDetail.Next() = 0;
            until TimeSheetLine.Next() = 0;

        Assert.AreEqual(ServiceLineQtyCon, TimeSheetUncharQty, 'Incorrect service lines consume quantity.');
        Assert.AreEqual(ServiceLineQty, TimeSheetCharQty + TimeSheetUncharQty, 'Incorrect service lines quantity.');
    end;

    local procedure VerifyServiceLinesQtyForFewTS(ServiceOrderNo: Code[20]; TimeSheetNo: array[2] of Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceLineQty: Decimal;
        ServiceLineQtyCon: Decimal;
        TimeSheetCharQty: array[2] of Decimal;
        TimeSheetUncharQty: array[2] of Decimal;
    begin
        // calc service order quantity
        ServiceLine.SetRange("Document No.", ServiceOrderNo);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);

        // type
        if ServiceLine.FindSet() then
            repeat
                ServiceLineQtyCon := ServiceLineQtyCon + ServiceLine."Qty. to Consume";
                ServiceLineQty := ServiceLineQty + ServiceLine.Quantity;
            until ServiceLine.Next() = 0;

        CalcTSQuantity(ServiceOrderNo, TimeSheetNo[1], TimeSheetUncharQty[1], TimeSheetCharQty[1]);
        CalcTSQuantity(ServiceOrderNo, TimeSheetNo[2], TimeSheetUncharQty[2], TimeSheetCharQty[2]);

        Assert.AreEqual(ServiceLineQtyCon, TimeSheetUncharQty[1] + TimeSheetUncharQty[2], 'Incorrect service lines consume quantity.');
        Assert.AreEqual(
          ServiceLineQty, TimeSheetCharQty[1] + TimeSheetUncharQty[1] + TimeSheetCharQty[2] + TimeSheetUncharQty[2],
          'Incorrect service lines quantity.');
    end;

    local procedure CalcTSQuantity(ServiceOrderNo: Code[20]; TimeSheetNo: Code[20]; var QtyUnchargLines: Decimal; var QtyChargLines: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        // calc time sheet quantity
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetNo);
                TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
                TimeSheetDetail.SetRange("Service Order No.", ServiceOrderNo);
                if TimeSheetDetail.FindSet() then
                    repeat
                        if TimeSheetLine.Chargeable then
                            QtyChargLines := QtyChargLines + TimeSheetDetail.Quantity
                        else
                            QtyUnchargLines := QtyUnchargLines + TimeSheetDetail.Quantity;
                    until TimeSheetDetail.Next() = 0;
            until TimeSheetLine.Next() = 0;
    end;

    local procedure ChangeTimeSheetChartShowBy(var TimeSheetChartSetup: Record "Time Sheet Chart Setup"; var BusChartBuf: Record System.Visualization."Business Chart Buffer"; ShowBy: Option)
    var
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
    begin
        TimeSheetChartSetup."Show by" := ShowBy;
        TimeSheetChartSetup.Modify();
        TimeSheetChartMgt.UpdateData(BusChartBuf);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineJobDetailHandler(var TimeSheetLineJobDetail: TestPage "Time Sheet Line Job Detail")
    begin
        TimeSheetLineJobDetail."Work Type Code".Value := GlobalWorkTypeCode;
        TimeSheetLineJobDetail.Chargeable.Value := Format(GlobalChargeable);
        TimeSheetLineJobDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetLineServDetailHandler(var TimeSheetLineServiceDetail: TestPage "Time Sheet Line Service Detail")
    begin
        TimeSheetLineServiceDetail."Work Type Code".Value := GlobalWorkTypeCode;
        TimeSheetLineServiceDetail.Chargeable.Value := Format(GlobalChargeable);
        TimeSheetLineServiceDetail.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetListHandler(var TimeSheetList: TestPage "Time Sheet List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        TimeSheetList.FILTER.SetFilter("No.", TimeSheetNo);
        TimeSheetList.First();
        TimeSheetList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetListHandler(var ManagerTimeSheetList: TestPage "Manager Time Sheet List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        ManagerTimeSheetList.FILTER.SetFilter("No.", TimeSheetNo);
        ManagerTimeSheetList.First();
        ManagerTimeSheetList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TimeSheetArchiveListHandler(var TimeSheetArchiveList: TestPage "Time Sheet Archive List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        TimeSheetArchiveList.FILTER.SetFilter("No.", TimeSheetNo);
        TimeSheetArchiveList.First();
        TimeSheetArchiveList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ManagerTimeSheetArchiveListHandler(var ManagerTimeSheetArcList: TestPage "Manager Time Sheet Arc. List")
    var
        TimeSheetNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(TimeSheetNo);
        ManagerTimeSheetArcList.FILTER.SetFilter("No.", TimeSheetNo);
        ManagerTimeSheetArcList.First();
        ManagerTimeSheetArcList.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 2;
    end;

    local procedure VerifyMeasureIndex2MeasureTypeTransformation(ShowBy: Option Status,Type,Posted)
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
    begin
        TimeSheetChartSetup."Show by" := ShowBy;
        case ShowBy of
            ShowBy::Status:
                begin
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Open, TimeSheetChartSetup.MeasureIndex2MeasureType(0), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Submitted, TimeSheetChartSetup.MeasureIndex2MeasureType(1), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Rejected, TimeSheetChartSetup.MeasureIndex2MeasureType(2), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Approved, TimeSheetChartSetup.MeasureIndex2MeasureType(3), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Scheduled, TimeSheetChartSetup.MeasureIndex2MeasureType(4), '');
                end;
            ShowBy::Type:
                begin
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Resource, TimeSheetChartSetup.MeasureIndex2MeasureType(0), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Job, TimeSheetChartSetup.MeasureIndex2MeasureType(1), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Service, TimeSheetChartSetup.MeasureIndex2MeasureType(2), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Absence, TimeSheetChartSetup.MeasureIndex2MeasureType(3), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::"Assembly Order", TimeSheetChartSetup.MeasureIndex2MeasureType(4), '');
                    Assert.AreEqual(TimeSheetChartSetup."Measure Type"::Scheduled, TimeSheetChartSetup.MeasureIndex2MeasureType(5), '');
                end;
        end;
    end;

    local procedure GetMeasureTypeName(TimeSheetChartSetup: Record "Time Sheet Chart Setup"; i: Integer): Text[50]
    begin
        TimeSheetChartSetup."Measure Type" := TimeSheetChartSetup.MeasureIndex2MeasureType(i);
        exit(Format(TimeSheetChartSetup."Measure Type"));
    end;

    local procedure VerifyFlowChartMeasures(ShowBy: Option Status,Type,Posted)
    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        BusChartBuf: Record System.Visualization."Business Chart Buffer";
        BusChartMapMeasure: Record System.Visualization."Business Chart Map";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
        Index: Integer;
    begin
        Index := 0;
        TimeSheetChartSetup.Get(UserId);
        TimeSheetChartSetup."Show by" := ShowBy;
        TimeSheetChartSetup.Modify();
        TimeSheetChartMgt.UpdateData(BusChartBuf);
        if BusChartBuf.FindFirstMeasure(BusChartMapMeasure) then
            repeat
                Assert.AreEqual(
                  GetMeasureTypeName(TimeSheetChartSetup, Index), BusChartMapMeasure.Name, 'Incorrect time sheet chart measure name.');
                Index := Index + 1;
            until not BusChartBuf.NextMeasure(BusChartMapMeasure);
    end;

    local procedure ModifyCopyTimeSheetLinesinServiceSetup(AutoCreateServiceLines: Boolean)
    var
        ServMgtSetup: Record "Service Mgt. Setup";
    begin
        ServMgtSetup.Get();
        ServMgtSetup.Validate("Copy Time Sheet to Order", AutoCreateServiceLines);
        ServMgtSetup.Modify();
    end;
}

