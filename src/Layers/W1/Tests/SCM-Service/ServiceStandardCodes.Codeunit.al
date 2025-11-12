// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;

codeunit 136119 "Service Standard Codes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Standard Service Code] [Service]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ServiceItemGroupCode2: Code[10];
        StandardServiceCode2: Code[10];
        isInitialized: Boolean;
        StdServiceCodeMustNotExist: Label '%1 must not exist.';
        StdServiceLinesMustNotExist: Label '%1%2 must not exist.';
        TypeError: Label '%1 must not be %2 in %3 %4=''%5'',%6=''%7''.';
        TypeErrorServiceTier: Label '%1 must not be %2 in %3: %4=%5, %6=%7';
        UnknownError: Label 'Unknown error.';
        CurrencyNotMatching: Label '%1 of the standard service code must be equal to %2 on the %3.';
        QuantityMustbePositive: Label '%1 must be positive in %2 %3=''%4'',%5=''%6''.';
        ServiceLineMustNotExist: Label 'There is no %1 within the filter.Filters: %2: %3, %4: %5';
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';

    [Test]
    [Scope('OnPrem')]
    procedure RenameStdCode()
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        NewStandardServiceCode: Code[10];
        OldStandardServiceCode: Code[10];
    begin
        // Covers document number TC-SSC-01, TC-PP-SSC-02 - refer to TFS ID 20924.
        // Test that it is possible to create a new Standard Service Code with the Standard Service Lines attached and rename it.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create a new Standard Service Code with Standard Service Lines of all Type. Rename the Standard Service Code.
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);

        OldStandardServiceCode := StandardServiceCode.Code;
        NewStandardServiceCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(StandardServiceCode.FieldNo(Code), DATABASE::"Standard Service Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Standard Service Code", StandardServiceCode.FieldNo(Code)));
        StandardServiceCode.Rename(NewStandardServiceCode);

        // 3. Verify: Standard Service Code and related Standard Service Lines are renamed.
        Assert.IsFalse(StandardServiceCode.Get(OldStandardServiceCode), StrSubstNo(StdServiceCodeMustNotExist, OldStandardServiceCode));
        StandardServiceLine.SetRange("Standard Service Code", NewStandardServiceCode);
        StandardServiceLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantityOnStdCode()
    begin
        // Covers document number TC-PP-SSC-03 - refer to TFS 20924.
        // Test that it is possible to enter, change the value in the Quantity field for all Standard Service Line types.

        QuantityOnStdCode(LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearQuantityOnStdCode()
    begin
        // Covers document number TC-PP-SSC-03 - refer to TFS ID 20924.
        // Test that it is possible to clear the value in the Quantity field for all Standard Service Line types.

        QuantityOnStdCode(0);  // To Clear the Quantity on Standard Service Line.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeQuantityOnStdCode()
    begin
        // Covers document number TC-PP-SSC-03 - refer to TFS 20924.
        // Test that it is not possible to enter Negative Quantity field for all Standard Service Line types.

        QuantityOnStdCode(-LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
    end;

    local procedure QuantityOnStdCode(Quantity: Decimal)
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // 1. Setup: Create a new Standard Service Code with Standard Service Lines for all type.
        Initialize();
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);

        // 2. Exercise: Change the Quantity on Standard Service Lines.
        if Quantity < 0 then
            asserterror UpdateQuantityOnStdServiceLine(StandardServiceLine, StandardServiceCode.Code, Quantity)
        else
            UpdateQuantityOnStdServiceLine(StandardServiceLine, StandardServiceCode.Code, Quantity);

        // 3. Verify: Quantity updated on Standard Service Lines.
        if Quantity < 0 then
            Assert.AreEqual(
              StrSubstNo(QuantityMustbePositive, StandardServiceLine.FieldCaption(Quantity), StandardServiceLine.TableCaption(),
                StandardServiceLine.FieldCaption("Standard Service Code"), StandardServiceCode.Code,
                StandardServiceLine.FieldCaption("Line No."), StandardServiceLine."Line No."),
              GetLastErrorText,
              UnknownError)
        else
            VerifyQuantityOnStdServiceLine(StandardServiceCode.Code, Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateOnBlankStdCode()
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-PP-SSC-03, TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that application generates an error on enter, change value in the Quantity or Amount field for Standard Service Line
        // with type blank.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create a new Standard Service Code and Standard Service Line with Type blank.
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);

        // 3. Verify: Error is generated on updating the Quantity or Amount field on Standard Service Line with Type blank.
        Commit(); // Commit is important to the Test Case.
        VerifyQuantityAmountOnBlank(StandardServiceLine, StandardServiceCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAmountOnStdCodeGL()
    begin
        // Covers document number TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that it is possible to enter, change value in the Amount Excl. VAT field for Standard Service Line with type G/L Account.

        AmountOnStdCodeGL(LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAmountOnStdCodeGL()
    begin
        // Covers document number TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that it is possible to clear value in the Amount Excl. VAT field for Standard Service Line with type G/L Account.

        AmountOnStdCodeGL(0);
    end;

    local procedure AmountOnStdCodeGL(Amount: Decimal)
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // 1. Setup: Create a new Standard Service Code with Standard Service Line of type G/L Account.
        Initialize();
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);

        // 2. Exercise: Change the value in Amount Excl. VAT field on Standard Service Line.
        StandardServiceLine.Validate("Amount Excl. VAT", Amount);
        StandardServiceLine.Modify(true);

        // 3. Verify: Amount Excl. VAT updated on Standard Service Line.
        StandardServiceLine.TestField("Amount Excl. VAT", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAmountOnStdCodeItem()
    var
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that it is not possible to enter, change value in the Amount Excl. VAT field for Standard Service Line with type Item.

        ChangeAmountOnStdCode(StandardServiceLine.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAmountOnStdCodeResource()
    var
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that it is not possible to enter, change value in the Amount Excl. VAT field for Standard Service Line with type Resource.

        ChangeAmountOnStdCode(StandardServiceLine.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAmountOnStdCodeCost()
    var
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that it is not possible to enter, change value in the Amount Excl. VAT field for Standard Service Line with type Cost.

        ChangeAmountOnStdCode(StandardServiceLine.Type::Cost);
    end;

    local procedure ChangeAmountOnStdCode(Type: Enum "Service Line Type")
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-PP-SSC-04 - refer to TFS ID 20924.
        // Test that it is not possible to enter, change value in the Amount Excl. VAT field for Standard Service Line with type Cost.

        // 1. Setup: Create a new Standard Service Code with Standard Service Line with type.
        Initialize();
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        if Type = Type::Item then
            CreateStdServiceLineItem(StandardServiceCode.Code);
        if Type = Type::Resource then
            CreateStdServiceLineResource(StandardServiceCode.Code);
        if Type = Type::Cost then
            CreateStdServiceLineCost(StandardServiceCode.Code);

        // 2. Exercise: Change value in the Amount Excl. VAT field for Standard Service Line.
        asserterror StandardServiceLine.Validate("Amount Excl. VAT", LibraryRandom.RandInt(10));  // Required field - value is not important to test case.

        // 3. Verify: Error is generated on updating the Amount Excl. VAT field on Standard Service Line.
        Assert.AreEqual(
          StrSubstNo(
            TypeError, StandardServiceLine.FieldCaption(Type), StandardServiceLine.Type,
            StandardServiceLine.TableCaption(), StandardServiceLine.FieldCaption("Standard Service Code"),
            StandardServiceLine."Standard Service Code", StandardServiceLine.FieldCaption("Line No."), StandardServiceLine."Line No."),
          GetLastErrorText,
          UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteStdCode()
    var
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-PP-SSC-05 - refer to TFS ID 20924.
        // Test that deleting a Standard Service Code, the Standard Service Lines attached are deleted as well.

        // 1. Setup: Create a new Standard Service Code with Standard Service Lines for all Types.
        Initialize();
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);

        // 2. Exercise: Delete the Standard Service Code.
        StandardServiceCode.Delete(true);

        // 3. Verify: Standard Service Code and Standard service lines are deleted.
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceCode.Code);
        Assert.IsFalse(
          StandardServiceLine.FindFirst(),
          StrSubstNo(StdServiceLinesMustNotExist, StandardServiceCode.Code, StandardServiceLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure StdCodeToServiceItemGroup()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        // Covers document number TC-SSC-06 - refer to TFS ID 20924.
        // Test that it is possible to assign Standard Service Codes to a Service Item Group.

        // 1. Setup: Create a new Standard Service Code with Standard Service Lines for all Types.
        Initialize();
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);

        // 2. Exercise: Create a new Service Item Group and assign the Standard Service Code.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        StandardServiceCode2 := StandardServiceCode.Code;
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);

        // 3. Verify: Standard Service Code is assigned to the Service Item Group.
        StandardServiceItemGrCode.Get(ServiceItemGroup.Code, StandardServiceCode.Code);
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure EmptyStdCodeToServiceItemGroup()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        // Covers document number TC-SSC-06 - refer to TFS ID 20924.
        // Test that it is possible to assign Empty Standard Service Codes to a Service Item Group.

        // 1. Setup: Create a new empty Standard Service Code.
        Initialize();
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        // 2. Exercise: Create a new Service Item Group and assign the Standard Service Code.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateStandardServiceItemGr(StandardServiceItemGrCode, ServiceItemGroup.Code, StandardServiceCode.Code);
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        StandardServiceCode2 := StandardServiceCode.Code;
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);

        // 3. Verify: Standard Service Code is assigned to the Service Item Group.
        StandardServiceItemGrCode.Get(ServiceItemGroup.Code, StandardServiceCode.Code);
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        Assert.IsFalse(
          ServiceLine.FindFirst(),
          StrSubstNo(
            ServiceLineMustNotExist, ServiceLine.TableCaption(), ServiceLine.FieldCaption("Document Type"), ServiceLine."Document Type",
            ServiceLine.FieldCaption("Document No."), ServiceLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeWithAssigned()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        StandardServiceCodeItem: Code[10];
        StandardServiceCodeResCost: Code[10];
    begin
        // Covers document number TC-SSC-07 - refer to TFS ID 20924.
        // Test that if the Service Item Group Code field on the Service Item Line contains a Service Item Group Code with the
        // Standard Service Code assigned, then by running the Get Std. Service Codes function it is possible to insert Standard
        // Service Lines attached to any existing Standard Service Code.

        // 1. Setup: Create a new Service Item Group. Create Service Order with Service item line for the Service Item Group Code.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);

        // 2. Exercise: Create Standard Service Code and Run the Get Std. Service Codes function for the Service Item Group Code with
        // Standard Service Code assigned, Run the Get Std. Service Codes function to insert Standard Service Lines attached to
        // any existing Standard Service Code.
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);

        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);
        StandardServiceCodeItem := StandardServiceCode.Code;

        GetStdCodeForResourceCost(StandardServiceCode, ServiceItemLine);
        StandardServiceCodeResCost := StandardServiceCode.Code;
        GetStdCodeForGL(StandardServiceCode, ServiceItemLine);

        // 3. Verify: Service Lines is update with Standard Service Lines attached to existing Standard Service Codes.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCodeItem);
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCodeResCost);
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeWOAssigned()
    var
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCodeResCost: Code[10];
    begin
        // Covers document number TC-SSC-08 - refer to TFS ID 20924.
        // Test that if the Service Item Group Code field on the service item line contains a service item group code without the
        // Standard Service Code assigned, then by running the Get Std. Service Codes function it is possible to insert standard
        // service lines attached to any existing Standard Service Code.

        // 1. Setup: Create a new Service Item Group. Create Service Order with Service item line for the Service Item Group Code.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);

        // 2. Exercise: Run the Get Std. Service Codes function with New Standard Service Code.
        // Run the Get Std. Service Codes function without Service Item Group Code and Assign new Standard Service Code.
        GetStdCodeForResourceCost(StandardServiceCode, ServiceItemLine);
        StandardServiceCodeResCost := StandardServiceCode.Code;
        GetStdCodeForGL(StandardServiceCode, ServiceItemLine);

        // 3. Verify: Service Lines is update with Standard Service Lines attached to existing Standard Service Codes for which
        // Get Std. Service Codes was run.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCodeResCost);
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeNoServiceItemGroup()
    var
        StandardServiceCode: Record "Standard Service Code";
        ServiceItemGroup: Record "Service Item Group";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCodeGL: Code[10];
    begin
        // Covers document number TC-SSC-09 - refer to TFS ID 20924.
        // Test that if the Service Item Group Code field on the service item line is empty, then by running the Get Std. Service Codes
        // function it is possible to insert standard service lines attached to any existing Standard Service Code.

        // 1. Setup: Create a new Service Order. Create a new Service Item Group.
        Initialize();
        CreateServiceOrder(ServiceHeader, ServiceItemLine);
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        // 2. Exercise: Run the Get Std. Service Codes function insert standard service lines attached to the existing
        // Standard Service Code.
        GetStdCodeForGL(StandardServiceCode, ServiceItemLine);
        StandardServiceCodeGL := StandardServiceCode.Code;
        GetStdCodeForResourceCost(StandardServiceCode, ServiceItemLine);

        // 3. Verify: Service Lines is update with Standard Service Lines attached to existing Standard Service Codes for which
        // Get Std. Service Codes was run.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCodeGL);
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeWithContractNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        // Covers document number TC-SSC-10 - refer to TFS ID 20924.
        // Test that if the service item line has the Contract No., the Warranty,  the Fault Reason Code , the Fault Area Code, the Symptom
        // Code, the Fault Code and the Resolution Code field values specified, the Get Std. Service Codes function for this
        // service item line inserts standard service lines attached to any existing Standard Service Code.

        // 1. Setup: Create a new Service Item Group. Create Service Order with Service item line for the Service Item Group Code.
        // Create a new Standard Service Code.
        Initialize();
        PrepareGetStdCodeScenario(ServiceHeader, ServiceItemLine, StandardServiceCode);

        // 2. Exercise: Update the Service Line with Contract No., Warranty, Fault Reason Code, Fault Area Code, Symptom Code
        // Fault Code and the Resolution Code. Run the Get Std. Service Codes on Service Order with new Standard Service Code.
        UpdateServiceItemLine(ServiceItemLine);
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);

        // 3. Verify: Service Line is update with Standard Service Lines attached to existing Standard Service Codes.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeCurrencyDiffHeader()
    var
        Currency: Record Currency;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        // Covers document number TC-SSC-11 - refer to TFS ID 20924.
        // Test that if the Currency Code specified on the Service Header and that assigned to the Standard Service Code are different then
        // it is impossible to run the Get Std. Service Codes function.

        // 1. Setup: Create New Service Item Group, Create a new Service Order with Service Item Line for the Service Item Group.
        // Create a new Standard Service Code.
        Initialize();
        PrepareGetStdCodeScenario(ServiceHeader, ServiceItemLine, StandardServiceCode);

        // 2. Exercise: Update Currency on Service Header.
        LibraryERM.FindCurrency(Currency);
        ServiceHeader.Validate("Currency Code", Currency.Code);
        ServiceHeader.Modify(true);

        // 3. Verify: Error generated for Currency difference on Service Header and Standard Service Code on running Get Std. Service Codes.
        asserterror StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);
        VerifyCurrencyNotMatching(ServiceHeader, StandardServiceCode);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure PostAfterGetStdCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC-SSC-13 - refer to TFS ID 20924.
        // Test that it is possible to post the Service Lines which were inserted by the Get Std. Service Codes function on the
        // service order.

        // 1. Setup: Create New Service Item Group, Create a new Service Order with Service Item Line for the Service Item Group.
        // Run Get Std. Service Codes on the Service Order for the new Standard Service Code.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);
        GetStdCodeForItem(ServiceItemLine);

        // 2. Exercise: Update Quantity, Qty. to Ship and post the Service Order as Ship. Update Qty. to Consume and post the Service
        // Order as Ship and Consume. Update Qty. to Invoice and post the Service Order as Invoice.
        UpdatePartialQtyToShip(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");

        UpdateQtyToConsume(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");

        UpdateQtyToInvoice(ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);

        // 3. Verify: Service Shipment Line and Service Invoice Lines are created with the same Type and No as on Service Line.
        VerifyServiceShipment(ServiceHeader."No.");
        VerifyServiceInvoice(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeOnInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-SSC-14 - refer to TFS ID 20924.
        // Test that by running the Get Std. Service Codes function on Service Invoice it is possible to insert standard service
        // lines attached to any existing standard service code.

        GetStdCodeOnServiceDocument(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeOnCrMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-SSC-17 - refer to TFS ID 20924.
        // Test that by running the Get Std. Service Codes function on Service Credit Memo it is possible to insert standard service
        // lines attached to any existing standard service code.

        GetStdCodeOnServiceDocument(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure GetStdCodeOnServiceDocument(DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        StandardServiceCode: Record "Standard Service Code";
        ServiceItemGroup: Record "Service Item Group";
    begin
        // 1. Setup: Create a new Service Document as per Parameter.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");

        // 2. Exercise: Create Service Item Group Code, Run the Get Std. Service Codes on Service Document for the
        // Standard Service Code.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        CreateStdServiceResourceCost(StandardServiceCode);
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceCode.InsertServiceLines(ServiceHeader);

        // 3. Verify: Service Lines is update with Standard Service Lines attached to existing Standard Service Codes for which
        // Get Std. Service Codes was runs.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeCurrencyDiffInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-SSC-15 - refer to TFS ID 20924.
        // Test that if the currency code specified on the Service Invoice is different from the one assigned to the Standard Service Code,
        // it is impossible to run the Get Std. Service Codes function.

        GetStdCodeCurrencyDiff(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeCurrencyDiffCrMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-SSC-18 - refer to TFS ID 20924.
        // Test that if the currency code on the service header is different from that assigned to the standard service code,
        // it is impossible to run the Get Std. Service Codes function.

        GetStdCodeCurrencyDiff(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Normal]
    local procedure GetStdCodeCurrencyDiff(DocumentType: Enum "Service Document Type")
    var
        Currency: Record Currency;
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
    begin
        // 1. Setup: Create New Service Item Group, Create a new Service Document with Service Item Line as per parameter
        // Create a new Standard Service Code.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        CreateStdServiceResourceCost(StandardServiceCode);
        StandardServiceCode2 := StandardServiceCode.Code;

        // 2. Exercise: Update Currency on Service Header.
        LibraryERM.FindCurrency(Currency);
        ServiceHeader.Validate("Currency Code", Currency.Code);
        ServiceHeader.Modify(true);

        // 3. Verify: Error generated for Currency difference on Service Header and Standard Service Code on running Get Std. Service Codes.
        asserterror StandardServiceCode.InsertServiceLines(ServiceHeader);
        VerifyCurrencyNotMatching(ServiceHeader, StandardServiceCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServContrctTemplateListHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeOnInvoiceForContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
    begin
        // Covers document number TC-SSC-16 - refer to TFS ID 20924.
        // Test that by running the Get Std. Service Codes function on the Contract-related Service Invoice, it is possible to insert
        // Standard Service Lines attached to any existing Standard Service Code.

        // 1. Setup: Create a Service Contract. Sign and Invoice the Service Contract.
        CreateAndSignServiceContract(ServiceContractHeader);

        // 2. Exercise: Create Service Item Group Code. Create Standard Service Code. Run the Get Std. Service Codes on Service Invoice
        // for the Standard Service Code.
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();

        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        CreateStdServiceResourceCost(StandardServiceCode);
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceCode.InsertServiceLines(ServiceHeader);

        // 3. Verify: Service Lines is update with Standard Service Lines attached to existing Standard Service Codes for which
        // Get Std. Service Codes was runs.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServContrctTemplateListHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure GetStdCodeOnCrMemoForContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
    begin
        // Covers document number TC-SSC-19 - refer to TFS ID 20924.
        // Test that by running the Get Std. Service Codes function on the Contract-related Service Credit Memo, it is possible to
        // insert Standard Service Lines attached to any existing Standard Service Code.

        // 1. Setup: Create a Service Contract. Sign and Invoice the Service Contract.
        CreateAndSignServiceContract(ServiceContractHeader);
        Commit();  // Commit is Important to the Test Case.
        // 2. Exercise: Post Service Invoice and create Service Credit Memo from Service Contract.
        // Create Service Item Group Code, Run the Get Std. Service Codes on Service Credit Memo for the Standard Service Code.
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        REPORT.RunModal(REPORT::"Batch Post Service Invoices", false, true, ServiceHeader);
        ServiceContractHeader.Find();
        ModifyServiceContractStatus(ServiceContractHeader);
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.");

        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();

        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        CreateStdServiceResourceCost(StandardServiceCode);
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceCode.InsertServiceLines(ServiceHeader);

        // 3. Verify: Service Lines is update with Standard Service Lines attached to existing Standard Service Codes for which
        // Get Std. Service Codes was runs.
        VerifyServiceLine(ServiceHeader."Document Type", ServiceHeader."No.", StandardServiceCode.Code);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure PostInvoiceAfterGetStdCode()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-SSC-20 - refer to TFS ID 20924.
        // Test that it is possible to post a service invoice with the service lines inserted by the Get Std. Service Codes function.

        PostDocumentAfterGetStdCode(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure PostCrMemoAfterGetStdCode()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC-SSC-21 - refer to TFS ID 20924.
        // Test that it is possible to post a Service Credit Memo with the Service Lines inserted by the Get Std. Service Codes function.

        PostDocumentAfterGetStdCode(ServiceHeader."Document Type"::"Credit Memo");
    end;

    local procedure PostDocumentAfterGetStdCode(DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        ServiceItemGroup: Record "Service Item Group";
    begin
        // 1. Setup: Create Service Document as per parameter. Create Service Item Group Code, Run the Get Std. Service Codes on
        // Service Document for the Standard Service Code.

        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        CreateServiceLinesWithServiceCode(StandardServiceCode, StandardServiceLine);

        // Required field - value is not important to test case.
        UpdateQuantityOnStdServiceLine(StandardServiceLine, StandardServiceCode.Code, LibraryRandom.RandInt(10));

        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceCode.InsertServiceLines(ServiceHeader);

        // 2. Exercise: Post the Service Document.
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Check Service Ledger Entry, Customer Ledger Entries, Detailed Customer Ledger Entries, Resource Leger Entry,
        // VAT Entry and GL entries are created correctly for the posted Service Document.
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice then
            VerifyPostedInvoice(ServiceHeader)
        else
            VerifyPostedCreditMemo(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServContrctTemplateListHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure PostInvoiceContractGetStdCode()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-SSC-20 - refer to TFS ID 20924.
        // Test that it is possible to post a service invoice created for Service Contract with the service lines inserted by the
        // Get Std. Service Codes function.

        // 1. Setup: Create a Service Contract. Sign and Invoice the Service Contract.
        // Create Service Item Group Code. Create Standard Service Code. Run the Get Std. Service Codes on Service Invoice
        // for the Standard Service Code.
        CreateAndSignServiceContract(ServiceContractHeader);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();

        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        CreateServiceLinesWithServiceCode(StandardServiceCode, StandardServiceLine);

        // Required field - value is not important to test case.
        UpdateQuantityOnStdServiceLine(StandardServiceLine, StandardServiceCode.Code, LibraryRandom.RandInt(10));

        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceCode.InsertServiceLines(ServiceHeader);

        // 2. Exercise: Post the Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Check Service Ledger Entry, Customer Ledger Entries, Detailed Customer Ledger Entries, Resource Leger Entry,
        // VAT Entry and GL entries are created correctly for the posted Invoice.
        VerifyPostedInvoice(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ServContrctTemplateListHandler,ModalFormHandlerServItemGroup')]
    [Scope('OnPrem')]
    procedure PostCrMemoContractGetStdCode()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // Covers document number TC-SSC-21 - refer to TFS ID 20924.
        // Test that it is possible to post a Service Credit Memo created for Service Contract with the Service Lines inserted by the
        // Get Std. Service Codes function.

        // 1. Setup: Create a Service Contract. Sign and Invoice the Service Contract.
        CreateAndSignServiceContract(ServiceContractHeader);
        Commit();  // Commit is Important to the Test Case.

        // 2. Exercise: Post Service Invoice and create Service Credit Memo from Service Contract.
        // Create Service Item Group Code, Run the Get Std. Service Codes on Service Credit Memo for the Standard Service Code.
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        REPORT.RunModal(REPORT::"Batch Post Service Invoices", false, true, ServiceHeader);
        ServiceContractHeader.Find();
        ModifyServiceContractStatus(ServiceContractHeader);
        CreateServiceCreditMemo(ServiceContractHeader."Contract No.");

        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::"Credit Memo");
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();

        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;

        CreateServiceLinesWithServiceCode(StandardServiceCode, StandardServiceLine);

        // Required field - value is not important to test case.
        UpdateQuantityOnStdServiceLine(StandardServiceLine, StandardServiceCode.Code, LibraryRandom.RandInt(10));

        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceCode.InsertServiceLines(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Check Service Ledger Entry, Customer Ledger Entries, Detailed Customer Ledger Entries, Resource Leger Entry, VAT Entry
        // and GL entries are created correctly for the posted Credit Memo.
        VerifyPostedCreditMemo(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteStandardServiceItemGroupCode()
    var
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        StandardServiceCode: Record "Standard Service Code";
    begin
        // Check that Standard Service Code still exists after deleting a related Standard Service Item Group Code.

        // 1. Setup: Create Service Item Group, Standard Service Code and group them using Standard Service Item Group.
        Initialize();
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        LibraryService.CreateStandardServiceItemGr(StandardServiceItemGrCode, ServiceItemGroup.Code, StandardServiceCode.Code);

        // 2. Exercise: Delete Standard Service Item Group having Standard Service Code attached.
        StandardServiceItemGrCode.Delete(true);

        // 3. Verify: Verify that after deleting Standard Service Item Group, Standard Service Code still exists.
        StandardServiceCode.Get(StandardServiceCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteStandardServiceItemGrCode()
    var
        StandardServiceItemGrCode1: Record "Standard Service Item Gr. Code";
        StandardServiceItemGrCode2: Record "Standard Service Item Gr. Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277472] Standart Service Line must be deleted after deleting a related Standard Service Item Gr. Code
        Initialize();

        // [GIVEN] Two Standard Service Item Gr. Code "SIGR1" and "SIGR2"
        // [GIVEN] Two Standard Service Line "SSL1" and "SSL2" for "SIGR1" and "SIGR2" respectively
        CreateStdServiceItemGrCodeWithStdServiceLine(StandardServiceItemGrCode1);
        CreateStdServiceItemGrCodeWithStdServiceLine(StandardServiceItemGrCode2);

        // [WHEN] Delete the first Standard Service Item Gr. Code - "SIGR1"
        StandardServiceItemGrCode1.Delete(true);

        // [THEN] "SIGR1" is deleted
        Assert.IsFalse(StandardServiceItemGrCode1.Find(), 'The Standard Service Item Gr. Code must be deleted');

        // [THEN] "SSL1" is deleted
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceItemGrCode1.Code);
        Assert.RecordIsNotEmpty(StandardServiceLine);

        // [THEN] "SIGR2" is exist
        Assert.IsTrue(StandardServiceItemGrCode2.Find(), 'The Standard Service Item Gr. Code must exist');

        // [THEN] "SSL2" is exist
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceItemGrCode2.Code);
        Assert.RecordIsNotEmpty(StandardServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StandardServiceLineNonInventoryTypeItem()
    var
        Item: Record Item;
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // [FEATURE] [UT] [Item] [Non-Inventory]
        // [SCENARIO 318744] Validate No. in Standard Service Line with Non-inventory type Item
        Initialize();

        // [GIVEN] Item with Non-Inventory type
        LibraryInventory.CreateNonInventoryTypeItem(Item);

        // [GIVEN] Standard Service Code with Item type Line
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);

        // [WHEN] Validate No. = Item "No." in the Line
        StandardServiceLine.Validate("No.", Item."No.");

        // [THEN] No. = Item "No." in the Line
        StandardServiceLine.TestField("No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerServItemGroup')]
    procedure ReservationEntryMustBeCreatedWhenReserveIsAlwaysInServiceLine()
    var
        Item: Record Item;
        Location: Record Location;
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        ExpectedQuantity: Integer;
    begin
        // [SCENARIO 566581] Verify Reservation Entry must be created When Item that has Reserve = Always in the Service Line.
        // when "Get Std. Service Codes." is executed.
        Initialize();

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create an item with Reserve = Always.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify();

        // [GIVEN] Generate Quantity.
        ExpectedQuantity := LibraryRandom.RandInt(20);

        // [GIVEN] Post inventory.
        SetItemInventory(Item, ExpectedQuantity, Location.Code);

        // [GIVEN] Create Service Item.
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");

        // [GIVEN] Create Standard Service Code with Item and Quantity.
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineWithItem(StandardServiceCode.Code, Item."No.", ExpectedQuantity);

        // [GIVEN] Create Service Order with Location.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Location Code", Location.Code);
        ServiceHeader.Modify();

        // [GIVEN] Create Service Item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // [GIVEN] Delete Standard Service Group Code.
        StandardServiceItemGrCode.DeleteAll();

        // [WHEN] Insert Service Line through Standard Service Code.
        ServiceItemGroupCode2 := '';
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);

        // [THEN] Verify "Reserved Qty. (Base)" must be updated in the Service Line.
        FindServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceLine.CalcFields("Reserved Qty. (Base)");
        Assert.AreEqual(
            ExpectedQuantity,
            ServiceLine."Reserved Qty. (Base)",
            StrSubstNo(ValueMustBeEqualErr, ServiceLine.FieldCaption("Reserved Qty. (Base)"), ExpectedQuantity, ServiceLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Standard Codes");
        Clear(LibraryService);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Standard Codes");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountsInServiceContractAccountGroups();
        LibraryERMCountryData.UpdateAccountInServiceCosts();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryService.SetupServiceMgtNoSeries();
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Standard Codes");
    end;

    local procedure CalcTotalAmtShippedLineCrMemo(PreAssignedNo: Code[20]) TotalAmount: Decimal
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindSet();
        repeat
            TotalAmount += -ServiceCrMemoLine."Amount Including VAT";
        until ServiceCrMemoLine.Next() = 0;
    end;

    local procedure CalcTotalAmtShippedLineInvoice(PreAssignedNo: Code[20]) TotalAmount: Decimal
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindSet();
        repeat
            TotalAmount += ServiceInvoiceLine."Amount Including VAT";
        until ServiceInvoiceLine.Next() = 0;
    end;

    [Normal]
    local procedure CreateAndSignServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        Customer: Record Customer;
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Create Service Item, Service Contract Header, Service Contract Line. Sign and Invoice the Service Contract.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    [Normal]
    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceContractLine.Modify(true);
    end;

    [Normal]
    local procedure CreateServiceCreditMemo(ContractNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindFirst();
        LibraryService.CreateContractLineCreditMemo(ServiceContractLine, true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
    end;

    local procedure CreateStdServiceResourceCost(var StandardServiceCode: Record "Standard Service Code")
    begin
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
    end;

    local procedure CreateStdServiceLineCost(StandardServiceCode: Code[10])
    var
        ServiceCost: Record "Service Cost";
        StandardServiceLine: Record "Standard Service Line";
    begin
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode);
        ServiceCost.SetRange("Service Zone Code", '');
        LibraryService.FindServiceCost(ServiceCost);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Cost);
        StandardServiceLine.Validate("No.", ServiceCost.Code);
        StandardServiceLine.Modify(true);
    end;

    local procedure CreateStdServiceLineGL(var StandardServiceLine: Record "Standard Service Line"; StandardServiceCode: Code[10])
    begin
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::"G/L Account");
        StandardServiceLine.Validate("No.", LibraryERM.CreateGLAccountWithSalesSetup());
        StandardServiceLine.Modify(true);
    end;

    local procedure CreateStdServiceLineItem(StandardServiceCode: Code[10])
    var
        StandardServiceLine: Record "Standard Service Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);
        StandardServiceLine.Validate("No.", LibraryInventory.CreateItemNo());
        StandardServiceLine.Modify(true);
    end;

    local procedure CreateStdServiceLineResource(StandardServiceCode: Code[10])
    var
        StandardServiceLine: Record "Standard Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Resource);
        StandardServiceLine.Validate("No.", LibraryResource.CreateResourceNo());
        StandardServiceLine.Modify(true);
    end;

    local procedure CreateServiceLinesWithServiceCode(var StandardServiceCode: Record "Standard Service Code"; var StandardServiceLine: Record "Standard Service Line")
    begin
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);
    end;

    local procedure CreateStdServiceItemGrCodeWithStdServiceLine(var StandardServiceItemGrCode: Record "Standard Service Item Gr. Code")
    var
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceCode: Record "Standard Service Code";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        LibraryService.CreateStandardServiceItemGr(StandardServiceItemGrCode, ServiceItemGroup.Code, StandardServiceCode.Code);
        CreateStdServiceLineItem(StandardServiceCode.Code);
    end;

    [Normal]
    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Line Type"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
    end;

    local procedure GetStdCodeForGL(var StandardServiceCode: Record "Standard Service Code"; var ServiceItemLine: Record "Service Item Line")
    var
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);
    end;

    local procedure GetStdCodeForItem(ServiceItemLine: Record "Service Item Line")
    var
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        StandardServiceCode: Record "Standard Service Code";
    begin
        LibraryService.CreateStandardServiceCode(StandardServiceCode);
        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);
    end;

    local procedure GetStdCodeForResourceCost(var StandardServiceCode: Record "Standard Service Code"; var ServiceItemLine: Record "Service Item Line")
    var
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        CreateStdServiceResourceCost(StandardServiceCode);
        StandardServiceCode2 := StandardServiceCode.Code;
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);
    end;

    [Normal]
    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    [Normal]
    local procedure ModifyServiceContractStatus(var ServiceContractHeader: Record "Service Contract Header")
    var
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Find();
        ServiceContractHeader.Validate("Expiration Date", WorkDate());
        ServiceContractHeader.Modify(true);
    end;

    local procedure PrepareGetStdCodeScenario(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var StandardServiceCode: Record "Standard Service Code")
    var
        ServiceItemGroup: Record "Service Item Group";
        StandardServiceLine: Record "Standard Service Line";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        CreateServiceOrder(ServiceHeader, ServiceItemLine);

        ServiceItemGroupCode2 := ServiceItemGroup.Code;
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        CreateStdServiceLineItem(StandardServiceCode.Code);
        CreateStdServiceLineResource(StandardServiceCode.Code);
        CreateStdServiceLineCost(StandardServiceCode.Code);
        CreateStdServiceLineGL(StandardServiceLine, StandardServiceCode.Code);
        StandardServiceCode2 := StandardServiceCode.Code;
    end;

    local procedure UpdatePartialQtyToShip(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQtyToConsume(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        repeat
            ServiceLine.Validate("Qty. to Consume", ServiceLine."Qty. to Ship");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQtyToInvoice(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        repeat
            ServiceLine.Validate(
              "Qty. to Invoice",
              (ServiceLine."Quantity Shipped" - ServiceLine."Quantity Consumed") * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQuantityOnStdServiceLine(var StandardServiceLine: Record "Standard Service Line"; StandardServiceCode: Code[10]; Quantity: Decimal)
    begin
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceCode);
        StandardServiceLine.FindSet();
        repeat
            StandardServiceLine.Validate(Quantity, Quantity);
            StandardServiceLine.Modify(true);
        until StandardServiceLine.Next() = 0;
    end;

    local procedure UpdateServiceItemLine(var ServiceItemLine: Record "Service Item Line")
    var
        FaultReasonCode: Record "Fault Reason Code";
        FaultCode: Record "Fault Code";
        ResolutionCode: Record "Resolution Code";
    begin
        // Update the Service Line with Contract No., Warranty, Fault Reason Code, Fault Area Code, Symptom Code Fault Code and
        // Resolution Code.
        FaultReasonCode.FindFirst();
        FaultCode.FindFirst();
        ResolutionCode.FindFirst();
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Validate("Fault Reason Code", FaultReasonCode.Code);
        ServiceItemLine.Validate("Fault Area Code", FaultCode."Fault Area Code");
        ServiceItemLine.Validate("Symptom Code", FaultCode."Symptom Code");
        ServiceItemLine.Validate("Fault Code", FaultCode.Code);
        ServiceItemLine.Validate("Resolution Code", ResolutionCode.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.TestField("Posting Date", PostingDate);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDetailedCustLedgerEntry(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; TotalAmount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindSet();
        repeat
            DetailedCustLedgEntry.TestField(Amount, TotalAmount);
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryCrMemo(PreAssignedNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        GLEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source Type", GLEntry."Source Type"::Customer);
            GLEntry.TestField("Source No.", ServiceCrMemoHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceCrMemoHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryInvoice(PreAssignedNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source Type", GLEntry."Source Type"::Customer);
            GLEntry.TestField("Source No.", ServiceInvoiceHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyPostedCreditMemo(ServiceHeader: Record "Service Header")
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();

        VerifyServiceLedgerEntry(ServiceHeader."Document Type", ServiceCrMemoHeader."No.", ServiceHeader."Customer No.");
        VerifyCustomerLedgerEntry(ServiceHeader."Document Type", ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Posting Date");
        VerifyDetailedCustLedgerEntry(
          ServiceHeader."Document Type", ServiceCrMemoHeader."No.", CalcTotalAmtShippedLineCrMemo(ServiceHeader."No."));
        VerifyResourceEntryCrMemo(ServiceHeader."No.");
        VerifyVATEntry(ServiceHeader."Document Type", ServiceCrMemoHeader."No.", ServiceCrMemoHeader."Posting Date");
        VerifyGLEntryCrMemo(ServiceHeader."No.");
    end;

    local procedure VerifyPostedInvoice(ServiceHeader: Record "Service Header")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();

        VerifyServiceLedgerEntry(ServiceHeader."Document Type", ServiceInvoiceHeader."No.", ServiceHeader."Customer No.");
        VerifyCustomerLedgerEntry(ServiceHeader."Document Type", ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date");
        VerifyDetailedCustLedgerEntry(
          ServiceHeader."Document Type", ServiceInvoiceHeader."No.", CalcTotalAmtShippedLineInvoice(ServiceHeader."No."));
        VerifyResourceEntryInvoice(ServiceHeader."No.");
        VerifyVATEntry(ServiceHeader."Document Type", ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Posting Date");
        VerifyGLEntryInvoice(ServiceHeader."No.");
    end;

    local procedure VerifyQuantityAmountOnBlank(StandardServiceLine: Record "Standard Service Line"; StandardServiceCode: Code[10])
    begin
        // Required field - value is not important to test case.
        asserterror UpdateQuantityOnStdServiceLine(StandardServiceLine, StandardServiceCode, LibraryRandom.RandInt(10));
        Assert.AreEqual(
          StrSubstNo(
            TypeErrorServiceTier, StandardServiceLine.FieldCaption(Type), StandardServiceLine.Type,
            StandardServiceLine.TableCaption(), StandardServiceLine.FieldCaption("Standard Service Code"),
            StandardServiceLine."Standard Service Code", StandardServiceLine.FieldCaption("Line No."), StandardServiceLine."Line No."),
          GetLastErrorText,
          UnknownError);

        asserterror StandardServiceLine.Validate("Amount Excl. VAT", LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
        VerifyStandardServiceLineType(StandardServiceLine);
    end;

    local procedure VerifyQuantityOnStdServiceLine(StandardServiceCode: Code[10]; Quantity: Decimal)
    var
        StandardServiceLine: Record "Standard Service Line";
    begin
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceCode);
        StandardServiceLine.FindSet();
        repeat
            StandardServiceLine.TestField(Quantity, Quantity);
        until StandardServiceLine.Next() = 0;
    end;

    local procedure VerifyResourceEntryCrMemo(PreAssignedNo: Code[20])
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.SetRange(Type, ServiceCrMemoLine.Type::Resource);
        ServiceCrMemoLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceCrMemoLine."Document No.");
        ResLedgerEntry.SetRange("Entry Type", ResLedgerEntry."Entry Type"::Sale);
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, ServiceCrMemoLine.Quantity);
        ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
        ResLedgerEntry.TestField("Order No.", PreAssignedNo);
        ResLedgerEntry.TestField("Order Line No.", ServiceCrMemoLine."Line No.");
    end;

    local procedure VerifyResourceEntryInvoice(PreAssignedNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Resource);
        ServiceInvoiceLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, -ServiceInvoiceLine.Quantity);
        ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
        ResLedgerEntry.TestField("Order No.", PreAssignedNo);
        ResLedgerEntry.TestField("Order Line No.", ServiceInvoiceLine."Line No.");
    end;

    local procedure VerifyCurrencyNotMatching(ServiceHeader: Record "Service Header"; StandardServiceCode: Record "Standard Service Code")
    begin
        Assert.AreEqual(
          StrSubstNo(
            CurrencyNotMatching, StandardServiceCode.FieldCaption("Currency Code"),
            ServiceHeader.FieldCaption("Currency Code"), ServiceHeader.TableCaption()),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyServiceInvoice(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        // Verify that the values of the fields Type and No. of Service Invoice Line are equal to the value of the
        // field Type and No. of the relevant Service Line.
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceInvoiceHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", ServiceLine."Line No.");
            ServiceInvoiceLine.TestField(Type, ServiceLine.Type);
            ServiceInvoiceLine.TestField("No.", ServiceLine."No.");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", DocumentType);
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        ServiceLedgerEntry.FindSet();
        repeat
            ServiceLedgerEntry.TestField("Customer No.", CustomerNo);
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure VerifyServiceLine(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; StandardServiceCode: Code[10])
    var
        StandardServiceLine: Record "Standard Service Line";
        ServiceLine: Record "Service Line";
    begin
        StandardServiceLine.SetRange("Standard Service Code", StandardServiceCode);
        StandardServiceLine.FindSet();
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        repeat
            ServiceLine.SetRange(Type, StandardServiceLine.Type);
            ServiceLine.SetRange("No.", StandardServiceLine."No.");
            ServiceLine.FindFirst();
            ServiceLine.TestField(Quantity, StandardServiceLine.Quantity);
        until StandardServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceShipment(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the values of the fields Type and No. of Service Shipment Line are equal to the value of the
        // field Type and No. of the relevant Service Line.
        FindServiceLine(ServiceLine, ServiceLine."Document Type"::Order, DocumentNo);
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        repeat
            ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
            ServiceShipmentLine.FindFirst();
            ServiceShipmentLine.TestField(Type, ServiceLine.Type);
            ServiceShipmentLine.TestField("No.", ServiceLine."No.");
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyStandardServiceLineType(StandardServiceLine: Record "Standard Service Line")
    begin
        Assert.AreEqual(
          StrSubstNo(
            TypeError, StandardServiceLine.FieldCaption(Type), StandardServiceLine.Type,
            StandardServiceLine.TableCaption(), StandardServiceLine.FieldCaption("Standard Service Code"),
            StandardServiceLine."Standard Service Code", StandardServiceLine.FieldCaption("Line No."), StandardServiceLine."Line No."),
          GetLastErrorText,
          UnknownError);
    end;

    local procedure VerifyVATEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure SetItemInventory(Item: Record Item; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify();

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateStdServiceLineWithItem(StandardServiceCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        StandardServiceLine: Record "Standard Service Line";
    begin
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode);
        StandardServiceLine.Validate(Type, StandardServiceLine.Type::Item);
        StandardServiceLine.Validate("No.", ItemNo);
        StandardServiceLine.Validate(Quantity, Quantity);
        StandardServiceLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerServItemGroup(var StandardServItemGrCodes: Page "Standard Serv. Item Gr. Codes"; var Response: Action)
    var
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        LibraryService.CreateStandardServiceItemGr(StandardServiceItemGrCode, ServiceItemGroupCode2, StandardServiceCode2);
        StandardServItemGrCodes.SetRecord(StandardServiceItemGrCode);
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageTest: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServContrctTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;
}

