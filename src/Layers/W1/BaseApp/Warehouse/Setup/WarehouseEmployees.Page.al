// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Inventory.Location;
using System.Security.User;

page 7328 "Warehouse Employees"
{
    AdditionalSearchTerms = 'warehouse worker';
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Employees';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Warehouse Employee";
    UsageCategory = Administration;
    PopulateAllFields = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the user ID of a warehouse employee. Each user who performs warehouse activities must be set up as a warehouse employee and assigned to at least one location.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the location in which the employee works.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the location code that is defined as the default location for this employee''s activities.';
                }
                field("ADCS User"; Rec."ADCS User")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'ADCS User';
                    ToolTip = 'Specifies the ADCS user name of a warehouse employee.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Add Me")
            {
                Caption = 'Add me as Warehouse Employee';
                ToolTip = 'Add yourself as a warehouse employee at selected locations.';
                Image = Employee;

                trigger OnAction()
                var
                    Location: Record Location;
                    WarehouseEmployee: Record "Warehouse Employee";
                    SelectedLocationsFilter: Text;
                begin
                    SelectedLocationsFilter := Location.SelectMultipleLocations();
                    if SelectedLocationsFilter = '' then
                        exit;

                    Location.SetFilter(Code, SelectedLocationsFilter);
                    if Location.FindSet() then
                        repeat
                            WarehouseEmployee.Init();
                            WarehouseEmployee."User ID" := CopyStr(UserId(), 1, MaxStrLen(WarehouseEmployee."User ID"));
                            WarehouseEmployee."Location Code" := Location.Code;
                            if WarehouseEmployee.Insert() then;
                        until Location.Next() = 0;
                end;
            }
        }
        area(Promoted)
        {
            actionref("Add Me_Promoted"; "Add Me")
            {

            }
        }
    }
}

