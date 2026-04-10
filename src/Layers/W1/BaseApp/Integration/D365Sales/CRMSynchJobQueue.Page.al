// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.SyncEngine;
using System.Threading;

page 5373 "CRM Synch. Job Queue"
{
    Caption = 'Microsoft Dynamics 365 Sales Synch. Job Queue';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Job Queue Entry";
    SourceTableView = sorting("Last Ready State");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Last Ready State"; Rec."Last Ready State")
                {
                    ApplicationArea = Suite;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date and time when the Dynamics 365 Sales synchronization job was set to Ready and sent to the job queue.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies the latest error message that was received from the job queue entry. You can view the error message if the Status field is set to Error. The field can contain up to 250 characters.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(EditJob)
            {
                ApplicationArea = Suite;
                Caption = 'Edit Job';
                Image = Edit;
                RunObject = Page "Job Queue Entry Card";
                RunPageOnRec = true;
                ShortCutKey = 'Return';
                ToolTip = 'Change the settings for the job queue entry.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusIsError := Rec.Status = Rec.Status::Error;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange(Status, Rec.Status::Error);
        Rec.SetFilter("Object ID to Run", '%1|%2|%3', Codeunit::"Integration Synch. Job Runner", Codeunit::"Int. Uncouple Job Runner", Codeunit::"Int. Coupling Job Runner");
    end;

    var
        StatusIsError: Boolean;
}

