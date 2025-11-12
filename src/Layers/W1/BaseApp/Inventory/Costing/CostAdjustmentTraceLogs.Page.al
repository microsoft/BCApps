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
                    ToolTip = 'Specifies the entry number of the cost adjustment trace log entry.';
                    Visible = false;
                }
                field("Cost Adjustment Run Guid"; Rec."Cost Adjustment Run Guid")
                {
                    Caption = 'Cost Adjustment Run Guid';
                    ToolTip = 'Specifies the unique identifier of the cost adjustment run.';
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
                    ToolTip = 'Specifies the name of the event that is traced.';
                }
                field("Item Cost Source/Recipient"; Rec."Item Cost Source/Recipient")
                {
                    Caption = 'Cost Source/Recipient';
                    ToolTip = 'Specifies if the traced entry acts as a cost source or recipient.';
                }
                field("Traced Table ID"; Rec."Traced Table ID")
                {
                    Caption = 'Traced Table ID';
                    ToolTip = 'Specifies the table ID of the traced entry.';
                }
                field("Traced Entry No."; Rec."Traced Entry No.")
                {
                    Caption = 'Traced Entry No.';
                    ToolTip = 'Specifies the traced entry number.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownEntryNo();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the item number of the traced entry.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    ToolTip = 'Specifies the location code of the traced entry.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                    ToolTip = 'Specifies the variant code of the traced entry.';
                }
                field("Valuation Date"; Rec."Valuation Date")
                {
                    Caption = 'Valuation Date';
                    ToolTip = 'Specifies the valuation date of the traced entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the traced entry.';
                }
                field("Order Type"; Rec."Order Type")
                {
                    Caption = 'Order Type';
                    ToolTip = 'Specifies the order type of the traced entry.';
                }
                field("Order No."; Rec."Order No.")
                {
                    Caption = 'Order No.';
                    ToolTip = 'Specifies the order number of the traced entry.';
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    Caption = 'Order Line No.';
                    ToolTip = 'Specifies the order line number of the traced entry.';
                    BlankZero = true;
                }
                field("Custom Dimensions"; Rec."Custom Dimensions")
                {
                    Caption = 'Custom Dimensions';
                    ToolTip = 'Specifies additional information about the traced entry.';
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