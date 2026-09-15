// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;

codeunit 5876 "Phys. Invt. Rec.-Finish"
{
    TableNo = "Phys. Invt. Record Header";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if not IsHandled then begin
            PhysInvtRecordHeader.Copy(Rec);
            Code();
            Rec := PhysInvtRecordHeader;
        end;
        OnAfterOnRun(Rec);
    end;

    var
        FinishingLinesMsg: Label 'Finishing lines              #2######', Comment = '%2 = counter';
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        NoLinesRecordedErr: Label 'There are no Lines recorded.';
        Window: Dialog;
        ErrorText: Text[250];
        LineCount: Integer;
        NextOrderLineNo: Integer;
        NoOfOrderLines: Integer;
        HideProgressWindow: Boolean;

    procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCode(PhysInvtRecordHeader, HideProgressWindow);

        InvtSetup.Get();
        PhysInvtRecordHeader.TestField("Order No.");
        PhysInvtRecordHeader.TestField("Recording No.");
        PhysInvtRecordHeader.TestField(Status, PhysInvtRecordHeader.Status::Open);

        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        PhysInvtRecordLine.SetFilter("Item No.", '<>%1', '');
        if not PhysInvtRecordLine.Find('-') then begin
            IsHandled := false;
            OnCodeOnBeforeNoPhysInvtRecordLineError(PhysInvtRecordHeader, IsHandled);
            if not IsHandled then
                Error(NoLinesRecordedErr);
        end;

        if not HideProgressWindow then begin
            Window.Open('#1#################################\\' + FinishingLinesMsg);
            Window.Update(1, StrSubstNo('%1 %2', PhysInvtRecordHeader.TableCaption(), PhysInvtRecordHeader."Order No."));
        end;

        PhysInvtOrderHeader.LockTable();
        PhysInvtOrderLine.LockTable();
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtRecordHeader."Order No.");
        if PhysInvtOrderLine.FindLast() then
            NextOrderLineNo := PhysInvtOrderLine."Line No." + 10000
        else
            NextOrderLineNo := 10000;

        PhysInvtOrderHeader.Get(PhysInvtRecordHeader."Order No.");

        LineCount := 0;
        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        if PhysInvtRecordLine.Find('-') then
            repeat
                LineCount := LineCount + 1;
                if not HideProgressWindow then
                    Window.Update(2, LineCount);

                if not PhysInvtRecordLine.EmptyLine() then begin
                    IsHandled := false;
                    OnCodeOnBeforeCheckPhysInvtRecordLine(PhysInvtRecordLine, IsHandled);
                    if not IsHandled then begin
                        PhysInvtRecordLine.TestField("Item No.");
                        PhysInvtRecordLine.TestField(Recorded, true);
                        if PhysInvtRecordLine."Location Code" <> '' then begin
                            Location.Get(PhysInvtRecordLine."Location Code");
                            CheckLocationDirectedPutAwayAndPick();
                            if Location."Bin Mandatory" then
                                PhysInvtRecordLine.TestField("Bin Code")
                            else
                                PhysInvtRecordLine.TestField("Bin Code", '');
                        end else begin
                            if InvtSetup."Location Mandatory" then
                                PhysInvtRecordLine.TestField("Location Code");
                            PhysInvtRecordLine.TestField("Bin Code", '');
                        end;
                    end;
                    IsHandled := false;
                    OnBeforeGetSamePhysInvtOrderLine(PhysInvtOrderLine, PhysInvtRecordLine, NoOfOrderLines, ErrorText, IsHandled);
                    if not IsHandled then
                        NoOfOrderLines :=
                          PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                            PhysInvtRecordLine."Item No.", PhysInvtRecordLine."Variant Code",
                            PhysInvtRecordLine."Location Code", PhysInvtRecordLine."Bin Code",
                            ErrorText, PhysInvtOrderLine);
                    if NoOfOrderLines > 1 then
                        Error(ErrorText);
                    if NoOfOrderLines = 0 then begin
                        if not PhysInvtRecordHeader."Allow Recording Without Order" then
                            Error(ErrorText);
                        PhysInvtOrderLine.Init();
                        PhysInvtOrderLine."Document No." := PhysInvtRecordHeader."Order No.";
                        PhysInvtOrderLine."Line No." := NextOrderLineNo;
                        PhysInvtOrderLine.Validate("Item No.", PhysInvtRecordLine."Item No.");
                        PhysInvtOrderLine.Validate("Variant Code", PhysInvtRecordLine."Variant Code");
                        PhysInvtOrderLine.Validate("Location Code", PhysInvtRecordLine."Location Code");
                        PhysInvtOrderLine.Validate("Bin Code", PhysInvtRecordLine."Bin Code");
                        PhysInvtOrderLine."Recorded Without Order" := true;
                        OnBeforePhysInvtOrderLineInsert(PhysInvtOrderLine, PhysInvtRecordLine);
                        PhysInvtOrderLine.CreateDimFromDefaultDim();
                        PhysInvtOrderLine.Insert(true);
                        NextOrderLineNo := NextOrderLineNo + 10000;
                    end;

                    PhysInvtRecordLine."Order Line No." := PhysInvtOrderLine."Line No.";
                    PhysInvtRecordLine."Recorded Without Order" := PhysInvtOrderLine."Recorded Without Order";
                    PhysInvtRecordLine.Modify();

                    PhysInvtOrderLine."Qty. Recorded (Base)" += PhysInvtRecordLine."Quantity (Base)";
                    PhysInvtOrderLine."No. Finished Rec.-Lines" += 1;
                    PhysInvtOrderLine."On Recording Lines" := PhysInvtOrderLine."No. Finished Rec.-Lines" <> 0;
                    OnBeforePhysInvtOrderLineModify(PhysInvtOrderLine, PhysInvtRecordLine);
                    PhysInvtOrderLine.Modify();
                end;
            until PhysInvtRecordLine.Next() = 0;

        OnCodeOnBeforeSetStatusToFinished(PhysInvtRecordHeader);
        PhysInvtRecordHeader.Status := PhysInvtRecordHeader.Status::Finished;
        PhysInvtRecordHeader.Modify();

        OnAfterCode(PhysInvtRecordHeader);
    end;

    local procedure CheckLocationDirectedPutAwayAndPick()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLocationDirectedPutAwayAndPick(PhysInvtRecordLine, IsHandled);
        if IsHandled then
            exit;

        Location.TestField("Directed Put-away and Pick", false);
    end;

    procedure SetHideProgressWindow(NewHideProgressWindow: Boolean)
    begin
        HideProgressWindow := NewHideProgressWindow;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLocationDirectedPutAwayAndPick(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSamePhysInvtOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var NoOfOrderLines: Integer; var ErrorText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineModify(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineInsert(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckPhysInvtRecordLine(PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSetStatusToFinished(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeNoPhysInvtRecordLineError(var PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var IsHandled: Boolean)
    begin
    end;
}

