codeunit 101995 "Create RapidStart Package"
{

    trigger OnRun()
    begin
        CreateConfigPackageHelper.CreatePackage(true);
        CreateConfigTemplates.CreateTemplates();
        CreateConfigWorksheet.CreateExtWorksheetLines();
        CreateConfigQuestionaries.CreateQuestionnaires();

        CreateDemonstrationData.GetTableIDs(TempIntegerTableID);
        if TempIntegerTableID.FindSet() then
            repeat
                CreateTable(TempIntegerTableID.Number);
            until TempIntegerTableID.Next() = 0;
        CreateConfigTables();
        CreateLocalRapidStartPack.CreateTables();
        CreateConfigPackageHelper.TurnOffFieldValidation();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        TempIntegerTableID: Record "Integer" temporary;
        CreateDemonstrationData: Codeunit "Create Demonstration Data";
        CreateLocalRapidStartPack: Codeunit "Create Local RapidStart Pack";
        CreateConfigWorksheet: Codeunit "Create Config. Worksheet";
        CreateConfigTemplates: Codeunit "Create Config. Templates";
        CreateConfigQuestionaries: Codeunit "Create Config. Questionaries";
        CreateConfigPackageHelper: Codeunit "Create Config. Package Helper";

    procedure InsertMiniAppData()
    begin
        CreateConfigPackageHelper.CreatePackage(false);
        CreateConfigTemplates.CreateMiniTemplates();
        CreateConfigWorksheet.CreateMiniWorksheetLines();

        CreateDimTables();
        CreateMiniTables();
        CreateJobTables();
        CreateLocalRapidStartPack.CreateTables();
    end;

    local procedure CreateMiniTables()
    var
        PaymentMethod: Record "Payment Method";
        Item: Record Item;
        Customer: Record Customer;
        ColumnLayout: Record "Column Layout";
        Contact: Record Contact;
        DocumentSendingProfile: Record "Document Sending Profile";
        ItemAttribute: Record "Item Attribute";
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        InventorySetup: Record "Inventory Setup";
        IncomingDocument: Record "Incoming Document";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then begin
            CreateTable(DATABASE::"Shipment Method");
            CreateTable(DATABASE::Location);
            CreateTable(DATABASE::"Transfer Route");
            CreateTable(DATABASE::"Salesperson/Purchaser");
            CreateTable(DATABASE::"Customer Discount Group");
            CreateTable(DATABASE::Territory);
            CreateTable(DATABASE::"Document Sending Profile");
            SkipValidateField(DocumentSendingProfile.FieldNo(Default));
            CreateConfigPackageHelper.SetSkipTableTriggers();
            CreateTable(DATABASE::Customer);
            SkipValidateField(Customer.FieldNo("Global Dimension 1 Code"));
            SkipValidateField(Customer.FieldNo("Global Dimension 2 Code"));
            CreateTable(DATABASE::"Customer Bank Account");
            CreateTable(DATABASE::Vendor);
            CreateTable(DATABASE::"Vendor Bank Account");
            CreateTable(DATABASE::"Ship-to Address");
            CreateTable(DATABASE::"Bank Account");
            SkipValidateField(BankAccount.FieldNo(IBAN));
            SkipValidateField(BankAccount.FieldNo("Bank Statement Import Format"));
            CreateTable(DATABASE::"Bank Acc. Reconciliation");
            CreateTableChild(DATABASE::"Bank Acc. Reconciliation Line", DATABASE::"Bank Acc. Reconciliation");
            ExcludeField(BankAccReconciliationLine.FieldNo(Difference));
            CreateTable(DATABASE::"Bank Export/Import Setup");
            CreateTable(DATABASE::"Payment Registration Setup");
            CreateConfigPackageHelper.SetSkipTableTriggers();
            CreateTable(DATABASE::"Item Charge");
            CreateTable(DATABASE::Item);
            IncludeField(Item.FieldNo(Picture));
            CreateTableChild(DATABASE::"Item Unit of Measure", DATABASE::Item);
            CreateTableChild(DATABASE::"Item Reference", DATABASE::Item);
            CreateTableChild(DATABASE::"Item Substitution", DATABASE::Item);
            CreateTable(DATABASE::"BOM Component");
            SetBOM();
            CreateTable(DATABASE::"Inventory Setup");
            CreateTable(DATABASE::Manufacturer);
            CreateTable(DATABASE::Purchasing);
            CreateTable(DATABASE::"Item Category");
            CreateTable(DATABASE::"Nonstock Item");
            CreateTable(DATABASE::"Sales Header");
            CreateTableChild(DATABASE::"Sales Line", DATABASE::"Sales Header");
            CreateTable(DATABASE::"Purchase Header");
            CreateTableChild(DATABASE::"Purchase Line", DATABASE::"Purchase Header");
            CreateTable(DATABASE::"Transfer Header");
            CreateTableChild(DATABASE::"Transfer Line", DATABASE::"Transfer Header");
            CreateTable(DATABASE::"Segment Header");
            CreateTableChild(DATABASE::"Segment Line", DATABASE::"Segment Header");
            CreateTableChild(DATABASE::"Item Attribute", DATABASE::Item);
            SkipValidateField(ItemAttribute.FieldNo(Name));
            SkipValidateField(ItemAttribute.FieldNo(Type));
            CreateTableChild(DATABASE::"Item Attribute Value", DATABASE::Item);
            CreateTableChild(DATABASE::"Item Attribute Value Mapping", DATABASE::Item);
            CreateTable(DATABASE::"Employee Posting Group");
            CreateTableChild(DATABASE::Employee, DATABASE::"Employee Posting Group");
            CreateTable(Database::"Cause of Absence");
            CreateTable(DATABASE::"Incoming Document");
            ExcludeField(IncomingDocument.FieldNo("Created By User ID"));
            ExcludeField(IncomingDocument.FieldNo("Released By User ID"));
            ExcludeField(IncomingDocument.FieldNo("Last Modified By User ID"));
            CreateTableChild(DATABASE::"Incoming Document Attachment", DATABASE::"Incoming Document");
            CreateTableChild(DATABASE::"Text-to-Account Mapping", DATABASE::"G/L Account");
            CreateTable(DATABASE::"Analysis View");
            CreateTable(Database::"Over-Receipt Code");
            CreateTable(Database::"Customer Templ.");
            CreateTable(Database::"Item Templ.");
            CreateTable(Database::"Vendor Templ.");
            CreateTable(Database::"Employee Templ.");
            CreateTable(Database::"Notification Setup");
        end;

        CreateTable(Database::"Assembly Setup");
        CreateTable(Database::"Dispute Status");
        CreateTable(Database::"Req. Wksh. Template");
        CreateTable(Database::"Requisition Wksh. Name");
        CreateTable(Database::"Order Promising Setup");
        CreateTable(DATABASE::"Price Calculation Setup");
        CreateTable(DATABASE::"Human Resources Setup");
        CreateTable(DATABASE::"Human Resource Unit of Measure");
        CreateTable(DATABASE::"Shipping Agent");
        CreateTable(DATABASE::"Shipping Agent Services");
        CreateTable(DATABASE::"Payment Terms");
        CreateTable(DATABASE::"Payment Term Translation");
        CreateTable(DATABASE::Currency);
        CreateTable(DATABASE::"Finance Charge Terms");
        CreateTable(DATABASE::Language);
        CreateTable(DATABASE::"Country/Region");
        CreateTable(DATABASE::"Country/Region Translation");
        CreateTable(DATABASE::"Accounting Period");
        CreateTable(DATABASE::"G/L Account");
        CreateTable(DATABASE::"G/L Account Category");
        CreateTable(DATABASE::"Report Selections");
        CreateTable(DATABASE::"Company Information");
        CreateTable(DATABASE::"Customer Posting Group");
        CreateTable(DATABASE::"Vendor Posting Group");
        CreateTable(DATABASE::"Inventory Posting Group");
        CreateTable(DATABASE::"Gen. Journal Template");
        CreateTable(DATABASE::"Gen. Journal Line");
        CreateTable(DATABASE::"General Ledger Setup");
        CreateTable(DATABASE::"Gen. Journal Batch");
        ExcludeField(GenJournalBatch.FieldNo(BalAccountId));
        CreateTable(DATABASE::"Unit of Measure");
        CreateTable(DATABASE::"Unit of Measure Translation");
        CreateTable(DATABASE::"Post Code");
        CreateTable(DATABASE::"Source Code");
        CreateTable(DATABASE::"Source Code Setup");
        CreateTable(DATABASE::"Gen. Business Posting Group");
        CreateTable(DATABASE::"Gen. Product Posting Group");
        CreateTable(DATABASE::"General Posting Setup");
        CreateTable(DATABASE::"Reminder Terms");
        CreateTable(DATABASE::"Reminder Level");
        CreateTable(DATABASE::"Reminder Attachment Text");
        CreateTable(DATABASE::"Reminder Attachment Text Line");
        CreateTable(DATABASE::"Reminder Email Text");
        CreateTable(DATABASE::"Reminder Text");
        CreateTable(Database::"Reminder Action Group");
        CreateTable(Database::"Reminder Action");
        CreateTable(Database::"Create Reminders Setup");
        CreateTable(Database::"Send Reminders Setup");
        CreateTable(DATABASE::"Payment Method");
        IncludeField(PaymentMethod.FieldNo("Bal. Account No."));
        CreateTable(DATABASE::"Payment Method Translation");
        CreateTable(DATABASE::"No. Series");
        CreateTable(DATABASE::"No. Series Line");
        CreateTable(DATABASE::"Item Tracking Code");
        CreateTable(DATABASE::"Sales & Receivables Setup");
        CreateTable(DATABASE::"Purchases & Payables Setup");
        CreateTable(DATABASE::"Jobs Setup");
        CreateTable(DATABASE::"Resources Setup");
        CreateTable(DATABASE::"Inventory Setup");
        SkipValidateField(InventorySetup.FieldNo("Automatic Cost Posting"));
        CreateTable(DATABASE::"Profile Questionnaire Header");
        CreateTable(DATABASE::"Profile Questionnaire Line");
        CreateTable(DATABASE::"Named Forward Link");

        case CreateConfigPackageHelper.GetCompanyType() of
            DemoDataSetup."Company Type"::VAT:
                begin
                    CreateTable(DATABASE::"VAT Business Posting Group");
                    CreateTable(DATABASE::"VAT Product Posting Group");
                    CreateTable(DATABASE::"VAT Posting Setup");
                    CreateTable(DATABASE::"VAT Setup Posting Groups");
                    CreateTable(DATABASE::"VAT Assisted Setup Bus. Grp.");
                    CreateTable(DATABASE::"VAT Clause");
                    CreateTable(DATABASE::"VAT Registration No. Format");
                    CreateTable(DATABASE::"VAT Report Setup");
                    CreateTable(DATABASE::"VAT Reports Configuration");
                    CreateTable(DATABASE::"VAT Statement Template");
                    CreateTable(DATABASE::"VAT Statement Name");
                    CreateTable(DATABASE::"VAT Statement Line");
                end;
            DemoDataSetup."Company Type"::"Sales Tax":
                begin
                    CreateTable(DATABASE::"VAT Posting Setup");
                    CreateSalesTaxTables();
                end;
        end;

        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then
            CreateTable(DATABASE::"Currency Exchange Rate");
        CreateTable(DATABASE::"Inventory Posting Setup");
        CreateTable(DATABASE::"Config. Line");
        CreateTable(DATABASE::"Config. Package Filter");
        CreateTable(DATABASE::"Config. Setup");
        CreateTable(DATABASE::"RapidStart Services Cue");
        CreateTable(DATABASE::"Financial Report");
        CreateTable(DATABASE::"Acc. Schedule Name");
        CreateTable(DATABASE::"Acc. Schedule Line");
        CreateTable(DATABASE::"Column Layout");
        SkipValidateField(ColumnLayout.FieldNo("Comparison Period Formula"));
        CreateTable(DATABASE::"Column Layout Name");
        CreateTable(DATABASE::"Account Schedules Chart Setup");
        CreateTable(DATABASE::"Acc. Sched. Chart Setup Line");
        CreateTable(DATABASE::"Trial Balance Setup");
        CreateTable(DATABASE::"Chart Definition");
        CreateTable(9701); // Cue Setup
        SkipValidateField(6); // Cue Setup - Threshold 1
        SkipValidateField(8); // Cue Setup - Threshold 2
        CreateTable(DATABASE::"Acc. Sched. KPI Web Srv. Setup");
        CreateTable(DATABASE::"Acc. Sched. KPI Web Srv. Line");
        CreateCashManagmentTables();
        CreateO365SalesTables();
        CreateTable(DATABASE::"Online Map Setup");
        CreateTable(DATABASE::"Online Map Parameter Setup");
        CreateTable(DATABASE::"User Preference");
        CreateTable(DATABASE::"Incoming Documents Setup");
        SkipValidateField(IncomingDocumentsSetup.FieldNo("General Journal Template Name"));
        SkipValidateField(IncomingDocumentsSetup.FieldNo("General Journal Batch Name"));
        CreateTable(Database::"Job Queue Category");
        CreateTable(Database::"Item Journal Template");
        CreateTable(Database::"Word Template");

        // Reporting
        CreateTable(DATABASE::"Custom Report Layout");
        CreateConfigPackageHelper.SetSkipTableTriggers();

        // Office Add-Ins
        CreateTable(DATABASE::"Office Add-in");
        CreateTable(DATABASE::"Email Item");

        // Relationship management
        CreateTable(DATABASE::"Business Relation");
        CreateTable(DATABASE::Attachment);
        CreateTable(DATABASE::"Interaction Group");
        CreateTable(DATABASE::"Interaction Tmpl. Language");
        CreateTable(DATABASE::"Interaction Template");
        SkipValidateField(InteractionTemplate.FieldNo("Wizard Action"));
        CreateTable(DATABASE::"Interaction Template Setup");
        CreateTable(DATABASE::Salutation);
        CreateTable(DATABASE::"Salutation Formula");
        CreateTable(DATABASE::"Marketing Setup");
        CreateTable(DATABASE::"Mailing Group");
        CreateTable(DATABASE::"Industry Group");
        CreateTable(DATABASE::"Web Source");
        CreateTable(DATABASE::"Job Responsibility");
        CreateTable(DATABASE::"Organizational Level");
        CreateTable(DATABASE::Team);
        CreateTable(DATABASE::"Sales Cycle");
        CreateTable(DATABASE::"Campaign Status");
        CreateTable(DATABASE::Campaign);
        CreateTable(DATABASE::Activity);
        CreateTable(DATABASE::"Activity Step");
        CreateTable(DATABASE::"Sales Cycle Stage");
        CreateTable(DATABASE::"Close Opportunity Code");
        CreateTable(DATABASE::"Duplicate Search String Setup");
        CreateTable(DATABASE::Contact);
        SkipValidateField(Contact.FieldNo("Company Name"));
        CreateTable(DATABASE::"Contact Business Relation");
        CreateTable(DATABASE::Opportunity);
        CreateTableChild(DATABASE::"Opportunity Entry", DATABASE::"Close Opportunity Code");
        CreateConfigPackageHelper.SetSkipTableTriggers();
        CreateTableChild(Database::"Contact Job Responsibility", Database::Contact);
        CreateTable(DATABASE::"Interaction Log Entry");
        ExcludeField(InteractionLogEntry.FieldNo("User ID"));

        // Fixed Asset
        CreateTable(DATABASE::"Depreciation Book");
        CreateTable(DATABASE::"FA Posting Group");
        CreateTable(DATABASE::"FA Setup");
        CreateTable(DATABASE::"FA Class");
        CreateTable(DATABASE::"FA Subclass");
        CreateTable(DATABASE::"FA Journal Template");
        CreateTable(DATABASE::"FA Journal Batch");
        CreateTable(DATABASE::"Insurance Journal Template");
        CreateTable(DATABASE::"Insurance Journal Batch");
        CreateTable(DATABASE::"FA Journal Setup");
        CreateTable(DATABASE::"FA Location");

        // Excel Templates
        CreateTable(DATABASE::"Excel Template Storage");
        CreateConfigPackageHelper.SetSkipTableTriggers();

        // ADCS
        CreateTable(DATABASE::"Miniform Header");
        CreateTable(DATABASE::"Miniform Line");
        CreateTable(DATABASE::"Miniform Function Group");
        CreateTable(DATABASE::"Miniform Function");
        CreateTable(DATABASE::"Item Identifier");
        CreateTable(DATABASE::"ADCS User");
    end;

    local procedure CreateCashManagmentTables()
    begin
        CreateTable(DATABASE::"Bank Export/Import Setup");
        CreateTable(DATABASE::"Data Exchange Type");
        CreateTable(DATABASE::"Data Exch. Def");
        CreateConfigPackageHelper.SetSkipTableTriggers();
        CreateTable(DATABASE::"Data Exch. Line Def");
        CreateTable(DATABASE::"Data Exch. Column Def");
        CreateTable(DATABASE::"Data Exch. Mapping");
        CreateTable(DATABASE::"Data Exch. Field Mapping");
        CreateConfigPackageHelper.SetSkipTableTriggers();
        CreateTable(DATABASE::"Bank Pmt. Appl. Rule");
        CreateTable(DATABASE::"Bank Account Posting Group");
        CreateTable(DATABASE::"Payment Registration Setup");
    end;

    local procedure CreateO365SalesTables()
    begin
        CreateTable(DATABASE::"O365 HTML Template");
        CreateTable(DATABASE::"O365 Brand Color");
        CreateTable(DATABASE::"O365 Payment Service Logo");
    end;

    local procedure CreateDimTables()
    begin
        CreateTable(DATABASE::Dimension);
        CreateTable(DATABASE::"Dimension Value");
        CreateTable(DATABASE::"Dimension Combination");
        CreateTable(DATABASE::"Dimension Value Combination");
        CreateTable(DATABASE::"Default Dimension");
        CreateTable(DATABASE::"Default Dimension Priority");
        CreateTable(DATABASE::"Dimension Translation");
        CreateTable(DATABASE::"Job Task Dimension");
        CreateTable(DATABASE::"Dim. Value per Account");
    end;

    local procedure CreateConfigTables()
    begin
        CreateTable(DATABASE::"Config. Questionnaire");
        CreateTable(DATABASE::"Config. Question Area");
        CreateTable(DATABASE::"Config. Question");
        CreateTable(DATABASE::"Config. Template Header");
        CreateTable(DATABASE::"Config. Template Line");
        CreateTable(DATABASE::"Config. Line");
        CreateTable(DATABASE::"Config. Package Filter");
    end;

    local procedure CreateBankReconRule()
    begin
        CreateConfigPackageHelper.CreateProcessingRuleCustom(10000, CODEUNIT::"Match Bank Pmt. Appl.");
    end;

    local procedure CreateGenJnlLineRule()
    begin
        CreateConfigPackageHelper.CreateProcessingRuleCustom(10000, CODEUNIT::"Post Late Gen. Journal Lines");
    end;

    local procedure CreateGenJnlBatchRule()
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
    begin
        CreateConfigPackageHelper.CreateProcessingRule(10000, ConfigTableProcessingRule.Action::Post);
    end;

    local procedure CreatePurchaseDocRules()
    var
        PurchHeader: Record "Purchase Header";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        InterfaceEvaluationData: Codeunit "Interface Evaluation Data";
        RuleNo: Integer;
    begin
        // Post Invoices wihtout 'OPEN' document marker in "Your Reference"
        RuleNo := 10000;
        CreateConfigPackageHelper.CreateProcessingRule(RuleNo, ConfigTableProcessingRule.Action::Invoice);
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        CreateConfigPackageHelper.CreateProcessingFilter(
          RuleNo, PurchHeader.FieldNo("Document Type"),
          StrSubstNo('=%1', Format(PurchHeader."Document Type", 0, 9)));
        CreateConfigPackageHelper.CreateProcessingFilter(
          RuleNo, PurchHeader.FieldNo("Your Reference"),
          StrSubstNo('<>%1', InterfaceEvaluationData.GetOpenDocsMarker()));
    end;

    local procedure CreateSalesDocRules()
    var
        SalesHeader: Record "Sales Header";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        InterfaceEvaluationData: Codeunit "Interface Evaluation Data";
        RuleNo: Integer;
    begin
        // Post Invoices wihtout 'OPEN' document marker in "Your Reference"
        RuleNo := 10000;
        CreateConfigPackageHelper.CreateProcessingRule(RuleNo, ConfigTableProcessingRule.Action::Invoice);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        CreateConfigPackageHelper.CreateProcessingFilter(
          RuleNo, SalesHeader.FieldNo("Document Type"),
          StrSubstNo('=%1', Format(SalesHeader."Document Type", 0, 9)));
        CreateConfigPackageHelper.CreateProcessingFilter(
          RuleNo, SalesHeader.FieldNo("Your Reference"),
          StrSubstNo('<>%1', InterfaceEvaluationData.GetOpenDocsMarker()));
    end;

    local procedure CreateSalesTaxTables()
    begin
        CreateTable(DATABASE::"Tax Area");
        CreateTableChild(DATABASE::"Tax Area Line", DATABASE::"Tax Area");
        CreateTable(DATABASE::"Tax Jurisdiction");
        CreateTableChild(DATABASE::"Tax Detail", DATABASE::"Tax Jurisdiction");
        CreateTable(DATABASE::"Tax Group");
        CreateTable(DATABASE::"Tax Setup");
        CreateTable(DATABASE::"Tax Area Translation");
        CreateTable(DATABASE::"Tax Jurisdiction Translation");
    end;

    local procedure CreateTable(TableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTable(TableID);
        SetFieldsAndFilters(TableID);
    end;

    local procedure CreateTableChild(TableID: Integer; ParentTableID: Integer)
    begin
        CreateConfigPackageHelper.CreateTableChild(TableID, ParentTableID);
        SetFieldsAndFilters(TableID);
    end;

    local procedure CreateTransferShipmentRules()
    var
        TransferHeader: Record "Transfer Header";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        InterfaceEvaluationData: Codeunit "Interface Evaluation Data";
        RuleNo: Integer;
    begin
        // Ship Transfer Orders wihtout 'OPEN' document marker in "External Document No."
        RuleNo := 10000;
        CreateConfigPackageHelper.CreateProcessingRule(RuleNo, ConfigTableProcessingRule.Action::Ship);
        CreateConfigPackageHelper.CreateProcessingFilter(
          RuleNo, TransferHeader.FieldNo("External Document No."),
          StrSubstNo('<>%1', InterfaceEvaluationData.GetOpenDocsMarker()));
    end;

    local procedure CreateTransferReceiptRules()
    var
        TransferHeader: Record "Transfer Header";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        InterfaceEvaluationData: Codeunit "Interface Evaluation Data";
        RuleNo: Integer;
    begin
        // Receive Transfer Orders wihtout 'OPEN' document marker in "External Document No."
        RuleNo := 20000;
        CreateConfigPackageHelper.CreateProcessingRule(RuleNo, ConfigTableProcessingRule.Action::Receive);
        CreateConfigPackageHelper.CreateProcessingFilter(
          RuleNo, TransferHeader.FieldNo("External Document No."),
          StrSubstNo('<>%1', InterfaceEvaluationData.GetOpenDocsMarker()));
    end;

    local procedure CreateCompanyInformationRules()
    var
        CompanyInformation: Record "Company Information";
    begin
        ExcludeField(CompanyInformation.FieldNo(Name));
        ExcludeField(CompanyInformation.FieldNo("Ship-to Name"));
        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then
            CreateConfigPackageHelper.CreateProcessingRuleCustom(10000, CODEUNIT::"Setup Company Name");
    end;

    local procedure ExcludeField(FieldID: Integer)
    begin
        CreateConfigPackageHelper.IncludeField(FieldID, false);
    end;

    local procedure IncludeField(FieldID: Integer)
    begin
        CreateConfigPackageHelper.IncludeField(FieldID, true);
    end;

    local procedure SkipValidateField(FieldID: Integer)
    begin
        CreateConfigPackageHelper.ValidateField(FieldID, false);
    end;

    local procedure SetFieldsAndFilters(TableID: Integer)
    var
        ServiceItemLog: Record "Service Item Log";
        DimensionSetTreeNode: Record "Dimension Set Tree Node";
        DimensionValue: Record "Dimension Value";
        DocType: Integer;
    begin
        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Extended then
            case TableID of
                DATABASE::"Dimension Value":
                    CreateConfigPackageHelper.MarkFieldAsPrimaryKey(DimensionValue.FieldNo("Dimension Value ID"));
                DATABASE::"Dimension Set Tree Node":
                    CreateConfigPackageHelper.MarkFieldAsPrimaryKey(DimensionSetTreeNode.FieldNo("Dimension Set ID"));
                DATABASE::"Service Item":
                    CreateConfigPackageHelper.CreateTableFilter(1, '<>3?&<>4?'); // to exclude items 30..41
                DATABASE::"Service Item Log":
                    begin
                        CreateConfigPackageHelper.CreateTableFilter(
                          ServiceItemLog.FieldNo("Service Item No."), '<>3?&<>4?'); // to exclude items 30..41
                        ServiceItemLog."Document Type" := ServiceItemLog."Document Type"::Order;
                        DocType := ServiceItemLog."Document Type";
                        CreateConfigPackageHelper.CreateTableFilter(
                          ServiceItemLog.FieldNo("Document Type"), StrSubstNo('<>%1', DocType));
                    end;
            end
        else
            case TableID of
                DATABASE::"Salesperson/Purchaser":
                    if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Evaluation then
                        CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                DATABASE::"G/L Account":
                    SetGLAcc();
                DATABASE::"G/L Account Category":
                    CreateConfigPackageHelper.DeleteRecsBeforeProcessing();
                DATABASE::Customer:
                    begin
                        SetCust();
                        if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Evaluation then
                            CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                    end;
                DATABASE::Vendor:
                    begin
                        SetVend();
                        if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Evaluation then
                            CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                    end;
                DATABASE::Item:
                    begin
                        SetItem();
                        if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Evaluation then
                            CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                    end;
                DATABASE::"Sales Header":
                    begin
                        SetSalesHeader();
                        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then
                            CreateSalesDocRules();
                    end;
                DATABASE::"Sales Line":
                    SetSalesLine();
                DATABASE::"Purchase Header":
                    begin
                        SetPurchHeader();
                        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then
                            CreatePurchaseDocRules();
                    end;
                DATABASE::"Purchase Line":
                    SetPurchLine();
                DATABASE::"Transfer Header":
                    if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then begin
                        CreateTransferShipmentRules();
                        CreateTransferReceiptRules();
                    end;
                DATABASE::"Gen. Journal Line":
                    if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then begin
                        SetGenJnlLine();
                        CreateGenJnlLineRule();
                    end else
                        CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                DATABASE::"Item Journal Line":
                    CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                DATABASE::"Gen. Journal Batch":
                    begin
                        SetGenJnlBatch();
                        if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then
                            CreateGenJnlBatchRule();
                    end;
                DATABASE::"General Ledger Setup":
                    SetGLSetup();
                DATABASE::"Bank Account":
                    if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Evaluation then
                        CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                DATABASE::"Bank Acc. Reconciliation":
                    if CreateConfigPackageHelper.GetDataType() = DemoDataSetup."Data Type"::Evaluation then
                        CreateBankReconRule();
                DATABASE::"Payment Method":
                    SetPaymentMethod();
                DATABASE::"No. Series Line":
                    SetNoSeriesLine();
                DATABASE::"VAT Posting Setup":
                    SetVATPostingSetup();
                DATABASE::"Dimension Value":
                    SetDimValue();
                DATABASE::"Default Dimension":
                    begin
                        SetDefaultDim();
                        CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', '13|18|23'));
                    end;
                DATABASE::"Bank Export/Import Setup":
                    SetBankExportImportSetup();
                DATABASE::"Default Dimension Priority":
                    CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', 0));
                DATABASE::"Inventory Posting Setup":
                    if CreateConfigPackageHelper.GetDataType() <> DemoDataSetup."Data Type"::Evaluation then
                        CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', ''' '''));
                DATABASE::"Config. Line":
                    CreateConfigPackageHelper.CreateTableFilter(36, StrSubstNo('=%1', DemoDataSetup.GetRSPackageCode()));
                DATABASE::"Config. Package Filter":
                    CreateConfigPackageHelper.CreateTableFilter(1, StrSubstNo('=%1', DemoDataSetup.GetRSPackageCode()));
                DATABASE::"Ship-to Address":
                    SetShipToAddress();
                DATABASE::"Company Information":
                    CreateCompanyInformationRules();
                DATABASE::"Item Unit of Measure":
                    SetItemUoM();
            end;
        CreateLocalRapidStartPack.SetFieldsAndFilters(TableID);
    end;

    local procedure SetGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(GenJournalLine.FieldNo("Journal Template Name"));
        SkipValidateField(GenJournalLine.FieldNo("Journal Template Name"));
        IncludeField(GenJournalLine.FieldNo("Journal Batch Name"));
        SkipValidateField(GenJournalLine.FieldNo("Journal Batch Name"));
        IncludeField(GenJournalLine.FieldNo("Line No."));
        SkipValidateField(GenJournalLine.FieldNo("Line No."));
        IncludeField(GenJournalLine.FieldNo("Document Type"));
        SkipValidateField(GenJournalLine.FieldNo("Document Type"));
        IncludeField(GenJournalLine.FieldNo("System-Created Entry"));
        SkipValidateField(GenJournalLine.FieldNo("System-Created Entry"));
        IncludeField(GenJournalLine.FieldNo("Posting Date"));
        SkipValidateField(GenJournalLine.FieldNo("Posting Date"));
        IncludeField(GenJournalLine.FieldNo("Account Type"));
        SkipValidateField(GenJournalLine.FieldNo("Account Type"));
        IncludeField(GenJournalLine.FieldNo("Account No."));
        SkipValidateField(GenJournalLine.FieldNo("Account No."));
        IncludeField(GenJournalLine.FieldNo("Bal. Account Type"));
        SkipValidateField(GenJournalLine.FieldNo("Bal. Account Type"));
        IncludeField(GenJournalLine.FieldNo("Bal. Account No."));
        SkipValidateField(GenJournalLine.FieldNo("Bal. Account No."));
        IncludeField(GenJournalLine.FieldNo("Document No."));
        SkipValidateField(GenJournalLine.FieldNo("Document No."));
        IncludeField(GenJournalLine.FieldNo(Description));
        SkipValidateField(GenJournalLine.FieldNo(Description));
        IncludeField(GenJournalLine.FieldNo(Amount));
        SkipValidateField(GenJournalLine.FieldNo(Amount));
    end;

    local procedure SetGLAcc()
    var
        GLAcc: Record "G/L Account";
    begin
        ExcludeField(GLAcc.FieldNo("Last Date Modified"));
    end;

    local procedure SetCust()
    var
        Cust: Record Customer;
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(Cust.FieldNo("No."));
        IncludeField(Cust.FieldNo(Name));
        IncludeField(Cust.FieldNo("Name 2"));
        IncludeField(Cust.FieldNo(Address));
        IncludeField(Cust.FieldNo("Address 2"));
        IncludeField(Cust.FieldNo(City));
        IncludeField(Cust.FieldNo(Contact));
        IncludeField(Cust.FieldNo("Phone No."));
        IncludeField(Cust.FieldNo("Telex No."));
        IncludeField(Cust.FieldNo("Territory Code"));
        IncludeField(Cust.FieldNo("Global Dimension 1 Code"));
        IncludeField(Cust.FieldNo("Global Dimension 2 Code"));
        IncludeField(Cust.FieldNo("Credit Limit (LCY)"));
        IncludeField(Cust.FieldNo("Language Code"));
        IncludeField(Cust.FieldNo("Country/Region Code"));
        IncludeField(Cust.FieldNo("Fax No."));
        IncludeField(Cust.FieldNo("Telex Answer Back"));
        IncludeField(Cust.FieldNo("VAT Registration No."));
        IncludeField(Cust.FieldNo("Customer Posting Group"));
        IncludeField(Cust.FieldNo("Gen. Bus. Posting Group"));
        IncludeField(Cust.FieldNo("VAT Bus. Posting Group"));
        IncludeField(Cust.FieldNo("Payment Terms Code"));
        IncludeField(Cust.FieldNo("Tax Area Code"));
        IncludeField(Cust.FieldNo("Tax Liable"));
        IncludeField(Cust.FieldNo("Post Code"));
        SkipValidateField(Cust.FieldNo("Post Code"));
        IncludeField(Cust.FieldNo(County));
        IncludeField(Cust.FieldNo("E-Mail"));
        IncludeField(Cust.FieldNo("Home Page"));
        IncludeField(Cust.FieldNo("Document Sending Profile"));
        IncludeField(Cust.FieldNo("Salesperson Code"));
        IncludeField(Cust.FieldNo(Image));
        IncludeField(Cust.FieldNo("Reminder Terms Code"));
    end;

    local procedure SetVend()
    var
        Vend: Record Vendor;
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(Vend.FieldNo("No."));
        IncludeField(Vend.FieldNo(Name));
        IncludeField(Vend.FieldNo("Name 2"));
        IncludeField(Vend.FieldNo(Address));
        IncludeField(Vend.FieldNo("Address 2"));
        IncludeField(Vend.FieldNo(City));
        IncludeField(Vend.FieldNo(Contact));
        IncludeField(Vend.FieldNo("Phone No."));
        IncludeField(Vend.FieldNo("Telex No."));
        IncludeField(Vend.FieldNo("Territory Code"));
        IncludeField(Vend.FieldNo("Global Dimension 1 Code"));
        IncludeField(Vend.FieldNo("Global Dimension 2 Code"));
        IncludeField(Vend.FieldNo("Budgeted Amount"));
        IncludeField(Vend.FieldNo("Country/Region Code"));
        IncludeField(Vend.FieldNo("Fax No."));
        IncludeField(Vend.FieldNo("Telex Answer Back"));
        IncludeField(Vend.FieldNo("VAT Registration No."));
        IncludeField(Vend.FieldNo("Vendor Posting Group"));
        IncludeField(Vend.FieldNo("Gen. Bus. Posting Group"));
        IncludeField(Vend.FieldNo("VAT Bus. Posting Group"));
        IncludeField(Vend.FieldNo("Payment Terms Code"));
        IncludeField(Vend.FieldNo("Tax Area Code"));
        IncludeField(Vend.FieldNo("Tax Liable"));
        IncludeField(Vend.FieldNo("Post Code"));
        SkipValidateField(Vend.FieldNo("Post Code"));
        IncludeField(Vend.FieldNo(County));
        IncludeField(Vend.FieldNo("E-Mail"));
        IncludeField(Vend.FieldNo("Home Page"));
        IncludeField(Vend.FieldNo(Image));
    end;

    local procedure SetItem()
    var
        Item: Record Item;
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(Item.FieldNo("No."));
        IncludeField(Item.FieldNo("No. 2"));
        IncludeField(Item.FieldNo(Description));
        IncludeField(Item.FieldNo("Description 2"));
        IncludeField(Item.FieldNo("Base Unit of Measure"));
        IncludeField(Item.FieldNo("Unit Price"));
        IncludeField(Item.FieldNo("Unit Cost"));
        IncludeField(Item.FieldNo("Vendor No."));
        IncludeField(Item.FieldNo("Inventory Posting Group"));
        IncludeField(Item.FieldNo("Gen. Prod. Posting Group"));
        IncludeField(Item.FieldNo("VAT Prod. Posting Group"));
        IncludeField(Item.FieldNo("Tax Group Code"));
        IncludeField(Item.FieldNo("Reorder Point"));
        IncludeField(Item.FieldNo("Gross Weight"));
        IncludeField(Item.FieldNo("Net Weight"));
        IncludeField(Item.FieldNo("Unit Volume"));
        IncludeField(Item.FieldNo("Item Category Code"));
        IncludeField(Item.FieldNo("Tariff No."));
        IncludeField(Item.FieldNo("Sales Unit of Measure"));
        SkipValidateField(Item.FieldNo("Sales Unit of Measure"));
        IncludeField(Item.FieldNo("Purch. Unit of Measure"));
        SkipValidateField(Item.FieldNo("Purch. Unit of Measure"));
    end;

    local procedure SetGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        SkipValidateField(GLSetup.FieldNo("Inv. Rounding Precision (LCY)"));
        SkipValidateField(GLSetup.FieldNo("Inv. Rounding Type (LCY)"));
        SkipValidateField(GLSetup.FieldNo("Amount Rounding Precision"));
        SkipValidateField(GLSetup.FieldNo("Unit-Amount Rounding Precision"));
        SkipValidateField(GLSetup.FieldNo("Appln. Rounding Precision"));
        IncludeField(GLSetup.FieldNo("Max. VAT Difference Allowed"));
    end;

    local procedure SetGenJnlBatch()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        SkipValidateField(GenJnlBatch.FieldNo("Journal Template Name"));
        SkipValidateField(GenJnlBatch.FieldNo("Bal. Account Type"));
        SkipValidateField(GenJnlBatch.FieldNo("Bal. Account No."));
    end;

    local procedure SetPaymentMethod()
    var
        PaymentMethod: Record "Payment Method";
    begin
        ExcludeField(PaymentMethod.FieldNo("Bal. Account No."));
    end;

    local procedure SetPurchHeader()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(PurchHeader.FieldNo("Document Type"));
        IncludeField(PurchHeader.FieldNo("No."));
        IncludeField(PurchHeader.FieldNo("Vendor Invoice No."));
        IncludeField(PurchHeader.FieldNo("Buy-from Vendor No."));
        IncludeField(PurchHeader.FieldNo("Posting Date"));
        IncludeField(PurchHeader.FieldNo("Document Date"));
        IncludeField(PurchHeader.FieldNo("Order Date"));
        IncludeField(PurchHeader.FieldNo("Expected Receipt Date"));
        IncludeField(PurchHeader.FieldNo("Receiving No. Series"));
        IncludeField(PurchHeader.FieldNo("Posting No. Series"));
        IncludeField(PurchHeader.FieldNo("Payment Terms Code"));
        IncludeField(PurchHeader.FieldNo("Payment Method Code"));
        IncludeField(PurchHeader.FieldNo("Your Reference"));
        IncludeField(PurchHeader.FieldNo("Location Code"));
    end;

    local procedure SetPurchLine()
    var
        PurchLine: Record "Purchase Line";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(PurchLine.FieldNo("Document Type"));
        IncludeField(PurchLine.FieldNo("Document No."));
        IncludeField(PurchLine.FieldNo("Line No."));
        IncludeField(PurchLine.FieldNo(Type));
        IncludeField(PurchLine.FieldNo("No."));
        IncludeField(PurchLine.FieldNo(Description));
        IncludeField(PurchLine.FieldNo(Quantity));
        IncludeField(PurchLine.FieldNo("Direct Unit Cost"));
        IncludeField(PurchLine.FieldNo(Amount));
        IncludeField(PurchLine.FieldNo("Location Code"));
    end;

    local procedure SetSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(SalesHeader.FieldNo("Document Type"));
        IncludeField(SalesHeader.FieldNo("No."));
        IncludeField(SalesHeader.FieldNo("Sell-to Customer No."));
        IncludeField(SalesHeader.FieldNo("Posting Date"));
        IncludeField(SalesHeader.FieldNo("Document Date"));
        IncludeField(SalesHeader.FieldNo("Order Date"));
        IncludeField(SalesHeader.FieldNo("Requested Delivery Date"));
        IncludeField(SalesHeader.FieldNo("Shipping No. Series"));
        IncludeField(SalesHeader.FieldNo("Payment Terms Code"));
        IncludeField(SalesHeader.FieldNo("Payment Method Code"));
        IncludeField(SalesHeader.FieldNo("Shipping Agent Code"));
        IncludeField(SalesHeader.FieldNo("Shipping Agent Service Code"));
        IncludeField(SalesHeader.FieldNo("Your Reference"));
    end;

    local procedure SetSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(SalesLine.FieldNo("Document Type"));
        IncludeField(SalesLine.FieldNo("Document No."));
        IncludeField(SalesLine.FieldNo("Line No."));
        IncludeField(SalesLine.FieldNo(Type));
        IncludeField(SalesLine.FieldNo("No."));
        IncludeField(SalesLine.FieldNo(Description));
        IncludeField(SalesLine.FieldNo(Quantity));
        IncludeField(SalesLine.FieldNo("Unit Price"));
        IncludeField(SalesLine.FieldNo(Amount));
    end;

    local procedure SetNoSeriesLine()
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        ExcludeField(NoSeriesLine.FieldNo("Last Date Used"));
    end;

    local procedure SetVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SkipValidateField(VATPostingSetup.FieldNo("VAT %"));
    end;

    local procedure SetDimValue()
    var
        DimValue: Record "Dimension Value";
    begin
        ExcludeField(DimValue.FieldNo("Map-to IC Dimension Code"));
        ExcludeField(DimValue.FieldNo("Map-to IC Dimension Value Code"));
        ExcludeField(DimValue.FieldNo("Dimension Id"));
        ExcludeField(DimValue.FieldNo("Last Modified Date Time"));
    end;

    local procedure SetDefaultDim()
    var
        DefaultDim: Record "Default Dimension";
    begin
        SkipValidateField(DefaultDim.FieldNo("No."));
        ExcludeField(DefaultDim.FieldNo(ParentId));
        ExcludeField(DefaultDim.FieldNo(DimensionId));
        ExcludeField(DefaultDim.FieldNo(DimensionValueId));
    end;

    local procedure SetBankExportImportSetup()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        SkipValidateField(BankExportImportSetup.FieldNo("Data Exch. Def. Code"));
    end;

    local procedure SetShipToAddress()
    var
        ShiptoAddress: Record "Ship-to Address";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(ShiptoAddress.FieldNo("Customer No."));
        IncludeField(ShiptoAddress.FieldNo(Code));
        IncludeField(ShiptoAddress.FieldNo(Name));
        IncludeField(ShiptoAddress.FieldNo(Address));
        IncludeField(ShiptoAddress.FieldNo(City));
        IncludeField(ShiptoAddress.FieldNo("Country/Region Code"));
        IncludeField(ShiptoAddress.FieldNo("Post Code"));
        IncludeField(ShiptoAddress.FieldNo(County));
    end;

    local procedure SetBOM()
    var
        BOMComponent: Record "BOM Component";
    begin
        CreateConfigPackageHelper.ExcludeAllFields();
        IncludeField(BOMComponent.FieldNo("Parent Item No."));
        IncludeField(BOMComponent.FieldNo("Line No."));
        IncludeField(BOMComponent.FieldNo(Type));
        IncludeField(BOMComponent.FieldNo("No."));
        IncludeField(BOMComponent.FieldNo(Description));
        IncludeField(BOMComponent.FieldNo("Quantity per"));
        IncludeField(BOMComponent.FieldNo("Unit of Measure Code"));
    end;

    local procedure SetItemUoM()
    var
        ItemUoM: Record "Item Unit of Measure";
    begin
        SkipValidateField(ItemUoM.FieldNo("Qty. Rounding Precision"));
    end;

    local procedure CreateJobTables()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
    begin
        CreateTable(DATABASE::Resource);
        CreateTable(DATABASE::Job);
        CreateConfigPackageHelper.SetSkipTableTriggers();
        CreateTableChild(DATABASE::"Job Task", DATABASE::Job);
        CreateTableChild(DATABASE::"Job Planning Line", DATABASE::Job);
        ExcludeField(JobPlanningLine.FieldNo("User ID"));
        CreateTableChild(DATABASE::"Job Journal Line", DATABASE::Job);
        ExcludeField(JobJournalLine.FieldNo("Dimension Set ID"));
        CreateTable(DATABASE::"Job Journal Batch");
        CreateTable(DATABASE::"Job Posting Group");
        CreateTable(DATABASE::"Job Journal Template");
    end;
}

