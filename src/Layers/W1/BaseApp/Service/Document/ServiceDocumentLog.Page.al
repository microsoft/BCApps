// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Service.History;
using Microsoft.Utilities;
using System.Security.User;

page 5920 "Service Document Log"
{
    ApplicationArea = Service;
    Caption = 'Service Document Log';
    DataCaptionExpression = GetCaptionHeader();
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Service Document Log";
    SourceTableView = sorting("Change Date", "Change Time")
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service document that underwent changes.';
                    Visible = DocumentTypeVisible;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service document that has undergone changes.';
                    Visible = DocumentNoVisible;
                }
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line, if the event is linked to a service item line.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
#pragma warning disable AA0100
                field("ServLogMgt.ServOrderEventDescription(""Event No."")"; ServLogMgt.ServOrderEventDescription(Rec."Event No."))
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the event that occurred to a particular service document.';
                }
                field(After; Rec.After)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contents of the modified field after the event takes place.';
                }
                field(Before; Rec.Before)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contents of the modified field before the event takes place.';
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
                action("&Delete Service Document Log")
                {
                    ApplicationArea = Service;
                    Caption = '&Delete Service Document Log';
                    Ellipsis = true;
                    Image = Delete;
                    ToolTip = 'Delete the automatically generated service document log entries, for example, the unnecessary or outdated ones.';

                    trigger OnAction()
                    var
                        ServOrderLog: Record "Service Document Log";
                        DeleteServOrderLog: Report "Delete Service Document Log";
                    begin
                        ServOrderLog.SetRange("Document Type", Rec."Document Type");
                        ServOrderLog.SetRange("Document No.", Rec."Document No.");
                        DeleteServOrderLog.SetTableView(ServOrderLog);
                        DeleteServOrderLog.RunModal();

                        if DeleteServOrderLog.GetOnPostReportStatus() then begin
                            ServOrderLog.Reset();
                            DeleteServOrderLog.GetServDocLog(ServOrderLog);
                            Rec.CopyFilters(ServOrderLog);
                            Rec.DeleteAll();
                            Rec.Reset();
                            Rec.SetCurrentKey("Change Date", "Change Time");
                            Rec.Ascending(false);
                        end;
                    end;
                }
            }
            action("&Show")
            {
                ApplicationArea = Service;
                Caption = '&Show';
                Image = View;
                ToolTip = 'View the log details.';

                trigger OnAction()
                var
                    ServShptHeader: Record "Service Shipment Header";
                    ServInvHeader: Record "Service Invoice Header";
                    ServCrMemoHeader: Record "Service Cr.Memo Header";
                    PageManagement: Codeunit "Page Management";
                    isError: Boolean;
                begin
                    if Rec."Document Type" in
                       [Rec."Document Type"::Order, Rec."Document Type"::Quote,
                        Rec."Document Type"::Invoice, Rec."Document Type"::"Credit Memo"]
                    then
                        if ServOrderHeaderRec.Get(Rec."Document Type", Rec."Document No.") then begin
                            isError := false;
                            PageManagement.PageRun(ServOrderHeaderRec);
                        end else
                            isError := true
                    else begin // posted documents
                        isError := true;
                        case Rec."Document Type" of
                            Rec."Document Type"::Shipment:
                                if ServShptHeader.Get(Rec."Document No.") then begin
                                    isError := false;
                                    PAGE.Run(PAGE::"Posted Service Shipment", ServShptHeader);
                                end;
                            Rec."Document Type"::"Posted Invoice":
                                if ServInvHeader.Get(Rec."Document No.") then begin
                                    isError := false;
                                    PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader);
                                end;
                            Rec."Document Type"::"Posted Credit Memo":
                                if ServCrMemoHeader.Get(Rec."Document No.") then begin
                                    isError := false;
                                    PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader);
                                end;
                        end;
                    end;
                    if isError then
                        Error(Text001, Rec."Document Type", Rec."Document No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Show_Promoted"; "&Show")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        DocumentNoVisible := true;
        DocumentTypeVisible := true;
    end;

    var
        ServOrderHeaderRec: Record "Service Header";
        ServLogMgt: Codeunit ServLogManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Service %1 %2 does not exist.', Comment = 'Service Order 2001 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DocumentTypeVisible: Boolean;
        DocumentNoVisible: Boolean;

    local procedure GetCaptionHeader(): Text[250]
    var
        ServHeader: Record "Service Header";
    begin
        if Rec.GetFilter(Rec."Document No.") <> '' then begin
            DocumentTypeVisible := false;
            DocumentNoVisible := false;
            if ServHeader.Get(Rec."Document Type", Rec."Document No.") then
                exit(Format(Rec."Document Type") + ' ' + Rec."Document No." + ' ' + ServHeader.Description);

            exit(Format(Rec."Document Type") + ' ' + Rec."Document No.");
        end;

        DocumentTypeVisible := true;
        DocumentNoVisible := true;
        exit('');
    end;
}

