// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.RoleCenters;

using Microsoft.Foundation.Navigate;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Reports;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;

page 8904 "Project Manager Role Center"
{
    Caption = 'Project Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Projects';
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Job List";
                }
                action("Job WIP Worksheet")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project WIP Cockpit';
                    RunObject = page "Job WIP Cockpit";
                }
                action("Manager Time Sheet by Job")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Manager Time Sheet by Project';
                    RunObject = page "Manager Time Sheet by Job";
                }
                action("Job Calculate WIP")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Calculate WIP';
                    RunObject = report "Job Calculate WIP";
                }
                action("Job Post WIP to G/L")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Post WIP to G/L';
                    RunObject = report "Job Post WIP to G/L";
                }
                action("Job Create Sales Invoice")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Create Sales Invoice';
                    RunObject = report "Job Create Sales Invoice";
                }
                group("Group1")
                {
                    Caption = 'Journals';
                    action("Job Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Journals';
                        RunObject = page "Job Journal";
                    }
                    action("Job G/L Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project G/L Journals';
                        RunObject = page "Job G/L Journal";
                    }
                    action("Recurring Journals")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Recurring Project Journals';
                        RunObject = page "Recurring Job Jnl.";
                    }
                }
                group("Group2")
                {
                    Caption = 'Register/Entries';
                    action("Job Registers")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Registers';
                        RunObject = page "Job Registers";
                    }
                    action("Job Ledger Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Ledger Entries';
                        RunObject = page "Job Ledger Entries";
                    }
                    action("Job WIP Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project WIP Entries';
                        RunObject = page "Job WIP Entries";
                    }
                    action("Job WIP G/L Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project WIP G/L Entries';
                        RunObject = page "Job WIP G/L Entries";
                    }
                    action("Resource Capacity Entries")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity Entries';
                        RunObject = page "Res. Capacity Entries";
                    }
                    action("Navi&gate")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        Image = Navigate;
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
                group("Group3")
                {
                    Caption = 'Reports';
                    action("Job Analysis")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Analysis';
                        RunObject = report "Job Analysis";
                    }
                    action("Job - Planing Lines")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project - Planning Lines';
                        RunObject = report "Job - Planning Lines";
                    }
                    action("Job - Transaction Detail")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project - Transaction Detail';
                        RunObject = report "Job - Transaction Detail";
                    }
                    action("Job Register")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Register';
                        RunObject = report "Job Register";
                    }
                    action("Job Actual To Budget")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Actual To Budget';
                        RunObject = report "Job Actual To Budget";
                    }
                    action("Job WIP To G/L")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project WIP To G/L';
                        RunObject = report "Job WIP To G/L";
                    }
                    action("Job Sug. Billing")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Suggested Billing';
                        RunObject = report "Job Suggested Billing";
                    }
                    action("Jobs per Customer")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Projects per Customer';
                        RunObject = report "Jobs per Customer";
                    }
                    action("Job/Item")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Items per Project';
                        RunObject = report "Items per Job";
                    }
                    action("Item/Job")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Projects per Item';
                        RunObject = report "Jobs per Item";
                    }
                }
                group("Group4")
                {
                    Caption = 'Setup';
                    action("Jobs Setup")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Projects Setup';
                        RunObject = page "Jobs Setup";
                        AccessByPermission = TableData "Job" = R;
                    }
                    action("Job Posting Groups")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Posting Groups';
                        RunObject = page "Job Posting Groups";
                    }
                    action("Job Journal Templates")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Journal Templates';
                        RunObject = page "Job Journal Templates";
                    }
                    action("Job WIP Methods")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project WIP Methods';
                        RunObject = page "Job WIP Methods";
                    }
                }
            }
        }
    }
}
