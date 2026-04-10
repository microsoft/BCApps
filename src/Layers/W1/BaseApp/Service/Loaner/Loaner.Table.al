// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Service.Comment;
using Microsoft.Service.Setup;

table 5913 Loaner
{
    Caption = 'Loaner';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Loaner List";
    LookupPageID = "Loaner List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ServMgtSetup.Get();
                    NoSeries.TestManual(ServMgtSetup."Loaner Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the loaner.';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies an additional description of the loaner.';
        }
        field(5; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if ("Item No." = const('<>''')) "Item Unit of Measure".Code where("Item No." = field("Item No."))
            else
            "Unit of Measure";
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the unit price of the loaner.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                end else begin
                    Description := '';
                    "Description 2" := '';
                end;
            end;
        }
        field(7; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            ToolTip = 'Specifies the date when the loaner card was last modified.';
            Editable = false;
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const(Loaner),
                                                              "Table Subtype" = const("0"),
                                                              "No." = field("No.")));
            Caption = 'Comment';
            ToolTip = 'Specifies that there is a comment for this loaner.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
        }
        field(11; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(12; "Document No."; Code[20])
        {
            CalcFormula = lookup("Loaner Entry"."Document No." where("Loaner No." = field("No."),
                                                                      Lent = const(true)));
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the service document for the service item that was lent.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Lent; Boolean)
        {
            CalcFormula = exist("Loaner Entry" where("Loaner No." = field("No."),
                                                      Lent = const(true)));
            Caption = 'Lent';
            ToolTip = 'Specifies that the loaner has been lent to a customer.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number for the loaner for the service item.';
        }
        field(15; "Document Type"; Enum "Service Loaner Document Type")
        {
            CalcFormula = lookup("Loaner Entry"."Document Type" where("Loaner No." = field("No."),
                                                                       Lent = const(true)));
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type of the loaner entry.';
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
        key(Key2; Description)
        {
        }
        key(Key3; "Item No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Item No.")
        {
        }
    }

    trigger OnDelete()
    var
        ServCommentLine: Record "Service Comment Line";
    begin
        CalcFields(Lent, "Document No.");

        if Lent then
            Error(Text000);

        if not Blocked then
            Error(Text001, TableCaption(), FieldCaption(Blocked));

        Clear(LoanerEntry);
        LoanerEntry.SetCurrentKey("Loaner No.");
        LoanerEntry.SetRange("Loaner No.", "No.");
        LoanerEntry.DeleteAll();

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::Loaner);
        ServCommentLine.SetRange("Table Subtype", 0);
        ServCommentLine.SetRange("No.", "No.");
        ServCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            ServMgtSetup.Get();
            ServMgtSetup.TestField("Loaner Nos.");
                "No. Series" := ServMgtSetup."Loaner Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot delete a loaner that is lent.';
#pragma warning disable AA0470
        Text001: Label 'You can only delete a %1 that is %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServMgtSetup: Record "Service Mgt. Setup";
        Item: Record Item;
        Loaner: Record Loaner;
        LoanerEntry: Record "Loaner Entry";
        NoSeries: Codeunit "No. Series";

    procedure AssistEdit(OldLoaner: Record Loaner): Boolean
    begin
        Loaner := Rec;
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Loaner Nos.");
        if NoSeries.LookupRelatedNoSeries(ServMgtSetup."Loaner Nos.", OldLoaner."No. Series", Loaner."No. Series") then begin
            Loaner."No." := NoSeries.GetNextNo(Loaner."No. Series");
            Rec := Loaner;
            exit(true);
        end;
    end;
}
