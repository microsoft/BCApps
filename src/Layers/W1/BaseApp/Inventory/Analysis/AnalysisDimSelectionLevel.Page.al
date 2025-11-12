// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;

page 7161 "Analysis Dim. Selection-Level"
{
    Caption = 'Analysis Dim. Selection-Level';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Analysis Dim. Selection Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Level; Rec.Level)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the level for the selected dimension for analysis.';

                    trigger OnValidate()
                    var
                        xAnalysisDimSelBuf: Record "Analysis Dim. Selection Buffer";
                        HasError: Boolean;
                    begin
                        if Rec.Level <> Rec.Level::" " then begin
                            xAnalysisDimSelBuf.Copy(Rec);
                            Rec.Reset();
                            Rec.SetFilter(Code, '<>%1', xAnalysisDimSelBuf.Code);
                            Rec.SetRange(Level, xAnalysisDimSelBuf.Level);
                            HasError := not Rec.IsEmpty();
                            Rec.Copy(xAnalysisDimSelBuf);
                            if HasError then
                                Error(Text000, Rec.FieldCaption(Level));
                        end;
                    end;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a code for the selection.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the selection.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value that the analysis view is based on.';
                }
            }
        }
    }

    actions
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'This %1 already exists.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetDimSelBuf(var AnalysisDimSelBuf: Record "Analysis Dim. Selection Buffer")
    begin
        AnalysisDimSelBuf.DeleteAll();
        if Rec.FindSet() then
            repeat
                AnalysisDimSelBuf := Rec;
                AnalysisDimSelBuf.Insert();
            until Rec.Next() = 0;
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewDimValueFilter: Text[250]; NewLevel: Option)
    var
        Dim: Record Dimension;
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.GetMLName(GlobalLanguage);

        Rec.Init();
        Rec.Selected := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        if NewSelected then begin
            Rec."Dimension Value Filter" := NewDimValueFilter;
            Rec.Level := NewLevel;
        end;
        Rec.Insert();
    end;
}

