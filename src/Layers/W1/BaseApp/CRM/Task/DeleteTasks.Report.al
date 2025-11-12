// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

report 5188 "Delete Tasks"
{
    Caption = 'Delete Tasks';
    ProcessingOnly = true;

    dataset
    {
        dataitem("To-do"; "To-do")
        {
            DataItemTableView = where(Canceled = const(true), "System To-do Type" = filter(Organizer | Team));
            RequestFilterFields = "No.", Date, "Salesperson Code", "Team Code", "Campaign No.", "Contact No.";

            trigger OnAfterGetRecord()
            begin
                if ("Team Code" = '') or ("System To-do Type" = "System To-do Type"::Team) then
                    Delete(true)
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }
}

