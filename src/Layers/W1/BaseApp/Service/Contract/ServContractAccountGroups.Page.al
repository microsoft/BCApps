// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6070 "Serv. Contract Account Groups"
{
    ApplicationArea = Service;
    Caption = 'Serv. Contract Account Groups';
    PageType = List;
    SourceTable = "Service Contract Account Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code assigned to the service contract account group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract account group.';
                }
                field("Non-Prepaid Contract Acc."; Rec."Non-Prepaid Contract Acc.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the general ledger account number for the non-prepaid account.';
                }
                field("Prepaid Contract Acc."; Rec."Prepaid Contract Acc.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the general ledger account number for the prepaid account.';
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
    }
}

