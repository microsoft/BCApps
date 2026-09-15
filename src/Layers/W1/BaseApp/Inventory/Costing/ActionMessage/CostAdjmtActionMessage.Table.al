// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;

table 5842 "Cost Adjmt. Action Message"
{
    Caption = 'Cost Adjustment Action Message';
    DataClassification = SystemMetadata;
    InherentPermissions = RIMDX;
    InherentEntitlements = RIMDX;
    LookupPageId = "Cost Adjmt. Action Messages";
    Access = Internal;
    Extensible = false;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry assigned by the auto-increment process.';
        }
        field(2; Type; Enum "Cost Adjmt. Action Msg. Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the cost adjustment action message.';
        }
        field(3; Message; Text[250])
        {
            Caption = 'Message';
            ToolTip = 'Specifies the message text of the cost adjustment action message.';
        }
        field(4; "Next Check Date/Time"; DateTime)
        {
            Caption = 'Next Check Date/Time';
            ToolTip = 'Specifies the date and time when the next check of the cost adjustment action message is scheduled.';
        }
        field(5; Importance; Integer)
        {
            Caption = 'Importance';
            ToolTip = 'Specifies the importance of the cost adjustment action message.';
        }
        field(9; "Table Id"; Integer)
        {
            Caption = 'Table ID';
            ToolTip = 'Specifies the table ID of the record related to the action message.';
        }
        field(10; "System ID"; Guid)
        {
            Caption = 'System ID';
            ToolTip = 'Specifies the unique identifier of the record related to the action message.';
        }
        field(20; Active; Boolean)
        {
            Caption = 'Active';
            ToolTip = 'Specifies if the cost adjustment action message is active or not.';
        }
        field(100; "Custom Dimensions"; Text[2048])
        {
            Caption = 'Custom Dimensions';
            ToolTip = 'Specifies the custom dimensions of the cost adjustment action message that contains additional information.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Type, "Table Id", "Next Check Date/Time")
        {
        }
    }

    internal procedure Navigate()
    var
        InventorySetup: Record "Inventory Setup";
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        Item: Record Item;
    begin
        case Rec.Type of
            "Cost Adjmt. Action Msg. Type"::"Cost Adjustment Not Running":
                begin
                    InventorySetup.Get();
                    Page.Run(0, InventorySetup, InventorySetup.FieldNo("Automatic Cost Adjustment"));
                end;
            "Cost Adjmt. Action Msg. Type"::"Cost Adjustment Running Long":
                begin
                    CostAdjustmentDetailedLog.FindLast();
                    CostAdjustmentDetailedLog.SetRange("Cost Adjustment Run Guid", CostAdjustmentDetailedLog."Cost Adjustment Run Guid");
                    CostAdjustmentDetailedLog.SetFilter(Duration, '>%1', 5 * 60 * 1000);
                    Page.Run(0, CostAdjustmentDetailedLog);
                end;
            "Cost Adjmt. Action Msg. Type"::"Suboptimal Avg. Cost Settings":
                begin
                    InventorySetup.Get();
                    Page.Run(0, InventorySetup, InventorySetup.FieldNo("Average Cost Period"));
                end;
            "Cost Adjmt. Action Msg. Type"::"Inventory Periods Unused":
                Page.Run(Page::"Inventory Periods");
            "Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Entry Points":
                begin
                    AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
                    Page.Run(0, AvgCostAdjmtEntryPoint, AvgCostAdjmtEntryPoint.FieldNo("Cost Is Adjusted"));
                end;
            "Cost Adjmt. Action Msg. Type"::"Many Non-Adjusted Orders":
                begin
                    InventoryAdjmtEntryOrder.SetRange("Cost Is Adjusted", false);
                    Page.Run(0, InventoryAdjmtEntryOrder, InventoryAdjmtEntryOrder.FieldNo("Cost Is Adjusted"));
                end;
            "Cost Adjmt. Action Msg. Type"::"Item Excluded from Cost Adjustment":
                begin
                    Item.SetRange("Excluded from Cost Adjustment", true);
                    Page.Run(0, Item);
                end;
            else
                OnOtherCostAdjmtActionMsgTypeNavigate(Rec);
        end;
    end;

    [InternalEvent(false)]
    local procedure OnOtherCostAdjmtActionMsgTypeNavigate(CostAdjmtActionMessage: Record "Cost Adjmt. Action Message")
    begin
    end;
}