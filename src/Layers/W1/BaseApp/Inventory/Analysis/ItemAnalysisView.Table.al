// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

table 7152 "Item Analysis View"
{
    Caption = 'Item Analysis View';
    DataCaptionFields = "Analysis Area", "Code", Name;
    LookupPageID = "Item Analysis View List";
    Permissions = TableData "Item Analysis View Entry" = rimd,
                  TableData "Item Analysis View Budg. Entry" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Last Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
            Editable = false;
        }
        field(5; "Last Budget Entry No."; Integer)
        {
            Caption = 'Last Budget Entry No.';
            Editable = false;
        }
        field(6; "Last Date Updated"; Date)
        {
            Caption = 'Last Date Updated';
            Editable = false;
        }
        field(7; "Update on Posting"; Boolean)
        {
            Caption = 'Update on Posting';
            Editable = false;
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';

            trigger OnValidate()
            begin
                if not Blocked and "Refresh When Unblocked" then begin
                    ValidateDelete(FieldCaption(Blocked));
                    ItemAnalysisViewReset();
                    "Refresh When Unblocked" := false;
                end;
            end;
        }
        field(9; "Item Filter"; Code[250])
        {
            Caption = 'Item Filter';
            TableRelation = Item;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                ItemAnalysisViewEntry: Record "Item Analysis View Entry";
                ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
                Item: Record Item;
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Item Filter" = '') and ("Item Filter" <> '') then begin
                    ValidateModify(FieldCaption("Item Filter"));
                    Item.SetFilter("No.", "Item Filter");
                    if Item.Find('-') then
                        repeat
                            Item.Mark := true;
                        until Item.Next() = 0;
                    Item.SetRange("No.");
                    if Item.Find('-') then
                        repeat
                            if not Item.Mark() then begin
                                ItemAnalysisViewEntry.SetRange("Analysis Area", "Analysis Area");
                                ItemAnalysisViewEntry.SetRange("Analysis View Code", Code);
                                ItemAnalysisViewEntry.SetRange("Item No.", Item."No.");
                                ItemAnalysisViewEntry.DeleteAll();
                                ItemAnalysisViewBudgetEntry.SetRange("Analysis Area", "Analysis Area");
                                ItemAnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                                ItemAnalysisViewBudgetEntry.SetRange("Item No.", Item."No.");
                                ItemAnalysisViewBudgetEntry.DeleteAll();
                            end;
                        until Item.Next() = 0;
                end;
                if ("Last Entry No." <> 0) and ("Item Filter" <> xRec."Item Filter") and (xRec."Item Filter" <> '') then begin
                    ValidateDelete(FieldCaption("Item Filter"));
                    ItemAnalysisViewReset();
                end;
            end;
        }
        field(10; "Location Filter"; Code[250])
        {
            Caption = 'Location Filter';
            TableRelation = Location;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Location: Record Location;
                TempLocation: Record Location temporary;
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and (xRec."Location Filter" = '') and
                   ("Location Filter" <> xRec."Location Filter")
                then begin
                    ValidateModify(FieldCaption("Location Filter"));
                    if Location.Find('-') then
                        repeat
                            TempLocation := Location;
                            TempLocation.Insert();
                        until Location.Next() = 0;
                    TempLocation.Init();
                    TempLocation.Code := '';
                    TempLocation.Insert();
                    TempLocation.SetFilter(Code, "Location Filter");
                    TempLocation.DeleteAll();
                    TempLocation.SetRange(Code);
                    if TempLocation.Find('-') then
                        repeat
                            ItemAnalysisViewEntry.SetRange("Analysis Area", "Analysis Area");
                            ItemAnalysisViewEntry.SetRange("Analysis View Code", Code);
                            ItemAnalysisViewEntry.SetRange("Location Code", TempLocation.Code);
                            ItemAnalysisViewEntry.DeleteAll();
                            ItemAnalysisViewBudgetEntry.SetRange("Analysis Area", "Analysis Area");
                            ItemAnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                            ItemAnalysisViewBudgetEntry.SetRange("Location Code", TempLocation.Code);
                            ItemAnalysisViewBudgetEntry.DeleteAll();
                        until TempLocation.Next() = 0
                end;
                if ("Last Entry No." <> 0) and (xRec."Location Filter" <> '') and
                   ("Location Filter" <> xRec."Location Filter")
                then begin
                    ValidateDelete(FieldCaption("Location Filter"));
                    ItemAnalysisViewReset();
                end;
            end;
        }
        field(11; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Starting Date" <> xRec."Starting Date") then begin
                    ValidateDelete(FieldCaption("Starting Date"));
                    ItemAnalysisViewReset();
                end;
            end;
        }
        field(12; "Date Compression"; Option)
        {
            Caption = 'Date Compression';
            InitValue = Day;
            OptionCaption = 'None,Day,Week,Month,Quarter,Year,Period';
            OptionMembers = "None",Day,Week,Month,Quarter,Year,Period;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and ("Date Compression" <> xRec."Date Compression") then begin
                    ValidateDelete(FieldCaption("Date Compression"));
                    ItemAnalysisViewReset();
                end;
            end;
        }
        field(13; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 1 Code", 20, '', Code, "Analysis Area".AsInteger()) then
                    Error(Text000, Dim.GetCheckDimErr());
                ModifyDim(FieldCaption("Dimension 1 Code"), "Dimension 1 Code", xRec."Dimension 1 Code");
                Modify();
            end;
        }
        field(14; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 2 Code", 21, '', Code, "Analysis Area".AsInteger()) then
                    Error(Text000, Dim.GetCheckDimErr());
                ModifyDim(FieldCaption("Dimension 2 Code"), "Dimension 2 Code", xRec."Dimension 2 Code");
                Modify();
            end;
        }
        field(15; "Dimension 3 Code"; Code[20])
        {
            Caption = 'Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if Dim.CheckIfDimUsed("Dimension 3 Code", 22, '', Code, "Analysis Area".AsInteger()) then
                    Error(Text000, Dim.GetCheckDimErr());
                ModifyDim(FieldCaption("Dimension 3 Code"), "Dimension 3 Code", xRec."Dimension 3 Code");
                Modify();
            end;
        }
        field(17; "Include Budgets"; Boolean)
        {
            AccessByPermission = TableData "Item Budget Name" = R;
            Caption = 'Include Budgets';

            trigger OnValidate()
            begin
                TestField(Blocked, false);
                if ("Last Entry No." <> 0) and xRec."Include Budgets" and not "Include Budgets" then begin
                    ValidateDelete(FieldCaption("Include Budgets"));
                    AnalysisviewBudgetReset();
                end;
            end;
        }
        field(18; "Refresh When Unblocked"; Boolean)
        {
            Caption = 'Refresh When Unblocked';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
    begin
        ItemAnalysisViewReset();
        ItemAnalysisViewFilter.SetRange("Analysis Area", "Analysis Area");
        ItemAnalysisViewFilter.SetRange("Analysis View Code", Code);
        ItemAnalysisViewFilter.DeleteAll();
    end;

    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        NewItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
        NewItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
        Dim: Record Dimension;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1\You cannot use the same dimension twice in the same analysis view.';
        Text001: Label 'The dimension %1 is used in the analysis view %2 %3.';
#pragma warning restore AA0470
        Text002: Label ' You must therefore retain the dimension to keep consistency between the analysis view and the Item entries.';
        Text004: Label 'All analysis views must be updated with the latest Item entries and Item budget entries.';
        Text005: Label ' Both blocked and unblocked analysis views must be updated.';
        Text007: Label ' Note, you must remove the checkmark in the blocked field before updating the blocked analysis views.\';
#pragma warning disable AA0470
        Text008: Label 'Currently, %1 analysis views are not updated.';
#pragma warning restore AA0470
        Text009: Label ' Do you wish to update these analysis views?';
        Text010: Label 'All analysis views must be updated with the latest Item entries.';
#pragma warning disable AA0470
        Text011: Label 'If you change the contents of the %1 field, the analysis view entries will be deleted.';
        Text012: Label '\You will have to update again.\\Do you want to enter a new value in the %1 field?';
#pragma warning restore AA0470
        Text013: Label 'The update has been interrupted in response to the warning.';
#pragma warning disable AA0470
        Text014: Label 'If you change the contents of the %1 field, the analysis view entries will be changed as well.\\';
        Text015: Label 'Do you want to enter a new value in the %1 field?';
        Text017: Label 'When you enable %1, you need to update the analysis view. Do you want to update the analysis view now?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ModifyDim(DimFieldName: Text[100]; DimValue: Code[20]; xDimValue: Code[20])
    begin
        if ("Last Entry No." <> 0) and (DimValue <> xDimValue) then begin
            if DimValue <> '' then begin
                ValidateDelete(DimFieldName);
                ItemAnalysisViewReset();
            end;
            if DimValue = '' then begin
                ValidateModify(DimFieldName);
                case DimFieldName of
                    FieldCaption("Dimension 1 Code"):
                        begin
                            ItemAnalysisViewEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                            ItemAnalysisViewBudgetEntry.SetFilter("Dimension 1 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 2 Code"):
                        begin
                            ItemAnalysisViewEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                            ItemAnalysisViewBudgetEntry.SetFilter("Dimension 2 Value Code", '<>%1', '');
                        end;
                    FieldCaption("Dimension 3 Code"):
                        begin
                            ItemAnalysisViewEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                            ItemAnalysisViewBudgetEntry.SetFilter("Dimension 3 Value Code", '<>%1', '');
                        end;
                end;
                ItemAnalysisViewEntry.SetRange("Analysis Area", "Analysis Area");
                ItemAnalysisViewEntry.SetRange("Analysis View Code", Code);
                ItemAnalysisViewBudgetEntry.SetRange("Analysis Area", "Analysis Area");
                ItemAnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
                if ItemAnalysisViewEntry.Find('-') then
                    repeat
                        ItemAnalysisViewEntry.Delete();
                        NewItemAnalysisViewEntry := ItemAnalysisViewEntry;
                        case DimFieldName of
                            FieldCaption("Dimension 1 Code"):
                                NewItemAnalysisViewEntry."Dimension 1 Value Code" := '';
                            FieldCaption("Dimension 2 Code"):
                                NewItemAnalysisViewEntry."Dimension 2 Value Code" := '';
                            FieldCaption("Dimension 3 Code"):
                                NewItemAnalysisViewEntry."Dimension 3 Value Code" := '';
                        end;
                        InsertItemAnalysisViewEntry();
                    until ItemAnalysisViewEntry.Next() = 0;
                if ItemAnalysisViewBudgetEntry.Find('-') then
                    repeat
                        ItemAnalysisViewBudgetEntry.Delete();
                        NewItemAnalysisViewBudgetEntry := ItemAnalysisViewBudgetEntry;
                        case DimFieldName of
                            FieldCaption("Dimension 1 Code"):
                                NewItemAnalysisViewBudgetEntry."Dimension 1 Value Code" := '';
                            FieldCaption("Dimension 2 Code"):
                                NewItemAnalysisViewBudgetEntry."Dimension 2 Value Code" := '';
                            FieldCaption("Dimension 3 Code"):
                                NewItemAnalysisViewBudgetEntry."Dimension 3 Value Code" := '';
                        end;
                        InsertAnalysisViewBudgetEntry();
                    until ItemAnalysisViewBudgetEntry.Next() = 0;
            end;
        end;
    end;

    local procedure InsertItemAnalysisViewEntry()
    begin
        if not NewItemAnalysisViewEntry.Insert() then begin
            NewItemAnalysisViewEntry.Find();
            NewItemAnalysisViewEntry."Sales Amount (Actual)" :=
              NewItemAnalysisViewEntry."Sales Amount (Actual)" + ItemAnalysisViewEntry."Sales Amount (Actual)";
            NewItemAnalysisViewEntry."Cost Amount (Actual)" :=
              NewItemAnalysisViewEntry."Cost Amount (Actual)" + ItemAnalysisViewEntry."Cost Amount (Actual)";
            NewItemAnalysisViewEntry.Quantity :=
              NewItemAnalysisViewEntry.Quantity + ItemAnalysisViewEntry.Quantity;
            NewItemAnalysisViewEntry."Invoiced Quantity" :=
              NewItemAnalysisViewEntry."Invoiced Quantity" + ItemAnalysisViewEntry."Invoiced Quantity";
            NewItemAnalysisViewEntry.Modify();
        end;
    end;

    local procedure InsertAnalysisViewBudgetEntry()
    begin
        if not NewItemAnalysisViewBudgetEntry.Insert() then begin
            NewItemAnalysisViewBudgetEntry.Find();
            NewItemAnalysisViewBudgetEntry."Sales Amount" :=
              NewItemAnalysisViewBudgetEntry."Sales Amount" + ItemAnalysisViewBudgetEntry."Sales Amount";
            NewItemAnalysisViewBudgetEntry.Modify();
        end;
    end;

    procedure ItemAnalysisViewReset()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        ItemAnalysisViewEntry.SetRange("Analysis Area", "Analysis Area");
        ItemAnalysisViewEntry.SetRange("Analysis View Code", Code);
        ItemAnalysisViewEntry.DeleteAll();
        "Last Entry No." := 0;
        "Last Date Updated" := 0D;
        AnalysisviewBudgetReset();
    end;

    procedure CheckDimensionsAreRetained(ObjectType: Integer; ObjectID: Integer; OnlyIfIncludeBudgets: Boolean)
    begin
        Reset();
        if OnlyIfIncludeBudgets then
            SetRange("Include Budgets", true);
        if Find('-') then
            repeat
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 1 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 2 Code", Code, Name);
                CheckDimIsRetained(ObjectType, ObjectID, "Dimension 3 Code", Code, Name);
            until Next() = 0;
    end;

    local procedure CheckDimIsRetained(ObjectType: Integer; ObjectID: Integer; DimCode: Code[20]; AnalysisViewCode: Code[10]; AnalysisViewName: Text[50])
    var
        SelectedDim: Record "Selected Dimension";
    begin
        if DimCode <> '' then
            if not SelectedDim.Get(UserId, ObjectType, ObjectID, '', DimCode) then
                Error(
                  Text001 +
                  Text002,
                  DimCode, AnalysisViewCode, AnalysisViewName);
    end;

    procedure CheckViewsAreUpdated()
    var
        ValueEntry: Record "Value Entry";
        ItemBudgetEntry: Record "Item Budget Entry";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        NoNotUpdated: Integer;
    begin
        if ValueEntry.FindLast() or ItemBudgetEntry.FindLast() then begin
            NoNotUpdated := 0;
            Reset();
            if Find('-') then
                repeat
                    if ("Last Entry No." < ValueEntry."Entry No.") or
                       "Include Budgets" and ("Last Budget Entry No." < ItemBudgetEntry."Entry No.")
                    then
                        NoNotUpdated := NoNotUpdated + 1;
                until Next() = 0;
            if NoNotUpdated > 0 then
                if Confirm(
                     Text004 +
                     Text005 +
                     Text007 +
                     Text008 +
                     Text009, true, NoNotUpdated)
                then begin
                    if Find('-') then
                        repeat
                            if Blocked then begin
                                "Refresh When Unblocked" := true;
                                "Last Budget Entry No." := 0;
                                Modify();
                            end else
                                UpdateItemAnalysisView.Update(Rec, 2, true);
                        until Next() = 0;
                end else
                    Error(Text010);
        end;
    end;

    procedure ValidateDelete(FieldName: Text)
    var
        Question: Text;
    begin
        Question := StrSubstNo(Text011 + Text012, FieldName);
        if not Confirm(Question, true) then
            Error(Text013);
    end;

    local procedure AnalysisviewBudgetReset()
    var
        ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
    begin
        ItemAnalysisViewBudgetEntry.SetRange("Analysis Area", "Analysis Area");
        ItemAnalysisViewBudgetEntry.SetRange("Analysis View Code", Code);
        ItemAnalysisViewBudgetEntry.DeleteAll();
        "Last Budget Entry No." := 0;
    end;

    local procedure ValidateModify(FieldName: Text)
    var
        Question: Text;
    begin
        Question := StrSubstNo(Text014 + Text015, FieldName);
        if not Confirm(Question, true) then
            Error(Text013);
    end;

    procedure CopyAnalysisViewFilters(ObjectType: Integer; ObjectID: Integer; AnalysisArea: Integer; AnalysisViewCode: Code[10])
    var
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        Item: Record Item;
        Location: Record Location;
    begin
        if Get(AnalysisArea, AnalysisViewCode) then begin
            if "Item Filter" <> '' then
                if AnalysisSelectedDim.Get(
                     UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Item.TableCaption())
                then begin
                    if AnalysisSelectedDim."Dimension Value Filter" = '' then begin
                        AnalysisSelectedDim."Dimension Value Filter" := "Item Filter";
                        AnalysisSelectedDim.Modify();
                    end;
                end else begin
                    AnalysisSelectedDim.Init();
                    AnalysisSelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(AnalysisSelectedDim."User ID"));
                    AnalysisSelectedDim."Object Type" := ObjectType;
                    AnalysisSelectedDim."Object ID" := ObjectID;
                    AnalysisSelectedDim."Analysis Area" := "Analysis Area Type".FromInteger(AnalysisArea);
                    AnalysisSelectedDim."Analysis View Code" := AnalysisViewCode;
                    AnalysisSelectedDim."Dimension Code" := Item.TableCaption();
                    AnalysisSelectedDim."Dimension Value Filter" := "Item Filter";
                    AnalysisSelectedDim.Insert();
                end;
            if "Location Filter" <> '' then
                if AnalysisSelectedDim.Get(
                     UserId, ObjectType, ObjectID, AnalysisArea, AnalysisViewCode, Location.TableCaption())
                then begin
                    if AnalysisSelectedDim."Dimension Value Filter" = '' then begin
                        AnalysisSelectedDim."Dimension Value Filter" := "Location Filter";
                        AnalysisSelectedDim.Modify();
                    end;
                end else begin
                    AnalysisSelectedDim.Init();
                    AnalysisSelectedDim."User ID" := CopyStr(UserId(), 1, MaxStrLen(AnalysisSelectedDim."User ID"));
                    AnalysisSelectedDim."Object Type" := ObjectType;
                    AnalysisSelectedDim."Object ID" := ObjectID;
                    AnalysisSelectedDim."Analysis Area" := "Analysis Area Type".FromInteger(AnalysisArea);
                    AnalysisSelectedDim."Analysis View Code" := AnalysisViewCode;
                    AnalysisSelectedDim."Dimension Code" := Location.TableCaption();
                    AnalysisSelectedDim."Dimension Value Filter" := "Location Filter";
                    AnalysisSelectedDim.Insert();
                end;
        end;
    end;

    procedure SetUpdateOnPosting(NewUpdateOnPosting: Boolean)
    begin
        if "Update on Posting" = NewUpdateOnPosting then
            exit;

        if not "Update on Posting" and NewUpdateOnPosting then
            if not Confirm(StrSubstNo(Text017, FieldCaption("Update on Posting")), false) then
                exit;

        "Update on Posting" := NewUpdateOnPosting;
        if "Update on Posting" then begin
            Modify();
            CODEUNIT.Run(CODEUNIT::"Update Item Analysis View", Rec);
            Find();
        end;
    end;
}

