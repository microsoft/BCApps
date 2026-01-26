// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;

table 10726 "G/L Account Buffer"
{
    Caption = 'G/L Account Buffer';
    DataCaptionFields = "No.", Name;
    LookupPageID = "G/L Account List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; "Include G/L Acc. in 347"; Boolean)
        {
            Caption = 'Include G/L Acc. in 347';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        SelectedGLAcc: Record "Selected G/L Accounts";

    procedure SetGLAccSelectionMultiple(var SelectedGLAccText: Text[250]; var FilterString: Text[250])
    var
        GLAccount: Record "G/L Account";
        TempGLAccBuffer: Record "G/L Account Buffer" temporary;
        GLAccSelectionMultiple: Page "G/L Account Selection";
    begin
        Clear(GLAccSelectionMultiple);
        if GLAccount.Find('-') then
            repeat
                GLAccSelectionMultiple.InsertGLAccSelBuf(
                  SelectedGLAcc.Get(GLAccount."No."),
                  GLAccount."No.", GLAccount.Name);
            until GLAccount.Next() = 0;

        GLAccSelectionMultiple.LookupMode := true;
        if GLAccSelectionMultiple.RunModal() = ACTION::LookupOK then begin
            GLAccSelectionMultiple.GetGLAccSelBuf(TempGLAccBuffer);
            SetGLAccSelection(SelectedGLAccText, TempGLAccBuffer, FilterString);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetGLAccSelection(var SelectedGLAccText: Text[250]; var GLAccSelectionBuf: Record "G/L Account Buffer"; var FilterString: Text[250])
    begin
        SelectedGLAcc.DeleteAll();
        SelectedGLAccText := '';
        GLAccSelectionBuf.SetRange("Include G/L Acc. in 347", true);
        if GLAccSelectionBuf.Find('-') then
            repeat
                SelectedGLAcc."No." := GLAccSelectionBuf."No.";
                SelectedGLAcc.Name := GLAccSelectionBuf.Name;
                SelectedGLAcc.Insert();
                AddGLAccNoToText(SelectedGLAcc."No.", SelectedGLAccText, FilterString);
            until GLAccSelectionBuf.Next() = 0;
    end;

    procedure AddGLAccNoToText(GLAccNo: Code[20]; var Text: Text[250]; var FilterString: Text[250])
    begin
        if Text = '' then begin
            Text := GLAccNo;
            FilterString := StrSubstNo('%1', Text);
        end else
            if (StrLen(Text) + StrLen(GLAccNo)) <= (MaxStrLen(Text) - 4) then begin
                Text := StrSubstNo('%1;%2', Text, GLAccNo);
                FilterString := StrSubstNo('%1|%2', FilterString, GLAccNo);
            end else
                Text := StrSubstNo('%1;...', Text)
    end;

    [Scope('OnPrem')]
    procedure GetGLAccSelectionText(): Text[250]
    var
        SelectedGLAcc: Record "Selected G/L Accounts";
        SelectedGLAccText: Text[250];
    begin
        if SelectedGLAcc.Find('-') then
            repeat
                AddGLAccNoToText(SelectedGLAcc."No.", SelectedGLAccText, SelectedGLAccText);
            until SelectedGLAcc.Next() = 0;
        exit(SelectedGLAccText);
    end;
}

