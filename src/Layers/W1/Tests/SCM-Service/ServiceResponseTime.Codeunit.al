// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using System.Utilities;

codeunit 136106 "Service Response Time"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Response Time]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServItemLineResponseTimeErr: Label 'Wrong Service Item Line "Response Time" value';

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeFromServiceItem()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time (Hours) on Service Item Line is equal to the value of Response Time (Hours) of Service Item.

        // 1. Setup: Create Service Item - validate any value for Response Time (Hours).
        Initialize();
        CreateServiceItemWithResponseTime(ServiceItem, LibraryRandom.RandInt(100));

        // 2. Exercise: Create Service Order - Service Header and Service Item Line.
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", WorkDate());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 3. Verify: Verify that the Response Time (Hours) on Service Item Line is equal to value of Response Time (Hours) of Service Item.
        ServiceItemLine.TestField("Response Time (Hours)", ServiceItem."Response Time (Hours)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeServiceItemGroup()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time (Hours) on Service Item Line is Response Time (Hours) of Service Item Group on Service Item Line.

        // 1. Setup: Create Service Item Group - validate any value for Default Response Time (Hours) and attach it to a new Service Item.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Default Response Time (Hours)", LibraryRandom.RandInt(100));  // Required field - value is not important for test case.
        ServiceItemGroup.Modify(true);

        CreateServiceItem(ServiceItem);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Modify(true);

        // 2. Exercise: Create Service Order - Service Header and Service Item Line.
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", WorkDate());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 3. Verify: Verify that the value of the Response Time (Hours) on Service Item Line is equal to the value of Response Time
        // (Hours) of Service Item Group.
        ServiceItemLine.TestField("Response Time (Hours)", ServiceItemGroup."Default Response Time (Hours)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeInSameWorkingDay()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHour: Record "Service Hour";
        OrderDate: Date;
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is Ending Time of the relevant Service Hour minus the time subtracted, for a
        // Working Day and Response Time (Hours) as any time falling within the Service Hours on the same day.

        // 1. Setup: Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        Initialize();
        OrderDate := LibraryService.GetFirstWorkingDay(WorkDate());
        CreateServiceHeaderGivenDate(ServiceItemLine, OrderDate);

        // 2. Exercise: Get Service Hour for the relevant Date and validate Response Time (Hours) as any time falling within the Service
        // Hours on the same day.
        LibraryService.GetServiceHourForDate(ServiceHour, OrderDate);
        ServiceItemLine.Validate(
          "Response Time (Hours)", LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time") - 1);
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is Ending Time of the relevant Service Hour minus the time
        // subtracted.
        ServiceItemLine.TestField("Response Time", ServiceHour."Ending Time" - LibraryUtility.ConvertHoursToMilliSec(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeSameWorkingDayFull()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHour: Record "Service Hour";
        OrderDate: Date;
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is the Ending Time of the relevant Service Hour, for a Working Day and Response
        // Time (Hours) as full Shift Time (duration of Service Hours).

        // 1. Setup: Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        Initialize();
        OrderDate := LibraryService.GetFirstWorkingDay(WorkDate());
        CreateServiceHeaderGivenDate(ServiceItemLine, OrderDate);

        // 2. Exercise: Get Service Hour for the relevant Date and validate Response Time (Hours) on Service Item Line having boundary value
        // as full Shift Time (duration of Service Hours).
        LibraryService.GetServiceHourForDate(ServiceHour, OrderDate);
        ServiceItemLine.Validate(
          "Response Time (Hours)", LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time"));
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is the Ending Time of the relevant Service Hour.
        ServiceItemLine.TestField("Response Time", ServiceHour."Ending Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeSameWorkingDayZero()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceHour: Record "Service Hour";
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is the Order Time of the Service Header, for a Working Day and Response Time
        // (Hours) as 0.

        // 1. Setup: Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        Initialize();
        CreateServiceItem(ServiceItem);
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LibraryService.GetFirstWorkingDay(WorkDate()));
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Get Service Hour for the relevant Date and validate Response Time (Hours) on Service Item Line as boundary value 0.
        LibraryService.GetServiceHourForDate(ServiceHour, ServiceHeader."Order Date");
        ServiceItemLine.Validate("Response Time (Hours)", 0);  // The value 0 is important to the test case as boundary value.
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is the Order Time of the Service Header.
        ServiceItemLine.TestField("Response Time", ServiceHeader."Order Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeTwoSimulWorkingDay()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHour: Record "Service Hour";
        OrderDate: Date;
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is Starting Time of the relevant Service Hour for next working day
        // plus the time added, for a Working Day that is followed by another working day.

        // 1. Setup: Create Service Order for a Working Day that is followed by another working day - Service Item, Service Header,
        // Service Item Line.
        Initialize();
        OrderDate := GetTwoSimultaneousWorkingDays();
        CreateServiceHeaderGivenDate(ServiceItemLine, OrderDate);

        // 2. Exercise: Get Service Hour for the relevant Date and validate Response Time (Hours) on Service Item Line as
        // time falling outside of the Service Hours.
        LibraryService.GetServiceHourForDate(ServiceHour, OrderDate);
        ServiceItemLine.Validate(
          "Response Time (Hours)", LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time") + 1);
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is Starting Time of the relevant Service Hour for next working day
        // plus the time added.
        LibraryService.GetServiceHourForDate(ServiceHour, CalcDate('<1D>', OrderDate));
        ServiceItemLine.TestField("Response Time", ServiceHour."Starting Time" + LibraryUtility.ConvertHoursToMilliSec(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeWorkingNonWorking()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHour: Record "Service Hour";
        OrderDate: Date;
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is Starting Time of the relevant Service Hour for next working day
        // plus the time added, for a Working Day that is followed by non working day.

        // 1. Setup: Create Service Order for a Working Day that is followed by non working day - Service Item, Service Header,
        // Service Item Line.
        Initialize();
        OrderDate := GetWorkingFollowedByNonWorking();
        CreateServiceHeaderGivenDate(ServiceItemLine, OrderDate);

        // 2. Exercise: Get Service Hour for the relevant Date and validate Response Time (Hours)) on Service Item Line as time falling
        // outside of the Working Hours.
        LibraryService.GetServiceHourForDate(ServiceHour, OrderDate);
        ServiceItemLine.Validate(
          "Response Time (Hours)", LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time") + 1);
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is Starting Time of the relevant Service Hour for next working day
        // plus the time added.
        LibraryService.GetServiceHourForDate(ServiceHour, LibraryService.GetNextWorkingDay(OrderDate));
        ServiceItemLine.TestField("Response Time", ServiceHour."Starting Time" + LibraryUtility.ConvertHoursToMilliSec(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeNonWorkingWorking()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHour: Record "Service Hour";
        OrderDate: Date;
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is Ending Time of the relevant Service Hour for next working day
        // minus the time subtracted, for a non working day that is followed by a working day.

        // 1. Setup: Create Service Order for a non working day that is followed by a working day - Service Item, Service Header,
        // Service Item Line.
        Initialize();
        OrderDate := LibraryService.GetNonWrkngDayFollwdByWrkngDay();
        CreateServiceHeaderGivenDate(ServiceItemLine, OrderDate);

        // 2. Exercise: Get Service Hour for the relevant Date. Validate Response Time (Hours) on Service Item Line as
        // time falling inside the Service Hours of next working day.
        LibraryService.GetServiceHourForDate(ServiceHour, LibraryService.GetNextWorkingDay(OrderDate));
        ServiceItemLine.Validate(
          "Response Time (Hours)", LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time") - 1);
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is Starting Time of the relevant Service Hour for next working day
        // plus the time added.
        ServiceItemLine.TestField("Response Time", ServiceHour."Ending Time" - LibraryUtility.ConvertHoursToMilliSec(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponseTimeValidOnHolidays()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHour: Record "Service Hour";
        OrderDate: Date;
    begin
        // Covers document number TC0120 - refer to TFS ID 21728.
        // Test that the Response Time on Service Item Line is Ending Time of the relevant Service Hour minus the time subtracted, for a non
        // working day that has Valid on Holidays checked.

        // 1. Setup: Create Service Order for a non working day that has Valid on Holidays checked.
        Initialize();
        OrderDate := CreateNonWorkingDayWithHoliday();
        CreateServiceHeaderGivenDate(ServiceItemLine, OrderDate);

        // 2. Exercise: Get Service Hour for the relevant Date and validate Response Time (Hours) on Service Item Line as a time
        // falling within the Service Hours on the same day.
        LibraryService.GetServiceHourForDate(ServiceHour, OrderDate);
        ServiceItemLine.Validate(
          "Response Time (Hours)", LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time") - 1);
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Response Time on Service Item Line is Ending Time of the relevant Service Hour minus the
        // time subtracted.
        ServiceItemLine.TestField("Response Time", ServiceHour."Ending Time" - LibraryUtility.ConvertHoursToMilliSec(1));
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResponseTimeLessThanServiceHoursOnServiceOrder()
    var
        ServiceHour: Record "Service Hour";
        ServiceHeader: Record "Service Header";
        ServiceContractLine: Record "Service Contract Line";
        OrderDate: Date;
    begin
        // Verify Response Date and Time on a Service Order Line where Service Hours is less than Response Time (Hours) on Contract.

        // 1. Setup: Create Service Contract Header, Service Contract Line, Get Service Hour for the Working Day that is followed by another working day,
        // Validate Response Time (Hours) on Service Contract Line as time falling outside of the Service Hours and Sign Service Contract.
        Initialize();
        OrderDate := GetTwoSimultaneousWorkingDays();
        LibraryService.GetServiceHourForDate(ServiceHour, OrderDate);
        CreateAndSignServiceContract(
          ServiceContractLine, LibraryUtility.ConvertMilliSecToHours(ServiceHour."Ending Time" - ServiceHour."Starting Time") + 1);  // Value is important for test to have response time hours more than service hours.

        // 2. Exercise: Create Service Order for the relevant date - Service Item, Service Header, Service Item Line with the Contract No.
        CreateServiceHeader(ServiceHeader, ServiceContractLine."Customer No.", OrderDate);
        CreateServiceItemLineWithContractNo(ServiceHeader, ServiceContractLine);

        // 3. Verify: Verify that the Response Date is the Next Date from the Order Date and Response Time on Service Item Line is Starting Time of the relevant Service Hour for next working day plus the time added.
        VerifyServiceItemLine(
          ServiceHeader."No.", ServiceContractLine."Response Time (Hours)", CalcDate('<1D>', OrderDate), ServiceHour."Starting Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServItemLineResponseTime235959()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        Date: Date;
    begin
        // Verify Service Item Line "Response Time" in case of Service Hour 23:59:59 Ending Time
        Initialize();
        Date := CalcDate('<1M>', WorkDate());
        UpdateDefaultServiceHours(Date);

        CreateServiceItemWithResponseTime(ServiceItem, 24);
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", Date);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        Assert.AreEqual(ServiceHeader."Order Time", ServiceItemLine."Response Time", ServItemLineResponseTimeErr);

        // Tear Down
        DeleteServiceHours(Date);
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Response Time");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Response Time");

        LibraryERMCountryData.CreateVATData();
        LibraryService.SetupServiceMgtNoSeries();
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Response Time");
    end;

    local procedure CreateAndSignServiceContract(var ServiceContractLine: Record "Service Contract Line"; ResponseTimeHours: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        CreateServiceItem(ServiceItem);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ModifyServiceContractLine(ServiceContractLine, ResponseTimeHours);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item")
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
    end;

    local procedure CreateServiceItemWithResponseTime(var ServiceItem: Record "Service Item"; ResponseHours: Integer)
    begin
        CreateServiceItem(ServiceItem);
        ServiceItem.Validate("Response Time (Hours)", ResponseHours);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; OrderDate: Date)
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Order Date", OrderDate);
        ServiceHeader.Validate("Order Time", 000001T);  // Value 000001T is important for test case.
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceHeaderGivenDate(var ServiceItemLine: Record "Service Item Line"; OrderDate: Date)
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceItem(ServiceItem);
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", OrderDate);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateNonWorkingDayWithHoliday(): Date
    var
        ServiceHour: Record "Service Hour";
        Date: Record Date;
        NonWorkingDate: Date;
    begin
        NonWorkingDate := GetNonWorkingDay(WorkDate());
        if not LibraryService.GetServiceHourForDate(ServiceHour, NonWorkingDate) then begin
            Date.Get(Date."Period Type"::Date, NonWorkingDate);
            Evaluate(ServiceHour.Day, Date."Period Name");
            LibraryService.CreateDefaultServiceHour(ServiceHour, ServiceHour.Day);
            // Required field - value is not important for test case.
            ServiceHour.Validate(
              "Ending Time",
              ServiceHour."Starting Time" + LibraryUtility.ConvertHoursToMilliSec(LibraryRandom.RandIntInRange(5, 10)));
        end;
        ServiceHour.Validate("Valid on Holidays", true);
        ServiceHour.Modify(true);
        exit(NonWorkingDate);
    end;

    local procedure CreateServiceItemLineWithContractNo(ServiceHeader: Record "Service Header"; ServiceContractLine: Record "Service Contract Line")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceContractLine."Service Item No.");
        ServiceItemLine.Validate("Contract No.", ServiceContractLine."Contract No.");
        ServiceItemLine.Modify(true);
    end;

    local procedure GetNonWorkingDay(NonWorkingDate: Date): Date
    begin
        while LibraryService.IsWorking(NonWorkingDate) do
            NonWorkingDate := CalcDate('<1D>', NonWorkingDate);
        exit(NonWorkingDate);
    end;

    local procedure GetTwoSimultaneousWorkingDays(): Date
    var
        ServiceHour: Record "Service Hour";
        WorkingDate: Date;
    begin
        WorkingDate := WorkDate();
        repeat
            WorkingDate := CalcDate('<1D>', WorkingDate);
        until
              (LibraryService.IsWorking(WorkingDate) and LibraryService.GetServiceHourForDate(ServiceHour, WorkingDate)) and
              (LibraryService.IsWorking(CalcDate('<1D>', WorkingDate)) and
               LibraryService.GetServiceHourForDate(ServiceHour, CalcDate('<1D>', WorkingDate)));
        exit(WorkingDate);
    end;

    local procedure GetWorkingFollowedByNonWorking(): Date
    var
        ServiceHour: Record "Service Hour";
        WorkingDate: Date;
    begin
        WorkingDate := WorkDate();
        repeat
            WorkingDate := CalcDate('<1D>', WorkingDate);
        until
              (LibraryService.IsWorking(WorkingDate) and LibraryService.GetServiceHourForDate(ServiceHour, WorkingDate)) and
              not (LibraryService.IsWorking(CalcDate('<1D>', WorkingDate)) and
                   LibraryService.IsValidOnHolidays(CalcDate('<1D>', WorkingDate)));
        exit(WorkingDate);
    end;

    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Modify(true);
    end;

    local procedure ModifyServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ResponseTimeHours: Decimal)
    begin
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(100));  // Use Random because value is not important.
        ServiceContractLine.Validate("Response Time (Hours)", ResponseTimeHours);
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateDefaultServiceHours(StartingDate: Date)
    var
        ServiceHour: Record "Service Hour";
        DoW: Option;
    begin
        ServiceHour."Starting Date" := StartingDate;
        ServiceHour."Starting Time" := 000000T;
        ServiceHour."Ending Time" := 235959T;
        ServiceHour."Valid on Holidays" := true;
        for DoW := ServiceHour.Day::Monday to ServiceHour.Day::Sunday do begin
            ServiceHour.Day := DoW;
            ServiceHour.Insert();
        end;
    end;

    local procedure DeleteServiceHours(StartingDate: Date)
    var
        ServiceHour: Record "Service Hour";
    begin
        ServiceHour.SetRange("Starting Date", StartingDate);
        ServiceHour.DeleteAll();
    end;

    local procedure VerifyServiceItemLine(DocumentNo: Code[20]; ResponseTimeHours: Decimal; OrderDate: Date; StartingTime: Time)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", DocumentNo);
        ServiceItemLine.FindFirst();
        ServiceItemLine.TestField("Response Time (Hours)", ResponseTimeHours);
        ServiceItemLine.TestField("Response Date", OrderDate);
        ServiceItemLine.TestField("Response Time", StartingTime + LibraryUtility.ConvertHoursToMilliSec(1));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    begin
        Result := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

