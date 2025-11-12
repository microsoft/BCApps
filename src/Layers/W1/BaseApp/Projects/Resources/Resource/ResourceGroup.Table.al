// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.UOM;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Ledger;

table 152 "Resource Group"
{
    Caption = 'Resource Group';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Resource Groups";
    LookupPageID = "Resource Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(22; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(23; Capacity; Decimal)
        {
            CalcFormula = sum("Res. Capacity Entry".Capacity where("Resource Group No." = field("No."),
                                                                    Date = field("Date Filter")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(24; "Qty. on Order (Job)"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Quantity (Base)" where(Status = const(Order),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "Resource Group No." = field("No."),
                                                                           "Planning Date" = field("Date Filter")));
            Caption = 'Qty. on Order (Project)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Qty. Quoted (Job)"; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Quantity (Base)" where(Status = const(Quote),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "Resource Group No." = field("No."),
                                                                           "Planning Date" = field("Date Filter")));
            Caption = 'Qty. Quoted (Project)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Unit of Measure";
        }
        field(27; "Usage (Qty.)"; Decimal)
        {
            CalcFormula = sum("Res. Ledger Entry".Quantity where("Entry Type" = const(Usage),
                                                                  Chargeable = field("Chargeable Filter"),
                                                                  "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                  "Resource Group No." = field("No."),
                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Usage (Cost)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = sum("Res. Ledger Entry"."Total Cost" where("Entry Type" = const(Usage),
                                                                      Chargeable = field("Chargeable Filter"),
                                                                      "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                      "Resource Group No." = field("No."),
                                                                      "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Usage (Price)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Res. Ledger Entry"."Total Price" where("Entry Type" = const(Usage),
                                                                       Chargeable = field("Chargeable Filter"),
                                                                       "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                       "Resource Group No." = field("No."),
                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Sales (Qty.)"; Decimal)
        {
            CalcFormula = - sum("Res. Ledger Entry".Quantity where("Entry Type" = const(Sale),
                                                                   "Resource Group No." = field("No."),
                                                                   "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                   "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Sales (Cost)"; Decimal)
        {
            AutoFormatType = 2;
            CalcFormula = - sum("Res. Ledger Entry"."Total Cost" where("Entry Type" = const(Sale),
                                                                       "Resource Group No." = field("No."),
                                                                       "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                       "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Sales (Price)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Res. Ledger Entry"."Total Price" where("Entry Type" = const(Sale),
                                                                        "Resource Group No." = field("No."),
                                                                        "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                        "Posting Date" = field("Date Filter")));
            Caption = 'Sales (Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Chargeable Filter"; Boolean)
        {
            Caption = 'Chargeable Filter';
            FieldClass = FlowFilter;
        }
        field(34; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(35; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(36; "No. of Resources Assigned"; Integer)
        {
            CalcFormula = count(Resource where("Resource Group No." = field("No.")));
            Caption = 'No. of Resources Assigned';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ResCapacityEntry.SetCurrentKey("Resource Group No.");
        ResCapacityEntry.SetRange("Resource Group No.", "No.");
        ResCapacityEntry.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Resource Group");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::"Resource Group", "No.");
    end;

    trigger OnInsert()
    begin
        DimMgt.UpdateDefaultDim(
          DATABASE::"Resource Group", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnRename()
    var
        PriceListLine: Record "Price List Line";
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Resource Group", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Resource Group", xRec."No.", "No.");
        PriceListLine.RenameNo(PriceListLine."Asset Type"::"Resource Group", xRec."No.", "No.")
    end;

    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        CommentLine: Record "Comment Line";
        DimMgt: Codeunit DimensionManagement;

    local procedure AsPriceAsset(var PriceAsset: Record "Price Asset"; PriceType: Enum "Price Type")
    begin
        PriceAsset.Init();
        PriceAsset."Price Type" := PriceType;
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::"Resource Group";
        PriceAsset."Asset No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        AsPriceAsset(PriceAsset, PriceType);
        PriceUXManagement.ShowPriceListLines(PriceAsset, PriceType, AmountType);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Resource Group", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ResourceGroup: Record "Resource Group"; xResourceGroup: Record "Resource Group"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ResourceGroup: Record "Resource Group"; xResourceGroup: Record "Resource Group"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

