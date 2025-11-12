// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Warehouse.Reports;
using System.Reflection;

table 7309 "Warehouse Journal Template"
{
    Caption = 'Warehouse Journal Template';
    LookupPageID = "Whse. Journal Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Test Report ID"; Integer)
        {
            Caption = 'Test Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(6; "Page ID"; Integer)
        {
            Caption = 'Page ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));

            trigger OnValidate()
            begin
                if "Page ID" = 0 then
                    Validate(Type);
            end;
        }
        field(7; "Registering Report ID"; Integer)
        {
            Caption = 'Registering Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(8; "Force Registering Report"; Boolean)
        {
            Caption = 'Force Registering Report';
        }
        field(9; Type; Enum "Warehouse Journal Template Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                "Test Report ID" := Report::"Whse. Invt.-Registering - Test";
                "Registering Report ID" := Report::"Warehouse Register - Quantity";
                SourceCodeSetup.Get();
                case Type of
                    Type::Item:
                        begin
                            "Source Code" := SourceCodeSetup."Whse. Item Journal";
                            "Page ID" := PAGE::"Whse. Item Journal";
                        end;
                    Type::"Physical Inventory":
                        begin
                            "Source Code" := SourceCodeSetup."Whse. Phys. Invt. Journal";
                            "Page ID" := PAGE::"Whse. Phys. Invt. Journal";
                        end;
                    Type::Reclassification:
                        begin
                            "Source Code" := SourceCodeSetup."Whse. Reclassification Journal";
                            "Page ID" := PAGE::"Whse. Reclassification Journal";
                        end;
                end;
            end;
        }
        field(10; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";

            trigger OnValidate()
            begin
                WhseJnlLine.SetRange("Journal Template Name", Name);
                WhseJnlLine.ModifyAll("Source Code", "Source Code");
                Modify();
            end;
        }
        field(11; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(15; "Test Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Test Report ID")));
            Caption = 'Test Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Page Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Page),
                                                                           "Object ID" = field("Page ID")));
            Caption = 'Page Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Registering Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Registering Report ID")));
            Caption = 'Registering Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then
                    if "No. Series" = "Registering No. Series" then
                        "Registering No. Series" := '';
            end;
        }
        field(20; "Registering No. Series"; Code[20])
        {
            Caption = 'Registering No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Registering No. Series" = "No. Series") and ("Registering No. Series" <> '') then
                    FieldError("Registering No. Series", StrSubstNo(Text000, "Registering No. Series"));
            end;
        }
        field(30; "Increment Batch Name"; Boolean)
        {
            Caption = 'Increment Batch Name';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description, Type)
        {
        }
    }

    trigger OnDelete()
    begin
        WhseJnlLine.SetRange("Journal Template Name", Name);
        WhseJnlLine.DeleteAll(true);
        WhseJnlBatch.SetRange("Journal Template Name", Name);
        WhseJnlBatch.DeleteAll();
    end;

    trigger OnInsert()
    begin
        Validate("Page ID");
    end;

    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        SourceCodeSetup: Record "Source Code Setup";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

