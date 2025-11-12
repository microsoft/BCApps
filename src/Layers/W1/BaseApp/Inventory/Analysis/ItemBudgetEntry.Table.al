// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 7134 "Item Budget Entry"
{
    Caption = 'Item Budget Entry';
    DrillDownPageID = "Item Budget Entries";
    LookupPageID = "Item Budget Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
            NotBlank = true;
        }
        field(3; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "Item Budget Name".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ClosingDates = true;
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(6; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';

            trigger OnValidate()
            begin
                if "Source Type" <> xRec."Source Type" then
                    Validate("Source No.", '');
            end;
        }
        field(7; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
        }
        field(11; "Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales Amount';
        }
        field(13; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(14; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(15; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                if "Global Dimension 1 Code" = '' then
                    exit;
                GetGLSetup();
                ValidateDimValue(GLSetup."Global Dimension 1 Code", "Global Dimension 1 Code");
            end;
        }
        field(16; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                if "Global Dimension 2 Code" = '' then
                    exit;
                GetGLSetup();
                ValidateDimValue(GLSetup."Global Dimension 2 Code", "Global Dimension 2 Code");
            end;
        }
        field(17; "Budget Dimension 1 Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Budget Dimension 1 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 1 Code" := OnLookupDimCode(2, "Budget Dimension 1 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 1 Code" = '' then
                    exit;
                if ItemBudgetName.Name <> "Budget Name" then
                    ItemBudgetName.Get("Analysis Area", "Budget Name");
                ValidateDimValue(ItemBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
            end;
        }
        field(18; "Budget Dimension 2 Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Budget Dimension 2 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 2 Code" := OnLookupDimCode(3, "Budget Dimension 2 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 2 Code" = '' then
                    exit;
                if ItemBudgetName.Name <> "Budget Name" then
                    ItemBudgetName.Get("Analysis Area", "Budget Name");
                ValidateDimValue(ItemBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
            end;
        }
        field(19; "Budget Dimension 3 Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Budget Dimension 3 Code';

            trigger OnLookup()
            begin
                "Budget Dimension 3 Code" := OnLookupDimCode(4, "Budget Dimension 3 Code");
            end;

            trigger OnValidate()
            begin
                if "Budget Dimension 3 Code" = '' then
                    exit;
                if ItemBudgetName.Name <> "Budget Name" then
                    ItemBudgetName.Get("Analysis Area", "Budget Name");
                ValidateDimValue(ItemBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Analysis Area", "Budget Name", "Item No.", "Source Type", "Source No.", Date, "Location Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code")
        {
            SumIndexFields = "Cost Amount", "Sales Amount", Quantity;
        }
        key(Key3; "Analysis Area", "Budget Name", "Source Type", "Source No.", "Item No.", Date, "Location Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code")
        {
            SumIndexFields = "Cost Amount", "Sales Amount", Quantity;
        }
        key(Key4; "Analysis Area", "Budget Name", "Item No.", Date)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckIfBlocked();
        DeleteItemAnalysisViewBudgEntry();
    end;

    trigger OnInsert()
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        IsHandled: Boolean;
    begin
        CheckIfBlocked();
        TestField(Date);

        GetGLSetup();
        if ("Source No." = '') and ("Item No." = '') then begin
            GetSalesSetup();
            GetInventorySetup();

            IsHandled := false;
            OnInsertOnBeforeCheckGroupDimFilled(Rec, IsHandled);
            if not IsHandled then
                if not (CheckGroupDimFilled(SalesSetup."Customer Group Dimension Code") or
                        CheckGroupDimFilled(SalesSetup."Salesperson Dimension Code") or
                        CheckGroupDimFilled(InventorySetup."Item Group Dimension Code"))
                then
                    TestField("Item No.");
        end;

        TestField("Budget Name");
        LockTable();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        if "Entry No." = 0 then
            "Entry No." := GetLastEntryNo() + 1;

        GetGLSetup();
        DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
        UpdateDimSet(TempDimSetEntry, GLSetup."Global Dimension 1 Code", "Global Dimension 1 Code");
        UpdateDimSet(TempDimSetEntry, GLSetup."Global Dimension 2 Code", "Global Dimension 2 Code");
        UpdateDimSet(TempDimSetEntry, ItemBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
        UpdateDimSet(TempDimSetEntry, ItemBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
        UpdateDimSet(TempDimSetEntry, ItemBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
        "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    trigger OnModify()
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        CheckIfBlocked();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        GetGLSetup();

        DimMgt.GetDimensionSet(TempDimSetEntry, "Dimension Set ID");
        if "Global Dimension 1 Code" <> xRec."Global Dimension 1 Code" then
            UpdateDimSet(TempDimSetEntry, GLSetup."Global Dimension 1 Code", "Global Dimension 1 Code");
        if "Global Dimension 2 Code" <> xRec."Global Dimension 2 Code" then
            UpdateDimSet(TempDimSetEntry, GLSetup."Global Dimension 2 Code", "Global Dimension 2 Code");
        if "Budget Dimension 1 Code" <> xRec."Budget Dimension 1 Code" then
            UpdateDimSet(TempDimSetEntry, ItemBudgetName."Budget Dimension 1 Code", "Budget Dimension 1 Code");
        if "Budget Dimension 2 Code" <> xRec."Budget Dimension 2 Code" then
            UpdateDimSet(TempDimSetEntry, ItemBudgetName."Budget Dimension 2 Code", "Budget Dimension 2 Code");
        if "Budget Dimension 3 Code" <> xRec."Budget Dimension 3 Code" then
            UpdateDimSet(TempDimSetEntry, ItemBudgetName."Budget Dimension 3 Code", "Budget Dimension 3 Code");
        "Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    var
        ItemBudgetName: Record "Item Budget Name";
        GLSetup: Record "General Ledger Setup";
        InventorySetup: Record "Inventory Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
        GLSetupRetrieved: Boolean;
        InventorySetupRetrieved: Boolean;
        SalesSetupRetrieved: Boolean;

#pragma warning disable AA0074
        Text001: Label '1,5,,Budget Dimension 1 Code';
        Text002: Label '1,5,,Budget Dimension 2 Code';
        Text003: Label '1,5,,Budget Dimension 3 Code';
#pragma warning restore AA0074

    local procedure CheckIfBlocked()
    begin
        if "Budget Name" = ItemBudgetName.Name then
            exit;
        if ItemBudgetName.Name <> "Budget Name" then
            ItemBudgetName.Get("Analysis Area", "Budget Name");
        ItemBudgetName.TestField(Blocked, false);
    end;

    local procedure ValidateDimValue(DimCode: Code[20]; DimValueCode: Code[20])
    begin
        if not DimMgt.CheckDimValue(DimCode, DimValueCode) then
            Error(DimMgt.GetDimErr());
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRetrieved then begin
            GLSetup.Get();
            GLSetupRetrieved := true;
        end;
    end;

    local procedure GetInventorySetup()
    begin
        if not InventorySetupRetrieved then begin
            InventorySetup.Get();
            InventorySetupRetrieved := true;
        end;
    end;

    local procedure GetSalesSetup()
    begin
        if not SalesSetupRetrieved then begin
            SalesSetup.Get();
            SalesSetupRetrieved := true;
        end;
    end;

    local procedure OnLookupDimCode(DimOption: Option "Global Dimension 1","Global Dimension 2","Budget Dimension 1","Budget Dimension 2","Budget Dimension 3","Budget Dimension 4"; DefaultValue: Code[20]): Code[20]
    var
        DimValue: Record "Dimension Value";
        DimValueList: Page "Dimension Value List";
    begin
        if DimOption in [DimOption::"Global Dimension 1", DimOption::"Global Dimension 2"] then
            GetGLSetup()
        else
            if ItemBudgetName.Name <> "Budget Name" then
                ItemBudgetName.Get("Analysis Area", "Budget Name");
        case DimOption of
            DimOption::"Global Dimension 1":
                DimValue."Dimension Code" := GLSetup."Global Dimension 1 Code";
            DimOption::"Global Dimension 2":
                DimValue."Dimension Code" := GLSetup."Global Dimension 2 Code";
            DimOption::"Budget Dimension 1":
                DimValue."Dimension Code" := ItemBudgetName."Budget Dimension 1 Code";
            DimOption::"Budget Dimension 2":
                DimValue."Dimension Code" := ItemBudgetName."Budget Dimension 2 Code";
            DimOption::"Budget Dimension 3":
                DimValue."Dimension Code" := ItemBudgetName."Budget Dimension 3 Code";
        end;
        DimValue.SetRange("Dimension Code", DimValue."Dimension Code");
        if DimValue.Get(DimValue."Dimension Code", DefaultValue) then;
        DimValueList.SetTableView(DimValue);
        DimValueList.SetRecord(DimValue);
        DimValueList.LookupMode := true;
        if DimValueList.RunModal() = ACTION::LookupOK then begin
            DimValueList.GetRecord(DimValue);
            exit(DimValue.Code);
        end;
        exit(DefaultValue);
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if (ItemBudgetName."Analysis Area" <> "Analysis Area") or
           (ItemBudgetName.Name <> "Budget Name")
        then
            if not ItemBudgetName.Get("Analysis Area", "Budget Name") then
                exit('');
        case BudgetDimType of
            1:
                begin
                    if ItemBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,5,' + ItemBudgetName."Budget Dimension 1 Code");
                    exit(Text001);
                end;
            2:
                begin
                    if ItemBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,5,' + ItemBudgetName."Budget Dimension 2 Code");
                    exit(Text002);
                end;
            3:
                begin
                    if ItemBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,5,' + ItemBudgetName."Budget Dimension 3 Code");
                    exit(Text003);
                end;
        end;
    end;

    local procedure CheckGroupDimFilled(GroupDimCode: Code[20]): Boolean
    begin
        if GroupDimCode <> '' then
            case GroupDimCode of
                GLSetup."Global Dimension 1 Code":
                    exit("Global Dimension 1 Code" <> '');
                GLSetup."Global Dimension 2 Code":
                    exit("Global Dimension 2 Code" <> '');
                ItemBudgetName."Budget Dimension 1 Code":
                    exit("Budget Dimension 1 Code" <> '');
                ItemBudgetName."Budget Dimension 2 Code":
                    exit("Budget Dimension 2 Code" <> '');
                ItemBudgetName."Budget Dimension 3 Code":
                    exit("Budget Dimension 3 Code" <> '');
            end;
    end;

    procedure GetCaption(): Text[1024]
    var
        GLSetup: Record "General Ledger Setup";
        ItemBudgetName: Record "Item Budget Name";
        Cust: Record Customer;
        Vend: Record Vendor;
        Item: Record Item;
        Dimension: Record Dimension;
        DimValue: Record "Dimension Value";
        SourceTableCaption: Text[250];
        SourceFilter: Text;
        Description: Text[250];
    begin
        case true of
            GetFilter("Source No.") <> '':
                case "Source Type" of
                    "Source Type"::Customer:
                        begin
                            SourceTableCaption := Cust.TableCaption();
                            SourceFilter := GetFilter("Source No.");
                            if MaxStrLen(Cust."No.") >= StrLen(SourceFilter) then
                                if Cust.Get(SourceFilter) then
                                    Description := Cust.Name;
                        end;
                    "Source Type"::Vendor:
                        begin
                            SourceTableCaption := Vend.TableCaption();
                            SourceFilter := GetFilter("Source No.");
                            if MaxStrLen(Vend."No.") >= StrLen(SourceFilter) then
                                if Vend.Get(SourceFilter) then
                                    Description := Vend.Name;
                        end;
                end;
            GetFilter("Item No.") <> '':
                begin
                    SourceTableCaption := Item.TableCaption();
                    SourceFilter := GetFilter("Item No.");
                    if MaxStrLen(Item."No.") >= StrLen(SourceFilter) then
                        if Item.Get(SourceFilter) then
                            Description := Item.Description;
                end;
            GetFilter("Global Dimension 1 Code") <> '':
                begin
                    GLSetup.Get();
                    Dimension.Code := GLSetup."Global Dimension 1 Code";
                    SourceFilter := GetFilter("Global Dimension 1 Code");
                    SourceTableCaption := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(GLSetup."Global Dimension 1 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
            GetFilter("Global Dimension 2 Code") <> '':
                begin
                    GLSetup.Get();
                    Dimension.Code := GLSetup."Global Dimension 2 Code";
                    SourceFilter := GetFilter("Global Dimension 2 Code");
                    SourceTableCaption := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(GLSetup."Global Dimension 2 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
            GetFilter("Budget Dimension 1 Code") <> '':
                if ItemBudgetName.Get("Analysis Area", "Budget Name") then begin
                    Dimension.Code := ItemBudgetName."Budget Dimension 1 Code";
                    SourceFilter := GetFilter("Budget Dimension 1 Code");
                    SourceTableCaption := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(ItemBudgetName."Budget Dimension 1 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
            GetFilter("Budget Dimension 2 Code") <> '':
                if ItemBudgetName.Get("Analysis Area", "Budget Name") then begin
                    Dimension.Code := ItemBudgetName."Budget Dimension 2 Code";
                    SourceFilter := GetFilter("Budget Dimension 2 Code");
                    SourceTableCaption := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(ItemBudgetName."Budget Dimension 2 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
            GetFilter("Budget Dimension 3 Code") <> '':
                if ItemBudgetName.Get("Analysis Area", "Budget Name") then begin
                    Dimension.Code := ItemBudgetName."Budget Dimension 3 Code";
                    SourceFilter := GetFilter("Budget Dimension 3 Code");
                    SourceTableCaption := Dimension.GetMLName(GlobalLanguage);
                    if MaxStrLen(DimValue.Code) >= StrLen(SourceFilter) then
                        if DimValue.Get(ItemBudgetName."Budget Dimension 3 Code", SourceFilter) then
                            Description := DimValue.Name;
                end;
        end;

        exit(
          DelChr(
            StrSubstNo('%1 %2 %3 %4', SourceTableCaption, SourceFilter, Description, "Budget Name"),
            '>'));
    end;

    procedure ShowDimensions()
    var
        DimSetEntry: Record "Dimension Set Entry";
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Budget Name", "Item No.", Date));

        if OldDimSetID = "Dimension Set ID" then
            exit;

        GetGLSetup();
        ItemBudgetName.Get("Analysis Area", "Budget Name");

        "Global Dimension 1 Code" := '';
        "Global Dimension 2 Code" := '';
        "Budget Dimension 1 Code" := '';
        "Budget Dimension 2 Code" := '';
        "Budget Dimension 3 Code" := '';

        if DimSetEntry.Get("Dimension Set ID", GLSetup."Global Dimension 1 Code") then
            "Global Dimension 1 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", GLSetup."Global Dimension 2 Code") then
            "Global Dimension 2 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", ItemBudgetName."Budget Dimension 1 Code") then
            "Budget Dimension 1 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", ItemBudgetName."Budget Dimension 2 Code") then
            "Budget Dimension 2 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get("Dimension Set ID", ItemBudgetName."Budget Dimension 3 Code") then
            "Budget Dimension 3 Code" := DimSetEntry."Dimension Value Code";
    end;

    local procedure UpdateDimSet(var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimValueCode: Code[20])
    begin
        if DimCode = '' then
            exit;
        if TempDimSetEntry.Get("Dimension Set ID", DimCode) then
            TempDimSetEntry.Delete();
        if DimValueCode <> '' then begin
            DimVal.Get(DimCode, DimValueCode);
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Set ID" := "Dimension Set ID";
            TempDimSetEntry."Dimension Code" := DimCode;
            TempDimSetEntry."Dimension Value Code" := DimValueCode;
            TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
            TempDimSetEntry.Insert();
        end;
    end;

    local procedure DeleteItemAnalysisViewBudgEntry()
    var
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
    begin
        ItemAnalysisViewBudgEntry.SetRange("Entry No.", "Entry No.");
        ItemAnalysisViewBudgEntry.SetRange("Analysis Area", "Analysis Area");
        ItemAnalysisViewBudgEntry.SetRange("Budget Name", "Budget Name");
        ItemAnalysisViewBudgEntry.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeCheckGroupDimFilled(var ItemBudgetEntry: Record "Item Budget Entry"; var IsHandled: Boolean)
    begin
    end;
}

