// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Wizard;
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
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        RoutingLink: Record "Routing Link";
    begin
        // Create Work Center for subcontracting
        SubCreateProdOrdWizLibrary.CreateAndCalculateNeededWorkCenter(WorkCenter, true);

        LibraryInventory.CreateItem(Item);

        // Create routing link for purchase provisioning
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;

        ManufacturingSetup."Def. Wiz. Work Center No." := WorkCenter."No.";
        ManufacturingSetup."Rtng. Link Code Purch. Prov." := RoutingLink."Code";
        ManufacturingSetup."Def. Wiz. Flushing method" := "Flushing Method Routing"::Backward;
        ManufacturingSetup."Def. Wiz. Comp Item No." := Item."No.";

        // Set all Select fields to Edit as default
        ManufacturingSetup."Show Rtng BOM Select Nothing" := ManufacturingSetup."Show Rtng BOM Select Nothing"::Edit;
        ManufacturingSetup."Show Rtng BOM Select Partial" := ManufacturingSetup."Show Rtng BOM Select Partial"::Edit;
        ManufacturingSetup."Show Rtng BOM Select Both" := ManufacturingSetup."Show Rtng BOM Select Both"::Edit;
        ManufacturingSetup."Show Prod Comp Select Nothing" := ManufacturingSetup."Show Prod Comp Select Nothing"::Edit;
        ManufacturingSetup."Show Prod Comp Select Partial" := ManufacturingSetup."Show Prod Comp Select Partial"::Edit;
        ManufacturingSetup."Show Prod Comp Select Both" := ManufacturingSetup."Show Prod Comp Select Both"::Edit;

        ManufacturingSetup."Rtng. Link Code Purch. Prov." := RoutingLink."Code";
        ManufacturingSetup."Subc. Default Comp. Location" := ManufacturingSetup."Subc. Default Comp. Location"::Purchase;
        ManufacturingSetup.Modify();
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

    procedure ConfigureSubManagementForNothingPresentScenario(ShowRtngBOMSelect: Enum "Prod. Definition Display"; ShowProdRtngCompSelect: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();

        // Configure for NothingPresent scenario
        ManufacturingSetup."Show Rtng BOM Select Nothing" := ShowRtngBOMSelect;
        ManufacturingSetup."Show Prod Comp Select Nothing" := ShowProdRtngCompSelect;

        ManufacturingSetup.Modify();
    end;

    procedure ConfigureSubManagementForPartiallyPresentScenario(ShowRtngBOMSelect: Enum "Prod. Definition Display"; ShowProdRtngCompSelect: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();

        // Configure for PartiallyPresent scenario
        ManufacturingSetup."Show Rtng BOM Select Partial" := ShowRtngBOMSelect;
        ManufacturingSetup."Show Prod Comp Select Partial" := ShowProdRtngCompSelect;

        ManufacturingSetup.Modify();
    end;

    procedure ConfigureSubManagementForBothPresentScenario(ShowRtngBOMSelect: Enum "Prod. Definition Display"; ShowProdRtngCompSelect: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();

        // Configure for BothPresent scenario
        ManufacturingSetup."Show Rtng BOM Select Both" := ShowRtngBOMSelect;
        ManufacturingSetup."Show Prod Comp Select Both" := ShowProdRtngCompSelect;

        ManufacturingSetup.Modify();
    end;
}