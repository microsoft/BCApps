// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 7158 "Analysis Dim. Selection Buffer"
{
    Caption = 'Analysis Dim. Selection Buffer';
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
            TableRelation = if (Code = const('Item')) Item."No."
            else
            if (Code = const('Location')) Location.Code
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
            TableRelation = if (Code = const('Item')) Item."No."
            else
            if (Code = const('Location')) Location.Code
            else
            "Dimension Value".Code where("Dimension Code" = field(Code));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Selected := (Level <> Level::" ") or ("Dimension Value Filter" <> '');
            end;
        }
        field(6; Level; Option)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Level 1,Level 2,Level 3';
            OptionMembers = " ","Level 1","Level 2","Level 3";

            trigger OnValidate()
            begin
                Selected := (Level <> Level::" ") or ("Dimension Value Filter" <> '');
            end;
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
        AnalysisSelectedDim: Record "Analysis Selected Dimension";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Another user has modified the selected dimensions for the %1 field after you retrieved it from the database.\';
        Text002: Label 'Enter your changes again in the Dimension Selection window by clicking the AssistButton in the %1 field. ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CompareDimText(ObjectType: Integer; ObjectID: Integer; AnalysisArea: Integer; AnalysisViewCode: Code[10]; SelectedDimText: Text[250]; DimTextFieldName: Text[100])
    var
        AnalysisSelectedDim2: Record "Analysis Selected Dimension";
        SelectedDimTextFromDb: Text[250];
    begin
        SelectedDimTextFromDb := '';
        AnalysisSelectedDim2.SetCurrentKey(
          "User ID", "Object Type", "Object ID", "Analysis Area", "Analysis View Code", Level, "Dimension Code");
        AnalysisSelectedDim2.SetRange("User ID", UserId);
        AnalysisSelectedDim2.SetRange("Object Type", ObjectType);
        AnalysisSelectedDim2.SetRange("Object ID", ObjectID);
        AnalysisSelectedDim2.SetRange("Analysis Area", AnalysisArea);
        AnalysisSelectedDim2.SetRange("Analysis View Code", AnalysisViewCode);
        if AnalysisSelectedDim2.Find('-') then
            repeat
                AddDimCodeToText(AnalysisSelectedDim2."Dimension Code", SelectedDimTextFromDb);
            until AnalysisSelectedDim2.Next() = 0;
        if SelectedDimTextFromDb <> SelectedDimText then
            Error(
              Text000 +
              Text002,
              DimTextFieldName);
    end;

    local procedure AddDimCodeToText(DimCode: Code[20]; var Text: Text[250])
    begin
        if Text = '' then
            Text := DimCode
        else
            if (StrLen(Text) + StrLen(DimCode)) <= (MaxStrLen(Text) - 4) then
                Text := StrSubstNo('%1; %2', Text, DimCode)
            else
                Text := StrSubstNo('%1;...', Text)
    end;

    procedure SetDimSelection(ObjectType: Integer; ObjectID: Integer; AnalysisArea: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250]; var AnalysisDimSelBuf: Record "Analysis Dim. Selection Buffer")
    begin
        AnalysisSelectedDim.SetRange("User ID", UserId);
        AnalysisSelectedDim.SetRange("Object Type", ObjectType);
        AnalysisSelectedDim.SetRange("Object ID", ObjectID);
        AnalysisSelectedDim.SetRange("Analysis Area", AnalysisArea);
        AnalysisSelectedDim.SetRange("Analysis View Code", AnalysisViewCode);
        AnalysisSelectedDim.DeleteAll();
        SelectedDimText := '';
        AnalysisDimSelBuf.SetCurrentKey(Level, Code);
        AnalysisDimSelBuf.SetRange(Selected, true);
        if AnalysisDimSelBuf.Find('-') then
            repeat
                AnalysisSelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(AnalysisSelectedDim."User ID"));
                AnalysisSelectedDim."Object Type" := ObjectType;
                AnalysisSelectedDim."Object ID" := ObjectID;
                AnalysisSelectedDim."Analysis Area" := "Analysis Area Type".FromInteger(AnalysisArea);
                AnalysisSelectedDim."Analysis View Code" := AnalysisViewCode;
                AnalysisSelectedDim."Dimension Code" := AnalysisDimSelBuf.Code;
                AnalysisSelectedDim."New Dimension Value Code" := AnalysisDimSelBuf."New Dimension Value Code";
                AnalysisSelectedDim."Dimension Value Filter" := AnalysisDimSelBuf."Dimension Value Filter";
                AnalysisSelectedDim.Level := AnalysisDimSelBuf.Level;
                AnalysisSelectedDim.Insert();
                AddDimCodeToText(AnalysisSelectedDim."Dimension Code", SelectedDimText);
            until AnalysisDimSelBuf.Next() = 0;
    end;

    procedure SetDimSelectionLevel(ObjectType: Integer; ObjectID: Integer; AnalysisArea: Integer; AnalysisViewCode: Code[10]; var SelectedDimText: Text[250])
    var
        Item: Record Item;
        Location: Record Location;
        ItemAnalysisView: Record "Item Analysis View";
        Dim: Record Dimension;
        TempAnalysisDimSelBuf: Record "Analysis Dim. Selection Buffer" temporary;
        AnalysisDimSelectionLevel: Page "Analysis Dim. Selection-Level";
    begin
        Clear(AnalysisDimSelectionLevel);
        if ItemAnalysisView.Get(AnalysisArea, AnalysisViewCode) then begin
            if Dim.Get(ItemAnalysisView."Dimension 1 Code") then
                AnalysisDimSelectionLevel.InsertDimSelBuf(
                  AnalysisSelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  AnalysisSelectedDim."Dimension Value Filter", AnalysisSelectedDim.Level);

            if Dim.Get(ItemAnalysisView."Dimension 2 Code") then
                AnalysisDimSelectionLevel.InsertDimSelBuf(
                  AnalysisSelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  AnalysisSelectedDim."Dimension Value Filter", AnalysisSelectedDim.Level);

            if Dim.Get(ItemAnalysisView."Dimension 3 Code") then
                AnalysisDimSelectionLevel.InsertDimSelBuf(
                  AnalysisSelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  AnalysisSelectedDim."Dimension Value Filter", AnalysisSelectedDim.Level);

            AnalysisDimSelectionLevel.InsertDimSelBuf(
              AnalysisSelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Item.TableCaption()),
              Item.TableCaption(), Item.TableCaption(),
              AnalysisSelectedDim."Dimension Value Filter", AnalysisSelectedDim.Level);
            AnalysisDimSelectionLevel.InsertDimSelBuf(
              AnalysisSelectedDim.Get(UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Location.TableCaption()),
              Location.TableCaption(), Location.TableCaption(),
              AnalysisSelectedDim."Dimension Value Filter", AnalysisSelectedDim.Level);
        end;

        AnalysisDimSelectionLevel.LookupMode := true;
        if AnalysisDimSelectionLevel.RunModal() = ACTION::LookupOK then begin
            AnalysisDimSelectionLevel.GetDimSelBuf(TempAnalysisDimSelBuf);
            SetDimSelection(ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, SelectedDimText, TempAnalysisDimSelBuf);
        end;
    end;
}

