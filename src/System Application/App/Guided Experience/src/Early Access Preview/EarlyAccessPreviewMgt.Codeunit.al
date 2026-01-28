// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

codeunit 1965 "Early Access Preview Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure LoadNewFeatures(var GuidedExperienceItem: Record "Guided Experience Item")
    var
        FeatureDataJson: JsonArray;
        FeatureToken: JsonToken;
        FeatureObject: JsonObject;
        FeatureText: Text;
        InStr: InStream;
        FeatureNo: Integer;
    begin
        GuidedExperienceItem.Reset();
        GuidedExperienceItem.DeleteAll();
        FeatureNo := 0;

        // Load JSON from resource file
        NavApp.GetResource('EarlyAccessPreviewFeatures.json', InStr, TextEncoding::UTF8);
        InStr.Read(FeatureText);

        // Parse JSON array
        if FeatureDataJson.ReadFrom(FeatureText) then begin
            foreach FeatureToken in FeatureDataJson do
                if FeatureToken.IsObject() then begin
                    FeatureObject := FeatureToken.AsObject();
                    GuidedExperienceItem.Init();

                    FeatureNo += 1;
                    GuidedExperienceItem.Code := Format(FeatureNo);

                    if FeatureObject.Get('FeatureName', FeatureToken) then
                        GuidedExperienceItem.Title := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem.Title));

                    if FeatureObject.Get('Description', FeatureToken) then
                        GuidedExperienceItem.Description := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem.Description));

                    if FeatureObject.Get('Category', FeatureToken) then
                        GuidedExperienceItem.Keywords := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem.Keywords));

                    if FeatureObject.Get('HelpURL', FeatureToken) then
                        GuidedExperienceItem."Help URL" := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem."Help URL"));

                    if FeatureObject.Get('VideoURL', FeatureToken) then
                        GuidedExperienceItem."Video URL" := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem."Video URL"));

                    GuidedExperienceItem.Insert();
                end;
            GuidedExperienceItem.FindFirst();
        end;

    end;
}
