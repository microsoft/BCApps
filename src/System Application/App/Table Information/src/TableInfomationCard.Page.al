// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

using System.Diagnostics;
using System.Environment;
using System.Reflection;

/// <summary>
/// Page which displays detailed database information for a given table.
/// </summary>
page 8705 "Table Information Card"
{
    PageType = Card;

    ApplicationArea = All;
    AdditionalSearchTerms = 'Database,Size,Storage';
    SourceTable = "Table Metadata";

    Caption = 'Table Data Management - Card';

    Permissions = tabledata "Table Metadata" = r,
                  tabledata "Database Index" = r;

    DataCaptionExpression = StrSubstNo('%1 - %2', rec.Name, rec.ID);

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TableNo; rec.ID)
                {
                    Caption = 'Table No.';
                    Editable = false;
                    ToolTip = 'The ID number for the table';
                }
                field(TableName; rec.Name)
                {
                    Caption = 'Table Name';
                    Editable = false;
                    ToolTip = 'The name of the table';
                }
                field(Company; SetCompanyName)
                {
                    Enabled = PerCompany;
                    Caption = 'Company Name';
                    TableRelation = Company.Name;
                    ToolTip = 'The name of the company the table belongs to if table is per-company. Changing this value will update the data shown on this page to reflect the selected company.';

                    trigger OnValidate()
                    begin
                        SetBasedOnCompanyName(SetCompanyName);

                        CurrPage.Update(false);
                    end;
                }
                field(IndexSize; IndexSizeKB)
                {
                    Caption = 'Combined Index Size (KB)';
                    Editable = false;
                    ToolTip = 'The combined size of all indexes on the table for this company, presented in kilobytes.';
                }
                field(RowCount; RowCount)
                {
                    Caption = 'Table Row Count';
                    Editable = false;
                    ToolTip = 'The number of rows in the table for this company';
                }
                field("Database start time"; SqlServerRestartTime)
                {
                    Caption = 'Database start time';
                    Editable = false;
                    ToolTip = 'The last time the database engineer was. Index statistics are reset when SQL Server is restarted.';
                }
            }

            part(IndexLines; "Indexes List Part")
            {
                SubPageLink = TableId = FIELD(ID);
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetBasedOnCompanyName(rec.CurrentCompany());
    end;

    local procedure SetBasedOnCompanyName(cn: Text[30])
    var
        recref: RecordRef;
        DatabaseIndex: Record "Database Index";
        TableMetadata: Record "Table Metadata";
        TableId: Integer;
    begin
        if (Rec.ID <> 0)
        then
            TableId := Rec.ID
        else if (Evaluate(TableId, Rec.GetFilter("ID")) AND (TableId <> 0)) then
            TableId := TableId
        else
            exit;

        if (TableMetadata.Get(TableId) = false) then
            exit;

        // By-default show data for the current company.
        if (TableMetadata.DataPerCompany and (cn <> '')) then begin
            SetCompanyName := cn;
            PerCompany := true;

            DatabaseIndex.SetRange(DatabaseIndex."Company Name", SetCompanyName);
        end;

        recref.Open(TableId, false, SetCompanyName);

        RowCount := recref.Count();
        IndexSizeKB := 0;
        SqlServerRestartTime := 0DT;
        DatabaseIndex.SetRange(DatabaseIndex.TableId, TableId);
        if (DatabaseIndex.FindSet()) then
            repeat
                if (SqlServerRestartTime = 0DT) then
                    SqlServerRestartTime := DatabaseIndex."Database Start time";

                IndexSizeKB += DatabaseIndex."Index Size (KB)";
            until DatabaseIndex.Next() = 0;

        CurrPage.IndexLines.Page.SetCompanyFilter(SetCompanyName);
    end;

    var
        IndexSizeKB: BigInteger;
        RowCount: Integer;
        SetCompanyName: Text[30];
        SqlServerRestartTime: DateTime;
        PerCompany: Boolean;
}
