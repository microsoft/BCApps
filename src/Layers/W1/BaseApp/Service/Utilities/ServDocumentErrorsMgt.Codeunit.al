// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Service.Document;

codeunit 6478 "Serv. Document Errors Mgt."
{
    SingleInstance = true;

    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
        GlobalServiceOrderPage: Page "Service Order";
        GlobalServiceInvoicePage: Page "Service Invoice";
        GlobalServiceCreditMemoPage: Page "Service Credit Memo";
        CheckRunTxt: Label 'Check run', Locked = true;
        ErrorsFoundTxt: Label 'Errors Found', Locked = true;
        TableNameTxt: Label 'Table Name', Locked = true;
        DocumentTypeTxt: Label 'Document Type', Locked = true;
        TelemetryFeatureNameTxt: Label 'Check documents and journals while you work', Locked = true;

    [EventSubscriber(ObjectType::Page, Page::"Service Invoice Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventServiceInvoiceSubform(var Rec: Record "Service Line"; var xRec: Record "Service Line"; var AllowModify: Boolean)
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceInvoicePage.RunBackgroundCheck();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Credit Memo Subform", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventServiceCreditMemoSubform(var Rec: Record "Service Line"; var xRec: Record "Service Line"; var AllowModify: Boolean)
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceCreditMemoPage.RunBackgroundCheck();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Order", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordServiceOrder(var Sender: Page "Service Order"; var ServiceHeader: Record "Service Header")
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceOrderPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Invoice", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordServiceInvoice(var Sender: Page "Service Invoice"; var ServiceHeader: Record "Service Header")
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceInvoicePage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Credit Memo", 'OnAfterOnAfterGetRecord', '', false, false)]
    local procedure OnAfterOnAfterGetRecordServiceCreditMemo(var Sender: Page "Service Credit Memo"; var ServiceHeader: Record "Service Header")
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceCreditMemoPage := Sender;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Order", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventServiceOrder(var Rec: Record "Service Header"; var xRec: Record "Service Header"; var AllowModify: Boolean)
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceOrderPage.RunBackgroundCheck();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Invoice", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventServiceInvoice(var Rec: Record "Service Header"; var xRec: Record "Service Header"; var AllowModify: Boolean)
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceInvoicePage.RunBackgroundCheck();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Credit Memo", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventServiceCreditMemo(var Rec: Record "Service Header"; var xRec: Record "Service Header"; var AllowModify: Boolean)
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            GlobalServiceCreditMemoPage.RunBackgroundCheck();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Service Doc. Check Factbox", 'OnAfterGetCurrRecordEvent', '', false, false)]
    local procedure OnAfterGetCurrRecordServiceDocCheckFactbox(var Rec: Record "Service Header")
    begin
        if DocumentErrorsMgt.BackgroundValidationEnabled() then
            case Rec."Document Type" of
                "Service Document Type"::Invoice:
                    GlobalServiceInvoicePage.RunBackgroundCheck();
                "Service Document Type"::Order:
                    GlobalServiceOrderPage.RunBackgroundCheck();
                "Service Document Type"::"Credit Memo":
                    GlobalServiceCreditMemoPage.RunBackgroundCheck();
            end;
    end;

    procedure CollectServiceDocCheckParameters(ServiceHeader: Record "Service Header"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Document No." := ServiceHeader."No.";
        ErrorHandlingParameters."Service Document Type" := ServiceHeader."Document Type";
        ErrorHandlingParameters."Full Document Check" := true;
    end;

    procedure FeatureTelemetryLogUsageService(ErrorsFound: Boolean; TableName: Text; DocumentType: Enum "Service Document Type")
    var
        TranslationHelper: Codeunit System.IO."Translation Helper";
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
}
