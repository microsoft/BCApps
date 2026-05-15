// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
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
        ManufacturingSetup2: Record "Manufacturing Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center for subcontracting
        SubCreateProdOrdWizLibrary.CreateAndCalculateNeededWorkCenter(WorkCenter, true);

        // Create routing link for purchase provisioning
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        if not ManufacturingSetup2.Get() then begin
            ManufacturingSetup2.Init();
            ManufacturingSetup2.Insert();
        end;

        LibraryInventory.CreateItem(Item);

        // Set required fields for production order creation
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;

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
}