// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using System.AI;
using System.Environment;
using System.Environment.Configuration;

codeunit 7499 "Item From Picture"
{
    Access = Internal;
    Permissions = tabledata "Nav App Setting" = rm,
                  tabledata "Image Analysis Scenario" = Rimd;

    var
        // Setup handling
        ImageAnalysisDisabledNotAdminTxt: Label 'Next time you open this page, we can prefill some information for you. Ask your admin to activate this feature.';
        ImageAnalysisDisabledAdminTxt: Label 'Next time you open this page, we can prefill some information for you.';
        ImageAnalysisDisabledActionTxt: Label 'Set up';
        NotificationDontShowActionTxt: Label 'Don''t ask again';
        ImageAnalysisDisabledNotificationIdTxt: Label 'e33a923a-1931-488b-a6c9-2aefd146b2ab', Locked = true;
        ImageAnalysisErrorNotificationIdTxt: Label '046babbb-1713-45a2-b337-db23198314d2', Locked = true;
        ImageAnalysisNotificationNameTxt: Label 'Notify the user of Image Analysis capabilities when creating an item from picture.', MaxLength = 128;
        ImageAnalysisNotificationDescriptionTxt: Label 'Reminds the user that the Item From Picture experience supports using Image Analysis capabilities.';
        ItemFromPictureScenarioTxt: Label 'ITEM FROM PICTURE', Locked = true;
        // Sandbox HTTP calls handling
        SystemApplicationAppIdTxt: Label '63ca2fa4-4f03-4f2b-a480-172fef340d3f', Locked = true;
        EnableHttpCallsQst: Label 'This feature only works if you allow %1 extensions to communicate with external services. This is turned off by default in Sandbox environments.\\Do you want to allow communication from %1 extensions to external services? You can always change this from the Extension Management page.', Comment = '%1 = The publisher of the BaseApp extension, for example Microsoft.';
        CouldNotEnableHttpCallsMsg: Label 'We could not enable external calls for this scenario. You might lack permissions for this operation.';
        // Image handling
        ImageFileFilterLbl: Label 'All supported images (*.jpg;*.jpeg;*.png;*.gif;*.bmp)';
        ImageFileFilterExtensionsTxt: Label '%1|*.jpg;*.jpeg;*.png;*.gif;*.bmp', Locked = true;
        TempItemMediaTxt: Label 'Create Item From Picture: %1', MaxLength = 250, Comment = '%1: the original picture name, for example "table.png"';
        UploadDialogCaptionTxt: Label 'Upload a picture to get started';
        // Item handling
        ItemDescriptionCategoryFileTxt: Label '%1 (from picture "%2")', Comment = '%1: a category name, for example "Kitchen appliances"; %2: a file name, for example "fork_2023_02_07"';
        ItemDescriptionCategoryTxt: Label '%1', Comment = '%1: a category name, for example "Kitchen appliances"';
        ItemDescriptionFileTxt: Label 'Item from picture "%1"', Comment = '%1: a file name, for example "fork_2023_02_07"';
        // Error handling
        LimitReachedMsg: Label 'Seems like you reached the current limit of image analysis (%1 per %2). You won''t be able to analyze more images until the next period starts.', Comment = '%1: a number, for example 100; %2: a time period, for example "Month" or "Hour"';
        AnalysisNotPerformedMsg: Label 'We could not analyze your image because of the following error: %1', Comment = '%1: an error, for example "Usage limit reached"';
        // Telemetry
        ItemFromPictureTelemetryCategoryTxt: Label 'AL Item From Picture', Locked = true;
        ImageAnalysisFailedTelemetryTxt: Label 'Image analysis failed while creating item from picture.', Locked = true;
        ImageAnalysisCompleteTelemetryTxt: Label 'Image analysis completed successfully. Category found: %1. Template found: %2. Limit reached: %3.', Locked = true;
        ImageAnalysisStartedTelemetryTxt: Label 'Image analysis started for analysis types: %1.', Locked = true;
        SavingAttributesTelemetryTxt: Label 'Saving %1 attributes for item.', Locked = true;

    procedure EnableImageAnalysisScenario()
    var
        ImageAnalysisScenario: Record "Image Analysis Scenario";
        ItemFromPicture: Codeunit "Item From Picture";
    begin
        ImageAnalysisScenario.SetRange("Scenario Name", ItemFromPicture.GetItemFromPictureScenario());
        ImageAnalysisScenario.DeleteAll();

        ImageAnalysisScenario.Init();
        ImageAnalysisScenario."Scenario Name" := ItemFromPicture.GetItemFromPictureScenario();
        ImageAnalysisScenario."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ImageAnalysisScenario."Company Name"));
        ImageAnalysisScenario.Status := true;
        ImageAnalysisScenario.Insert(true);
    end;

    procedure GetNewFromPictureActionVisible(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        [SecurityFiltering(SecurityFilter::Ignored)]
        Item: Record Item;
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::Web, ClientType::Phone, ClientType::Tablet]) then
            exit(false);

        if not Item.WritePermission() or not Item.ReadPermission()
        or not ItemAttributeValueMapping.WritePermission() or not ItemAttributeValueMapping.ReadPermission() then
            exit(false);

        exit(true);
    end;

    procedure ImportFile(var ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary): Boolean
    var
        FileName: Text;
        ImageInStream: InStream;
        UploadResult: Boolean;
    begin
        UploadResult := UploadIntoStream(
            UploadDialogCaptionTxt,
            '',
            StrSubstNo(ImageFileFilterExtensionsTxt, ImageFileFilterLbl),
            FileName,
            ImageInStream);

        if (FileName = '') or (UploadResult = false) then
            exit(false);

        ItemFromPictureBuffer.ItemMediaSet.ImportStream(ImageInStream, StrSubstNo(TempItemMediaTxt, FileName));
        ItemFromPictureBuffer.ItemMediaFileName := CopyStr(FileName, 1, MaxStrLen(ItemFromPictureBuffer.ItemMediaFileName));

        exit(true);
    end;

    procedure CleanTenantMediaSet(MediaSetId: Guid)
    var
        TenantMediaSet: Record "Tenant Media Set";
        [SecurityFiltering(SecurityFilter::Ignored)]
        TenantMediaSet2: Record "Tenant Media Set";
        TenantMedia: Record "Tenant Media";
        [SecurityFiltering(SecurityFilter::Ignored)]
        TenantMedia2: Record "Tenant Media";
    begin
        // The Tenant Media was inserted in the database; manually clear it.
        if not TenantMediaSet2.WritePermission() or not TenantMediaSet.ReadPermission()
            or not TenantMedia2.WritePermission() or not TenantMedia.ReadPermission() then
            exit;

        TenantMediaSet.SetRange(ID, MediaSetId);
        if TenantMediaSet.FindSet() then
            repeat
                if TenantMedia.Get(TenantMediaSet."Media ID".MediaId()) then
                    if TenantMedia.Delete() then;
            until TenantMediaSet.Next() = 0;

        TenantMediaSet.DeleteAll();
    end;

    procedure GetFirstMediaFromMediaSet(MediaSetId: Guid): Guid
    var
        TenantMediaSet: Record "Tenant Media Set";
    begin
        TenantMediaSet.SetRange(ID, MediaSetId);
        if TenantMediaSet.FindFirst() then
            exit(TenantMediaSet."Media ID".MediaId);
    end;

    procedure ItemFromImage()
    var
        UnusedAction: Action;
    begin
        PromptOnHttpCallsIfSandbox();
        Commit();
        UnusedAction := Page.RunModal(Page::"Item From Picture");
    end;

    procedure GenerateItemDescription(ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary): Text[100]
    var
        ItemCategory: Record "Item Category";
        CategoryDisplayName: Text;
        CandidateText: Text;
    begin
        if ItemFromPictureBuffer.ItemDescription <> '' then
            exit(ItemFromPictureBuffer.ItemDescription);

        if (ItemFromPictureBuffer.ItemCategoryCode = '') or not (ItemCategory.Get(ItemFromPictureBuffer.ItemCategoryCode)) then
            exit(CopyStr(StrSubstNo(ItemDescriptionFileTxt, ItemFromPictureBuffer.ItemMediaFileName), 1, 100));

        if ItemCategory.Get(ItemFromPictureBuffer.ItemCategoryCode) then
            CategoryDisplayName := ItemCategory.Description
        else
            CategoryDisplayName := ItemFromPictureBuffer.ItemCategoryCode;

        CandidateText := StrSubstNo(ItemDescriptionCategoryFileTxt, CategoryDisplayName, ItemFromPictureBuffer.ItemMediaFileName);

        if StrLen(CandidateText) > 100 then
            CandidateText := StrSubstNo(ItemDescriptionCategoryTxt, CategoryDisplayName);

        exit(CopyStr(CandidateText, 1, 100));
    end;

    procedure AnalyzeImage(MediaId: Guid; var ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary; ImageAnalysisTypes: List of [Enum "Image Analysis Type"]; var NotificationBuffer: List of [Notification])
    var
        TempAzureAIUsage: Record "Azure AI Usage" temporary;
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        LastError: Text;
        UsageLimitError: Boolean;
        BestItemCategoryCode: Code[20];
        BestItemTemplateCode: Code[20];
        LimitValue: Integer;
        LimitType: Option;
    begin
        Session.LogMessage('0000JYR', StrSubstNo(ImageAnalysisStartedTelemetryTxt, ImageAnalysisManagement.ToCommaSeparatedList(ImageAnalysisTypes)), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());

        ImageAnalysisManagement.Initialize(Enum::"Image Analysis Provider"::"v3.2");
        ImageAnalysisManagement.SetMedia(MediaId);
        if not ImageAnalysisManagement.Analyze(ImageAnalysisResult, ImageAnalysisTypes) then begin
            Session.LogMessage('0000JYS', ImageAnalysisFailedTelemetryTxt, Verbosity::Warning,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());

            ImageAnalysisManagement.GetLastError(LastError, UsageLimitError);
            NotificationBuffer.Add(CreateErrorNotification(StrSubstNo(AnalysisNotPerformedMsg, LastError)));
            exit;
        end;

        BestItemCategoryCode := IdentifyBestItemCategory(ImageAnalysisResult);
        if BestItemCategoryCode <> '' then
            ItemFromPictureBuffer.Validate(ItemCategoryCode, BestItemCategoryCode);

        BestItemTemplateCode := IdentifyTemplateFromCategory(BestItemCategoryCode);
        if BestItemTemplateCode <> '' then
            ItemFromPictureBuffer.Validate(ItemTemplateCode, BestItemTemplateCode);

        ImageAnalysisManagement.GetLimitParams(LimitType, LimitValue);
        if ImageAnalysisSetup.IsUsageLimitReached(LastError, LimitValue, LimitType) then begin
            TempAzureAIUsage."Limit Period" := LimitType; // Get the right caption
            NotificationBuffer.Add(CreateErrorNotification(StrSubstNo(LimitReachedMsg, LimitValue, TempAzureAIUsage."Limit Period")));
        end;

        ItemFromPictureBuffer.SetResult(ImageAnalysisResult.GetResultVerbatim());

        Session.LogMessage('0000JYT',
            StrSubstNo(ImageAnalysisCompleteTelemetryTxt, ItemFromPictureBuffer.ItemCategoryCode <> '', ItemFromPictureBuffer.ItemTemplateCode <> '', ImageAnalysisSetup.IsUsageLimitReached(LastError, LimitValue, LimitType)),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    procedure IdentifyTemplateFromCategory(CategoryCode: Code[20]): Code[20]
    var
        ItemTempl: Record "Item Templ.";
    begin
        if CategoryCode <> '' then begin
            ItemTempl.SetRange("Item Category Code", CategoryCode);
            if ItemTempl.FindFirst() then
                exit(ItemTempl.Code);
        end;

        ItemTempl.Reset();
        if ItemTempl.FindFirst() then
            exit(ItemTempl.Code);

        exit('');
    end;

    local procedure IdentifyBestItemCategory(ImageAnalysisResult: Codeunit "Image Analysis Result"): Code[20]
    var
        BestItemCategory: Record "Item Category";
        TagIndex: Integer;
        FoundExactMatch: Boolean;
        FoundPartialMatch: Boolean;
        BestItemCategoryConfidence: Decimal;
    begin
        for TagIndex := 1 to ImageAnalysisResult.TagCount() do
            IdentifyBetterItemCategory(ImageAnalysisResult.TagName(TagIndex),
                ImageAnalysisResult.TagConfidence(TagIndex),
                FoundExactMatch,
                FoundPartialMatch,
                BestItemCategory,
                BestItemCategoryConfidence);

        exit(BestItemCategory.Code);
    end;

    local procedure IdentifyBetterItemCategory(TagName: Text; ItemConfidence: Decimal; var CurrentBestCategoryIsExactMatch: Boolean; var CurrentBestCategoryIsPartialMatch: Boolean; var CurrentBestItemCategory: Record "Item Category"; var CurrentBestCategoryConfidence: Decimal)
    var
        ItemCategory: Record "Item Category";
        ItemCategoryManagement: Codeunit "Item Category Management";
    begin
        if ItemConfidence <= 0.5 then
            exit;

        if ItemCategoryManagement.FindMatchInCategories(TagName, ItemCategory, true) then
            if (not CurrentBestCategoryIsExactMatch)
                    or (CurrentBestItemCategory.Indentation < ItemCategory.Indentation)
                    or ((CurrentBestItemCategory.Indentation = ItemCategory.Indentation) and (CurrentBestCategoryConfidence < ItemConfidence)) then begin
                CurrentBestItemCategory := ItemCategory;
                CurrentBestCategoryConfidence := ItemConfidence;
                CurrentBestCategoryIsExactMatch := true;
            end;

        if not CurrentBestCategoryIsExactMatch then
            if ItemCategoryManagement.FindMatchInCategories(TagName, ItemCategory, false) then
                if (not CurrentBestCategoryIsPartialMatch)
                        or (CurrentBestItemCategory.Indentation < ItemCategory.Indentation)
                        or ((CurrentBestItemCategory.Indentation = ItemCategory.Indentation) and (CurrentBestCategoryConfidence < ItemConfidence)) then begin
                    CurrentBestItemCategory := ItemCategory;
                    CurrentBestCategoryConfidence := ItemConfidence;
                    CurrentBestCategoryIsPartialMatch := true;
                end;
    end;

    local procedure CreateErrorNotification(NotificationMessage: Text): Notification
    var
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := ImageAnalysisErrorNotificationIdTxt;
        NotificationToSend.Message := NotificationMessage;
        NotificationToSend.Scope := NotificationScope::LocalScope;

        exit(NotificationToSend)
    end;

    procedure CanRunImageAnalysis(AnalysisTypes: List of [Enum "Image Analysis Type"]): Boolean
    var
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
    begin
        ImageAnalysisManagement.Initialize(Enum::"Image Analysis Provider"::"v3.2");

        if not ImageAnalysisManagement.IsCurrentUserLanguageSupported(AnalysisTypes) then
            exit(false);

        exit(true);
    end;

    procedure ApprovePrivacyNotice(): Boolean
    var
        NotificationBuffer: List of [Notification];
    begin
        exit(ApprovePrivacyNotice(NotificationBuffer));
    end;

    procedure ClearAttributeValues(var ItemAttributeValueSelection: Record "Item Attribute Value Selection" temporary)
    var
        ItemAttribute: Record "Item Attribute";
    begin
        if ItemAttributeValueSelection.FindSet() then
            repeat
                if ItemAttribute.Get(ItemAttributeValueSelection."Attribute ID") then
                    ItemAttribute.RemoveUnusedArbitraryValues();
            until ItemAttributeValueSelection.Next() = 0;
    end;

    procedure SaveAttributeValues(var ItemAttributeValueSelection: Record "Item Attribute Value Selection" temporary; Item: Record Item)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        Session.LogMessage('0000K00', StrSubstNo(SavingAttributesTelemetryTxt, ItemAttributeValueSelection.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());

        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        ItemAttributeValueMapping.DeleteAll();
        ItemAttributeValueMapping.Reset();

        if ItemAttributeValueSelection.FindSet() then
            repeat
                if ItemAttributeValueSelection.FindAttributeValue(ItemAttributeValue) then begin
                    ItemAttributeValueMapping.Init();
                    ItemAttributeValueMapping."Table ID" := DATABASE::Item;
                    ItemAttributeValueMapping."No." := Item."No.";
                    ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeValue."Attribute ID";
                    ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
                    ItemAttributeValueMapping.Insert();
                end;
            until ItemAttributeValueSelection.Next() = 0;
    end;

    procedure ApprovePrivacyNotice(var NotificationBuffer: List of [Notification]): Boolean
    var
        ImageAnalysisScenario: Record "Image Analysis Scenario";
        MyNotifications: Record "My Notifications";
        EnableNotification: Notification;
    begin
        if ImageAnalysisScenario.Enabled(ItemFromPictureScenarioTxt) then
            exit(true);

        if MyNotifications.IsEnabled(ImageAnalysisDisabledNotificationIdTxt) then begin
            EnableNotification.Id := ImageAnalysisDisabledNotificationIdTxt;
            EnableNotification.Scope := NotificationScope::LocalScope;

            if ImageAnalysisScenario.WritePermission then begin
                EnableNotification.Message := ImageAnalysisDisabledAdminTxt;
                EnableNotification.AddAction(ImageAnalysisDisabledActionTxt, Codeunit::"Item From Picture", 'RunWizard');
            end else
                EnableNotification.Message := ImageAnalysisDisabledNotAdminTxt;

            EnableNotification.AddAction(NotificationDontShowActionTxt, Codeunit::"Item From Picture", 'DisableNotification');
            NotificationBuffer.Add(EnableNotification);
        end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState();
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(ImageAnalysisDisabledNotificationIdTxt, ImageAnalysisNotificationNameTxt, ImageAnalysisNotificationDescriptionTxt, true);
    end;

    procedure DisableNotification(HostNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
        NotificationId: Guid;
    begin
        NotificationId := HostNotification.Id;
        if MyNotifications.Get(UserId(), NotificationId) then
            MyNotifications.Disable(NotificationId)
        else
            MyNotifications.InsertDefault(NotificationId, ImageAnalysisNotificationNameTxt, ImageAnalysisNotificationDescriptionTxt, false);
    end;

    procedure RunWizard(Notification: Notification)
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        ImageAnalysisSetup2: Record "Image Analysis Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        ItemFromPictureWizard: Page "Item From Picture Wizard";
        PageImageAnalysisSetup: Page "Image Analysis Setup";
    begin
        ItemFromPictureWizard.RunModal();

        if not ImageAnalysisSetup2.WritePermission() then
            exit;

        ImageAnalysisSetup.GetSingleInstance();
        if EnvironmentInformation.IsOnPrem() then
            if (ImageAnalysisSetup."Api Uri" = '') or (ImageAnalysisSetup.GetApiKeyAsSecret().IsEmpty()) then
                PageImageAnalysisSetup.Run();
    end;

    procedure GetItemFromPictureScenario(): Code[20]
    begin
        exit(ItemFromPictureScenarioTxt);
    end;

    internal procedure GetTelemetryCategory(): Text
    begin
        exit(ItemFromPictureTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Image Analysis Scenario", 'OnGetKnownScenarios', '', false, false)]
    local procedure OnGetKnownScenariosAddItemFromPicture(var Scenarios: List of [Code[20]])
    begin
        Scenarios.Add(ItemFromPictureScenarioTxt);
    end;

    local procedure PromptOnHttpCallsIfSandbox()
    var
        NavAppSettings: Record "NAV App Setting";
        [SecurityFiltering(SecurityFilter::Ignored)]
        NavAppSettings2: Record "NAV App Setting";
        EnvironmentInformation: Codeunit "Environment Information";
        BaseAppSettingsExist: Boolean;
        SystemAppSettingsExist: Boolean;
        ShowFailedMessage: Boolean;
        CurrentModuleInfo: ModuleInfo;
    begin
        if not EnvironmentInformation.IsSandbox() then
            exit;

        if not NavAppSettings2.WritePermission() then
            exit;

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);

        BaseAppSettingsExist := NavAppSettings.Get(CurrentModuleInfo.Id());
        SystemAppSettingsExist := NavAppSettings.Get(SystemApplicationAppIdTxt);

        if BaseAppSettingsExist and SystemAppSettingsExist then
            exit; // Choices have already been made

        if Confirm(EnableHttpCallsQst, false, CurrentModuleInfo.Publisher) then begin
            if not BaseAppSettingsExist then begin
                NavAppSettings."App ID" := CurrentModuleInfo.Id();
                NavAppSettings."Allow HttpClient Requests" := true;
                ShowFailedMessage := ShowFailedMessage or not NavAppSettings.Insert(true);
            end;

            if not SystemAppSettingsExist then begin
                NavAppSettings."App ID" := SystemApplicationAppIdTxt;
                NavAppSettings."Allow HttpClient Requests" := true;
                ShowFailedMessage := ShowFailedMessage or not NavAppSettings.Insert(true);
            end;

            if ShowFailedMessage then
                Message(CouldNotEnableHttpCallsMsg);
        end;
    end;
}
