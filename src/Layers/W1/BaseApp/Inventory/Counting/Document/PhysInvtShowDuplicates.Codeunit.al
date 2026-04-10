// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

codeunit 5886 "Phys. Invt.-Show Duplicates"
{
    TableNo = "Phys. Invt. Order Header";

    trigger OnRun()
    begin
        PhysInvtOrderHeader.Copy(Rec);
        Code();
        Rec := PhysInvtOrderHeader;
    end;

    var
        CheckingLinesMsg: Label 'Checking lines        #2######', Comment = '%2 = counter';
        NoDuplicateLinesMsg: Label 'There are no duplicate order lines in order %1.', Comment = '%1 = Order No.';
        DuplicatesFoundQst: Label 'There are %1 duplicate order lines in order %2.\Do you want to show it?', Comment = '%1 = duplicates count, %2 = Order No.';
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
        Window: Dialog;
        ErrorText: Text[250];
        LineCount: Integer;
        DuplicateCount: Integer;

    procedure "Code"()
    begin
        Window.Open('#1################################\\' + CheckingLinesMsg);
        Window.Update(1, StrSubstNo('%1 %2', PhysInvtOrderHeader.TableCaption(), PhysInvtOrderHeader."No."));

        LineCount := 0;
        DuplicateCount := 0;
        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", PhysInvtOrderHeader."No.");
        PhysInvtOrderLine.ClearMarks();
        if PhysInvtOrderLine.Find('-') then
            repeat
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
                if not PhysInvtOrderLine.EmptyLine() then begin
                    PhysInvtOrderLine.TestField("Item No.");
                    if
                       PhysInvtOrderHeader.GetSamePhysInvtOrderLine(
                         PhysInvtOrderLine,
                         ErrorText,
                         PhysInvtOrderLine2) > 1
                    then begin
                        PhysInvtOrderLine.Mark(true);
                        DuplicateCount := DuplicateCount + 1;
                    end;
                end;
            until PhysInvtOrderLine.Next() = 0;

        Window.Close();

        if DuplicateCount = 0 then
            Message(StrSubstNo(NoDuplicateLinesMsg, PhysInvtOrderHeader."No."))
        else
            if Confirm(StrSubstNo(DuplicatesFoundQst, DuplicateCount, PhysInvtOrderHeader."No."), true) then begin
                PhysInvtOrderLine.MarkedOnly(true);
                PAGE.Run(0, PhysInvtOrderLine);
            end;
    end;
}

