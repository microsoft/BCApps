// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Apps;

codeunit 1994 "Guided Experience Item Cleanup"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Description = 'The Codeunit is only public because we need the OnRun trigger for Job Queue (BaseApp), all procedures are internal or local';
    Permissions =
        tabledata "Published Application" = r,
        tabledata "Guided Experience Item" = rd;

    trigger OnRun()
    begin
        CleanupOldGuidedExperienceItems(false, 100);
    end;

    internal procedure CleanupOldGuidedExperienceItems(OnlyFirstParty: Boolean; Threshold: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceItem2: Record "Guided Experience Item";
        PublishedApplication: Record "Published Application";
        FirstPartyPublisherFilterString: Text;
        ItemsToCleanUp: List of [Code[300]];
        ItemCode: Code[300];
    begin
        GuidedExperienceItem.ReadIsolation := IsolationLevel::ReadUncommitted;
        GuidedExperienceItem2.ReadIsolation := IsolationLevel::ReadUncommitted;
        GuidedExperienceItem.SetLoadFields(Code, Version, "Extension ID");
        GuidedExperienceItem2.SetLoadFields(Code, Version);

        if OnlyFirstParty then begin
            PublishedApplication.SetRange(Publisher, 'Microsoft');
            FirstPartyPublisherFilterString := '';

            if PublishedApplication.FindSet() then
                repeat
                    if FirstPartyPublisherFilterString = '' then
                        FirstPartyPublisherFilterString := PublishedApplication.ID
                    else
                        FirstPartyPublisherFilterString += '|' + PublishedApplication.ID;
                until PublishedApplication.Next() = 0;

            GuidedExperienceItem.SetFilter("Extension ID", FirstPartyPublisherFilterString);
        end;

        if GuidedExperienceItem.FindSet() then
            repeat
                GuidedExperienceItem2.SetRange(Code, GuidedExperienceItem.Code);

                if GuidedExperienceItem2.Count() > Threshold then
                    if not ItemsToCleanUp.Contains(GuidedExperienceItem.Code) then
                        ItemsToCleanUp.Add(GuidedExperienceItem.Code);
            until GuidedExperienceItem.Next() = 0;

        foreach ItemCode in ItemsToCleanUp do
            DeleteDuplicatedGuidedExperienceItems(ItemCode);
    end;

    internal procedure DeleteDuplicatedGuidedExperienceItems(ItemCode: Code[300])
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        Batch, MaxVersion, i : Integer;
    begin
        // 1k records per batch
        Batch := 1000;
        MaxVersion := FindMaxVersionForGuidedExperienceItem(ItemCode);

        if Batch > MaxVersion then
            i := MaxVersion - 1
        else
            i := Batch;

        GuidedExperienceItem.SetRange(Code, ItemCode);

        while i < MaxVersion do begin
            GuidedExperienceItem.SetRange(Version, 0, i);
            GuidedExperienceItem.DeleteAll(false);
            i += Batch;

            // Commit is needed because the operation could timeout and we want to save the progress
            Commit();
        end;

        GuidedExperienceItem.SetRange(Version, 0, MaxVersion - 1);
        GuidedExperienceItem.DeleteAll(false);
    end;

    local procedure FindMaxVersionForGuidedExperienceItem(ItemCode: Code[300]): Integer
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        GuidedExperienceItem.SetLoadFields(Code, Version);
        GuidedExperienceItem.SetRange(Code, ItemCode);
        GuidedExperienceItem.SetCurrentKey(Version);

        GuidedExperienceItem.FindLast();

        exit(GuidedExperienceItem.Version);
    end;

    internal procedure GetDuplicatedGuidedExperienceItems(var TempGuidedExperienceItem: Record "Guided Experience Item" temporary; Threshold: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ItemsToCleanUp: List of [Code[300]];
        ItemCode: Code[300];
    begin
        GuidedExperienceItem.SetLoadFields(Code, Version);
        GuidedExperienceItem.SetFilter(Version, '>=%1', Threshold);

        if GuidedExperienceItem.FindSet() then
            repeat
                if not ItemsToCleanUp.Contains(GuidedExperienceItem.Code) then
                    ItemsToCleanUp.Add(GuidedExperienceItem.Code);
            until GuidedExperienceItem.Next() = 0;

        GuidedExperienceItem.Reset();
        GuidedExperienceItem.SetLoadFields(Code, Version);

        foreach ItemCode in ItemsToCleanUp do begin
            GuidedExperienceItem.SetRange(Code, ItemCode);
            if GuidedExperienceItem.Count() > Threshold then begin
                TempGuidedExperienceItem.Init();
                TempGuidedExperienceItem.Validate(Code, ItemCode);
                TempGuidedExperienceItem.Insert();
            end;
        end;
    end;
}