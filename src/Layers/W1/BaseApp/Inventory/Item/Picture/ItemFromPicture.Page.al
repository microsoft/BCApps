// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

using Microsoft.Inventory.Item;
using System.AI;
using System.Environment.Configuration;

page 7498 "Item From Picture"
{
    PageType = Card;
    ApplicationArea = Basic, Suite;
    DataCaptionExpression = '';
    Caption = 'Create Item From Picture';
    SourceTable = "Item From Picture Buffer";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            field(MainPicture; Rec.ItemMediaSet)
            {
                ApplicationArea = Basic, Suite;
                ShowCaption = false;
                ToolTip = 'Specifies the media set for the new item.';
                Editable = false;
            }
            group(ItemSetupGroup)
            {
                ShowCaption = false;

                field(CategoryCode; Rec.ItemCategoryCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category';
                    ToolTip = 'Specifies the item category for the new item.';
                    TableRelation = "Item Category";

                    trigger OnValidate()
                    var
                        CandidateTemplate: Code[20];
                    begin
                        LoadAttributesFromCategory();

                        if Rec.ItemCategoryCode = '' then
                            exit;

                        if Rec.ItemTemplateCode = '' then
                            CandidateTemplate := ItemFromPicture.IdentifyTemplateFromCategory(Rec.ItemCategoryCode);

                        if CandidateTemplate <> '' then
                            Rec.Validate(ItemTemplateCode, CandidateTemplate);
                    end;
                }
                field(TemplateCode; Rec.ItemTemplateCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Template to apply';
                    ToolTip = 'Specifies the template to apply to the new item.';
                    TableRelation = "Item Templ.";

                    trigger OnValidate()
                    var
                        ItemTempl: Record "Item Templ.";
                    begin
                        if Rec.ItemTemplateCode = '' then
                            exit;

                        ItemTempl.Get(Rec.ItemTemplateCode);

                        if (ItemTempl."Item Category Code" = '') or (ItemTempl."Item Category Code" = Rec.ItemCategoryCode) then
                            exit;

                        Rec.ItemCategoryCode := ItemTempl."Item Category Code";
                        LoadAttributesFromCategory();
                    end;
                }
            }
            part(Attributes; "Item From Picture-Attrib Part")
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        ProgressDialog: Dialog;
        ShouldUseImageAnalysis: Boolean;
        RecIsNew: Boolean;
    begin
        ShouldUseImageAnalysis := ItemFromPicture.CanRunImageAnalysis(GetImageAnalysisTypes());

        if ShouldUseImageAnalysis then
            ShouldUseImageAnalysis := ItemFromPicture.ApprovePrivacyNotice(NotificationBuffer);

        Session.LogMessage('0000JYQ', StrSubstNo(ItemFromPictureStartedTelemetryTxt, ShouldUseImageAnalysis), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ItemFromPicture.GetTelemetryCategory());

        if Rec.IsEmpty() then begin
            Rec.Init();
            if not ItemFromPicture.ImportFile(Rec) then
                Error('');

            RecIsNew := true;
        end;

        if ShouldUseImageAnalysis then begin
            ProgressDialog.Open(AnalyzingPictureProgressTxt);
            ItemFromPicture.AnalyzeImage(ItemFromPicture.GetFirstMediaFromMediaSet(Rec.ItemMediaSet.MediaId), Rec, GetImageAnalysisTypes(), NotificationBuffer);
            ProgressDialog.Close();
        end;

        if RecIsNew then
            Rec.Insert()
        else
            Rec.Modify();
    end;

    trigger OnAfterGetCurrRecord()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        NotificationToSend: Notification;
    begin
        LoadAttributesFromCategory();

        ImageAnalysisSetup.GetSingleInstance();

        foreach NotificationToSend in NotificationBuffer do
            NotificationLifecycleMgt.SendNotification(NotificationToSend, ImageAnalysisSetup.RecordId());

        Clear(NotificationBuffer);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::LookupCancel, Action::Cancel] then
            ClearMediaAndAttributes()
        else
            SaveItemAndAttributes();

        exit(true);
    end;

    var
        ItemFromPicture: Codeunit "Item From Picture";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        TemplateFailedOptionsTxt: Label 'Create item without template, Discard item', Comment = 'Comma separated list of options';
        TemplateFailedQuestionTxt: Label 'We could not apply the item template. Contact your partner to fix this issue.\\ Do you want to create the item without applying the template?';
        AnalyzingPictureProgressTxt: Label 'Analyzing your picture...';
        ItemFromPictureStartedTelemetryTxt: Label 'Item from picture started. Image analysis enabled: %1.', Locked = true;
        NotificationBuffer: List of [Notification];

    local procedure LoadAttributesFromCategory()
    begin
        CurrPage.Attributes.Page.LoadAttributesFromCategory(Rec.ItemCategoryCode);
    end;

    local procedure SaveItemAndAttributes()
    var
        Item: Record Item;
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        IsHandled: Boolean;
        ItemCreated: Boolean;
    begin
        if Rec.ItemTemplateCode <> '' then begin
            ItemCreated := ItemTemplMgt.CreateItemFromTemplate(item, IsHandled, Rec.ItemTemplateCode);
            if not IsHandled or not ItemCreated then
                // This happens only in case of partner code interfering
                case StrMenu(TemplateFailedOptionsTxt, 1, TemplateFailedQuestionTxt) of
                    0: // Cancel
                        Error('');
                    1: // Create without template
                        IsHandled := false;
                    2: // Discard
                        exit;
                end;
        end;

        if not IsHandled then begin
            Item.Init();
            Item.Insert(true);
        end;

        if Rec.ItemCategoryCode <> '' then
            Item.Validate("Item Category Code", Rec.ItemCategoryCode);
        Item.Validate(Description, ItemFromPicture.GenerateItemDescription(Rec));
        Item.Picture := Rec.ItemMediaSet;

        Item.Modify();

        CurrPage.Attributes.Page.SaveValues(Item);

        Page.Run(Page::"Item Card", Item);
    end;

    local procedure ClearMediaAndAttributes()
    begin
        ItemFromPicture.CleanTenantMediaSet(Rec.ItemMediaSet.MediaId());

        CurrPage.Attributes.Page.ClearValues();
    end;

    local procedure GetImageAnalysisTypes() ImageAnalysisTypes: List of [Enum "Image Analysis Type"]
    begin
        ImageAnalysisTypes.Add(Enum::"Image Analysis Type"::Tags);
    end;
}
