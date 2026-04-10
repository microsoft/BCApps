// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Inventory.Counting.Document;

report 5881 "Make Phys. Invt. Recording"
{
    Caption = 'Make New Phys. Invt. Recording';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Phys. Invt. Order Header"; "Phys. Invt. Order Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem("Phys. Invt. Order Line"; "Phys. Invt. Order Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");
                RequestFilterFields = "Item No.", "Location Code", "Bin Code", "Shelf No.", "Inventory Posting Group";

                trigger OnAfterGetRecord()
                var
                    ShouldInsertHeader: Boolean;
                begin
                    if CheckOrderLine("Phys. Invt. Order Line") then begin
                        ShouldInsertHeader := not HeaderInserted;
                        OnPhysInvtOrderLineOnAfterCalcShouldInsertHeader("Phys. Invt. Order Header", "Phys. Invt. Order Line", ShouldInsertHeader);
                        if ShouldInsertHeader then begin
                            InsertRecordingHeader("Phys. Invt. Order Header");
                            HeaderInserted := true;
                            NextLineNo := 10000;
                            HeaderCount := HeaderCount + 1;
                        end;
                        InsertRecordingLine("Phys. Invt. Order Line");
                        OnPhysInvtOrderLineOnAfterInsertRecordingLine("Phys. Invt. Order Header", "Phys. Invt. Order Line", PhysInvtRecordHeader, PhysInvtRecordLine);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    HeaderInserted := false;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Status, Status::Open);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(OnlyLinesNotInRecordings; OnlyLinesNotInRecordings)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Lines Not In Recordings';
                        ToolTip = 'Specifies that a new physical inventory recording lines are only created when the data does not exist on any other physical inventory recording line. This is useful when you want to make sure that different recordings do not contain the same items.';
                    }
                    field(AllowRecWithoutOrder; AllowRecWithoutOrder)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Allow Recording Without Order';
                        ToolTip = 'Specifies that recording lines are automatically created for items that do not exist on the physical inventory order. This can only happen if none of the values in these four fields exist for an item on the order: Item No., Variant Code, Location Code, and Bin Code.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostReport(PhysInvtRecordHeader, HeaderCount, IsHandled);
        if not IsHandled then
            case HeaderCount of
                0:
                    Message(NewOrderNotCreatedMsg);
                1:
                    Message(NewOrderCreatedMsg,
                    PhysInvtRecordHeader."Order No.", PhysInvtRecordHeader."Recording No.");
                else
                    Message(DifferentOrdersMsg, HeaderCount);
            end;

        OnAfterOnPostReport(PhysInvtRecordHeader, HeaderCount);
    end;

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport("Phys. Invt. Order Header");

        HeaderCount := 0;
    end;

    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        NewOrderNotCreatedMsg: Label 'A physical inventory recording was not created because no valid physical inventory order lines exist.';
        NewOrderCreatedMsg: Label 'Physical inventory recording %1 %2 has been created.', Comment = '%1 = Order No. %2 = Recording No.';
        DifferentOrdersMsg: Label '%1 different orders has been created.', Comment = '%1 = counter';

    protected var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        NextLineNo: Integer;
        HeaderCount: Integer;
        OnlyLinesNotInRecordings: Boolean;
        HeaderInserted: Boolean;
        AllowRecWithoutOrder: Boolean;

    procedure CheckOrderLine(PhysInvtOrderLine: Record "Phys. Invt. Order Line"): Boolean
    var
        PhysInvtRecordLine2: Record "Phys. Invt. Record Line";
    begin
        if PhysInvtOrderLine.EmptyLine() then
            exit(false);
        PhysInvtOrderLine.TestField(PhysInvtOrderLine."Item No.");
        if OnlyLinesNotInRecordings then begin
            PhysInvtRecordLine2.SetCurrentKey(
              "Order No.", "Item No.", "Variant Code", "Location Code", "Bin Code");
            PhysInvtRecordLine2.SetRange("Order No.", PhysInvtOrderLine."Document No.");
            PhysInvtRecordLine2.SetRange("Item No.", PhysInvtOrderLine."Item No.");
            PhysInvtRecordLine2.SetRange("Variant Code", PhysInvtOrderLine."Variant Code");
            PhysInvtRecordLine2.SetRange("Location Code", PhysInvtOrderLine."Location Code");
            PhysInvtRecordLine2.SetRange("Bin Code", PhysInvtOrderLine."Bin Code");
            OnCheckOrderLineOnAfterSetFilters(PhysInvtRecordLine2, PhysInvtOrderLine);
            if not PhysInvtRecordLine2.IsEmpty() then
                exit(false);
        end;
        exit(true);
    end;

    procedure InsertRecordingHeader(PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
        PhysInvtRecordHeader.Init();
        PhysInvtRecordHeader."Order No." := PhysInvtOrderHeader."No.";
        PhysInvtRecordHeader."Recording No." := 0;
        PhysInvtRecordHeader."Person Responsible" := PhysInvtOrderHeader."Person Responsible";
        PhysInvtRecordHeader."Location Code" := PhysInvtOrderHeader."Location Code";
        PhysInvtRecordHeader."Bin Code" := PhysInvtOrderHeader."Bin Code";
        PhysInvtRecordHeader."Allow Recording Without Order" := AllowRecWithoutOrder;
        OnInsertRecordingHeaderOnBeforeInsert(PhysInvtRecordHeader, PhysInvtOrderHeader);
        PhysInvtRecordHeader.Insert(true);
    end;

    procedure InsertRecordingLine(PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
        PhysInvtRecordLine.Init();
        PhysInvtRecordLine."Order No." := PhysInvtRecordHeader."Order No.";
        PhysInvtRecordLine."Recording No." := PhysInvtRecordHeader."Recording No.";
        PhysInvtRecordLine."Line No." := NextLineNo;
        PhysInvtRecordLine.Validate(PhysInvtRecordLine."Item No.", PhysInvtOrderLine."Item No.");
        PhysInvtRecordLine.Validate(PhysInvtRecordLine."Variant Code", PhysInvtOrderLine."Variant Code");
        PhysInvtRecordLine.Validate(PhysInvtRecordLine."Location Code", PhysInvtOrderLine."Location Code");
        PhysInvtRecordLine.Validate(PhysInvtRecordLine."Bin Code", PhysInvtOrderLine."Bin Code");
        PhysInvtRecordLine.Description := PhysInvtOrderLine.Description;
        PhysInvtRecordLine."Description 2" := PhysInvtOrderLine."Description 2";
        PhysInvtRecordLine."Use Item Tracking" := PhysInvtOrderLine."Use Item Tracking";
        PhysInvtRecordLine."Shelf No." := PhysInvtOrderLine."Shelf No.";
        PhysInvtRecordLine.Validate(PhysInvtRecordLine."Unit of Measure Code", PhysInvtOrderLine."Base Unit of Measure Code");
        PhysInvtRecordLine.Recorded := false;
        OnBeforePhysInvtRecordLineInsert(PhysInvtRecordLine, PhysInvtOrderLine);
        PhysInvtRecordLine.Insert();
        OnAfterPhysInvtRecordLineInsert(PhysInvtRecordLine, PhysInvtOrderLine);
        NextLineNo := PhysInvtRecordLine."Line No." + 10000;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPostReport(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; HeadCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPhysInvtRecordLineInsert(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtRecordLineInsert(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckOrderLineOnAfterSetFilters(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertRecordingHeaderOnBeforeInsert(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostReport(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var HeaderCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPhysInvtOrderLineOnAfterCalcShouldInsertHeader(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ShouldInsertHeader: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPhysInvtOrderLineOnAfterInsertRecordingLine(PhysInvtOrderHeader: Record "Phys. Invt. Order Header"; PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;
}

