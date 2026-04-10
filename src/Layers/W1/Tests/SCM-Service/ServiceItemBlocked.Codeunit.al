// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using System.TestLibraries.Utilities;

codeunit 136136 "Service Item Blocked"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Service Item] [Blocked]
        IsInitialized := false;
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceContractOperation: Option "Create Contract from Template","Invoice for Period";
        InvalidTableRelationErr: Label 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).', Comment = '%1 - Validating Field Caption, %2 - Validating Table Caption, %3 - Validating Value, %4 - Related Table Caption';
        BlockedTestFieldErr: Label '%1 must be equal to ''%2''', Comment = '%1 - Field Caption, %2 - Expected value';
        BlockedMustNotBeErr: Label '%1 must not be %2', Comment = '%1 - Field Caption, %2 - Prohibited value';

    [Test]
    procedure Blocked_LogToServiceItemLogOnChange()
    var
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Item Log]
        // [SCENARIO 378441] Log "Blocked" field changes to Service Item Log.
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [WHEN] Change Blocked
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [THEN] Check the Service Item Log entry after creation of the Service Item.
        VerifyServiceItemLogEntry(ServiceItem."No.", 19);  // The value 19 is the event number for modifying Blocked in Service Item.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_NotAllowedInServiceContractLine()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract" not allowed in Service Contract Line.
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        CreateBlockedServiceItem(ServiceItem, Enum::"Service Item Blocked"::"Service Contract");

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [WHEN] Create a Service Contract Line with Service Item
        asserterror LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceContractLine.FieldCaption("Service Item No."), ServiceContractLine.TableCaption(), ServiceItem."No.", ServiceItem.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_NotAllowedInServiceContractLine()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract]
        // [SCENARIO 378441] Service item with "Blocked" = "All" not allowed in Service Contract Line.
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "All"
        CreateBlockedServiceItem(ServiceItem, Enum::"Service Item Blocked"::All);

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [WHEN] Create a Service Contract Line with Service Item
        asserterror LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceContractLine.FieldCaption("Service Item No."), ServiceContractLine.TableCaption(), ServiceItem."No.", ServiceItem.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ContractLineSelectionHandler')]
    procedure Blocked_ServiceContract_NotVisibleInSelectContractLines()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Contract Line Selection]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract" not visible in "Select Contract Lines" action in "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        CreateBlockedServiceItem(ServiceItem, Enum::"Service Item Blocked"::"Service Contract");

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [WHEN] Open Contract Line Selection page from Service Contract
        ServiceContract.OpenEdit();
        ServiceContract.Filter.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.SelectContractLines.Invoke();

        // [THEN] Verify that the Contract Line Selection page is blank and is closed by clicking Cancel through the handler ContractLineSelectionHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ContractLineSelectionHandler')]
    procedure Blocked_All_NotVisibleInSelectContractLines()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContract: TestPage "Service Contract";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Contract Line Selection]
        // [SCENARIO 378441] Service item with "Blocked" = "All" not visible in "Select Contract Lines" action in "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "All"
        CreateBlockedServiceItem(ServiceItem, Enum::"Service Item Blocked"::All);

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [WHEN] Open Contract Line Selection page from Service Contract
        ServiceContract.OpenEdit();
        ServiceContract.Filter.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.SelectContractLines.Invoke();

        // [THEN] Verify that the Contract Line Selection page is blank and is closed by clicking Cancel through the handler ContractLineSelectionHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ContractLineSelectionHandler')]
    procedure Blocked_ServiceContract_NotVisibleInSelectContractQuoteLines()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractQuote: TestPage "Service Contract Quote";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Contract Line Selection]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract" not visible in "Select Contract Quote Lines" action in "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        CreateBlockedServiceItem(ServiceItem, Enum::"Service Item Blocked"::"Service Contract");

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [WHEN] Open Contract Line Selection page from Service Contract Quote
        ServiceContractQuote.OpenEdit();
        ServiceContractQuote.Filter.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractQuote."&Select Contract Quote Lines".Invoke();

        // [THEN] Verify that the Contract Line Selection page is blank and is closed by clicking Cancel through the handler ContractLineSelectionHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ContractLineSelectionHandler')]
    procedure Blocked_All_NotVisibleInSelectContractQuoteLines()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractQuote: TestPage "Service Contract Quote";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Contract Line Selection]
        // [SCENARIO 378441] Service item with "Blocked" = "All" not visible in "Select Contract Quote Lines" action in "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "All"
        CreateBlockedServiceItem(ServiceItem, Enum::"Service Item Blocked"::All);

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [WHEN] Open Contract Line Selection page from Service Contract Quote
        ServiceContractQuote.OpenEdit();
        ServiceContractQuote.Filter.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractQuote."&Select Contract Quote Lines".Invoke();

        // [THEN] Verify that the Contract Line Selection page is blank and is closed by clicking Cancel through the handler ContractLineSelectionHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_CannotLockServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Lock]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot Lock "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Lock Service Contract
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_CannotLockServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Lock]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Lock "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Lock Service Contract
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_CannotLockServiceContractQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Lock]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot Lock "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract Quote
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Lock Service Contract Quote
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_CannotLockServiceContractQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Lock]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Lock "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract Quote
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Lock Service Contract Quote
        asserterror LockServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_CannotSignServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Sign]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot Sign "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Sign Service Contract
        asserterror SignServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_CannotSignServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Sign]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Sign "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Sign Service Contract
        asserterror SignServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_CannotMakeServiceContractFromServiceContractQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Make Contract]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot Make Contract from "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract Quote
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Make Service Contract
        asserterror MakeServiceContractFromServiceContractQuote(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_CannotMakeServiceContractFromServiceContractQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Make Contract]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Make Contract from "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract Quote
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Make Service Contract
        asserterror MakeServiceContractFromServiceContractQuote(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_CannotCopyServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Copy]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot Copy "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Copy Service Contract
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_CannotCopyServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Copy]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Copy "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Copy Service Contract
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_ServiceContract_CannotCopyServiceContractQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Copy]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot Copy "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Copy Service Contract Quote
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    procedure Blocked_All_CannotCopyServiceContractQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract Quote] [Copy]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Copy "Service Contract Quote".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Quote Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Copy Service Contract Quote
        asserterror CopyServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ChangeCustomerInContractRequestPageHandler')]
    procedure Blocked_ServiceContract_CannotChangeCustomerInServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Change Customer]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", cannot "Change Customer" in "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] "Change Customer" in Service Contract
        Commit();
        asserterror ChangeCustomerInServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ChangeCustomerInContractRequestPageHandler')]
    procedure Blocked_All_CannotChangeCustomerInServiceContract()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Change Customer]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot "Change Customer" in "Service Contract".
        Initialize();

        // [GIVEN] Create Service Item
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [GIVEN] Create a Service Contract Header
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Service Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] "Change Customer" in Service Contract
        Commit();
        asserterror ChangeCustomerInServiceContract(ServiceContractHeader);

        // [THEN] An error appears: 'Blocked must be equal to ' ''
        Assert.ExpectedError(StrSubstNo(BlockedTestFieldErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::" ")));
    end;

    [Test]
    procedure Blocked_All_NotAllowedInServiceOrder()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Order]
        // [SCENARIO 378441] Service item with "Blocked" = "All" not allowed in Service Order.
        Initialize();

        // [GIVEN] Create Service Item with "Blocked" = "All"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [WHEN] Create Service Item Line with Service Item with "Blocked" = "All"
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] An error appears: 'The field %1 of table %2 contains a value (%3) that cannot be found in the related table (%4).'
        Assert.ExpectedError(StrSubstNo(InvalidTableRelationErr, ServiceItemLine.FieldCaption("Service Item No."), ServiceItemLine.TableCaption(), ServiceItem."No.", ServiceItem.TableCaption()));
    end;

    [Test]
    procedure Blocked_ServiceContract_AllowedInServiceOrderAndCanBePosted()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Order]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract" allowed in Service Order and can be posted.
        Initialize();

        // [GIVEN] Create Item and add Inventory
        LibraryInventory.CreateItem(Item);
        SetItemInventory(Item, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create Service Item Line with Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Create Service Line with Item
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] Service Order can be posted
    end;

    [Test]
    procedure Blocked_All_DefinedAfterCreation_CannotPostServiceOrder()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Order]
        // [SCENARIO 378441] Service item with "Blocked" = "All" after creation, cannot post Service Order.
        Initialize();

        // [GIVEN] Create Item and add Inventory
        LibraryInventory.CreateItem(Item);
        SetItemInventory(Item, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create Service Item Line with Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Create Service Line with Item
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Post Service Order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] Service Order cannot be posted. An error appears: 'Blocked must not be All'
        Assert.ExpectedError(StrSubstNo(BlockedMustNotBeErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::All)));
    end;

    [Test]
    procedure Blocked_ServiceContract_DefinedAfterCreation_CanPostServiceOrder()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Order]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract" after creation, can post Service Order.
        Initialize();

        // [GIVEN] Create Item and add Inventory
        LibraryInventory.CreateItem(Item);
        SetItemInventory(Item, LibraryRandom.RandIntInRange(15, 20));

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Order Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Create Service Item Line with Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Create Service Line with Item
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] Service Order can be posted
    end;

    [Test]
    procedure Blocked_All_AllowedInServiceCreditMemoAndCanBePosted()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Credit Memo]
        // [SCENARIO 378441] Service item with "Blocked" = "All" allowed in Service Credit Memo and can be posted.
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Item with "Blocked" = "All"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Credit Memo Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceItem."Customer No.");

        // [WHEN] Create Service Line with Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [WHEN] Post Service Credit Memo
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Service Credit Memo can be posted
    end;

    [Test]
    procedure Blocked_ServiceContract_AllowedInServiceCreditMemoAndCanBePosted()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Credit Memo]
        // [SCENARIO 378441] Service item with "Blocked" = "All" allowed in Service Credit Memo and can be posted.
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Item with "Blocked" = "All"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Credit Memo Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceItem."Customer No.");

        // [WHEN] Create Service Line with Service Item with "Blocked" = "All"
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [WHEN] Post Service Credit Memo
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // [THEN] Service Credit Memo can be posted
    end;

    [Test]
    procedure Blocked_All_CannotReleaseServiceDocument()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Release Service Document (Quote/Invoice/Order).
        Initialize();

        // [GIVEN] Item without "Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Release Service Document
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] Service Order cannot be posted. An error appears: 'Blocked must not be All'
        Assert.ExpectedError(StrSubstNo(BlockedMustNotBeErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::All)));
    end;

    [Test]
    procedure Blocked_ServiceContract_CanReleaseServiceDocument()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Quote] [Release]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", can Release Service Document (Quote/Invoice/Order).
        Initialize();

        // [GIVEN] Item without "Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [WHEN] Release Service Document
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] Can Release Service Document
    end;

    [Test]
    procedure Blocked_All_CannotCreateServiceOrderFromQuote()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Quote] [Make Order]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot Create Service Order from Quote.
        Initialize();

        // [GIVEN] Item without "Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Create Service Order from Service Quote
        asserterror LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Service Order cannot be posted. An error appears: 'Blocked must not be All'
        Assert.ExpectedError(StrSubstNo(BlockedMustNotBeErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::All)));
    end;

    [Test]
    procedure Blocked_ServiceContract_CanCreateServiceOrderFromQuote()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Quote] [Make Order]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", can Create Service Order from Quote.
        Initialize();

        // [GIVEN] Item without "Blocked"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Item with "Blocked" = "Service Contract"
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Quote Header, Service Item Line and Service Line with Item
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceLine.Modify(true);

        // [WHEN] Create Service Order from Service Quote
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Service Order is created
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure Blocked_All_CannotCreateContractServiceOrders()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServicePeriodDateFormula: DateFormula;
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Create Service Orders]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot execute "Create Contract Service Orders".
        Initialize();

        // [GIVEN] Create Item and Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("First Service Date", WorkDate());
        Evaluate(ServicePeriodDateFormula, '<1Y>');
        ServiceContractHeader.Validate("Service Period", ServicePeriodDateFormula);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Run "Create Contract Service Orders"
        asserterror CreateServiceContractServiceOrders(ServiceContractHeader);

        // [THEN] Service Order cannot be posted. An error appears: 'Blocked must not be All'
        Assert.ExpectedError(StrSubstNo(BlockedMustNotBeErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::All)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler,MessageHandler')]
    procedure Blocked_ServiceContract_CanCreateContractServiceOrders()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServicePeriodDateFormula: DateFormula;
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Create Service Orders]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", can execute "Create Contract Service Orders".
        Initialize();

        // [GIVEN] Create Item and Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");

        // [GIVEN] Create a Service Contract Line with Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("First Service Date", WorkDate());
        Evaluate(ServicePeriodDateFormula, '<1Y>');
        ServiceContractHeader.Validate("Service Period", ServicePeriodDateFormula);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Run "Create Contract Service Orders"
        CreateServiceContractServiceOrders(ServiceContractHeader);

        // [THEN] Service Orders are created.
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler')]
    procedure Blocked_All_CannotCreateContractServiceInvoices()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Create Service Invoices]
        // [SCENARIO 378441] Service item with "Blocked" = "All", cannot execute "Create Contract Invoices".
        Initialize();

        // [GIVEN] Create Item and Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] Create a Service Contract Line with Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Update Service Item "Blocked" = "All"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::All);
        ServiceItem.Modify(true);

        // [WHEN] Run "Create Contract Invoices"
        asserterror CreateServiceContractInvoices(ServiceContractHeader);

        // [THEN] Service Order cannot be posted. An error appears: 'Blocked must not be All'
        Assert.ExpectedError(StrSubstNo(BlockedMustNotBeErr, ServiceItem.FieldCaption(Blocked), Format(ServiceItem.Blocked::All)));
    end;

    [Test]
    [HandlerFunctions('ServiceConfirmHandler,MessageHandler')]
    procedure Blocked_ServiceContract_CanCreateContractServiceInvoices()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [FEATURE] [Service Item] [Blocked] [Service Contract] [Create Service Invoices]
        // [SCENARIO 378441] Service item with "Blocked" = "Service Contract", can execute "Create Contract Invoices".
        Initialize();

        // [GIVEN] Create Item and Service Item with Item
        CreateServiceItemWithItem(ServiceItem, '', Item);

        // [GIVEN] Create a Service Contract Header
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Create Contract from Template");
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-1Y>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] Create a Service Contract Line with Item
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10)); // Use Random because value is not important.
        ServiceContractLine.Modify(true);

        // [GIVEN] Set "Annual Amount" in Service Contract
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractLine."Line Amount");
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Service Contract
        LibraryVariableStorage.Enqueue(ServiceContractOperation::"Invoice for Period");
        SignServiceContract(ServiceContractHeader);

        // [GIVEN] Update Service Item "Blocked" = "Service Contract"
        ServiceItem.Validate(Blocked, ServiceItem.Blocked::"Service Contract");
        ServiceItem.Modify(true);

        // [WHEN] Run "Create Contract Invoices"
        CreateServiceContractInvoices(ServiceContractHeader);

        // [THEN] Service Invoices are created.
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Service Item Blocked");

        // Lazy Setup
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Service Item Blocked");

        LibraryService.SetupServiceMgtNoSeries();
        AtLeastOneServiceContractTemplateMustExist();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibrarySales.SetStockoutWarning(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Service Item Blocked");
    end;

    local procedure AtLeastOneServiceContractTemplateMustExist()
    var
        ServiceContractTemplate: Record "Service Contract Template";
    begin
        if not ServiceContractTemplate.IsEmpty() then
            exit;

        ServiceContractTemplate.Init();
        ServiceContractTemplate.Insert(true);
    end;

    local procedure SetItemInventory(Item: Record Item; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.TestField("No.");

        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalLine."Journal Batch Name");
    end;

    local procedure VerifyServiceItemLogEntry(ServiceItemNo: Code[20]; EventNo: Integer)
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        // Verify Service Item Log entry contains the Event No. that corresponds to the event that occured due to a certain action.
        ServiceItemLog.SetRange("Service Item No.", ServiceItemNo);
        ServiceItemLog.FindLast();
        ServiceItemLog.TestField("Event No.", EventNo);
    end;

    local procedure CreateBlockedServiceItem(var ServiceItem: Record "Service Item"; ServiceItemBlocked: Enum "Service Item Blocked")
    begin
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate(Blocked, ServiceItemBlocked);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceItemWithItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);

        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);
    end;

    local procedure LockServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LockOpenServContract.LockServContract(ServiceContractHeader);
    end;

    local procedure SignServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure MakeServiceContractFromServiceContractQuote(var ServiceContractHeader: Record "Service Contract Header")
    var
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        SignServContractDoc.SetHideDialog(true);
        SignServContractDoc.SignContractQuote(ServiceContractHeader);
    end;

    local procedure CopyServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLineTo: Record "Service Contract Line";
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
    begin
        CopyServiceContractMgt.CopyServiceContractLines(ServiceContractHeader, ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", ServiceContractLineTo);
    end;

    local procedure ChangeCustomerInServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        ChangeCustomerinContract: Report "Change Customer in Contract";
    begin
        ChangeCustomerinContract.SetRecord(ServiceContractHeader."Contract No.");
        ChangeCustomerinContract.RunModal();
    end;

    local procedure CreateServiceContractServiceOrders(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractServiceOrders: Report "Create Contract Service Orders";
    begin
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractServiceOrders.SetTableView(ServiceContractHeader);
        CreateContractServiceOrders.InitializeRequest(WorkDate(), WorkDate(), 0);
        CreateContractServiceOrders.UseRequestPage(false);
        CreateContractServiceOrders.Run();
    end;

    local procedure CreateServiceContractInvoices(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractInvoices: Report "Create Contract Invoices";
    begin
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(WorkDate(), ServiceContractHeader."Next Invoice Date", 0);
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm as false.
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ServiceConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    var
        ServiceContractOperationValue: Option "Create Contract from Template","Invoice for Period";
    begin
        ServiceContractOperationValue := LibraryVariableStorage.DequeueInteger();
        case ServiceContractOperationValue of
            ServiceContractOperationValue::"Create Contract from Template":
                Result := false; // Do not use Template
            ServiceContractOperationValue::"Invoice for Period":
                Result := false; // Do not create Invoice for Period
        end;
    end;

    [ModalPageHandler]
    procedure ContractLineSelectionHandler(var ContractLineSelection: TestPage "Contract Line Selection")
    begin
        // Verifying that there is no value on the Contract Line Selection page.
        ContractLineSelection."No.".AssertEquals('');
        ContractLineSelection."Customer No.".AssertEquals('');
        ContractLineSelection.Cancel().Invoke(); // Using Cancel to close the page as OK button is disabled.
    end;

    [RequestPageHandler]
    procedure ChangeCustomerInContractRequestPageHandler(var ChangeCustomerInContract: TestRequestPage "Change Customer in Contract")
    begin
    end;
}

