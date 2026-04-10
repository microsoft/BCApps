// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using System.Security.User;

page 6073 "Filed Service Contract List"
{
    ApplicationArea = Service;
    Caption = 'Filed Service Contracts';
    CardPageID = "Filed Service Contract";
    DataCaptionFields = "Contract No. Relation";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Filed Service Contract Header";
    UsageCategory = History;
    AdditionalSearchTerms = 'Filed Service Contract Quotes';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("File Date"; Rec."File Date")
                {
                    ApplicationArea = Service;
                }
                field("File Time"; Rec."File Time")
                {
                    ApplicationArea = Service;
                }
                field("Filed By"; Rec."Filed By")
                {
                    ApplicationArea = Service;

                    trigger OnDrillDown()
                    var
                        UserManagement: Codeunit "User Management";
                    begin
                        UserManagement.DisplayUserInformation(Rec."Filed By");
                    end;
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    DrillDown = false;
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

    trigger OnInit()
    begin
        CurrPage.LookupMode(false);
    end;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnResponsibilityCenter();
    end;
}

