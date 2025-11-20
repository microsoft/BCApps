// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Service.Analysis;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;
using Microsoft.TestLibraries.Foundation.NoSeries;

codeunit 136110 "Service Management Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service]
        isInitialized := false;
        ServiceOrderAllocation.Init();
    end;

    var
        ServiceOrderAllocation: Record "Service Order Allocation";
        Resource: Record Resource;
        FaultResolCodRelationship2: Record "Fault/Resol. Cod. Relationship";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        Question: Label 'Force confirm ?';
        FieldLengthErr: Label 'The length of the Field ''%1'' must be more or equal to %2';
        UseContractTemplateConfirm: Label 'Do you want to create the contract using a contract template?';
        ResourceNotQualifiedError: Label '%1 %2 %3 is not qualified to carry out the service.';
        UnknownError: Label 'Unknown error.';
        FaultReportingLevelNoneError: Label 'You cannot use %1, because the %2 in the %3 table is %4.';
        ResponseTimeMoreThanYearError: Label 'The %1 for this %2 occurs in more than 1 year. Please verify the setting for service hours and the %3 for the %4.';
        WarrantyDurationNegativeError: Label 'Default warranty duration is negative. The warranty cannot be activated.';
        ContractChangeLogError: Label '%1 must be empty for %2 %3.';
        ContractCancellationQuestion: Label 'It is not possible to change a service contract to its previous status.\\Do you want to cancel the contract?';
        DateRangeError: Label 'The date range you have entered is a longer period than is allowed in the %1 table.';
        LineDiscountPerError: Label 'Line Discount % field have different values.';
        ServiceInvoiceMassage: Label 'Service Invoice ';
        ZeroOrderCreated: Label '0 service order was created.';
        UnexpectedMessage: Label 'Unknown message %1.';
        ServiceOrderError: Label '%1 must not exist for %2 %3=%4.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Management Setup");
        Clear(FaultResolCodRelationship2);
        Clear(LibraryService);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Management Setup");

        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibraryERMCountryData.CreateVATData();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Management Setup");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestPlannedNextServCalcMethod()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        SetupModified: Boolean;
    begin
        // Covers document number TC0108 - refer to TFS ID 21727.
        // 1. Setup Next Service Calc. Method in Service Management Setup as Planned.
        // 2. Create and Sign a Prepaid Service Contract with any Customer.
        // 3. Create and post a Service Order - Service Header with Contract No. as No. of Service Contract Header, Service Item Lines and
        // Service Lines.
        // 4. Verify that the Next Planned Date in Service Line is obtained by adding Service Period of the Service Contract Header to the
        // Starting Date of the Service Contract Header.
        // 5. Cleanup if Setup was changed.

        // Setup: Setup Next Service Calc. Method in Service Management Setup as Planned. Create and sign Service Contract.
        Initialize();
        SetupModified := SetupServiceMgtSetupPlanned();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Exercise: Create and Post Service Order as Ship and Invoice with Contract No. as No. of Service Contract Header.
        CreateAndPostServiceOrderForResource(
          ServiceHeader, ServiceContractLine, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract No.", true);

        // Verify: Check that the Next Planned Date in Service Line is obtained by adding Service Period of the Service Contract Header to
        // the Starting Date of the Service Contract Header.
        VerifyPlannedNextServCalcMthod(ServiceContractHeader);

        // Cleanup: If the Next Service Calc. Method in Service Management Setup was changed then cleanup.
        if SetupModified then
            SetupServiceMgtSetupActual();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestActualNextServCalcMethod()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        SetupModified: Boolean;
    begin
        // Covers document number TC0108 - refer to TFS ID 21727.
        // 1. Setup Next Service Calc. Method in Service Management Setup as Actual.
        // 2. Create and Sign a Prepaid Service Contract with any Customer.
        // 3. Create and post a Service Order - Service Header with Contract No. as No. of Service Contract Header, Service Item Lines and
        // Service Lines.
        // 4. Verify that the Next Planned Date in Service Line is obtained by adding Service Period of the Service Contract Header to the
        // Last Service Date of the Service Contract Line.
        // 5. Cleanup if Setup was changed.

        // Setup: Setup Next Service Calc. Method in Service Management Setup as Actual. Create and sign Service Contract.
        Initialize();
        SetupModified := SetupServiceMgtSetupActual();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Exercise: Create and Post Service Order with Contract No. as No. of Service Contract Header.
        CreateAndPostServiceOrderForResource(
          ServiceHeader, ServiceContractLine, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract No.", true);

        // Verify: Check that the Next Planned Date in Service Line is obtained by adding Service Period of the Service Contract Header to
        // the Last Service Date of the Service Contract Line.
        VerifyActualNextServCalcMthod(ServiceContractLine, ServiceContractHeader."Service Period");

        // Cleanup: If the Next Service Calc. Method in Service Management Setup was changed then cleanup.
        if SetupModified then
            SetupServiceMgtSetupPlanned();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestServiceLineStartFee()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        // Covers document number TC0109 - refer to TFS ID 21727.
        // 1. If Service Order Starting Fee of Service Management Setup is blank then create a new Service Cost and input in the field.
        // 2. Create a new Service Order - Service Header and Service Line.
        // 3. Add starting fee to the Service Line by Insert Starting Fee function.
        // 4. Verify that the values on the Service Line correspond to the values of the Service Cost entered in the Service Mgt. Setup.

        // Setup: Setup Service Order Starting Fee of Service Management Setup. Create a new Service Order - Service Header, Service Line.
        Initialize();
        ExecuteConfirm();
        SetupServiceMgtStartingFee(ServiceCost);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // Exercise: Add starting fee to the Service Line by Insert Starting Fee function.
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Init();
        ServOrderManagement.InsertServCost(ServiceLine, 1, false);

        // Verify: Check that values on the Service Line correspond to the values of the Service Cost entered in the Service Mgt. Setup.
        VerifyServiceLineStartingFee(ServiceHeader, ServiceCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceLineStartFeeBlank()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceSetup: Record "Service Mgt. Setup";
        ServOrderManagement: Codeunit ServOrderManagement;
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0109 - refer to TFS ID 21727.
        // 1. Input Service Order Starting Fee of Service Management Setup as blank.
        // 2. Create a new Service Order - Service Header and Service Line.
        // 3. Add starting fee to the Service Line by Insert Starting Fee function.
        // 4. Verify that the application generates an error if Starting Fee has not been specified in Service Management Setup.

        // Setup: Setup Service Order Starting Fee of Service Management Setup. Create a new Service Order - Service Header, Service Line.
        Initialize();
        SetupServiceMgtStartngFeeBlank();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // Exercise: Add starting fee to the Service Line by Insert Starting Fee function.
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Init();
        asserterror ServOrderManagement.InsertServCost(ServiceLine, 1, false);

        // Verify: Check that the application generates an error if Starting Fee has not been specified in Service Management Setup.
        Assert.ExpectedTestFieldError(ServiceSetup.FieldCaption("Service Order Starting Fee"), '');
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler')]
    [Scope('OnPrem')]
    procedure TestResSkillWrngDisplayedError()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option as Warning Displayed in Service Management Setup and Service Zones Option as Code Shown.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application generates an error if the Resource is not qualified to carry the Service.

        // Setup: Input Resource Skills Option as Warning Displayed in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned.
        Initialize();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Warning Displayed", ServiceMgtSetup."Service Zones Option"::"Code Shown");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);
        Commit();

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        asserterror ServiceOrderSubform.Run();

        // Verify: Check that the application generates an error if the Resource is not qualified to carry the Service.
        Assert.AreEqual(
          StrSubstNo(ResourceNotQualifiedError, Resource.TableCaption(), Resource.FieldCaption("No."), Resource."No."),
          GetLastErrorText, UnknownError);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 0);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler')]
    [Scope('OnPrem')]
    procedure TestResSkillWrngDisplayedAlloc()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option as Warning Displayed in Service Management Setup and Service Zones Option as Code Shown.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application allows Resource allocation if Resource is qualified to carry the Service.

        // Setup: Input Resource Skills Option as Warning Displayed in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned. Assign the Skill Code to Resource.
        Initialize();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Warning Displayed", ServiceMgtSetup."Service Zones Option"::"Code Shown");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::Resource, Resource."No.", SkillCode.Code);

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.Run();

        // Verify: Check that the application allows Resource allocation if Resource is qualified to carry the Service.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCodeShownConfirmAlloc()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option as Code Shown in Service Management Setup and Service Zones Option as Warning Displayed.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application generates a confirmation message and allows resource to be allocated if the Resource is not
        // qualified to carry the Service.

        // Setup: Input Resource Skills Option as Code Shown in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned.
        Initialize();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Code Shown", ServiceMgtSetup."Service Zones Option"::"Warning Displayed");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.Run();
        ExecuteConfirm();

        // Verify: Check that the application allows the Resource to be allocated if the Resource is not qualified to carry the Service.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler')]
    [Scope('OnPrem')]
    procedure TestBothCodeShownConfirmAlloc()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option as Code Shown in Service Management Setup and Service Zones Option as Code Shown.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application generates a confirmation message and allows resource to be allocated if the Resource is not
        // qualified to carry the Service.

        // Setup: Input Resource Skills Option as Code Shown in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned.
        Initialize();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Code Shown", ServiceMgtSetup."Service Zones Option"::"Code Shown");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.Run();

        // Verify: Check that the application allows the Resource to be allocated if the Resource is not qualified to carry the Service.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler')]
    [Scope('OnPrem')]
    procedure TestBothWrngDisplayedError()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option and Service Zones Option as Warning Displayed in Service Management Setup.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application generates an error if the Resource is not qualified to carry the Service.

        // Setup:Input Resource Skills Option as Warning Displayed in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned.
        Initialize();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Warning Displayed", ServiceMgtSetup."Service Zones Option"::"Warning Displayed");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);
        Commit();

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        asserterror ServiceOrderSubform.Run();

        // Verify: Check that the application generates an error if the Resource is not qualified to carry the Service.
        Assert.AreEqual(
          StrSubstNo(ResourceNotQualifiedError, Resource.TableCaption(), Resource.FieldCaption("No."), Resource."No."),
          GetLastErrorText, UnknownError);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 0);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestBothWrngDisplayedAlloc()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option and Service Zones Option as Warning Displayed in Service Management Setup.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application allows Resource allocation if Resource is qualified to carry the Service.

        // Setup: Input Resource Skills Option as Warning Displayed in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned. Assign the Skill Code to Resource.
        Initialize();
        ExecuteConfirm();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Warning Displayed", ServiceMgtSetup."Service Zones Option"::"Warning Displayed");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::Resource, Resource."No.", SkillCode.Code);

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.Run();

        // Verify: Check that the application allows Resource allocation if Resource is qualified to carry the Service.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformFormHandler,ResourceAllocationsFormHandler,ResAvailabilityModlFormHandler')]
    [Scope('OnPrem')]
    procedure TestBothNotUsedAlloc()
    var
        ServiceHeader: Record "Service Header";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceOrderSubform: Page "Service Order Subform";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0110 - refer to TFS ID 21727.
        // 1. Input Resource Skills Option and Service Zones Option as Not Used in Service Management Setup.
        // 2. Create a new Service Order - Service Item with new Resource Skill assigned, Service Header and Service Item Line.
        // 3. Allocate Resource to the Service Line by calling Resource Allocations from the Service Item Line.
        // 4. Verify that the application allows Resource allocation if Resource is qualified to carry the Service.

        // Setup: Input both Options as Not Used in Service Management Setup. Create a new Service Order - Service
        // Header, Service Item Line, Service Line having Service Item with Resource Skill assigned. Assign the Skill Code to Resource.
        Initialize();
        SetupServiceMgtResSkillServZon(
          ServiceMgtSetup."Resource Skills Option"::"Not Used", ServiceMgtSetup."Service Zones Option"::"Not Used");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.", SkillCode.Code);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::Resource, Resource."No.", SkillCode.Code);

        // Exercise: Allocate Resource to the Service Line.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Line No.", ServiceItemLine."Line No.");
        ServiceOrderSubform.SetTableView(ServiceItemLine);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.Run();

        // Verify: Check that the application allows Resource allocation if Resource is qualified to carry the Service.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", 1);  // One Resource should be allocated.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFaultReportingNoneError()
    var
        FaultCode: Record "Fault Code";
        FaultArea: Record "Fault Area";
        SymptomCode: Record "Symptom Code";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Covers document number TC0111 - refer to TFS ID 21727.
        // 1. Input Fault Reporting Level as None in Service Management Setup. Find Fault Area and Symptom Code.
        // 2. Try to insert a Fault Code record with Fault Code as not blank.
        // 3. Verify that the application generates an error on insertion of Fault Code record if Fault Reporting Level is set to None.

        // Setup: Input Fault Reporting Level as None in Service Management Setup.
        SetupServiceFaultReporting(ServiceMgtSetup, ServiceMgtSetup."Fault Reporting Level"::None);

        LibraryService.CreateFaultArea(FaultArea);
        LibraryService.CreateSymptomCode(SymptomCode);

        // Exercise: Insert Fault Code.
        asserterror LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);

        // Verify: Check that the application generates an error on insertion of Fault Code record if Fault Reporting Level is set to None.
        Assert.AreEqual(
          StrSubstNo(FaultReportingLevelNoneError, FaultCode.TableCaption(), ServiceMgtSetup.FieldCaption("Fault Reporting Level"),
            ServiceMgtSetup.TableCaption(), Format(ServiceMgtSetup."Fault Reporting Level")), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestFaultReportingFault()
    var
        FaultCode: Record "Fault Code";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
        FaultResolRelationCalculate: Codeunit "FaultResolRelation-Calculate";
    begin
        // Covers document number TC0111 - refer to TFS ID 21727.
        // 1. Input Fault Reporting Level as Fault in Service Management Setup.
        // 2. Insert a Fault Code record with Fault Code with Fault Area Code and Symptom Code as blank.
        // 3. Create a Service order - Service Item with Service Item Group, Service Item Line with Fault and Resolution, Service Line.
        // 4. Post the Service Order and insert Fault/Resolution relationships.
        // 5. Verify that the values in the Fault Resolution Codes Relationship correspond to the values in the Fault Code record.

        // Setup: Input Fault Reporting Level as Fault in Service Management Setup. Insert Fault Code, Service Header, Service Item Line,
        // Service line.
        SetupServiceFaultReporting(ServiceMgtSetup, ServiceMgtSetup."Fault Reporting Level"::Fault);
        ExecuteConfirm();
        LibraryService.CreateFaultCode(FaultCode, '', '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceItemLineForFault(ServiceItemLine, ServiceHeader, FaultCode);

        ServiceCost.SetFilter("Unit of Measure Code", '<>''''');
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);

        // Exercise: Post Service Order as Ship and insert Fault/Resolution relationships by calling codeunit FaultResolRelationCalculate.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FaultResolRelationCalculate.CopyResolutionRelationToTable(WorkDate(), WorkDate(), true, true);

        // Verify: Check that the values in the Fault Resolution Codes Relationship correspond to the values in the Fault Code record.
        FaultResolCodRelationship.SetRange("Fault Code", FaultCode.Code);
        FaultResolCodRelationship.SetRange("Resolution Code", ServiceItemLine."Resolution Code");
        FaultResolCodRelationship.FindFirst();
        FaultResolCodRelationship.TestField("Fault Area Code", '');
        FaultResolCodRelationship.TestField("Symptom Code", '');
        FaultResolCodRelationship.TestField("Service Item Group Code", ServiceItemLine."Service Item Group Code");
        FaultResolCodRelationship.TestField(Occurrences, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestFaultReportingFaultSymptom()
    var
        FaultCode: Record "Fault Code";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
        FaultArea: Record "Fault Area";
        SymptomCode: Record "Symptom Code";
        FaultResolRelationCalculate: Codeunit "FaultResolRelation-Calculate";
    begin
        // Covers document number TC0111 - refer to TFS ID 21727.
        // 1. Input Fault Reporting Level as Fault+Symptom+Area (IRIS) in Service Management Setup.
        // 2. Insert a Fault Code record with Fault Code with Fault Area Code and Symptom Code as blank.
        // 3. Create a Service order - Service Item with Service Item Group, Service Item Line with Fault and Resolution, Service Line.
        // 4. Post the Service Order and insert Fault/Resolution relationships.
        // 5. Verify that the values in the Fault Resolution Codes Relationship correspond to the values in the Fault Code record.

        // Setup: Input Fault Reporting Level as Fault+Symptom+Area (IRIS) in Service Management Setup. Insert Fault Code,
        // Service Header, Service Item Line, Service Line.
        LibraryService.CreateFaultArea(FaultArea);
        LibraryService.CreateSymptomCode(SymptomCode);
        SetupServiceFaultReporting(ServiceMgtSetup, ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)");
        ExecuteConfirm();
        LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceItemLineForFault(ServiceItemLine, ServiceHeader, FaultCode);

        ServiceCost.SetFilter("Unit of Measure Code", '<>''''');
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);

        // Exercise: Post Service Order as Ship and insert Fault/Resolution relationships by calling codeunit FaultResolRelationCalculate.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FaultResolRelationCalculate.CopyResolutionRelationToTable(WorkDate(), WorkDate(), true, true);

        // Verify: Check that the values in the Fault Resolution Codes Relationship correspond to the values in the Fault Code record.
        FaultResolCodRelationship.SetRange("Fault Code", FaultCode.Code);
        FaultResolCodRelationship.SetRange("Resolution Code", ServiceItemLine."Resolution Code");
        FaultResolCodRelationship.FindFirst();
        FaultResolCodRelationship.TestField("Fault Area Code", FaultArea.Code);
        FaultResolCodRelationship.TestField("Symptom Code", SymptomCode.Code);
        FaultResolCodRelationship.TestField("Service Item Group Code", ServiceItemLine."Service Item Group Code");
        FaultResolCodRelationship.TestField(Occurrences, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBaseCalendBlankError()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        Assert: Codeunit Assert;
        BaseCalendarCode: Code[10];
    begin
        // Covers document number TC0112 - refer to TFS ID 21727.
        // 1. Setup Base Calendar Code as blank in Service Management Setup.
        // 2. Create Service Order - Service Header, Service Item, Service Item Line.
        // 3. Verify that the application generates an error on insertion of the Service Item Line if the Base Calendar Code is blank.

        // Setup: Input Base Calendar Code as blank in Service Management Setup. Create Service Order - Service Header, Service Item.
        BaseCalendarCode := SetupServiceMgtBaseCalndrBlank(ServiceMgtSetup);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");

        // Exercise: Create Service Item Line.
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Verify: Check that the application generates an error on Service Item line insertion if Base Calendar Code is blank.
        Assert.ExpectedTestFieldError(ServiceMgtSetup.FieldCaption("Base Calendar Code"), '');

        // Cleanup: Enter the original Base Calendar Code in Service Management Setup.
        ServiceMgtSetup.Validate("Base Calendar Code", BaseCalendarCode);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBaseCalendRespDateNonWrkng()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC0112 - refer to TFS ID 21727.
        // 1. Create Service Order for a non working day that is followed by a working day - Service Item, Service Header,
        // Service Item Line.
        // 2. Update Response Time (Hours) on Service Item Line as a time falling inside the Service Hours of next working day - 1 hour.
        // 3. Verify that the Response Date on Service Item Line is the next working day.

        // Setup: Create Service Order for a non working day that is followed by a working day - Service Item, Service Header, Service Item
        // Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LibraryService.GetNonWrkngDayFollwdByWrkngDay());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Exercise: Input Response Time (Hours) as 1.
        ServiceItemLine.Validate("Response Time (Hours)", 1);  // Value 1 is important to the test case.
        ServiceItemLine.Modify(true);

        // Verify: Verify that the Response Date on Service Item Line is the next working day.
        ServiceItemLine.TestField("Response Date", LibraryService.GetNextWorkingDay(ServiceHeader."Order Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBaseCalendRespDateWrkngDay()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number TC0112 - refer to TFS ID 21727.
        // 1. Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        // 2. Update Response Time (Hours) on Service Item Line as boundary value - 0.
        // 3. Verify that the Response Date on Service Item Line is the Service Order Date.

        // Setup: Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LibraryService.GetFirstWorkingDay(WorkDate()));
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Exercise: Input Response Time (Hours) as boundary value 0.
        ServiceItemLine.Validate("Response Time (Hours)", 0);
        ServiceItemLine.Modify(true);

        // Verify: Verify that the Response Date on Service Item Line is the Service Order Date.
        ServiceItemLine.TestField("Response Date", ServiceHeader."Order Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultResponsTimeNull()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        DefaultResponseTime: Decimal;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Default Response Time (Hours) on Service Management Setup as 0.
        // 2. Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        // 3. Verify that the Response Time (Hours) on Service Item Line is 0.
        // 4. Enter the original Default Response Time (Hours) in Service Management Setup.

        // Setup:Input Default Response Time (Hours) on Service Management Setup as 0. Create Service Order.
        Initialize();
        DefaultResponseTime := SetupServiceMgtDefaultRespTime(ServiceMgtSetup, 0);  // Value 0 is important to test case.
        LibraryService.CreateServiceItem(ServiceItem, '');
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LibraryService.GetFirstWorkingDay(WorkDate()));

        // Exercise: Create Service item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Verify: Verify that the Response Time (Hours) on Service Item Line is 0.
        ServiceItemLine.TestField("Response Time (Hours)", 0);

        // Cleanup: Enter the original Default Response Time (Hours) in Service Management Setup.
        ServiceMgtSetup.Validate("Default Response Time (Hours)", DefaultResponseTime);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultResponsTimeRandom()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        DefaultResponseTime: Decimal;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Default Response Time (Hours) on Service Management Setup as any random value.
        // 2. Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        // 3. Verify that the Response Time (Hours) on Service Item Line is equal to the value of the field Default Response Time (Hours)
        // of Service Management Setup.
        // 4. Enter the original Default Response Time (Hours) in Service Management Setup.

        // Setup:Input Default Response Time (Hours) on Service Management Setup as any random value. Create Service Order.
        Initialize();
        DefaultResponseTime := SetupServiceMgtDefaultRespTime(ServiceMgtSetup, LibraryRandom.RandInt(100));
        LibraryService.CreateServiceItem(ServiceItem, '');
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LibraryService.GetFirstWorkingDay(WorkDate()));

        // Exercise: Create Service item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Verify: Verify that the Response Time (Hours) on Service Item Line is equal to the value of the field Default Response Time
        // (Hours) of Service Management Setup.
        ServiceItemLine.TestField("Response Time (Hours)", ServiceMgtSetup."Default Response Time (Hours)");

        // Cleanup: Enter the original Default Response Time (Hours) in Service Management Setup.
        ServiceMgtSetup.Validate("Default Response Time (Hours)", DefaultResponseTime);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultResponsTimeMoreYear()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        Assert: Codeunit Assert;
        DefaultResponseTime: Decimal;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Default Response Time (Hours) on Service Management Setup as more than a year.
        // 2. Create Service Order for a Working Day - Service Item, Service Header, Service Item Line.
        // 3. Verify that the application generates an error if Default response Time (Hours) is greater than a year.
        // 4. Enter the original Default Response Time (Hours) in Service Management Setup.

        // Setup:Input Default Response Time (Hours) on Service Management Setup as any more than a year. Create Service Order.
        Initialize();
        DefaultResponseTime := SetupServiceMgtDefaultRespTime(ServiceMgtSetup, (365 * 24) + LibraryRandom.RandInt(100));
        LibraryService.CreateServiceItem(ServiceItem, '');
        CreateServiceHeader(ServiceHeader, ServiceItem."Customer No.", LibraryService.GetFirstWorkingDay(WorkDate()));

        // Exercise: Create Service item Line.
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Verify: Verify that the application generates an error if Default response Time (Hours) is greater than a year.
        Assert.AreEqual(
          StrSubstNo(ResponseTimeMoreThanYearError, ServiceItemLine.FieldCaption("Response Date"), ServiceItemLine.TableCaption(),
            ServiceItem.FieldCaption("Response Time (Hours)"), ServiceItem.TableCaption()), GetLastErrorText, UnknownError);

        // Cleanup: Enter the original Default Response Time (Hours) in Service Management Setup.
        ServiceMgtSetup.Validate("Default Response Time (Hours)", DefaultResponseTime);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWarrantyDiscntServiceLine()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Warranty Disc. % (Parts) and Warranty Disc. % (Labor) on Service Management Setup as any random value.
        // 2. Create Service Order - Service Header, Service Item Line without Service Item and Service Line.
        // 3. Verify that the Warranty % (Parts) and Warranty % (Labor) on Service Item Line is equal to the value of the
        // field Warranty Disc. % (Parts) and Warranty Disc. % (Labor) of Service Management Setup. Verify that the value of Warranty
        // Disc. % fields on Service Line is equal to the value of the Warranty Disc. % (Parts) field of Service Management Setup.

        // Setup: Input Warranty Disc. % (Parts) and Warranty Disc. % (Labor) on Service Management Setup as any random value.
        // Create Service Order.
        Initialize();
        SetupServiceMgtWarrantyDisc(ServiceMgtSetup, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // Exercise: Create Service Item Line and Service Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Warranty, true);
        ServiceLine.Modify(true);

        // Verify: Verify that the Warranty % (Parts) and Warranty % (Labor) on Service Item Line is equal to the value of the
        // field Warranty Disc. % (Parts) and Warranty Disc. % (Labor) of Service Management Setup. Check Warranty Disc % on Service Line.
        ServiceItemLine.TestField("Warranty % (Parts)", ServiceMgtSetup."Warranty Disc. % (Parts)");
        ServiceItemLine.TestField("Warranty % (Labor)", ServiceMgtSetup."Warranty Disc. % (Labor)");
        ServiceLine.TestField("Warranty Disc. %", ServiceMgtSetup."Warranty Disc. % (Parts)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWarrantyDurServiceLineGrtr()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        DefaultWarrantyDuration: DateFormula;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Default Warranty Duration on Service Management Setup as one month.
        // 2. Create Service Order - Service Header, Service Item Line without Service Item.
        // 3. Verify that the Warranty Ending Date (Parts) and Warranty Ending Date (Labor) on Service Item Line are equal to
        // the value of the field Default Warranty Duration of Service Management Setup plus Starting Date.
        // 4. Enter the original Default Warranty Duration in Service Management Setup.

        // Setup: Input Default Warranty Duration on Service Management Setup as one month. Create Service Order.
        Initialize();
        Evaluate(DefaultWarrantyDuration, '<1M>');
        Evaluate(DefaultWarrantyDuration, SetupServiceMgtDefaultWarrDur(ServiceMgtSetup, DefaultWarrantyDuration));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // Exercise: Create Service item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);

        // Verify: Check that the Warranty Ending Date (Parts) and Warranty Ending Date (Labor) on Service Item Line are equal to
        // the value of the field Default Warranty Duration of Service Management Setup plus Starting Date.
        ServiceItemLine.TestField(
          "Warranty Ending Date (Parts)", CalcDate(ServiceMgtSetup."Default Warranty Duration",
            ServiceItemLine."Warranty Starting Date (Parts)"));
        ServiceItemLine.TestField("Warranty Ending Date (Labor)", CalcDate(ServiceMgtSetup."Default Warranty Duration",
            ServiceItemLine."Warranty Starting Date (Labor)"));

        // Cleanup: Enter the original Default Warranty Duration in Service Management Setup.
        ServiceMgtSetup.Validate("Default Warranty Duration", DefaultWarrantyDuration);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWarrantyDurServiceLineNull()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        DefaultWarrantyDuration: DateFormula;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Default Warranty Duration on Service Management Setup as zero month.
        // 2. Create Service Order - Service Header, Service Item Line without Service Item.
        // 3. Verify that the Warranty Ending Date (Parts) and Warranty Ending Date (Labor) on Service Item Line are equal to
        // the value of the field Warranty Starting Date (Parts) and Warranty Starting Date (Labor).
        // 4. Enter the original Default Warranty Duration in Service Management Setup.

        // Setup: Input Default Warranty Duration on Service Management Setup as zero month. Create Service Order.
        Initialize();
        Evaluate(DefaultWarrantyDuration, '<0M>');
        Evaluate(DefaultWarrantyDuration, SetupServiceMgtDefaultWarrDur(ServiceMgtSetup, DefaultWarrantyDuration));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // Exercise: Create Service Item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);

        // Verify: Check that the Warranty Ending Date (Parts) and Warranty Ending Date (Labor) on Service Item Line are equal to
        // the value of the field Warranty Starting Date (Parts) and Warranty Starting Date (Labor).
        ServiceItemLine.TestField("Warranty Ending Date (Parts)", ServiceItemLine."Warranty Starting Date (Parts)");
        ServiceItemLine.TestField("Warranty Ending Date (Labor)", ServiceItemLine."Warranty Starting Date (Labor)");

        // Cleanup: Enter the original Default Warranty Duration in Service Management Setup.
        ServiceMgtSetup.Validate("Default Warranty Duration", DefaultWarrantyDuration);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestWarrantyDurServiceLineSmll()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        Assert: Codeunit Assert;
        DefaultWarrantyDuration: DateFormula;
    begin
        // Covers document number TC0113 - refer to TFS ID 21727.
        // 1. Input Default Warranty Duration on Service Management Setup as minus one month.
        // 2. Create Service Order - Service Header, Service Item Line without Service Item.
        // 3. Verify that the application generates an error if the Default Warranty Duration is negative.
        // 4. Enter the original Default Warranty Duration in Service Management Setup.

        // Setup: Input Default Warranty Duration on Service Management Setup as minus one month. Create Service Order.
        Initialize();
        Evaluate(DefaultWarrantyDuration, '<-1M>');
        Evaluate(DefaultWarrantyDuration, SetupServiceMgtDefaultWarrDur(ServiceMgtSetup, DefaultWarrantyDuration));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // Exercise: Create Service Item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        asserterror ServiceItemLine.Validate(Warranty, true);

        // Verify: Check that the application generates an error if Default Warranty Duration is negative.
        Assert.AreEqual(StrSubstNo(WarrantyDurationNegativeError), GetLastErrorText, UnknownError);

        // Cleanup: Enter the original Default Warranty Duration in Service Management Setup.
        ServiceMgtSetup.Validate("Default Warranty Duration", DefaultWarrantyDuration);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestRegisterCntrctChangeFalse()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ContractChangeLog: Record "Contract Change Log";
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0114 - refer to TFS ID 21727.
        // 1. Input Register Contract Changes as FALSE on Service Management Setup.
        // 2. Create Service Contract - Service Contract Header, Service Item, Service Contract Line.
        // 3. Check that the Contract Change Log for the Service Contract created is empty.

        // Setup: Input Register Contract Changes as FALSE on Service Management Setup.
        Initialize();
        SetupServiceMgtRgistrCtrctChng(false);

        // Exercise: Create Service Contract - Service Contract Header, Service Item, Service Contract Line.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Verify: Check that the Contract Change Log for the Service Contract created is empty.
        ContractChangeLog.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Assert.AreEqual(
          ContractChangeLog.Count, 0, StrSubstNo(ContractChangeLogError, ContractChangeLog.TableCaption(),
            ServiceContractHeader.FieldCaption("Contract No."), ServiceContractHeader."Contract No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestRegisterCntrctChangeTrue()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ContractChangeLog: Record "Contract Change Log";
    begin
        // Covers document number TC0114 - refer to TFS ID 21727.
        // 1. Input Register Contract Changes as TRUE on Service Management Setup.
        // 2. Create Service Contract - Service Contract Header, Service Item, Service Contract Line.
        // 3. Check that the Contract Change Log for the Service Contract created is generated.

        // Setup: Input Register Contract Changes as TRUE on Service Management Setup.
        Initialize();
        SetupServiceMgtRgistrCtrctChng(true);

        // Exercise: Create Service Contract - Service Contract Header, Service Item, Service Contract Line.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Verify: Check that the Contract Change Log for the Service Contract created is generated.
        ContractChangeLog.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractChangeLog.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ConfirmContractCancellation')]
    [Scope('OnPrem')]
    procedure TestCntrctCancelReasonTrue()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0115 - refer to TFS ID 21727.
        // 1. Input Use Contract Cancel Reason as TRUE on Service Management Setup.
        // 2. Create Service Contract - Service Contract Header, Service Item, Service Contract Line.
        // 3. Check that the application generates an error if Contract is cancelled without inputting Cancel Reason Code.

        // Setup: Input Use Contract Cancel Reason as TRUE on Service Management Setup. Create Service Contract - Service Contract
        // Header, Service Item, Service Contract Line.
        Initialize();
        SetupServiceMgtCntrctCancelRsn(true);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Exercise: Change the Status to Canceled.
        asserterror ServiceContractHeader.Validate(Status, ServiceContractHeader.Status::Cancelled);

        // Verify: Check that the application generates an error if Contract is cancelled without inputting Cancel Reason Code.
        Assert.ExpectedTestFieldError(ServiceContractHeader.FieldCaption("Cancel Reason Code"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmContractCancellation')]
    [Scope('OnPrem')]
    procedure TestCntrctCancelReasonNotBlank()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ReasonCode: Record "Reason Code";
    begin
        // Covers document number TC0115 - refer to TFS ID 21727.
        // 1. Input Use Contract Cancel Reason as TRUE on Service Management Setup.
        // 2. Create Service Contract - Service Contract Header with Cancel Reason Code, Service Item, Service Contract Line.
        // 3. Check that the application allows the Contract to be cancelled if Cancel Reason Code is not blank.

        // Setup: Input Use Contract Cancel Reason as TRUE on Service Management Setup. Create Service Contract - Service Contract
        // Header, Service Item, Service Contract Line. Create a new Reason Code and enter it in the field Cancel Reason Code.
        Initialize();
        SetupServiceMgtCntrctCancelRsn(true);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        LibraryService.CreateReasonCode(ReasonCode);
        ServiceContractHeader.Validate("Cancel Reason Code", ReasonCode.Code);

        // Exercise: Change the Status to Canceled.
        ServiceContractHeader.Validate(Status, ServiceContractHeader.Status::Cancelled);
        ServiceContractHeader.Modify(true);

        // Verify: Check that the application allows the Contract to be cancelled if Cancel Reason Code is not blank.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Change Status", ServiceContractHeader."Change Status"::Locked);
    end;

    [Test]
    [HandlerFunctions('ConfirmContractCancellation')]
    [Scope('OnPrem')]
    procedure TestCntrctCancelReasonFalse()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
    begin
        // Covers document number TC0115 - refer to TFS ID 21727.
        // 1. Input Use Contract Cancel Reason as FALSE on Service Management Setup.
        // 2. Create Service Contract - Service Contract Header, Service Item, Service Contract Line.
        // 3. Check that the application allows the Contract to be cancelled if Cancel Reason Code is blank and Use Contract Cancel Reason
        // is FALSE on Service Management Setup.

        // Setup: Input Use Contract Cancel Reason as FALSE on Service Management Setup. Create Service Contract - Service Contract
        // Header, Service Item, Service Contract Line.
        Initialize();
        SetupServiceMgtCntrctCancelRsn(false);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Exercise: Change the Status to Canceled.
        ServiceContractHeader.Validate(Status, ServiceContractHeader.Status::Cancelled);
        ServiceContractHeader.Modify(true);

        // Verify: Check that the application allows the Contract to be cancelled if Cancel Reason Code is blank and Use Contract Cancel
        // Reason is FALSE on Service Management Setup.
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.TestField("Change Status", ServiceContractHeader."Change Status"::Locked);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCntrctServOrderMaxDaysNull()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        CreateContractServiceOrders: Report "Create Contract Service Orders";
        Assert: Codeunit Assert;
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractServOrdMaxDays: Integer;
    begin
        // Covers document number TC0116 - refer to TFS ID 21727.
        // 1. Input Contract Serv. Ord.  Max. Days as 0 on Service Management Setup.
        // 2. Create and Sign Service Contract - Service Contract Header, Service Item, Service Contract Line.
        // 3. Run Create Service Contract Orders.
        // 4. Check that the application generates an error if the date range entered is longer than the period allowed in Service Setup.
        // 5. Enter the original Contract Serv. Ord.  Max. Days in Service Management Setup.

        // Setup: Input Contract Serv. Ord.  Max. Days as 0 on Service Management Setup. Create and Sign Service Contract - Service
        // Contract Header, Service Item, Service Contract Line.
        Initialize();
        ContractServOrdMaxDays := SetupServiceMgtServOrdMaxDays(ServiceMgtSetup, 0);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(100));
        ServiceContractLine.Modify(true);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Exercise: Run Create Service Contract Orders report.
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractServiceOrders.SetTableView(ServiceContractHeader);
        CreateContractServiceOrders.UseRequestPage(false);
        CreateContractServiceOrders.InitializeRequest(WorkDate(), WorkDate(), 0);
        asserterror CreateContractServiceOrders.Run();

        // Verify: Check that the application generates an error if the date range entered is longer than the period allowed in Service
        // Management Setup.
        Assert.AreEqual(StrSubstNo(DateRangeError, ServiceMgtSetup.TableCaption()), GetLastErrorText, UnknownError);

        // Cleanup: Enter the original Contract Serv. Ord.  Max. Days in Service Management Setup.
        ServiceMgtSetup.Validate("Contract Serv. Ord.  Max. Days", ContractServOrdMaxDays);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerServOrdMaxDays')]
    [Scope('OnPrem')]
    procedure TestCntrctServOrderMaxDaysOne()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceHeader: Record "Service Header";
        CreateContractServiceOrders: Report "Create Contract Service Orders";
        Assert: Codeunit Assert;
        SignServContractDoc: Codeunit SignServContractDoc;
        ContractServOrdMaxDays: Integer;
    begin
        // Covers document number TC0116 - refer to TFS ID 21727.
        // 1. Input Contract Serv. Ord.  Max. Days as 1 on Service Management Setup.
        // 2. Create and Sign Service Contract - Service Contract Header, Service Item, Service Contract Line.
        // 3. Run Create Service Contract Orders.
        // 4. Check that the application generates an error if the date range entered is invalid and no Service Order is created.
        // 5. Enter the original Contract Serv. Ord.  Max. Days in Service Management Setup.

        // Setup: Input Contract Serv. Ord.  Max. Days as 1 on Service Management Setup. Create and Sign Service Contract - Service
        // Contract Header, Service Item, Service Contract Line.
        Initialize();
        ContractServOrdMaxDays := SetupServiceMgtServOrdMaxDays(ServiceMgtSetup, 1);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(100));
        ServiceContractLine.Modify(true);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // Exercise: Run Create Service Contract Orders report.
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        CreateContractServiceOrders.SetTableView(ServiceContractHeader);
        CreateContractServiceOrders.UseRequestPage(false);
        CreateContractServiceOrders.InitializeRequest(WorkDate(), WorkDate(), 0);
        CreateContractServiceOrders.Run();

        // Verify: Check that the application generates an error if the date range entered is invalid and no Service Order is created.
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Assert.AreEqual(
          0, ServiceHeader.Count, StrSubstNo(ServiceOrderError, ServiceHeader.TableCaption(), ServiceContractHeader.TableCaption(),
            ServiceContractHeader.FieldCaption("Contract No."), ServiceContractHeader."Contract No."));

        // Cleanup: Enter the original Contract Serv. Ord.  Max. Days in Service Management Setup.
        ServiceMgtSetup.Validate("Contract Serv. Ord.  Max. Days", ContractServOrdMaxDays);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('UpdateQuantityPageHandler,PostAsShipHandler,FaultResolutionRelationHandler')]
    [Scope('OnPrem')]
    procedure FaultResolutionRelationFault()
    var
        FaultCode: Record "Fault Code";
        ResolutionCode: Record "Resolution Code";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        No: Code[20];
        DefaultFaultReportingLevel: Option;
    begin
        // Test fault / resolution code relationship in a Service Order using Fault Reporting Level of Fault.

        // 1. Setup: Create Resolution Code, Fault Code, set Fault Reporting Level and create a Service Order.
        Initialize();
        ServiceMgtSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryService.CreateResolutionCode(ResolutionCode);
        DefaultFaultReportingLevel := ServiceMgtSetup."Fault Reporting Level";
        SetupServiceFaultReporting(ServiceMgtSetup, ServiceMgtSetup."Fault Reporting Level"::Fault);
        LibraryService.CreateFaultCode(FaultCode, '', '');

        No := LibraryService.CreateServiceOrderHeaderUsingPage();
        CreateServiceItemLine(FaultCode, No, ResolutionCode.Code);
        InsertFaultReasonCode(No);
        OpenServiceItemLine(No);

        // 2. Exercise: Insert fault / resolution code relationship.
        InsertFaultResolutionRelation();

        // 3. Verify: Verify that the Fault Reason Code inserted on Service Item Line matches with value on Service Line.
        // Verify that the values on the fault / resolution code relationship page matches with values inserted.
        VerifyFaultReasonCode(No);
        VerifyFaultResolutionRelation(FaultCode, No);

        // 4. Tear Down: Restore the Fault Reporting Level to it's original value.
        SetupServiceFaultReporting(ServiceMgtSetup, DefaultFaultReportingLevel);
    end;

    [Test]
    [HandlerFunctions('UpdateQuantityPageHandler,PostAsShipHandler,FaultResolutionRelationHandler')]
    [Scope('OnPrem')]
    procedure RelationFaultSymptom()
    var
        FaultCode: Record "Fault Code";
        SymptomCode: Record "Symptom Code";
        ResolutionCode: Record "Resolution Code";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        No: Code[20];
        DefaultFaultReportingLevel: Option;
    begin
        // Test fault / resolution code relationship in a Service Order using Fault Reporting Level of Fault and Symptom.

        // 1. Setup: Create Resolution Code, Fault Code, set Fault Reporting Level and create a Service Order.
        Initialize();
        ServiceMgtSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryService.CreateSymptomCode(SymptomCode);
        LibraryService.CreateResolutionCode(ResolutionCode);
        DefaultFaultReportingLevel := ServiceMgtSetup."Fault Reporting Level";
        SetupServiceFaultReporting(ServiceMgtSetup, ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom");
        LibraryService.CreateFaultCode(FaultCode, '', SymptomCode.Code);

        No := LibraryService.CreateServiceOrderHeaderUsingPage();
        CreateServiceItemLine(FaultCode, No, ResolutionCode.Code);
        InsertFaultReasonCode(No);
        OpenServiceItemLine(No);

        // 2. Exercise: Insert fault / resolution code relationship.
        InsertFaultResolutionRelation();

        // 3. Verify: Verify that the Fault Reason Code inserted on Service Item Line matches with value on Service Line.
        // Verify that the values on the fault / resolution relationship page matches with values inserted.
        VerifyFaultReasonCode(No);
        VerifyFaultResolutionRelation(FaultCode, No);

        // 4. Tear Down: Restore the Fault Reporting Level to it's original value.
        SetupServiceFaultReporting(ServiceMgtSetup, DefaultFaultReportingLevel);
    end;

    [Test]
    [HandlerFunctions('UpdateQuantityPageHandler,PostAsShipHandler,FaultResolutionRelationHandler')]
    [Scope('OnPrem')]
    procedure RelationFaultSymptomArea()
    var
        FaultCode: Record "Fault Code";
        FaultArea: Record "Fault Area";
        ResolutionCode: Record "Resolution Code";
        SymptomCode: Record "Symptom Code";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        No: Code[20];
        DefaultFaultReportingLevel: Option;
    begin
        // Test fault / resolution code relationship in a Service Order using Fault Reporting Level of Fault, Symptom and Area.

        // 1. Setup: Create Resolution Code, Fault Code, set Fault Reporting Level and create a Service Order.
        Initialize();
        ServiceMgtSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        LibraryService.CreateFaultArea(FaultArea);
        LibraryService.CreateSymptomCode(SymptomCode);
        LibraryService.CreateResolutionCode(ResolutionCode);
        DefaultFaultReportingLevel := ServiceMgtSetup."Fault Reporting Level";
        SetupServiceFaultReporting(ServiceMgtSetup, ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)");
        LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);

        No := LibraryService.CreateServiceOrderHeaderUsingPage();
        CreateServiceItemLine(FaultCode, No, ResolutionCode.Code);
        InsertFaultReasonCode(No);
        OpenServiceItemLine(No);

        // 2. Exercise: Insert fault / resolution code relationship.
        InsertFaultResolutionRelation();

        // 3. Verify: Verify that the Fault Reason Code inserted on Service Item Line matches with value on Service Line.
        // Verify that the values on the fault / resolution relationship page matches with values inserted.
        VerifyFaultReasonCode(No);
        VerifyFaultResolutionRelation(FaultCode, No);

        // 4. Tear Down: Restore the Fault Reporting Level to it's original value.
        SetupServiceFaultReporting(ServiceMgtSetup, DefaultFaultReportingLevel);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,InsertTravelFeePageHandler')]
    [Scope('OnPrem')]
    procedure NextPlannedServiceDateAfterInsertTravelFee()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test Next Planned Service Date on Service Contract Header after Insert Travel Fee.

        // Setup: Create and Post Service Order as Ship with Contract No. as No. of Service Contract Header.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);
        SignServContractDoc.SignContract(ServiceContractHeader);
        CreateAndPostServiceOrderForResource(
          ServiceHeader, ServiceContractLine, ServiceContractHeader."Customer No.", ServiceContractHeader."Contract No.", false);
        OpenServiceOrderAndInsertTravelFee(ServiceHeader."No.");

        // Exercise: Post Service Order as Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify Next Planned Service Date on Service Contract header after Inserting Travel Fee.
        VerifyPlannedNextServCalcMthod(ServiceContractHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckContractChangeLogOldNewValueFieldLength()
    var
        ContractChangeLog: Record "Contract Change Log";
        ServiceContractHeader: Record "Service Contract Header";
    begin
        ServiceContractHeader.Init();
        Assert.IsTrue(
          MaxStrLen(ServiceContractHeader."E-Mail") <= MaxStrLen(ContractChangeLog."Old Value"),
          StrSubstNo(FieldLengthErr, ContractChangeLog.FieldCaption("Old Value"), MaxStrLen(ServiceContractHeader."E-Mail")));
        Assert.IsTrue(
          MaxStrLen(ServiceContractHeader."E-Mail") <= MaxStrLen(ContractChangeLog."New Value"),
          StrSubstNo(FieldLengthErr, ContractChangeLog.FieldCaption("New Value"), MaxStrLen(ServiceContractHeader."E-Mail")));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    procedure AssistEditServiceHeaderNo()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeriesLine: Record "No. Series Line";
        ServiceOrder: TestPage "Service Order";
        NoSeriesCode: Code[20];
    begin
        // [SCENARIO 436504] User is able to open number series via assist edit from "No." on the service order page
        Initialize();

        // [GIVEN] Number series "NS" related to "Service Order Nos." in "Service Mgt. Setup" table
        ServiceMgtSetup.Get();
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        LibraryNoSeries.CreateNoSeriesRelationship(ServiceMgtSetup."Service Order Nos.", NoSeriesCode);
        LibraryVariableStorage.Enqueue(NoSeriesCode);

        // [WHEN] Invoke "No." assist edit on the service order page and select "NS" (processed in NoSeriesListModalPageHandler)
        ServiceOrder.OpenNew();
        ServiceOrder."No.".AssistEdit();

        // [THEN] Service order "No." = "Last No. Used" from "NS"
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindFirst();
        ServiceOrder."No.".AssertEquals(NoSeriesLine."Last No. Used");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowHideDocumentNoOnServiceOrder()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        ServiceOrder: TestPage "Service Order";
        OldServiceOrderNoSeries: Code[20];
    begin
        // [SCENARIO 424764] System will hide Document No. field on Service Order page if "Service Order Nos." is default without manual input
        Initialize();

        // [GIVEN] Number series related to "Service Order Nos." in "Service Mgt. Setup" table
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Order Nos." <> '' then
            OldServiceOrderNoSeries := ServiceMgtSetup."Service Order Nos.";

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        ServiceMgtSetup.Validate("Service Order Nos.", NoSeries.Code);
        ServiceMgtSetup.Modify(true);

        // [WHEN] [THEN] init new service order and check if "No." field is hidden
        DocumentNoVisibility.ClearState();
        ServiceOrder.OpenNew();
        Assert.IsFalse(ServiceOrder."No.".Visible(), 'No. field should be hidden');

        // [WHEN] Service order no series is set to manual nos
        NoSeries.Get(ServiceMgtSetup."Service Order Nos.");
        NoSeries."Manual Nos." := true;
        NoSeries.Modify(true);

        // [THEN] init new service order and check if "No." field is visible
        DocumentNoVisibility.ClearState();
        Clear(ServiceOrder);
        ServiceOrder.OpenNew();
        Assert.IsTrue(ServiceOrder."No.".Visible(), 'No. field should be visible');

        if OldServiceOrderNoSeries <> '' then begin
            ServiceMgtSetup.Validate("Service Order Nos.", OldServiceOrderNoSeries);
            ServiceMgtSetup.Modify(true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowHideDocumentNoOnServiceContract()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        ServiceContract: TestPage "Service Contract";
        OldServiceContractNoSeries: Code[20];
    begin
        // [SCENARIO 424764] System will hide Document No. field on Service Contract page if "Service Contract Nos." is default without manual input
        Initialize();

        // [GIVEN] Number series related to "Service Contract Nos." in "Service Mgt. Setup" table
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Order Nos." <> '' then
            OldServiceContractNoSeries := ServiceMgtSetup."Service Contract Nos.";

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        ServiceMgtSetup.Validate("Service Contract Nos.", NoSeries.Code);
        ServiceMgtSetup.Modify(true);

        // [WHEN] [THEN] init new service contract and check if "Contract No." field is hidden
        DocumentNoVisibility.ClearState();
        ServiceContract.OpenNew();
        Assert.IsFalse(ServiceContract."Contract No.".Visible(), 'Contract No. field should be hidden');

        // [WHEN] Service contract no series is set to manual nos
        NoSeries.Get(ServiceMgtSetup."Service Contract Nos.");
        NoSeries."Manual Nos." := true;
        NoSeries.Modify(true);

        // [THEN] init new service contract and check if "Contract No." field is visible
        DocumentNoVisibility.ClearState();
        Clear(ServiceContract);
        ServiceContract.OpenNew();
        Assert.IsTrue(ServiceContract."Contract No.".Visible(), 'Contract No. field should be visible');

        if OldServiceContractNoSeries <> '' then begin
            ServiceMgtSetup.Validate("Service Contract Nos.", OldServiceContractNoSeries);
            ServiceMgtSetup.Modify(true);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyContractGroupCodeAvailableOnAllServiceLedgerEntryAfter()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ContractGroup: Record "Contract Group";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [SCENARIO 475360] Service - Contract group code not set in all Service Ledger Entries
        Initialize();

        // [GIVEN] Setup: Create Contract Group, and Service Contract
        LibraryService.CreateContractGroup(ContractGroup);
        CreateServiceContract(ServiceContractHeader, ServiceContractLine);

        // [THEN] Update Service Contract also set Contract Group Code
        UpdateServiceContractHeader(ServiceContractHeader, ContractGroup.Code);


        // [THEN] Lock and Sign Service Contract
        LockOpenServContract.LockServContract(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Create and Post Service Order
        CreateAndPostServiceOrderForItem(
            ServiceHeader,
            ServiceContractLine,
            ServiceContractHeader."Customer No.",
            ServiceContractHeader."Contract No.",
            false);

        // [VERIFY]: Verify COntract Group Code on Service Ledger Entries
        VerifyContractGroupCodeOnServiceLedgerEntry(ServiceContractHeader."Contract No.", ContractGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TestLineDiscountOnChangingFaultReasonCode()
    var
        FaultReasonCode: Record "Fault Reason Code";
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // [SCENARIO 491083] The "Line Discount %" field should be updated correctly when the Fault Reason Code that has both warranty and contract discount checked is selected.
        Initialize();

        // [GIVEN] Create a new Fault Reason Code with Exclude Warranty Discount and Exclude Contract Discount should be true
        LibraryService.CreateFaultReasonCode(FaultReasonCode, true, true);

        // [GIVEN] Create a new Service Order with Service Item Worksheet in which Warranty will be enabled
        SetupServiceMgtWarrantyDisc(ServiceMgtSetup, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));

        // [WHEN] Input the new Fault Reason Code created 
        ServiceLine.Validate("Fault Reason Code", FaultReasonCode.Code);
        ServiceLine.Modify(true);

        // [THEN] Line Discount % value should be 0.
        Assert.AreEqual(ServiceLine."Line Discount %", 0, LineDiscountPerError);
    end;

    [Test]
    [HandlerFunctions('ServiceLinesPageHandler,ConfirmHandler')]
    procedure TestLineDiscountOnChangingFaultReasonCodeServicetItemLine()
    var
        FaultReasonCode: Record "Fault Reason Code";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceOrder: TestPage "Service Order";
        ServiceLines: TestPage "Service Lines";
        LineDiscountPct: Decimal;
    begin
        // [SCENARIO 506177] Line Discount % is deleted in the service line when changing the fault reason code in the service order.
        Initialize();

        // [GIVEN] Create a new Fault Reason Code with Exclude Warranty Discount and Exclude Contract Discount should be true
        LibraryService.CreateFaultReasonCode(FaultReasonCode, true, true);

        // [GIVEN] Setup Warranty Discount on Service Management and Create Service Order
        SetupServiceMgtWarrantyDisc(ServiceMgtSetup, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate(Warranty, true);
        ServiceItemLine.Modify(true);

        // [WHEN] Initialize "Line Discount %" and Enqueue to perform verification on ServiceLinesPageHandler 
        LineDiscountPct := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryVariableStorage.Enqueue(LineDiscountPct);

        // [THEN] Create Service Line and set "Line Discount %"
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate("Line Discount %", LineDiscountPct);
        ServiceLine.Modify(true);

        // [WHEN] Input the new Fault Reason Code on Service Item Line
        ServiceItemLine.Validate("Fault Reason Code", FaultReasonCode.Code);
        ServiceItemLine.Modify();

        // [THEN] Verify: Open Service Line Page and check "Line Discount %" should be equal to LineDiscountPct
        ServiceOrder.OpenEdit();
        ServiceOrder.GoToRecord(ServiceHeader);
        ServiceLines.Trap();
        ServiceOrder.ServItemLines."Service Lines".Invoke();
    end;

    local procedure CreateAndPostServiceOrderForResource(var ServiceHeader: Record "Service Header"; ServiceContractLine: Record "Service Contract Line"; CustomerNo: Code[20]; ContractNo: Code[20]; Invoice: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Contract No.", ContractNo);
        ServiceHeader.Modify(true);
        CreateServiceItemLinesContract(ServiceItemLine, ServiceContractLine, ServiceHeader);
        CreateServiceLinesForResource(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, Invoice);
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    begin
        // Create Service Contract Header, Service Contract Line and enter Annual Amount and Starting Date in Service Contract Header.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", ServiceContractHeader."Starting Date");
        ServiceContractHeader.Validate("Service Zone Code", FindServiceZone());
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Contract Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
            LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
            ServiceContractLine.Validate("Line Value", 1 + LibraryRandom.RandInt(100));  // Enter any value greater than 1 as value is not important.
            ServiceContractLine.Validate("Service Period", ServiceContractHeader."Service Period");
            ServiceContractLine.Modify(true);
        end;
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost")
    var
        GLAccount: Record "G/L Account";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Cost Type", ServiceCost."Cost Type"::Travel);
        ServiceCost.Validate("Account No.", GLAccount."No.");
        ServiceCost.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; OrderDate: Date)
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Order Date", OrderDate);
        ServiceHeader.Validate("Order Time", 000001T);  // Value 000001T is important for test case.
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceItemLine(FaultCode: Record "Fault Code"; No: Code[20]; ResolutionCode: Code[10])
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceOrder: TestPage "Service Order";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceOrderPageOpenEdit(ServiceOrder, No);
        ServiceOrder."Customer No.".SetValue(ServiceItem."Customer No.");
        ServiceOrder.ServItemLines.ServiceItemNo.SetValue(ServiceItem."No.");
        ServiceOrder.ServItemLines."Fault Area Code".SetValue(FaultCode."Fault Area Code");
        ServiceOrder.ServItemLines."Symptom Code".SetValue(FaultCode."Symptom Code");
        ServiceOrder.ServItemLines."Fault Code".SetValue(FaultCode.Code);
        ServiceOrder.ServItemLines."Resolution Code".SetValue(ResolutionCode);
        ServiceOrder.ServItemLines.New();
        ServiceOrder.OK().Invoke();
    end;

    local procedure CreateServiceItemLinesContract(var ServiceItemLine: Record "Service Item Line"; ServiceContractLine: Record "Service Contract Line"; ServiceHeader: Record "Service Header")
    begin
        // Create Service Item Line for each Service Contract Line.
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        ServiceContractLine.FindSet();
        repeat
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceContractLine."Service Item No.");
        until ServiceContractLine.Next() = 0;
    end;

    local procedure CreateServiceItemLineForFault(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; FaultCode: Record "Fault Code")
    var
        ServiceItem: Record "Service Item";
        ResolutionCode: Record "Resolution Code";
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.FindResolutionCode(ResolutionCode);
        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceItemLine.Validate("Fault Area Code", FaultCode."Fault Area Code");
        ServiceItemLine.Validate("Symptom Code", FaultCode."Symptom Code");
        ServiceItemLine.Validate("Fault Code", FaultCode.Code);
        ServiceItemLine.Validate("Resolution Code", ResolutionCode.Code);
        ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceLinesForResource(ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
        ResourceNo: Code[20];
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        ResourceNo := LibraryResource.CreateResourceNo();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure FindServiceItemLineForOrder(var ServiceItemLine: Record "Service Item Line"; DocumentNo: Code[20])
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", DocumentNo);
        ServiceItemLine.FindFirst();
    end;

    local procedure FindServiceLineForOrder(var ServiceLine: Record "Service Line"; No: Code[20])
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", No);
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceZone(): Code[10]
    var
        ServiceCost: Record "Service Cost";
    begin
        ServiceCost.SetRange("Cost Type", ServiceCost."Cost Type"::Travel);
        ServiceCost.SetFilter("Account No.", '<>''''');
        ServiceCost.SetFilter("Service Zone Code", '<>''''');
        ServiceCost.FindFirst();
        exit(ServiceCost."Service Zone Code");
    end;

    local procedure InsertFaultReasonCode(No: Code[20])
    var
        FaultReasonCode: Record "Fault Reason Code";
        ServiceItemLine: Record "Service Item Line";
    begin
        FindServiceItemLineForOrder(ServiceItemLine, No);
        LibraryService.FindFaultReasonCode(FaultReasonCode);
        ServiceItemLine.Validate("Fault Reason Code", FaultReasonCode.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure InsertFaultResolutionRelation()
    var
        InsertFaultResolRelations: Report "Insert Fault/Resol. Relations";
    begin
        InsertFaultResolRelations.UseRequestPage(false);
        // Using random values for To Date as value is not important.
        InsertFaultResolRelations.InitializeRequest(WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), true, true);
        InsertFaultResolRelations.RunModal();
    end;

    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure OpenServiceItemLine(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrderPageOpenView(ServiceOrder, No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
    end;

    local procedure OpenServiceOrderAndInsertTravelFee(ServiceHeaderNo: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrderPageOpenEdit(ServiceOrder, ServiceHeaderNo);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
    end;

    local procedure ServiceOrderPageOpenEdit(ServiceOrder: TestPage "Service Order"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure ServiceOrderPageOpenView(ServiceOrder: TestPage "Service Order"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceOrder.OpenView();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure SetupServiceMgtSetupPlanned(): Boolean
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Next Service Calc. Method" <> ServiceMgtSetup."Next Service Calc. Method"::Planned then begin
            ServiceMgtSetup.Validate("Next Service Calc. Method", ServiceMgtSetup."Next Service Calc. Method"::Planned);
            ServiceMgtSetup.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetupServiceMgtSetupActual(): Boolean
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Next Service Calc. Method" <> ServiceMgtSetup."Next Service Calc. Method"::Actual then begin
            ServiceMgtSetup.Validate("Next Service Calc. Method", ServiceMgtSetup."Next Service Calc. Method"::Actual);
            ServiceMgtSetup.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetupServiceMgtStartingFee(var ServiceCost: Record "Service Cost")
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // If Service Order Starting Fee of Service Management Setup is blank or not of Cost Type as Travel then create a new Service Cost
        // and enter in the field.
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Order Starting Fee" <> '' then begin
            ServiceCost.Get(ServiceMgtSetup."Service Order Starting Fee");
            if ServiceCost."Cost Type" = ServiceCost."Cost Type"::Travel then
                exit;
        end;

        CreateServiceCost(ServiceCost);
        ServiceMgtSetup.Validate("Service Order Starting Fee", ServiceCost.Code);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtStartngFeeBlank()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // If Service Order Starting Fee of Service Management Setup is blank then create a new Service Cost and enter in the field.
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Order Starting Fee" <> '' then begin
            ServiceMgtSetup.Validate("Service Order Starting Fee", '');
            ServiceMgtSetup.Modify(true);
        end;
    end;

    local procedure SetupServiceMgtResSkillServZon(ResourceSkillsOption: Option; ServiceZonesOption: Option)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Setup Resource Skills Option and Service Zones Option of Service Management Setup as Code Shown.
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Resource Skills Option", ResourceSkillsOption);
        ServiceMgtSetup.Validate("Service Zones Option", ServiceZonesOption);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceFaultReporting(var ServiceMgtSetup: Record "Service Mgt. Setup"; FaultReportingLevel: Option)
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Fault Reporting Level", FaultReportingLevel);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtBaseCalndrBlank(var ServiceMgtSetup: Record "Service Mgt. Setup") BaseCalendarCode: Code[10]
    begin
        ServiceMgtSetup.Get();
        BaseCalendarCode := ServiceMgtSetup."Base Calendar Code";
        ServiceMgtSetup.Validate("Base Calendar Code", '');
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtDefaultRespTime(var ServiceMgtSetup: Record "Service Mgt. Setup"; DefaultResponseTime: Decimal) DefaultResponseTimeOld: Decimal
    begin
        ServiceMgtSetup.Get();
        DefaultResponseTimeOld := ServiceMgtSetup."Default Response Time (Hours)";
        ServiceMgtSetup.Validate("Default Response Time (Hours)", DefaultResponseTime);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtWarrantyDisc(var ServiceMgtSetup: Record "Service Mgt. Setup"; WarrantyDiscParts: Decimal; WarrantyDiscLabor: Decimal)
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Warranty Disc. % (Parts)", WarrantyDiscParts);
        ServiceMgtSetup.Validate("Warranty Disc. % (Labor)", WarrantyDiscLabor);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtDefaultWarrDur(var ServiceMgtSetup: Record "Service Mgt. Setup"; DefaultWarrantyDuration: DateFormula) DefaultWarrantyDurationOld: Text[30]
    begin
        ServiceMgtSetup.Get();
        DefaultWarrantyDurationOld := Format(ServiceMgtSetup."Default Warranty Duration");
        ServiceMgtSetup.Validate("Default Warranty Duration", DefaultWarrantyDuration);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtRgistrCtrctChng(RegisterContractChanges: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Register Contract Changes", RegisterContractChanges);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtCntrctCancelRsn(UseContractCancelReason: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Use Contract Cancel Reason", UseContractCancelReason);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure SetupServiceMgtServOrdMaxDays(var ServiceMgtSetup: Record "Service Mgt. Setup"; ContractServOrdMaxDays: Integer) ContractServOrdMaxDaysOld: Integer
    begin
        ServiceMgtSetup.Get();
        ContractServOrdMaxDaysOld := ServiceMgtSetup."Contract Serv. Ord.  Max. Days";
        ServiceMgtSetup.Validate("Contract Serv. Ord.  Max. Days", ContractServOrdMaxDays);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure VerifyPlannedNextServCalcMthod(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Check that the Next Planned Date in Service Line is obtained by adding Service Period of the Service Contract Header to
        // the Starting Date of the Service Contract Header.
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindSet();
        repeat
            ServiceContractLine.TestField(
              "Next Planned Service Date", CalcDate(ServiceContractHeader."Service Period", ServiceContractHeader."Starting Date"));
        until ServiceContractLine.Next() = 0;
    end;

    local procedure VerifyActualNextServCalcMthod(ServiceContractLine: Record "Service Contract Line"; ContractHeaderServicePeriod: DateFormula)
    begin
        // Check that the Next Planned Date in Service Line is obtained by adding Service Period of the Service Contract Header to
        // the Last Service Date of the Service Contract Line.
        ServiceContractLine.SetRange("Contract Type", ServiceContractLine."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractLine."Contract No.");
        ServiceContractLine.FindSet();
        repeat
            ServiceContractLine.TestField(
              "Next Planned Service Date", CalcDate(ContractHeaderServicePeriod, ServiceContractLine."Last Service Date"));
        until ServiceContractLine.Next() = 0;
    end;

    local procedure VerifyFaultReasonCode(No: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        FindServiceItemLineForOrder(ServiceItemLine, No);
        FindServiceLineForOrder(ServiceLine, No);
        ServiceItemLine.SetRange("Line No.", ServiceLine."Line No.");
        ServiceItemLine.FindFirst();
        ServiceLine.TestField("Fault Reason Code", ServiceItemLine."Fault Reason Code");
    end;

    local procedure VerifyFaultResolutionRelation(FaultCode: Record "Fault Code"; No: Code[20])
    var
        FaultResolCodRelationship: TestPage "Fault/Resol. Cod. Relationship";
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrderPageOpenView(ServiceOrder, No);
        FaultResolCodRelationship.OpenView();
        FaultResolCodRelationship.FILTER.SetFilter("Fault Code", ServiceOrder.ServItemLines."Fault Code".Value);
        ServiceOrder.ServItemLines."Fault/Resol. Codes Relations".Invoke();
        FaultResolCodRelationship2.TestField("Fault Area Code", FaultCode."Fault Area Code");
        FaultResolCodRelationship2.TestField("Symptom Code", FaultCode."Symptom Code");
    end;

    local procedure VerifyServiceLineStartingFee(ServiceHeader: Record "Service Header"; ServiceCost: Record "Service Cost")
    var
        ServiceLine: Record "Service Line";
    begin
        // Check that the values populated in the Service Line are equal to the values in the Service Cost selected.
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField(Type, ServiceLine.Type::Cost);
        ServiceLine.TestField("No.", ServiceCost.Code);
        ServiceLine.TestField(Quantity, ServiceCost."Default Quantity");
        ServiceLine.TestField("Unit of Measure Code", ServiceCost."Unit of Measure Code");
        ServiceLine.TestField("Unit Cost (LCY)", ServiceCost."Default Unit Cost");
    end;

    local procedure UpdateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; ContractGroupCode: Code[10])
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Validate("Contract Group Code", ContractGroupCode);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateAndPostServiceOrderForItem(var ServiceHeader: Record "Service Header"; ServiceContractLine: Record "Service Contract Line"; CustomerNo: Code[20]; ContractNo: Code[20]; Invoice: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Contract No.", ContractNo);
        ServiceHeader.Modify(true);
        CreateServiceItemLinesContract(ServiceItemLine, ServiceContractLine, ServiceHeader);
        CreateServiceLinesForItem(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, Invoice);
    end;

    local procedure CreateServiceLinesForItem(ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        ItemNo := LibraryInventory.CreateItemNo();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure VerifyContractGroupCodeOnServiceLedgerEntry(ContractNo: Code[20]; ContractGroupCode: Code[10])
    var
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLine(ServiceLine, ContractNo);

        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        ServiceLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(ServiceLedgerEntry."Contract Group Code", ContractGroupCode, '');
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ContractNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Contract No.", ContractNo);
        ServiceHeader.FindLast();

        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = UseContractTemplateConfirm);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmContractCancellation(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (StrPos(Question, ContractCancellationQuestion) = 0);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Handle Message.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerServOrdMaxDays(Message: Text[1024])
    begin
        // Handle Message.
        if (StrPos(Message, ServiceInvoiceMassage) = 0) and (StrPos(Message, ZeroOrderCreated) = 0) then
            Error(UnexpectedMessage, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResAvailabilityModlFormHandler(var ResAvailabilityService: Page "Res. Availability (Service)"; var Response: Action)
    var
        ServAllocationManagement: Codeunit ServAllocationManagement;
    begin
        // Call the ServAllocationManagement code unit to allocate Resource.
        ServAllocationManagement.AllocateDate(
          ServiceOrderAllocation."Document Type".AsInteger(), ServiceOrderAllocation."Document No.", ServiceOrderAllocation."Entry No.",
          Resource."No.", '', WorkDate(), 0);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderSubformFormHandler(var ServiceOrderSubform: Page "Service Order Subform")
    begin
        // Call the function AllocateResource of the Service Order Subform to allocate Resource.
        ServiceOrderSubform.AllocateResource();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ResourceAllocationsFormHandler(var ResourceAllocations: Page "Resource Allocations")
    var
        ResAvailabilityService: Page "Res. Availability (Service)";
    begin
        // Run the Res. Availability (Service) form from Resource Allocations form.
        ResourceAllocations.GetRecord(ServiceOrderAllocation);
        ResAvailabilityService.SetData(
          ServiceOrderAllocation."Document Type".AsInteger(), ServiceOrderAllocation."Document No.", ServiceOrderAllocation."Service Item Line No.",
          ServiceOrderAllocation."Entry No.");
        if ServiceOrderAllocation."Resource No." <> '' then
            ResAvailabilityService.SetRecord(Resource);
        ResAvailabilityService.RunModal();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateQuantityPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(LibraryInventory.CreateItem(Item));

        // Use random value for Quantity as value is not important.
        ServiceLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        // Post the service Order as Ship.
        ServiceLines.Post.Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostAsShipHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FaultResolutionRelationHandler(var FaultResolCodRelationship: TestPage "Fault/Resol. Cod. Relationship")
    begin
        FaultResolCodRelationship2.Init();
        FaultResolCodRelationship2.Validate("Fault Area Code", FaultResolCodRelationship.FaultArea.Value);
        FaultResolCodRelationship2.Validate("Symptom Code", FaultResolCodRelationship.SymptomCode.Value);
    end;

    local procedure ExecuteConfirm()
    var
        Answer: Boolean;
    begin
        Clear(Answer);
        Answer := DIALOG.Confirm(Question, true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InsertTravelFeePageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines."Insert Travel Fee".Invoke();
    end;

    [ModalPageHandler]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange(Code, LibraryVariableStorage.DequeueText());
        NoSeries.FindFirst();
        NoSeriesList.GoToRecord(NoSeries);
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesPageHandler(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.SelectionFilter.SetValue('All');
        ServiceLines.First();
        ServiceLines."Line Discount %".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

}
