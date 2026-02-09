// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;

codeunit 139988 "Subc. Setup Library"
{
    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";

    procedure InitSetupFields()
    var
        Item: Record Item;
        RoutingLink: Record "Routing Link";
        SubManagementSetup: Record "Subc. Management Setup";
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center for subcontracting
        SubCreateProdOrdWizLibrary.CreateAndCalculateNeededWorkCenter(WorkCenter, true);

        // Create routing link for purchase provisioning
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        if not SubManagementSetup.Get() then begin
            SubManagementSetup.Init();
            SubManagementSetup.Insert();
        end;

        LibraryInventory.CreateItem(Item);

        // Set required fields for production order creation
        SubManagementSetup."Common Work Center No." := WorkCenter."No.";
        SubManagementSetup."Rtng. Link Code Purch. Prov." := RoutingLink."Code";
        SubManagementSetup."Def. provision flushing method" := "Flushing Method Routing"::Backward;
        SubManagementSetup."Component at Location" := SubManagementSetup."Component at Location"::Purchase;
        SubManagementSetup."Preset Component Item No." := Item."No.";

        // Set all Select fields to Edit as default
        SubManagementSetup.ShowRtngBOMSelect_Nothing := SubManagementSetup.ShowRtngBOMSelect_Nothing::Edit;
        SubManagementSetup.ShowRtngBOMSelect_Partial := SubManagementSetup.ShowRtngBOMSelect_Partial::Edit;
        SubManagementSetup.ShowRtngBOMSelect_Both := SubManagementSetup.ShowRtngBOMSelect_Both::Edit;
        SubManagementSetup.ShowProdRtngCompSelect_Nothing := SubManagementSetup.ShowProdRtngCompSelect_Nothing::Edit;
        SubManagementSetup.ShowProdRtngCompSelect_Partial := SubManagementSetup.ShowProdRtngCompSelect_Partial::Edit;
        SubManagementSetup.ShowProdRtngCompSelect_Both := SubManagementSetup.ShowProdRtngCompSelect_Both::Edit;

        SubManagementSetup.Modify();
    end;

    procedure ConfigureSubManagementForNothingPresentScenario(ShowRtngBOMSelect: Enum "Subc. Show/Edit Type"; ShowProdRtngCompSelect: Enum "Subc. Show/Edit Type")
    var
        SubManagementSetup: Record "Subc. Management Setup";
    begin
        SubManagementSetup.Get();

        // Configure for NothingPresent scenario
        SubManagementSetup.ShowRtngBOMSelect_Nothing := ShowRtngBOMSelect;
        SubManagementSetup.ShowProdRtngCompSelect_Nothing := ShowProdRtngCompSelect;

        SubManagementSetup.Modify();
    end;

    procedure ConfigureSubManagementForPartiallyPresentScenario(ShowRtngBOMSelect: Enum "Subc. Show/Edit Type"; ShowProdRtngCompSelect: Enum "Subc. Show/Edit Type")
    var
        SubManagementSetup: Record "Subc. Management Setup";
    begin
        SubManagementSetup.Get();

        // Configure for PartiallyPresent scenario
        SubManagementSetup.ShowRtngBOMSelect_Partial := ShowRtngBOMSelect;
        SubManagementSetup.ShowProdRtngCompSelect_Partial := ShowProdRtngCompSelect;

        SubManagementSetup.Modify();
    end;

    procedure ConfigureSubManagementForBothPresentScenario(ShowRtngBOMSelect: Enum "Subc. Show/Edit Type"; ShowProdRtngCompSelect: Enum "Subc. Show/Edit Type")
    var
        SubManagementSetup: Record "Subc. Management Setup";
    begin
        SubManagementSetup.Get();

        // Configure for BothPresent scenario
        SubManagementSetup.ShowRtngBOMSelect_Both := ShowRtngBOMSelect;
        SubManagementSetup.ShowProdRtngCompSelect_Both := ShowProdRtngCompSelect;

        SubManagementSetup.Modify();
    end;

    internal procedure InitialSetupForGenProdPostingGroup()
    var
        GenProdPostingGroup1: Record Microsoft.Finance.GeneralLedger.Setup."Gen. Product Posting Group";
        GenProdPostingGroup2: Record Microsoft.Finance.GeneralLedger.Setup."Gen. Product Posting Group";
    begin
        // Assign Def. VAT Prod. Posting Group to a Gen. Prod. Posting Group based on W1.
        GenProdPostingGroup2.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        if not GenProdPostingGroup2.FindFirst() then
            exit; // All Gen. Prod. Posting Groups have Def. VAT Prod. Posting Group assigned.

        GenProdPostingGroup1.SetFilter("Def. VAT Prod. Posting Group", '');
        if GenProdPostingGroup1.FindSet(true) then
            repeat
                GenProdPostingGroup1."Def. VAT Prod. Posting Group" := GenProdPostingGroup2."Def. VAT Prod. Posting Group";
                GenProdPostingGroup1.Modify(true);
            until GenProdPostingGroup1.Next() = 0;
    end;
}