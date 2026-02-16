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
    DataCaptionExpression = StrSubstNo('%1 - %2', Rec.Name, Rec.ID);
    Permissions = tabledata "Table Metadata" = r,
                  tabledata "Database Index" = r;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(TableNo; Rec.ID)
                {
                    Caption = 'Table No.';
                    Editable = false;
                    ToolTip = 'Specifies the number for the table.';
                }
                field(TableName; Rec.Name)
                {
                    Caption = 'Table Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the table.';
                }
                field(Company; SetCompanyName)
                {
                    Enabled = PerCompany;
                    Caption = 'Company Name';
                    TableRelation = Company.Name;
                    ToolTip = 'Specifies the name of the company the table belongs to if the table is per-company. Changing this value will update the data shown on this page to reflect the selected company.';

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
                    ToolTip = 'Specifies the combined size of all indexes on the table for this company, presented in kilobytes.';
                }
                field(RowCount; RowCount)
                {
                    Caption = 'Table Row Count';
                    Editable = false;
                    ToolTip = 'Specifies the number of rows in the table for this company.';
                }
                field("Database start time"; SqlServerRestartTime)
                {
                    Caption = 'Database start time';
                    Editable = false;
                    ToolTip = 'Specifies the last time the database engine was started. Index statistics are reset when SQL Server is restarted.';
                }
            }

            part(IndexLines; "Indexes List Part")
            {
                SubPageLink = TableId = field(ID);
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetBasedOnCompanyName(Rec.CurrentCompany());
    end;

    local procedure SetBasedOnCompanyName(NewCompanyName: Text)
    var
        DatabaseIndex: Record "Database Index";
        TableMetadata: Record "Table Metadata";
        Recref: RecordRef;
        TableId: Integer;
    begin
        if Rec.ID <> 0 then
            TableId := Rec.ID
        else
            if Evaluate(TableId, Rec.GetFilter("ID")) and (TableId <> 0) then
                TableId := TableId
            else
                exit;

        if not TableMetadata.Get(TableId) then
            exit;

        // By-default show data for the current company.
        if TableMetadata.DataPerCompany and (NewCompanyName <> '') then begin
            SetCompanyName := NewCompanyName;
            PerCompany := true;

            DatabaseIndex.SetRange(DatabaseIndex."Company Name", SetCompanyName);
        end;

        Recref.Open(TableId, false, SetCompanyName);

        RowCount := Recref.Count();
        IndexSizeKB := 0;
        SqlServerRestartTime := 0DT;
        DatabaseIndex.SetRange(DatabaseIndex.TableId, TableId);
        if DatabaseIndex.FindSet() then
            repeat
                if SqlServerRestartTime = 0DT then
                    SqlServerRestartTime := DatabaseIndex."Database Start time";

                IndexSizeKB += DatabaseIndex."Index Size (KB)";
            until DatabaseIndex.Next() = 0;

        CurrPage.IndexLines.Page.SetCompanyFilter(SetCompanyName);
    end;

    var
        IndexSizeKB: BigInteger;
        RowCount: Integer;
        SetCompanyName: Text;
        SqlServerRestartTime: DateTime;
        PerCompany: Boolean;
}
