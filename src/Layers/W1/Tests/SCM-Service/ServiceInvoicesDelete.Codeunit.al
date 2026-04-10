// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using System.TestLibraries.Utilities;

codeunit 136147 "Service Invoices Delete"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service Contract] [Service Invoice] [Service]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        CurrentWorkDate: Date;
        IsInitialized: Boolean;
        CannotDeleteWhenNextInvPostedErr: Label 'The service invoice cannot be deleted because there are posted service ledger entries with a later posting date.';
        CannotDeleteWhenNextInvExistsErr: Label 'The service invoice cannot be deleted because there are service invoices with a later posting date.';
        CannotRestoreInvoiceDatesErr: Label 'The service invoice cannot be deleted because the previous invoice dates cannot be restored in the service contract.';
        InvoicePeriodChangedErr: Label 'The invoice period in the service contract has been changed and cannot be updated.';

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure CannotDeleteInvoiceIfLaterInvoiceExists()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Cannot delete a service invoice if a later invoice exists.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        WorkDate(CalcDate('<1M>', WorkDate()));
        CreateServiceInvoice(ServiceContractHeader);

        // [WHEN] Delete service invoice.
        asserterror DeleteServiceInvoice(ServiceHeader);

        Assert.ExpectedError(CannotDeleteWhenNextInvExistsErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure CannotDeleteInvoiceIfLaterInvoicePosted()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        LaterServiceHeader: Record "Service Header";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // [SCENARIO] Cannot delete a service invoice if a later invoice is posted.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        // Mock close service ledger entry.
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::" ");
        ServiceLedgerEntry.SetRange("Document No.", ServiceHeader."No.");
        ServiceLedgerEntry.ModifyAll(Open, false);

        WorkDate(CalcDate('<1M>', WorkDate()));
        LaterServiceHeader.Get(LaterServiceHeader."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));
        LibraryService.PostServiceOrder(LaterServiceHeader, true, false, true);

        // Mock reopen service ledger entry.
        ServiceLedgerEntry.ModifyAll(Open, true);

        // [WHEN] Delete service invoice.
        asserterror DeleteServiceInvoice(ServiceHeader);

        Assert.ExpectedError(CannotDeleteWhenNextInvPostedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure CannotDeleteInvoiceIfDatesNotStoredInServiceRegister()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceDocumentRegister: Record "Service Document Register";
    begin
        // [SCENARIO] Cannot delete a service invoice if the date fields are not stored in the service document register.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceDocumentRegister.Get(
          ServiceDocumentRegister."Source Document Type"::Contract, ServiceContractHeader."Contract No.",
          ServiceDocumentRegister."Destination Document Type"::Invoice, ServiceHeader."No.");
        Clear(ServiceDocumentRegister."Invoice Period");
        Clear(ServiceDocumentRegister."Last Invoice Date");
        Clear(ServiceDocumentRegister."Next Invoice Date");
        Clear(ServiceDocumentRegister."Next Invoice Period Start");
        Clear(ServiceDocumentRegister."Next Invoice Period End");
        ServiceDocumentRegister.Modify();

        // [WHEN] Delete service invoice.
        asserterror DeleteServiceInvoice(ServiceHeader);

        Assert.ExpectedError(CannotRestoreInvoiceDatesErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure CannotDeleteInvoiceIfInvoicePeriodChangedInContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Cannot delete a service invoice if the invoice period has been changed in the service contract.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceContractHeader.Find();
        ServiceContractHeader."Invoice Period" := ServiceContractHeader."Invoice Period"::"Two Months";
        ServiceContractHeader.Modify();

        // [WHEN] Delete service invoice.
        asserterror DeleteServiceInvoice(ServiceHeader);

        Assert.ExpectedError(InvoicePeriodChangedErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure Prepaid_DeleteServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeaderInitialState: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLineInitialState: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // [SCENARIO] Prepaid scenario. Delete a service invoice and verify that the date fields in the service contract are restored and reverse entries are created in the service ledger.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, true);
        ServiceContractHeaderInitialState := ServiceContractHeader;
        ServiceContractLineInitialState := ServiceContractLine;

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceDocumentRegister.Get(
          ServiceDocumentRegister."Source Document Type"::Contract, ServiceContractHeader."Contract No.",
          ServiceDocumentRegister."Destination Document Type"::Invoice, ServiceHeader."No.");
        ServiceDocumentRegister.TestField("Invoice Period", ServiceContractHeaderInitialState."Invoice Period");
        ServiceDocumentRegister.TestField("Last Invoice Date", ServiceContractHeaderInitialState."Last Invoice Date");
        ServiceDocumentRegister.TestField("Next Invoice Date", ServiceContractHeaderInitialState."Next Invoice Date");
        ServiceDocumentRegister.TestField("Next Invoice Period Start", ServiceContractHeaderInitialState."Next Invoice Period Start");
        ServiceDocumentRegister.TestField("Next Invoice Period End", ServiceContractHeaderInitialState."Next Invoice Period End");

        // [WHEN] Delete service invoice.
        DeleteServiceInvoice(ServiceHeader);

        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderInitialState, 0);

        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineInitialState."Invoiced to Date");

        ServiceLedgerEntry.SetCurrentKey("Service Contract No.");
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        Assert.RecordCount(ServiceLedgerEntry, 2);
        ServiceLedgerEntry.SetRange(Open, false);
        Assert.RecordCount(ServiceLedgerEntry, 2);

        ServiceLedgerEntry.CalcSums("Cost Amount", Quantity, Amount, "Amount (LCY)");
        ServiceLedgerEntry.TestField("Cost Amount", 0);
        ServiceLedgerEntry.TestField(Quantity, 0);
        ServiceLedgerEntry.TestField(Amount, 0);
        ServiceLedgerEntry.TestField("Amount (LCY)", 0);

        ServiceLedgerEntry.SetFilter("Applies-to Entry No.", '<>0');
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.Get(ServiceLedgerEntry."Applies-to Entry No.");
        ServiceLedgerEntry.TestField("Service Contract No.", ServiceContractHeader."Contract No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure Prepaid_DeleteTwoServiceInvoices()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeaderInitialState: array[2] of Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLineInitialState: array[2] of Record "Service Contract Line";
        ServiceHeader: array[2] of Record "Service Header";
    begin
        // [SCENARIO] Prepaid scenario. Delete two consecutive service invoices and verify that the date fields in the service contract are restored.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, true);
        ServiceContractHeaderInitialState[1] := ServiceContractHeader;
        ServiceContractLineInitialState[1] := ServiceContractLine;

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader[1], ServiceHeader[1]."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceContractHeader.Find();
        ServiceContractLine.Find();
        ServiceContractHeaderInitialState[2] := ServiceContractHeader;
        ServiceContractLineInitialState[2] := ServiceContractLine;

        WorkDate(CalcDate('<1M>', WorkDate()));
        ServiceHeader[2].Get(ServiceHeader[2]."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));

        // [WHEN] Delete the second and then the first service invoice.
        DeleteServiceInvoice(ServiceHeader[2]);
        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderInitialState[2], 1);
        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineInitialState[2]."Invoiced to Date");

        DeleteServiceInvoice(ServiceHeader[1]);
        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderInitialState[1], 0);
        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineInitialState[1]."Invoiced to Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure Prepaid_DeleteAndRecreateTwoServiceInvoices()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractHeaderNewState: Record "Service Contract Header";
        ServiceContractLineNewState: Record "Service Contract Line";
        ServiceHeader: array[2] of Record "Service Header";
    begin
        // [SCENARIO] Prepaid scenario. Create two service invoices, delete the second one, post the first one, and then recreate and post the second one.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, true);

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader[1], ServiceHeader[1]."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceContractHeader.Find();

        WorkDate(CalcDate('<1M>', WorkDate()));
        ServiceHeader[2].Get(ServiceHeader[2]."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));

        ServiceContractHeader.Find();
        ServiceContractLine.Find();
        ServiceContractHeaderNewState := ServiceContractHeader;
        ServiceContractLineNewState := ServiceContractLine;

        // [WHEN] Delete the second service invoice, post the first one, and then recreate and post the second one.
        DeleteServiceInvoice(ServiceHeader[2]);

        LibraryService.PostServiceOrder(ServiceHeader[1], true, false, true);

        Clear(ServiceHeader[2]);
        ServiceHeader[2].Get(ServiceHeader[2]."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));
        LibraryService.PostServiceOrder(ServiceHeader[2], true, false, true);

        ServiceContractHeader.Find();
        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderNewState, 0);
        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineNewState."Invoiced to Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure NonPrepaid_DeleteServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeaderInitialState: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLineInitialState: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // [SCENARIO] Non-prepaid scenario. Delete a service invoice and verify that the date fields in the service contract are restored and reverse entries are created in the service ledger.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);
        ServiceContractHeaderInitialState := ServiceContractHeader;
        ServiceContractLineInitialState := ServiceContractLine;

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceDocumentRegister.Get(
          ServiceDocumentRegister."Source Document Type"::Contract, ServiceContractHeader."Contract No.",
          ServiceDocumentRegister."Destination Document Type"::Invoice, ServiceHeader."No.");
        ServiceDocumentRegister.TestField("Invoice Period", ServiceContractHeaderInitialState."Invoice Period");
        ServiceDocumentRegister.TestField("Next Invoice Date", ServiceContractHeaderInitialState."Next Invoice Date");
        ServiceDocumentRegister.TestField("Next Invoice Period Start", ServiceContractHeaderInitialState."Next Invoice Period Start");
        ServiceDocumentRegister.TestField("Next Invoice Period End", ServiceContractHeaderInitialState."Next Invoice Period End");

        // [WHEN] Delete service invoice.
        DeleteServiceInvoice(ServiceHeader);

        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderInitialState, 0);

        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineInitialState."Invoiced to Date");

        ServiceLedgerEntry.SetCurrentKey("Service Contract No.");
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        Assert.RecordCount(ServiceLedgerEntry, 2);
        ServiceLedgerEntry.SetRange(Open, false);
        Assert.RecordCount(ServiceLedgerEntry, 2);

        ServiceLedgerEntry.CalcSums("Cost Amount", Quantity, Amount, "Amount (LCY)");
        ServiceLedgerEntry.TestField("Cost Amount", 0);
        ServiceLedgerEntry.TestField(Quantity, 0);
        ServiceLedgerEntry.TestField(Amount, 0);
        ServiceLedgerEntry.TestField("Amount (LCY)", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure NonPrepaid_DeleteTwoServiceInvoices()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeaderInitialState: array[2] of Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLineInitialState: array[2] of Record "Service Contract Line";
        ServiceHeader: array[2] of Record "Service Header";
    begin
        // [SCENARIO] Non-prepaid scenario. Delete two consecutive service invoices and verify that the date fields in the service contract are restored.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);
        ServiceContractHeaderInitialState[1] := ServiceContractHeader;
        ServiceContractLineInitialState[1] := ServiceContractLine;

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader[1], ServiceHeader[1]."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceContractHeader.Find();
        ServiceContractLine.Find();
        ServiceContractHeaderInitialState[2] := ServiceContractHeader;
        ServiceContractLineInitialState[2] := ServiceContractLine;

        WorkDate(CalcDate('<1M>', WorkDate()));
        ServiceHeader[2].Get(ServiceHeader[2]."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));

        // [WHEN] Delete the second and then the first service invoice.
        DeleteServiceInvoice(ServiceHeader[2]);
        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderInitialState[2], 1);
        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineInitialState[2]."Invoiced to Date");

        DeleteServiceInvoice(ServiceHeader[1]);
        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderInitialState[1], 0);
        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineInitialState[1]."Invoiced to Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ServiceContractTemplateListHandler,ConfirmHandler')]
    procedure NonPrepaid_DeleteAndRecreateTwoServiceInvoices()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractHeaderNewState: Record "Service Contract Header";
        ServiceContractLineNewState: Record "Service Contract Line";
        ServiceHeader: array[2] of Record "Service Header";
    begin
        // [SCENARIO] Non-prepaid scenario. Create two service invoices, delete the second one, post the first one, and then recreate and post the second one.
        Initialize();

        CreateServiceContract(ServiceContractHeader, ServiceContractLine, false);

        SignContract(ServiceContractHeader);

        CreateRemainingPeriodInvoice(ServiceContractHeader);
        FindServiceDocumentHeader(ServiceHeader[1], ServiceHeader[1]."Document Type"::Invoice, ServiceContractHeader."Contract No.");

        ServiceContractHeader.Find();

        WorkDate(CalcDate('<1M>', WorkDate()));
        ServiceHeader[2].Get(ServiceHeader[2]."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));

        ServiceContractHeader.Find();
        ServiceContractLine.Find();
        ServiceContractHeaderNewState := ServiceContractHeader;
        ServiceContractLineNewState := ServiceContractLine;

        // [WHEN] Delete the second service invoice, post the first one, and then recreate and post the second one.
        DeleteServiceInvoice(ServiceHeader[2]);

        LibraryService.PostServiceOrder(ServiceHeader[1], true, false, true);

        Clear(ServiceHeader[2]);
        ServiceHeader[2].Get(ServiceHeader[2]."Document Type"::Invoice, CreateServiceInvoice(ServiceContractHeader));
        LibraryService.PostServiceOrder(ServiceHeader[2], true, false, true);

        ServiceContractHeader.Find();
        VerifyServiceContract(ServiceContractHeader, ServiceContractHeaderNewState, 0);
        ServiceContractLine.Find();
        ServiceContractLine.TestField("Invoiced to Date", ServiceContractLineNewState."Invoiced to Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Invoices Delete");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if CurrentWorkDate = 0D then
            CurrentWorkDate := WorkDate();
        WorkDate(CalcDate('<CM-1W>', CurrentWorkDate));

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Service Invoices Delete");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        CreateServiceContractTemplates();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Service Invoices Delete");
    end;

    local procedure CreateServiceContractTemplates()
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        ServiceContractTemplate.DeleteAll();

        CreateServiceContractTemplate(
          ServiceContractTemplate, '<3M>', ServiceContractTemplate."Invoice Period"::Month, false, true, false, true);
        Clear(ServiceContractTemplate);
        CreateServiceContractTemplate(
          ServiceContractTemplate, '<3M>', ServiceContractTemplate."Invoice Period"::Month, false, true, false, false);
    end;

    local procedure CreateServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template"; ServicePeriodTxt: Text; InvoicePeriod: Option; CombineInvoices: Boolean; ContractLinesOnInvoice: Boolean; InvoiceAfterService: Boolean; IsPrepaid: Boolean)
    var
        DefaultServicePeriod: DateFormula;
    begin
        Evaluate(DefaultServicePeriod, ServicePeriodTxt);

        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        ServiceContractTemplate.Validate("Invoice Period", InvoicePeriod);
        ServiceContractTemplate.Validate(Prepaid, IsPrepaid);
        ServiceContractTemplate.Validate("Combine Invoices", CombineInvoices);
        ServiceContractTemplate.Validate("Contract Lines on Invoice", ContractLinesOnInvoice);
        ServiceContractTemplate.Validate("Invoice after Service", InvoiceAfterService);
        ServiceContractTemplate.Modify(true);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; IsPrepaid: Boolean)
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        CustomerNo: Code[20];
    begin
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(IsPrepaid);

        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);

        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Validate("Starting Date");
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandDec(100, 2));
        ServiceContractLine.Validate("Line Value", 100 * LibraryRandom.RandDec(100, 2));
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateRemainingPeriodInvoice(ServiceContractHeader: Record "Service Contract Header") InvoiceNo: Code[20]
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        LibraryVariableStorage.Enqueue(true);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        InvoiceNo := ServContractManagement.CreateRemainingPeriodInvoice(ServiceContractHeader);
    end;

    local procedure CreateServiceInvoice(ServiceContractHeader: Record "Service Contract Header") InvoiceNo: Code[20]
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        InvoiceNo := ServContractManagement.CreateInvoice(ServiceContractHeader);
    end;

    local procedure DeleteServiceInvoice(var ServiceHeader: Record "Service Header")
    begin
        LibraryVariableStorage.Enqueue(true);
        ServiceHeader.Delete(true);
    end;

    local procedure FindServiceDocumentHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; ContractNo: Code[20])
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindLast();
    end;

    local procedure SignContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure VerifyServiceContract(var ServiceContractHeader: Record "Service Contract Header"; PreviousServiceContractHeader: Record "Service Contract Header"; NoOfUnpostedInvoices: Integer)
    begin
        ServiceContractHeader.Find();
        ServiceContractHeader.CalcFields("No. of Unposted Invoices");
        ServiceContractHeader.TestField("No. of Unposted Invoices", NoOfUnpostedInvoices);
        ServiceContractHeader.TestField("Invoice Period", PreviousServiceContractHeader."Invoice Period");
        ServiceContractHeader.TestField("Last Invoice Date", PreviousServiceContractHeader."Last Invoice Date");
        ServiceContractHeader.TestField("Next Invoice Date", PreviousServiceContractHeader."Next Invoice Date");
        ServiceContractHeader.TestField("Next Invoice Period Start", PreviousServiceContractHeader."Next Invoice Period Start");
        ServiceContractHeader.TestField("Next Invoice Period End", PreviousServiceContractHeader."Next Invoice Period End");
    end;

    [ModalPageHandler]
    procedure ServiceContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        ServiceContractTemplate.SetRange(Prepaid, LibraryVariableStorage.DequeueBoolean());
        ServiceContractTemplate.FindFirst();
        ServiceContractTemplateList.Filter.SetFilter("No.", ServiceContractTemplate."No.");
        ServiceContractTemplateList.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}