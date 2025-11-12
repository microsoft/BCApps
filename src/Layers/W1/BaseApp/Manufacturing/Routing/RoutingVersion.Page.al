// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;
using System.Utilities;

page 99000810 "Routing Version"
{
    Caption = 'Routing Version';
    DataCaptionExpression = Rec.Caption();
    PageType = ListPlus;
    SourceTable = "Routing Version";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the routing.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the routing version.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies in which order operations in the routing are performed.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this routing version.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date for this routing version.';
                }
            }
            part(RoutingLine; "Routing Version Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Routing No." = field("Routing No."),
                              "Version Code" = field("Version Code");
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
                action(CopyRouting)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &Routing';
                    Image = CopyRouteHeader;
                    ToolTip = 'Copy an existing routing to quickly create a similar BOM.';

                    trigger OnAction()
                    var
                        RoutingHeader: Record "Routing Header";
                        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
                    begin
                        if not Confirm(CopyFromRoutingQst, false) then
                            exit;

                        RoutingHeader.Get(Rec."Routing No.");
                        RoutingLineCopyLines.CopyRouting(Rec."Routing No.", '', RoutingHeader, Rec."Version Code");
                    end;
                }
                action("Copy Routing &Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy Routing &Version';
                    Ellipsis = true;
                    Image = CopyRouteVersion;
                    ToolTip = 'Copy an existing routing version to quickly create a similar routing.';

                    trigger OnAction()
                    var
                        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
                    begin
                        RoutingLineCopyLines.SelectCopyFromVersionList(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyRouting_Promoted; CopyRouting)
                {
                }
                actionref("Copy Routing &Version_Promoted"; "Copy Routing &Version")
                {
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not CurrPage.Editable() then
            exit(true);

        if IsNullGuid(Rec.SystemId) then
            exit(true);

        if Rec.Status in [Rec.Status::Certified, Rec.Status::Closed] then
            exit(true);

        if not Rec.RoutingLinesExist() then
            exit(true);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CertifyQst, CurrPage.Caption), false) then
            exit(false);

        exit(true);
    end;

    var
        CopyFromRoutingQst: Label 'Copy from routing header?';
        CertifyQst: Label 'The %1 has not been certified. Are you sure you want to exit?', Comment = '%1 = page caption (Production BOM)';
}

