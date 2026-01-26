// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;

page 11007 "Data Export Table Relation"
{
    Caption = 'Data Export Table Relationship';
    DataCaptionExpression = GetCaption();
    DataCaptionFields = "Data Exp. Rec. Type Code";
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Data Export Record Source";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Relation To Table No."; Rec."Relation To Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From Table No.';
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the parent table associated with this table.';
                }
                field("Relation To Table Name"; Rec."Relation To Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From Table Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the table that is specified in the Relation To Table No. field.';
                }
                field(ToTableID; Rec."Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To Table No.';
                    Editable = false;
                    Lookup = false;
                    LookupPageID = Objects;
                    TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
                    ToolTip = 'Specifies the number of the table that you selected for the record source.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To Table Name';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the table that you selected in the Table No. field.';
                }
            }
            part(Relationships; "Data Export Table Relation Sub")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Relationships';
                SubPageLink = "Data Export Code" = field("Data Export Code"),
                              "Data Exp. Rec. Type Code" = field("Data Exp. Rec. Type Code"),
                              "From Table No." = field("Relation To Table No."),
                              "To Table No." = field("Table No.");
                SubPageView = sorting("Data Export Code", "Data Exp. Rec. Type Code", "From Table No.", "From Field No.", "To Table No.", "To Field No.");
            }
        }
    }

    actions
    {
    }

    local procedure GetCaption(): Text[250]
    var
        DataExportRecordType: Record "Data Export Record Type";
    begin
        if DataExportRecordType.Get(Rec."Data Exp. Rec. Type Code") then
            exit(DataExportRecordType.Code + ' ' + DataExportRecordType.Description);
    end;
}

