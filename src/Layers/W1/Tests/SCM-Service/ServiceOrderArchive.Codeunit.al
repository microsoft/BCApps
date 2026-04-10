// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 136152 "Service Order Archive"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Archive] [Service]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        ArchiveConfirmMsg: Label 'Archive Order no.: %1?', Comment = '%1= No.';
        ServiceHeaderArchiveMsg: Label 'Document %1 has been archived.', Comment = '%1 =Document No.';
        MissingServiceDocumentErr: Label 'Unposted %1 %2 does not exist anymore.\It is not possible to restore the %1.', Comment = '%1= Document Type %2= No.';
        ReleaseStatusErr: Label 'Release Status must be equal to ''Open''  in Service Header: Document Type=%1, No.=%2. Current value is ''%3''.', Comment = '%1= Document Type %2= No. %3= Status';
        RestoreDocumentConfirmationQst: Label 'Do you want to restore %1 %2 Version %3?', Comment = '%1 = Document Type %2 = No. %3 = Version No.';
        ServiceDocumentRestoredMsg: Label '%1 %2 has been restored.', Comment = '%1 = Document Type %2 = No.';
        ServiceDocumentRestoreNotPossibleErr: Label '%1 %2 has been partly posted.\Restore not possible.', Comment = '%1 = Document Type %2 = No.';
        ServieItemLineArchiveIsEmptyErr: Label 'Table "Servie Item Line Archive" is Empty. Document is not archived.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CreateServiceOrderAndManualArchive()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrder: TestPage "Service Order";
    begin

        // [SCENARIO] 366089 Test creation of Service Order and check Manual archival of document.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        // [WHEN] Manually archive Service Order from page.
        ServiceOrder.OpenEdit();
        ServiceOrder.GoToRecord(ServiceHeader);
        ServiceOrder."Archive Document".Invoke();

        // [THEN] Check that the Service Order is archived.
        CheckIfTableIsArchived(ServiceHeader, true);

        // [THEN] Check that the Service Order is archived.
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderAutoArchiveOnPostDocument()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLineArchive: Record "Service Item Line Archive";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceLine: Record "Service Line";
        Resource: Record Resource;
        ServiceItemLineNo: Integer;
    begin
        // [SCENARIO] 366089 Test creation of Service Order and check document is auto archived while posting.

        // [GIVEN] Setup: Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceItemWithComponent(ServiceItem);

        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);
        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, 0);

        // [GIVEN] Set Archive
        SetArchiveOption(true);

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify that the Service Order is archived.
        CheckIfTableIsArchived(ServiceHeader, true);

        // [THEN] Verify Service Item Line is archived
        ServiceItemLineArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLineArchive.SetRange("Document No.", ServiceHeader."No.");
        if ServiceItemLineArchive.IsEmpty then
            Error(ServieItemLineArchiveIsEmptyErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyServiceOrderIsArchivedOnDeleteWithArchiveTrueOption()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Verify that Service Order can be archived on delete with Archive option true
        Initialize();

        // [GIVEN] Set Always Archive
        SetArchiveOption(true);

        //[GIVEN] Create Service Order
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        //[WHEN] Delete Service Header
        ServiceHeader.Delete(true);

        //[THEN] Verify Service Order is archived
        CheckIfTableIsArchived(ServiceHeader, true);

        //[THEN] Verify that Service Item Line is archived
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyServiceOrderIsNotArchivedOnDeleteWithArchiveOptionFalse()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Verify that a Service Order is not archived on delete with Archive option false
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption(false);

        //[GIVEN] Create Service Order with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Delete Service Order
        ServiceHeader.Delete(true);

        //[THEN] Verify Service Order is not archived
        CheckIfTableIsArchived(ServiceHeader, false);

        //[THEN] Verify that Service Item Line is not archived
        CheckIfTableIsArchived(ServiceItemLine, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRestoreIsNotPossibleIfServiceOrderIsPartiallyPosted()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceLine: Record "Service Line";
        Resource: Record Resource;
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceItemLineNo: Integer;
    begin
        // [SCENARIO] 366089 Verify restore of Service Order is not possible if Service Order is partially posted.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceItemWithComponent(ServiceItem);

        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);
        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, 0);

        // [GIVEN] Set Archive
        SetArchiveOption(true);

        // [GIVEN] Update Qty on Service Line
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity - 1);
        ServiceLine.Modify();

        // [GIVEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [WHEN] Restore Service Document
        asserterror ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify .
        Assert.ExpectedError(StrSubstNo(ServiceDocumentRestoreNotPossibleErr, ServiceHeader."Document Type", ServiceHeader."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreServiceOrderIsNotPossibleIfServiceOrderNotExist()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO] 366089 Verify restore Service Order is not possible if Service Order does not exist
        Initialize();

        // [GIVEN] Set Archive false
        SetArchiveOption(false);

        //[GIVEN] Create Service Order with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[GIVEN] Archive Service Order
        ServiceOrder.OpenEdit();
        ServiceOrder.GoToRecord(ServiceHeader);
        ServiceOrder."Archive Document".Invoke();

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [GIVEN] Delete Service Order
        ServiceHeader.Delete(true);

        // [WHEN]  Restore Service Order
        asserterror ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(MissingServiceDocumentErr, ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreServiceOrderIsNotPossibleIfServiceOrderStatusIsReleased()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO] 366089 Verify restore Service Order is not possible if Service Order status is released
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption(true);

        //[GIVEN] Create Service Order with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[GIVEN] Archive Service Order
        ServiceOrder.OpenEdit();
        ServiceOrder.GoToRecord(ServiceHeader);
        ServiceOrder."Archive Document".Invoke();

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [GIVEN] Release status is modified
        ServiceHeader."Release Status" := ServiceHeader."Release Status"::"Released to Ship";
        ServiceHeader.Modify(true);

        // [WHEN]  Restore Service Order
        asserterror ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(ReleaseStatusErr, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Release Status"));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('FormHandlerResourceAllocation,ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceCommentLine: Record "Service Comment Line";
        Resource: Record Resource;
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO] 366089 Verify restore Service Order 
        Initialize();

        //[GIVEN] Create Service Order with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, 0);

        // [GIVEN] Define one "Service Order Allocation" record
        AllocateResource(Resource, ServiceItemLine);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[GIVEN] Archive Service Order
        ServiceOrder.OpenEdit();
        ServiceOrder.GoToRecord(ServiceHeader);
        ServiceOrder."Archive Document".Invoke();

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(RestoreDocumentConfirmationQst, ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No.", ServiceHeaderArchive."Version No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceDocumentRestoredMsg, ServiceHeader."Document Type", ServiceHeader."No."));

        // [WHEN]  Restore Service Order
        ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify results
        FindServiceDocumentTables(ServiceHeader, ServiceItemLine, ServiceCommentLine, ServiceOrderAllocation);

        // [THEN] Verify results
        Assert.RecordCount(ServiceHeader, 1);
        Assert.RecordCount(ServiceItemLine, 1);
        Assert.RecordCount(ServiceCommentLine, 2);
        Assert.RecordCount(ServiceOrderAllocation, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceOrderReportPageHandler')]
    procedure AutoArchiveServiceOrderOnReportWithTrueOption()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] 366089 Auto Arhive Service Order while generating Service Order report.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // [GIVEN] Set Archive option
        SetArchiveOption(true);

        // [WHEN] Save Service Order Report as XML and XLSX in local Temp folder.
        RunServiceOrderReport(ServiceHeader."No.");

        // [THEN] Service Document is archived.
        CheckIfTableIsArchived(ServiceHeader, true);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderReportPageHandler')]
    procedure ServiceOrderArchivedOnReportDownloadWithArchiveOptionFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] 366089 Auto Arhive Service Order while generating Service Order report with archive option false in setup

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // [GIVEN] Set Archive option
        SetArchiveOption(false);

        // [WHEN] Save Service Order Report as XML and XLSX in local Temp folder.
        RunServiceOrderReport(ServiceHeader."No.");

        // [THEN] Service Document is archived.
        CheckIfTableIsArchived(ServiceHeader, true);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderNotArchiveReportPageHandler')]
    procedure ServiceOrderNotArchivedOnReportDownloadWithArchiveOptionFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] 366089 Do not Auto Arhive Service Order while generating Service Order report.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order);

        // [GIVEN] Set Archive option
        SetArchiveOption(false);

        // [WHEN] Exercise: Save Service Order Report as XML and XLSX in local Temp folder.
        RunServiceOrderReport(ServiceHeader."No.");

        // [THEN] Service Document is archived.
        CheckIfTableIsArchived(ServiceHeader, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure TestServiceArchiveWorkDescription()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceOrder: TestPage "Service Order";
        WorkDescription: Text;
    begin
        // [SCENARIO] 568647 Verify Work Description is transfered to Service Header Archive table.
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption(true);

        //[GIVEN] Create Service Order with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Service Order with non-empty "Work Description"
        WorkDescription := LibraryRandom.RandText(10);
        ServiceHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, ServiceHeader.GetWorkDescription(), '');

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[WHEN] Archive Service Order
        ServiceOrder.OpenEdit();
        ServiceOrder.GoToRecord(ServiceHeader);
        ServiceOrder."Archive Document".Invoke();

        // Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [THEN] Sales Archive Header has correct "Work Description"
        Assert.AreEqual(ServiceHeader.GetWorkDescription(), ServiceHeaderArchive.GetWorkDescription(), '');

        // [GIVEN] Update "Work Description" on Service Header
        WorkDescription := LibraryRandom.RandText(10);
        ServiceHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, ServiceHeader.GetWorkDescription(), '');

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(RestoreDocumentConfirmationQst, ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No.", ServiceHeaderArchive."Version No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceDocumentRestoredMsg, ServiceHeader."Document Type", ServiceHeader."No."));

        // [WHEN]  Restore Service Order
        ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Sales Header has correct "Work Description"
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        Assert.AreEqual(ServiceHeader.GetWorkDescription(), ServiceHeaderArchive.GetWorkDescription(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Order Archive");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        ClearTables();
        ClearArchiveTables();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Service Order Archive");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        UpdateCustNoSeries();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        LibraryTemplates.EnableTemplatesFeature();
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Service Order Archive");
    end;

    local procedure UpdateCustNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ClearArchiveTables();
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceItemLineArchive: Record "Service Item Line Archive";
    begin
        ServiceHeaderArchive.DeleteAll();
        ServiceItemLineArchive.DeleteAll();
    end;

    local procedure ClearTables()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceHeader.DeleteAll();
        ServiceItemLine.DeleteAll();
        ServiceCommentLine.DeleteAll();
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; Type: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, Type, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CheckIfTableIsArchived(ArchiveTable: Variant; Archived: Boolean)
    var
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceItemLineArchive: Record "Service Item Line Archive";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(ArchiveTable);
        case RecRef.Number of
            Database::"Service Header":
                if DataTypeManagement.FindFieldByName(RecRef, FldRef, 'No.') then begin
                    ServiceHeaderArchive.SetRange("No.", FldRef.Value());
                    if Archived then
                        Assert.RecordIsNotEmpty(ServiceHeaderArchive)
                    else
                        Assert.RecordIsEmpty(ServiceHeaderArchive);
                end;
            Database::"Service Item Line":
                if DataTypeManagement.FindFieldByName(RecRef, FldRef, 'Document No.') then begin
                    ServiceItemLineArchive.SetRange("Document No.", FldRef.Value());
                    if Archived then
                        Assert.RecordIsNotEmpty(ServiceItemLineArchive)
                    else
                        Assert.RecordIsEmpty(ServiceItemLineArchive);
                end;
        end;
    end;

    local procedure SetArchiveOption(ArchiveOption: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        if ArchiveOption then
            ServiceMgtSetup."Archive Orders" := true
        else
            ServiceMgtSetup."Archive Orders" := false;
        ServiceMgtSetup.Modify(true);
    end;

    local procedure CreateServiceItemWithComponent(var ServiceItem: Record "Service Item"): Code[20]
    var
        Item: Record Item;
        ServiceItemComponent: Record "Service Item Component";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItem."No.", ServiceItemComponent.Type::Item, Item."No.");
        exit(Item."No.");
    end;

    local procedure FindServiceHeaderArchive(var ServiceHeaderArchive: Record "Service Header Archive"; var ServiceHeader: Record "Service Header"; Version: Integer)
    begin
        ServiceHeaderArchive.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeaderArchive.SetRange("No.", ServiceHeader."No.");
        ServiceHeaderArchive.SetRange("Doc. No. Occurrence", ServiceHeader."Doc. No. Occurrence");
        ServiceHeaderArchive.SetRange("Version No.", Version);
        ServiceHeaderArchive.FindFirst()
    end;

    local procedure RunServiceOrderReport(No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Report "Service Order";
    begin
        Commit();
        Clear(ServiceOrder);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("No.", No);
        ServiceOrder.SetTableView(ServiceHeader);
        ServiceOrder.Run();
    end;

    local procedure FindServiceDocumentTables(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceCommentLine: Record "Service Comment Line"; var ServiceOrderAllocation: Record "Service Order Allocation")
    begin
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");

        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();

        ServiceCommentLine.SetRange("No.", ServiceHeader."No.");
        ServiceCommentLine.FindSet();

        ServiceOrderAllocation.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceOrderAllocation.SetRange("Document No.", ServiceHeader."No.");
        ServiceOrderAllocation.FindSet();
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal; UnitPrice: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        exit(ServiceItemLine."Line No.");
    end;

    local procedure UpdateServiceLineWithRandomQtyAndPrice(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        UpdateServiceLine(
          ServiceLine, ServiceItemLineNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure AllocateResource(var Resource: Record Resource; ServiceItemLine: Record "Service Item Line")
    var
        ServiceOrderSubform: Page "Service Order Subform";
    begin
        LibraryResource.FindResource(Resource);
        LibraryVariableStorage.Enqueue(Resource."No.");
        Clear(ServiceOrderSubform);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.AllocateResource();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [RequestPageHandler]
    procedure ServiceOrderReportPageHandler(var SalesOrderReport: TestRequestPage "Service Order")
    begin
        SalesOrderReport.ArchiveDocument.SetValue(true);
        SalesOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure ServiceOrderNotArchiveReportPageHandler(var SalesOrderReport: TestRequestPage "Service Order")
    begin
        SalesOrderReport.ArchiveDocument.SetValue(false);
        SalesOrderReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerResourceAllocation(var ResourceAllocations: Page "Resource Allocations")
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.Init();
        ResourceAllocations.GetRecord(ServiceOrderAllocation);
        ServiceOrderAllocation.Validate(
          "Resource No.", CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ServiceOrderAllocation."Resource No.")));
        ServiceOrderAllocation.Validate("Allocation Date", WorkDate());
        ServiceOrderAllocation.Modify(true);
    end;
}