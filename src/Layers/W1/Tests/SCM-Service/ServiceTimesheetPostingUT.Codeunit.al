namespace Microsoft.Service.Test;

using Microsoft.Service.Document;
using Microsoft.Projects.TimeSheet;
using Microsoft.Service.History;
using Microsoft.Projects.Resources.Resource;

codeunit 136511 "Service Timesheet Posting UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Time Sheet]
    end;

    var
        LibraryService: Codeunit "Library - Service";
        ServTimesheetMgt: Codeunit "Serv. Time Sheet Mgt.";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        Text016: Label 'Time Sheet field %1 value is incorrect.';
        Text020: Label 'There is no Time Sheet';
        Text021: Label 'Unexpected time sheet searching error.';
        Text023: Label 'Quantity cannot be';
        Text024: Label '%1 field %2 value is incorrect.';
        Text027: Label 'Service Line field %1 value is incorrect.';

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderShipConsume()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify time sheet total quantity after ship and consume service order with timesheet resource.

        Initialize();
        LibraryService.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify();

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        LibraryService.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          SavedServiceLine."Qty. to Consume", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderShip()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify time sheet total quantity after ship service order with timesheet resource.

        Initialize();
        LibraryService.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        LibraryService.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          SavedServiceLine."Qty. to Ship", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestWithoutTimeSheet_ServiceOrderShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Resource: Record Resource;
        UserSetup: Record System.Security.User."User Setup";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify an error when trying to ship service order with time sheet resource.

        Initialize();

        // create user setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, false);

        // resource - person
        LibraryTimeSheet.CreateTimeSheetResource(Resource);
        Resource.Validate("Time Sheet Owner User ID", UserSetup."User ID");
        Resource.Validate("Time Sheet Approver User ID", UserId);
        Resource.Modify();

        LibraryService.CreateServiceOrder(ServiceHeader, WorkDate());

        // create service line
        CreateServiceLine(ServiceLine, ServiceHeader, Resource."No.", LibraryTimeSheet.GetRandomDecimal());

        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Assert.IsTrue(StrPos(GetLastErrorText, Text020) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyLinesFromTimeSheet_PostServiceOrderShip()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Create time sheet resource and service order, copy service lines from time sheet into service order, ship service order, verify TS lines

        Initialize();
        // create time sheet with lines and linked to resource empty service order
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        // copy service lines from time sheet into service order
        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        // create service line
        CreateServiceLine(ServiceLine, ServiceHeader, TimeSheetHeader."Resource No.", LibraryTimeSheet.GetRandomDecimal());

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        LibraryService.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          SavedServiceLine."Qty. to Ship", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostServiceOrderShip_CopyLinesFromTimeSheet()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        ServiceLineQuantity: Decimal;
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Ship service order with time sheet resource, create time sheet line and copy service lines from TS, verify Quantities in service lines.

        Initialize();
        // create service order with line and linked to resource empty time sheet
        LibraryService.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        ServiceLineQuantity := ServiceLine."Qty. to Ship";
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceLineNo := ServiceLine."Line No.";

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        LibraryTimeSheet.CreateTimeSheetLine(TimeSheetHeader, TimeSheetLine, TimeSheetLine.Type::Service, '', '', ServiceHeader."No.", '');
        TimeSheetLine.Validate("Service Order No.", ServiceHeader."No.");
        LibraryTimeSheet.CreateTimeSheetDetail(TimeSheetLine, TimeSheetHeader."Starting Date", LibraryTimeSheet.GetRandomDecimal());
        // submit and approve lines
        TimeSheetApprovalMgt.Submit(TimeSheetLine);
        TimeSheetApprovalMgt.Approve(TimeSheetLine);

        // copy service lines from time sheet into service order
        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeaderNo);
        Assert.AreEqual(2, ServiceLine.Count,
          StrSubstNo(Text016, 'COUNT of rows'));

        ServiceLine.SetRange("Line No.", ServiceLineNo);
        ServiceLine.FindFirst();
        Assert.AreEqual(ServiceLineQuantity, ServiceLine.Quantity,
          StrSubstNo(Text016, ServiceLine.FieldCaption(Quantity)));

        ServiceLine.Reset();
        ServiceLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        ServiceLine.FindFirst();
        Assert.AreEqual(TimeSheetLine."Total Quantity", ServiceLine.Quantity,
          StrSubstNo(Text016, ServiceLine.FieldCaption(Quantity)));
    end;

    [Test]
    [HandlerFunctions('HndlConfirm')]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderUndoShipment()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        SavedServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Check Quantity in time sheet line after undo shipment of service order with time sheet resource.

        Initialize();
        LibraryService.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        SavedServiceLine.Copy(ServiceLine);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceShipmentLine.SetRange("Order No.", SavedServiceLine."Document No.");
        ServiceShipmentLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);

        LibraryService.CheckServiceTimeSheetLine(TimeSheetHeader, SavedServiceLine."Document No.", SavedServiceLine."Line No.",
          -SavedServiceLine."Qty. to Ship", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderPartialShipInvoice()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineQuantity: Decimal;
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
        Iteration: Integer;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Check Quantity in timesheet line after partially shipping & invoicing service order with time sheet resource in two steps.

        Initialize();
        LibraryService.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);

        // get values from service order
        ServiceLineQuantity := ServiceLine."Qty. to Ship";
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceLineNo := ServiceLine."Line No.";

        for Iteration := 1 to 2 do begin
            ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
            ServiceLine.SetRange("Document No.", ServiceHeaderNo);
            if ServiceLine.FindSet() then
                repeat
                    ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity / 2);
                    ServiceLine.Modify();
                until ServiceLine.Next() = 0;
            ServiceHeader.Find();
            LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
            LibraryService.CheckServiceTimeSheetLine(TimeSheetHeader, ServiceHeaderNo, ServiceLineNo, ServiceLineQuantity / 2, true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTimeSheet_ServiceOrderPartialShipConsume()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineQuantity: Decimal;
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
        Iteration: Integer;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Check Quantity in timesheet line after partially shipping & consuming service order with time sheet resource in two steps.

        Initialize();
        LibraryService.InitBackwayScenario(TimeSheetHeader, ServiceHeader, ServiceLine);
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify();

        // get values from service order
        ServiceLineQuantity := ServiceLine."Qty. to Consume";
        ServiceHeaderNo := ServiceHeader."No.";
        ServiceLineNo := ServiceLine."Line No.";

        for Iteration := 1 to 2 do begin
            ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
            ServiceLine.SetRange("Document No.", ServiceHeaderNo);
            if ServiceLine.FindSet() then
                repeat
                    ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity / 2);
                    ServiceLine.Validate("Qty. to Invoice", 0);
                    ServiceLine.Modify();
                until ServiceLine.Next() = 0;
            ServiceHeader.Find();
            LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
            LibraryService.CheckServiceTimeSheetLine(TimeSheetHeader, ServiceHeaderNo, ServiceLineNo, ServiceLineQuantity / 2, false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrder_PostingQtyMoreThanTimeSheetLine_Ship()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify that service order with service line having Quantity greater than timesheet line cannot be shipped.

        Initialize();
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate(Quantity, TimeSheetLine."Total Quantity" + LibraryTimeSheet.GetRandomDecimal());
        ServiceLine.Modify();

        ServiceHeader.Find();
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.IsTrue(StrPos(GetLastErrorText, Text023) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrder_PostingQtyMoreThanTimeSheetLine_ShipConsume()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify that service order with service line having Quantity greater than timesheet line cannot be shipped and consumed.

        Initialize();
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);

        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Validate(Quantity, TimeSheetLine."Total Quantity" + LibraryTimeSheet.GetRandomDecimal());
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify();

        ServiceHeader.Find();
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        Assert.IsTrue(StrPos(GetLastErrorText, Text023) > 0, Text021);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceOrder_PartialPosting_Ship()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceHeaderNo: Code[20];
        ServiceLineNo: Integer;
        Delta: Decimal;
    begin
        // [FEATURE] [Order] [Service]
        // [SCENARIO] Verify time sheet posting entry and Remaining Quantity in service line after partially shipping service order with time sheet resource.

        Initialize();
        LibraryService.InitServiceScenario(TimeSheetHeader, TimeSheetLine, ServiceHeader);
        ServiceHeaderNo := ServiceHeader."No.";
        TimeSheetLine.CalcFields("Total Quantity");
        Delta := TimeSheetLine."Total Quantity" * (LibraryTimeSheet.GetRandomDecimal() / 100);

        ServTimeSheetMgt.CreateServDocLinesFromTS(ServiceHeader);

        CheckServicelLineRemainingQuantity(ServiceLine, ServiceHeaderNo, TimeSheetLine, TimeSheetLine."Total Quantity", false);
        ServiceLineNo := ServiceLine."Line No.";

        ServiceLine.Validate("Qty. to Ship", Delta);
        ServiceLine.Modify();
        ServiceHeader.Find();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ServiceShipmentLine.SetRange("Order No.", ServiceHeaderNo);
        ServiceShipmentLine.SetRange("Order Line No.", ServiceLineNo);
        ServiceShipmentLine.SetRange("No.", TimeSheetHeader."Resource No.");
        ServiceShipmentLine.FindFirst();
        CheckTimeSheetPostingEntry(TimeSheetLine, ServiceShipmentLine."Document No.", Delta);

        CheckServicelLineRemainingQuantity(ServiceLine, ServiceHeaderNo, TimeSheetLine, TimeSheetLine."Total Quantity" - Delta, false);
    end;

    local procedure Initialize()
    var
        UserSetup: Record System.Security.User."User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Timesheet Posting UT");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Timesheet Posting UT");

        LibraryTimeSheet.Initialize();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateLocalData();

        // create current user id setup
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Timesheet Posting UT");
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ResourceNo: Code[20]; Qty: Decimal)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate("Service Item Line No.", 10000);
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Modify();
    end;

    local procedure CheckTimeSheetPostingEntry(TimeSheetLine: Record "Time Sheet Line"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        TimeSheetPostingEntry: Record "Time Sheet Posting Entry";
    begin
        TimeSheetPostingEntry.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        TimeSheetPostingEntry.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        TimeSheetPostingEntry.SetRange("Document No.", DocumentNo);
        TimeSheetPostingEntry.FindLast();
        Assert.AreEqual(
          Quantity, TimeSheetPostingEntry.Quantity,
          StrSubstNo(Text024, TimeSheetPostingEntry.TableCaption(), TimeSheetPostingEntry.FieldCaption(Quantity)));
    end;

    local procedure CheckServicelLineRemainingQuantity(var ServiceLine: Record "Service Line"; ServiceHeaderNo: Code[20]; TimeSheetLine: Record "Time Sheet Line"; TimeSheetLineRemainingQuantity: Decimal; Consume: Boolean)
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeaderNo);
        ServiceLine.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        ServiceLine.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        ServiceLine.FindFirst();
        if not Consume then
            Assert.AreEqual(
              TimeSheetLineRemainingQuantity, ServiceLine."Qty. to Ship", StrSubstNo(Text027, ServiceLine.FieldCaption("Qty. to Ship")))
        else
            Assert.AreEqual(
              TimeSheetLineRemainingQuantity, ServiceLine."Qty. to Consume", StrSubstNo(Text027, ServiceLine.FieldCaption("Qty. to Consume")));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HndlConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

