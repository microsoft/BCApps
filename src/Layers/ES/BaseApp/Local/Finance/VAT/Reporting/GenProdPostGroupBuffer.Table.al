// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;

table 10730 "Gen. Prod. Post. Group Buffer"
{
    Caption = 'Gen. Prod. Post. Group Buffer';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Product Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; "Exclude from 349"; Boolean)
        {
            Caption = 'Exclude from 349';
            DataClassification = SystemMetadata;
        }
        field(4; "Non Deduct. Prod. Post. Group"; Boolean)
        {
            Caption = 'Non Deduct. Prod. Post. Group';
            DataClassification = SystemMetadata;
        }
        field(5; "Rev. Charge Prod. Post. Group"; Boolean)
        {
            Caption = 'Rev. Charge Prod. Post. Group';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        SelectedGPPG: Record "Selected Gen. Prod. Post. Gr.";
        NonDeductGPPG340: Record "Selected Gen. Prod. Post. 340";

    [Scope('OnPrem')]
    procedure SetGPPGSelectionMultiple(var SelectedGPPGText: Text[1024]; var FilterString: Text[1024])
    var
        GenProdPostGroup: Record "Gen. Product Posting Group";
        TempGPPGBuffer: Record "Gen. Prod. Post. Group Buffer" temporary;
        GPPGSelectionMultiple: Page "Gen. Prod. Post. Gr. Selection";
    begin
        Clear(GPPGSelectionMultiple);
        if GenProdPostGroup.Find('-') then
            repeat
                GPPGSelectionMultiple.InsertGPPGSelBuf(
                  SelectedGPPG.Get(GenProdPostGroup.Code),
                  GenProdPostGroup.Code, GenProdPostGroup.Description);
            until GenProdPostGroup.Next() = 0;

        GPPGSelectionMultiple.LookupMode := true;
        if GPPGSelectionMultiple.RunModal() = ACTION::LookupOK then begin
            GPPGSelectionMultiple.GetGPPGSelBuf(TempGPPGBuffer);
            SetGPPGSelection(SelectedGPPGText, TempGPPGBuffer, FilterString);
        end;
    end;

    local procedure SetGPPGSelection(var SelectedGPPGText: Text[1024]; var GPPGSelectionBuf: Record "Gen. Prod. Post. Group Buffer"; var FilterString: Text[1024])
    begin
        SelectedGPPG.DeleteAll();
        SelectedGPPGText := '';
        GPPGSelectionBuf.SetRange("Exclude from 349", true);
        if GPPGSelectionBuf.Find('-') then
            repeat
                SelectedGPPG.Code := GPPGSelectionBuf.Code;
                SelectedGPPG.Description := GPPGSelectionBuf.Description;
                SelectedGPPG.Insert();
                AddGPPGCodeToText(SelectedGPPG.Code, SelectedGPPGText, FilterString);
            until GPPGSelectionBuf.Next() = 0;
    end;

    local procedure AddGPPGCodeToText(GPPGCode: Code[20]; var Text: Text[1024]; var FilterString: Text[1024])
    begin
        if Text = '' then begin
            Text := GPPGCode;
            FilterString := StrSubstNo('<>%1', Text);
        end else
            if (StrLen(Text) + StrLen(GPPGCode)) <= (MaxStrLen(Text) - 4) then begin
                Text := Text + ';' + GPPGCode;
                FilterString := FilterString + '&<>' + GPPGCode;
            end else
                Text := Text + ';...';
    end;

    [Scope('OnPrem')]
    procedure SetNonDedGPPGSelectMultiple340(var SelectedGPPGText: Text[1024]; var FilterString: Text[1024])
    var
        GenProdPostGroup: Record "Gen. Product Posting Group";
        TempGPPGBuffer: Record "Gen. Prod. Post. Group Buffer" temporary;
        GPPGNonDeductSelectMul340: Page "Gen. Prod. Post. Selection 340";
    begin
        Clear(GPPGNonDeductSelectMul340);
        if GenProdPostGroup.Find('-') then
            repeat
                GPPGNonDeductSelectMul340.InsertGPPGSelBuf(
                  NonDeductGPPG340.Get(GenProdPostGroup.Code),
                  GenProdPostGroup.Code, GenProdPostGroup.Description);
            until GenProdPostGroup.Next() = 0;

        GPPGNonDeductSelectMul340.LookupMode := true;
        if GPPGNonDeductSelectMul340.RunModal() = ACTION::LookupOK then begin
            GPPGNonDeductSelectMul340.GetGPPGSelBuf(TempGPPGBuffer);
            SetNonDeductGPPGSelection340(SelectedGPPGText, TempGPPGBuffer, FilterString);
        end;
    end;

    local procedure SetNonDeductGPPGSelection340(var SelectedGPPGText: Text[1024]; var GPPGSelectionBuf: Record "Gen. Prod. Post. Group Buffer"; var FilterString: Text[1024])
    begin
        NonDeductGPPG340.DeleteAll();
        SelectedGPPGText := '';
        GPPGSelectionBuf.SetRange("Non Deduct. Prod. Post. Group", true);
        if GPPGSelectionBuf.FindFirst() then
            repeat
                NonDeductGPPG340.Code := GPPGSelectionBuf.Code;
                NonDeductGPPG340.Description := GPPGSelectionBuf.Description;
                NonDeductGPPG340.Insert();
                AddGPPGCodeToText(NonDeductGPPG340.Code, SelectedGPPGText, FilterString);
            until GPPGSelectionBuf.Next() = 0;
    end;
}

