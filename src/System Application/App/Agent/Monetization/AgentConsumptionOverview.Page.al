// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment.Consumption;
using System.Security.AccessControl;

page 4333 "Agent Consumption Overview"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "User AI Consumption Data";
    Caption = 'Agent consumption overview';
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTableView = sorting("Consumption DateTime") order(descending);
    Permissions = tabledata User = r, tabledata "User AI Consumption Data" = r;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Agent; Rec."Feature Name")
                {
                    Caption = 'Feature name';
                }
                field(UserName; UserName)
                {
                    Caption = 'User Name';
                    ToolTip = 'Specifies the name of the user who performed the operation.';
                }
                field("Agent Task ID"; Rec."Agent Task ID")
                {
                }
                field(Operation; Rec."Actions")
                {
                    Caption = 'Actions';
                }
                field(Description; DescriptionTxt)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the operation';
                    trigger OnDrillDown()
                    begin
                        Message(DescriptionTxt);
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    Visible = false;
                }
                field(CopilotStudioFeature; Rec."Copilot Studio Feature")
                {
                    Caption = 'Copilot Studio Feature';
                }
                field(Credits; Rec."Copilot Credits")
                {
                    AutoFormatType = 0;
                    Caption = 'Quantity';
                }
                field(ConsumptionDateTime; Rec."Consumption DateTime")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        CurrentModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Rec.SetRange("App Id", CurrentModule.Id);
    end;

    trigger OnAfterGetRecord()
    var
        User: Record User;
        DescriptionInStream: InStream;
    begin
        Rec.CalcFields(Description);
        Rec.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
        DescriptionInStream.ReadText(DescriptionTxt);
        if User.Get(Rec."User Id") then
            UserName := User."Full Name";
    end;

    var
        DescriptionTxt: Text;
        UserName: Text[80];
}