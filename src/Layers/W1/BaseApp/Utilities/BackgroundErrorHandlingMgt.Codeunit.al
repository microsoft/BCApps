// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Journal;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.IO;
using System.Telemetry;
using System.Utilities;

codeunit 9079 "Background Error Handling Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ItemJournalErrorsMgt: Codeunit "Item Journal Errors Mgt.";
        JobJournalErrorsMgt: Codeunit "Job Journal Errors Mgt.";
        ResJournalErrorsMgt: Codeunit "Res. Journal Errors Mgt.";
        TranslationHelper: Codeunit "Translation Helper";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NullJSONTxt: Label 'null', Locked = true;
        CheckRunTxt: Label 'Check run', Locked = true;
        ErrorsFoundTxt: Label 'Errors Found', Locked = true;
        TableNameTxt: Label 'Table Name', Locked = true;
        DocumentTypeTxt: Label 'Document Type', Locked = true;
        TelemetryFeatureNameTxt: Label 'Check documents and journals while you work', Locked = true;

    procedure BackgroundValidationFeatureEnabled(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Enable Data Check");
    end;

    procedure CleanTempErrorMessages(var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        CheckCleanDeletedGenJnlLinesErrors(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then begin
            TempErrorMessage.Reset();
            TempErrorMessage.DeleteAll();
        end else
            if ErrorHandlingParameters."Line Modified" then begin
                CleanDocumentRelatedErrors(
                    TempErrorMessage, ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name",
                    ErrorHandlingParameters."Previous Document No.", ErrorHandlingParameters."Previous Posting Date");
                CleanDocumentRelatedErrors(
                    TempErrorMessage, ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name",
                    ErrorHandlingParameters."Document No.", ErrorHandlingParameters."Posting Date");
            end;
    end;

    local procedure CheckCleanDeletedGenJnlLinesErrors(var TempErrorMessage: Record "Error Message" temporary)
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        if JournalErrorsMgt.GetDeletedGenJnlLine(TempGenJnlLine, true) then begin
            TempErrorMessage.Reset();
            if TempGenJnlLine.FindSet() then
                repeat
                    TempErrorMessage.SetRange("Context Record ID", TempGenJnlLine.RecordId());
                    TempErrorMessage.DeleteAll();

                    CleanDocumentRelatedErrors(
                        TempErrorMessage, TempGenJnlLine."Journal Template Name", TempGenJnlLine."Journal Batch Name",
                        TempGenJnlLine."Document No.", TempGenJnlLine."Posting Date");
                until TempGenJnlLine.Next() = 0;
        end;
    end;

    procedure CleanItemJnlTempErrorMessages(var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        CheckCleanDeletedItemJnlLinesErrors(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then begin
            TempErrorMessage.Reset();
            TempErrorMessage.DeleteAll();
        end else begin
            if ItemJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Line No.") then
                CleanItemJnlLineRelatedError(TempErrorMessage, ItemJnlLine);
            if ItemJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Previous Line No.") then
                CleanItemJnlLineRelatedError(TempErrorMessage, ItemJnlLine);
        end;
    end;

    local procedure CleanItemJnlLineRelatedError(var TempErrorMessage: Record "Error Message" temporary; ItemJnlLine: Record "Item Journal Line")
    begin
        TempErrorMessage.SetRange("Context Table Number", Database::"Item Journal Line");
        TempErrorMessage.SetRange("Context Record ID", ItemJnlLine.RecordId());
        TempErrorMessage.DeleteAll();
    end;

    local procedure CheckCleanDeletedItemJnlLinesErrors(var TempErrorMessage: Record "Error Message" temporary)
    var
        TempItemJnlLine: Record "Item Journal Line" temporary;
    begin
        if ItemJournalErrorsMgt.GetDeletedItemJnlLine(TempItemJnlLine, true) then begin
            TempErrorMessage.Reset();
            if TempItemJnlLine.FindSet() then
                repeat
                    CleanItemJnlLineRelatedError(TempErrorMessage, TempItemJnlLine);
                until TempItemJnlLine.Next() = 0;
        end;
    end;

    local procedure CleanDocumentRelatedErrors(var TempErrorMessage: Record "Error Message" temporary; TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date)
    var
        DocGenJnlLine: Record "Gen. Journal Line";
    begin
        TempErrorMessage.Reset();
        DocGenJnlLine.SetRange("Journal Template Name", TemplateName);
        DocGenJnlLine.SetRange("Journal Batch Name", BatchName);
        DocGenJnlLine.SetRange("Document No.", DocumentNo);
        DocGenJnlLine.SetRange("Posting Date", PostingDate);
        if DocGenJnlLine.FindSet() then
            repeat
                TempErrorMessage.SetRange("Context Record ID", DocGenJnlLine.RecordId());
                TempErrorMessage.DeleteAll();
            until DocGenJnlLine.Next() = 0;
    end;

    procedure CollectGenJnlCheckParameters(GenJnlLine: Record "Gen. Journal Line"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempxGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        ErrorHandlingParameters."Journal Template Name" := GenJnlLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        ErrorHandlingParameters."Full Batch Check" := JournalErrorsMgt.GetFullBatchCheck();
        ErrorHandlingParameters."Line Modified" := JournalErrorsMgt.GetRecXRecOnModify(TempxGenJnlLine, TempGenJnlLine);
        ErrorHandlingParameters."Document No." := TempGenJnlLine."Document No.";
        ErrorHandlingParameters."Posting Date" := TempGenJnlLine."Posting Date";
        ErrorHandlingParameters."Previous Document No." := TempxGenJnlLine."Document No.";
        ErrorHandlingParameters."Previous Posting Date" := TempxGenJnlLine."Posting Date";
    end;

    procedure CollectItemJnlCheckParameters(ItemJnlLine: Record "Item Journal Line"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Journal Template Name" := ItemJnlLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
        ErrorHandlingParameters."Line No." := ItemJnlLine."Line No.";
        ErrorHandlingParameters."Full Batch Check" := ItemJournalErrorsMgt.GetFullBatchCheck();
        ErrorHandlingParameters."Previous Line No." := ItemJournalErrorsMgt.GetItemJnlLinePreviousLineNo();
    end;

    procedure CollectSalesDocCheckParameters(SalesHeader: Record "Sales Header"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Document No." := SalesHeader."No.";
        ErrorHandlingParameters."Sales Document Type" := SalesHeader."Document Type";
        ErrorHandlingParameters."Full Document Check" := DocumentErrorsMgt.GetFullDocumentCheck();
        ErrorHandlingParameters."Line No." := DocumentErrorsMgt.GetModifiedSalesLineNo();
    end;

    procedure CollectPurchaseDocCheckParameters(PurchaseHeader: Record "Purchase Header"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Document No." := PurchaseHeader."No.";
        ErrorHandlingParameters."Purchase Document Type" := PurchaseHeader."Document Type";
        ErrorHandlingParameters."Full Document Check" := DocumentErrorsMgt.GetFullDocumentCheck();
        ErrorHandlingParameters."Line No." := DocumentErrorsMgt.GetModifiedPurchaseLineNo();
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Document Errors Mgt.', '25.0')]
    procedure CollectServiceDocCheckParameters(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Document No." := ServiceHeader."No.";
        ErrorHandlingParameters."Service Document Type" := ServiceHeader."Document Type";
        ErrorHandlingParameters."Full Document Check" := true;
    end;
#endif

    procedure GetErrorsFromItemJnlCheckResultValues(ResultValues: List of [Text]; var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        CleanItemJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        ErrorMessageMgt.GetErrorsFromResultValues(ResultValues, TempErrorMessage);
        ItemJournalErrorsMgt.SetErrorMessages(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then
            ItemJournalErrorsMgt.SetFullBatchCheck(false);
    end;

    procedure GetErrorsFromResJnlCheckResultValues(ResultValues: List of [Text]; var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        CleanResJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        ErrorMessageMgt.GetErrorsFromResultValues(ResultValues, TempErrorMessage);
        ResJournalErrorsMgt.SetErrorMessages(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then
            ResJournalErrorsMgt.SetFullBatchCheck(false);
    end;

    procedure GetErrorsFromDocumentCheckResultValues(ResultValues: List of [Text]; var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        CleanSalesTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        ErrorMessageMgt.GetErrorsFromResultValues(ResultValues, TempErrorMessage);
        DocumentErrorsMgt.SetErrorMessages(TempErrorMessage);

        if ErrorHandlingParameters."Full Document Check" then
            DocumentErrorsMgt.SetFullDocumentCheck(false);
    end;

    procedure CleanSalesTempErrorMessages(var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        if ErrorHandlingParameters."Full Document Check" then begin
            TempErrorMessage.Reset();
            TempErrorMessage.DeleteAll();
        end else
            if ErrorHandlingParameters."Line No." <> 0 then begin
                TempSalesLine."Document Type" := ErrorHandlingParameters."Sales Document Type";
                TempSalesLine."Document No." := ErrorHandlingParameters."Document No.";
                TempSalesLine."Line No." := ErrorHandlingParameters."Line No.";
                TempErrorMessage.SetRange("Context Table Number", Database::"Sales Line");
                TempErrorMessage.SetRange("Context Record ID", TempSalesLine.RecordId());
                TempErrorMessage.DeleteAll();
            end;
    end;

    procedure CleanResJnlTempErrorMessages(var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        CheckCleanDeletedResJnlLinesErrors(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then begin
            TempErrorMessage.Reset();
            TempErrorMessage.DeleteAll();
        end else begin
            if ResJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Line No.") then
                CleanResJnlLineRelatedError(TempErrorMessage, ResJnlLine);
            if ResJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Previous Line No.") then
                CleanResJnlLineRelatedError(TempErrorMessage, ResJnlLine);
        end;
    end;

    local procedure CleanResJnlLineRelatedError(var TempErrorMessage: Record "Error Message" temporary; ResJnlLine: Record "Res. Journal Line")
    begin
        TempErrorMessage.SetRange("Context Table Number", Database::"Res. Journal Line");
        TempErrorMessage.SetRange("Context Record ID", ResJnlLine.RecordId());
        TempErrorMessage.DeleteAll();
    end;

    local procedure CheckCleanDeletedResJnlLinesErrors(var TempErrorMessage: Record "Error Message" temporary)
    var
        TempResJnlLine: Record "Res. Journal Line" temporary;
    begin
        if ResJournalErrorsMgt.GetDeletedResJnlLine(TempResJnlLine, true) then begin
            TempErrorMessage.Reset();
            if TempResJnlLine.FindSet() then
                repeat
                    CleanResJnlLineRelatedError(TempErrorMessage, TempResJnlLine);
                until TempResJnlLine.Next() = 0;
        end;
    end;

    procedure GetErrorsFromGenJnlCheckResultValues(ResultValues: List of [Text]; var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        ErrorMessageMgt.GetErrorsFromResultValues(ResultValues, TempErrorMessage);
        JournalErrorsMgt.SetErrorMessages(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then
            JournalErrorsMgt.SetFullBatchCheck(false);
    end;

    procedure GetErrorsFromJobJnlCheckResultValues(ResultValues: List of [Text]; var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        CleanJobJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);
        ErrorMessageMgt.GetErrorsFromResultValues(ResultValues, TempErrorMessage);
        JobJournalErrorsMgt.SetErrorMessages(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then
            JobJournalErrorsMgt.SetFullBatchCheck(false);
    end;

    procedure CleanJobJnlTempErrorMessages(var TempErrorMessage: Record "Error Message" temporary; ErrorHandlingParameters: Record "Error Handling Parameters")
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        CheckCleanDeletedJobJnlLinesErrors(TempErrorMessage);

        if ErrorHandlingParameters."Full Batch Check" then begin
            TempErrorMessage.Reset();
            TempErrorMessage.DeleteAll();
        end else begin
            if JobJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Line No.") then
                CleanJobJnlLineRelatedError(TempErrorMessage, JobJnlLine);
            if JobJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Previous Line No.") then
                CleanJobJnlLineRelatedError(TempErrorMessage, JobJnlLine);
        end;
    end;

    local procedure CleanJobJnlLineRelatedError(var TempErrorMessage: Record "Error Message" temporary; JobJnlLine: Record "Job Journal Line")
    begin
        TempErrorMessage.SetRange("Context Table Number", Database::"Job Journal Line");
        TempErrorMessage.SetRange("Context Record ID", JobJnlLine.RecordId());
        TempErrorMessage.DeleteAll();
    end;

    local procedure CheckCleanDeletedJobJnlLinesErrors(var TempErrorMessage: Record "Error Message" temporary)
    var
        TempJobJnlLine: Record "Job Journal Line" temporary;
    begin
        if JobJournalErrorsMgt.GetDeletedJobJnlLine(TempJobJnlLine, true) then begin
            TempErrorMessage.Reset();
            if TempJobJnlLine.FindSet() then
                repeat
                    CleanJobJnlLineRelatedError(TempErrorMessage, TempJobJnlLine);
                until TempJobJnlLine.Next() = 0;
        end;
    end;

    procedure PackDeletedDocumentsToArgs(var Args: Dictionary of [Text, Text])
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        if JournalErrorsMgt.GetDeletedGenJnlLine(TempGenJnlLine, false) then begin
            TempGenJnlLine.FindSet();
            repeat
                Args.Add(Format(TempGenJnlLine."Line No."), DeletedDocumentToJson(TempGenJnlLine));
            until TempGenJnlLine.Next() = 0;
        end;
    end;

    local procedure DeletedDocumentToJson(TempGenJnlLine: Record "Gen. Journal Line" temporary) JSON: Text
    var
        JObject: JsonObject;
    begin
        JObject.Add(TempGenJnlLine.FieldName("Document No."), TempGenJnlLine."Document No.");
        JObject.Add(TempGenJnlLine.FieldName("Posting Date"), TempGenJnlLine."Posting Date");
        JObject.WriteTo(JSON);
    end;

    local procedure ParseDeletedDocument(JSON: Text; var TempGenJnlLine: Record "Gen. Journal Line" temporary): Boolean
    var
        JObject: JsonObject;
        DocumentNo: Text;
        PostingDateText: Text;
    begin
        if NullJSONTxt <> JSON then begin
            if not JObject.ReadFrom(JSON) then
                exit(false);
            if not GetJsonKeyValue(JObject, TempGenJnlLine.FieldName("Document No."), DocumentNo) then
                exit(false);
            if not GetJsonKeyValue(JObject, TempGenJnlLine.FieldName("Posting Date"), PostingDateText) then
                exit(false);

            TempGenJnlLine.Init();
            TempGenJnlLine."Document No." := CopyStr(DocumentNo, 1, MaxStrLen(TempGenJnlLine."Document No."));
            Evaluate(TempGenJnlLine."Posting Date", PostingDateText);

            exit(true);
        end;
    end;

    local procedure GetJsonKeyValue(var JObject: JsonObject; KeyName: Text; var KeyValue: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(false);

        KeyValue := JToken.AsValue().AsText();
        exit(true);
    end;

    procedure GetDeletedDocumentsFromArgs(Args: Dictionary of [Text, Text]; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        JSON: Text;
    begin
        foreach JSON in Args.Values do
            if ParseDeletedDocument(JSON, TempGenJnlLine) then begin
                TempGenJnlLine."Line No." += 10000;
                TempGenJnlLine.Insert();
            end;
    end;

    procedure FeatureTelemetryLogUptakeUsed()
    begin
        FeatureTelemetry.LogUptake('0000GNO', TelemetryFeatureNameTxt, "Feature Uptake Status"::Used)
    end;

    procedure FeatureTelemetryLogUsage(ErrorsFound: Boolean; TableName: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        CustomDimensions.Add(ErrorsFoundTxt, Format(ErrorsFound));
        CustomDimensions.Add(TableNameTxt, TableName);
        FeatureTelemetry.LogUsage('0000GNP', TelemetryFeatureNameTxt, CheckRunTxt, CustomDimensions);
        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure FeatureTelemetryLogUsageSales(ErrorsFound: Boolean; TableName: Text; DocumentType: Enum "Sales Document Type")
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        FeatureTelemetryLogUsageDocument(ErrorsFound, TableName, Format(DocumentType));
        TranslationHelper.RestoreGlobalLanguage();
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Document Errors Mgt.', '25.0')]
    procedure FeatureTelemetryLogUsageService(ErrorsFound: Boolean; TableName: Text; DocumentType: Enum Microsoft.Service.Document."Service Document Type")
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        FeatureTelemetryLogUsageDocument(ErrorsFound, TableName, Format(DocumentType));
        TranslationHelper.RestoreGlobalLanguage();
    end;
#endif

    procedure FeatureTelemetryLogUsagePurchase(ErrorsFound: Boolean; TableName: Text; DocumentType: Enum "Purchase Document Type")
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        FeatureTelemetryLogUsageDocument(ErrorsFound, TableName, Format(DocumentType));
        TranslationHelper.RestoreGlobalLanguage();
    end;

    local procedure FeatureTelemetryLogUsageDocument(ErrorsFound: Boolean; TableName: Text; DocumentType: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add(ErrorsFoundTxt, Format(ErrorsFound));
        CustomDimensions.Add(TableNameTxt, TableName);
        CustomDimensions.Add(DocumentTypeTxt, DocumentType);
        FeatureTelemetry.LogUsage('0000GNM', TelemetryFeatureNameTxt, CheckRunTxt, CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterValidateEvent', 'Enable Data Check', false, false)]
    local procedure AfterValidateGLSetupEnableDataCheck(var Rec: Record "General Ledger Setup"; var xRec: Record "General Ledger Setup"; CurrFieldNo: Integer)
    begin
        if Rec."Enable Data Check" then
            FeatureTelemetry.LogUptake('0000GNK', TelemetryFeatureNameTxt, "Feature Uptake Status"::Discovered)
        else
            FeatureTelemetry.LogUptake('0000GNN', TelemetryFeatureNameTxt, "Feature Uptake Status"::Undiscovered)
    end;

    [EventSubscriber(ObjectType::Table, Database::"My Notifications", 'OnAfterValidateEvent', 'Enabled', false, false)]
    local procedure AfterValidateMyNotificationsDataCheck(var Rec: Record "My Notifications"; var xRec: Record "My Notifications"; CurrFieldNo: Integer)
    begin
        if Rec."Notification Id" = DocumentErrorsMgt.GetShowDocumentCheckFactboxNotificationID() then
            if Rec.Enabled then
                FeatureTelemetry.LogUptake('0000GNL', TelemetryFeatureNameTxt, "Feature Uptake Status"::"Set up")
    end;
}
