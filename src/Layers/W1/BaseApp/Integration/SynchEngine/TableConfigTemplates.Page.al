// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Globalization;

page 5325 "Table Config Templates"
{
    Caption = 'Table Config Templates';
    PageType = List;
    SourceTable = "Table Config Template";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table Config Template Code"; Rec."Table Config Template Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a configuration template to use when creating new records in the Business Central table during synchronization.';
                }
                field("Integration Table Filter"; IntegrationTableFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Table Filter';
                    ToolTip = 'Specifies the configuration template inclusion filter on the Dataverse table.';

                    trigger OnAssistEdit()
                    var
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        FilterPageBuilder.AddTable(IntegrationTableCaptionValue, Rec."Integration Table ID");
                        if IntegrationTableFilter <> '' then
                            FilterPageBuilder.SetView(IntegrationTableCaptionValue, IntegrationTableFilter);
                        if FilterPageBuilder.RunModal() then begin
                            IntegrationTableFilter := FilterPageBuilder.GetView(IntegrationTableCaptionValue, false);
                            Rec.SetIntegrationTableFilter(IntegrationTableFilter);
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
        IntegrationTableCaptionValue := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, Rec."Integration Table ID");
        IntegrationTableFilter := Rec.GetIntegrationTableFilter();
    end;

    var
        ObjectTranslation: Record "Object Translation";
        IntegrationTableFilter: Text;
        IntegrationTableCaptionValue: Text[250];
        IntegrationTableMappingFilter: Text;
}