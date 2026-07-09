// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Manufacturing;

using Microsoft.DemoData.Common;
using Microsoft.DemoData.Finance;
using Microsoft.DemoTool.Helpers;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Setup;

codeunit 5152 "Create Mfg Item Template"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        FinanceModuleSetup: Record "Finance Module Setup";
        ContosoInventory: Codeunit "Contoso Inventory";
        CreateCommonUnitOfMeasure: Codeunit "Create Common Unit Of Measure";
        CreateCommonPostingGroup: Codeunit "Create Common Posting Group";
        CreateMfgPostingGroup: Codeunit "Create Mfg Posting Group";
    begin
        FinanceModuleSetup.Get();

        ContosoInventory.InsertItemTemplateData(Produced(), ProducedLbl, CreateCommonUnitOfMeasure.Piece(), Enum::"Item Type"::Inventory, CreateMfgPostingGroup.Finished(), CreateCommonPostingGroup.Retail(), FinanceModuleSetup."VAT Prod. Post Grp. Standard", Enum::"Reserve Method"::Optional, Enum::"Costing Method"::Standard, Enum::"Replenishment System"::"Prod. Order", Enum::"Manufacturing Policy"::"Make-to-Order", Enum::"Flushing Method"::Manual, Enum::"Reordering Policy"::"Lot-for-Lot", true, TimeBucketTok, 10);
    end;

    procedure Produced(): Code[20]
    begin
        exit(ProducedTok);
    end;

    var
        ProducedTok: Label 'PRODUCED', MaxLength = 20;
        ProducedLbl: Label 'Produced', MaxLength = 100;
        TimeBucketTok: Label '<1W>', Locked = true;
}
