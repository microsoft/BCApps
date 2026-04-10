// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Displays list of consolidation processes in progress with status monitoring and management capabilities.
/// Provides real-time view of running consolidation operations with process details and error information.
/// </summary>
/// <remarks>
/// Process monitoring page for tracking consolidation execution status across multiple business units.
/// Shows consolidation process details, execution status, error messages, and completion information.
/// Enables consolidation process management with delete capabilities for completed or failed processes.
/// </remarks>
page 245 "Consolidations in Progress"
{
    ApplicationArea = All;
    Caption = 'Consolidation status';
    SourceTable = "Consolidation Process";
    SourceTableView = order(descending);
    PageType = List;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Consolidations)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Starting Date';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Ending Date';
                }
                field(ScheduledAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Scheduled At';
                    ToolTip = 'Date and time when the consolidation was scheduled';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SeeDetails)
            {
                ApplicationArea = All;
                Caption = 'See Details';
                ToolTip = 'See details of the consolidation process';
                RunPageOnRec = true;
                Scope = Repeater;
                Image = ViewDetails;

                trigger OnAction()
                var
                    ConsProcessDetails: Page "Cons. Process Details";
                begin
                    ConsProcessDetails.SetConsolidationProcess(Rec.Id);
                    ConsProcessDetails.Run();
                end;
            }
        }
    }
}
