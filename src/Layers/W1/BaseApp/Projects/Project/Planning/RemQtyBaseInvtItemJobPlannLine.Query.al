// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;

query 1003 RemQtyBaseInvtItemJobPlannLine
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in project planning lines.', Locked = true;

    elements
    {
        dataitem(Job_Planning_Line; "Job Planning Line")
        {
            DataItemTableFilter = Type = const(Item);
            filter(Job_No_; "Job No.")
            {
            }
            column(Remaining_Qty___Base_; "Remaining Qty. (Base)")
            {
                Method = Sum;
            }
            dataitem(Item; Item)
            {
                SqlJoinType = InnerJoin;
                DataItemLink = "No." = Job_Planning_Line."No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetJobPlanningLineFilter(Job: Record Job)
    begin
        SetRange(Job_No_, Job."No.");
    end;
}