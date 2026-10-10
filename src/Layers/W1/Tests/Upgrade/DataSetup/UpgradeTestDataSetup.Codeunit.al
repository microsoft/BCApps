codeunit 132802 "Upgrade Test Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupCRMStatus()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.get() then
            CRMConnectionSetup.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnGetTablesToBackupPerCompany', '', false, false)]
    local procedure BackupIntegrationTableMapping(TableMapping: Dictionary of [Integer, Integer])
    var
        UPGIntegrationTableMapping: Record "UPG-Integration Table Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        OpportunityTableFilter: Text;
    begin
        IntegrationTableMapping.SetRange(Name, 'OPPORTUNITY');
        IntegrationTableMapping.SetRange("Table ID", Database::Opportunity);
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Opportunity");
        if IntegrationTableMapping.FindFirst() then begin
            OpportunityTableFilter := IntegrationTableMapping.GetTableFilter();
            UPGIntegrationTableMapping.Name := IntegrationTableMapping.Name;
            UPGIntegrationTableMapping.SetTableFilter(OpportunityTableFilter);
            UPGIntegrationTableMapping.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnGetTablesToBackupPerDatabase', '', false, false)]
    local procedure BackupUpgradeTags(TableMapping: Dictionary of [Integer, Integer])
    begin
        TableMapping.Add(9999, Database::"UPG - Upgrade Tag")
    end;
    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyWhseActivityLineForJobSource()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("No.", 'UPG-WHACT-J01');
        WarehouseActivityLine.DeleteAll();

        WarehouseActivityLine.Init();
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."No." := 'UPG-WHACT-J01';
        WarehouseActivityLine."Line No." := 10000;
        WarehouseActivityLine."Source Type" := Database::Job;
        WarehouseActivityLine."Source Subtype" := 0;
        WarehouseActivityLine."Source No." := 'UPG-JOB-01';
        WarehouseActivityLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyWhseWorksheetLineForJobSource()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", 'UPGWHT');
        WhseWorksheetLine.SetRange(Name, 'UPGWSN');
        WhseWorksheetLine.DeleteAll();

        WhseWorksheetLine.Init();
        WhseWorksheetLine."Worksheet Template Name" := 'UPGWHT';
        WhseWorksheetLine.Name := 'UPGWSN';
        WhseWorksheetLine."Location Code" := '';
        WhseWorksheetLine."Line No." := 10000;
        WhseWorksheetLine."Source Type" := Database::Job;
        WhseWorksheetLine."Source Subtype" := 0;
        WhseWorksheetLine."Source No." := 'UPG-JOB-01';
        WhseWorksheetLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyWarehouseRequestForJobSource()
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetFilter("Source No.", '%1|%2', 'UPG-JOB-01', 'UPG-SALES-01');
        WarehouseRequest.DeleteAll();

        // Legacy Job row that MUST be renamed to (Database::"Job Planning Line", Order) by the upgrade.
        WarehouseRequest.Init();
        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Location Code" := '';
        WarehouseRequest."Source Type" := Database::Job;
        WarehouseRequest."Source Subtype" := 0;
        WarehouseRequest."Source No." := 'UPG-JOB-01';
        WarehouseRequest.Insert();

        // Non-job row (Sales Header) that MUST NOT be touched by the upgrade. Guards against a regression
        // where the Warehouse Request FindSet() loop iterates without a Source Type / Source Subtype filter.
        WarehouseRequest.Init();
        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Location Code" := '';
        WarehouseRequest."Source Type" := Database::"Sales Header";
        WarehouseRequest."Source Subtype" := 1; // Sales Order
        WarehouseRequest."Source No." := 'UPG-SALES-01';
        WarehouseRequest.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupLegacyReminderCommunicationData()
    begin
        SetupLegacyOnlyReminderCommunicationData();
        SetupPartialReminderCommunicationData();
    end;

    local procedure SetupLegacyOnlyReminderCommunicationData()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        LanguageCode: Code[10];
    begin
        LanguageCode := GetLanguageCode();
        CreateReminderTermsAndLevel(ReminderTerms, ReminderLevel, 'UPGRM1', 'Legacy terms fee', 'Legacy level fee');
        CreateLegacyReminderText(ReminderLevel, "Reminder Text Position"::Beginning, 10000, 'Legacy beginning', '');
        CreateLegacyReminderText(ReminderLevel, "Reminder Text Position"::Ending, 10000, 'Legacy ending', '');
        CreateLegacyReminderText(ReminderLevel, "Reminder Text Position"::"Email Body", 10000, '', 'Legacy email body');
        CreateReminderTermsTranslation(ReminderTerms.Code, LanguageCode, 'Legacy translated fee');
    end;

    local procedure SetupPartialReminderCommunicationData()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
        ReminderEmailText: Record "Reminder Email Text";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        AttachmentTextId: Guid;
        EmailTextId: Guid;
        LanguageCode: Code[10];
    begin
        LanguageCode := GetLanguageCode();
        CreateReminderTermsAndLevel(ReminderTerms, ReminderLevel, 'UPGRM2', '', 'Legacy level fee');
        CreateLegacyReminderText(ReminderLevel, "Reminder Text Position"::Beginning, 10000, 'Legacy beginning', '');
        CreateLegacyReminderText(ReminderLevel, "Reminder Text Position"::Ending, 10000, 'Legacy ending', '');
        CreateLegacyReminderText(ReminderLevel, "Reminder Text Position"::"Email Body", 10000, '', 'Legacy email body');

        AttachmentTextId := CreateGuid();
        EmailTextId := CreateGuid();
        ReminderLevel."Reminder Attachment Text" := AttachmentTextId;
        ReminderLevel."Reminder Email Text" := EmailTextId;
        ReminderLevel.Modify();

        ReminderAttachmentText.Init();
        ReminderAttachmentText.Id := AttachmentTextId;
        ReminderAttachmentText."Language Code" := LanguageCode;
        ReminderAttachmentText."Source Type" := "Reminder Text Source Type"::"Reminder Level";
        ReminderAttachmentText."Inline Fee Description" := 'Permanent level fee';
        ReminderAttachmentText.Insert();

        ReminderAttachmentTextLine.Init();
        ReminderAttachmentTextLine.Id := AttachmentTextId;
        ReminderAttachmentTextLine."Language Code" := LanguageCode;
        ReminderAttachmentTextLine.Position := ReminderAttachmentTextLine.Position::"Beginning Line";
        ReminderAttachmentTextLine."Line No." := 10000;
        ReminderAttachmentTextLine.Text := 'Permanent beginning';
        ReminderAttachmentTextLine.Insert();

        ReminderEmailText.Init();
        ReminderEmailText.Id := EmailTextId;
        ReminderEmailText."Language Code" := LanguageCode;
        ReminderEmailText."Source Type" := "Reminder Text Source Type"::"Reminder Level";
        ReminderEmailText.Insert();
        ReminderEmailText.SetBodyText('Permanent email body');
    end;

    local procedure CreateReminderTermsAndLevel(var ReminderTerms: Record "Reminder Terms"; var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10]; TermsFeeDescription: Text[150]; LevelFeeDescription: Text[100])
    begin
        ReminderTerms.Init();
        ReminderTerms.Code := ReminderTermsCode;
        ReminderTerms."Note About Line Fee on Report" := TermsFeeDescription;
        ReminderTerms.Insert();

        ReminderLevel.Init();
        ReminderLevel."Reminder Terms Code" := ReminderTermsCode;
        ReminderLevel."No." := 1;
        ReminderLevel."Add. Fee per Line Description" := LevelFeeDescription;
        ReminderLevel.Insert();
    end;

    local procedure CreateLegacyReminderText(ReminderLevel: Record "Reminder Level"; Position: Enum "Reminder Text Position"; LineNo: Integer; LineText: Text[100]; EmailBody: Text)
    var
        ReminderText: Record "Reminder Text";
        EmailTextOutStream: OutStream;
    begin
        ReminderText.Init();
        ReminderText."Reminder Terms Code" := ReminderLevel."Reminder Terms Code";
        ReminderText."Reminder Level" := ReminderLevel."No.";
        ReminderText.Position := Position;
        ReminderText."Line No." := LineNo;
        ReminderText.Text := LineText;
        if EmailBody <> '' then begin
            ReminderText."Email Text".CreateOutStream(EmailTextOutStream, TextEncoding::UTF8);
            EmailTextOutStream.WriteText(EmailBody);
        end;
        ReminderText.Insert();
    end;

    local procedure CreateReminderTermsTranslation(ReminderTermsCode: Code[10]; LanguageCode: Code[10]; FeeDescription: Text[150])
    var
        ReminderTermsTranslation: Record "Reminder Terms Translation";
    begin
        ReminderTermsTranslation.Init();
        ReminderTermsTranslation."Reminder Terms Code" := ReminderTermsCode;
        ReminderTermsTranslation."Language Code" := LanguageCode;
        ReminderTermsTranslation."Note About Line Fee on Report" := FeeDescription;
        ReminderTermsTranslation.Insert();
    end;

    local procedure GetLanguageCode(): Code[10]
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetLanguageCode(Language.GetDefaultApplicationLanguageId()));
    end;
}