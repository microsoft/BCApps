codeunit 136209 "Marketing Opportunity Mgmt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Opportunity] [Marketing]
    end;

    var
        Opportunity2: Record Opportunity;
        Contact2: Record Contact;
        SalespersonPurchaser2: Record "Salesperson/Purchaser";
        SalesCycle2: Record "Sales Cycle";
        SalesCycleStage2: Record "Sales Cycle Stage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        ExistErr: Label '%1 for %2 %3 must not exist.';
        SalesCycleCode: Code[10];
        CurrentSalesCycleStage: Integer;
        WizardEstimatedValueLCY: Decimal;
        WizardChancesOfSuccessPercent: Decimal;
        UnknownErr: Label 'Unexpected Error.';
        DeleteErr: Label 'You cannot delete this opportunity while it is active.';
        ActionType: Option " ",First,Next,Previous,Skip,Update,Jump;
        SalespersonCode: Code[20];
        SalesQuoteErr: Label 'You cannot go to this stage before you have assigned a sales quote.';
        SalesQuoteNo: Code[20];
        ActionTaken: Option " ",Next,Previous,Updated,Jumped,Won,Lost;
        ActivateFirstStage: Boolean;
        Completed: Decimal;
        ShowSalesQuoteErr: Label 'There is no sales quote that is assigned to this opportunity.';
        CloseOpportunityErr: Label '%1 for %2  must not exist.';
        ActionShouldBeEnabledErr: Label 'Action should be enabled';
        OpportunityCreatedFromIntLogEntryMsg: Label 'Opportunity %1 was created based on selected interaction log entry.', Comment = '%1 - opportunity code';
        ActionShouldBeDisabledErr: Label 'Action should be disabled';
        OppStatusErr: Label 'Opportunity is the wrong status';
        CreationDateErr: Label 'Opportunity Creation Date is incorrect';
        CampaignListErr: Label 'Campaign List contains wrong data';
        CampaignNoErr: Label 'Campaign No. is incorrect';
        SegmentListErr: Label 'Segment List contains wrong data';
        SegmentNoErr: Label 'Segment No. is incorrect';
        OppCampaignNoErr: Label 'Campaign No. must not be %1 in Opportunity No.=''%2''';
        OppCardSalesDocTypeErr: Label 'Validation error for Field: Sales Document Type,  Message = ''Your entry of ''%1'' is not an acceptable value for ''Sales Document Type''. (Select Refresh to discard errors)''';
        OppNoNotUpdatedOnSalesQuoteErr: Label 'Opportunity No. not updated on Sales Quote.';
        ToDoCountShouldBeOneErr: Label 'To-do count should be one.';

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure SalesCycleProbabilityAdd()
    var
        SalesCycle: Record "Sales Cycle";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Opportunity values with Sales Cycle of Probability Calculation Add.
        Initialize();
        SalesCycleProbability(SalesCycle."Probability Calculation"::Add);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure SalesCycleProbabilityChances()
    var
        SalesCycle: Record "Sales Cycle";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Opportunity values with Sales Cycle of Probability Calculation Chances of Success %.
        Initialize();
        SalesCycleProbability(SalesCycle."Probability Calculation"::"Chances of Success %");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure SalesCycleProbabilityCompleted()
    var
        SalesCycle: Record "Sales Cycle";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Opportunity values with Sales Cycle of Probability Calculation Completed %.
        Initialize();
        SalesCycleProbability(SalesCycle."Probability Calculation"::"Completed %");
    end;

    local procedure SalesCycleProbability(ProbabilityCalculation: Option)
    var
        Contact: Record Contact;
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage, update Probability Calculation as per parameter create Opportunity
        // for Contact.
        Initialize();
        CreateContactWithSalesCycle(SalesCycleStage, Contact);
        SalesCycle.Get(SalesCycleStage."Sales Cycle Code");
        SalesCycle.Validate("Probability Calculation", ProbabilityCalculation);
        SalesCycle.Modify(true);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        CreateOpportunity(Contact."No.");

        // 2. Exercise: Update Opportunity.
        UpdateOpportunityValue(Contact."No.");

        // 3. Verify: Verify Probability % and Calcd. Current Value (LCY) on Opportunity as per parameter ProbabilityCalculation.
        VerifyValuesOnOpportunity(
          Contact."No.", ProbabilityCalculation, WizardEstimatedValueLCY, SalesCycleStage."Chances of Success %",
          SalesCycleStage."Completed %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesCycleComment()
    var
        SalesCycle: Record "Sales Cycle";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Sales Cycle update on Creation of Comment for Sales Cycle.

        // 1. Setup: Create Sales Cycle.
        Initialize();
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // 2. Exercise: Create Comment for Created Sales Cycle.
        LibraryMarketing.CreateRlshpMgtCommentSales(RlshpMgtCommentLine, SalesCycle.Code);

        // 3. Verify: Verify Sales Cycle update on Creation of Comment for Sales Cycle.
        SalesCycle.Get(SalesCycle.Code);
        SalesCycle.CalcFields(Comment);
        SalesCycle.TestField(Comment, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCloseOpportunityCode()
    var
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Close Opportunity Code Successfully Created.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Close Opportunity Code.
        LibraryMarketing.CreateCloseOpportunityCode(CloseOpportunityCode);

        // 3. Verify: Verify Close Opportunity Code Created.
        CloseOpportunityCode.Get(CloseOpportunityCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyCloseOpportunityCode()
    var
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Close Opportunity Code Successfully Modified.

        // 1. Setup: Create Close Opportunity Code.
        Initialize();
        LibraryMarketing.CreateCloseOpportunityCode(CloseOpportunityCode);

        // 2. Exercise: Update Close Opportunity Code.
        CloseOpportunityCode.Validate(Type, CloseOpportunityCode.Type::Lost);
        CloseOpportunityCode.Modify(true);

        // 3. Verify: Verify Close Opportunity Code Modified.
        CloseOpportunityCode.Get(CloseOpportunityCode.Code);
        CloseOpportunityCode.TestField(Type, CloseOpportunityCode.Type::Lost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCloseOpportunityCode()
    var
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        // Covers document number TC0021 - refer to TFS ID 21735.
        // Test Close Opportunity Code Successfully Deleted.

        // 1. Setup: Create Close Opportunity Code.
        Initialize();
        LibraryMarketing.CreateCloseOpportunityCode(CloseOpportunityCode);

        // 2. Exersice: Delete Close Opportunity Code.
        CloseOpportunityCode.Delete(true);

        // 3. Verify: Verify Close Opportunity Code Deleted.
        Assert.IsFalse(
          CloseOpportunityCode.Get(CloseOpportunityCode.Code),
          StrSubstNo(CloseOpportunityErr, CloseOpportunityCode.TableCaption(), CloseOpportunityCode.Code));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure UpdateOpportunitySalesCycle()
    var
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0022, TC0023 - refer to TFS ID 21735.
        // Test Opportunity Successfully updated through Update opportunity Wizard with Sales Cycle Code and Sales Cycle Stage.

        // 1. Create Contact, Sales Cycle, Sales Cycle Stage, Opportunity for Contact and Update Opportunity.
        CreateAndUpdateOpportunity(Opportunity, SalesCycleStage);

        // 2. Verify: Verify Opportunity successfully created with Sales Cycle Code and Estimated Value (LCY).
        VerifyOpportunityValues(
          SalesCycleStage, Opportunity."Contact No.", WizardEstimatedValueLCY, SalesCycleStage."Chances of Success %");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure DeleteOpenOpportunity()
    var
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0022 - refer to TFS ID 21735.
        // Test error occurs on deletion of Active Opportunity.

        // 1. Create Contact, Sales Cycle, Sales Cycle Stage, Opportunity for Contact and Update Opportunity.
        CreateAndUpdateOpportunity(Opportunity, SalesCycleStage);

        // 3. Verify: Verify error occurs on deletion of Active Opportunity.
        Opportunity.Get(Opportunity."No.");
        asserterror Opportunity.Delete(true);
        Assert.AreEqual(StrSubstNo(DeleteErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity,ModalFormCloseOpportunity')]
    [Scope('OnPrem')]
    procedure DeleteCloseOpportunity()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        OpportunityEntry: Record "Opportunity Entry";
    begin
        // Covers document number TC0022 - refer to TFS ID 21735.
        // Test Opportunity and Opportunity Entry Successfully deleted after close opportunity through Close opportunity wizard.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage create and update Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActionTaken := ActionTaken::Lost;

        CreateOpportunity(Contact."No.");
        UpdateOpportunityValue(Contact."No.");

        // 2. Exercise: Close the Opportunity and Delete closed Opportunity.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();

        Opportunity.Get(Opportunity."No.");
        Opportunity.Delete(true);

        // 3. Verify: Verify Opportunity and Opportunity Entry deleted.
        Assert.IsFalse(Opportunity.FindFirst(), StrSubstNo(ExistErr, Opportunity.TableCaption(), Contact.TableCaption(), Contact."No."));

        OpportunityEntry.SetRange("Opportunity No.", Opportunity."No.");
        Assert.IsFalse(
          OpportunityEntry.FindFirst(), StrSubstNo(ExistErr, OpportunityEntry.TableCaption(), Opportunity.TableCaption(), Opportunity."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure UpdateOpportunity()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0023 - refer to TFS ID 21735.
        // Test error occurs on selecting different option except First on Update opportunity wizard.

        // 1. Setup: Create Contact, Sales Cycle and Sales Cycle Stage.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::Next, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        // 2. Exercise: Create opportunity for Contact.
        CreateOpportunity(Contact."No.");

        // 3. Verify: Verify error occurs on selecting different option except First on Update opportunity wizard.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        asserterror Opportunity.UpdateOpportunity();
        Assert.ExpectedErrorCannotFind(Database::"Sales Cycle Stage");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure UpdateOpportunityTwice()
    var
        Contact: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0023 - refer to TFS ID 21735.
        // Test Sales Value successfully updated on Opportunity through Update opportunity wizard Twice.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage and Create opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        CreateSalesCycleStage(SalesCycleStage, SalesCycleStage."Sales Cycle Code");
        CreateOpportunity(Contact."No.");

        // 2. Exercise: Update Opportunity and Update Opportunity again with Next Option.
        UpdateOpportunityValue(Contact."No.");

        // Set Global Variable for Form Handler.
        ActionType := ActionType::Next;
        CurrentSalesCycleStage := SalesCycleStage.Stage;

        UpdateOpportunityValue(Contact."No.");

        // 3. Verify: Verify Sales Values on Opportunity.
        VerifyOpportunityValues(SalesCycleStage, Contact."No.", WizardEstimatedValueLCY, SalesCycleStage."Chances of Success %");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure UpdateOpportunityWithSkip()
    var
        Contact: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0023 - refer to TFS ID 21735.
        // Test error occurs on selecting Skip Option on Update opportunity wizard.

        // 1. Setup: Create Contact, Sales Cycle and Sales Cycle Stage.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::Skip, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        // 2. Exercise: Create opportunity for Contact.
        CreateOpportunity(Contact."No.");

        // 3. Verify: Verify error occurs on selecting Skip Option on Update opportunity wizard.
        asserterror UpdateOpportunityValue(Contact."No.");
        Assert.ExpectedErrorCannotFind(Database::"Sales Cycle Stage");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ModalHandlerOpportunityTask')]
    [Scope('OnPrem')]
    procedure CreateOpportunityTask()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0024 - refer to TFS ID 21735.
        // Test To-Do for opportunity Successfully created with Type Meeting.

        // 1. Setup: Create Contact, Sales Cycle and Sales Cycle Stage and Create Opportunity.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        InitializeGlobalVariable();
        SalesCycleCode := SalesCycleStage."Sales Cycle Code";
        SalespersonCode := Contact."Salesperson Code";

        CreateOpportunity(Contact."No.");

        // 2. Exercise: Create To-Do for Opportunity.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Task.SetRange("Opportunity No.", Opportunity."No.");
        TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify To-Do for opportunity Successfully created with Type Meeting.
        Task.FindFirst();
        Task.TestField("Salesperson Code", Contact."Salesperson Code");
        Task.TestField(Type, Task.Type::Meeting);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ModalHandlerOpportunityTask')]
    [Scope('OnPrem')]
    procedure ModifyOpportunityTask()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // Covers document number TC0024 - refer to TFS ID 21735.
        // Test To-Do for opportunity Successfully Updated with Type Meeting.

        // 1. Setup: Create Contact, Sales Cycle and Sales Cycle Stage and Create Opportunity.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        InitializeGlobalVariable();
        SalesCycleCode := SalesCycleStage."Sales Cycle Code";
        SalespersonCode := Contact."Salesperson Code";

        CreateOpportunity(Contact."No.");

        CreateSalespersonWithEmail(SalespersonPurchaser);

        // 2. Exercise: Create To-Do for Opportunity and Update Salesperson Code on Created To-Do.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Task.SetRange("Opportunity No.", Opportunity."No.");
        TempTask.CreateTaskFromTask(Task);

        Task.FindFirst();
        Task.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Task.Modify(true);

        // 3. Verify: Verify To-Do successfully changed to New salesperson Code.
        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Task.FindFirst();
        Task.TestField("Opportunity No.", Opportunity."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ModalHandlerOpportunityTask')]
    [Scope('OnPrem')]
    procedure DeleteOpportunityTask()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0024 - refer to TFS ID 21735.
        // Test To-Do for opportunity Successfully deleted with Type Meeting.

        // 1. Setup: Create Contact, Sales Cycle and Sales Cycle Stage and Create Opportunity.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        InitializeGlobalVariable();
        SalesCycleCode := SalesCycleStage."Sales Cycle Code";
        SalespersonCode := Contact."Salesperson Code";

        CreateOpportunity(Contact."No.");

        // 2. Exercise: Create To-Do for Opportunity and Delete the Created To-Do.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Task.SetRange("Opportunity No.", Opportunity."No.");
        TempTask.CreateTaskFromTask(Task);

        Task.FindFirst();
        Task.Delete(true);

        // 3. Verify: Verify To-Do for opportunity deleted.
        Task.SetRange("Opportunity No.", Opportunity."No.");
        Assert.IsFalse(Task.FindFirst(), StrSubstNo(ExistErr, Task.TableCaption(), Opportunity.TableCaption(), Task."No."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure OpportunityWOSalesQuote()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0025 - refer to TFS ID 21735.
        // Test error occurs on select Show Sales Quote for Opportunity without Create Sales Quote.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage and Create Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        CreateOpportunity(Contact."No.");

        // 2. Exercise: Update opportunity for Contact.
        UpdateOpportunityValue(Contact."No.");

        // 3. Verify: Verify error occurs on select Show Sales Quote for Opportunity.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        asserterror Opportunity.ShowSalesQuoteWithCheck();
        Assert.AreEqual(StrSubstNo(ShowSalesQuoteErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure UpdateOpportunityWOSalesQuote()
    var
        Contact: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0025 - refer to TFS ID 21735.
        // Test error occurs on update Opportunity without Create Sales Quote.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage and Create Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        CreateSalesCycleStage(SalesCycleStage, SalesCycleStage."Sales Cycle Code");
        SalesCycleStage.Validate("Quote Required", true);
        SalesCycleStage.Modify(true);
        CreateOpportunity(Contact."No.");

        // 2. Exercise: Update opportunity for Contact.
        UpdateOpportunityValue(Contact."No.");

        ActionType := ActionType::Next;
        CurrentSalesCycleStage := SalesCycleStage.Stage;

        // 3. Verify: Verify error occurs on update Opportunity without Create Sales Quote.
        asserterror UpdateOpportunityValue(Contact."No.");
        Assert.AreEqual(StrSubstNo(SalesQuoteErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity,FormHandlerSalesQuote')]
    [Scope('OnPrem')]
    procedure AssignSalesQuoteToOpportunity()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0025 - refer to TFS ID 21735.
        // Test Sales Quote successfully Assign to Opportunity.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage and Create Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        CreateOpportunity(Contact."No.");

        // 2. Exercise: Update opportunity for Contact and Create Sales Quote for Updated opportunity.
        UpdateOpportunityValue(Contact."No.");

        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CreateQuote();

        // 3. Verify: Verify Sales Quote successfully Assign to Opportunity.
        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::Quote);
        Opportunity.TestField("Sales Document No.", SalesQuoteNo);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity,FormHandlerSalesQuote,ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure MakeOrderFromQuote()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesHeader: Record "Sales Header";
    begin
        // Covers document number TC0025 - refer to TFS ID 21735.
        // Test error occurs on Make Order from Create Sales Quote to Active Opportunity.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage and Create Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        CreateOpportunity(Contact."No.");

        // 2. Exercise: Update opportunity for Contact and Create Sales Quote for Updated opportunity.
        UpdateOpportunityValue(Contact."No.");

        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CreateQuote();

        // 3. Verify: Verify error occurs on Make Order from Create Sales Quote to Active Opportunity.
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteNo);
        Commit();
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity,FormHandlerSalesQuote,ConfirmMessageHandler,ModalFormCloseOpportunity')]
    [Scope('OnPrem')]
    procedure CloseOpportunityWithWon()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesHeader: Record "Sales Header";
    begin
        // Covers document number TC0025 - refer to TFS ID 21735.
        // Test Sales Order created after Close Opportunity with Won option having Assigned Sales Quote.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage, Create Opportunity for Contact and Update Opportunity.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActionTaken := ActionTaken::Won;

        CreateOpportunity(Contact."No.");
        UpdateOpportunityValue(Contact."No.");

        // 2. Exercise: Create Sales Quote to Opportunity and Make order from assigned Sales Quote.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CreateQuote();
        Commit();

        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteNo);
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // 3. Verify: Verify Sale Quote Deleted and Sale Order Created.
        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuoteNo),
          StrSubstNo(ExistErr, SalesHeader.TableCaption(), SalesHeader."Document Type", SalesQuoteNo));
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Quote No.", SalesQuoteNo);
        SalesHeader.FindFirst();
        SalesHeader.TestField("Opportunity No.", Opportunity."No.");
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity,ModalFormCloseOpportunity')]
    [Scope('OnPrem')]
    procedure SalesQuoteToCloseOpportunity()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0025 - refer to TFS ID 21735.
        // Test error occurs on Create Sales Quote to close Opportunity.

        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage, Create Opportunity for Contact and Update Opportunity.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActionTaken := ActionTaken::Lost;

        CreateOpportunity(Contact."No.");
        UpdateOpportunityValue(Contact."No.");

        // 2. Exercise: Close opportunity for Contact.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();

        // 3. Verify: Verify error occurs on Create Sales Quote to close Opportunity.
        Opportunity.Get(Opportunity."No.");
        asserterror Opportunity.CreateQuote();
        Assert.ExpectedTestFieldError(Opportunity.FieldCaption(Status), Format(Opportunity.Status::"In Progress"));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerOpportunityStatis,FormHandlerContactStatis,FormHandlerSalesPersonStatis,FormHandlerSalesCycleStatis,FormHandlerSalesCycleStage')]
    [Scope('OnPrem')]
    procedure StatisticsOpenOpportunity()
    var
        Contact: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0026 - refer to TFS ID 21735.
        // Test Opportunity, Contact, Salesperson, Sales cycle and Sales Cycle Stage Statistics values after creation of Opportunity.

        // 1. Setup: Create Contact, Sales Cycle and Sales Cycle Stage.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActivateFirstStage := true;
        Completed := SalesCycleStage."Completed %";

        // 2. Exercise: Create opportunity for Contact.
        CreateOpportunity(Contact."No.");

        // 3. Verify: Verify Opportunity, Contact, Salesperson, Sales cycle and Sales Cycle Stage Statistics values.
        RunAndVerifyContactOpportunity(Contact, WizardEstimatedValueLCY, WizardChancesOfSuccessPercent, Completed);

        RunSalesCycleStatistics(SalesCycleStage."Sales Cycle Code");
        VerifySalesCycleStatistics(SalesCycle2, WizardEstimatedValueLCY, WizardChancesOfSuccessPercent, Completed);

        RunSalesCycleStageStatistics(SalesCycleStage);
        VerifySalesStageStatistics(SalesCycleStage2, WizardEstimatedValueLCY, WizardChancesOfSuccessPercent, Completed);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ModalFormCloseOpportunity,FormHandlerOpportunityStatis,FormHandlerContactStatis,FormHandlerSalesPersonStatis,FormHandlerSalesCycleStatis,FormHandlerSalesCycleStage')]
    [Scope('OnPrem')]
    procedure StatisticsCloseOpportunity()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // Covers document number TC0026 - refer to TFS ID 21735.
        // Test Opportunity, Contact, Salesperson, Sales cycle and Sales Cycle Stage Statistics values after closing of Opportunity.

        // 1. Setup: Create Contact, Sales Cycle Sales Cycle Stage and Create Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActivateFirstStage := true;
        Completed := SalesCycleStage."Completed %";
        ActionTaken := ActionTaken::Won;

        CreateOpportunity(Contact."No.");

        // 2. Exercise: Close opportunity for Contact.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();

        // 3. Verify: Verify Opportunity, Contact, Salesperson, Sales cycle and Sales Cycle Stage Statistics values.
        RunAndVerifyContactOpportunity(Contact, WizardEstimatedValueLCY, 100, 100);

        // Use 0 because after Close Activity fields on Sale Cycle and Sales Cycle Stage Statistics updated to 0.
        RunSalesCycleStatistics(SalesCycleStage."Sales Cycle Code");
        VerifySalesCycleStatistics(SalesCycle2, 0, 0, 0);

        RunSalesCycleStageStatistics(SalesCycleStage);
        VerifySalesStageStatistics(SalesCycleStage2, 0, 0, 0);
    end;

    local procedure RunAndVerifyContactOpportunity(var Contact: Record Contact; EstimatedValue: Decimal; ChancesOfSuccessPercent: Integer; Completed: Integer)
    begin
        RunOpportunityStatistics(Contact."No.");
        VerifyOpportunityStatistics(Opportunity2, CurrentSalesCycleStage, EstimatedValue, ChancesOfSuccessPercent, Completed);

        RunContactStatistics(Contact);
        VerifyContactStatistics(Contact2, EstimatedValue, ChancesOfSuccessPercent, Completed);

        RunSalespersonStatistics(Contact."Salesperson Code");
        VerifySalespersonStatistics(SalespersonPurchaser2, EstimatedValue, ChancesOfSuccessPercent, Completed);
    end;

    [Test]
    [HandlerFunctions('OpportunityCardHandler,ModalFormHandlerOpportunity')]
    [Scope('OnPrem')]
    procedure OpportunityStatisticsFactBox()
    var
        Contact: Record Contact;
        SalesCycleStage: Record "Sales Cycle Stage";
        Opportunity: Record Opportunity;
        OpportunityCard: Page "Opportunity Card";
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO 171760] Opportunity 'Statistics' factbox shows relevant information

        // [GIVEN] Opportunity
        PrepareOpportunityWithSalesCycle(Contact, SalesCycleStage);

        // [WHEN] Opportunity page is opened
        // [THEN] Statistics FactBox shows values corresponding to current record
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();

        Clear(OpportunityCard);
        OpportunityCard.SetRecord(Opportunity);
        OpportunityCard.Run();
    end;

    [Test]
    [HandlerFunctions('SalesCyclesHandler,ModalFormHandlerOpportunity')]
    [Scope('OnPrem')]
    procedure SalesCycleStatisticsFactBox()
    var
        Contact: Record Contact;
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesCycles: Page "Sales Cycles";
    begin
        // [FEATURE] [Sales Cycle]
        // [SCENARIO 171760] Sales Cycles 'Statistics' factbox shows relevant information

        // [GIVEN] Sales Cycle
        PrepareOpportunityWithSalesCycle(Contact, SalesCycleStage);

        // [WHEN] Sales Cycles page is opened
        // [THEN] Statistics FactBox shows values corresponding to current record
        SalesCycle.SetRange(Code, SalesCycleCode);
        SalesCycle.FindFirst();

        Clear(SalesCycles);
        SalesCycles.SetRecord(SalesCycle);
        SalesCycles.Run();
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,CustomerTemplateListModalPageHandler,ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityAssignSalesQuoteWithCustTemplateWithNewCustomer()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        OpportunityCard: TestPage "Opportunity Card";
        SalesQuote: TestPage "Sales Quote";
        CustomerTemplateCode: Code[20];
        ActionOption: Option LookupOK,Cancel;
    begin
        // [SCENARIO 180155] Create Sales Quote from Opportunity with a new Customer using Customer Template selection.
        // [SCENARIO 253087] Update the dialogs and modal windows.
        Initialize();

        // [GIVEN] Contact "C" with Company Type, Customer Template "CT"
        CustomerTemplateCode := CreateCustomerTemplateForContact('');
        Contact.Get(CreateContactWithCustTemplateAndOpportunity(true));

        // [GIVEN] Opportunity for Contact "C"
        OpenOpportunityCardForContact(OpportunityCard, Contact."No.");
        SalesQuote.Trap();

        // [WHEN] Create Sales Quote from Opportunity where user selects to create new Customer from the "CT".
        LibraryVariableStorage.Enqueue(ActionOption::LookupOK);
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        OpportunityCard.CreateSalesQuote.Invoke();

        // [THEN] Sales Quote with a new Customer and "Sell-to Customer Template Code" = "CT" is created
        SalesQuote."Sell-to Contact No.".AssertEquals(Contact."No.");
        SalesQuote."Sell-to Customer Templ. Code".AssertEquals(CustomerTemplateCode);
        Customer.Get(SalesQuote."Sell-to Customer No.".Value());
        Customer.TestField(Name, Contact."Company Name");
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,CustomerTemplateListModalPageHandler,ConfirmMessageHandlerYesNo')]
    [Scope('OnPrem')]
    procedure OpportunityAssignSalesQuoteWithCustTemplateWithNoNewCustomer()
    var
        OpportunityCard: TestPage "Opportunity Card";
        SalesQuote: TestPage "Sales Quote";
        CustomerTemplateCode: Code[20];
        ContactNo: Code[20];
        ActionOption: Option LookupOK,Cancel;
    begin
        // [SCENARIO 180155] Create Sales Quote from Opportunity without a new Customer but with Customer Template selection applied.
        // [SCENARIO 253087] Update the dialogs and modal windows.
        Initialize();

        // [GIVEN] Contact "C" with Company Type, Customer Template "CT"
        CustomerTemplateCode := CreateCustomerTemplateForContact('');
        ContactNo := CreateContactWithCustTemplateAndOpportunity(true);

        // [GIVEN] Opportunity for Contact "C"
        OpenOpportunityCardForContact(OpportunityCard, ContactNo);
        SalesQuote.Trap();

        // [WHEN] Create Sales Quote from Opportunity, where user declines to create new Customer, and also selects the Customer Tempalate "CT" to assign to the Sales Quote
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ActionOption::LookupOK);
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        OpportunityCard.CreateSalesQuote.Invoke();

        // [THEN] Sales Quote with Sell-to Customer Template Code "CT" is created and new Customer is not created
        SalesQuote."Sell-to Contact No.".AssertEquals(ContactNo);
        SalesQuote."Sell-to Customer No.".AssertEquals('');
        SalesQuote."Sell-to Customer Templ. Code".AssertEquals(CustomerTemplateCode);
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,CustomerTemplateListModalPageHandler,ConfirmMessageHandlerYesNo')]
    [Scope('OnPrem')]
    procedure OpportunityAssignSalesQuoteWithCustTemplateWithNoNewCustomerWhenTemplateSelectionCancel()
    var
        OpportunityCard: TestPage "Opportunity Card";
        SalesQuote: TestPage "Sales Quote";
        ContactNo: Code[20];
        ActionOption: Option LookupOK,Cancel;
    begin
        // [SCENARIO 253087] Sales Quote created from Opportunity where user declines to create Customer and confirms to add Customer Template and then cancels the Customer Template page.
        Initialize();

        // [GIVEN] Contact "C" with Company Type
        ContactNo := CreateContactWithCustTemplateAndOpportunity(true);

        // [GIVEN] Opportunity for Contact "C"
        OpenOpportunityCardForContact(OpportunityCard, ContactNo);
        SalesQuote.Trap();

        // [WHEN] Create Sales Quote from Opportunity where User declines to create new Customer from a Customer Templates, confirms to assign Customer Template but Cancel the Customer Template selection.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ActionOption::Cancel);
        OpportunityCard.CreateSalesQuote.Invoke();

        // [THEN] Sales Quote is created based on Contact without a new Customer and without a Customer Template
        SalesQuote."Sell-to Contact No.".AssertEquals(ContactNo);
        SalesQuote."Sell-to Customer No.".AssertEquals('');
        SalesQuote."Sell-to Customer Templ. Code".AssertEquals('');
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure OpportunityAssignSalesQuoteWithNoCustTemplateWithNoNewCustomer()
    var
        OpportunityCard: TestPage "Opportunity Card";
        SalesQuote: TestPage "Sales Quote";
        ContactNo: Code[20];
    begin
        // [SCENARIO 180155] Sales Quote created from Opportunity without creating a new Customer and without Customer Template.
        // [SCENARIO 253087] Update the dialogs and modal windows.
        Initialize();

        // [GIVEN] Contact "C" with Company Type
        ContactNo := CreateContactWithCustTemplateAndOpportunity(true);

        // [GIVEN] Opportunity for Contact "C"
        OpenOpportunityCardForContact(OpportunityCard, ContactNo);
        SalesQuote.Trap();

        // [WHEN] Create Sales Quote from Opportunity where User declines to create new Customer from a Customer Templates, and also declines to assign Customer Template to the Sales Quote
        OpportunityCard.CreateSalesQuote.Invoke();

        // [THEN] Sales Quote is created based on Contact without a new Customer and without a Customer Template
        SalesQuote."Sell-to Contact No.".AssertEquals(ContactNo);
        SalesQuote."Sell-to Customer No.".AssertEquals('');
        SalesQuote."Sell-to Customer Templ. Code".AssertEquals('');
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityAssignSalesQuoteEnabledDisabled()
    var
        OpportunityCard: TestPage "Opportunity Card";
        ContactNo: Code[20];
    begin
        // [SCENARIO 180155] Assign Quote enabled after activation of first stage of Opportunity
        Initialize();

        // [GIVEN] New Opportunity "O"
        ContactNo := CreateContactWithCustTemplateAndOpportunity(false);

        // [WHEN] Opportunity card for Opportunity "O" opened
        OpenOpportunityCardForContact(OpportunityCard, ContactNo);

        // [THEN] "Create Sales Quote" action is not enabled
        Assert.IsFalse(OpportunityCard.CreateSalesQuote.Enabled(), ActionShouldBeDisabledErr);

        // [WHEN] First Stage of Opportunity activated
        OpportunityCard."Activate the First Stage".Invoke();

        // [THEN] "Create Sales Quote" action is enabled
        Assert.IsTrue(OpportunityCard.CreateSalesQuote.Enabled(), ActionShouldBeEnabledErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,CustomerTemplateListModalPageHandler,ConfirmMessageHandler,MessageHandler,CloseOpportunityVerifyHandler,FormHandlerSalesOrder')]
    [Scope('OnPrem')]
    procedure CloseOpportunityOnSalesQuoteToOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CloseOpportunityCode: Record "Close Opportunity Code";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        OpportunityCard: TestPage "Opportunity Card";
        SalesQuote: TestPage "Sales Quote";
        CustomerTemplateCode: Code[20];
        ContactNo: Code[20];
        ActionOption: Option LookupOK,Cancel;
    begin
        // [SCENARIO 180154] Close Opportunity on creation of Sales Order from Sales Quote sets default fields
        Initialize();

        // [GIVEN] Contact "C"
        CreateVATPostingSetup(VATPostingSetup);
        CustomerTemplateCode := CreateCustomerTemplateForContact(VATPostingSetup."VAT Bus. Posting Group");
        ContactNo := CreateContactWithCustTemplateAndOpportunity(true);

        // [GIVEN] Close Opportunity Code "COP"
        LibraryMarketing.CreateCloseOpportunityCode(CloseOpportunityCode);
        CloseOpportunityCode.Validate(Type, CloseOpportunityCode.Type::Won);
        CloseOpportunityCode.Modify();

        // [GIVEN] Opportunity for Contact "C"
        OpenOpportunityCardForContact(OpportunityCard, ContactNo);
        SalesQuote.Trap();

        // [GIVEN] Sales Quote created from Opportunity with Amount "SA"
        LibraryVariableStorage.Enqueue(ActionOption::LookupOK);
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        OpportunityCard.CreateSalesQuote.Invoke();
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuote."No.".Value);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithPostingSetup(GenProductPostingGroup.Code, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify();

        LibraryVariableStorage.Enqueue(CloseOpportunityCode.Code);
        LibraryVariableStorage.Enqueue(GetSalesDocValue(SalesHeader));

        // [WHEN] Make Order run
        SalesQuote.MakeOrder.Invoke();

        // [THEN] "Close Opportunity" page is opened with "Opportunity Status" = Won, "Cancel Old To-dos" = TRUE, Sales (LCY) = "SA",
        // [THEN] Closing Date = WORKDATE,
        // Verified in CloseOpportunityVerifyHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityCardCommentForSuiteUserExperience()
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        OpportunityCard: TestPage "Opportunity Card";
        RlshpMgtCommentSheet: TestPage "Rlshp. Mgt. Comment Sheet";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199903] User is able to add comments for opportunity when user experience is Suite from card page
        Initialize();

        // [GIVEN] Create opportunity XXX
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");

        // [GIVEN] Create comment YYY for opportunity XXX
        CreateOpportunityCommentLine(RlshpMgtCommentLine, Opportunity);

        // [GIVEN] Open opportunity card page
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);

        // [WHEN] Action Comments is being hit
        RlshpMgtCommentSheet.Trap();
        OpportunityCard."Co&mments".Invoke();

        // [THEN] Comment YYY is displayed in the opened Rlshp. Mgt. Comment Sheet page
        RlshpMgtCommentSheet.Date.AssertEquals(RlshpMgtCommentLine.Date);
        RlshpMgtCommentSheet.Comment.AssertEquals(RlshpMgtCommentLine.Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityListCommentForSuiteUserExperience()
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        OpportunityList: TestPage "Opportunity List";
        RlshpMgtCommentSheet: TestPage "Rlshp. Mgt. Comment Sheet";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199903] User is able to add comments for opportunity when user experience is Suite from list page
        Initialize();

        // [GIVEN] Create opportunity XXX
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");

        // [GIVEN] Create comment YYY for opportunity XXX
        CreateOpportunityCommentLine(RlshpMgtCommentLine, Opportunity);

        // [GIVEN] Open opportunity card page
        OpportunityList.OpenView();
        OpportunityList.GotoRecord(Opportunity);

        // [WHEN] Action Comments is being hit
        RlshpMgtCommentSheet.Trap();
        OpportunityList."Co&mments".Invoke();

        // [THEN] Comment YYY is displayed in the opened Rlshp. Mgt. Comment Sheet page
        RlshpMgtCommentSheet.Date.AssertEquals(RlshpMgtCommentLine.Date);
        RlshpMgtCommentSheet.Comment.AssertEquals(RlshpMgtCommentLine.Comment);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CreateOppWithActivationOnCloseCard()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201923] User creates Opportunity and activates first stage on closing card page
        Initialize();
        // [GIVEN] New Opportunity
        OpportunityCard.OpenNew();
        OpportunityCard."Sales Cycle Code".SetValue(CreateSalesCycleWithStage());
        Opportunity.Get(OpportunityCard."No.".Value);
        // [WHEN] Close Opportunity card and click "OK" for first stage activation question
        OpportunityCard.Close();
        // [THEN] Opportunity created, first stage is activated, Status = "In Progress"
        Opportunity.Get(Opportunity."No.");
        Assert.IsTrue(Opportunity.Status = Opportunity.Status::"In Progress", OppStatusErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure CreateOppWithoutActivationOnCloseCard()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201923] User creates Opportunity and doesn't activate first stage on closing card page
        Initialize();
        // [GIVEN] New Opportunity
        OpportunityCard.OpenNew();
        OpportunityCard."Sales Cycle Code".SetValue(CreateSalesCycleWithStage());
        Opportunity.Get(OpportunityCard."No.".Value);
        // [WHEN] Close Opportunity card and click "Cancel" for first stage activation question
        OpportunityCard.Close();
        // [THEN] Opportunity created, first stage is not activated, Status = "Not Started"
        Opportunity.Get(Opportunity."No.");
        Assert.IsTrue(Opportunity.Status = Opportunity.Status::"Not Started", OppStatusErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OppCreationDate()
    var
        Opportunity: Record Opportunity;
        CreationDate: Date;
    begin
        // [SCENARIO 186663] Opportunity "Creation Date" is equal to WORKDATE after it was created
        Initialize();
        // [GIVEN] Creation Date = "CD" = WORKDATE
        CreationDate := WorkDate();
        // [WHEN] Create opportunity "O"
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());
        // [THEN] "O"."Creation Date" = "CD"
        Assert.AreEqual(CreationDate, Opportunity."Creation Date", CreationDateErr);
    end;

    [Test]
    [HandlerFunctions('CampaignListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LookupCampaigns()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
        CampaignNo: Code[20];
    begin
        // [SCENARIO 186663] Lookup to "Campaign No." field from Opportunity card.
        // Only Campaigns with Campaign."Starting Date" <= Opportunity."Creation Date" => Campaign."Ending Date" are available for selection.
        CleanCampaignAndSegmentTables();
        // [GIVEN] Creation Date = WORKDATE
        // [GIVEN] Campaign "C1" with Starting Date = WorkDate() - 1 and Ending Date = WorkDate() + 1
        CampaignNo := CreateCampaignWithDates(WorkDate() - 1, WorkDate() + 1);
        LibraryVariableStorage.Enqueue(CampaignNo);
        // [GIVEN] Campaign "C2" with Starting Date = WorkDate() + 1 and Ending Date = WorkDate() + 2
        CreateCampaignWithDates(WorkDate() + 1, WorkDate() + 2);
        // [GIVEN] Opportunity "O" with Creation Date = WORKDATE
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());
        // [WHEN] Lookup to "Campaign No." field from Opportunity card
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);
        OpportunityCard."Campaign No.".Lookup();
        // [THEN] Campaings' list page contains only "C1" campaign. Verify in CampaignListPageHandler.
        // [THEN] "O"."Campaign No." = "C1"."No."
        Assert.AreEqual(CampaignNo, OpportunityCard."Campaign No.".Value, CampaignNoErr);
    end;

    [Test]
    [HandlerFunctions('SegmentListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure LookupSegments()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
        CampaignNo: Code[20];
        SegmentHeaderNo: Code[20];
    begin
        // [SCENARIO 186663] Lookup to "Segment No." field from Opportunity card.
        // Only Segments related to "Campaign No." in the Opportunity card are available for selection.
        CleanCampaignAndSegmentTables();
        // [GIVEN] Campaign "C1"
        CampaignNo := CreateCampaignWithDates(WorkDate() - 1, WorkDate() + 1);
        // [GIVEN] Segment "S1" with "Campaign No." = "C1"."No."
        SegmentHeaderNo := CreateSegmentWithCampaign(CampaignNo);
        LibraryVariableStorage.Enqueue(SegmentHeaderNo);
        // [GIVEN] Opportunity "O" with "Campaign No." = "C1"."No."
        CreateOpportunityWithCampaign(Opportunity, CampaignNo);
        // [GIVEN] Campaign "C2"
        CampaignNo := CreateCampaignWithDates(WorkDate() + 1, WorkDate() + 2);
        // [GIVEN] Segment "S2" with "Campaign No." = "C2"."No."
        CreateSegmentWithCampaign(CampaignNo);
        // [WHEN] Lookup to "Segment No." field from Opportunity card
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);
        OpportunityCard."Segment No.".Lookup();
        // [THEN] Segments' list page contains only S1 segment. Verify in SegmentListPageHandler.
        // [THEN] "O"."Segment No." = "S1"."No."
        Assert.AreEqual(SegmentHeaderNo, OpportunityCard."Segment No.".Value, SegmentNoErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OppCampaignNoWithWrongDatesCampaign()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
        CampaignNo: Code[20];
    begin
        // [SCENARIO 186663] User manually updates "Campaign No." field in the Opportunity card with campaign with dates out Opportunity Createion Date
        CleanCampaignAndSegmentTables();
        // [GIVEN] Creation Date = WORKDATE
        // [GIVEN] Campaign "C1" with Starting Date = WorkDate() + 1 and Ending Date = WorkDate() + 2
        CampaignNo := CreateCampaignWithDates(WorkDate() + 1, WorkDate() + 2);
        // [GIVEN] Opportunity "O" with Creation Date = WORKDATE
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());
        // [WHEN] Validate "Campaign No." field in the Opportunity card with "C1"."No."
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);
        asserterror OpportunityCard."Campaign No.".SetValue(CampaignNo);
        // [THEN] Error message appeared
        Assert.ExpectedError(StrSubstNo(OppCampaignNoErr, CampaignNo, Opportunity."No."));
    end;

    [Test]
    [HandlerFunctions('OpportunityCreatedSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure NotificationOnCreateOpportunityFromIntLogEntry()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntries: TestPage "Interaction Log Entries";
        OpportunityNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201759] Notification displayed when opportunity is being created from interaction log entry
        Initialize();

        // [GIVEN] Mock interaction log entry
        MockInterLogEntry(InteractionLogEntry);

        // [GIVEN] Open interaction log entry in the Interaction Log Entries page
        InteractionLogEntries.OpenView();
        InteractionLogEntries.GotoRecord(InteractionLogEntry);

        // Mock created opportunity number
        OpportunityNo := FindNextOpportunityNo();

        // [WHEN] Action Create Opportunity is being hit
        // [THEN] Notification displayed: 'Opportunity <Opportunity No.> was created based on selected interaction log entry'.
        LibraryVariableStorage.Enqueue(OpportunityNo);
        InteractionLogEntries.CreateOpportunity.Invoke();
    end;

    [Test]
    [HandlerFunctions('OpportunityCreatedSendNotificationHandlerWithAction')]
    [Scope('OnPrem')]
    procedure OpenOpportunityFromOnCreateOpportunityNotification()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntries: TestPage "Interaction Log Entries";
        OpportunityCard: TestPage "Opportunity Card";
        OpportunityNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 201759] Message displayed when opportunity is being created from interaction log entry
        Initialize();

        // [GIVEN] Mock interaction log entry
        MockInterLogEntry(InteractionLogEntry);

        // [GIVEN] Open interaction log entry in the Interaction Log Entries page
        InteractionLogEntries.OpenView();
        InteractionLogEntries.GotoRecord(InteractionLogEntry);

        // Mock created opportunity number XXX
        OpportunityNo := FindNextOpportunityNo();

        // [GIVEN] Action Create Opportunity hit, opportunity XXX created
        OpportunityCard.Trap();
        InteractionLogEntries.CreateOpportunity.Invoke();

        // [WHEN] User clicks Open Opportunity link
        // [THEN] Opportunity card is opened with created opportunity XXX
        OpportunityCard."No.".AssertEquals(OpportunityNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateOppFromCampaignUT()
    var
        Campaign: Record Campaign;
        Opportunity: Record Opportunity;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 207179] Opportunity created from Campaign should have filled in "Campaign No." after.
        Initialize();
        // [GIVEN] Campaign "C"
        LibraryMarketing.CreateCampaign(Campaign);
        // [GIVEN] Opportunity "O" with filter for "Campaign No."
        Opportunity.SetFilter("Campaign No.", Campaign."No.");
        Opportunity.SetCampaignFromFilter();
        // [WHEN] Insert "O"
        Opportunity.Insert(true);
        // [THEN] "O"."Campaign No." = "C"."No."
        Assert.AreEqual(Campaign."No.", Opportunity."Campaign No.", CampaignNoErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure VerifySalesCycleStageDescOnOppEntry()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        OpportunityEntry: Record "Opportunity Entry";
        Contact: Record Contact;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 208522] Field "Sales Cycle Stage Description" of Opportunity Entry update correctly when new entry is inserting and the value have to be shown in Opportunity Card.
        Initialize();

        // [GIVEN] "Contact" = "C" and "Sales Cycle Stage" with Description = "Descr"
        CreateContactWithSalesCycle(SalesCycleStage, Contact);
        LibraryUtility.FillFieldMaxText(SalesCycleStage, SalesCycleStage.FieldNo(Description));
        SalesCycleStage.Get(SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        // [GIVEN] Opportunity for contact - "C"
        CreateOpportunity(Contact."No.");

        // [WHEN] Updating the opportunity
        UpdateOpportunityValue(Contact."No.");

        // [THEN] "Opportunity Entry"."Description" = "Descr"
        OpportunityEntry.SetRange("Sales Cycle Code", SalesCycleStage."Sales Cycle Code");
        OpportunityEntry.SetRange("Sales Cycle Stage", SalesCycleStage.Stage);
        OpportunityEntry.FindFirst();
        OpportunityEntry.TestField("Sales Cycle Stage Description", SalesCycleStage.Description);

        // [THEN] Page Opportunity Card is showing value of Sales Cycle Stage Description = "Descr"
        OpportunityCard.OpenView();
        OpportunityCard.GotoKey(OpportunityEntry."Opportunity No.");
        OpportunityCard.Control25."Sales Cycle Stage Description".AssertEquals(SalesCycleStage.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesCycleStageDescOnOppEntryAfterValidateSalesCycleStage()
    var
        OpportunityEntry: Record "Opportunity Entry";
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesCycle: Record "Sales Cycle";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 208552] Value of "Sales Cycle Stage Description" of Opportunity Entry have to be filled after Validation of "Sales Cycle Stage"
        Initialize();

        // [GIVEN] "Sales Cycle Stage" with Description = "DESCR1" and "Sales Cycle Code" = "SCC"
        LibraryMarketing.CreateSalesCycle(SalesCycle);
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycle.Code);
        LibraryUtility.FillFieldMaxText(SalesCycle, SalesCycle.FieldNo(Description));
        SalesCycleStage.Get(SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        // [GIVEN] "Opportunity Entry" with "Sales Cycle Stage Description" = "DESCR2" and "Sales Cycle Code" = "SCC"
        OpportunityEntry.Init();
        OpportunityEntry."Entry No." := LibraryUtility.GetNewRecNo(OpportunityEntry, OpportunityEntry.FieldNo("Entry No."));
        OpportunityEntry."Sales Cycle Code" := SalesCycleStage."Sales Cycle Code";
        OpportunityEntry.Insert();
        LibraryUtility.FillFieldMaxText(OpportunityEntry, OpportunityEntry.FieldNo("Sales Cycle Stage Description"));
        OpportunityEntry.Get(OpportunityEntry."Entry No.");

        // [WHEN] Validate "Opportunity Entry"."Sales Cycle Stage"
        OpportunityEntry.Validate("Sales Cycle Stage", SalesCycleStage.Stage);

        // [THEN] "Opportunity Entry"."Sales Cycle Stage Description" = "DESCR1"
        OpportunityEntry.TestField("Sales Cycle Stage Description", SalesCycleStage.Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityCardSalesDocumentTypeFieldEmptyValueIsAllowed()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228825] Opportunity Card "Sales Document Type" field allows Empty value

        // [GIVEN] Create new Opportunity "O" on Opportunity Card page "OC"
        OpportunityCard.OpenNew();

        // [WHEN] Set "OC"."Sales Document Type" with value " "
        OpportunityCard."Sales Document Type".SetValue(Opportunity."Sales Document Type"::" ");
        Opportunity.Get(OpportunityCard."No.".Value);

        // [THEN] "O"."Sales Document Type" = " " and "OC"."Sales Document Type" = " "
        OpportunityCard."Sales Document Type".AssertEquals(Opportunity."Sales Document Type"::" ");
        OpportunityCard.Close();
        Opportunity.Get(Opportunity."No.");
        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityCardSalesDocumentTypeFieldOrderValueIsAllowed()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228825] Opportunity Card "Sales Document Type" field allows Order value

        // [GIVEN] Create new Opportunity "O" on Opportunity Card page "OC"
        OpportunityCard.OpenNew();

        // [WHEN]  Set "OC"."Sales Document Type" with value Order
        OpportunityCard."Sales Document Type".SetValue(Opportunity."Sales Document Type"::Order);
        Opportunity.Get(OpportunityCard."No.".Value);

        // [THEN] "O"."Sales Document Type" = Order and "OC"."Sales Document Type" = Order
        OpportunityCard."Sales Document Type".AssertEquals(Opportunity."Sales Document Type"::Order);
        OpportunityCard.Close();
        Opportunity.Get(Opportunity."No.");
        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpportunityCardSalesDocumentTypeFieldQuoteValueIsAllowed()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228825] Opportunity Card "Sales Document Type" field allows Quote value

        // [GIVEN] Create new Opportunity "O" on Opportunity Card page "OC"
        OpportunityCard.OpenNew();

        // [WHEN]  Set "OC"."Sales Document Type" with value Quote
        OpportunityCard."Sales Document Type".SetValue(Opportunity."Sales Document Type"::Quote);
        Opportunity.Get(OpportunityCard."No.".Value);

        // [THEN] "O"."Sales Document Type" = Quote and "OC"."Sales Document Type" = Quote
        OpportunityCard."Sales Document Type".AssertEquals(Opportunity."Sales Document Type"::Quote);
        OpportunityCard.Close();
        Opportunity.Get(Opportunity."No.");
        Opportunity.TestField("Sales Document Type", Opportunity."Sales Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityCardSalesDocumentTypeFieldInvoiceValueIsNotAllowed()
    var
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228825] Opportunity Card "Sales Document Type" field does not allow Posted Invoice value

        // [GIVEN] Create new Opportunity on Opportunity Card page "OC"
        OpportunityCard.OpenNew();

        // [WHEN] Set "OC"."Sales Document Type" with value Posted Invoice
        asserterror OpportunityCard."Sales Document Type".SetValue(Opportunity."Sales Document Type"::"Posted Invoice");

        // [THEN] "Sales Document Type" field validation not passed. Error raised 'Validation error for field Sales Document Type'
        Assert.ExpectedError(StrSubstNo(OppCardSalesDocTypeErr, OpportunityCard."Sales Document Type".Value));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure FirstStageActivationOfOpportunityCreatedFromSegmentCountTasks()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
        Contact: Record Contact;
        ToDo: Record "To-do";
        ActivityStep: Record "Activity Step";
    begin
        // [FEATURE] [Segment]
        // [SCENARIO 275160] Opportunity First Stage Activation creates number of tasks equal to Activity Steps
        Initialize();

        // [GIVEN] Contact, Sales Cycle with 5 Activity Step for 1st Stage
        CreateContactWithSalesCycle(SalesCycleStage, Contact);
        ActivityStep.SetRange("Activity Code", SalesCycleStage."Activity Code");

        // [GIVEN] Segment with Contact in Segment Line
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify();

        // [GIVEN] Opportunity created from Segment with Sales Cycle assigned
        Opportunity.CreateFromSegmentLine(SegmentLine);
        Opportunity."Sales Cycle Code" := SalesCycleStage."Sales Cycle Code";
        Opportunity.Modify();

        // [WHEN] Opportunity First Stage is activated
        Opportunity.StartActivateFirstStage();

        // [THEN] 5 Tasks created with "System To-do Type" = Organizer, Tasks count = Activity steps count
        ToDo.SetRange("Segment No.", SegmentHeader."No.");
        ToDo.SetRange("System To-do Type", ToDo."System To-do Type"::Organizer);
        Assert.RecordCount(ToDo, ActivityStep.Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityHasDescriptionAsSortingKey()
    var
        "Key": Record "Key";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277501] Opportunity table has key Description

        Initialize();

        Key.SetRange(TableNo, DATABASE::Opportunity);
        Key.SetRange(Key, 'Description');
        Assert.RecordIsNotEmpty(Key);
    end;

    [Test]
    [HandlerFunctions('SalesCycleStagesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateOpportunityPage_SalesCycleStageLookup()
    var
        SalesCycleStage: Record "Sales Cycle Stage";
        Result: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 309620] Table 5091 "Sales Cycle Stage" has LookupPageID value.
        Initialize();

        Result := PAGE.RunModal(0, SalesCycleStage) = ACTION::LookupOK;
        // OK is invoked at SalesCycleStagesModalPageHandler
        Assert.IsTrue(Result = true, 'Expected LookupOK');
    end;

    [Test]
    [HandlerFunctions('UpdateOpportunityModalPageHandler,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateOppotunityPageFieldSalesCycleDescription();
    var
        Opportunity: Record Opportunity;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 346726] Page "Update Entry" field "Sales Cycle Description" shows Description of Sales Cycle Stage.
        Initialize();

        // [GIVEN] Opportunity with Opportunity Entry.
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());
        Opportunity.StartActivateFirstStage();

        // [WHEN] Page "Update Entry" is opened.
        Opportunity.UpdateOpportunity();

        // [THEN] Page "Update Entry" field "Sales Cycle Description" is equal to Description of Sales Cycle Stage.
        SalesCycleStage.GET(Opportunity."Sales Cycle Code", LibraryVariableStorage.DequeueInteger());
        Assert.AreEqual(SalesCycleStage.Description, LibraryVariableStorage.DequeueText(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunitySegmentDescriptionValidation()
    var
        Opportunity: Record Opportunity;
        SegmentHeader: Record "Segment Header";
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO 365637] Validating "Segment No." on Opportunity also validates "Segment Description" from related Segment Header
        Initialize();

        // [GIVEN] Segment Header was created with No. = 0001 and Description = "XYZ"
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);

        // [GIVEN] Opportunity was created
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());

        // [WHEN] Validating Segment No. = 0001 on Opportunity
        Opportunity.Validate("Segment No.", SegmentHeader."No.");

        // [THEN] Segment description equals Segment Header's Description "XYZ"
        Opportunity.TestField("Segment Description", SegmentHeader.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunitySegmentDescriptionValidationEmptyNo()
    var
        Opportunity: Record Opportunity;
        SegmentHeader: Record "Segment Header";
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO 365637] Validating "Segment No." with empty No. on Opportunity clears "Segment Description"
        Initialize();

        // [GIVEN] Segment Header was created with No. = 0001 and Description = "XYZ"
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);

        // [GIVEN] Opportunity was created
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());

        // [GIVEN] Segment No. = 0001 on Opportunity, Segment Description = "XYZ"
        Opportunity.Validate("Segment No.", SegmentHeader."No.");

        // [WHEN] Validating Segment No. = ""
        Opportunity.Validate("Segment No.", '');

        // [THEN] Segment description is empty
        Opportunity.TestField("Segment Description", '');
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity,CustomerTemplateListModalPageHandler,ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SameOpportunityAssignToNewSalesQuote()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
        SalesQuote: TestPage "Sales Quote";
        CustomerTemplateCode: Code[20];
        ActionOption: Option LookupOK,Cancel;
    begin
        // [SCENARIO 462715] Same Opportunity No. cannot be inserted twice in a different Sales Quote
        Initialize();

        // [GIVEN] Contact "C" with Company Type, Customer Template "CT"
        CustomerTemplateCode := CreateCustomerTemplateForContact('');
        Contact.Get(CreateContactWithCustTemplateAndOpportunity(true));

        // [GIVEN] Opportunity for Contact "C"
        OpenOpportunityCardForContact(OpportunityCard, Contact."No.");
        Opportunity.Get(Format(OpportunityCard."No."));
        SalesQuote.Trap();

        // [WHEN] Create Sales Quote from Opportunity where user selects to create new Customer from the "CT" and Verify the Opportunity No. on Sales Quote
        LibraryVariableStorage.Enqueue(ActionOption::LookupOK);
        LibraryVariableStorage.Enqueue(CustomerTemplateCode);
        OpportunityCard.CreateSalesQuote.Invoke();
        Customer.Get(SalesQuote."Sell-to Customer No.".Value());
        Assert.AreEqual(Opportunity."No.", SalesQuote."Opportunity No.".Value, OppNoNotUpdatedOnSalesQuoteErr);
        SalesQuote.Close();

        // [GIVEN] Create New Sales Quote "SQ"
        CreateSalesQuoteWithCustomer(SalesHeader, Customer."No.");

        // [THEN] Open Sales Quote and set Opportunity
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote."Opportunity No.".SetValue(Opportunity."No.");
        SalesQuote.Close();
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesHeader."No.");

        // [VERIFY] Verify: Opportunity No. on New Sales Quote
        Assert.AreEqual(Opportunity."No.", SalesHeader."Opportunity No.", OppNoNotUpdatedOnSalesQuoteErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,FormHandlerUpdateOpportunity')]
    [Scope('OnPrem')]
    procedure SalesCycleStageWithOnlyOneActivityStepOfTypePhoneCallCreatesOnlyOneTask()
    var
        Contact: Record Contact;
        Activity: Record Activity;
        ActivityStep: Record "Activity Step";
        Opportunity: Record Opportunity;
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
        SalesHeader: Record "Sales Header";
        ToDo: Record "To-do";
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [SCENARIO 495997] When stan runs Update action from an Opportunity of Sales Cycle Stage having only one Activity Step of Type Phone Call then only one Task Line is created in Task List.
        Initialize();

        // [GIVEN] Create Contact of Type Person.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Create Activity with Activity Step Type Phone Call.
        CreateActivityWithActivityStepTypePhoneCall(Activity, ActivityStep);

        // [GIVEN] Create Sales Cycle.
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // [GIVEN] Create Sales Cycle Stage with blank Activity Code.
        CreateSalesCycleStageWithActivityCode(SalesCycle, SalesCycleStage, '');

        // [GIVEN] Create Sales Cycle Stage 2 with Activity Code.
        CreateSalesCycleStageWithActivityCode(SalesCycle, SalesCycleStage2, Activity.Code);

        // [GIVEN] Create Sales Quote with Contact.
        CreateSalesQuoteWithContact(SalesHeader, Contact);

        // [GIVEN] Create Opportunity and Validate Sales Cycle Code.
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");
        Opportunity.Validate("Sales Cycle Code", SalesCycle.Code);
        Opportunity.Modify(true);

        // [GIVEN] Open Opportunity Card page and run Activate the First Stage action.
        OpportunityCard.OpenEdit();
        OpportunityCard.GoToRecord(Opportunity);
        OpportunityCard."Activate the First Stage".Invoke();
        OpportunityCard.Close();

        // [GIVEN] Enter Sales Document Type and Sales Document No in Opportunity.
        Opportunity."Sales Document Type" := Opportunity."Sales Document Type"::Quote;
        Opportunity."Sales Document No." := SalesHeader."No.";
        Opportunity.Modify(true);

        // [GIVEN] Find and Update Opportunity.
        AssignGlobalVariables(ActionType::Next, SalesCycleStage2."Sales Cycle Code", SalesCycleStage2.Stage);
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.UpdateOpportunity();

        // [WHEN] Find Task.
        ToDo.SetRange("Opportunity No.", Opportunity."No.");

        // [VERIFY] Only one Task is created.
        Assert.IsTrue(ToDo.Count() = 1, ToDoCountShouldBeOneErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,CloseOpportunityPageHandler,CustomerCreated')]
    procedure ConvertContactIntoCustomerClosingOpportunity()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
        ContactCard: TestPage "Contact Card";
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [SCENARIO 527026] Convert a Contact into a Customer by closing the Opportunity with no linked to a Company No.
        Initialize();

        // [GIVEN] Create Contact of Type Person.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Open Conact card , go to record and invoke Opportunities.
        ContactCard.OpenEdit();
        ContactCard.GoToRecord(Contact);
        ContactCard."Oppo&rtunities".Invoke();

        // [GIVEN] Create Sales Cycle.
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // [GIVEN] Create Sales Cycle Stage with blank Activity Code.
        CreateSalesCycleStageWithActivityCode(SalesCycle, SalesCycleStage, '');

        // [GIVEN] Create Opportunity and Validate Sales Cycle Code.
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");
        Opportunity.Validate("Sales Cycle Code", SalesCycle.Code);
        Opportunity.Modify(true);

        // [GIVEN] Open Opportunity Card page and run Activate the First Stage action.
        OpportunityCard.OpenEdit();
        OpportunityCard.GoToRecord(Opportunity);
        OpportunityCard."Activate the First Stage".Invoke();

        // [THEN] Close Opportunity to verify if Customer is created.
        Opportunity.CloseOpportunity();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BuildCaptionLengthIssueOnOpportunitiesListPage()
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
        OpportunityList: TestPage "Opportunity List";
        FilterText: Text;
        i: Integer;
    begin
        // [SCENARIO 574639] The length of the string is XX but it must be less than or equal to 20 characters when working with Opportunities
        Initialize();

        // [GIVEN] Create contact and it's opportunity
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");

        // [GIVEN] Prepare Filter Text with Salesperson Code
        for i := 1 to LibraryRandom.RandIntInRange(20, 20) do
            FilterText += Opportunity."Salesperson Code" + '|';
        FilterText += Opportunity."Salesperson Code";

        // [THEN] Open Opportunities list page and apply salesperson code filter without issue
        Clear(FilterText);
        OpportunityList.OpenView();
        OpportunityList.Filter.SetFilter("Salesperson Code", FilterText);
        OpportunityList.Close();

        // [GIVEN] Prepare Filter Text with Contact No
        for i := 1 to LibraryRandom.RandIntInRange(20, 20) do
            FilterText += Contact."No." + '|';
        FilterText += Contact."No.";

        // [THEN] Open Opportunities list page and contacts filter without issue
        OpportunityList.OpenView();
        OpportunityList.Filter.SetFilter("Contact No.", FilterText);
        OpportunityList.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Opportunity Mgmt");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Opportunity Mgmt");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryApplicationArea.EnableRelationshipMgtSetup();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Opportunity Mgmt");
    end;

    local procedure InitializeGlobalVariable()
    begin
        SalesCycleCode := '';
        CurrentSalesCycleStage := 0;
        WizardEstimatedValueLCY := 0;
        WizardChancesOfSuccessPercent := 0;
        Clear(ActionType);
        SalespersonCode := '';
        SalesQuoteNo := '';
        Clear(ActionTaken);
        ActivateFirstStage := false;
        Completed := 0;
    end;

    local procedure AssignGlobalVariables(ActionType2: Option; SalesCycleCode2: Code[10]; Stage: Integer)
    begin
        InitializeGlobalVariable();
        ActionType := ActionType2;
        SalesCycleCode := SalesCycleCode2;

        // Use Random because value is not important.
        WizardEstimatedValueLCY := LibraryRandom.RandInt(100);
        WizardChancesOfSuccessPercent := LibraryRandom.RandInt(100);
        CurrentSalesCycleStage := Stage;
    end;

    local procedure PrepareOpportunityWithSalesCycle(var Contact: Record Contact; var SalesCycleStage: Record "Sales Cycle Stage")
    begin
        CreateContactWithSalesCycle(SalesCycleStage, Contact);
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActivateFirstStage := true;
        Completed := SalesCycleStage."Completed %";
        CreateOpportunity(Contact."No.");
    end;

    local procedure CreateAttendee(var TempAttendee: Record Attendee temporary; AttendeeNo: Code[20]; AttendanceType: Option)
    var
        LineNo: Integer;
    begin
        TempAttendee.SetRange("To-do No.", '');
        if TempAttendee.FindLast() then
            LineNo := TempAttendee."Line No." + 10000
        else
            LineNo := 10000;
        TempAttendee.Init();
        TempAttendee.Validate("Attendance Type", AttendanceType);
        TempAttendee.Validate("Attendee Type", TempAttendee."Attendee Type"::Salesperson);
        TempAttendee.Validate("Line No.", LineNo);  // Use 10000 for Line No.
        TempAttendee.Validate("Attendee No.", AttendeeNo);
        TempAttendee.Insert();
    end;

    local procedure CreateAndUpdateOpportunity(var Opportunity: Record Opportunity; var SalesCycleStage: Record "Sales Cycle Stage")
    var
        Contact: Record Contact;
        TempOpportunity: Record Opportunity temporary;
    begin
        // 1. Setup: Create Contact, Sales Cycle, Sales Cycle Stage and Opportunity for Contact.
        CreateContactWithSalesCycle(SalesCycleStage, Contact);

        // Set Global Variable for Form Handler.
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);

        Opportunity.SetRange("Contact No.", Contact."No.");
        TempOpportunity.CreateOppFromOpp(Opportunity);
        Commit();

        // 2. Exercise: Update Opportunity.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.UpdateOpportunity();
    end;

    local procedure CreateContactWithSalesCycle(var SalesCycleStage: Record "Sales Cycle Stage"; var Contact: Record Contact)
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesCycle: Record "Sales Cycle";
    begin
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, Contact."No.", BusinessRelation.Code);
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := LibrarySales.CreateCustomerNo();
        ContactBusinessRelation.Modify(true);
        CreateSalespersonWithEmail(SalespersonPurchaser);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Modify(true);

        LibraryMarketing.CreateSalesCycle(SalesCycle);
        CreateSalesCycleStage(SalesCycleStage, SalesCycle.Code);
    end;

    local procedure CreateCustomerTemplateForContact(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        CustomerTemplate: Record "Customer Templ.";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
        CustomerTemplate.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        CustomerTemplate.Validate("Payment Terms Code", PaymentTerms.Code);
        CustomerTemplate.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        CustomerTemplate.Modify();
        exit(CustomerTemplate.Code);
    end;

    local procedure CreateOpportunity(ContactNo: Code[20])
    var
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        TempOpportunity.CreateOppFromOpp(Opportunity);
    end;

    local procedure CreateContactWithCustTemplateAndOpportunity(ShouldActivateFirstStage: Boolean): Code[20]
    var
        Contact: Record Contact;
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateSalesCycle(SalesCycle);
        CreateSalesCycleStage(SalesCycleStage, SalesCycle.Code);
        AssignGlobalVariables(ActionType::First, SalesCycleStage."Sales Cycle Code", SalesCycleStage.Stage);
        ActivateFirstStage := ShouldActivateFirstStage;
        CreateOpportunity(Contact."No.");
        exit(Contact."No.");
    end;

    local procedure CreateOpportunityWithCampaign(var Opportunity: Record Opportunity; CampaignNo: Code[20])
    begin
        LibraryMarketing.CreateOpportunity(Opportunity, LibraryMarketing.CreateCompanyContactNo());
        Opportunity.Validate("Campaign No.", CampaignNo);
        Opportunity.Modify(true);
    end;

    local procedure CreateOpportunityCommentLine(var RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line"; Opportunity: Record Opportunity)
    var
        RecRef: RecordRef;
    begin
        RlshpMgtCommentLine.Init();
        RlshpMgtCommentLine.Validate("Table Name", RlshpMgtCommentLine."Table Name"::Opportunity);
        RlshpMgtCommentLine.Validate("No.", Opportunity."No.");
        RlshpMgtCommentLine.Validate(Date, WorkDate());
        RecRef.GetTable(RlshpMgtCommentLine);
        RlshpMgtCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, RlshpMgtCommentLine.FieldNo("Line No.")));
        RlshpMgtCommentLine.Comment := LibraryUtility.GenerateRandomCode(RlshpMgtCommentLine.FieldNo(Comment), DATABASE::"Rlshp. Mgt. Comment Line");
        RlshpMgtCommentLine.Insert(true);
    end;

    local procedure CreateSalesCycleStage(var SalesCycleStage: Record "Sales Cycle Stage"; SalesCycleCode: Code[10])
    var
        Activity: Record Activity;
    begin
        Activity.FindFirst();
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycleCode);
        SalesCycleStage.Validate("Completed %", LibraryRandom.RandInt(100));  // Use Random because value is not important.
        SalesCycleStage.Validate("Chances of Success %", LibraryRandom.RandInt(100));  // Use Random because value is not important.
        SalesCycleStage.Validate("Activity Code", Activity.Code);
        SalesCycleStage.Modify(true);
    end;

    local procedure CreateSalesCycleWithStage(): Code[10]
    var
        SalesCycle: Record "Sales Cycle";
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        LibraryMarketing.CreateSalesCycle(SalesCycle);
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycle.Code);
        exit(SalesCycle.Code);
    end;

    local procedure CreateSalespersonWithEmail(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate(
          "E-Mail", LibraryUtility.GenerateRandomEmail());
        SalespersonPurchaser.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
    end;

    local procedure CreateCampaignWithDates(StartingDate: Date; EndingDate: Date): Code[20]
    var
        Campaign: Record Campaign;
        CampaignTargetGroup: Record "Campaign Target Group";
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", StartingDate);
        Campaign.Validate("Ending Date", EndingDate);
        Campaign.Modify(true);

        CampaignTargetGroup.Init();
        CampaignTargetGroup."No." := Campaign."No.";
        CampaignTargetGroup."Campaign No." := Campaign."No.";
        CampaignTargetGroup.Insert();

        exit(Campaign."No.");
    end;

    local procedure CreateSegmentWithCampaign(CampaignNo: Code[20]): Code[20]
    var
        SegmentHeader: Record "Segment Header";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Campaign No.", CampaignNo);
        SegmentHeader.Modify();
        exit(SegmentHeader."No.");
    end;

    local procedure CleanCampaignAndSegmentTables()
    var
        Campaign: Record Campaign;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        Campaign.DeleteAll();
        SegmentHeader.DeleteAll();
        SegmentLine.DeleteAll();
    end;

    local procedure GetSalesDocValue(SalesHeader: Record "Sales Header"): Decimal
    var
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        VATAmount: Decimal;
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
    begin
        SalesPost.SumSalesLines(
          SalesHeader, 0, TotalSalesLine, TotalSalesLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);
        exit(TotalSalesLineLCY.Amount);
    end;

    local procedure FindNextOpportunityNo(): Code[20]
    var
        MarketingSetup: Record "Marketing Setup";
        NoSeries: Codeunit "No. Series";
    begin
        MarketingSetup.Get();
        exit(NoSeries.PeekNextNo(MarketingSetup."Opportunity Nos."));
    end;

    local procedure MockInterLogEntry(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
        InteractionLogEntry.Init();
        InteractionLogEntry."Entry No." := LibraryUtility.GetNewRecNo(InteractionLogEntry, InteractionLogEntry.FieldNo("Entry No."));
        InteractionLogEntry.Insert();
    end;

    local procedure OpenOpportunityCardForContact(var OpportunityCard: TestPage "Opportunity Card"; ContactNo: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);
    end;

    local procedure RunContactStatistics(Contact: Record Contact)
    var
        ContactStatistics: Page "Contact Statistics";
    begin
        Clear(ContactStatistics);
        ContactStatistics.SetRecord(Contact);
        ContactStatistics.Run();
    end;

    local procedure RunOpportunityStatistics(ContactNo: Code[20])
    var
        Opportunity: Record Opportunity;
        OpportunityStatistics: Page "Opportunity Statistics";
    begin
        Clear(OpportunityStatistics);
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        OpportunityStatistics.SetRecord(Opportunity);
        OpportunityStatistics.Run();
    end;

    local procedure RunSalesCycleStatistics(SalesCycleCode: Code[10])
    var
        SalesCycle: Record "Sales Cycle";
        SalesCycleStatistics: Page "Sales Cycle Statistics";
    begin
        Clear(SalesCycleStatistics);
        SalesCycle.SetRange(Code, SalesCycleCode);
        SalesCycle.FindFirst();
        SalesCycleStatistics.SetRecord(SalesCycle);
        SalesCycleStatistics.Run();
    end;

    local procedure RunSalesCycleStageStatistics(SalesCycleStage: Record "Sales Cycle Stage")
    var
        SalesCycleStageStatistics: Page "Sales Cycle Stage Statistics";
    begin
        Clear(SalesCycleStageStatistics);
        SalesCycleStageStatistics.SetRecord(SalesCycleStage);
        SalesCycleStageStatistics.Run();
    end;

    local procedure RunSalespersonStatistics(SalespersonCode: Code[20])
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonStatistics: Page "Salesperson Statistics";
    begin
        Clear(SalespersonStatistics);
        SalespersonPurchaser.SetRange(Code, SalespersonCode);
        SalespersonPurchaser.FindFirst();
        SalespersonStatistics.SetRecord(SalespersonPurchaser);
        SalespersonStatistics.Run();
    end;

    local procedure UpdateOpportunityValue(ContactNo: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.UpdateOpportunity();
    end;

    local procedure VerifyContactStatistics(Contact: Record Contact; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal; Completed2: Decimal)
    begin
        Contact.CalcFields("No. of Opportunities", "Estimated Value (LCY)", "Calcd. Current Value (LCY)");
        Contact.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY2);
        Contact.TestField("No. of Opportunities", 1);
        Contact.TestField(
          "Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * (WizardChancesOfSuccessPercent2 / 100) * (Completed2 / 100));
    end;

    local procedure VerifyOpportunityValues(SalesCycleStage: Record "Sales Cycle Stage"; ContactNo: Code[20]; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal)
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.TestField("Sales Cycle Code", SalesCycleStage."Sales Cycle Code");
        Opportunity.CalcFields("Current Sales Cycle Stage", "Estimated Value (LCY)", "Chances of Success %");
        Opportunity.TestField("Current Sales Cycle Stage", SalesCycleStage.Stage);
        Opportunity.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY2);
        Opportunity.TestField("Chances of Success %", WizardChancesOfSuccessPercent2);
    end;

    local procedure VerifyOpportunityStatistics(Opportunity: Record Opportunity; CurrentSalesCycleStage2: Integer; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal; Completed2: Decimal)
    begin
        Opportunity.CalcFields(
          "Estimated Value (LCY)", "Chances of Success %", "Current Sales Cycle Stage", "Completed %", "Calcd. Current Value (LCY)");
        Opportunity.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY2);
        Opportunity.TestField("Chances of Success %", WizardChancesOfSuccessPercent2);
        Opportunity.TestField("Completed %", Completed2);

        if Completed2 <> 100 then begin  // Use 100 for Close Opportunity as Won.
            Opportunity.TestField("Current Sales Cycle Stage", CurrentSalesCycleStage2);
            Opportunity.TestField(
              "Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * (WizardChancesOfSuccessPercent2 / 100) * (Completed2 / 100));
        end;
    end;

    local procedure VerifySalesCycleStatistics(SalesCycle: Record "Sales Cycle"; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal; Completed2: Decimal)
    begin
        SalesCycle.CalcFields("No. of Opportunities", "Estimated Value (LCY)", "Calcd. Current Value (LCY)");
        SalesCycle.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY2);

        // Use 0 for Close Opportunity.
        if WizardEstimatedValueLCY2 = 0 then
            SalesCycle.TestField("No. of Opportunities", 0)
        else
            SalesCycle.TestField("No. of Opportunities", 1);  // Use 1 for Active Opportunity.
        SalesCycle.TestField(
          "Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * (WizardChancesOfSuccessPercent2 / 100) * (Completed2 / 100));
    end;

    local procedure VerifySalesStageStatistics(SalesCycleStage: Record "Sales Cycle Stage"; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal; Completed2: Decimal)
    begin
        SalesCycleStage.CalcFields("No. of Opportunities", "Estimated Value (LCY)", "Calcd. Current Value (LCY)");
        SalesCycleStage.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY2);

        // Use 0 for Close Opportunity.
        if WizardEstimatedValueLCY2 = 0 then
            SalesCycleStage.TestField("No. of Opportunities", 0)
        else
            SalesCycleStage.TestField("No. of Opportunities", 1);  // Use 1 for Active Opportunity.
        SalesCycleStage.TestField(
          "Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * (WizardChancesOfSuccessPercent2 / 100) * (Completed2 / 100));
    end;

    local procedure VerifySalespersonStatistics(SalespersonPurchaser: Record "Salesperson/Purchaser"; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal; Completed2: Decimal)
    begin
        SalespersonPurchaser.CalcFields("No. of Opportunities", "Estimated Value (LCY)", "Calcd. Current Value (LCY)");
        SalespersonPurchaser.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY2);
        SalespersonPurchaser.TestField("No. of Opportunities", 1);  // Use 1 for Active Opportunity.
        SalespersonPurchaser.TestField(
          "Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * (WizardChancesOfSuccessPercent2 / 100) * (Completed2 / 100));
    end;

    local procedure VerifyValuesOnOpportunity(ContactNo: Code[20]; ProbabilityCalculation: Option; WizardEstimatedValueLCY2: Decimal; WizardChancesOfSuccessPercent2: Decimal; Completed2: Decimal)
    var
        SalesCycle: Record "Sales Cycle";
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", ContactNo);
        Opportunity.FindFirst();
        Opportunity.CalcFields("Calcd. Current Value (LCY)", "Probability %");
        if ProbabilityCalculation = SalesCycle."Probability Calculation"::"Completed %" then begin
            Opportunity.TestField("Probability %", Completed2);
            Opportunity.TestField("Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * Completed2 / 100);
        end;

        if ProbabilityCalculation = SalesCycle."Probability Calculation"::"Chances of Success %" then begin
            Opportunity.TestField("Probability %", WizardChancesOfSuccessPercent2);
            Opportunity.TestField("Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * WizardChancesOfSuccessPercent2 / 100);
        end;

        if ProbabilityCalculation = SalesCycle."Probability Calculation"::Add then begin
            Opportunity.TestField("Probability %", (WizardChancesOfSuccessPercent2 + Completed2) / 2);
            Opportunity.TestField(
              "Calcd. Current Value (LCY)", WizardEstimatedValueLCY2 * ((WizardChancesOfSuccessPercent2 + Completed2) / 2) / 100);
        end;
    end;

    local procedure CreateSalesQuoteWithCustomer(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Insert(true);
    end;

    local procedure CreateActivityWithActivityStepTypePhoneCall(var Activity: Record Activity; var ActivityStep: Record "Activity Step")
    begin
        LibraryMarketing.CreateActivity(Activity);
        LibraryMarketing.CreateActivityStep(ActivityStep, Activity.Code);
        ActivityStep.Validate(Type, ActivityStep.Type::"Phone Call");
        ActivityStep.Validate(Priority, ActivityStep.Priority::Normal);
        ActivityStep.Modify(true);
    end;

    local procedure CreateSalesCycleStageWithActivityCode(
        var SalesCycle: Record "Sales Cycle";
        var SalesCycleStage: Record "Sales Cycle Stage";
        ActivityCode: Code[10])
    begin
        LibraryMarketing.CreateSalesCycleStage(SalesCycleStage, SalesCycle.Code);
        SalesCycleStage.Validate("Completed %", LibraryRandom.RandInt(50));
        SalesCycleStage.Validate("Chances of Success %", LibraryRandom.RandInt(25));
        SalesCycleStage.Validate("Activity Code", ActivityCode);
        SalesCycleStage.Modify(true);
    end;

    local procedure CreateSalesQuoteWithContact(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Contact, Contact."No.");
        Customer.Modify(true);

        LibraryInventory.CreateItem(Item);

        CreateSalesQuoteWithCustomer(SalesHeader, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(0));

        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(20, 2));
        SalesLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerForFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerYesNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormCloseOpportunity(var CloseOpportunity: Page "Close Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        TempOpportunityEntry.Init();
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.Validate("Action Taken", ActionTaken);

        if ActionTaken = ActionTaken::Won then
            CloseOpportunityCode.SetRange(Type, CloseOpportunityCode.Type::Won)
        else
            CloseOpportunityCode.SetRange(Type, CloseOpportunityCode.Type::Lost);
        CloseOpportunityCode.FindFirst();

        TempOpportunityEntry.Validate("Close Opportunity Code", CloseOpportunityCode.Code);
        TempOpportunityEntry.Validate("Calcd. Current Value (LCY)", WizardEstimatedValueLCY);
        TempOpportunityEntry.CheckStatus();
        TempOpportunityEntry.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerOpportunity(var CreateOpportunity: Page "Create Opportunity"; var Response: Action)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        TempOpportunity.Init();
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();
        TempOpportunity.Validate(
          Description, LibraryUtility.GenerateRandomCode(TempOpportunity.FieldNo(Description), DATABASE::Opportunity));
        TempOpportunity.Validate("Sales Cycle Code", SalesCycleCode);

        if ActivateFirstStage then begin
            TempOpportunity.Validate("Activate First Stage", true);
            TempOpportunity.Validate("Wizard Estimated Value (LCY)", WizardEstimatedValueLCY);
            TempOpportunity.Validate("Wizard Chances of Success %", WizardChancesOfSuccessPercent);
            TempOpportunity.Validate("Wizard Estimated Closing Date", CalcDate('<1D>', WorkDate()));
        end;

        TempOpportunity.CheckStatus();
        TempOpportunity.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerUpdateOpportunity(var UpdateOpportunity: Page "Update Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        SalesCycleStage: Record "Sales Cycle Stage";
    begin
        TempOpportunityEntry.Init();
        UpdateOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.CreateStageList();
        TempOpportunityEntry.Validate("Action Type", ActionType);
        TempOpportunityEntry.Validate("Sales Cycle Stage", CurrentSalesCycleStage);
        TempOpportunityEntry.Modify();
        TempOpportunityEntry.WizardSalesCycleStageValidate2();

        TempOpportunityEntry.Validate("Estimated Value (LCY)", WizardEstimatedValueLCY);
        SalesCycleStage.Get(TempOpportunityEntry."Sales Cycle Code", CurrentSalesCycleStage);
        TempOpportunityEntry.Validate("Chances of Success %", SalesCycleStage."Chances of Success %");
        TempOpportunityEntry.Validate("Estimated Close Date", CalcDate('<1D>', WorkDate()));
        TempOpportunityEntry.Modify();

        TempOpportunityEntry.CheckStatus2();
        TempOpportunityEntry.FinishWizard2();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalHandlerOpportunityTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
        TempAttendee: Record Attendee temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(Type, TempTask.Type::Meeting);
        TempTask.Validate(Description, TempTask."Opportunity No.");
        TempTask.Validate(Date, WorkDate());
        TempTask.Validate("All Day Event", true);
        CreateAttendee(TempAttendee, SalespersonCode, TempAttendee."Attendance Type"::"To-do Organizer");

        TempTask.SetAttendee(TempAttendee);
        TempTask.GetAttendee(TempAttendee);

        TempTask.Validate(Priority, TempTask.Priority::Low);

        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateListModalPageHandler(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    var
        CustomerTemplate: Record "Customer Templ.";
        ActionOption: Option LookupOK,Cancel;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ActionOption::LookupOK:
                begin
                    CustomerTemplate.Get(LibraryVariableStorage.DequeueText());
                    CustomerTemplateList.SetRecord(CustomerTemplate);
                    Reply := ACTION::LookupOK;
                end;
            ActionOption::Cancel:
                Reply := ACTION::Cancel;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure OpportunityCreatedSendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(
          StrSubstNo(OpportunityCreatedFromIntLogEntryMsg, LibraryVariableStorage.DequeueText()),
          Notification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure OpportunityCreatedSendNotificationHandlerWithAction(var Notification: Notification): Boolean
    var
        InteractionMgt: Codeunit "Interaction Mgt.";
    begin
        // Mock hit "Open Opportunity" link
        InteractionMgt.ShowCreatedOpportunity(Notification);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerSalesQuote(var SalesQuote: Page "Sales Quote")
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        SalesHeader.Init();
        SalesQuote.GetRecord(SalesHeader);
        LibrarySales.CreateCustomer(Customer);
        SalesHeader."Sell-to Customer No." := Customer."No.";  // Assign value to avoid Confirmation Message.
        SalesHeader."Bill-to Customer No." := Customer."No.";  // Assign value to avoid Confirmation Message. Value important for IN.
        SalesHeader.Modify(true);
        SalesQuoteNo := SalesHeader."No.";
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerOpportunityStatis(var OpportunityStatistics: Page "Opportunity Statistics")
    begin
        Opportunity2.Init();
        OpportunityStatistics.GetRecord(Opportunity2);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerContactStatis(var ContactStatistics: Page "Contact Statistics")
    begin
        Contact2.Init();
        ContactStatistics.GetRecord(Contact2);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerSalesPersonStatis(var SalespersonStatistics: Page "Salesperson Statistics")
    begin
        SalespersonPurchaser2.Init();
        SalespersonStatistics.GetRecord(SalespersonPurchaser2);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerSalesCycleStatis(var SalesCycleStatistics: Page "Sales Cycle Statistics")
    begin
        SalesCycle2.Init();
        SalesCycleStatistics.GetRecord(SalesCycle2);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerSalesCycleStage(var SalesCycleStageStatistics: Page "Sales Cycle Stage Statistics")
    begin
        SalesCycleStage2.Init();
        SalesCycleStageStatistics.GetRecord(SalesCycleStage2);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure OpportunityCardHandler(var OpportunityCard: TestPage "Opportunity Card")
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.Get(OpportunityCard."No.".Value());
        Opportunity.CalcFields(
          "Current Sales Cycle Stage", "Estimated Value (LCY)", "Chances of Success %", "Probability %");

        Opportunity.TestField(
          "Current Sales Cycle Stage",
          OpportunityCard.Control7."Current Sales Cycle Stage".AsInteger());
        Opportunity.TestField(
          "Estimated Value (LCY)",
          OpportunityCard.Control7."Estimated Value (LCY)".AsDecimal());
        Opportunity.TestField(
          "Chances of Success %",
          OpportunityCard.Control7."Chances of Success %".AsDecimal());
        Opportunity.TestField(
          "Probability %",
          OpportunityCard.Control7."Probability %".AsDecimal());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCyclesHandler(var SalesCycles: TestPage "Sales Cycles")
    var
        SalesCycle: Record "Sales Cycle";
    begin
        SalesCycle.Get(SalesCycles.Code.Value());
        SalesCycle.CalcFields(
          "No. of Opportunities", "Estimated Value (LCY)", "Calcd. Current Value (LCY)");

        SalesCycle.TestField(
          "No. of Opportunities",
          SalesCycles.Control5."No. of Opportunities".AsInteger());
        SalesCycle.TestField(
          "Estimated Value (LCY)",
          SalesCycles.Control5."Estimated Value (LCY)".AsDecimal());
        SalesCycle.TestField(
          "Calcd. Current Value (LCY)",
          SalesCycles.Control5."Calcd. Current Value (LCY)".AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CloseOpportunityVerifyHandler(var CloseOpportunity: TestPage "Close Opportunity")
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        CloseOpportunity.OptionWon.AssertEquals(OpportunityEntry."Action Taken"::Won);
        CloseOpportunity."Date of Change".AssertEquals(WorkDate());
        CloseOpportunity."Cancel Old To Do".AssertEquals(true);
        CloseOpportunity."Close Opportunity Code".SetValue(LibraryVariableStorage.DequeueText());
        CloseOpportunity."Calcd. Current Value (LCY)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        CloseOpportunity.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerSalesOrder(var SalesOrder: TestPage "Sales Order")
    begin
        SalesOrder.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CampaignListPageHandler(var CampaignList: TestPage "Campaign List")
    begin
        CampaignList.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CampaignList."No.".Value, CampaignListErr);
        Assert.IsFalse(CampaignList.Next(), CampaignListErr);
        CampaignList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SegmentListPageHandler(var SegmentList: TestPage "Segment List")
    begin
        SegmentList.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), SegmentList."No.".Value, SegmentListErr);
        Assert.IsFalse(SegmentList.Next(), SegmentListErr);
        SegmentList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCycleStagesModalPageHandler(var SalesCycleStages: TestPage "Sales Cycle Stages")
    begin
        SalesCycleStages.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateOpportunityModalPageHandler(var UpdateOpportunity: TestPage "Update Opportunity");
    begin
        LibraryVariableStorage.Enqueue(UpdateOpportunity."Sales Cycle Stage".Value());
        LibraryVariableStorage.Enqueue(UpdateOpportunity."Sales Cycle Stage Description".Value());
        UpdateOpportunity.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CloseOpportunityPageHandler(var CloseOpportunity: Page "Close Opportunity"; var Response: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
        CloseOpportunityCode: Record "Close Opportunity Code";
    begin
        TempOpportunityEntry.Init();
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.Validate("Action Taken", TempOpportunityEntry."Action Taken"::Won);

        CloseOpportunityCode.SetRange(Type, CloseOpportunityCode.Type::Won);
        CloseOpportunityCode.FindFirst();

        TempOpportunityEntry.Validate("Close Opportunity Code", CloseOpportunityCode.Code);
        TempOpportunityEntry.Validate("Calcd. Current Value (LCY)", Random(10));
        TempOpportunityEntry.CheckStatus();
        TempOpportunityEntry.FinishWizard();
    end;

    [MessageHandler]
    procedure CustomerCreated(Message: Text)
    var
        ExpectedMsg: Label 'The Customer record has been created.';
    begin
        Assert.ExpectedMessage(ExpectedMsg, Message);
    end;
}
