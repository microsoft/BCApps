// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

page 181 "Additional Customer Terms"
{
    Caption = 'Additional Customer Terms';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    Permissions = tabledata "License Agreement" = rim;
    InherentEntitlements = X;
    InherentPermissions = X;
    SourceTable = "License Agreement";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(PleaseReadLbl; PleaseReadLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowEULA();
                    end;
                }
                label(Control3)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = ConfirmationForAcceptingLicenseTermsQst;
                    ShowCaption = false;
                }
                field(Accepted; Rec.Accepted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the license agreement was accepted.';
                }
                field("Accepted By"; Rec."Accepted By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the person that accepted the license agreement.';
                }
                field("Accepted On"; Rec."Accepted On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date the license agreement is accepted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Read the Additional Customer Terms")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Read the Additional Customer Terms';
                Image = Agreement;
                ToolTip = 'Read the additional customer terms.';

                trigger OnAction()
                begin
                    Rec.ShowEULA();
                end;
            }
            action("&Accept the Additional Customer Terms")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Accept the Additional Customer Terms';
                Image = Approve;
                ToolTip = 'Accept the additional customer terms.';

                trigger OnAction()
                begin
                    Rec.Validate(Accepted, true);
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Read the Additional Customer Terms_Promoted"; "Read the Additional Customer Terms")
                {
                }
                actionref("&Accept the Additional Customer Terms_Promoted"; "&Accept the Additional Customer Terms")
                {
                }
            }
        }
    }

    var
        ConfirmationForAcceptingLicenseTermsQst: Label 'Do you accept the Partner Agreement?';
        PleaseReadLbl: Label 'Please read and accept the additional customer terms.';
}

