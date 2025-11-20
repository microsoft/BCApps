// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.StandardCost;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.StandardCost;
using Microsoft.Projects.Resources.Resource;

table 5841 "Standard Cost Worksheet"
{
    Caption = 'Standard Cost Worksheet';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Standard Cost Worksheet Name"; Code[10])
        {
            Caption = 'Standard Cost Worksheet Name';
            TableRelation = "Standard Cost Worksheet Name";
        }
        field(3; Type; Enum "Standard Cost Source Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    Validate("No.", '');
            end;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource;

            trigger OnValidate()
            var
                TempStdCostWksh: Record "Standard Cost Worksheet" temporary;
            begin
                TempStdCostWksh := Rec;
                Init();
                Type := TempStdCostWksh.Type;
                "No." := TempStdCostWksh."No.";
                "Replenishment System" := "Replenishment System"::" ";

                if "No." = '' then
                    exit;

                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            Description := Item.Description;
                            "Replenishment System" := Item."Replenishment System";
                            GetItemCosts();
                        end;
                    Type::Resource:
                        begin
                            Res.Get("No.");
                            Description := Res.Name;
                            GetResourceCosts();
                        end;
                end;
            end;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Implemented; Boolean)
        {
            Caption = 'Implemented';
            Editable = false;
        }
        field(7; "Replenishment System"; Enum "Replenishment System")
        {
            Caption = 'Replenishment System';
            Editable = false;
        }
        field(11; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Standard Cost';
            Editable = false;
            MinValue = 0;
        }
        field(12; "New Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Standard Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                if Type = Type::Item then
                    UpdateCostShares();
            end;
        }
        field(13; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(14; "New Indirect Cost %"; Decimal)
        {
            Caption = 'New Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(15; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(16; "New Overhead Rate"; Decimal)
        {
            Caption = 'New Overhead Rate';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                if Type = Type::Resource then
                    TestField("New Overhead Rate", 0);
            end;
        }
        field(21; "Single-Lvl Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Lvl Material Cost';
            Editable = false;
        }
        field(22; "New Single-Lvl Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Single-Lvl Material Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(23; "Single-Lvl Cap. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Lvl Cap. Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(24; "New Single-Lvl Cap. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Single-Lvl Cap. Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; "Single-Lvl Subcontrd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Lvl Subcontrd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(26; "New Single-Lvl Subcontrd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Single-Lvl Subcontrd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(27; "Single-Lvl Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Lvl Cap. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(28; "New Single-Lvl Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Single-Lvl Cap. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(29; "Single-Lvl Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Single-Lvl Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(30; "New Single-Lvl Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Single-Lvl Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Material Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(42; "New Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Rolled-up Material Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(43; "Rolled-up Cap. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Cap. Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(44; "New Rolled-up Cap. Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Rolled-up Cap. Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(45; "Rolled-up Subcontrd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Subcontrd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(46; "New Rolled-up Subcontrd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Rolled-up Subcontrd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(47; "Rolled-up Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Cap. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(48; "New Rolled-up Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Rolled-up Cap. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(49; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50; "New Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'New Rolled-up Mfg. Ovhd Cost';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Standard Cost Worksheet Name", Type, "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        StdCostWkshName.Get("Standard Cost Worksheet Name");
    end;

    var
        Item: Record Item;
        Res: Record Resource;
        StdCostWkshName: Record "Standard Cost Worksheet Name";

    local procedure GetItemCosts()
    begin
        OnBeforeGetItemCosts(Rec, Item);

        "Standard Cost" := Item."Standard Cost";
        "New Standard Cost" := Item."Standard Cost";
        "Overhead Rate" := Item."Overhead Rate";
        "New Overhead Rate" := Item."Overhead Rate";
        "Indirect Cost %" := Item."Indirect Cost %";
        "New Indirect Cost %" := Item."Indirect Cost %";

        TransferStandardCostFromItem();

        OnAfterGetItemCosts(Rec, Item);
    end;

    local procedure GetResourceCosts()
    begin
        OnBeforeGetResourceCosts(Rec, Res);

        "Standard Cost" := Res."Unit Cost";
        "New Standard Cost" := Res."Unit Cost";
        "Overhead Rate" := 0;
        "New Overhead Rate" := 0;
        "Indirect Cost %" := Res."Indirect Cost %";
        "New Indirect Cost %" := Res."Indirect Cost %";
    end;

    local procedure UpdateCostShares()
    var
        Ratio: Decimal;
        RoundingResidual: Decimal;
    begin
        if xRec."New Standard Cost" <> 0 then
            Ratio := "New Standard Cost" / xRec."New Standard Cost";

        "New Single-Lvl Material Cost" := RoundAmt("New Single-Lvl Material Cost", Ratio);
        "New Single-Lvl Mfg. Ovhd Cost" := RoundAmt("New Single-Lvl Mfg. Ovhd Cost", Ratio);
        "New Single-Lvl Cap. Cost" := RoundAmt("New Single-Lvl Cap. Cost", Ratio);
        "New Single-Lvl Subcontrd Cost" := RoundAmt("New Single-Lvl Subcontrd Cost", Ratio);
        "New Single-Lvl Cap. Ovhd Cost" := RoundAmt("New Single-Lvl Cap. Ovhd Cost", Ratio);
        RoundingResidual := "New Standard Cost" -
          ("New Single-Lvl Material Cost" +
           "New Single-Lvl Mfg. Ovhd Cost" +
           "New Single-Lvl Cap. Cost" +
           "New Single-Lvl Subcontrd Cost" +
           "New Single-Lvl Cap. Ovhd Cost");
        "New Single-Lvl Material Cost" := "New Single-Lvl Material Cost" + RoundingResidual;

        "New Rolled-up Material Cost" := RoundAmt("New Rolled-up Material Cost", Ratio);
        "New Rolled-up Mfg. Ovhd Cost" := RoundAmt("New Rolled-up Mfg. Ovhd Cost", Ratio);
        "New Rolled-up Cap. Cost" := RoundAmt("New Rolled-up Cap. Cost", Ratio);
        "New Rolled-up Subcontrd Cost" := RoundAmt("New Rolled-up Subcontrd Cost", Ratio);
        "New Rolled-up Cap. Ovhd Cost" := RoundAmt("New Rolled-up Cap. Ovhd Cost", Ratio);
        RoundingResidual := "New Standard Cost" -
          ("New Rolled-up Material Cost" +
           "New Rolled-up Mfg. Ovhd Cost" +
           "New Rolled-up Cap. Cost" +
           "New Rolled-up Subcontrd Cost" +
           "New Rolled-up Cap. Ovhd Cost");
        "New Rolled-up Material Cost" := "New Rolled-up Material Cost" + RoundingResidual;

        OnAfterUpdateCostShares(Rec, Ratio);
    end;

    local procedure RoundAmt(Amt: Decimal; AmtAdjustFactor: Decimal): Decimal
    begin
        exit(Round(Amt * AmtAdjustFactor, 0.00001));
    end;

    local procedure TransferStandardCostFromItem()
    begin
        "Single-Lvl Material Cost" := Item."Standard Cost";
        "New Single-Lvl Material Cost" := Item."Standard Cost";
        "Single-Lvl Cap. Cost" := 0;
        "New Single-Lvl Cap. Cost" := 0;
        "Single-Lvl Subcontrd Cost" := 0;
        "New Single-Lvl Subcontrd Cost" := 0;
        "Single-Lvl Cap. Ovhd Cost" := 0;
        "New Single-Lvl Cap. Ovhd Cost" := 0;
        "Single-Lvl Mfg. Ovhd Cost" := 0;
        "New Single-Lvl Mfg. Ovhd Cost" := 0;

        "Rolled-up Material Cost" := Item."Standard Cost";
        "New Rolled-up Material Cost" := Item."Standard Cost";
        "Rolled-up Cap. Cost" := 0;
        "New Rolled-up Cap. Cost" := 0;
        "Rolled-up Subcontrd Cost" := 0;
        "New Rolled-up Subcontrd Cost" := 0;
        "Rolled-up Cap. Ovhd Cost" := 0;
        "New Rolled-up Cap. Ovhd Cost" := 0;
        "Rolled-up Mfg. Ovhd Cost" := 0;
        "New Rolled-up Mfg. Ovhd Cost" := 0;

        OnAfterTransferStandardCostFromItem(Rec, Item);
    end;

    procedure TransferManufCostsFromItem(var Item: Record Item)
    begin
        "Single-Lvl Material Cost" := Item."Single-Level Material Cost";
        "New Single-Lvl Material Cost" := Item."Single-Level Material Cost";
        "Single-Lvl Cap. Cost" := Item."Single-Level Capacity Cost";
        "New Single-Lvl Cap. Cost" := Item."Single-Level Capacity Cost";
        "Single-Lvl Subcontrd Cost" := Item."Single-Level Subcontrd. Cost";
        "New Single-Lvl Subcontrd Cost" := Item."Single-Level Subcontrd. Cost";
        "Single-Lvl Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
        "New Single-Lvl Cap. Ovhd Cost" := Item."Single-Level Cap. Ovhd Cost";
        "Single-Lvl Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";
        "New Single-Lvl Mfg. Ovhd Cost" := Item."Single-Level Mfg. Ovhd Cost";

        "Rolled-up Material Cost" := Item."Rolled-up Material Cost";
        "New Rolled-up Material Cost" := Item."Rolled-up Material Cost";
        "Rolled-up Cap. Cost" := Item."Rolled-up Capacity Cost";
        "New Rolled-up Cap. Cost" := Item."Rolled-up Capacity Cost";
        "Rolled-up Subcontrd Cost" := Item."Rolled-up Subcontracted Cost";
        "New Rolled-up Subcontrd Cost" := Item."Rolled-up Subcontracted Cost";
        "Rolled-up Cap. Ovhd Cost" := Item."Rolled-up Cap. Overhead Cost";
        "New Rolled-up Cap. Ovhd Cost" := Item."Rolled-up Cap. Overhead Cost";
        "Rolled-up Mfg. Ovhd Cost" := Item."Rolled-up Mfg. Ovhd Cost";
        "New Rolled-up Mfg. Ovhd Cost" := Item."Rolled-up Mfg. Ovhd Cost";

        OnAfterTransferManufCostsFromItem(Rec, Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferStandardCostFromItem(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferManufCostsFromItem(var StandardCostWorksheet: Record "Standard Cost Worksheet"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCostShares(var StandardCostWorksheet: Record "Standard Cost Worksheet"; Ratio: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetResourceCosts(var StandardCostWorksheet: Record "Standard Cost Worksheet"; var Resource: Record Resource)
    begin
    end;
}

