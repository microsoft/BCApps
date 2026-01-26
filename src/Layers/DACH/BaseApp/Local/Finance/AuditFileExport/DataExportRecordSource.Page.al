// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;
using System.Text;

page 11004 "Data Export Record Source"
{
    AutoSplitKey = true;
    Caption = 'Data Export Record Source';
    DataCaptionFields = "Data Exp. Rec. Type Code";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Data Export Record Source";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Table Name";
                ShowCaption = false;
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the table that you selected for the record source.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Enabled = false;
                    ToolTip = 'Specifies the name of the table that you selected in the Table No. field.';
                }
                field("Export Table Name"; Rec."Export Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a name for the data from this source table that can be accepted by the auditor''s tools.';
                }
                field("Period Field No."; Rec."Period Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the date field used to calculate the period for the data export.';
                }
                field("Period Field Name"; Rec."Period Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the date field used to calculate the period for the data export.';
                }
                field("Table Filter"; Rec."Table Filter")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Editable = false;
                    ToolTip = 'Specifies a table filter in a data export record source.';

                    trigger OnAssistEdit()
                    var
                        TableFilter: Record "Table Filter";
                        TableFilterPage: Page "Table Filter";
                        TableFilterText: Text;
                    begin
                        TableFilter.FilterGroup(2);
                        TableFilter.SetRange("Table Number", Rec."Table No.");
                        TableFilter.FilterGroup(0);
                        TableFilterPage.SetTableView(TableFilter);
                        TableFilterPage.SetSourceTable(Format(Rec."Table Filter"), Rec."Table No.", Rec."Table Name");
                        if ACTION::OK = TableFilterPage.RunModal() then begin
                            TableFilterText := TableFilterPage.CreateTextTableFilterWithoutTableName(false);
                            if TableFilterText = '' then
                                Evaluate(Rec."Table Filter", '')
                            else
                                Evaluate(Rec."Table Filter", TableFilterPage.CreateTextTableFilter(false));
                            Rec.Validate("Table Filter");
                        end;
                    end;
                }
                field("Date Filter Field No."; Rec."Date Filter Field No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID for the date filter on the data export record definition source table.';
                }
                field("Date Filter Handling"; Rec."Date Filter Handling")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the field Starting Date and Ending Date in the Export Business Data batch job, influence the calculation.';
                }
                field("Key No."; Rec."Key No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the table key to be used to sort the exported data.';
                }
                field("Export File Name"; Rec."Export File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name for the file that the data will be exported to.';
                }
                field("Table Relation Defined"; Rec."Table Relation Defined")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you have defined a table relationship for this table.';

                    trigger OnAssistEdit()
                    var
                        DataExportManagement: Codeunit "Data Export Management";
                    begin
                        CurrPage.Update(true);
                        Commit();
                        DataExportManagement.UpdateTableRelation(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            part("Fields"; "Data Export Record Fields")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Fields';
                SubPageLink = "Data Export Code" = field("Data Export Code"),
                              "Data Exp. Rec. Type Code" = field("Data Exp. Rec. Type Code"),
                              "Source Line No." = field("Line No."),
                              "Table No." = field("Table No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1140006; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                Image = Setup;
                action(Validate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate';
                    Image = Approve;
                    ToolTip = 'Test the specified data before you export it.';

                    trigger OnAction()
                    var
                        DataExportRecordDefinition: Record "Data Export Record Definition";
                    begin
                        DataExportRecordDefinition.Get(Rec."Data Export Code", Rec."Data Exp. Rec. Type Code");
                        DataExportRecordDefinition.ValidateExportSources();
                    end;
                }
            }
            group(Indentation)
            {
                Caption = 'Indentation';
                action(Indent)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Indent';
                    Image = Indent;
                    ToolTip = 'Indent the selected table, for example after you have added it as a related table to the source table on the line above it. ';

                    trigger OnAction()
                    begin
                        Rec.Validate(Indentation, Rec.Indentation + 1);
                        CurrPage.Update();
                    end;
                }
                action(Unindent)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unindent';
                    Image = CancelIndent;
                    ToolTip = 'Remove the indentation of the selected table. ';

                    trigger OnAction()
                    begin
                        Rec.Validate(Indentation, Rec.Indentation - 1);
                        CurrPage.Update();
                    end;
                }
                action(Relationships)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Relationships';
                    Image = Relationship;
                    ToolTip = 'View the related tables of the selected table.';

                    trigger OnAction()
                    var
                        DataExportManagement: Codeunit "Data Export Management";
                    begin
                        DataExportManagement.UpdateTableRelation(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Validate_Promoted; Validate)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Indentation', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Indent_Promoted; Indent)
                {
                }
                actionref(Unindent_Promoted; Unindent)
                {
                }
                actionref(Relationships_Promoted; Relationships)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        MoveFiltersToFilterGroup(2);
    end;

    [Scope('OnPrem')]
    procedure MoveFiltersToFilterGroup(FilterGroupNo: Integer)
    var
        Filters: Text;
    begin
        Rec.FilterGroup(0);
        Filters := Rec.GetView();
        Rec.FilterGroup(FilterGroupNo);
        Rec.SetView(Filters);
        Rec.FilterGroup(0);
        Rec.SetView('');
    end;
}

