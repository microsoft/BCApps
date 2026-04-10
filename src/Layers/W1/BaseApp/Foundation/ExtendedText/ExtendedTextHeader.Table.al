// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;
using System.Globalization;

table 279 "Extended Text Header"
{
    Caption = 'Extended Text Header';
    DataCaptionFields = "No.", "Language Code", "Text No.";
    LookupPageID = "Extended Text List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Enum "Extended Text Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Table Name" = const("Standard Text")) "Standard Text"
            else
            if ("Table Name" = const("G/L Account")) "G/L Account"
            else
            if ("Table Name" = const(Item)) Item
            else
            if ("Table Name" = const(Resource)) Resource
            else
            if ("Table Name" = const("VAT Clause")) "VAT Clause";
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
            TableRelation = Language;

            trigger OnValidate()
            begin
                if "Language Code" <> '' then
                    "All Language Codes" := false;
            end;
        }
        field(4; "Text No."; Integer)
        {
            Caption = 'Text No.';
            Editable = false;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies a date from which the text will be used on the item, account, resource or standard text.';
        }
        field(6; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies a date on which the text will no longer be used on the item, account, resource or standard text.';
        }
        field(7; "All Language Codes"; Boolean)
        {
            Caption = 'All Language Codes';
            ToolTip = 'Specifies whether the text should be used for all language codes. If a language code has been chosen in the Language Code field, it will be overruled by this function.';
            InitValue = true;

            trigger OnValidate()
            begin
                if "All Language Codes" then
                    "Language Code" := ''
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the content of the extended item description.';
        }
        field(11; "Sales Quote"; Boolean)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Sales Quote';
            ToolTip = 'Specifies whether the text will be available on sales quotes.';
            InitValue = true;
        }
        field(12; "Sales Invoice"; Boolean)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Sales Invoice';
            ToolTip = 'Specifies whether the text will be available on sales invoices.';
            InitValue = true;
        }
        field(13; "Sales Order"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Sales Order';
            ToolTip = 'Specifies whether the text will be available on sales orders.';
            InitValue = true;
        }
        field(14; "Sales Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Sales Credit Memo';
            ToolTip = 'Specifies whether the text will be available on sales credit memos.';
            InitValue = true;
        }
        field(15; "Purchase Quote"; Boolean)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Purchase Quote';
            ToolTip = 'Specifies whether the text will be available on purchase quotes.';
            InitValue = true;
        }
        field(16; "Purchase Invoice"; Boolean)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Purchase Invoice';
            ToolTip = 'Specifies whether the text will be available on purchase invoices.';
            InitValue = true;
        }
        field(17; "Purchase Order"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Purchase Order';
            ToolTip = 'Specifies whether the text will be available on purchase orders.';
            InitValue = true;
        }
        field(18; "Purchase Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Purchase Credit Memo';
            ToolTip = 'Specifies whether the text will be available on purchase credit memos.';
            InitValue = true;
        }
        field(19; Reminder; Boolean)
        {
            AccessByPermission = TableData Customer = R;
            Caption = 'Reminder';
            ToolTip = 'Specifies whether the extended text will be available on reminders.';
            InitValue = true;
        }
        field(20; "Finance Charge Memo"; Boolean)
        {
            AccessByPermission = TableData Customer = R;
            Caption = 'Finance Charge Memo';
            ToolTip = 'Specifies whether the extended text will be available on finance charge memos.';
            InitValue = true;
        }
        field(21; "Sales Blanket Order"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Sales Blanket Order';
            ToolTip = 'Specifies whether the text will be available on sales blanket orders.';
            InitValue = true;
        }
        field(22; "Purchase Blanket Order"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Purchase Blanket Order';
            ToolTip = 'Specifies whether the text will be available on purchase blanket orders.';
            InitValue = true;
        }
        field(23; "Prepmt. Sales Invoice"; Boolean)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Prepmt. Sales Invoice';
            ToolTip = 'Specifies whether the text will be available on prepayment sales invoices.';
            InitValue = true;
        }
        field(24; "Prepmt. Sales Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Sales Header" = R;
            Caption = 'Prepmt. Sales Credit Memo';
            ToolTip = 'Specifies whether the text will be available on prepayment sales credit memos.';
            InitValue = true;
        }
        field(25; "Prepmt. Purchase Invoice"; Boolean)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Prepmt. Purchase Invoice';
            ToolTip = 'Specifies whether the text will be available on prepayment purchase invoices.';
            InitValue = true;
        }
        field(26; "Prepmt. Purchase Credit Memo"; Boolean)
        {
            AccessByPermission = TableData "Purchase Header" = R;
            Caption = 'Prepmt. Purchase Credit Memo';
            ToolTip = 'Specifies whether the text will be available on prepayment purchase credit memos.';
            InitValue = true;
        }
        field(167; "Job"; Boolean)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project';
            ToolTip = 'Specifies whether the text will be available on projects.';
            InitValue = true;
        }
        field(6600; "Sales Return Order"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Sales Return Order';
            ToolTip = 'Specifies whether the text will be available on sales return orders.';
            InitValue = true;
        }
        field(6605; "Purchase Return Order"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Purchase Return Order';
            ToolTip = 'Specifies whether the text will be available on purchase return orders.';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Language Code", "Text No.")
        {
            Clustered = true;
        }
        key(Key2; "Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ExtTextLine: Record "Extended Text Line";
    begin
        ExtTextLine.SetRange("Table Name", "Table Name");
        ExtTextLine.SetRange("No.", "No.");
        ExtTextLine.SetRange("Language Code", "Language Code");
        ExtTextLine.SetRange("Text No.", "Text No.");
        ExtTextLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        IncrementTextNo();
    end;

    trigger OnRename()
    begin
        if ("Table Name" <> xRec."Table Name") or ("No." <> xRec."No.") then
            Error(RenameRecordErr, FieldCaption("Table Name"), FieldCaption("No."));

        IncrementTextNo();

        RecreateTextLines();
    end;

    var
        UntitledMsg: Label 'untitled';
        RenameRecordErr: Label 'You cannot rename %1 or %2.', Comment = '%1 is TableName Field %2 is No.Table Field';

    procedure IncrementTextNo()
    var
        ExtTextHeader: Record "Extended Text Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncrementTextNo(Rec, IsHandled);
        if IsHandled then
            exit;

        ExtTextHeader.SetRange("Table Name", "Table Name");
        ExtTextHeader.SetRange("No.", "No.");
        ExtTextHeader.SetRange("Language Code", "Language Code");

        if ExtTextHeader.FindLast() then
            "Text No." := ExtTextHeader."Text No." + 1
        else
            "Text No." := 1;
    end;

    local procedure RecreateTextLines()
    var
        ExtTextLine: Record "Extended Text Line";
        TmpExtTextLine: Record "Extended Text Line";
    begin
        ExtTextLine.SetRange("Table Name", "Table Name");
        ExtTextLine.SetRange("No.", "No.");
        ExtTextLine.SetRange("Language Code", xRec."Language Code");
        ExtTextLine.SetRange("Text No.", xRec."Text No.");
        OnRecreateTextLinesOnAfterExtTextLineSetFilters(ExtTextLine);

        if ExtTextLine.Find('-') then
            repeat
                TmpExtTextLine := ExtTextLine;
                TmpExtTextLine."Text No." := "Text No.";
                TmpExtTextLine."Language Code" := "Language Code";
                TmpExtTextLine.Insert();
            until ExtTextLine.Next() = 0;

        ExtTextLine.DeleteAll();
    end;

    procedure GetCaption(): Text
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Res: Record Resource;
        StandardText: Record "Standard Text";
        VATClause: Record "VAT Clause";
        Descr: Text[100];
    begin
        if "Text No." <> 0 then begin
            case "Table Name" of
                "Table Name"::"Standard Text":
                    begin
                        if StandardText.Code <> "No." then
                            StandardText.Get("No.");
                        Descr := StandardText.Description;
                    end;
                "Table Name"::"G/L Account":
                    begin
                        if GLAcc."No." <> "No." then
                            GLAcc.Get("No.");
                        Descr := GLAcc.Name;
                    end;
                "Table Name"::Item:
                    begin
                        if Item."No." <> "No." then
                            Item.Get("No.");
                        Descr := Item.Description;
                    end;
                "Table Name"::Resource:
                    begin
                        if Res."No." <> "No." then
                            Res.Get("No.");
                        Descr := Res.Name;
                    end;
                "Table Name"::"VAT Clause":
                    begin
                        if VATClause.Code <> "No." then
                            VATClause.Get("No.");
                        Descr := CopyStr(VATClause.Description, 1, MaxStrLen(Descr));
                    end;
                else
                    OnGetCaption(Rec, Descr);
            end;
            exit(StrSubstNo('%1 %2 %3 %4', "No.", Descr, "Language Code", Format("Text No.")));
        end;
        exit(UntitledMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrementTextNo(var ExtendedTextHeader: Record "Extended Text Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCaption(ExtendedTextHeader: Record "Extended Text Header"; var Descr: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateTextLinesOnAfterExtTextLineSetFilters(var ExtTextLine: Record "Extended Text Line")
    begin
    end;
}

