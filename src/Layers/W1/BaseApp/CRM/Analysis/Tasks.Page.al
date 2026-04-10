// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using System.Utilities;

page 5099 Tasks
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tasks';
    DataCaptionExpression = Format(SelectStr(OutputOption + 1, Text001));
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "RM Matrix Management";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(TableOption; TableOption)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show as Lines';
                    OptionCaption = 'Salesperson,Team,Campaign,Contact';
                    ToolTip = 'Specifies which values you want to show as lines in the window. This allows you to see the same matrix window from various perspectives, especially when you use both the Show as Lines field and the Show as Columns field.';
                }
                field(OutputOption; OutputOption)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Show';
                    OptionCaption = 'No. of Tasks,Contact No.';
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(FilterSalesPerson; FilterSalesPerson)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Salesperson Filter';
                    TableRelation = "Salesperson/Purchaser";
                    ToolTip = 'Specifies which salespeople will be included in the Tasks matrix view.';
                }
                field(FilterTeam; FilterTeam)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team Filter';
                    TableRelation = Team;
                    ToolTip = 'Specifies which teams will be included in the Tasks matrix view.';
                }
                field(FilterCampaign; FilterCampaign)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign Filter';
                    TableRelation = Campaign;
                    ToolTip = 'Specifies which campaigns will be included in the Tasks matrix view.';
                }
                field(FilterContact; FilterContact)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Company No. Filter';
                    TableRelation = Contact where(Type = const(Company));
                    ToolTip = 'Specifies which contacts will be included in the Tasks matrix view.';
                }
                field(StatusFilter; StatusFilter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Status Filter';
                    OptionCaption = ' ,Not Started,In Progress,Completed,Waiting,Postponed';
                    ToolTip = 'Specifies what tasks statuses will be included in the Tasks matrix view.';
                }
                field(IncludeClosed; IncludeClosed)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Include Closed Tasks';
                    ToolTip = 'Specifies if closed tasks will be included in the Tasks matrix view.';
                }
                field(PriorityFilter; PriorityFilter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Priority Filter';
                    OptionCaption = ' ,Low,Normal,High';
                    ToolTip = 'Specifies which tasks priorities will be included in the Tasks matrix view.';
                }
            }
            group("Matrix Options")
            {
                Caption = 'Matrix Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        CreateCaptionSet(Enum::"Matrix Page Step Type"::Initial);
                    end;
                }
                field(ColumnSet; ColumnSet)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Column Set';
                    Editable = false;
                    ToolTip = 'Specifies the range of values that are displayed in the matrix window, for example, the total period. To change the contents of the field, choose Next Set or Previous Set.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowMatrix)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Show Matrix';
                Image = ShowMatrix;
                ToolTip = 'Show tasks in a matrix.';

                trigger OnAction()
                var
                    MatrixForm: Page "Tasks Matrix";
                begin
                    Clear(MatrixForm);
                    MatrixForm.Load(MatrixColumnCaptions, MatrixRecords, TableOption, ColumnDateFilters, OutputOption, FilterSalesPerson,
                      FilterTeam, FilterCampaign, FilterContact, StatusFilter, IncludeClosed, PriorityFilter);
                    MatrixForm.RunModal();
                end;
            }
            action("Previous Set")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Go to the previous set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(Enum::"Matrix Page Step Type"::Previous);
                end;
            }
            action("Next Set")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Go to the next set of data.';

                trigger OnAction()
                begin
                    CreateCaptionSet(Enum::"Matrix Page Step Type"::Next);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowMatrix_Promoted; ShowMatrix)
                {
                }
                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(true);
    end;

    trigger OnOpenPage()
    begin
        CurrSetLength := 32;
        CreateCaptionSet(Enum::"Matrix Page Step Type"::Initial);
    end;

    var
        MatrixRecords: array[32] of Record Date;
        MatrixMgt: Codeunit "Matrix Management";
        PeriodType: Enum "Analysis Period Type";
        OutputOption: Option "No. of Tasks","Contact No.";
        TableOption: Option Salesperson,Team,Campaign,Contact;
        StatusFilter: Option " ","Not Started","In Progress",Completed,Waiting,Postponed;
        PriorityFilter: Option " ",Low,Normal,High;
        IncludeClosed: Boolean;
        FilterSalesPerson: Code[250];
        FilterTeam: Code[250];
        FilterCampaign: Code[250];
        FilterContact: Code[250];
#pragma warning disable AA0074
        Text001: Label 'No. of Tasks,Contact No.';
#pragma warning restore AA0074
        ColumnDateFilters: array[32] of Text[50];
        MatrixColumnCaptions: array[32] of Text[1024];
        ColumnSet: Text[1024];
        PKFirstRecInCurrSet: Text[100];
        CurrSetLength: Integer;

    local procedure CreateCaptionSet(StepType: Enum "Matrix Page Step Type")
    begin
        MatrixMgt.GeneratePeriodMatrixData(
            StepType.AsInteger(), 32, false, PeriodType, '',
            PKFirstRecInCurrSet, MatrixColumnCaptions, ColumnSet, CurrSetLength, MatrixRecords);
    end;
}

