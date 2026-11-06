// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using System;
using System.Apps;
using System.Globalization;
using System.Reflection;
using System.Security.User;
using System.Xml;

codeunit 1485 "Rolecenter Selector Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ActionContainerXmlElementLbl: Label 'ActionContainers', Locked = true;
        ActionContainerTypeAttrLbl: Label 'ActionContainerType', Locked = true;
        ActivityButtonsLbl: Label 'ActivityButtons', Locked = true;
        JsonNameElementLbl: Label 'name', Locked = true;
        TooltipAttrLbl: Label 'ToolTipML', Locked = true;
        CaptionAttrLbl: Label 'CaptionML', Locked = true;
        JsonRowElementLbl: Label 'rows', Locked = true;
        JsonTooltipLbl: Label 'tooltip', Locked = true;
        PromotedAttrLbl: Label 'Promoted', Locked = true;
        ActionCaptionTxt: Label 'Continue';
        ActionDescriptionTxt: Label 'Choose a Role Center that suits your business role, and then choose the Continue button. You can change the Role Center any time.';
        DropdownLbl: Label 'My Role Center';
        JsonHeaderLbl: Label 'HeaderLabel', Locked = true;
        JsonDropdownContentLbl: Label 'DropContent', Locked = true;
        JsonProfileNameLbl: Label 'Name', Locked = true;
        JsonProfileDescriptionLbl: Label 'Description', Locked = true;
        JsonRolecenterIdLbl: Label 'RolecenterId', Locked = true;
        JsonDefaultActionLbl: Label 'DefaultActionLabel', Locked = true;
        JsonDisclaimerTextLbl: Label 'DisclaimerText', Locked = true;
        JsonActionDescriptionLbl: Label 'ActionDescription', Locked = true;
        DisclaimerTxt: Label 'Note that this view merely shows you the breadth of functionality in the selected Role Center. What you will actually see depends on your company and personal UI settings.';
        DefaultLangaugeCodeTxt: Label 'ENU', Locked = true;
        LanguageCodeRegExPatternTxt: Label '[A-Z]{3}=', Locked = true;
        LanguageCodePatternTxt: Label '%1=', Locked = true;

    [Scope('OnPrem')]
    procedure BuildJsonFromPageMetadata(RolecenterId: Integer): Text
    var
        AllObj: Record AllObj;
        ApplicationObjectMetadata: Record "Application Object Metadata";
        XMLDOMManagement: Codeunit "XML DOM Management";
        ReturnXmlDocument: DotNet XmlDocument;
        ReturnedXMLNodeList: DotNet XmlNodeList;
        ActivityButtonsXmlNode: DotNet XmlNode;
        BucketXmlNode: DotNet XmlNode;
        FeatureXmlNode: DotNet XmlNode;
        FeatureBucketsJArray: JsonArray;
        FeatureBucketJObject: JsonObject;
        FeatureJArray: JsonArray;
        FeatureJObject: JsonObject;
        Instream: InStream;
        JsonText: Text;
        Tooltip: Text;
        Caption: Text;
    begin
        AllObj.Get(AllObj."Object Type"::Page, RolecenterId);
        ApplicationObjectMetadata.Get(AllObj."App Runtime Package ID", ApplicationObjectMetadata."Object Type"::Page, RolecenterId);
        ApplicationObjectMetadata.CalcFields(Metadata);
        ApplicationObjectMetadata.Metadata.CreateInStream(Instream);

        XMLDOMManagement.LoadXMLDocumentFromInStream(Instream, ReturnXmlDocument);
        ReturnedXMLNodeList := ReturnXmlDocument.GetElementsByTagName(ActionContainerXmlElementLbl);

        if not GetActivityButtonsActionContainerXmlNode(ActivityButtonsXmlNode, ReturnedXMLNodeList) then begin
            FeatureBucketsJArray.WriteTo(JsonText);
            exit(JsonText);
        end;

        foreach BucketXmlNode in ActivityButtonsXmlNode.ChildNodes do begin
            Clear(FeatureBucketJObject);
            GetLanguageSpecificCaptionAndTooltip(BucketXmlNode, Caption, Tooltip);
            FeatureBucketJObject.Add(JsonNameElementLbl, Caption);
            FeatureBucketJObject.Add(JsonTooltipLbl, Tooltip);

            Clear(FeatureJArray);
            foreach FeatureXmlNode in BucketXmlNode.ChildNodes do
                if IsNodePromoted(FeatureXmlNode) then begin
                    Clear(FeatureJObject);
                    GetLanguageSpecificCaptionAndTooltip(FeatureXmlNode, Caption, Tooltip);
                    FeatureJObject.Add(JsonNameElementLbl, Caption);
                    FeatureJObject.Add(JsonTooltipLbl, Tooltip);
                    FeatureJArray.Add(FeatureJObject);
                end;

            if FeatureJArray.Count() > 0 then begin
                FeatureBucketJObject.Add(JsonRowElementLbl, FeatureJArray);
                FeatureBucketsJArray.Add(FeatureBucketJObject);
            end;
        end;

        FeatureBucketsJArray.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure BuildJsonFromPageActionTable(RolecenterId: Integer): Text
    var
        PageAction: Record "Page Action";
        BucketPageAction: Record "Page Action";
        FeaturePageAction: Record "Page Action";
        FeatureBucketsJArray: JsonArray;
        FeatureBucketJObject: JsonObject;
        FeatureJArray: JsonArray;
        FeatureJObject: JsonObject;
        JsonText: Text;
    begin
        PageAction.SetRange("Page ID", RolecenterId);
        PageAction.SetRange("Action Type", PageAction."Action Type"::ActionContainer);
        PageAction.SetRange("Action Subtype", PageAction."Action Subtype"::ActivityButtons);
        if not PageAction.FindFirst() then begin
            FeatureBucketsJArray.WriteTo(JsonText);
            exit(JsonText);
        end;

        BucketPageAction.SetRange("Page ID", RolecenterId);
        BucketPageAction.SetRange("Parent Action ID", PageAction."Action ID");
        BucketPageAction.SetRange("Action Type", BucketPageAction."Action Type"::ActionGroup);
        BucketPageAction.SetRange(Indentation, 1);
        if BucketPageAction.FindSet() then
            repeat
                Clear(FeatureBucketJObject);
                FeatureBucketJObject.Add(JsonNameElementLbl, BucketPageAction.Caption);
                FeatureBucketJObject.Add(JsonTooltipLbl,
                  BucketPageAction.ToolTip1 + BucketPageAction.ToolTip2 + BucketPageAction.ToolTip3 + BucketPageAction.ToolTip4);

                Clear(FeatureJArray);
                FeaturePageAction.SetRange("Page ID", RolecenterId);
                FeaturePageAction.SetRange("Parent Action ID", BucketPageAction."Action ID");
                FeaturePageAction.SetRange("Action Type", FeaturePageAction."Action Type"::Action);
                FeaturePageAction.SetRange(Indentation, 2);
                FeaturePageAction.SetRange(Promoted, true);

                if FeaturePageAction.FindSet() then
                    repeat
                        Clear(FeatureJObject);
                        FeatureJObject.Add(JsonNameElementLbl, FeaturePageAction.Caption);
                        FeatureJObject.Add(JsonTooltipLbl,
                          FeaturePageAction.ToolTip1 + FeaturePageAction.ToolTip2 + FeaturePageAction.ToolTip3 + FeaturePageAction.ToolTip4);
                        FeatureJArray.Add(FeatureJObject);
                    until FeaturePageAction.Next() = 0;

                if FeatureJArray.Count() > 0 then begin
                    FeatureBucketJObject.Add(JsonRowElementLbl, FeatureJArray);
                    FeatureBucketsJArray.Add(FeatureBucketJObject);
                end;
            until BucketPageAction.Next() = 0;

        FeatureBucketsJArray.WriteTo(JsonText);
        exit(JsonText);
    end;

    procedure BuildPageDataJsonForRolecenterSelector(): Text
    var
        AllProfile: Record "All Profile";
        PageDataJObject: JsonObject;
        ProfileJArray: JsonArray;
        ProfileJObject: JsonObject;
        JsonText: Text;
    begin
        PageDataJObject.Add(JsonHeaderLbl, DropdownLbl);
        PageDataJObject.Add(JsonDefaultActionLbl, ActionCaptionTxt);
        PageDataJObject.Add(JsonDisclaimerTextLbl, DisclaimerTxt);
        PageDataJObject.Add(JsonActionDescriptionLbl, ActionDescriptionTxt);

        AllProfile.SetRange(Enabled, true);
        if AllProfile.FindSet() then
            repeat
                Clear(ProfileJObject);
                ProfileJObject.Add(JsonProfileNameLbl, Format(AllProfile.RecordId));
                ProfileJObject.Add(JsonProfileDescriptionLbl, AllProfile.Description);
                ProfileJObject.Add(JsonRolecenterIdLbl, AllProfile."Role Center ID");
                ProfileJArray.Add(ProfileJObject);
            until AllProfile.Next() = 0;

        PageDataJObject.Add(JsonDropdownContentLbl, ProfileJArray);

        PageDataJObject.WriteTo(JsonText);
        exit(JsonText);
    end;

    [Scope('OnPrem')]
    procedure IsRolecenterSelectorEnabled(UserName: Code[50]): Boolean
    begin
        exit(false);
    end;

    local procedure GetActivityButtonsActionContainerXmlNode(var ActivityButtonsXmlNode: DotNet XmlNode; ActionContainerXmlNodeList: DotNet XmlNodeList): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        if IsNull(ActionContainerXmlNodeList) then
            exit(false);

        foreach ActivityButtonsXmlNode in ActionContainerXmlNodeList do
            if XMLDOMManagement.GetAttributeValue(ActivityButtonsXmlNode, ActionContainerTypeAttrLbl) = ActivityButtonsLbl then
                exit(true);

        exit(false);
    end;

    local procedure IsNodePromoted(FeatureXmlNode: DotNet XmlNode): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        exit(XMLDOMManagement.GetAttributeValue(FeatureXmlNode, PromotedAttrLbl) = '1');
    end;

    local procedure GetLanguageSpecificCaptionAndTooltip(XmlNode: DotNet XmlNode; var Caption: Text; var Tooltip: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        Caption := '';
        Tooltip := '';

        Caption := GetLanguageSpecificText(GlobalLanguage, XMLDOMManagement.GetAttributeValue(XmlNode, CaptionAttrLbl));
        Tooltip := GetLanguageSpecificText(GlobalLanguage, XMLDOMManagement.GetAttributeValue(XmlNode, TooltipAttrLbl));
        if Tooltip = '' then
            Tooltip := Caption;
    end;

    local procedure GetLanguageSpecificText(LanguageID: Integer; InputMLText: Text) ReturnText: Text
    var
        Language: Codeunit Language;
        RegEx: DotNet Regex;
        RegExMatch: DotNet Match;
        RegExMatchs: DotNet MatchCollection;
        Dictionary: DotNet GenericDictionary2;
        PrevMatch: DotNet Match;
        HtmlUtility: DotNet HttpUtility;
        LanguageCode: Text;
    begin
        LanguageCode := Language.GetLanguageCode(LanguageID);

        if LanguageCode = '' then
            LanguageCode := DefaultLangaugeCodeTxt;

        Dictionary := Dictionary.Dictionary();
        RegExMatchs := RegEx.Matches(InputMLText, StrSubstNo(LanguageCodeRegExPatternTxt));

        foreach RegExMatch in RegExMatchs do begin
            if not IsNull(PrevMatch) then
                Dictionary.Add(
                  PrevMatch.Value,
                  CopyStr(InputMLText, PrevMatch.Index + PrevMatch.Length + 1, RegExMatch.Index - (PrevMatch.Index + PrevMatch.Length) - 1));
            PrevMatch := RegExMatch;
        end;

        if not IsNull(PrevMatch) then
            Dictionary.Add(
              PrevMatch.Value,
              CopyStr(InputMLText, PrevMatch.Index + PrevMatch.Length + 1, StrLen(InputMLText) - (PrevMatch.Index + PrevMatch.Length)));

        if not Dictionary.TryGetValue(StrSubstNo(LanguageCodePatternTxt, LanguageCode), ReturnText) then
            if LanguageCode <> DefaultLangaugeCodeTxt then
                if not Dictionary.TryGetValue(StrSubstNo(LanguageCodePatternTxt, DefaultLangaugeCodeTxt), ReturnText) then
                    exit;

        ReturnText := HtmlUtility.HtmlDecode(ReturnText);
        if StrPos(ReturnText, '"') <> 0 then
            ReturnText := CopyStr(ReturnText, 2, StrLen(ReturnText) - 2);
    end;

    procedure GetShowStateFromUserPreference(UserName: Code[50]) RoleCenterSelectorIsEnabled: Boolean
    var
        UserPreference: Record "User Preference";
    begin
        if not UserPreference.Get(UserName, GetUserPreferenceCode()) then
            exit(false);

        UserPreference.CalcFields("User Selection");

        if not Evaluate(RoleCenterSelectorIsEnabled, UserPreference.GetUserSelectionAsText()) then
            exit(false);
    end;

    procedure SetShowStateFromUserPreference(UserName: Code[50]; State: Boolean)
    var
        UserPreference: Record "User Preference";
    begin
        if UserPreference.Get(UserName, GetUserPreferenceCode()) then begin
            UserPreference.SetUserSelection(State);
            UserPreference.Modify();
            exit;
        end;

        UserPreference.Init();
        UserPreference."User ID" := UserName;
        UserPreference."Instruction Code" := GetUserPreferenceCode();
        UserPreference.SetUserSelection(State);
        UserPreference.Insert();
    end;

    procedure GetUserPreferenceCode(): Code[50]
    begin
        exit(UpperCase('RoleCenterOverviewShowState'));
    end;
}
