// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;

table 7153 "Item Analysis View Filter"
{
    Caption = 'Item Analysis View Filter';
    LookupPageID = "Item Analysis View Filter";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Item Analysis View".Code where("Analysis Area" = field("Analysis Area"),
                                                             Code = field("Analysis View Code"));
        }
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;
        }
        field(4; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis View Code", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemAnalysisView.Get("Analysis Area", "Analysis View Code");
        ItemAnalysisView.TestField(Blocked, false);
        ItemAnalysisView.ValidateDelete(ItemAnalysisViewFilter.FieldCaption("Dimension Code"));
        ItemAnalysisView.ItemAnalysisViewReset();
        ItemAnalysisView.Modify();
    end;

    trigger OnInsert()
    begin
        ValidateModifyFilter();
    end;

    trigger OnModify()
    begin
        ValidateModifyFilter();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename an %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ValidateModifyFilter()
    var
        ItemAnalysisView: Record "Item Analysis View";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemAnalysisView.Get("Analysis Area", "Analysis View Code");
        ItemAnalysisView.TestField(Blocked, false);
        if (ItemAnalysisView."Last Entry No." <> 0) and (xRec."Dimension Code" <> "Dimension Code") then begin
            ItemAnalysisView.ValidateDelete(ItemAnalysisViewFilter.FieldCaption("Dimension Code"));
            ItemAnalysisView.ItemAnalysisViewReset();
            "Dimension Value Filter" := '';
            ItemAnalysisView.Modify();
        end;
        if (ItemAnalysisView."Last Entry No." <> 0) and (xRec."Dimension Value Filter" <> "Dimension Value Filter") then begin
            ItemAnalysisView.ValidateDelete(ItemAnalysisViewFilter.FieldCaption("Dimension Value Filter"));
            ItemAnalysisView.ItemAnalysisViewReset();
            ItemAnalysisView.Modify();
        end;
    end;
}

