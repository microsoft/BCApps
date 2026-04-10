// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Service.Document;

codeunit 5945 CreateCreditfromContractLines
{
    SingleInstance = true;
    TableNo = "Service Contract Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, LinesToDelete, IsHandled);
        if IsHandled then
            exit;

        ServContractHeader.Get(Rec."Contract Type", Rec."Contract No.");
        if not Rec.Credited and
           not Rec."New Line"
        then begin
            if Rec."Line Amount" > 0 then
                if ServContractHeader."Automatic Credit Memos" then
                    if Rec."Credit Memo Date" > 0D then
                        CreditNoteNo := ServContractMgt.CreateContractLineCreditMemo(Rec, true);
            ServItemLine.Reset();
            ServItemLine.SetCurrentKey("Contract No.");
            ServItemLine.SetRange("Contract No.", Rec."Contract No.");
            ServItemLine.SetRange("Contract Line No.", Rec."Line No.");
            ServItemLineExist := ServItemLine.FindFirst();
        end;

        if LinesToDelete = 1 then begin
            LinesToDelete := 0;
            if CreditNoteNo <> '' then
                Message(Text000, CreditNoteNo);
            if ServItemLineExist then
                if LinesToDelete = 1 then
                    Message(Text002, LowerCase(Rec.TableCaption))
                else
                    Message(Text001);
            ServItemLineExist := false;
            CreditNoteNo := '';
        end;
    end;

    var
        ServContractHeader: Record "Service Contract Header";
        ServItemLine: Record "Service Item Line";
        ServContractMgt: Codeunit ServContractManagement;
        CreditNoteNo: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Credit Memo %1 was created.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServItemLineExist: Boolean;
        LinesToDelete: Integer;
#pragma warning disable AA0074
        Text001: Label 'Some service contract lines are part of a service order/s.\You have to update this service order/s manually.';
#pragma warning disable AA0470
        Text002: Label 'This %1 is part of a service order/s.\You have to update this service order/s manually.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetSelectionFilterNo(LinesSelected: Integer)
    begin
        LinesToDelete := LinesSelected;
    end;

    procedure InitVariables()
    begin
        ServItemLineExist := false;
        CreditNoteNo := '';
        LinesToDelete := 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceContractLine: Record "Service Contract Line"; LinesToDelete: Integer; var IsHandled: Boolean)
    begin
    end;
}

