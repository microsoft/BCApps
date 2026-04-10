// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

report 5883 "Copy Phys. Invt. Recording"
{
    Caption = 'Copy Phys. Invt. Rec. Line';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
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

    trigger OnPreReport()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPreReportOnBeforeCopyLine(PhysInvtRecordLine, ToPhysInvtRecordLine, LineSpacing, NoOfCopies, IsHandled);
        if IsHandled then
            exit;

        if NoOfCopies <= 0 then
            exit;

        PhysInvtRecordLine.TestField("Order No.");
        PhysInvtRecordHeader.Get(PhysInvtRecordLine."Order No.", PhysInvtRecordLine."Recording No.");
        PhysInvtRecordHeader.TestField(Status, PhysInvtRecordHeader.Status::Open);

        ToPhysInvtRecordLine.Reset();
        ToPhysInvtRecordLine.SetRange("Order No.", PhysInvtRecordLine."Order No.");
        ToPhysInvtRecordLine.SetRange("Recording No.", PhysInvtRecordLine."Recording No.");
        ToPhysInvtRecordLine := PhysInvtRecordLine;
        if ToPhysInvtRecordLine.Find('>') then begin
            LineSpacing := (ToPhysInvtRecordLine."Line No." - PhysInvtRecordLine."Line No.") div (1 + NoOfCopies);
            if LineSpacing = 0 then
                Error(
                  NotEnoughSpaceErr, NoOfCopies);
        end else
            LineSpacing := 10000;

        for I := 1 to NoOfCopies do begin
            ToPhysInvtRecordLine := PhysInvtRecordLine;
            if ToPhysInvtRecordLine."Serial No." <> '' then
                ToPhysInvtRecordLine."Serial No." := '';
            ToPhysInvtRecordLine."Line No." :=
              PhysInvtRecordLine."Line No." + I * LineSpacing;
            ToPhysInvtRecordLine.Insert();
        end;
    end;

    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        I: Integer;

        NotEnoughSpaceErr: Label 'There is not enough space to insert %1 copies.', Comment = '%1 = Number';

    protected var
        ToPhysInvtRecordLine: Record "Phys. Invt. Record Line";
        LineSpacing: Integer;
        NoOfCopies: Integer;

    procedure SetPhysInvtRecordLine(var NewPhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
        PhysInvtRecordLine := NewPhysInvtRecordLine;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyLine(FromPhysInvtRecordLine: Record "Phys. Invt. Record Line"; var ToPhysInvtRecordLine: Record "Phys. Invt. Record Line"; var LineSpacing: Integer; NoOfCopies: Integer; var IsHandled: Boolean)
    begin
    end;
}

