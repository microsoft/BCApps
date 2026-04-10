// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 136151 "Service Quote Archive"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Quote] [Archive] [Service]
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
        Assert: Codeunit Assert;
        ArchiveConfirmMsg: Label 'Archive Quote no.: %1?', Comment = '%1= No.';
        ServiceHeaderArchiveMsg: Label 'Document %1 has been archived.', Comment = '%1 =Document No.';
        MissingServiceDocumentErr: Label 'Unposted %1 %2 does not exist anymore.\It is not possible to restore the %1.', Comment = '%1= Document Type %2= No.';
        ReleaseStatusErr: Label 'Release Status must be equal to ''Open''  in Service Header: Document Type=%1, No.=%2. Current value is ''%3''.', Comment = '%1= Document Type %2= No. %3= Status';
        RestoreDocumentConfirmationQst: Label 'Do you want to restore %1 %2 Version %3?', Comment = '%1 = Document Type %2 = No. %3 = Version No.';
        ServiceDocumentRestoredMsg: Label '%1 %2 has been restored.', Comment = '%1 = Document Type %2 = No.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure CreateServiceQuoteAndManualArchive()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [SCENARIO] 366089 Test creation of Service Quote and check Manual archival of document.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header, Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        // [WHEN] Manually archive Service Quote from page.
        ServiceQuote.OpenEdit();
        ServiceQuote.GoToRecord(ServiceHeader);
        ServiceQuote."Archive Document".Invoke();

        // [THEN] Check that the Service Quote is archived.
        CheckIfTableIsArchived(ServiceHeader, true);

        // [THEN] Check that the Service Quote is archived.
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeServiceOrderFromQuoteAndAutoArchive()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Test creation of Service Order from Service Quote and check document is archived.

        // [GIVEN] Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header, Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Set Always Archive
        SetArchiveOption('Always');

        // [WHEN] Convert Service Quote to Service Order.
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Verify that the Service Quote is archived.
        CheckIfTableIsArchived(ServiceHeader, true);

        //[THEN] Verify that Service Item Line is archived
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MakeServiceOrderFromQuoteAndAutoArchiveWithQuestionOption()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Test creation of Service Order from Service Quote and check document is archived.

        // [GIVEN] Setup: Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header, Service Item Line and Service Line with random Quantity.
        Initialize();
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        // [GIVEN] Set Always Archive
        SetArchiveOption('Question');

        // [WHEN] Convert Service Quote to Service Order.
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Verify that the Service Quote is archived.
        CheckIfTableIsArchived(ServiceHeader, true);

        //[THEN] Verify that Service Item Line is archived
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyServiceQuoteIsArchivedOnDeleteWithAlwaysArchive()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Verify that Service Quote can be archived on delete with Always Archive
        Initialize();

        // [GIVEN] Set Always Archive
        SetArchiveOption('Always');

        //[GIVEN] Create Service Quote
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        //[WHEN] Delete Service Header
        ServiceHeader.Delete(true);

        //[THEN] Verify Service Quote is archived
        CheckIfTableIsArchived(ServiceHeader, true);

        //[THEN] Verify that Service Item Line is archived
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyServiceQuoteIsArchivedOnDeleteWithArchiveQuestionOption()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Verify that a Service Quote can be archived on delete with Archive with Question option
        Initialize();

        // [GIVEN] Set Archive with Question
        SetArchiveOption('Question');

        //[GIVEN] Create Service Quote with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[WHEN] Delete Service Header
        ServiceHeader.Delete(true);

        //[THEN] Verify Service Quote is archived
        CheckIfTableIsArchived(ServiceHeader, true);

        //[THEN] Verify that Service Item Line is archived
        CheckIfTableIsArchived(ServiceItemLine, true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure VerifyServiceQuoteIsNotArchivedOnDeleteWithNeverArchive()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] 366089 Verify that a Service Quote is not archived on delete with Never Archive
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        //[GIVEN] Create Service Quote with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Delete Service Quote
        ServiceHeader.Delete(true);

        //[THEN] Verify Service Quote is not archived
        CheckIfTableIsArchived(ServiceHeader, false);

        //[THEN] Verify that Service Item Line is not archived
        CheckIfTableIsArchived(ServiceItemLine, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreServiceQuoteIsNotPossibleIfServiceQuoteNotExist()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [SCENARIO] 366089 Verify restore Service Quote is not possible if Service Quote does not exist
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        //[GIVEN] Create Service Quote with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[GIVEN] Archive Service Quote
        ServiceQuote.OpenEdit();
        ServiceQuote.GoToRecord(ServiceHeader);
        ServiceQuote."Archive Document".Invoke();

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [GIVEN] Delete Service Quote
        ServiceHeader.Delete(true);

        // [WHEN]  Restore Service Quote
        asserterror ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(MissingServiceDocumentErr, ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No."));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreServiceQuoteIsNotPossibleIfServiceQuoteStatusIsReleased()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [SCENARIO] 366089 Verify restore Service Quote is not possible if Service Quote status is released
        Initialize();

        // [GIVEN] Set Never Archive
        SetArchiveOption('Never');

        //[GIVEN] Create Service Quote with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[GIVEN] Archive Service Quote
        ServiceQuote.OpenEdit();
        ServiceQuote.GoToRecord(ServiceHeader);
        ServiceQuote."Archive Document".Invoke();

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [GIVEN] Release status is modified
        ServiceHeader."Release Status" := ServiceHeader."Release Status"::"Released to Ship";
        ServiceHeader.Modify(true);

        // [WHEN]  Restore Service Quote
        asserterror ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify results
        Assert.ExpectedError(StrSubstNo(ReleaseStatusErr, ServiceHeader."Document Type", ServiceHeader."No.", ServiceHeader."Release Status"));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure VerifyRestoreServiceQuote()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeaderArchive: Record "Service Header Archive";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [SCENARIO] 366089 Verify restore Service Quote 
        Initialize();

        //[GIVEN] Create Service Quote with random item and customer no.
        CreateServiceItemWithComponent(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, 0);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        //[GIVEN] Archive Service Quote
        ServiceQuote.OpenEdit();
        ServiceQuote.GoToRecord(ServiceHeader);
        ServiceQuote."Archive Document".Invoke();

        // [GIVEN] Find Service Header Archive
        FindServiceHeaderArchive(ServiceHeaderArchive, ServiceHeader, 1);

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(RestoreDocumentConfirmationQst, ServiceHeaderArchive."Document Type", ServiceHeaderArchive."No.", ServiceHeaderArchive."Version No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceDocumentRestoredMsg, ServiceHeader."Document Type", ServiceHeader."No."));

        // [WHEN]  Restore Service Quote
        ServiceDocumentArchiveMgmt.RestoreServiceDocument(ServiceHeaderArchive);

        // [THEN] Verify results
        FindServiceDocumentTables(ServiceHeader, ServiceItemLine, ServiceCommentLine);

        // [THEN] Verify results
        Assert.RecordCount(ServiceHeader, 1);
        Assert.RecordCount(ServiceItemLine, 1);
        Assert.RecordCount(ServiceCommentLine, 2);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteReportPageHandler')]
    procedure AutoArchiveServiceQuoteOnReportWithAlwaysOption()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] 366089 Auto Arhive Service Quote while generating Service Quote report.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header, Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // [GIVEN] Set Archive option
        SetArchiveOption('Always');

        // [WHEN] Exercise: Save Service Quote Report as XML and XLSX in local Temp folder.
        RunServiceQuoteReport(ServiceHeader."No.");

        // [THEN] Service Document is archived.
        CheckIfTableIsArchived(ServiceHeader, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServiceQuoteReportPageHandler')]
    procedure AutoArchiveServiceQuoteOnReportWithQuestionOption()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] 366089 Auto Arhive Service Quote while generating Service Quote report with archive option question in setup

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Quote for the Service Item - Service Header, Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // [GIVEN] Set Archive option
        SetArchiveOption('Question');

        // [GIVEN] Enqueue data
        LibraryVariableStorage.Enqueue(StrSubstNo(ArchiveConfirmMsg, ServiceHeader."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(ServiceHeaderArchiveMsg, ServiceHeader."No."));

        // [WHEN] Exercise: Save Service Quote Report as XML and XLSX in local Temp folder.
        RunServiceQuoteReport(ServiceHeader."No.");

        // [THEN] Service Document is archived.
        CheckIfTableIsArchived(ServiceHeader, true);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderNotArchiveReportPageHandler')]
    procedure ServiceQuoteNotArchivedOnReportDownloadWithNeverArchiveOption()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] 366089 Do not Auto Arhive Service Quote while generating Service Quote report.

        // [GIVEN] Create a new Service Item with a random Customer. Create a Service Order for the Service Item - Service Header, Service Item Line and Service Line with Random Quantity.
        Initialize();
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Quote);

        // [GIVEN] Set Archive option
        SetArchiveOption('Never');

        // [WHEN] Exercise: Save Service Order Report as XML and XLSX in local Temp folder.
        RunServiceQuoteReport(ServiceHeader."No.");

        // [THEN] Service Document is archived.
        CheckIfTableIsArchived(ServiceHeader, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Quote Archive");
        ClearTables();
        ClearArchiveTables();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Service Quote Archive");

        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.SetStockoutWarning(false);
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        isInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Service Quote Archive");
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

    local procedure SetArchiveOption(ArchiveOption: Text[10])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        case ArchiveOption of
            'Always':
                ServiceMgtSetup."Archive Quotes" := ServiceMgtSetup."Archive Quotes"::Always;
            'Question':
                ServiceMgtSetup."Archive Quotes" := ServiceMgtSetup."Archive Quotes"::Question;
            'Never':
                ServiceMgtSetup."Archive Quotes" := ServiceMgtSetup."Archive Quotes"::Never;
        end;
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

    local procedure RunServiceQuoteReport(No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceQuote: Report "Service Quote";
    begin
        Commit();
        Clear(ServiceQuote);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Quote);
        ServiceHeader.SetRange("No.", No);
        ServiceQuote.SetTableView(ServiceHeader);
        ServiceQuote.Run();
    end;

    local procedure FindServiceDocumentTables(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceCommentLine: Record "Service Comment Line")
    begin
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        ServiceCommentLine.SetRange("No.", ServiceHeader."No.");
        ServiceCommentLine.FindSet();
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
    procedure ServiceQuoteReportPageHandler(var SalesQuoteReport: TestRequestPage "Service Quote")
    begin
        SalesQuoteReport.ArchiveDocument.SetValue(true);
        SalesQuoteReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure ServiceOrderNotArchiveReportPageHandler(var SalesQuoteReport: TestRequestPage "Service Quote")
    begin
        SalesQuoteReport.ArchiveDocument.SetValue(false);
        SalesQuoteReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}