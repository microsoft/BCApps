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
        FeatureText: Text;
        InStr: InStream;
    begin
        NavApp.GetResource('EarlyAccessPreviewFeatures.json', InStr, TextEncoding::UTF8);
        InStr.Read(FeatureText);
        FeatureDataJson.ReadFrom(FeatureText);
        LoadNewFeatures(GuidedExperienceItem, FeatureDataJson);
    end;

    procedure LoadNewFeatures(var GuidedExperienceItem: Record "Guided Experience Item"; FeatureDataJson: JsonArray)
    var
        FeatureToken: JsonToken;
        FeatureObject: JsonObject;
        FeatureNo: Integer;
    begin
        GuidedExperienceItem.Reset();
        GuidedExperienceItem.DeleteAll();
        Clear(GuidedExperienceItem);
        Clear(ReleaseVersions);
        Clear(Overviews);
        Clear(GettingStartedGuides);

        foreach FeatureToken in FeatureDataJson do begin
            FeatureNo += 1;
            if not FeatureToken.IsObject() then
                Error(InvalidFeatureErr, FeatureNo);

            FeatureObject := FeatureToken.AsObject();
            GuidedExperienceItem.Init();
            GuidedExperienceItem.Code := Format(FeatureNo);

            if FeatureObject.Get('FeatureName', FeatureToken) then
                GuidedExperienceItem.Title := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem.Title));

            if FeatureObject.Get('Description', FeatureToken) then begin
                Overviews.Add(GuidedExperienceItem.Code, FeatureToken.AsValue().AsText());
                GuidedExperienceItem.Description := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem.Description));
            end;

            if FeatureObject.Get('Category', FeatureToken) then
                GuidedExperienceItem.Keywords := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem.Keywords));

            if FeatureObject.Get('HelpURL', FeatureToken) then
                GuidedExperienceItem."Help URL" := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem."Help URL"));

            if FeatureObject.Get('VideoURL', FeatureToken) then
                GuidedExperienceItem."Video URL" := CopyStr(FeatureToken.AsValue().AsText(), 1, MaxStrLen(GuidedExperienceItem."Video URL"));

            LoadFeatureMetadata(FeatureObject, GuidedExperienceItem.Code, FeatureNo);
            GuidedExperienceItem.Insert();
        end;

        if not GuidedExperienceItem.IsEmpty() then
            GuidedExperienceItem.FindFirst();
    end;

    procedure GetReleaseVersion(FeatureCode: Code[300]) ReleaseVersion: Text
    begin
        if ReleaseVersions.Get(FeatureCode, ReleaseVersion) then;
    end;

    procedure GetFeatureDetails(FeatureCode: Code[300]; var Overview: Text; var GettingStarted: Text)
    begin
        Clear(Overview);
        Clear(GettingStarted);
        if Overviews.Get(FeatureCode, Overview) then;
        if GettingStartedGuides.Get(FeatureCode, GettingStarted) then;
    end;

    local procedure LoadFeatureMetadata(FeatureObject: JsonObject; FeatureCode: Code[300]; FeatureNo: Integer)
    var
        MetadataToken: JsonToken;
        StepToken: JsonToken;
        Steps: JsonArray;
        GettingStarted: TextBuilder;
        ReleaseVersion: Text;
        ReleasePart: Text;
        ReleaseParts: List of [Text];
        StepNo: Integer;
    begin
        if FeatureObject.Get('ReleaseVersion', MetadataToken) then begin
            ReleaseVersion := ReadMetadataText(MetadataToken, 'ReleaseVersion', FeatureNo);
            if ReleaseVersion <> '' then begin
                ReleaseParts := ReleaseVersion.Split('.');
                if ReleaseParts.Count() <> 2 then
                    Error(InvalidReleaseVersionErr, FeatureNo);
                foreach ReleasePart in ReleaseParts do
                    if (ReleasePart = '') or (DelChr(ReleasePart, '=', '0123456789') <> '') then
                        Error(InvalidReleaseVersionErr, FeatureNo);
            end;
            ReleaseVersions.Add(FeatureCode, ReleaseVersion);
        end;

        if FeatureObject.Get('GettingStartedSteps', MetadataToken) then begin
            if not MetadataToken.IsArray() then
                Error(InvalidStepsErr, FeatureNo);
            Steps := MetadataToken.AsArray();
            foreach StepToken in Steps do begin
                StepNo += 1;
                if StepNo > 1 then begin
                    GettingStarted.AppendLine();
                    GettingStarted.AppendLine();
                end;
                GettingStarted.Append(Format(StepNo, 0, 9));
                GettingStarted.Append('. ');
                GettingStarted.Append(ReadMetadataText(StepToken, 'GettingStartedSteps', FeatureNo));
            end;
            GettingStartedGuides.Add(FeatureCode, GettingStarted.ToText());
        end;
    end;

    local procedure ReadMetadataText(Token: JsonToken; PropertyName: Text; FeatureNo: Integer): Text
    var
        SerializedValue: Text;
    begin
        // AsText also converts other JSON scalars; require a string in the catalog.
        Token.WriteTo(SerializedValue);
        if CopyStr(SerializedValue, 1, 1) <> '"' then
            Error(InvalidTextErr, PropertyName, FeatureNo);
        exit(Token.AsValue().AsText());
    end;

    var
        ReleaseVersions: Dictionary of [Code[300], Text];
        Overviews: Dictionary of [Code[300], Text];
        GettingStartedGuides: Dictionary of [Code[300], Text];
        InvalidFeatureErr: Label 'Early access preview feature %1 must be a JSON object.', Comment = '%1 = feature position in the catalog';
        InvalidTextErr: Label 'The %1 value for early access preview feature %2 must be a JSON string.', Comment = '%1 = JSON property name, %2 = feature position in the catalog';
        InvalidReleaseVersionErr: Label 'The release version for early access preview feature %1 must use the major.minor format, for example 30.0.', Comment = '%1 = feature position in the catalog';
        InvalidStepsErr: Label 'The getting started steps for early access preview feature %1 must be a JSON array of strings.', Comment = '%1 = feature position in the catalog';
}
