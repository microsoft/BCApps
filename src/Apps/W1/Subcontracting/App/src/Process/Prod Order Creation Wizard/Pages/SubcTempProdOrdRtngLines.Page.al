// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

page 99001509 "Subc. TempProdOrdRtngLines"
{
    ApplicationArea = Manufacturing;
    Caption = 'Temporary Prod. Order Routing Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Prod. Order Routing Line";
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
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ToolTip = 'Specifies the flushing method for the operation.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ToolTip = 'Specifies the work center number.';
                }
                field("Input Quantity"; Rec."Input Quantity")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the input quantity for the operation.';
                }
                field("Expected Operation Cost Amt."; Rec."Expected Operation Cost Amt.")
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the expected operation cost amount.';
                }
                field("Vendor No. Subc. Price"; Rec."Vendor No. Subc. Price")
                {
                    ToolTip = 'Specifies the vendor number for subcontracting prices.';
                }
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Prod. Order No." := xRec."Prod. Order No.";
        Rec."Routing Reference No." := xRec."Routing Reference No.";
        Rec."Routing No." := xRec."Routing No.";
        Rec.Status := xRec.Status;
        Rec."Vendor No. Subc. Price" := xRec."Vendor No. Subc. Price";

        if PresetSubValues then begin
            GetSubManagementSetup();
            Rec."Routing Link Code" := SubcManagementSetup."Rtng. Link Code Purch. Prov.";
            Rec."Flushing Method" := SubcManagementSetup."Def. provision flushing method";
        end;
    end;

    protected var
        LinesChanged: Boolean;

    var
        SubcManagementSetup: Record "Subc. Management Setup";
        PresetSubValues: Boolean;
        SubManagementSetupRead: Boolean;

    trigger OnModifyRecord(): Boolean
    begin
        LinesChanged := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        LinesChanged := true;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        LinesChanged := true;
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    procedure GetLinesChanged(): Boolean
    begin
        exit(LinesChanged);
    end;

    procedure SetTemporaryRecords(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
        Rec.Copy(TempProdOrderRoutingLine, true);
        if Rec.FindFirst() then;
    end;

    procedure SetPresetSubValues(Preset: Boolean)
    begin
        PresetSubValues := Preset;
    end;

    local procedure GetSubManagementSetup()
    begin
        if not SubManagementSetupRead then begin
            SubcManagementSetup.SetLoadFields("Rtng. Link Code Purch. Prov.", "Def. provision flushing method");
            SubcManagementSetup.Get();
            SubManagementSetupRead := true;
        end;
    end;
}
