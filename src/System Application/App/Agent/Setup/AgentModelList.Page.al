// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4319 "Agent Model List"
{
    ApplicationArea = All;
    PageType = List;
    SourceTable = "Agent Model";
    Caption = 'Agent Models';
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Models)
            {
                field("Model ID"; Rec."Model ID")
                {
                    ApplicationArea = All;
                    Caption = 'Model ID';
                    ToolTip = 'Specifies the unique identifier of the agent model.';
                }
                field("Model Name"; Rec."Model Name")
                {
                    ApplicationArea = All;
                    Caption = 'Model Name';
                    ToolTip = 'Specifies the name of the agent model.';
                }
                field("Is Default"; Rec."Is Default")
                {
                    ApplicationArea = All;
                    Caption = 'Is Default';
                    ToolTip = 'Specifies whether this is the default agent model.';
                }
                field(Availability; Rec.Availability)
                {
                    ApplicationArea = All;
                    Caption = 'Availability';
                    ToolTip = 'Specifies the availability status of the agent model.';
                }
                field("Retirement Date"; Rec."Retirement Date")
                {
                    ApplicationArea = All;
                    Caption = 'Retirement Date';
                    ToolTip = 'Specifies the date when the agent model will be retired.';
                }
            }
        }
    }
}
