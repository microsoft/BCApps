// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Upgrade;
using System.Upgrade;

codeunit 7048 "Set Price Line Source Group"
{
    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupUpgradeTag()) then
            UpdatePriceListLineStatus()
        else
            UpdatePriceSourceGroupInPriceListLines();
        Message(CompletedTxt);
    end;

    var
        CompletedTxt: Label 'The task was successfully completed.';

    local procedure CommitAfter1KRecords(var Counter: Integer)
    begin
        Counter += 1;
        if Counter > 1000 then begin
            Counter := 0;
            Commit();
        end;
    end;

    local procedure UpdatePriceSourceGroupInPriceListLines()
    var
        PriceListLine: Record "Price List Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Counter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupFixedUpgradeTag()) then
            exit;

        PriceListLine.SetLoadFields("Source Group", "Source Type", "Price Type", Status);
        PriceListLine.SetRange("Source Group", PriceListLine."Source Group"::All);
        if PriceListLine.FindSet(true) then
            repeat
                if PriceListLine."Source Type" in
                    [PriceListLine."Source Type"::"All Jobs",
                    PriceListLine."Source Type"::Job,
                    PriceListLine."Source Type"::"Job Task"]
                then
                    PriceListLine."Source Group" := PriceListLine."Source Group"::Job
                else
                    case PriceListLine."Price Type" of
                        "Price Type"::Purchase:
                            PriceListLine."Source Group" := PriceListLine."Source Group"::Vendor;
                        "Price Type"::Sale:
                            PriceListLine."Source Group" := PriceListLine."Source Group"::Customer;
                    end;
                if PriceListLine."Source Group" <> PriceListLine."Source Group"::All then
                    if PriceListLine.Status = "Price Status"::Active then begin
                        PriceListLine.Status := "Price Status"::Draft;
                        PriceListLine.Modify();
                        PriceListLine.Status := "Price Status"::Active;
                        PriceListLine.Modify();
                    end else
                        PriceListLine.Modify();
                CommitAfter1KRecords(Counter);
            until PriceListLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetPriceSourceGroupFixedUpgradeTag());
    end;

    local procedure UpdatePriceListLineStatus()
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Status: Enum "Price Status";
        Counter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSyncPriceListLineStatusUpgradeTag()) then
            exit;

        PriceListLine.SetLoadFields("Price List Code", Status);
        PriceListLine.SetRange(Status, "Price Status"::Draft);
        if PriceListLine.Findset(true) then
            repeat
                if PriceListHeader.Code <> PriceListLine."Price List Code" then
                    if PriceListHeader.Get(PriceListLine."Price List Code") then
                        Status := PriceListHeader.Status
                    else
                        Status := Status::Draft;
                if Status = Status::Active then begin
                    PriceListLine.Status := Status::Active;
                    PriceListLine.Modify();
                    CommitAfter1KRecords(Counter);
                end;
            until PriceListLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSyncPriceListLineStatusUpgradeTag());
    end;
}