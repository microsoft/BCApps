#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

table 11207 "SIE Dimension"
{
    Caption = 'SIE Dimension';
    ObsoleteReason = 'Replaced by Dimension SIE table of Standard Import Export (SIE) extension';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if Dimension.Get("Dimension Code") then
                    Name := Dimension.Name;

                GLSetup.Get();
                if GLSetup."Shortcut Dimension 1 Code" = "Dimension Code" then
                    ShortCutDimNo := 1;
                if GLSetup."Shortcut Dimension 2 Code" = "Dimension Code" then
                    ShortCutDimNo := 2;
                if GLSetup."Shortcut Dimension 3 Code" = "Dimension Code" then
                    ShortCutDimNo := 3;
                if GLSetup."Shortcut Dimension 4 Code" = "Dimension Code" then
                    ShortCutDimNo := 4;
                if GLSetup."Shortcut Dimension 5 Code" = "Dimension Code" then
                    ShortCutDimNo := 5;
                if GLSetup."Shortcut Dimension 6 Code" = "Dimension Code" then
                    ShortCutDimNo := 6;
                if GLSetup."Shortcut Dimension 7 Code" = "Dimension Code" then
                    ShortCutDimNo := 7;
                if GLSetup."Shortcut Dimension 8 Code" = "Dimension Code" then
                    ShortCutDimNo := 8;
            end;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
            InitValue = true;
        }
        field(4; "SIE Dimension"; Integer)
        {
            Caption = 'SIE Dimension';
        }
        field(5; ShortCutDimNo; Integer)
        {
            Caption = 'ShortCutDimNo';
        }
    }

    keys
    {
        key(Key1; "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "SIE Dimension")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Dimension: Record Dimension;
        GLSetup: Record "General Ledger Setup";

    [Scope('OnPrem')]
    procedure AddDimCodeToText(DimCode: Code[20]; var Text: Text[250])
    begin
        if Text = '' then
            Text := DimCode
        else
            if (StrLen(Text) + StrLen(DimCode)) <= (MaxStrLen(Text) - 4) then
                Text := StrSubstNo('%1; %2', Text, DimCode)
            else
                Text := StrSubstNo('%1;...', Text)
    end;

    [Scope('OnPrem')]
    procedure GetDimSelectionText(): Text[250]
    var
        SelectedDim: Record "SIE Dimension";
        SelectedDimText: Text[250];
    begin
        SelectedDim.SetRange(Selected, true);
        if SelectedDim.Find('-') then
            repeat
                SelectedDim.AddDimCodeToText(SelectedDim."Dimension Code", SelectedDimText);
            until SelectedDim.Next() = 0;
        exit(SelectedDimText);
    end;
}

 
#endif
