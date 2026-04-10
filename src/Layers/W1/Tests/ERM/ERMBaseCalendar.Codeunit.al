codeunit 134233 "ERM Base Calendar"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Base Calendar]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        PlannedDeliveryDateErr: Label 'Planned Delivery Date must be %1 in %2.', Comment = '%1= Value ,%2=Table Name.';

    [Test]
    procedure T001_CalcBaseCalendarLocationWithBlankCalendar()
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CompanyInformation: Record "Company Information";
        Location: Record Location;
    begin
        // [FEATURE] [Location]
        // [SCENARIO 345913] Base calendar is taken from Company Information if Location's base calendar is blank.
        // [GIVEN] CompanyInformation, where "Base Calendar Code" is 'BC'
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CompanyInformation.Get();
        CompanyInformation."Base Calendar Code" := BaseCalendar.Code;
        CompanyInformation.Modify();
        // [GIVEN] Location 'A', where "Base Calendar Code" is <blank>
        LibraryWarehouse.CreateLocation(Location);
        Location."Base Calendar Code" := '';
        Location.Modify();
        // [GIVEN] Calendar Change, where "Source Type" is Locatio, "Source Code" is 'A'
        CustomizedCalendarChange."Source Type" := CustomizedCalendarChange."Source Type"::Location;
        CustomizedCalendarChange."Source Code" := Location.Code;

        // [WHEN] run CalcCalendarCode()
        CustomizedCalendarChange.CalcCalendarCode();

        // [THEN] Calendar Change, where "Base Calendar Code" is 'BC'
        CustomizedCalendarChange.testfield("Base Calendar Code", BaseCalendar.Code);
    end;

    [Test]
    procedure T002_CalcBaseCalendarShipmentAgentNotExisting()
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CompanyInformation: Record "Company Information";
        ShippingAgent: Record "Shipping Agent";
    begin
        // [FEATURE] [Shipment Agent]
        // [SCENARIO 345913] Base calendar is taken from Company Information if Shipment Agent Services does not exist.
        // [GIVEN] CompanyInformation, where "Base Calendar Code" is 'BC'
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CompanyInformation.Get();
        CompanyInformation."Base Calendar Code" := BaseCalendar.Code;
        CompanyInformation.Modify();
        // [GIVEN] Shipping Agent 'A', ShippingAgentServices 'A'-'X' does not exist
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        // [GIVEN] Calendar Change, where "Source Type" is 'Shipping Agent', "Source Code" is 'A', "Additional Source Code" is 'X'
        CustomizedCalendarChange."Source Type" := CustomizedCalendarChange."Source Type"::"Shipping Agent";
        CustomizedCalendarChange."Source Code" := ShippingAgent.Code;
        CustomizedCalendarChange."Additional Source Code" := LibraryUtility.GenerateGUID();

        // [WHEN] run CalcCalendarCode()
        CustomizedCalendarChange.CalcCalendarCode();

        // [THEN] Calendar Change, where "Base Calendar Code" is 'BC'
        CustomizedCalendarChange.testfield("Base Calendar Code", BaseCalendar.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustomer()
    var
        Customer: Record Customer;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 271255] The customized calendar data related with the customer is deleted when the source customer is deleted
        // [GIVEN] The customer "C", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateCustomerWithCustomizedCalendar(Customer);

        // [WHEN] The customer "C" is deleted
        Customer.Delete(true);

        // [THEN] The customized calendar data related with the customer "C" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Customer, Customer."No.", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendor()
    var
        Vendor: Record Vendor;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 271255] The customized calendar data related with the vendor is deleted when the source vendor is deleted
        // [GIVEN] The vendor "V", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateVendorWithCustomizedCalendar(Vendor);

        // [WHEN] The vendor "V" is deleted
        Vendor.Delete(true);

        // [THEN] The customized calendar data related with the vendor "V" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Vendor, Vendor."No.", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLocation()
    var
        Location: Record Location;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Location]
        // [SCENARIO 271255] The customized calendar data related with the location is deleted when the source location is deleted
        // [GIVEN] The location "L", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateLocationWithCustomizedCalendar(Location);

        // [WHEN] The location "L" is deleted
        Location.Delete(true);

        // [THEN] The customized calendar data related with the location "L" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Location, Location.Code, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteShippingAgent()
    var
        ShippingAgent: Record "Shipping Agent";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Shipping Agent]
        // [SCENARIO 271255] The customized calendar data related with the shipping agent is deleted when the source shipping agent is deleted
        // [GIVEN] The shipping agent "SA", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateShippingAgentWithCustomizedCalendar(ShippingAgent);

        // [WHEN] The shipping agent "SA" is deleted
        ShippingAgent.Delete(true);

        // [THEN] The customized calendar data related with the shipping agent "SA" also are deleted
        VerifyEmptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::"Shipping Agent", ShippingAgent.Code, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameCustomer()
    var
        Customer: Record Customer;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 271255] The customized calendar data related with the customer is accordingly renamed when the source customer is renamed
        // [GIVEN] The customer "C", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateCustomerWithCustomizedCalendar(Customer);

        // [WHEN] The customer "C" is renamed
        Customer.Rename(LibraryUtility.GenerateRandomCode20(Customer.FieldNo("No."), DATABASE::Customer));

        // [THEN] The customized calendar data related with the customer "C" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Customer, Customer."No.", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameVendor()
    var
        Vendor: Record Vendor;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 271255] The customized calendar data related with the vendor is accordingly renamed when the source vendor is renamed
        // [GIVEN] The vendor "V", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateVendorWithCustomizedCalendar(Vendor);

        // [WHEN] The vendor "V" is renamed
        Vendor.Rename(LibraryUtility.GenerateRandomCode20(Vendor.FieldNo("No."), DATABASE::Vendor));

        // [THEN] The customized calendar data related with the vendor "V" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Vendor, Vendor."No.", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameLocation()
    var
        Location: Record Location;
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Location]
        // [SCENARIO 271255] The customized calendar data related with the location is accordingly renamed when the source location is renamed
        // [GIVEN] The location "L", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateLocationWithCustomizedCalendar(Location);

        // [WHEN] The location "L" is renamed
        Location.Rename(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location));

        // [THEN] The customized calendar data related with the location "L" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::Location, Location.Code, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameShippingAgent()
    var
        ShippingAgent: Record "Shipping Agent";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        BaseCalendarCode: Code[10];
    begin
        // [FEATURE] [Shipping Agent]
        // [SCENARIO 271255] The customized calendar data related with the shipping agent is accordingly renamed when the source shipping agent is renamed
        // [GIVEN] The shipping agent "SA", base calendar and related data - customized change and entry, "Where Used Base Calendar"
        BaseCalendarCode := CreateShippingAgentWithCustomizedCalendar(ShippingAgent);

        // [WHEN] The shipping agent "SA" is renamed
        ShippingAgent.Rename(LibraryUtility.GenerateRandomCode(ShippingAgent.FieldNo(Code), DATABASE::"Shipping Agent"));

        // [THEN] The customized calendar data related with the shipment agent "SA" also are renamed
        VerifyUnemptyCalendarData(BaseCalendarCode, CustomizedCalendarChange."Source Type"::"Shipping Agent", ShippingAgent.Code, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseCalendarCardUpdatesCodeOnSubformOnValidate()
    var
        BaseCalendarChange: Record "Base Calendar Change";
        BaseCalendarCard: TestPage "Base Calendar Card";
        NewDescription: text[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 292658] Base Calendar Card updates CalendarCode on subform when it's changed on the page

        // [GIVEN] Base Calendar Card is open
        BaseCalendarCard.OpenNew();

        // [GIVEN] Enter Calendar Code
        BaseCalendarCard.Code.SetValue(LibraryUtility.GenerateGUID());

        // [WHEN] Set any entry as non-working
        BaseCalendarCard.BaseCalendarEntries.Nonworking.SetValue(true);

        // [THEN] A record in Base Calendar Change with correct Calendar Code is inserted
        BaseCalendarChange.SetRange("Base Calendar Code", BaseCalendarCard.Code.Value);
        BaseCalendarChange.SetRange(Date, BaseCalendarCard.BaseCalendarEntries."Period Start".AsDate());
        Assert.RecordIsNotEmpty(BaseCalendarChange);

        // [GIVEN] Add Description as 'X' to the same row
        NewDescription := LibraryUtility.GenerateGUID();
        BaseCalendarCard.BaseCalendarEntries.Description.SetValue(NewDescription);

        // [WHEN] Move the cursor to the previous row and back   
        BaseCalendarCard.BaseCalendarEntries.Previous();
        BaseCalendarCard.BaseCalendarEntries.Next();
        // [THEN] Nonworking is 'Yes', Dewscription is 'X' in the row.
        BaseCalendarCard.BaseCalendarEntries.Nonworking.AssertEquals(Format(true));
        BaseCalendarCard.BaseCalendarEntries.Description.AssertEquals(NewDescription);
        // [THEN] the record in Base Calendar Change, where Nonworking is 'Yes', Dewscription is 'X'
        BaseCalendarChange.SetRange("Base Calendar Code", BaseCalendarCard.Code.Value);
        BaseCalendarChange.SetRange(Date, BaseCalendarCard.BaseCalendarEntries."Period Start".AsDate());
        BaseCalendarChange.FindFirst();
        BaseCalendarChange.TestField(Description, NewDescription);
        BaseCalendarChange.TestField(Nonworking, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseCalendarEntriesShowCorrespondingRecords()
    var
        BaseCalendar: Record "Base Calendar";
        FirstBaseCalendarCode: Code[10];
        SecondBaseCalendarCode: Code[10];
        BaseCalendarCard: TestPage "Base Calendar Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 373256] The "Base Calendar Entries Subform" must show corresponding records after change record in "Base Calendar Card"
        BaseCalendar.DeleteAll();

        // [GIVEN] 2 Base Calendar with Customized Calendar Change
        // [GIVEN] First Base Calendar Code = "BC1"
        FirstBaseCalendarCode := CreateBaseCalendarWithCustomizedCalendarChange();

        // [GIVEN] Second Base Calendar Code = "BC2"
        SecondBaseCalendarCode := CreateBaseCalendarWithCustomizedCalendarChange();

        // [GIVEN] Open "Base Calendar Card" on the first record
        BaseCalendarCard.OpenView();
        BaseCalendarCard.BaseCalendarEntries.Description.AssertEquals(FirstBaseCalendarCode);

        // [WHEN] Invoke Next() on the "Base Calendar Card"
        BaseCalendarCard.Next();

        // [THEN] BaseCalendarEntries shows corresponding record
        BaseCalendarCard.BaseCalendarEntries.Description.AssertEquals(SecondBaseCalendarCode);
    end;

    [Test]
    procedure UpdatePlannedDeliveryDateWithLocationBaseCalenderCode()
    var
        Location: Record Location;
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        DateFormula: DateFormula;
        Day: Option " ",Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday;
    begin
        // [SCENARIO 542852] Requested Delivery Date is not taking into consideration Weekends when no Base Calendar Code is set on the Shipping Agent Service, but is considering when setting a Requested Delivery Date calculating back to the Shipment Date.

        // [GIVEN] Create Base Calendar.
        LibraryService.CreateBaseCalendar(BaseCalendar);

        // [GIVEN] Create Nonworking Day for Saturday and Sunday in Base Calendar Change.
        CreateNonWorkingBaseCalendarChange(BaseCalendar.Code, Day::Saturday, BaseCalendarChange);
        CreateNonWorkingBaseCalendarChange(BaseCalendar.Code, Day::Sunday, BaseCalendarChange);

        // [GIVEN] Create location with Base Calendar Code and assign Base Calendar Code and Outbound Whse. Handling Time as 3 Days.
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Base Calendar Code", BaseCalendar.Code);
        Evaluate(DateFormula, '<3D>');
        Location.Validate("Outbound Whse. Handling Time", DateFormula);
        Location.Modify(true);

        // [GIVEN] Create Shipping Agent and Shipping Agent Service with ShippingTime as 10 Days.
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(DateFormula, '<10D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);

        // [GIVEN] Create Customer and assign Shipment method, Shipping Agent and Shipping Agent Service.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", Location.Code);
        Customer.Validate("Shipment Method Code", CreateShipmentMethodCode());
        Customer.Validate("Shipping Agent Code", ShippingAgent.Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Sales Header with Document Type Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Create Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Verify Planned Delivery Date with is calculated from Shipping Time.
        Assert.AreEqual(
            SalesLine.CalcPlannedDeliveryDate(SalesLine.FieldNo("Shipment Date")),
            SalesLine."Planned Delivery Date",
            StrSubstNo(
                PlannedDeliveryDateErr,
                SalesLine.CalcPlannedDate(),
                SalesLine.TableCaption()));
    end;

    local procedure CreateShipmentMethodCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure CreateNonWorkingBaseCalendarChange(BaseCalendarCode: code[10]; Day: Option; var BaseCalendarChange: Record "Base Calendar Change")
    begin
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendarCode, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D, Day);
        BaseCalendarChange.Validate(Nonworking, true);
        BaseCalendarChange.Modify(true);
    end;

    local procedure CreateCustomerWithCustomizedCalendar(var Customer: Record Customer): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Base Calendar Code", BaseCalendar.Code);
        Customer.Modify(true);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::Customer, Customer."No.", '',
          WorkDate(), false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::Customer, Customer."No.",
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateVendorWithCustomizedCalendar(var Vendor: Record Vendor): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Base Calendar Code", BaseCalendar.Code);
        Vendor.Modify(true);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::Vendor, Vendor."No.", '',
          WorkDate(), false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::Vendor, Vendor."No.",
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateLocationWithCustomizedCalendar(var Location: Record Location): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryWarehouse.CreateLocation(Location);
        LibraryService.CreateBaseCalendar(BaseCalendar);
        Location.Validate("Base Calendar Code", BaseCalendar.Code);
        Location.Modify(true);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::Location, Location.Code, '',
          WorkDate(), false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::Location, Location.Code,
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateShippingAgentWithCustomizedCalendar(var ShippingAgent: Record "Shipping Agent"): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        ShippingAgentServices: Record "Shipping Agent Services";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        CalendarManagement: Codeunit "Calendar Management";
        DateFormula: DateFormula;
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(DateFormula, '<1D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, DateFormula);
        CreateCustomizedCalendarChange(
          CustomizedCalendarChange, BaseCalendar.Code, CustomizedCalendarChange."Source Type"::"Shipping Agent", ShippingAgent.Code, '',
          WorkDate(), false);
        CreateCustomizedCalendarEntry(
          CustomizedCalendarEntry, BaseCalendar.Code,
          CustomizedCalendarEntry."Source Type"::"Shipping Agent", ShippingAgent.Code,
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(CustomizedCalendarEntry.Description)), 1, MaxStrLen(CustomizedCalendarEntry.Description)), false);
        ShippingAgentServices.Validate("Base Calendar Code", BaseCalendar.Code);
        ShippingAgentServices.Modify(true);
        CalendarManagement.CreateWhereUsedEntries(BaseCalendar.Code);
        exit(BaseCalendar.Code);
    end;

    local procedure CreateCustomizedCalendarChange(var CustomizedCalendarChange: Record "Customized Calendar Change"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; AdditionalSourceCode: Code[10]; NewDate: Date; IsNonworking: Boolean)
    begin
        Clear(CustomizedCalendarChange);
        CustomizedCalendarChange.Validate("Source Type", SourceType);
        CustomizedCalendarChange.Validate("Source Code", SourceCode);
        CustomizedCalendarChange.Validate("Additional Source Code", AdditionalSourceCode);
        CustomizedCalendarChange.Validate("Base Calendar Code", BaseCalendarCode);
        CustomizedCalendarChange.Validate(Date, NewDate);
        CustomizedCalendarChange.Validate(Nonworking, IsNonworking);
        CustomizedCalendarChange.Insert(true);
    end;

    local procedure CreateCustomizedCalendarEntry(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; NewDescription: Text[30]; IsNonworking: Boolean)
    begin
        Clear(CustomizedCalendarEntry);
        CustomizedCalendarEntry.Validate("Source Type", SourceType);
        CustomizedCalendarEntry.Validate("Source Code", SourceCode);
        CustomizedCalendarEntry.Validate("Additional Source Code", '');
        CustomizedCalendarEntry.Validate("Base Calendar Code", BaseCalendarCode);
        CustomizedCalendarEntry.Validate(Date, WorkDate());
        CustomizedCalendarEntry.Validate(Description, NewDescription);
        CustomizedCalendarEntry.Validate(Nonworking, IsNonworking);
        CustomizedCalendarEntry.Insert(true);
    end;

    local procedure FilterCustomizedCalendarChange(var CustomizedCalendarChange: Record "Customized Calendar Change"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; AdditionalSourceCode: Code[20]; DatePar: Date)
    begin
        CustomizedCalendarChange.SetRange("Source Type", SourceType);
        CustomizedCalendarChange.SetRange("Source Code", SourceCode);
        CustomizedCalendarChange.SetRange("Additional Source Code", AdditionalSourceCode);
        CustomizedCalendarChange.SetRange("Base Calendar Code", BaseCalendarCode);
        CustomizedCalendarChange.SetRange(Date, DatePar);
    end;

    local procedure FilterCustomizedCalendarEntry(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20]; AdditionalSourceCode: Code[20]; DatePar: Date)
    begin
        CustomizedCalendarEntry.SetRange("Source Type", SourceType);
        CustomizedCalendarEntry.SetRange("Source Code", SourceCode);
        CustomizedCalendarEntry.SetRange("Additional Source Code", AdditionalSourceCode);
        CustomizedCalendarEntry.SetRange("Base Calendar Code", BaseCalendarCode);
        CustomizedCalendarEntry.SetRange(Date, DatePar);
    end;

    local procedure FilterWhereUsedBaseCalendar(var WhereUsedBaseCalendar: Record "Where Used Base Calendar"; BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceCode: Code[20])
    begin
        WhereUsedBaseCalendar.SetRange("Source Type", SourceType);
        WhereUsedBaseCalendar.SetRange("Source Code", SourceCode);
        WhereUsedBaseCalendar.SetRange("Base Calendar Code", BaseCalendarCode);
    end;

    local procedure CreateBaseCalendarWithCustomizedCalendarChange(): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CreateCustomizedCalendarChange(CustomizedCalendarChange, BaseCalendar.Code,
            "Calendar Source Type"::Company, '', '', WorkDate(), false);
        CustomizedCalendarChange.Validate(Description, BaseCalendar.Code);
        CustomizedCalendarChange.Modify(true);
        exit(BaseCalendar.Code);
    end;

    local procedure VerifyEmptyCalendarData(BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceNo: Code[20]; Date: Date)
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        FilterCustomizedCalendarChange(CustomizedCalendarChange, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsEmpty(CustomizedCalendarChange);
        FilterCustomizedCalendarEntry(CustomizedCalendarEntry, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsEmpty(CustomizedCalendarEntry);
        FilterWhereUsedBaseCalendar(WhereUsedBaseCalendar, BaseCalendarCode, SourceType, SourceNo);
        Assert.RecordIsEmpty(WhereUsedBaseCalendar);
    end;

    local procedure VerifyUnemptyCalendarData(BaseCalendarCode: Code[10]; SourceType: Enum "Calendar Source Type"; SourceNo: Code[20]; Date: Date)
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        FilterCustomizedCalendarChange(CustomizedCalendarChange, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsNotEmpty(CustomizedCalendarChange);
        FilterCustomizedCalendarEntry(CustomizedCalendarEntry, BaseCalendarCode, SourceType, SourceNo, '', Date);
        Assert.RecordIsNotEmpty(CustomizedCalendarEntry);
        FilterWhereUsedBaseCalendar(WhereUsedBaseCalendar, BaseCalendarCode, SourceType, SourceNo);
        Assert.RecordIsNotEmpty(WhereUsedBaseCalendar);
    end;
}

