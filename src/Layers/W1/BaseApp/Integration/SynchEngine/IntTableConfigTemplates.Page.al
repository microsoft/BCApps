// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;
using System.Globalization;

page 5326 "Int. Table Config Templates"
{
    Caption = 'Integration Table Config Templates';
    PageType = List;
    SourceTable = "Int. Table Config Template";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Integration Table Config Template Code"; Rec."Int. Tbl. Config Template Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a configuration template to use when creating new records in the Dataverse table during synchronization.';
                }
                field("Table Filter"; TableFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Table Filter';
                    ToolTip = 'Specifies the configuration template inclusion filter on the Business Central table.';

                    trigger OnAssistEdit()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        Codeunit.Run(Codeunit::"CRM Integration Management");
                        FilterPageBuilder.AddTable(TableCaptionValue, Rec."Table ID");
                        if TableFilter <> '' then
                            FilterPageBuilder.SetView(TableCaptionValue, TableFilter);
                        Commit();
                        if FilterPageBuilder.RunModal() then begin
                            TableFilter := FilterPageBuilder.GetView(TableCaptionValue, false);
                            Rec.SetTableFilter(TableFilter);
                        end;
                    end;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the priority of the configuration template.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Evaluate(Rec."Integration Table Mapping Name", IntegrationTableMappingFilter);
        IntegrationTableMapping.Get(Rec."Integration Table Mapping Name");
        Rec."Table ID" := IntegrationTableMapping."Table ID";
        Rec."Integration Table ID" := IntegrationTableMapping."Integration Table ID";
    end;

    trigger OnOpenPage()
    begin
        IntegrationTableMappingFilter := Rec.GetFilter("Integration Table Mapping Name");
    end;

    trigger OnAfterGetRecord()
    begin
        TableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, Rec."Table ID");
        TableFilter := Rec.GetTableFilter();
    end;

    var
        ObjectTranslation: Record "Object Translation";
        TableFilter: Text;
        TableCaptionValue: Text[250];
        IntegrationTableMappingFilter: Text;
}