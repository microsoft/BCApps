// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Service.Document;
using System.Security.User;

page 5989 "Service Item Log"
{
    ApplicationArea = Service;
    Caption = 'Service Item Log';
    DataCaptionExpression = GetCaptionHeader();
    Editable = false;
    PageType = List;
    SourceTable = "Service Item Log";
    SourceTableView = order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the event associated with the service item.';
                    Visible = ServiceItemNoVisible;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("ServLogMgt.ServItemEventDescription(""Event No."")"; ServLogMgt.ServItemEventDescription(Rec."Event No."))
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the event regarding service item that has taken place.';
                }
                field(After; Rec.After)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value of the field modified after the event takes place.';
                }
                field(Before; Rec.Before)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the previous value of the field, modified after the event takes place.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the document type of the service item associated with the event, such as contract, order, or quote.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the document number of the event associated with the service item.';
                }
                field("Change Date"; Rec."Change Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the event.';
                }
                field("Change Time"; Rec."Change Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time of the event.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Delete Service Item Log")
                {
                    ApplicationArea = Service;
                    Caption = 'Delete Service Item Log';
                    Ellipsis = true;
                    Image = Delete;
                    ToolTip = 'Delete the log of service activities.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Delete Service Item Log", true, false, Rec);
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        ServiceItemNoVisible := true;
    end;

    var
        ServLogMgt: Codeunit ServLogManagement;
        ServiceItemNoVisible: Boolean;

    local procedure GetCaptionHeader(): Text[250]
    var
        ServItem: Record "Service Item";
    begin
        if Rec.GetFilter("Service Item No.") <> '' then begin
            ServiceItemNoVisible := false;
            if ServItem.Get(Rec."Service Item No.") then
                exit(Rec."Service Item No." + ' ' + ServItem.Description);

            exit(Rec."Service Item No.");
        end;

        ServiceItemNoVisible := true;
        exit('');
    end;
}

