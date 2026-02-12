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

    // Added to remove the New and Delete on the action bar.
    InsertAllowed = false;
    DeleteAllowed = false;

    Permissions = tabledata "Key" = r,
                  tabledata "Database Index" = r;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Index name"; rec."Index Name")
                {
                    Width = 30;
                    Caption = 'Index Name';
                    ToolTip = 'The name of the index.';
                }
                field(Enabled; rec.Enabled)
                {
                    Caption = 'Enabled in Database.';
                    ToolTip = 'Indicates whether the index is enabled in the database.';
                }
                field("AL defined"; rec."Metadata Defined")
                {
                    Caption = 'AL Defined';
                    ToolTip = 'Indicates whether the index is defined as an AL key or automatically created to improve performance.';
                }
                field("Unique"; rec.Unique)
                {
                    Caption = 'AL defined as unique';
                    ToolTip = 'Indicates whether an AL defined key is defined as unique.';
                }
                field("Fragmentation"; rec."Fragmentation %")
                {
                    Caption = 'Fragmentation (%)';
                    ToolTip = 'Indicates the percentage of fragmentation in the index.';
                }
                field("Index size in KB"; rec."Index Size (KB)")
                {
                    Caption = 'Index Size (KB).';
                    ToolTip = 'The size of the index in kilobytes.';
                }
                field("User seeks"; rec."User seeks")
                {
                    Width = 10;
                    Caption = 'User Seeks';
                    ToolTip = 'Number of user seeks on this index since the database was last started.';
                }
                field("User scans"; rec."User scans")
                {
                    Width = 10;
                    Caption = 'User Scans';
                    ToolTip = 'Number of user scans on this index since the database was last started.';
                }
                field("User lookups"; rec."User lookups")
                {
                    Width = 10;
                    Caption = 'User Lookups';
                    ToolTip = 'Number of user lookups on this index since the database was last started.';
                }
                field("User updates"; rec."User updates")
                {
                    Width = 10;
                    Caption = 'User Updates';
                    ToolTip = 'Number of user updates on this index since the database was last started.';
                }
                field("Last seek"; rec."Last seek")
                {
                    Caption = 'Last Seek';
                    ToolTip = 'Timestamp of the last user seek on this index since the database was last started.';
                }
                field("Last scan"; rec."Last scan")
                {
                    Caption = 'Last Scan';
                    ToolTip = 'Timestamp of the last user scan on this index since the database was last started.';
                }
                field("Last lookup"; rec."Last lookup")
                {
                    Caption = 'Last Lookup';
                    ToolTip = 'Timestamp of the last user lookup on this index since the database was last started.';
                }
                field("Last Update"; rec."Last update")
                {
                    Caption = 'Last Update';
                    ToolTip = 'Timestamp of the last user update on this index since the database was last started.';
                }
                field("Stat updated at"; rec."Statistics rebuild at")
                {
                    Caption = 'Statistics Last Rebuild';
                    ToolTip = 'Last time the index''s corresponding statistics was rebuild. Statistics are updated automatically by the database engine based on certain thresholds of data changes, or when an index is re-enabled.';
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        t: Record "Database Index" temporary;
        tid: Integer;
        prevFilterGroup: Integer;
        TempDatabaseIndex: Record "Database Index";
        keyRec: Record "Key";
    begin
        // After calling a action this method gets called again, ensure we don't double insert records into the temporary table.
        if (rec.Count() <> 0) then begin
            exit(rec.Find(Which));
        end;

        prevFilterGroup := rec.FilterGroup;
        rec.FilterGroup := 4; // Link group.
        if (Evaluate(tid, rec.GetFilter("TableId"))) then begin
            // TableId filter is set.
        end else begin
            exit(false);
        end;

        rec.FilterGroup := prevFilterGroup;

        // Combines the indexes from "Database Index" and "Key" virtual tables. "Database Index" contains all indexes currently in the database,
        // including those automatically created by the database engine, while "Key" contains all metadata defined keys.

        TempDatabaseIndex.SetRange(TempDatabaseIndex.TableId, tid);
        TempDatabaseIndex.SetRange(TempDatabaseIndex."Company Name", setCompanyName);

        if (TempDatabaseIndex.FindSet()) then begin
            repeat
                rec.TransferFields(TempDatabaseIndex);
                rec.Insert();
            until TempDatabaseIndex.Next() = 0;
        end;

        keyRec.SetRange(keyRec.TableNo, tid);
        keyRec.SetRange(keyRec.SQLIndex);
        if (keyRec.FindSet()) then begin
            repeat
                if (rec.Get(tid, keyRec."Key name", setCompanyName, keyRec."Source App ID")) then
                    continue;

                Clear(rec);

                rec.TableId := keyRec.TableNo;
                rec."Column Names" := keyRec."Key";
                rec."Company Name" := setCompanyName;
                rec.Unique := keyRec.Unique;
                rec.Enabled := false;
                rec."Metadata Defined" := true;
                rec."Index Name" := keyRec."Key name";
                rec."Source App ID" := keyRec."Source App ID";

                rec.Insert();
            until keyRec.Next() = 0;
        end;

        exit(rec.Find(Which));
    end;

    procedure SetCompanyFilter(cn: Text[30])
    begin
        setCompanyName := cn;

        // Clear the temporary table to make sure only indexes for the selected company is shown.
        rec.DeleteAll();
    end;

    var
        setCompanyName: Text[30];
}
