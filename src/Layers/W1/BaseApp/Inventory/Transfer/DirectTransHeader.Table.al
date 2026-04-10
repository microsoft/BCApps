// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;

table 5856 "Direct Trans. Header"
{
    Caption = 'Direct Transfer Header';
    DataCaptionFields = "No.";
    LookupPageID = "Posted Direct Transfers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            ToolTip = 'Specifies the code of the location that items are transferred from.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
            ToolTip = 'Specifies the name of the sender at the location that the items are transferred from.';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
            ToolTip = 'Specifies an additional part of the name of the sender at the location that the items are transferred from.';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
            ToolTip = 'Specifies the address of the location that the items are transferred from.';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
            ToolTip = 'Specifies an additional part of the address of the location that items are transferred from.';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            ToolTip = 'Specifies the post code of the location that the items are transferred from.';
            TableRelation = "Post Code";

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Transfer-from City", "Transfer-from Post Code",
                  "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            ToolTip = 'Specifies the city of the location that the items are transferred from.';

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Transfer-from City", "Transfer-from Post Code",
                  "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            ToolTip = 'Specifies the code of the location that the items are transferred to.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
            ToolTip = 'Specifies the name of the recipient at the location that the items are transferred to.';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the recipient at the location that the items are transferred to.';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
            ToolTip = 'Specifies the address of the location that the items are transferred to.';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
            ToolTip = 'Specifies an additional part of the address of the location that the items are transferred to.';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            ToolTip = 'Specifies the postal code of the location that the items are transferred to.';
            TableRelation = "Post Code";

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            ToolTip = 'Specifies the city of the location that items are transferred to.';

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(20; "Transfer Order Date"; Date)
        {
            Caption = 'Transfer Order Date';
            ToolTip = 'Specifies the date when the transfer order was created.';
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the entry''s posting date.';
        }
        field(22; Comment; Boolean)
        {
            CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Posted Transfer Receipt"),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            ToolTip = 'Specifies the number of the related transfer order.';
            TableRelation = "Transfer Header";
            ValidateTableRelation = false;
        }
        field(26; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(30; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
            ToolTip = 'Specifies the name of the contact person at the location that the items are transferred from.';
        }
        field(31; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
            ToolTip = 'Specifies the name of the contact person at the location that items are transferred to.';
        }
        field(32; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
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
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Posting Date", "Transfer Order Date")
        {
        }
    }

    trigger OnDelete()
    var
        InvtCommentLine: Record "Inventory Comment Line";
        DirectTransLine: Record "Direct Trans. Line";
        MoveEntries: Codeunit MoveEntries;
    begin
        DirectTransLine.SetRange("Document No.", "No.");
        DirectTransLine.DeleteAll();

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Posted Direct Transfer");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll();

        ItemTrackingMgt.DeleteItemEntryRelation(DATABASE::"Direct Trans. Line", 0, "No.", '', 0, 0, true);

        MoveEntries.MoveDocRelatedEntries(DATABASE::"Direct Trans. Header", "No.");
    end;

    var
        PostCode: Record "Post Code";
        DimMgt: Codeunit DimensionManagement;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DocumentTxt: Label '%1 %2', Locked = true;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.Run();
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        DocumentPrint: Codeunit "Document-Print";
    begin
        DocumentPrint.PrintDirectTransfer(Rec, ShowRequestForm);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo(DocumentTxt, TableCaption(), "No."), 1, 250));
    end;
}

