// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Setup;

table 7310 "Warehouse Journal Batch"
{
    Caption = 'Warehouse Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Whse. Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Warehouse Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                if "Reason Code" <> xRec."Reason Code" then begin
                    WhseJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    WhseJnlLine.SetRange("Journal Batch Name", Name);
                    WhseJnlLine.SetRange("Location Code", "Location Code");
                    WhseJnlLine.ModifyAll("Reason Code", "Reason Code");
                    Modify();
                end;
            end;
        }
        field(5; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then
                    if "No. Series" = "Registering No. Series" then
                        Validate("Registering No. Series", '');
            end;
        }
        field(6; "Registering No. Series"; Code[20])
        {
            Caption = 'Registering No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Registering No. Series" = "No. Series") and ("Registering No. Series" <> '') then
                    FieldError("Registering No. Series", StrSubstNo(Text000, "Registering No. Series"));
                WhseJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                WhseJnlLine.SetRange("Journal Batch Name", Name);
                WhseJnlLine.SetRange("Location Code", "Location Code");
                WhseJnlLine.ModifyAll("Registering No. Series", "Registering No. Series");
                Modify();
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;

            trigger OnValidate()
            var
                Location: Record Location;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateLocationCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                Location.Get("Location Code");
                Location.TestField("Directed Put-away and Pick", true);
            end;
        }
        field(21; "Template Type"; Enum "Warehouse Journal Template Type")
        {
            CalcFormula = lookup("Warehouse Journal Template".Type where(Name = field("Journal Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7700; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Warehouse Employee" where("Location Code" = field("Location Code"));
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name, "Location Code")
        {
            Clustered = true;
        }
        key(Key2; "Location Code", "Assigned User ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        WhseJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", Name);
        WhseJnlLine.SetRange("Location Code", "Location Code");
        WhseJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        WhseJnlTemplate.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        WhseJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", xRec.Name);
        WhseJnlLine.SetRange("Location Code", xRec."Location Code");
        while WhseJnlLine.FindFirst() do
            WhseJnlLine.Rename("Journal Template Name", Name, "Location Code", WhseJnlLine."Line No.");
    end;

    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlLine: Record "Warehouse Journal Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetupNewBatch()
    begin
        WhseJnlTemplate.Get("Journal Template Name");
        "No. Series" := WhseJnlTemplate."No. Series";
        "Registering No. Series" := WhseJnlTemplate."Registering No. Series";
        "Reason Code" := WhseJnlTemplate."Reason Code";

        OnAfterSetupNewBatch(Rec, WhseJnlTemplate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; WarehouseJournalTemplate: Record "Warehouse Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateLocationCode(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; var IsHandled: Boolean)
    begin
    end;
}

