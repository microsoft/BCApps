// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

table 368 "Dimension Selection Buffer"
{
    Caption = 'Dimension Selection Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Text[30])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                "New Dimension Value Code" := '';
                "Dimension Value Filter" := '';
                Level := Level::" ";
            end;
        }
        field(4; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
            DataClassification = SystemMetadata;
            TableRelation = if (Code = const('G/L Account')) "G/L Account"."No."
            else
            if (Code = const('Business Unit')) "Business Unit".Code
            else
            "Dimension Value".Code where("Dimension Code" = field(Code), Blocked = const(false));

            trigger OnValidate()
            begin
                Selected := true;
            end;
        }
        field(5; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            DataClassification = SystemMetadata;
            TableRelation = if ("Filter Lookup Table No." = const(15)) "G/L Account"."No."
            else
            if ("Filter Lookup Table No." = const(220)) "Business Unit".Code
            else
            if ("Filter Lookup Table No." = const(841)) "Cash Flow Account"."No."
            else
            if ("Filter Lookup Table No." = const(840)) "Cash Flow Forecast"."No."
            else
            "Dimension Value".Code where("Dimension Code" = field(Code), Blocked = const(false));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if (Level = Level::" ") and ("Dimension Value Filter" = '') then
                    Selected := false
                else
                    Selected := true;
            end;
        }
        field(6; Level; Option)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Level 1,Level 2,Level 3,Level 4';
            OptionMembers = " ","Level 1","Level 2","Level 3","Level 4";

            trigger OnValidate()
            begin
                if (Level = Level::" ") and ("Dimension Value Filter" = '') then
                    Selected := false
                else
                    Selected := true;
            end;
        }
        field(7; "Filter Lookup Table No."; Integer)
        {
            Caption = 'Filter Lookup Table No.';
            DataClassification = SystemMetadata;
            Editable = false;
            InitValue = 349;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Level, "Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Another user has modified the selected dimensions for the %1 field after you retrieved it from the database.\';
        Text002: Label 'Enter your changes again in the Dimension Selection window by clicking the AssistButton on the %1 field. ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetDimSelectionMultiple(ObjectType: Integer; ObjectID: Integer; var SelectedDimText: Text[250])
    var
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        DimSelectionMultiple: Page "Dimension Selection-Multiple";
    begin
        Clear(DimSelectionMultiple);
        if Dim.Find('-') then
            repeat
                InsertDimSelBufForDimSelectionMultiple(DimSelectionMultiple, Dim, ObjectType, ObjectID)
            until Dim.Next() = 0;

        if DimSelectionMultiple.RunModal() = ACTION::OK then begin
            DimSelectionMultiple.GetDimSelBuf(TempDimSelectionBuf);
            SetDimSelection(ObjectType, ObjectID, '', SelectedDimText, TempDimSelectionBuf);
        end;
    end;

    local procedure InsertDimSelBufForDimSelectionMultiple(var DimSelectionMultiple: Page "Dimension Selection-Multiple"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer)
    var
        SelectedDim: Record "Selected Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDimSelBufForDimSelectionMultiple(DimSelectionMultiple, Dimension, ObjectType, ObjectID, IsHandled);
        if IsHandled then
            exit;

        DimSelectionMultiple.InsertDimSelBuf(SelectedDim.Get(UserId, ObjectType, ObjectID, '', Dimension.Code), Dimension.Code, Dimension.GetMLName(GlobalLanguage));
    end;

    procedure SetDimSelectionChange(ObjectType: Integer; ObjectID: Integer; var SelectedDimText: Text[250])
    var
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        DimSelectionChange: Page "Dimension Selection-Change";
    begin
        Clear(DimSelectionChange);
        if Dim.Find('-') then
            repeat
                InsertDimSelBufForDimSelectionChange(DimSelectionChange, Dim, ObjectType, ObjectID);
            until Dim.Next() = 0;

        if DimSelectionChange.RunModal() = ACTION::OK then begin
            DimSelectionChange.GetDimSelBuf(TempDimSelectionBuf);
            SetDimSelection(ObjectType, ObjectID, '', SelectedDimText, TempDimSelectionBuf);
        end;

        OnAfterSetDimSelectionChange(Rec, TempDimSelectionBuf);
    end;

    local procedure InsertDimSelBufForDimSelectionChange(var DimSelectionChange: Page "Dimension Selection-Change"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer)
    var
        SelectedDim: Record "Selected Dimension";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertDimSelBufForDimSelectionChange(DimSelectionChange, Dimension, ObjectType, ObjectID, IsHandled);
        if IsHandled then
            exit;

        DimSelectionChange.InsertDimSelBuf(
          SelectedDim.Get(UserId, ObjectType, ObjectID, '', Dimension.Code),
          Dimension.Code, Dimension.GetMLName(GlobalLanguage),
          SelectedDim."New Dimension Value Code",
          SelectedDim."Dimension Value Filter");
    end;

    procedure CompareDimText(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; SelectedDimText: Text[250]; DimTextFieldName: Text[100])
    var
        SelectedDim: Record "Selected Dimension";
        SelectedDimTextFromDb: Text[250];
    begin
        SelectedDimTextFromDb := '';
        SelectedDim.SetCurrentKey(
          "User ID", "Object Type", "Object ID", "Analysis View Code", Level, "Dimension Code");
        SetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID, AnalysisViewCode);
        OnCompareDimTextOnBeforeSelectedDimFind(SelectedDim, ObjectType, ObjectID);
        if SelectedDim.Find('-') then
            repeat
                AddDimCodeToText(SelectedDim."Dimension Code", SelectedDimTextFromDb);
            until SelectedDim.Next() = 0;
        if SelectedDimTextFromDb <> SelectedDimText then
            Error(
              Text000 +
              Text002,
              DimTextFieldName);
    end;

    local procedure AddDimCodeToText(DimCode: Code[30]; var Text: Text[250])
    begin
        if Text = '' then
            Text := DimCode
        else
            if (StrLen(Text) + StrLen(DimCode)) <= (MaxStrLen(Text) - 4) then
                Text := StrSubstNo('%1;%2', Text, DimCode)
            else
                if CopyStr(Text, StrLen(Text) - 2, 3) <> '...' then
                    Text := StrSubstNo('%1;...', Text)
    end;

    procedure SetDimSelection(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250]; var DimSelectionBuf: Record "Dimension Selection Buffer")
    var
        SelectedDim: Record "Selected Dimension";
    begin
        SetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID, AnalysisViewCode);
        OnSetDimSelectionOnAfterSetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID);
        SelectedDim.DeleteAll();
        SelectedDimText := '';
        DimSelectionBuf.SetCurrentKey(Level, Code);
        DimSelectionBuf.SetRange(Selected, true);
        if DimSelectionBuf.Find('-') then begin
            repeat
                SelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(SelectedDim."User ID"));
                SelectedDim."Object Type" := ObjectType;
                SelectedDim."Object ID" := ObjectID;
                SelectedDim."Analysis View Code" := AnalysisViewCode;
                SelectedDim."Dimension Code" := DimSelectionBuf.Code;
                SelectedDim."New Dimension Value Code" := DimSelectionBuf."New Dimension Value Code";
                SelectedDim."Dimension Value Filter" := DimSelectionBuf."Dimension Value Filter";
                SelectedDim.Level := DimSelectionBuf.Level;
                OnSetDimSelectionOnBeforeSelectedDimInsert(SelectedDim, ObjectType, ObjectID);
                SelectedDim.Insert();
            until DimSelectionBuf.Next() = 0;
            SelectedDimText := GetDimSelectionText(ObjectType, ObjectID, AnalysisViewCode);
        end;
    end;

    procedure SetDimSelectionLevelGLAcc(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        GLAcc: Record "G/L Account";
    begin
        SetDimSelectionLevelWithAutoSet(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, GLAcc.TableCaption(), false);
    end;

    procedure SetDimSelectionLevelGLAccAutoSet(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        GLAcc: Record "G/L Account";
    begin
        SetDimSelectionLevelWithAutoSet(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, GLAcc.TableCaption(), true);
    end;

    procedure SetDimSelectionLevelCFAcc(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        CFAcc: Record "Cash Flow Account";
    begin
        SetDimSelectionLevelWithAutoSet(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, CFAcc.TableCaption(), false);
    end;

    local procedure SetDimSelectionLevelWithAutoSet(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250]; AccTableCaption: Text[30]; AutoSet: Boolean)
    var
        SelectedDim: Record "Selected Dimension";
        AnalysisView: Record "Analysis View";
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        DimSelectionLevel: Page "Dimension Selection-Level";
        SelectedDimLevel: Option;
        GetSelectedDim: Boolean;
        Finished: Boolean;
    begin
        Clear(DimSelectionLevel);
        if AnalysisView.Get(AnalysisViewCode) then begin
            if Dim.Get(AnalysisView."Dimension 1 Code") then begin
                GetSelectedDim := SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code);
                if AutoSet and not GetSelectedDim then begin
                    SelectedDimLevel := SelectedDim.Level::"Level 2";
                    GetSelectedDim := true;
                end else
                    SelectedDimLevel := SelectedDim.Level;

                DimSelectionLevel.InsertDimSelBuf(
                  GetSelectedDim,
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDimLevel);
            end;

            if Dim.Get(AnalysisView."Dimension 2 Code") then
                DimSelectionLevel.InsertDimSelBuf(
                  SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDim.Level);

            if Dim.Get(AnalysisView."Dimension 3 Code") then
                DimSelectionLevel.InsertDimSelBuf(
                  SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDim.Level);

            if Dim.Get(AnalysisView."Dimension 4 Code") then
                DimSelectionLevel.InsertDimSelBuf(
                  SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."Dimension Value Filter", SelectedDim.Level);

            GetSelectedDim := SelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisViewCode, AccTableCaption);
            if AutoSet and not GetSelectedDim then
                SelectedDimLevel := SelectedDim.Level::"Level 1"
            else
                SelectedDimLevel := SelectedDim.Level;

            DimSelectionLevel.InsertDimSelBuf(
              GetSelectedDim,
              AccTableCaption, AccTableCaption,
              SelectedDim."Dimension Value Filter", SelectedDimLevel);
        end;

        if not AutoSet then
            Finished := DimSelectionLevel.RunModal() = ACTION::OK
        else
            Finished := true;

        if Finished then begin
            DimSelectionLevel.GetDimSelBuf(TempDimSelectionBuf);
            SetDimSelection(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, TempDimSelectionBuf);
        end;
    end;

    procedure GetDimSelectionText(ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]): Text[250]
    var
        SelectedDim: Record "Selected Dimension";
        SelectedDimText: Text[250];
    begin
        SetDefaultRangeOnSelectedDimTable(SelectedDim, ObjectType, ObjectID, AnalysisViewCode);
        SelectedDim.SetCurrentKey("User ID", "Object Type", "Object ID", "Analysis View Code", Level, "Dimension Code");
        if SelectedDim.Find('-') then
            repeat
                AddDimCodeToText(SelectedDim."Dimension Code", SelectedDimText);
            until SelectedDim.Next() = 0;
        exit(SelectedDimText);
    end;

    local procedure SetDefaultRangeOnSelectedDimTable(var SelectedDim: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10])
    begin
        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", ObjectType);
        SelectedDim.SetRange("Object ID", ObjectID);
        SelectedDim.SetRange("Analysis View Code", AnalysisViewCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimSelectionChange(var DimensionSelectionBuffer: Record "Dimension Selection Buffer"; var TheDimSelectionBuf: Record "Dimension Selection Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDimSelBufForDimSelectionChange(var DimSelectionChange: Page "Dimension Selection-Change"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDimSelBufForDimSelectionMultiple(var DimSelectionMultiple: Page "Dimension Selection-Multiple"; Dimension: Record Dimension; ObjectType: Integer; ObjectID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCompareDimTextOnBeforeSelectedDimFind(var SelectedDimension: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDimSelectionOnAfterSetDefaultRangeOnSelectedDimTable(var SelectedDimension: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDimSelectionOnBeforeSelectedDimInsert(var SelectedDimension: Record "Selected Dimension"; ObjectType: Integer; ObjectID: Integer)
    begin
    end;
}

