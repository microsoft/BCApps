// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Analysis;
using Microsoft.Service.Contract;
using Microsoft.Service.Item;

codeunit 136139 "Service Matrix Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Contract Gain/Loss] [Service]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        Amount: Decimal;
        PeriodStart: Date;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Matrix Management");
        // Clear the global variables.
        Amount := 0;
        Clear(PeriodStart);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Matrix Management");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Matrix Management");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,GainLossGroupsMatrixHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossGroups()
    var
        ContractGroup: Record "Contract Group";
        ServiceContractHeader: Record "Service Contract Header";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractGainLossGroups: TestPage "Contract Gain/Loss (Groups)";
    begin
        // Test Contract Gain/Loss (Groups) Matrix after signing the Service Contract.

        // 1. Setup: Create Contract Group, Service Contract Header, Service Contract Line, update Contract Group Code on Service
        // Contract Header and sign the Service Contract.
        Initialize();
        LibraryService.CreateContractGroup(ContractGroup);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        CreateServiceContractLine(ServiceContractHeader);
        UpdateContractGroupCode(ServiceContractHeader, ContractGroup.Code);
        UpdateServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindContractGainLossEntry(ContractGainLossEntry, ServiceContractHeader."Contract No.");

        // Assign global variable for page handler.
        Amount := ContractGainLossEntry.Amount;
        PeriodStart := ContractGainLossEntry."Change Date";

        // 2. Exercise: Run Show Matrix from Contract Gain/Loss (Groups) page with Period Start Date and Group filter.
        ContractGainLossGroups.OpenEdit();
        ContractGainLossGroups.PeriodStart.SetValue(ContractGainLossEntry."Change Date");
        ContractGainLossGroups.GroupFilter.SetValue(ServiceContractHeader."Contract Group Code");
        Commit();
        ContractGainLossGroups.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Contract Gain/Loss (Groups) Matrix performed on Contract Gain/Loss (Groups) Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,GainLossCustomerMatrixHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossCustomers()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ServiceContractHeader: Record "Service Contract Header";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractGainLossCustomers: TestPage "Contract Gain/Loss (Customers)";
    begin
        // Test Contract Gain/Loss (Customers) Matrix after signing the Service Contract.

        // 1. Setup: Create Service Contract Header, create Ship to Address for Customer, update it on Service Contract Header, Service
        // Contract Line and sign the Service Contract.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateAndUpdateShipToAddress(ServiceContractHeader, ShipToAddress.Code);
        CreateServiceContractLine(ServiceContractHeader);
        UpdateServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindContractGainLossEntry(ContractGainLossEntry, ServiceContractHeader."Contract No.");

        // Assign global variable for page handler.
        Amount := ContractGainLossEntry.Amount;
        PeriodStart := ContractGainLossEntry."Change Date";

        // 2. Exercise: Run Show Matrix from Contract Gain/Loss (Customers) page with Period Start date, Customer No. and Ship to Code
        // filter.
        ContractGainLossCustomers.OpenEdit();
        ContractGainLossCustomers.PeriodStart.SetValue(ContractGainLossEntry."Change Date");
        ContractGainLossCustomers.CustomerNo.SetValue(ServiceContractHeader."Customer No.");
        ContractGainLossCustomers.ShipToCodeFilter.SetValue(ShipToAddress.Code);
        Commit();
        ContractGainLossCustomers.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Contract Gain/Loss (Customers) Matrix performed on Contract Gain/Loss (Customers) Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,ContractGainLossMatrixHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossReasons()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ReasonCode: Record "Reason Code";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ContractGainLossReasons: TestPage "Contract Gain/Loss (Reasons)";
        ServiceContract: TestPage "Service Contract";
    begin
        // Test Contract Gain/Loss Matrix after signing the Service Contract.

        // 1. Setup: Create Reason Code, Service Contract Header, Service Contract Line, update Cancel Reason Code on Service
        // Contract Header, open Service Contract page and update Status to Canceled.
        Initialize();
        LibraryService.CreateReasonCode(ReasonCode);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractHeader);
        UpdateCancelReasonCode(ServiceContractHeader, ReasonCode.Code);
        UpdateServiceContractHeader(ServiceContractHeader);

        ServiceContract.OpenEdit();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.Status.SetValue(ServiceContractHeader.Status::Cancelled);
        FindContractGainLossEntry(ContractGainLossEntry, ServiceContractHeader."Contract No.");

        // Assign global variable for page handler.
        Amount := ContractGainLossEntry.Amount;
        PeriodStart := ContractGainLossEntry."Change Date";

        // 2. Exercise: Run Show Matrix from Contract Gain/Loss (Reasons) page with Period Start date and Reason filter.
        ContractGainLossReasons.OpenEdit();
        ContractGainLossReasons.PeriodStart.SetValue(ContractGainLossEntry."Change Date");
        ContractGainLossReasons.ReasonFilter.SetValue(ReasonCode.Code);
        Commit();
        ContractGainLossReasons.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Contract Gain/Loss Matrix performed on Contract Gain/Loss Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ResponsibilityMatrixHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossResponsibility()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceContractHeader: Record "Service Contract Header";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractGainLossRespCtr: TestPage "Contract Gain/Loss (Resp.Ctr)";
    begin
        // Test Contract Gain/Loss (Responsibility Center) Matrix after signing the Service Contract.

        // 1. Setup: Create Responsibility Center, Service Contract Header, Service Contract Line, update Responsibility Center on
        // Service Contract Header and sign the Service Contract.
        Initialize();
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        CreateServiceContractLine(ServiceContractHeader);
        UpdateResponsibilityCenter(ServiceContractHeader, ResponsibilityCenter.Code);
        UpdateServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindContractGainLossEntry(ContractGainLossEntry, ServiceContractHeader."Contract No.");

        // Assign global variable for page handler.
        Amount := ContractGainLossEntry.Amount;
        PeriodStart := ContractGainLossEntry."Change Date";

        // 2. Exercise: Run Show Matrix from Contract Gain/Loss (Responsibility Center) page with Period Start Date and
        // Responsibility Center filter.
        ContractGainLossRespCtr.OpenEdit();
        ContractGainLossRespCtr.PeriodStart.SetValue(ContractGainLossEntry."Change Date");
        ContractGainLossRespCtr.RespCrFilter.SetValue(ResponsibilityCenter.Code);
        Commit();
        ContractGainLossRespCtr.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Contract Gain/Loss (Responsibility Center) Matrix performed on Contract Gain/Loss
        // (Responsibility Center) Matrix page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,GainLossContractsMatrixHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossContracts()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractGainLossContracts: TestPage "Contract Gain/Loss (Contracts)";
    begin
        // Test Contract Gain/Loss (Contracts) Matrix after signing the Service Contract.

        // 1. Setup: Create Service Contract Header, Service Contract Line and sign the Service Contract.
        Initialize();
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        CreateServiceContractLine(ServiceContractHeader);
        UpdateServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        FindContractGainLossEntry(ContractGainLossEntry, ServiceContractHeader."Contract No.");

        // Assign global variable for page handler.
        Amount := ContractGainLossEntry.Amount;
        PeriodStart := ContractGainLossEntry."Change Date";

        // 2. Exercise: Run Show Matrix from Contract Gain/Loss (Contracts) page with Period Start date and Contract filter.
        ContractGainLossContracts.OpenEdit();
        ContractGainLossContracts.PeriodStart.SetValue(ContractGainLossEntry."Change Date");
        ContractGainLossContracts.ContractFilter.SetValue(ServiceContractHeader."Contract No.");
        Commit();
        ContractGainLossContracts.ShowMatrix.Invoke();

        // 3. Verify: Verify value on Contract Gain/Loss (Contracts) Matrix performed on Contract Gain/Loss (Contracts) Matrix
        // page handler.
    end;

    local procedure CreateAndUpdateShipToAddress(var ServiceContractHeader: Record "Service Contract Header"; ShipToCode: Code[10])
    begin
        ServiceContractHeader.Validate("Ship-to Code", ShipToCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Use Random for Line Cost and Line Value.
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandDec(10000, 2));
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandDec(1000, 2));
        ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
        ServiceContractLine.Modify(true);
    end;

    local procedure FindContractGainLossEntry(var ContractGainLossEntry: Record "Contract Gain/Loss Entry"; ContractNo: Code[20])
    begin
        ContractGainLossEntry.SetRange("Contract No.", ContractNo);
        ContractGainLossEntry.FindFirst();
    end;

    local procedure UpdateCancelReasonCode(var ServiceContractHeader: Record "Service Contract Header"; CancelReasonCode: Code[10])
    begin
        ServiceContractHeader.Validate("Cancel Reason Code", CancelReasonCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateContractGroupCode(var ServiceContractHeader: Record "Service Contract Header"; ContractGroupCode: Code[10])
    begin
        ServiceContractHeader.Validate("Contract Group Code", ContractGroupCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateResponsibilityCenter(var ServiceContractHeader: Record "Service Contract Header"; ResponsibilityCenter: Code[10])
    begin
        ServiceContractHeader.Validate("Responsibility Center", ResponsibilityCenter);
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractGainLossMatrixHandler(var ContractGainLossMatrix: TestPage "Contract Gain/Loss Matrix")
    begin
        ContractGainLossMatrix.FILTER.SetFilter("Period Start", Format(PeriodStart));
        ContractGainLossMatrix.TotalGainLoss.AssertEquals(Amount);
        ContractGainLossMatrix.Field1.AssertEquals(Format(Amount, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        ServiceContractTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GainLossContractsMatrixHandler(var ContrGLossContrMatrix: TestPage "Contr. G/Loss (Contr.) Matrix")
    begin
        ContrGLossContrMatrix.FILTER.SetFilter("Period Start", Format(PeriodStart));
        ContrGLossContrMatrix.TotalGainLoss.AssertEquals(Amount);
        ContrGLossContrMatrix.Field1.AssertEquals(Format(Amount, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GainLossCustomerMatrixHandler(var ContrGLossCustMatrix: TestPage "Contr. G/Loss (Cust.) Matrix")
    begin
        ContrGLossCustMatrix.FILTER.SetFilter("Period Start", Format(PeriodStart));
        ContrGLossCustMatrix.TotalGainLoss.AssertEquals(Amount);
        ContrGLossCustMatrix.Field1.AssertEquals(Format(Amount, 0, '<Precision,2><Standard Format,0>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GainLossGroupsMatrixHandler(var ContrGainLossGrpsMatrix: TestPage "Contr. Gain/Loss (Grps) Matrix")
    begin
        ContrGainLossGrpsMatrix.FILTER.SetFilter("Period Start", Format(PeriodStart));
        ContrGainLossGrpsMatrix.TotalGainLoss.AssertEquals(Amount);
        ContrGainLossGrpsMatrix.Field1.AssertEquals(Format(Amount, 0, '<Precision,2><Standard Format,0>'));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResponsibilityMatrixHandler(var ContrGLossResCtrMatrix: TestPage "Contr. G/Loss (Res.Ctr) Matrix")
    begin
        ContrGLossResCtrMatrix.FILTER.SetFilter("Period Start", Format(PeriodStart));
        ContrGLossResCtrMatrix.TotalGainLoss.AssertEquals(Amount);
        ContrGLossResCtrMatrix.Field1.AssertEquals(Format(Amount, 0, '<Precision,2><Standard Format,0>'));
    end;
}

