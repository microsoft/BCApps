// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

query 1038 "Job Task by Bill-to Customer"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Job_Task; "Job Task")
        {
            DataItemTableFilter = "Bill-to Customer No." = filter(<> '');
            column(Job_No; "Job No.")
            {
            }
            column(Job_Task_No_Count)
            {
                Method = Count;
            }
            filter(Bill_to_Customer_No_Filter; "Bill-to Customer No.")
            {
            }
        }
    }
}