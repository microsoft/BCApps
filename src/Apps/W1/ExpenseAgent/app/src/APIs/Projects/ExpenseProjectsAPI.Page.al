// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7092 "Expense Projects API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'expenseProject';
    EntitySetName = 'expenseProjects';
    EntityCaption = 'Expense Project';
    EntitySetCaption = 'Expense Projects';
    SourceTable = "Expense Project Buf";
    SourceTableTemporary = true;
    ODataKeyFields = "Expense User SystemId", "Project No.", "Project Task No.";
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutTitle = 'Expense Projects';
    AboutText = 'Returns, as a flat list of project/posting-task rows, the projects an Expense User can post expenses against. Requires an expenseUserSystemId filter. When Project Visibility is "All projects" every non-completed project is returned; otherwise only the projects and tasks assigned to the user are returned.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(expenseUserSystemId; Rec."Expense User SystemId")
                {
                    Caption = 'Expense User System Id';
                }
                field(systemId; Rec."Project SystemId")
                {
                    Caption = 'System Id';
                }
                field(projectNo; Rec."Project No.")
                {
                    Caption = 'Project No.';
                }
                field(projectDescription; Rec."Project Description")
                {
                    Caption = 'Project Description';
                }
                field(projectStatus; Rec."Project Status")
                {
                    Caption = 'Project Status';
                }
                field(projectStartingDate; Rec."Project Starting Date")
                {
                    Caption = 'Project Starting Date';
                }
                field(projectEndingDate; Rec."Project Ending Date")
                {
                    Caption = 'Project Ending Date';
                }
                field(taskSystemId; Rec."Task SystemId")
                {
                    Caption = 'Task System Id';
                }
                field(projectTaskNo; Rec."Project Task No.")
                {
                    Caption = 'Project Task No.';
                }
                field(taskDescription; Rec."Task Description")
                {
                    Caption = 'Task Description';
                }
                field(taskType; Rec."Task Type")
                {
                    Caption = 'Task Type';
                }
                field(taskStartDate; Rec."Task Start Date")
                {
                    Caption = 'Task Start Date';
                }
                field(taskEndDate; Rec."Task End Date")
                {
                    Caption = 'Task End Date';
                }
            }
        }
    }

    var
        Builder: Codeunit "Expense Projects Builder";
        Loaded: Boolean;
        ProjectFieldsNotEnabledErr: Label 'Project fields are not enabled in the Expense Agent Setup.';
        ScopeRequiredErr: Label 'A filter on expenseUserSystemId is required.';

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        ExpenseCapabilitiesProvider: Codeunit "Expense Capabilities Provider";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
        if not ExpenseCapabilitiesProvider.IsEnabled(Enum::"Expense Capability"::Projects) then
            Error(ProjectFieldsNotEnabledErr);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        UserFilter: Text;
        FilterView: Text;
    begin
        if not Loaded then begin
            UserFilter := Rec.GetFilter("Expense User SystemId");
            if UserFilter = '' then
                Error(ScopeRequiredErr);
            FilterView := Rec.GetView();
            Builder.BuildProjects(Rec, UserFilter);
            Rec.SetView(FilterView);
            Loaded := true;
        end;
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Rec.Next(Steps));
    end;
}
