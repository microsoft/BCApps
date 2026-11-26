// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Manufacturing.WorkCenter;

codeunit 137421 "Prod. Def. Wiz. Setup Lib."
{
    var
        LibraryERM: Codeunit "Library - ERM";
        ProdDefWizLibrary: Codeunit "Prod. Def. Wiz. Library";
        LibraryInventory: Codeunit "Library - Inventory";

    procedure InitializeBasicSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        if ManufacturingSetup."Production BOM Nos." = '' then begin
            ManufacturingSetup.Validate("Production BOM Nos.", LibraryERM.CreateNoSeriesCode());
            ManufacturingSetup.Modify(true);
        end;
        if ManufacturingSetup."Routing Nos." = '' then begin
            ManufacturingSetup.Validate("Routing Nos.", LibraryERM.CreateNoSeriesCode());
            ManufacturingSetup.Modify(true);
        end;
        if ManufacturingSetup."Def. Wiz. Work Center No." = '' then
            CreateDefaultWorkCenterAndSetInSetup();
        if ManufacturingSetup."Def. Wiz. Comp Item No." = '' then
            CreateDefaultComponentItemAndSetInSetup();
    end;

    procedure SetBOMRoutingDisplayForBothAvailable(Display: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Rtng BOM Select Both", Display);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetBOMRoutingDisplayForPartiallyAvailable(Display: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Rtng BOM Select Partial", Display);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetBOMRoutingDisplayForNothingAvailable(Display: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Rtng BOM Select Nothing", Display);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetProdCompDisplayForBothAvailable(Display: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Prod Comp Select Both", Display);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetProdCompDisplayForPartiallyAvailable(Display: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Prod Comp Select Partial", Display);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetProdCompDisplayForNothingAvailable(Display: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Prod Comp Select Nothing", Display);
        ManufacturingSetup.Modify(true);
    end;

    procedure ConfigureForBothAvailable(BOMRtngDisplay: Enum "Prod. Definition Display"; ProdCompDisplay: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Rtng BOM Select Both", BOMRtngDisplay);
        ManufacturingSetup.Validate("Show Prod Comp Select Both", ProdCompDisplay);
        ManufacturingSetup.Modify(true);
    end;

    procedure ConfigureForPartiallyAvailable(BOMRtngDisplay: Enum "Prod. Definition Display"; ProdCompDisplay: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Rtng BOM Select Partial", BOMRtngDisplay);
        ManufacturingSetup.Validate("Show Prod Comp Select Partial", ProdCompDisplay);
        ManufacturingSetup.Modify(true);
    end;

    procedure ConfigureForNothingAvailable(BOMRtngDisplay: Enum "Prod. Definition Display"; ProdCompDisplay: Enum "Prod. Definition Display")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Show Rtng BOM Select Nothing", BOMRtngDisplay);
        ManufacturingSetup.Validate("Show Prod Comp Select Nothing", ProdCompDisplay);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetAllowEditUISelection(Allow: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Allow Edit UI Selection", Allow);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetAlwaysSaveModifiedVersions(AlwaysSave: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Always Save Modified Versions", AlwaysSave);
        ManufacturingSetup.Modify(true);
    end;

    procedure GetAlwaysSaveModifiedVersions(): Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        exit(ManufacturingSetup."Always Save Modified Versions");
    end;

    procedure SetDefWizFlushingMethod(FlushingMethod: Enum "Flushing Method")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Def. Wiz. Flushing Method", FlushingMethod);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetDefaultWorkCenter(WorkCenterNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Def. Wiz. Work Center No.", WorkCenterNo);
        ManufacturingSetup.Modify(true);
    end;

    procedure SetDefaultComponentItem(ItemNo: Code[20])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Def. Wiz. Comp Item No.", ItemNo);
        ManufacturingSetup.Modify(true);
    end;

    procedure CreateDefaultWorkCenterAndSetInSetup(): Code[20]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
    begin
        ProdDefWizLibrary.CreateAndCalculateWorkCenter(WorkCenter);
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Def. Wiz. Work Center No.", WorkCenter."No.");
        ManufacturingSetup.Modify(true);
        exit(WorkCenter."No.");
    end;

    procedure CreateDefaultComponentItemAndSetInSetup(): Code[20]
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        LibraryInventory.CreateItem(Item);
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Def. Wiz. Comp Item No.", Item."No.");
        ManufacturingSetup.Modify(true);
        exit(Item."No.");
    end;
}