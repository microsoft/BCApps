// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;

page 567 "Dimension Selection-Change"
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
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that this dimension will be included.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies a description of the dimension.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value that the analysis view is based on.';
                }
                field("New Dimension Value Code"; Rec."New Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the new dimension value to that you are changing to.';
                }
            }
        }
    }

    actions
    {
    }

    procedure GetDimSelBuf(var TheDimSelectionBuf: Record "Dimension Selection Buffer")
    begin
        TheDimSelectionBuf.DeleteAll();
        if Rec.Find('-') then
            repeat
                TheDimSelectionBuf := Rec;
                TheDimSelectionBuf.Insert();
            until Rec.Next() = 0;
    end;

    procedure InsertDimSelBuf(NewSelected: Boolean; NewCode: Text[30]; NewDescription: Text[30]; NewNewDimValueCode: Code[20]; NewDimValueFilter: Text[250])
    var
        Dim: Record Dimension;
        GLAcc: Record "G/L Account";
        BusinessUnit: Record "Business Unit";
    begin
        if NewDescription = '' then
            if Dim.Get(NewCode) then
                NewDescription := Dim.Name;

        Rec.Init();
        Rec.Selected := NewSelected;
        Rec.Code := NewCode;
        Rec.Description := NewDescription;
        if NewSelected then begin
            Rec."New Dimension Value Code" := NewNewDimValueCode;
            Rec."Dimension Value Filter" := NewDimValueFilter;
        end;
        case Rec.Code of
            GLAcc.TableCaption:
                Rec."Filter Lookup Table No." := Database::"G/L Account";
            BusinessUnit.TableCaption:
                Rec."Filter Lookup Table No." := Database::"Business Unit";
        end;
        Rec.Insert();
    end;
}

