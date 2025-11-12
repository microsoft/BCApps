// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Intercompany.Dimension;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Globalization;

table 348 Dimension
{
    Caption = 'Dimension';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Dimension List";
    LookupPageID = "Dimension List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                BusUnit: Record "Business Unit";
                Item: Record Item;
                Location: Record Location;
            begin
                if (UpperCase(Code) = UpperCase(GLAcc.TableCaption())) or
                   (UpperCase(Code) = UpperCase(BusUnit.TableCaption())) or
                   (UpperCase(Code) = UpperCase(Item.TableCaption())) or
                   (UpperCase(Code) = UpperCase(Location.TableCaption())) or
                   (UpperCase(Code) = UpperCase(Text006))
                then
                    Error(Text007, FieldCaption(Code), GLAcc.TableCaption(), BusUnit.TableCaption(), Item.TableCaption(), Location.TableCaption());

                UpdateText(Code, '', Name);
                UpdateText(Code, Text008, "Code Caption");
                UpdateText(Code, Text009, "Filter Caption");
            end;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Code Caption"; Text[80])
        {
            Caption = 'Code Caption';
        }
        field(4; "Filter Caption"; Text[80])
        {
            Caption = 'Filter Caption';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(7; "Consolidation Code"; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consolidation Code';
        }
        field(8; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';
            TableRelation = "IC Dimension";

            trigger OnValidate()
            var
                DimensionValue: Record "Dimension Value";
            begin
                if "Map-to IC Dimension Code" <> xRec."Map-to IC Dimension Code" then begin
                    DimensionValue.SetRange("Dimension Code", Code);
                    DimensionValue.ModifyAll("Map-to IC Dimension Code", "Map-to IC Dimension Code");
                    DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                end;
            end;
        }
        field(8001; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
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
        fieldgroup(DropDown; "Code", Name, Blocked)
        {
        }
        fieldgroup(Brick; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        DimVal.SetRange("Dimension Code", xRec.Code);
        if CheckIfDimUsed(xRec.Code, 0, '', '', 0) then begin
            if DimVal.FindSet() then
                repeat
                    if DimVal.CheckIfDimValueUsed() then
                        Error(Text000, GetCheckDimErr());
                until DimVal.Next() = 0;
            Error(Text001, GetCheckDimErr());
        end;
        if DimVal.FindSet() then
            repeat
                if DimVal.CheckIfDimValueUsed() then
                    Error(Text002);
            until DimVal.Next() = 0;

        DeleteRelatedRecords(Code);

        GLSetup.Get();
        case Code of
            GLSetup."Shortcut Dimension 3 Code":
                begin
                    GLSetup."Shortcut Dimension 3 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 4 Code":
                begin
                    GLSetup."Shortcut Dimension 4 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 5 Code":
                begin
                    GLSetup."Shortcut Dimension 5 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 6 Code":
                begin
                    GLSetup."Shortcut Dimension 6 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 7 Code":
                begin
                    GLSetup."Shortcut Dimension 7 Code" := '';
                    GLSetup.Modify();
                end;
            GLSetup."Shortcut Dimension 8 Code":
                begin
                    GLSetup."Shortcut Dimension 8 Code" := '';
                    GLSetup.Modify();
                end;
        end;

        RemoveICDimensionMappings();
    end;

    trigger OnInsert()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnModify()
    begin
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.RenameDimension(xRec.Code, Code);
        SetLastModifiedDateTime();
    end;

    var
        DefaultDim: Record "Default Dimension";
        DimVal: Record "Dimension Value";
        DimComb: Record "Dimension Combination";
        SelectedDim: Record "Selected Dimension";
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        DimTrans: Record "Dimension Translation";
        UsedAsGlobalDim: Boolean;
        UsedAsShortcutDim: Boolean;
        UsedAsBudgetDim: Boolean;
        UsedAsAnalysisViewDim: Boolean;
        UsedAsItemBudgetDim: Boolean;
        UsedAsItemAnalysisViewDim: Boolean;
        CheckDimErr: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1\This dimension is also used in posted or budget entries.\You cannot delete it.';
        Text001: Label '%1\You cannot delete it.';
#pragma warning restore AA0470
        Text002: Label 'You cannot delete this dimension value, because it has been used in one or more documents or budget entries.';
        Text006: Label 'Period';
#pragma warning disable AA0470
        Text007: Label '%1 can not be %2, %3, %4, %5 or Period. These names are used internally by the system.';
#pragma warning restore AA0470
        Text008: Label 'Code';
        Text009: Label 'Filter';
        Text010: Label 'This dimension is used in the following setup: ';
        Text011: Label 'General Ledger Setup, ';
        Text012: Label 'G/L Budget Names, ';
        Text013: Label 'Analysis View Card, ';
        Text014: Label 'Item Budget Names, ';
        Text015: Label 'Item Analysis View Card, ';
#pragma warning restore AA0074

    local procedure UpdateText("Code": Code[20]; AddText: Text[30]; var Text: Text[80])
    begin
        if Text = '' then begin
            Text := LowerCase(Code);
            Text[1] := Code[1];
            if AddText <> '' then
                Text := StrSubstNo('%1 %2', Text, AddText);
        end;
    end;

    local procedure DeleteRelatedRecords(DimensionCode: Code[20])
    begin
        OnBeforeDeleteRelatedRecords(DimensionCode);

        DefaultDim.SetRange("Dimension Code", DimensionCode);
        DefaultDim.DeleteAll(true);

        DimVal.SetRange("Dimension Code", DimensionCode);
        DimVal.DeleteAll(true);

        DimComb.SetRange("Dimension 1 Code", DimensionCode);
        DimComb.DeleteAll();

        DimComb.Reset();
        DimComb.SetRange("Dimension 2 Code", DimensionCode);
        DimComb.DeleteAll();

        SelectedDim.SetRange("Dimension Code", DimensionCode);
        SelectedDim.DeleteAll();

        AnalysisSelectedDim.SetRange("Dimension Code", DimensionCode);
        AnalysisSelectedDim.DeleteAll();

        DimTrans.SetRange(Code, DimensionCode);
        DimTrans.DeleteAll();

        OnAfterDeleteRelatedRecords(DimensionCode);
    end;

    procedure CheckIfDimUsed(DimChecked: Code[20]; DimTypeChecked: Option " ",Global1,Global2,Shortcut3,Shortcut4,Shortcut5,Shortcut6,Shortcut7,Shortcut8,Budget1,Budget2,Budget3,Budget4,Analysis1,Analysis2,Analysis3,Analysis4,ItemBudget1,ItemBudget2,ItemBudget3,ItemAnalysis1,ItemAnalysis2,ItemAnalysis3; BudgetNameChecked: Code[10]; AnalysisViewChecked: Code[10]; AnalysisAreaChecked: Integer): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        AnalysisView: Record "Analysis View";
        ItemBudgetName: Record "Item Budget Name";
        ItemAnalysisView: Record "Item Analysis View";
        CustomDimErr: Text;
        CheckAllDim: Boolean;
        CheckGlobalDim: Boolean;
        CheckShortcutDim: Boolean;
        CheckBudgetDim: Boolean;
        CheckAnalysisViewDim: Boolean;
        CheckItemBudgetDim: Boolean;
        CheckItemAnalysisViewDim: Boolean;
        UsedAsCustomDim: Boolean;
    begin
        if DimChecked = '' then
            exit;

        OnBeforeCheckIfDimUsed(DimChecked, DimTypeChecked, UsedAsCustomDim, CustomDimErr, AnalysisViewChecked, AnalysisAreaChecked);

        CheckAllDim := DimTypeChecked in [DimTypeChecked::" "];
        CheckGlobalDim := DimTypeChecked in [DimTypeChecked::Global1, DimTypeChecked::Global2];
        CheckShortcutDim := DimTypeChecked in [DimTypeChecked::Shortcut3, DimTypeChecked::Shortcut4, DimTypeChecked::Shortcut5,
                                               DimTypeChecked::Shortcut6, DimTypeChecked::Shortcut7, DimTypeChecked::Shortcut8];
        CheckBudgetDim := DimTypeChecked in [DimTypeChecked::Budget1, DimTypeChecked::Budget2, DimTypeChecked::Budget3,
                                             DimTypeChecked::Budget4];
        CheckAnalysisViewDim := DimTypeChecked in [DimTypeChecked::Analysis1, DimTypeChecked::Analysis2, DimTypeChecked::Analysis3,
                                                   DimTypeChecked::Analysis4];
        CheckItemBudgetDim :=
          DimTypeChecked in [DimTypeChecked::ItemBudget1, DimTypeChecked::ItemBudget2, DimTypeChecked::ItemBudget3];
        CheckItemAnalysisViewDim :=
          DimTypeChecked in [DimTypeChecked::ItemAnalysis1, DimTypeChecked::ItemAnalysis2, DimTypeChecked::ItemAnalysis3];

        UsedAsGlobalDim := false;
        UsedAsShortcutDim := false;
        UsedAsBudgetDim := false;
        UsedAsAnalysisViewDim := false;
        UsedAsItemBudgetDim := false;
        UsedAsItemAnalysisViewDim := false;

        if CheckAllDim or CheckGlobalDim or CheckShortcutDim or CheckBudgetDim or CheckItemBudgetDim then begin
            GLSetup.Get();
            if (DimTypeChecked <> DimTypeChecked::Global1) and
               (DimChecked = GLSetup."Global Dimension 1 Code")
            then
                UsedAsGlobalDim := true;
            if (DimTypeChecked <> DimTypeChecked::Global2) and
               (DimChecked = GLSetup."Global Dimension 2 Code")
            then
                UsedAsGlobalDim := true;
        end;

        if CheckGlobalDim or CheckShortcutDim then begin
            if (DimTypeChecked <> DimTypeChecked::Shortcut3) and
               (DimChecked = GLSetup."Shortcut Dimension 3 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut4) and
               (DimChecked = GLSetup."Shortcut Dimension 4 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut5) and
               (DimChecked = GLSetup."Shortcut Dimension 5 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut6) and
               (DimChecked = GLSetup."Shortcut Dimension 6 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut7) and
               (DimChecked = GLSetup."Shortcut Dimension 7 Code")
            then
                UsedAsShortcutDim := true;
            if (DimTypeChecked <> DimTypeChecked::Shortcut8) and
               (DimChecked = GLSetup."Shortcut Dimension 8 Code")
            then
                UsedAsShortcutDim := true;
        end;

        if CheckAllDim or CheckGlobalDim or CheckBudgetDim then begin
            if BudgetNameChecked <> '' then
                GLBudgetName.SetRange(Name, BudgetNameChecked);
            if GLBudgetName.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::Budget1) and
                       (DimChecked = GLBudgetName."Budget Dimension 1 Code")
                    then
                        UsedAsBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Budget2) and
                       (DimChecked = GLBudgetName."Budget Dimension 2 Code")
                    then
                        UsedAsBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Budget3) and
                       (DimChecked = GLBudgetName."Budget Dimension 3 Code")
                    then
                        UsedAsBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Budget4) and
                       (DimChecked = GLBudgetName."Budget Dimension 4 Code")
                    then
                        UsedAsBudgetDim := true;
                until GLBudgetName.Next() = 0;
        end;

        if CheckAllDim or CheckGlobalDim or CheckItemBudgetDim then begin
            if BudgetNameChecked <> '' then begin
                ItemBudgetName.SetRange("Analysis Area", AnalysisAreaChecked);
                ItemBudgetName.SetRange(Name, BudgetNameChecked);
            end;
            if ItemBudgetName.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::ItemBudget1) and
                       (DimChecked = ItemBudgetName."Budget Dimension 1 Code")
                    then
                        UsedAsItemBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemBudget2) and
                       (DimChecked = ItemBudgetName."Budget Dimension 2 Code")
                    then
                        UsedAsItemBudgetDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemBudget3) and
                       (DimChecked = ItemBudgetName."Budget Dimension 3 Code")
                    then
                        UsedAsItemBudgetDim := true;
                until ItemBudgetName.Next() = 0;
        end;

        CheckIfDimUsedAsAnalysisViewDim(AnalysisView, DimChecked, DimTypeChecked, CheckAllDim, CheckAnalysisViewDim, AnalysisViewChecked);

        if CheckAllDim or CheckItemAnalysisViewDim then begin
            if AnalysisViewChecked <> '' then begin
                ItemAnalysisView.SetRange("Analysis Area", AnalysisAreaChecked);
                ItemAnalysisView.SetRange(Code, AnalysisViewChecked);
            end;
            if ItemAnalysisView.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::ItemAnalysis1) and
                       (DimChecked = ItemAnalysisView."Dimension 1 Code")
                    then
                        UsedAsItemAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemAnalysis2) and
                       (DimChecked = ItemAnalysisView."Dimension 2 Code")
                    then
                        UsedAsItemAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::ItemAnalysis3) and
                       (DimChecked = ItemAnalysisView."Dimension 3 Code")
                    then
                        UsedAsItemAnalysisViewDim := true;
                until ItemAnalysisView.Next() = 0;
        end;

        if UsedAsGlobalDim or
           UsedAsShortcutDim or
           UsedAsBudgetDim or
           UsedAsAnalysisViewDim or
           UsedAsItemBudgetDim or
           UsedAsItemAnalysisViewDim or
           UsedAsCustomDim
        then begin
            MakeCheckDimErr(CustomDimErr);
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckIfDimUsedAsAnalysisViewDim(AnalysisView: Record "Analysis View"; DimChecked: Code[20]; DimTypeChecked: Option " ",Global1,Global2,Shortcut3,Shortcut4,Shortcut5,Shortcut6,Shortcut7,Shortcut8,Budget1,Budget2,Budget3,Budget4,Analysis1,Analysis2,Analysis3,Analysis4,ItemBudget1,ItemBudget2,ItemBudget3,ItemAnalysis1,ItemAnalysis2,ItemAnalysis3; CheckAllDim: Boolean; CheckAnalysisViewDim: Boolean; AnalysisViewChecked: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfDimUsedAsAnalysisViewDim(AnalysisView, DimChecked, DimTypeChecked, CheckAllDim, CheckAnalysisViewDim, AnalysisViewChecked, UsedAsAnalysisViewDim, IsHandled);
        if IsHandled then
            exit;

        if CheckAllDim or CheckAnalysisViewDim then begin
            if AnalysisViewChecked <> '' then
                AnalysisView.SetRange(Code, AnalysisViewChecked);
            if AnalysisView.FindSet() then
                repeat
                    if (DimTypeChecked <> DimTypeChecked::Analysis1) and
                       (DimChecked = AnalysisView."Dimension 1 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Analysis2) and
                       (DimChecked = AnalysisView."Dimension 2 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Analysis3) and
                       (DimChecked = AnalysisView."Dimension 3 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                    if (DimTypeChecked <> DimTypeChecked::Analysis4) and
                       (DimChecked = AnalysisView."Dimension 4 Code")
                    then
                        UsedAsAnalysisViewDim := true;
                until AnalysisView.Next() = 0;
        end;
    end;

    local procedure MakeCheckDimErr(CustomDimErr: Text)
    begin
        CheckDimErr := Text010;
        if UsedAsGlobalDim or UsedAsShortcutDim then
            CheckDimErr := CheckDimErr + Text011;
        if UsedAsBudgetDim then
            CheckDimErr := CheckDimErr + Text012;
        if UsedAsAnalysisViewDim then
            CheckDimErr := CheckDimErr + Text013;
        if UsedAsItemBudgetDim then
            CheckDimErr := CheckDimErr + Text014;
        if UsedAsItemAnalysisViewDim then
            CheckDimErr := CheckDimErr + Text015;
        if CustomDimErr <> '' then
            CheckDimErr := CheckDimErr + CustomDimErr;
        CheckDimErr := CopyStr(CheckDimErr, 1, StrLen(CheckDimErr) - 2) + '.';
    end;

    procedure GetCheckDimErr(): Text[250]
    begin
        exit(CheckDimErr);
    end;

    procedure GetMLName(LanguageID: Integer): Text[30]
    begin
        GetDimTrans(LanguageID);
        exit(DimTrans.Name);
    end;

    procedure GetMLCodeCaption(LanguageID: Integer): Text[80]
    begin
        GetDimTrans(LanguageID);
        exit(DimTrans."Code Caption");
    end;

    procedure GetMLFilterCaption(LanguageID: Integer): Text[80]
    begin
        GetDimTrans(LanguageID);
        exit(DimTrans."Filter Caption");
    end;

    procedure SetMLName(NewMLName: Text[30]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if Name <> NewMLName then begin
                Name := NewMLName;
                Modify();
            end;
        end else begin
            InsertDimTrans(LanguageID);
            if DimTrans.Name <> NewMLName then begin
                DimTrans.Name := NewMLName;
                DimTrans.Modify();
            end;
        end;
    end;

    procedure SetMLCodeCaption(NewMLCodeCaption: Text[80]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if "Code Caption" <> NewMLCodeCaption then begin
                "Code Caption" := NewMLCodeCaption;
                Modify();
            end;
        end else begin
            InsertDimTrans(LanguageID);
            if DimTrans."Code Caption" <> NewMLCodeCaption then begin
                DimTrans."Code Caption" := NewMLCodeCaption;
                DimTrans.Modify();
            end;
        end;
    end;

    procedure SetMLFilterCaption(NewMLFilterCaption: Text[80]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if "Filter Caption" <> NewMLFilterCaption then begin
                "Filter Caption" := NewMLFilterCaption;
                Modify();
            end;
        end else begin
            InsertDimTrans(LanguageID);
            if DimTrans."Filter Caption" <> NewMLFilterCaption then begin
                DimTrans."Filter Caption" := NewMLFilterCaption;
                DimTrans.Modify();
            end;
        end;
    end;

    procedure SetMLDescription(NewMLDescription: Text[100]; LanguageID: Integer)
    begin
        if IsApplicationLanguage(LanguageID) then begin
            if Description <> NewMLDescription then begin
                Description := NewMLDescription;
                Modify();
            end;
        end else
            InsertDimTrans(LanguageID);
    end;

    local procedure GetDimTrans(LanguageID: Integer)
    begin
        if (DimTrans.Code <> Code) or (DimTrans."Language ID" <> LanguageID) then
            if not DimTrans.Get(Code, LanguageID) then begin
                DimTrans.Init();
                DimTrans.Code := Code;
                DimTrans."Language ID" := LanguageID;
                DimTrans.Name := Name;
                DimTrans."Code Caption" := "Code Caption";
                DimTrans."Filter Caption" := "Filter Caption";
            end;
    end;

    local procedure InsertDimTrans(LanguageID: Integer)
    begin
        if not DimTrans.Get(Code, LanguageID) then begin
            DimTrans.Init();
            DimTrans.Code := Code;
            DimTrans."Language ID" := LanguageID;
            DimTrans.Insert();
        end;
    end;

    local procedure IsApplicationLanguage(LanguageID: Integer): Boolean
    var
        Language: Codeunit Language;
    begin
        exit(LanguageID = Language.GetDefaultApplicationLanguageId());
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    local procedure RemoveICDimensionMappings()
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
    begin
        ICDimension.SetRange("Map-to Dimension Code", Rec."Code");
        if not ICDimension.IsEmpty() then begin
            ICDimension.FindSet();
            repeat
                ICDimensionValue.SetRange("Dimension Code", ICDimension.Code);
                if not ICDimensionValue.IsEmpty() then begin
                    ICDimensionValue.FindSet();
                    repeat
                        if ICDimensionValue."Map-to Dimension Code" <> '' then begin
                            ICDimensionValue."Map-to Dimension Code" := '';
                            ICDimensionValue."Map-to Dimension Value Code" := '';
                            ICDimensionValue.Modify();
                        end;
                    until ICDimensionValue.Next() = 0;
                end;
                ICDimension."Map-to Dimension Code" := '';
                ICDimension.Modify();
            until ICDimension.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelatedRecords(DimensionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelatedRecords(DimensionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDimUsed(DimChecked: Code[20]; DimTypeChecked: Option " ",Global1,Global2,Shortcut3,Shortcut4,Shortcut5,Shortcut6,Shortcut7,Shortcut8,Budget1,Budget2,Budget3,Budget4,Analysis1,Analysis2,Analysis3,Analysis4,ItemBudget1,ItemBudget2,ItemBudget3,ItemAnalysis1,ItemAnalysis2,ItemAnalysis3; var UsedAsCustomDim: Boolean; var CustomDimErr: Text; AnalysisViewChecked: Code[10]; AnalysisAreaChecked: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfDimUsedAsAnalysisViewDim(AnalysisView: Record "Analysis View"; DimChecked: Code[20]; DimTypeChecked: Option " ",Global1,Global2,Shortcut3,Shortcut4,Shortcut5,Shortcut6,Shortcut7,Shortcut8,Budget1,Budget2,Budget3,Budget4,Analysis1,Analysis2,Analysis3,Analysis4,ItemBudget1,ItemBudget2,ItemBudget3,ItemAnalysis1,ItemAnalysis2,ItemAnalysis3; CheckAllDim: Boolean; CheckAnalysisViewDim: Boolean; AnalysisViewChecked: Code[10]; var UsedAsAnalysisViewDim: Boolean; var IsHandled: Boolean)
    begin
    end;
}
