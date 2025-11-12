// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

table 233 "Item Journal Batch"
{
    Caption = 'Item Journal Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Item Journal Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Item Journal Template";
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
                    ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    ItemJnlLine.SetRange("Journal Batch Name", Name);
                    ItemJnlLine.ModifyAll("Reason Code", "Reason Code");
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
                if "No. Series" <> '' then begin
                    ItemJnlTemplate.Get("Journal Template Name");
                    if ItemJnlTemplate.Recurring then
                        Error(
                          Text000,
                          FieldCaption("Posting No. Series"));
                    if "No. Series" = "Posting No. Series" then
                        Validate("Posting No. Series", '');
                end;
            end;
        }
        field(6; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
                ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                ItemJnlLine.SetRange("Journal Batch Name", Name);
                ItemJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
                Modify();
            end;
        }
        field(21; "Template Type"; Enum "Item Journal Template Type")
        {
            CalcFormula = lookup("Item Journal Template".Type where(Name = field("Journal Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; Recurring; Boolean)
        {
            CalcFormula = lookup("Item Journal Template".Recurring where(Name = field("Journal Template Name")));
            Caption = 'Recurring';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6500; "Item Tracking on Lines"; Boolean)
        {
            Caption = 'Item Tracking on Lines';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateItemTrackingOnLines(Rec, IsHandled);
                if IsHandled then
                    exit;
                ItemJnlTemplate.Get("Journal Template Name");

                if not (ItemJnlTemplate.Type in [
                                                "Item Journal Template Type"::Item,
                                                ItemJnlTemplate.GetOutputTemplateType(),
                                                ItemJnlTemplate.GetConsumptionTemplateType()])
                then
                    ItemJnlTemplate.FieldError(Type, ItemJournalTemplateTypeErrorLbl);

                ItemJnlTemplate.TestField(Recurring, false);
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", Name);
        ItemJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        ItemJnlTemplate.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        ItemJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while ItemJnlLine.FindFirst() do
            ItemJnlLine.Rename("Journal Template Name", Name, ItemJnlLine."Line No.");
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Only the %1 field can be filled in on recurring journals.';
        Text001: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemJournalTemplateTypeErrorLbl: Label 'can only be Item, Output, or Consumption';

    procedure SetupNewBatch()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetupNewBatch(Rec, ItemJnlTemplate, IsHandled);
        if not IsHandled then begin
            ItemJnlTemplate.Get("Journal Template Name");
            "No. Series" := ItemJnlTemplate."No. Series";
            "Posting No. Series" := ItemJnlTemplate."Posting No. Series";
            "Reason Code" := ItemJnlTemplate."Reason Code";
        end;
        OnAfterSetupNewBatch(Rec, ItemJnlTemplate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJnlTemplate: Record "Item Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupNewBatch(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalTemplate: Record "Item Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemTrackingOnLines(var ItemJournalBatch: Record "Item Journal Batch"; var IsHandled: Boolean)
    begin
    end;
}
