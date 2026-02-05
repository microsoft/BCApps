// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

page 99001507 "Subc. Temp Routing Lines"
{
    ApplicationArea = Manufacturing;
    Caption = 'Temporary Routing Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Routing Line";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Operation No."; Rec."Operation No.")
                {
                    ToolTip = 'Specifies the operation number for this routing line.';
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the type of operation.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the work center or machine center.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the operation.';
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the setup time of the operation.';
                }
                field("Run Time"; Rec."Run Time")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the run time of the operation.';
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the wait time after processing.';
                }
                field("Move Time"; Rec."Move Time")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the move time.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ToolTip = 'Specifies the routing link code.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ToolTip = 'Specifies the work center number.';
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Routing No." := xRec."Routing No.";
        Rec."Version Code" := xRec."Version Code";
        if Rec."Version Code" = '' then
            Rec."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
    end;

    procedure SetTemporaryRecords(var TempRoutingLine: Record "Routing Line" temporary)
    begin
        Rec.Copy(TempRoutingLine, true);
    end;

    var
        SubcManagementSetup: Record "Subc. Management Setup";
}
