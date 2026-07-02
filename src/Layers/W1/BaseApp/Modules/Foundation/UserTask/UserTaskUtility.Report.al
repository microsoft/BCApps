// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

report 1170 "User Task Utility"
{
    Caption = 'User Task Utility';
    ProcessingOnly = true;

    dataset
    {
        dataitem("User Task"; "User Task")
        {
            RequestFilterFields = "Completed DateTime", "Assigned To", "Created By";

            trigger OnAfterGetRecord()
            begin
                Delete();
            end;

            trigger OnPreDataItem()
            var
                Filters: Text;
            begin
                Filters := GetFilters();

                if Filters = '' then begin
                    Message(NoFilterMsg);
                    CurrReport.Quit();
                end;
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

    var
        NoFilterMsg: Label 'No user tasks were deleted. To specify the user tasks that must be deleted, set the relevant filters.';
}

