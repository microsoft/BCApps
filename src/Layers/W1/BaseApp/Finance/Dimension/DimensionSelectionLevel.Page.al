// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

page 564 "Dimension Selection-Level"
{
    Caption = 'Dimension Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Dimension Selection Buffer";
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
                    ToolTip = 'Specifies the level for the selected dimension.';

                    trigger OnValidate()
                    var
                        DimSelectBuffer: Record "Dimension Selection Buffer";
                        LevelExists: Boolean;
                    begin
                        if Rec.Level <> Rec.Level::" " then begin
                            DimSelectBuffer.Copy(Rec);
                            Rec.Reset();
                            Rec.SetFilter(Code, '<>%1', DimSelectBuffer.Code);
                            Rec.SetRange(Level, DimSelectBuffer.Level);
                            LevelExists := not Rec.IsEmpty();
                            Rec.Copy(DimSelectBuffer);

                            if LevelExists then
                                Error(Text000, Rec.FieldCaption(Level));
                        end;
                    end;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the selected dimension.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a description of the selected dimension.';
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

    procedure GetDimSelBuf(var TheDimSelectionBuf: Record "Dimension Selection Buffer")
    begin
        TheDimSelectionBuf.DeleteAll();
        if Rec.Find('-') then
            repeat
                TheDimSelectionBuf := Rec;
                TheDimSelectionBuf.Insert();
            until Rec.Next() = 0;
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewDimValueFilter: Text[250]; NewLevel: Option)
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
        CFAcc: Record "Cash Flow Account";
        CashFlowForecast: Record "Cash Flow Forecast";
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
        case Rec.Code of
            GLAcc.TableCaption:
                Rec."Filter Lookup Table No." := Database::"G/L Account";
            BusinessUnit.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Business Unit";
            CFAcc.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Cash Flow Account";
            CashFlowForecast.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Cash Flow Forecast";
        end;
        Rec.Insert();
    end;
}

