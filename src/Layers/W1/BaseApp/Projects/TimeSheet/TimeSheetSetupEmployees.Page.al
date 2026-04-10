// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.HumanResources.Employee;

page 979 "Time Sheet Setup Employees"
{
    PageType = ListPart;
    SourceTable = Employee;
    Caption = 'Employees';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies an identification number for the entry or record.';
                }
                field(FullName; Rec.FullName())
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Full Name';
                    ToolTip = 'Specifies the full name of the employee.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a resource number for the employee.';
                }
            }

        }
    }
}
