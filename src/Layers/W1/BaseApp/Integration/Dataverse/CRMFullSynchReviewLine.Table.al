// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Threading;

table 5373 "CRM Full Synch. Review Line"
{
    Caption = 'CRM Full Synch. Review Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
        }
        field(2; "Dependency Filter"; Text[250])
        {
            Caption = 'Dependency Filter';
        }
        field(3; "Session ID"; Integer)
        {
            Caption = 'Session ID';
        }
        field(4; "To Int. Table Job ID"; Guid)
        {
            Caption = 'To Int. Table Job ID';

            trigger OnValidate()
            begin
                "To Int. Table Job Status" := GetSynchJobStatus("To Int. Table Job ID");
            end;
        }
        field(5; "To Int. Table Job Status"; Option)
        {
            Caption = 'To Int. Table Job Status';
            OptionCaption = ' ,Success,In Process,Error';
            OptionMembers = " ",Success,"In Process",Error;
        }
        field(6; "From Int. Table Job ID"; Guid)
        {
            Caption = 'From Int. Table Job ID';

            trigger OnValidate()
            begin
                "From Int. Table Job Status" := GetSynchJobStatus("From Int. Table Job ID");
            end;
        }
        field(7; "From Int. Table Job Status"; Option)
        {
            Caption = 'From Int. Table Job Status';
            OptionCaption = ' ,Success,In Process,Error';
            OptionMembers = " ",Success,"In Process",Error;
        }
        field(8; Direction; Option)
        {
            Caption = 'Direction';
            Editable = false;
            OptionCaption = 'Bidirectional,To Integration Table,From Integration Table';
            OptionMembers = Bidirectional,"To Integration Table","From Integration Table";
        }
        field(9; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';

            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                if not IsNullGuid("Job Queue Entry ID") then
                    if JobQueueEntry.Get("Job Queue Entry ID") then
                        SetJobQueueEntryStatus(JobQueueEntry.Status)
                    else
                        SetJobQueueEntryStatus(JobQueueEntry.Status::Error)
            end;
        }
        field(10; "Job Queue Entry Status"; Option)
        {
            Caption = 'Job Queue Entry Status';
            OptionCaption = ' ,Ready,In Process,Error,On Hold,Finished,On Hold with Inactivity Timeout,Waiting';
            OptionMembers = " ",Ready,"In Process",Error,"On Hold",Finished,"On Hold with Inactivity Timeout",Waiting;

            trigger OnValidate()
            begin
                if "Job Queue Entry Status" = "Job Queue Entry Status"::"In Process" then
                    "Session ID" := SessionId()
                else
                    "Session ID" := 0;
            end;
        }
        field(13; "Initial Synch Recommendation"; Option)
        {
            OptionCaption = 'Full Synchronization,Couple Records,No Records To Synchronize Now,Dependency not satisfied';
            OptionMembers = "Full Synchronization","Couple Records","No Records Found","Dependency not satisfied"; // "Dependency not satisfied" is obsolete option value
        }
        field(34; "Multi Company Synch. Enabled"; Boolean)
        {
            Caption = 'Multi-Company Synchronization Enabled';

            trigger OnValidate()
            var
                IntegrationTableMapping: Record "Integration Table Mapping";
            begin
                if not IntegrationTableMapping.Get(Name) then
                    Error(NoIntegrationMappingErr, Name);

                IntegrationTableMapping.Validate("Multi Company Synch. Enabled", Rec."Multi Company Synch. Enabled");
            end;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Generate(SkipEntitiesNotFullSyncReady: Boolean)
    var
        InitialSynchRecommendations: Dictionary of [Code[20], Integer];
        DeletedLines: List of [Code[20]];
    begin
        GenerateCRMSynchReviewLines(InitialSynchRecommendations, SkipEntitiesNotFullSyncReady, DeletedLines);
    end;


    [Scope('OnPrem')]
    procedure Generate(var InitialSynchRecommendations: Dictionary of [Code[20], Integer]; DeletedLines: List of [Code[20]])
    begin
        GenerateCRMSynchReviewLines(InitialSynchRecommendations, false, DeletedLines);
    end;

    [Scope('OnPrem')]
    procedure Generate(var InitialSynchRecommendations: Dictionary of [Code[20], Integer])
    var
        DeletedLines: List of [Code[20]];
    begin
        GenerateCRMSynchReviewLines(InitialSynchRecommendations, false, DeletedLines);
    end;

    procedure Generate()
    var
        InitialSynchRecommendations: Dictionary of [Code[20], Integer];
        DeletedLines: List of [Code[20]];
    begin
        GenerateCRMSynchReviewLines(InitialSynchRecommendations, false, DeletedLines);
    end;

    local procedure GenerateCRMSynchReviewLines(var InitialSynchRecommendations: Dictionary of [Code[20], Integer]; SkipNotFullSyncReady: Boolean; DeletedLines: List of [Code[20]])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        OwnershipModel: Option;
        handled: Boolean;
        IntegrationTableMappingFilter: Text;
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        CRMSynchHelper.OnGetCDSOwnershipModel(OwnershipModel, handled);
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            if handled and (OwnershipModel = CDSConnectionSetup."Ownership Model"::Team) then
                IntegrationTableMappingFilter := 'CUSTOMER|VENDOR|CONTACT|CURRENCY|PAYMENT TERMS|SHIPPING AGENT|SHIPMENT METHOD'
            else
                IntegrationTableMappingFilter := 'CUSTOMER|VENDOR|CONTACT|CURRENCY|PAYMENT TERMS|SHIPPING AGENT|SHIPMENT METHOD|SALESPEOPLE'
        else
            if handled and (OwnershipModel = CDSConnectionSetup."Ownership Model"::Team) then begin
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    IntegrationTableMappingFilter := '<>SALESPEOPLE&<>SOLINE-ORDERDETAIL&<>POSTEDSALESLINE-INV'
                else
                    IntegrationTableMappingFilter := '<>SALESPEOPLE&<>SALESORDER-ORDER&<>SOLINE-ORDERDETAIL&<>POSTEDSALESLINE-INV';
            end else
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    IntegrationTableMappingFilter := '<>SOLINE-ORDERDETAIL&<>POSTEDSALESLINE-INV'
                else
                    IntegrationTableMappingFilter := '<>SALESORDER-ORDER&<>SOLINE-ORDERDETAIL&<>POSTEDSALESLINE-INV';

        if IntegrationTableMappingFilter <> '' then
            IntegrationTableMapping.SetFilter(Name, IntegrationTableMappingFilter);

        if IntegrationTableMapping.FindSet() then
            repeat
                if not DeletedLines.Contains(IntegrationTableMapping.Name) then
                    InsertOrModifyCRMFullSynchReviewLines(IntegrationTableMapping, InitialSynchRecommendations, SkipNotFullSyncReady)
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure InsertOrModifyCRMFullSynchReviewLines(IntegrationTableMapping: Record "Integration Table Mapping"; var InitialSynchRecommendations: Dictionary of [Code[20], Integer]; SkipNotFullSyncReady: Boolean)
    begin
        if (not SkipNotFullSyncReady) or (GetInitialSynchRecommendation(IntegrationTableMapping, InitialSynchRecommendations) in ["Initial Synch Recommendation"::"Full Synchronization", "Initial Synch Recommendation"::"Couple Records"]) then begin
            Init();
            Name := IntegrationTableMapping.Name;
            "Multi Company Synch. Enabled" := IntegrationTableMapping."Multi Company Synch. Enabled";
            if not Find('=') then begin
                Validate("Dependency Filter", IntegrationTableMapping."Dependency Filter");
                Validate("Initial Synch Recommendation", GetInitialSynchRecommendation(IntegrationTableMapping, InitialSynchRecommendations));
                Direction := IntegrationTableMapping.Direction;
                Session.LogMessage('0000CDF', StrSubstNo(SynchRecommDetailsTxt, Name, Format(Direction), Format("Initial Synch Recommendation")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Insert(true);
            end else
                if "Job Queue Entry Status" = "Job Queue Entry Status"::" " then begin
                    Validate("Dependency Filter", IntegrationTableMapping."Dependency Filter");
                    Validate("Initial Synch Recommendation", GetInitialSynchRecommendation(IntegrationTableMapping, InitialSynchRecommendations));
                    Session.LogMessage('0000CDF', StrSubstNo(SynchRecommDetailsTxt, Name, Format(Direction), Format("Initial Synch Recommendation")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    Modify(true);
                end;
        end;
    end;

    procedure Start()
    var
        TempCRMFullSynchReviewLine: Record "CRM Full Synch. Review Line" temporary;
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        JobQueueEntryID: Guid;
    begin
        if FindLinesThatCanBeStarted(TempCRMFullSynchReviewLine) then
            repeat
                if TempCRMFullSynchReviewLine."Initial Synch Recommendation" = TempCRMFullSynchReviewLine."Initial Synch Recommendation"::"Full Synchronization" then
                    JobQueueEntryID := CRMIntegrationManagement.EnqueueFullSyncJob(TempCRMFullSynchReviewLine.Name);
                if TempCRMFullSynchReviewLine."Initial Synch Recommendation" = TempCRMFullSynchReviewLine."Initial Synch Recommendation"::"Couple Records" then
                    if IntegrationTableMapping.Get(TempCRMFullSynchReviewLine.Name) then
                        if CRMIntegrationManagement.MatchBasedCoupling(IntegrationTableMapping."Table ID", true, true, false) then begin
                            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Coupling Job Runner");
                            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                            if JobQueueEntry.FindFirst() then
                                JobQueueEntryID := JobQueueEntry.ID;
                        end;
                Get(TempCRMFullSynchReviewLine.Name);
                Validate("Job Queue Entry ID", JobQueueEntryID);
                Modify(true);
                Commit();
            until TempCRMFullSynchReviewLine.Next() = 0;
    end;


    internal procedure GetInitialSynchRecommendation(IntegrationTableMapping: Record "Integration Table Mapping"; var InitialSynchRecommendations: Dictionary of [Code[20], Integer]): Option
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMUomschedule: Record "CRM Uomschedule";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
        CDSRecRef: RecordRef;
        BCRecRef: RecordRef;
        DependencyInitialSynchRecommendation: Option "Full Synchronization","Couple Records","No Records Found","Dependency not satisfied"; // "Dependency not satisfied" is obsolete option value
    begin
        if InitialSynchRecommendations.ContainsKey(IntegrationTableMapping.Name) then
            exit(InitialSynchRecommendations.Get(IntegrationTableMapping.Name));

        BCRecRef.Open(IntegrationTableMapping."Table ID");
        CDSRecRef.Open(IntegrationTableMapping."Integration Table ID");

        case IntegrationTableMapping.Name of
            'SALESPEOPLE':
                exit("Initial Synch Recommendation"::"Full Synchronization");
            'CURRENCY':
                begin
                    DependencyInitialSynchRecommendation := GetCurrencyInitialSynchRecommendation();
                    exit(DependencyInitialSynchRecommendation);
                end;
            'VENDOR':
                begin
                    CRMAccount.Reset();
                    CRMAccount.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
                    CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Vendor);
                    if BCRecRef.IsEmpty() and CRMAccount.IsEmpty() then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CRMAccount.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'CUSTOMER':
                begin
                    CRMAccount.Reset();
                    CRMAccount.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Account"));
                    CRMAccount.SetRange(CustomerTypeCode, CRMAccount.CustomerTypeCode::Customer);
                    if BCRecRef.IsEmpty() and CRMAccount.IsEmpty() then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CRMAccount.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'CONTACT':
                begin
                    CRMContact.Reset();
                    CRMContact.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Contact"));
                    if BCRecRef.IsEmpty() and CRMContact.IsEmpty() then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (not CRMContact.IsEmpty()) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'UNIT OF MEASURE':
                begin
                    CRMUomschedule.Reset();
                    CRMUomschedule.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Uomschedule"));
                    if BCRecRef.IsEmpty() and (CRMUomschedule.Count() <= 1) then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (CRMUomschedule.Count() > 1) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'UNIT GROUP', 'ITEM UOM', 'RESOURCE UOM':
                begin
                    CRMUomschedule.Reset();
                    CRMUomschedule.SetView(LookupCRMTables.GetIntegrationTableMappingView(Database::"CRM Uomschedule"));
                    if BCRecRef.IsEmpty() and (CRMUomschedule.Count() <= 1) then
                        exit("Initial Synch Recommendation"::"No Records Found");
                    if (not BCRecRef.IsEmpty()) and (CRMUomschedule.Count() > 1) then
                        exit("Initial Synch Recommendation"::"Couple Records");
                end;
            'PAYMENT TERMS', 'SHIPPING AGENT', 'SHIPMENT METHOD':
                if BCRecRef.IsEmpty() then
                    exit("Initial Synch Recommendation"::"No Records Found")
                else
                    exit("Initial Synch Recommendation"::"Couple Records");
            else begin
                if BCRecRef.IsEmpty() and CDSRecRef.IsEmpty() then
                    exit("Initial Synch Recommendation"::"No Records Found");
                if (not BCRecRef.IsEmpty()) and (not CDSRecRef.IsEmpty()) then
                    exit("Initial Synch Recommendation"::"Couple Records");
            end;
        end;

        exit("Initial Synch Recommendation"::"Full Synchronization");
    end;

    local procedure GetCurrencyInitialSynchRecommendation(): Option
    var
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        CRMTransactionCurrency.Reset();
        CRMTransactionCurrency.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CRM Transactioncurrency"));
        if CRMTransactionCurrency.Count() = 1 then
            if CRMTransactionCurrency.FindFirst() then
                if CRMTransactionCurrency.ExchangeRate = 1.00 then
                    exit("Initial Synch Recommendation"::"Full Synchronization");
        exit("Initial Synch Recommendation"::"Couple Records");
    end;

    local procedure UpdateAsSynchJobStarted(MapName: Code[20]; JobID: Guid; SynchDirection: Option)
    begin
        Get(MapName);
        Validate("Job Queue Entry ID");
        case SynchDirection of
            Direction::"From Integration Table":
                Validate("From Int. Table Job ID", JobID);
            Direction::"To Integration Table":
                Validate("To Int. Table Job ID", JobID);
        end;
        Modify(true);
        Commit();
    end;

    local procedure UpdateAsSynchJobFinished(MapName: Code[20]; SynchDirection: Option)
    begin
        Get(MapName);
        Validate("Job Queue Entry ID");
        case SynchDirection of
            Direction::"From Integration Table":
                Validate("From Int. Table Job ID");
            Direction::"To Integration Table":
                Validate("To Int. Table Job ID");
        end;
        Modify(true);
        Commit();
    end;

    local procedure GetSynchJobStatus(JobID: Guid): Integer
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if IsNullGuid(JobID) then
            exit("To Int. Table Job Status"::" ");

        IntegrationSynchJob.Get(JobID);
        if IntegrationSynchJob."Finish Date/Time" = 0DT then
            exit("To Int. Table Job Status"::"In Process");

        if IntegrationSynchJob.AreSomeRecordsFailed() then
            exit("To Int. Table Job Status"::Error);

        exit("To Int. Table Job Status"::Success);
    end;

    local procedure FindLinesThatCanBeStarted(var TempCRMFullSynchReviewLine: Record "CRM Full Synch. Review Line" temporary): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        TempCRMFullSynchReviewLine.Reset();
        TempCRMFullSynchReviewLine.DeleteAll();

        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        if CRMFullSynchReviewLine.FindSet() then
            repeat
                if AreAllParentalJobsFinished(CRMFullSynchReviewLine."Dependency Filter") then begin
                    TempCRMFullSynchReviewLine := CRMFullSynchReviewLine;
                    TempCRMFullSynchReviewLine.Insert();
                end;
            until CRMFullSynchReviewLine.Next() = 0;
        exit(TempCRMFullSynchReviewLine.FindSet());
    end;

    local procedure AreAllParentalJobsFinished(DependencyFilter: Text[250]): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        if DependencyFilter <> '' then begin
            CRMFullSynchReviewLine.SetFilter(Name, DependencyFilter);
            CRMFullSynchReviewLine.SetFilter("Job Queue Entry Status", '<>%1', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
            CRMFullSynchReviewLine.SetFilter("Initial Synch Recommendation", '<>%1', CRMFullSynchReviewLine."Initial Synch Recommendation"::"No Records Found");
            exit(CRMFullSynchReviewLine.IsEmpty);
        end;
        exit(true);
    end;

    procedure FullSynchFinished(IntegrationTableMapping: Record "Integration Table Mapping"; SynchDirection: Option)
    begin
        if IntegrationTableMapping.IsFullSynch() then
            UpdateAsSynchJobFinished(IntegrationTableMapping."Parent Name", SynchDirection);
    end;

    procedure FullSynchStarted(IntegrationTableMapping: Record "Integration Table Mapping"; JobID: Guid; SynchDirection: Option)
    begin
        if IntegrationTableMapping.IsFullSynch() then
            UpdateAsSynchJobStarted(IntegrationTableMapping."Parent Name", JobID, SynchDirection);
    end;

    procedure OnBeforeModifyJobQueueEntry(JobQueueEntry: Record "Job Queue Entry")
    var
        NameToGet: Code[20];
    begin
        NameToGet := GetIntTableMappingNameJobQueueEntry(JobQueueEntry);
        if NameToGet = '' then
            exit;
        if Get(NameToGet) then begin
            SetJobQueueEntryStatus(JobQueueEntry.Status);
            Modify();

            if IsJobQueueEntryProcessed(JobQueueEntry) then
                Start();
        end;
    end;

    local procedure GetIntTableMappingNameJobQueueEntry(JobQueueEntry: Record "Job Queue Entry"): Code[20]
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SearchIntegrationTableMapping: Record "Integration Table Mapping";
        RecID: RecordID;
        RecRef: RecordRef;
    begin
        if Format(JobQueueEntry."Record ID to Process") = '' then
            exit;
        RecID := JobQueueEntry."Record ID to Process";
        if RecID.TableNo = DATABASE::"Integration Table Mapping" then begin
            RecRef := RecID.GetRecord();
            RecRef.SetTable(IntegrationTableMapping);
            SearchIntegrationTableMapping.SetLoadFields("Full Sync is Running", "Delete After Synchronization", "Parent Name");
            if not SearchIntegrationTableMapping.Get(IntegrationTableMapping.Name) then
                exit('');
            if SearchIntegrationTableMapping.IsFullSynch() then
                exit(SearchIntegrationTableMapping."Parent Name");
        end;
    end;

    local procedure IsJobQueueEntryProcessed(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        xJobQueueEntry: Record "Job Queue Entry";
    begin
        xJobQueueEntry := JobQueueEntry;
        xJobQueueEntry.Find();
        exit(
          (xJobQueueEntry.Status = xJobQueueEntry.Status::"In Process") and
          (xJobQueueEntry.Status <> JobQueueEntry.Status));
    end;

    procedure IsActiveSession(): Boolean
    begin
        exit(IsSessionActive("Session ID"));
    end;

    procedure IsThereActiveSessionInProgress(): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.SetFilter("Session ID", '<>0');
        CRMFullSynchReviewLine.SetRange("Job Queue Entry Status", "Job Queue Entry Status"::"In Process");
        if CRMFullSynchReviewLine.FindSet() then
            repeat
                if CRMFullSynchReviewLine.IsActiveSession() then
                    exit(true);
            until CRMFullSynchReviewLine.Next() = 0;
        exit(false);
    end;

    procedure IsThereBlankStatusLine(): Boolean
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.SetRange("Job Queue Entry Status", 0);
        exit(not CRMFullSynchReviewLine.IsEmpty);
    end;

    local procedure SetJobQueueEntryStatus(Status: Option)
    begin
        // shift the options to have an undefined state ' ' as 0.
        Validate("Job Queue Entry Status", Status + 1);
    end;

    procedure ShowJobQueueLogEntry()
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, "Job Queue Entry ID");
        PAGE.RunModal(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
    end;

    procedure ShowSynchJobLog(ID: Guid)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.SetRange(ID, ID);
        PAGE.RunModal(PAGE::"Integration Synch. Job List", IntegrationSynchJob);
    end;

    procedure GetStatusStyleExpression(StatusText: Text): Text
    begin
        case StatusText of
            'Error':
                exit('Unfavorable');
            'Finished', 'Success':
                exit('Favorable');
            'In Process':
                exit('Ambiguous');
            else
                exit('Subordinate');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetInitialSynchRecommendationStyleExpression(IntialSynchRecomeendation: Text): Text
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        case IntialSynchRecomeendation of
            Format(CRMFullSynchReviewLine."Initial Synch Recommendation"::"Dependency not satisfied"):
                exit('Unfavorable');
            Format(CRMFullSynchReviewLine."Initial Synch Recommendation"::"Full Synchronization"), Format(CRMFullSynchReviewLine."Initial Synch Recommendation"::"No Records Found"):
                exit('Favorable');
            Format(CRMFullSynchReviewLine."Initial Synch Recommendation"::"Couple Records"):
                exit('Ambiguous')
            else
                exit('Subordinate');
        end;
    end;

    var
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        SynchRecommDetailsTxt: Label 'The synchronization recommendation for Dataverse entity %1, with the direction %2 is %3', Comment = '%1 = Name of Dataverse entity, %2 = Synchronization Direction of Dataverse entity, %3 = Synchronization Recommendation', Locked = true;
        NoIntegrationMappingErr: Label 'Integration Table Mapping with the name %1 does not exist.', Comment = '%1 = Name of Integration Table Mapping';
}

