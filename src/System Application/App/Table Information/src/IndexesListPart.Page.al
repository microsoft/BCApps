// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using System.Diagnostics;
using System.Reflection;

/// <summary>
/// Shows more detailed information about indexes and provides actions to manage them.
/// </summary>
page 8704 "Indexes List Part"
{
    PageType = ListPart;
    AdditionalSearchTerms = 'Database,Size,Storage';
    ApplicationArea = All;
    SourceTable = "Database Index";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Permissions = tabledata "Key" = r,
                  tabledata "Database Index" = r;

    layout
    {
        area(Content)
        {
            repeater(Indexes)
            {
                field("Index name"; Rec."Index Name")
                {
                    Width = 30;
                    Caption = 'Index Name';
                    ToolTip = 'Specifies the name of the index.';
                }
                field(Enabled; Rec.Enabled)
                {
                    Caption = 'Enabled in Database';
                    ToolTip = 'Specifies whether the index is enabled in the database.';
                }
                field("AL defined"; Rec."Metadata Defined")
                {
                    Caption = 'AL Defined';
                    ToolTip = 'Specifies whether the index is defined as an AL key or automatically created to improve performance.';
                }
                field("Unique"; Rec.Unique)
                {
                    Caption = 'Unique';
                    ToolTip = 'Specifies whether the index is defined as unique in AL.';
                }
                field("Fragmentation"; Rec."Fragmentation %")
                {
                    Caption = 'Fragmentation (%)';
                    ToolTip = 'Specifies the percentage of fragmentation in the index.';
                    AutoFormatType = 0;
                    DecimalPlaces = 0;
                }
                field("Index size in KB"; Rec."Index Size (KB)")
                {
                    Caption = 'Index Size (KB)';
                    ToolTip = 'Specifies the size of the index in kilobytes.';
                }
                field("User seeks"; Rec."User seeks")
                {
                    Width = 10;
                    Caption = 'Seeks';
                    ToolTip = 'Specifies the number of user seeks on this index since the database was last started.';
                }
                field("User scans"; Rec."User scans")
                {
                    Width = 10;
                    Caption = 'Scans';
                    ToolTip = 'Specifies the number of user scans on this index since the database was last started.';
                }
                field("User lookups"; Rec."User lookups")
                {
                    Width = 10;
                    Caption = 'Lookups';
                    ToolTip = 'Specifies the number of user lookups on this index since the database was last started.';
                }
                field("User updates"; Rec."User updates")
                {
                    Width = 10;
                    Caption = 'Updates';
                    ToolTip = 'Specifies the number of user updates on this index since the database was last started.';
                }
                field("Last seek"; Rec."Last seek")
                {
                    Caption = 'Last Seek';
                    ToolTip = 'Specifies the timestamp of the last user seek on this index since the database was last started.';
                }
                field("Last scan"; Rec."Last scan")
                {
                    Caption = 'Last Scan';
                    ToolTip = 'Specifies the timestamp of the last user scan on this index since the database was last started.';
                }
                field("Last lookup"; Rec."Last lookup")
                {
                    Caption = 'Last Lookup';
                    ToolTip = 'Specifies the timestamp of the last user lookup on this index since the database was last started.';
                }
                field("Last Update"; Rec."Last update")
                {
                    Caption = 'Last Update';
                    ToolTip = 'Specifies the timestamp of the last user update on this index since the database was last started.';
                }
                field("Stat updated at"; Rec."Statistics rebuild at")
                {
                    Caption = 'Statistics updated at';
                    ToolTip = 'Specifies the last time the index''s corresponding statistics was rebuild. Statistics are updated automatically by the database engine based on certain thresholds of data changes, or when an index is re-enabled.';
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        DatabaseIndex: Record "Database Index";
        KeyRec: Record "Key";
        LinkTableId: Integer;
        PrevFilterGroup: Integer;
    begin
        // After calling a action this method gets called again, ensure we don't double insert records into the temporary table.
        if Rec.Count() <> 0 then
            exit(Rec.Find(Which));

        PrevFilterGroup := Rec.FilterGroup;
        Rec.FilterGroup := 4; // Link group.
        if not Evaluate(LinkTableId, Rec.GetFilter("TableId")) then begin
            Rec.FilterGroup := PrevFilterGroup;
            exit(false);
        end;

        Rec.FilterGroup := PrevFilterGroup;

        // Combines the indexes from "Database Index" and "Key" virtual tables. "Database Index" contains all indexes currently in the database,
        // including those automatically created by the database engine, while "Key" contains all metadata defined keys.

        DatabaseIndex.SetRange(DatabaseIndex.TableId, LinkTableId);
        DatabaseIndex.SetRange(DatabaseIndex."Company Name", SetCompanyName);

        if DatabaseIndex.FindSet() then
            repeat
                Rec.TransferFields(DatabaseIndex);
                Rec.Insert();
            until DatabaseIndex.Next() = 0;

        KeyRec.SetRange(KeyRec.TableNo, LinkTableId);
        KeyRec.SetRange(KeyRec.SQLIndex);
        if KeyRec.FindSet() then
            repeat
                if Rec.Get(LinkTableId, KeyRec."Key name", SetCompanyName, KeyRec."Source App ID") then
                    continue;

                Clear(Rec);

                Rec.TableId := KeyRec.TableNo;
                Rec."Column Names" := KeyRec."Key";
                Rec."Company Name" := CopyStr(SetCompanyName, 1, MaxStrLen(Rec."Company Name"));
                Rec.Unique := KeyRec.Unique;
                Rec.Enabled := false;
                Rec."Metadata Defined" := true;
                Rec."Index Name" := KeyRec."Key name";
                Rec."Source App ID" := KeyRec."Source App ID";

                Rec.Insert();
            until KeyRec.Next() = 0;


        exit(Rec.Find(Which));
    end;

    procedure SetCompanyFilter(NewCompanyName: Text)
    begin
        SetCompanyName := NewCompanyName;

        // Clear the temporary table to make sure only indexes for the selected company is shown.
        Rec.DeleteAll();
    end;

    var
        SetCompanyName: Text;
}
