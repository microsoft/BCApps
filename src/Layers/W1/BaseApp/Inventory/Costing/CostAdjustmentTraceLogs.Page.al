// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

page 5810 "Cost Adjustment Trace Logs"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Cost Adjustment Trace Log";
    Caption = 'Cost Adjustment Trace Logs';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Visible = false;
                }
                field("Cost Adjustment Run Guid"; Rec."Cost Adjustment Run Guid")
                {
                    Caption = 'Cost Adjustment Run Guid';
                    Visible = false;
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                    ToolTip = 'Specifies the date and time when the cost adjustment trace log entry was created.';
                }
                field("Event Name"; Rec."Event Name")
                {
                    Caption = 'Event Name';
                }
                field("Item Cost Source/Recipient"; Rec."Item Cost Source/Recipient")
                {
                    Caption = 'Cost Source/Recipient';
                }
                field("Traced Table ID"; Rec."Traced Table ID")
                {
                    Caption = 'Traced Table ID';
                }
                field("Traced Entry No."; Rec."Traced Entry No.")
                {
                    Caption = 'Traced Entry No.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownEntryNo();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field("Valuation Date"; Rec."Valuation Date")
                {
                    Caption = 'Valuation Date';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field("Order Type"; Rec."Order Type")
                {
                    Caption = 'Order Type';
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    Caption = 'Order Line No.';
                    BlankZero = true;
                }
                field("Custom Dimensions"; Rec."Custom Dimensions")
                {
                    Caption = 'Custom Dimensions';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearLog)
            {
                Caption = 'Clear Log';
                Image = Delete;
                ToolTip = 'Clear the log entries.';

                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.DeleteAll();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ClearLog_Promoted; ClearLog) { }
        }
    }
}