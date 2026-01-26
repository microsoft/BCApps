codeunit 101900 "Create Demonstration Data"
{
    SingleInstance = true;

    trigger OnRun()
    var
        TempCurrencyData: Record "Temporary Currency Data";
        ApplicationAreaSetup: Record "Application Area Setup";
        InterfaceTrialData: Codeunit "Interface Trial Data";
        InterfaceEvaluationData: Codeunit "Interface Evaluation Data";
        CreateRapidStartPackage: Codeunit "Create RapidStart Package";
        CreateGLAccount: Codeunit "Create G/L Account";
        CreateD365BaseData: Codeunit "Create D365 Base Data";
        CurrencyDataXML: XMLport "Currency Demo Data";
        IStream: InStream;
        File: File;
        PreRunLanguage: Integer;
    begin
        StartTime := Time;
        ShouldCollectTableIDs := false;
        TempIntegerTableID.DeleteAll();

        if SourceCode.Get(XSTART) then
            Error(XThiscompalrdycontainsdata);

        DemoDataSetup.Get();
        PreRunLanguage := GlobalLanguage;
        if DemoDataSetup."Data Language ID" <> PreRunLanguage then
            GlobalLanguage(DemoDataSetup."Data Language ID");

        File.Open(DemoDataSetup."Path to Picture Folder" + 'CurrencyData.txt');
        File.CreateInStream(IStream);
        CurrencyDataXML.SetSource(IStream);
        CurrencyDataXML.Import();
        File.Close();

        WorkDate := DemoDataSetup."Working Date";

        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Evaluation,
            DemoDataSetup."Data Type"::Extended,
            DemoDataSetup."Data Type"::O365:
                BindSubscription(CreateD365BaseData);
        end;

        CODEUNIT.Run(CODEUNIT::"Make Adjustments");
        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Standard:
                begin
                    SetApplicationArea('Premium');
                    InterfaceTrialData.CreateSetupData();
                end;
            DemoDataSetup."Data Type"::Evaluation:
                begin
                    SetApplicationArea('Premium');
                    InterfaceTrialData.CreateSetupData();
                    InterfaceEvaluationData.CreateSetupData();
                end;
            DemoDataSetup."Data Type"::Extended:
                begin
                    SetApplicationArea('Premium');
                    InsertTableIDsFilledByCompanyInitialize();
                    InterfaceBasisData.Create();
                end;
            DemoDataSetup."Data Type"::O365:
                CODEUNIT.Run(CODEUNIT::"Create D365 Base Data");
        end;

        CODEUNIT.Run(CODEUNIT::"Create Sales Status Icons");

        if DemoDataSetup.Financials then
            InterfaceFinancials.Create();
        if DemoDataSetup."Relationship Mgt." then
            InterfaceRelationshipMgt.Create();
        if DemoDataSetup."Reserved for future use 1" then
            InterfaceReservedforfut1.Create();
        if DemoDataSetup."Reserved for future use 2" then
            InterfaceReservedforfut2.Create();
        if DemoDataSetup."Service Management" then
            InterfaceServiceManagement.Create();
        if DemoDataSetup.Distribution then
            InterfaceDistribution.CreateData();
        if DemoDataSetup.Manufacturing then
            InterfaceManufacturing.Create();
        if DemoDataSetup.ADCS then
            InterfaceADCS.Create();
        if DemoDataSetup."Reserved for future use 3" then
            InterfaceReservedforfut3.Create();
        if DemoDataSetup."Reserved for future use 4" then
            InterfaceReservedforfut4.Create();
        LocalizedCreateDemoData.CreateDataBeforeActions();
        if not DemoDataSetup."Skip sequence of actions" then
            CODEUNIT.Run(CODEUNIT::"Create Sequence of Actions");
        LocalizedCreateDemoData.CreateDataAfterActions();

        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            CreateGLAccount.AddCategoriesToGLAccounts();
        CODEUNIT.Run(CODEUNIT::"Categ. Generate Acc. Schedules");
        CODEUNIT.Run(CODEUNIT::"Update Acc. Sched. KPI Data");

        case DemoDataSetup."Data Type" of
            DemoDataSetup."Data Type"::Standard,
            DemoDataSetup."Data Type"::Evaluation:
                begin
                    CreateRapidStartPackage.InsertMiniAppData();
                    LocalizedCreateDemoData.CreateEvaluationData();
                    UpdateAPIData();
                    CODEUNIT.Run(CODEUNIT::"Export RapidStart Packages");
                end;
            DemoDataSetup."Data Type"::Extended:
                begin
                    CODEUNIT.Run(CODEUNIT::"Create Cash Flow Data");
                    LocalizedCreateDemoData.CreateExtendedData();
                    ShouldCollectTableIDs := false;
                    CODEUNIT.Run(CODEUNIT::"Create RapidStart Package");
                    UpdateAPIData();
                    CODEUNIT.Run(CODEUNIT::"Export RapidStart Packages");
                end;
        end;

        EnableNewFeatures();

        // Insert Data Out Of Geo. Apps
        Codeunit.Run(Codeunit::"Add Data Out Of Geo. Apps");

        if ApplicationAreaMgmtFacade.IsPremiumExperienceEnabled() then
            ApplicationAreaSetup.DeleteAll(true);

        TempCurrencyData.DeleteAll();
        if GlobalLanguage <> PreRunLanguage then
            GlobalLanguage(PreRunLanguage);

        Message(StrSubstNo(DemoDataCreatedMsg, (Time - StartTime) / 1000));
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        SourceCode: Record "Source Code";
        TempIntegerTableID: Record "Integer" temporary;
        LocalizedCreateDemoData: Codeunit "Localized Create Demo Data";
        InterfaceBasisData: Codeunit "Interface Basis Data";
        InterfaceFinancials: Codeunit "Interface Financials";
        InterfaceRelationshipMgt: Codeunit "Interface Relationship Mgt.";
        InterfaceReservedforfut1: Codeunit "Interface Reserved for fut. 1";
        InterfaceReservedforfut2: Codeunit "Interface Reserved for fut. 2";
        InterfaceServiceManagement: Codeunit "Interface Service Management";
        InterfaceDistribution: Codeunit "Interface Distribution";
        InterfaceManufacturing: Codeunit "Interface Manufacturing";
        InterfaceADCS: Codeunit "Interface ADCS";
        InterfaceReservedforfut3: Codeunit "Interface Reserved for fut. 3";
        InterfaceReservedforfut4: Codeunit "Interface Reserved for fut. 4";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        StartTime: Time;
        XThiscompalrdycontainsdata: Label 'This company already contains data.';
        XSTART: Label 'START', Comment = 'START';
        DemoDataCreatedMsg: Label 'The Demonstration Data was successfully created.\Elapsed time: %1s', Comment = '%1 = seconds';
        ShouldCollectTableIDs: Boolean;
        LastTableID: Integer;

    procedure GetTableIDs(var IntegerTableID: Record "Integer" temporary)
    begin
        IntegerTableID.Copy(TempIntegerTableID, true);
    end;

    local procedure InsertTableID(TableID: Integer)
    begin
        TempIntegerTableID.Number := TableID;
        TempIntegerTableID.Insert();
    end;

    local procedure InsertTableIDsFilledByCompanyInitialize()
    begin
        TempIntegerTableID.DeleteAll();
        InsertTableID(DATABASE::"Acc. Schedule Name");
        InsertTableID(DATABASE::"Acc. Schedule Line");
        InsertTableID(DATABASE::"Column Layout");
        InsertTableID(DATABASE::"Financial Report");
        InsertTableID(DATABASE::"General Ledger Setup");
        InsertTableID(DATABASE::"Incoming Documents Setup");
        InsertTableID(DATABASE::"Sales & Receivables Setup");
        InsertTableID(DATABASE::"Purchases & Payables Setup");
        InsertTableID(DATABASE::"Inventory Setup");
        InsertTableID(DATABASE::"Resources Setup");
        InsertTableID(DATABASE::"Jobs Setup");
        InsertTableID(DATABASE::"Tax Setup");
        InsertTableID(DATABASE::"Column Layout Name");
        InsertTableID(DATABASE::"VAT Report Setup");
        InsertTableID(DATABASE::"Cash Flow Setup");
        InsertTableID(DATABASE::"Assembly Setup");
        InsertTableID(DATABASE::"Cost Accounting Setup");
        InsertTableID(DATABASE::"Bank Export/Import Setup");
        InsertTableID(DATABASE::"Data Migration Setup");
        InsertTableID(DATABASE::"Marketing Setup");
        InsertTableID(DATABASE::"Interaction Template Setup");
        InsertTableID(DATABASE::"Human Resources Setup");
        InsertTableID(DATABASE::"FA Setup");
        InsertTableID(DATABASE::"Nonstock Item Setup");
        InsertTableID(DATABASE::"Warehouse Setup");
        InsertTableID(DATABASE::"Service Mgt. Setup");
        InsertTableID(DATABASE::"Config. Setup");
        InsertTableID(DATABASE::"Media Repository");
        ShouldCollectTableIDs := true;
    end;

    local procedure EnableNewFeatures()
    var
        FeatureKey: Record "Feature Key";
    begin
        // Virtual table does not support ModifyAll
        FeatureKey.SetRange("Is One Way", false); // only enable features that can be disabled
        if FeatureKey.FindSet(true) then
            repeat
                if not ExcludeNewFeature(FeatureKey) then begin
                    FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
                    FeatureKey.Modify();
                end;
            until FeatureKey.Next() = 0;
    end;

    local procedure ExcludeNewFeature(FeatureKey: Record "Feature Key"): Boolean
    begin
        if FeatureKey.ID in ['PowerAutomateCopilot',
                             'FullTextSearch',
                             'AdvancedTellMe']
        then
            exit(true);

        exit(false)
    end;

    local procedure IsTableIDIncludedIntoFullPack(TableID: Integer): Boolean
    var
        IsTableIDExcluded: Boolean;
    begin
        if TableID >= 2000000000 then
            exit(false);
        IsTableIDExcluded :=
          TableID in
          [DATABASE::"G/L Entry",
           DATABASE::"Cust. Ledger Entry",
           DATABASE::"Vendor Ledger Entry",
           DATABASE::"Item Ledger Entry" .. DATABASE::"Purchase Line",
           DATABASE::"G/L Register",
           DATABASE::"Item Register",
           DATABASE::"Gen. Journal Line",
           DATABASE::"Item Journal Line",
           DATABASE::"Sales Shipment Header" .. DATABASE::"Purch. Cr. Memo Line",
           DATABASE::"Res. Capacity Entry",
           DATABASE::"Job Ledger Entry",
           DATABASE::"Res. Ledger Entry",
           DATABASE::"Res. Journal Line",
           DATABASE::"Job Journal Line",
           DATABASE::"Source Code",
           DATABASE::"Resource Register",
           DATABASE::"Job Register",
           DATABASE::"G/L Entry - VAT Entry Link",
           DATABASE::"VAT Entry",
           DATABASE::"Bank Account Ledger Entry" .. DATABASE::"Bank Account Statement Line",
           DATABASE::"Phys. Inventory Ledger Entry",
           DATABASE::"Reservation Entry",
           DATABASE::"Item Application Entry",
           DATABASE::"Analysis View Entry",
           DATABASE::"Selected Dimension",
           DATABASE::"Detailed Cust. Ledg. Entry",
           DATABASE::"Detailed Vendor Ledg. Entry",
           DATABASE::"Change Log Entry",
           DATABASE::"Job Planning Line",
           DATABASE::"Job Entry No.",
           DATABASE::"Job Queue Entry",
           DATABASE::"Cost Journal Line",
           DATABASE::"Cost Entry",
           DATABASE::"Cost Register",
           DATABASE::"Cont. Duplicate Search String",
           DATABASE::"Production Order" .. DATABASE::"Prod. Order Routing Line",
           DATABASE::"Sales Invoice Entity Aggregate",
           DATABASE::"Purch. Inv. Entity Aggregate",
           DATABASE::"Sales Order Entity Buffer",
           DATABASE::"Sales Quote Entity Buffer",
           DATABASE::"Sales Cr. Memo Entity Buffer",
           DATABASE::"Purch. Cr. Memo Entity Buffer",
           DATABASE::"FA Ledger Entry",
           DATABASE::"FA Register",
           DATABASE::"Maintenance Ledger Entry",
           DATABASE::"Ins. Coverage Ledger Entry",
           DATABASE::"Insurance Register",
           DATABASE::"FA G/L Posting Buffer",
           DATABASE::"Transfer Header",
           DATABASE::"Transfer Line",
           DATABASE::"Transfer Shipment Header" .. DATABASE::"Registered Whse. Activity Line",
           DATABASE::"Value Entry" .. DATABASE::"Post Value Entry to G/L",
           DATABASE::"G/L - Item Ledger Relation" .. DATABASE::"Service Line",
           DATABASE::"Service Ledger Entry",
           DATABASE::"Service Document Log",
           DATABASE::"Service Register",
           DATABASE::"Service Document Register",
           DATABASE::"Service Order Allocation",
           DATABASE::"Value Entry Relation",
           DATABASE::"Return Shipment Header" .. DATABASE::"Return Receipt Line",
           DATABASE::"Item Analysis View Entry",
           DATABASE::"Warehouse Journal Line" .. DATABASE::"Whse. Worksheet Line",
           DATABASE::"Calendar Entry",
           Database::"Dimension Set Entry",
           Database::"Dimension Set Tree Node",
           9004, // Plan
           9019, // "Default Permission Set In Plan"
           12142, // "VAT Book Entry" 
           12144, // "GL Book Entry"
           Database::"Demo Data File",
           Database::"VIES Declaration Header CZL" .. Database::"VIES Declaration Line CZL",
           Database::"VAT Ctrl. Report Header CZL",
           Database::"Bank Statement Header CZB" .. Database::"Iss. Payment Order Line CZB",
           Database::"Cash Document Header CZP" .. Database::"Cash Document Line CZP",
           Database::"Posted Cash Document Hdr. CZP" .. Database::"Posted Cash Document Line CZP",
           Database::"Detailed G/L Entry CZA",
           Database::"Compensation Header CZC" .. Database::"Posted Compensation Line CZC",
           Database::"VIES Declaration Header CZL" .. Database::"VIES Declaration Line CZL",
           Database::"VAT Ctrl. Report Header CZL"];
        exit(not IsTableIDExcluded);
    end;

    local procedure SetApplicationArea(ExperienceTier: Text)
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTier);
        ApplicationAreaMgmtFacade.SetupApplicationArea();
    end;

    local procedure UpdateAPIData()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CreateD365BaseData: Codeunit "Create D365 Base Data";
    begin
        BindSubscription(CreateD365BaseData);
        GraphMgtGeneralTools.ApiSetup();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseInsert', '', true, true)]
    local procedure OnAfterOnDatabaseRecordInsert(RecRef: RecordRef)
    begin
        if ShouldCollectTableIDs and (LastTableID <> RecRef.Number) then
            if IsTableIDIncludedIntoFullPack(RecRef.Number) then begin
                LastTableID := RecRef.Number;
                TempIntegerTableID.Number := LastTableID;
                if not TempIntegerTableID.Find() then
                    TempIntegerTableID.Insert();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterGetDatabaseTableTriggerSetup', '', true, true)]
    local procedure OnAfterGetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if ShouldCollectTableIDs then
            OnDatabaseInsert := IsTableIDIncludedIntoFullPack(TableId);
    end;
}

