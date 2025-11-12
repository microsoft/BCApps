// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.RoleCenters;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Resource;

page 9067 "Resource Manager Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Job Cue";

    layout
    {
        area(content)
        {
            cuegroup(Allocation)
            {
                Caption = 'Allocation';
                field("Available Resources"; Rec."Available Resources")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Resource List";
                    ToolTip = 'Specifies the number of available resources that are displayed in the Project Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Jobs w/o Resource"; Rec."Jobs w/o Resource")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Job List";
                    ToolTip = 'Specifies the number of projects without an assigned resource that are displayed in the Project Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Unassigned Resource Groups"; Rec."Unassigned Resource Groups")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Resource Groups";
                    ToolTip = 'Specifies the number of unassigned resource groups that are displayed in the Project Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Resource Capacity")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity';
                        RunObject = Page "Resource Capacity";
                        ToolTip = 'View the capacity of the resource.';
                    }
                    action("Resource Group Capacity")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Group Capacity';
                        RunObject = Page "Res. Group Capacity";
                        ToolTip = 'View the capacity of resource groups.';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRange("Date Filter", WorkDate(), WorkDate());
        Rec.SetRange("User ID Filter", UserId());
    end;
}

