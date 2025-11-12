// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

page 247 "VAT Registration Log Details"
{
    PageType = List;
    SourceTable = "VAT Registration Log Details";
    Caption = 'Validation Details';
    DataCaptionFields = "Account Type", "Account No.";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Details)
            {
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Requested; Rec.Requested)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Current Value"; Rec."Current Value")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Response; Rec.Response)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Accept)
            {
                ApplicationArea = Basic, Suite;
                Image = Approve;
                Enabled = AcceptEnabled;
                Caption = 'Accept';
                ToolTip = 'Apply the value that the service returned to the account.';

                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Accepted;
                    Rec.Modify();

                    UpdateControls();
                end;
            }
            action(AcceptAll)
            {
                ApplicationArea = Basic, Suite;
                Image = Approve;
                Enabled = AcceptAllEnabled;
                Caption = 'Accept All';
                ToolTip = 'Accept all returned values and update the account.';

                trigger OnAction()
                begin
                    UpdateAllDetailsStatus(Rec.Status::"Not Valid", Rec.Status::Accepted);
                end;

            }
            action(Reset)
            {
                ApplicationArea = Basic, Suite;
                Image = ResetStatus;
                Enabled = ResetEnabled;
                Caption = 'Reset';
                ToolTip = 'Reset the value that was applied to the account.';

                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::"Not Valid";
                    Rec.Modify();

                    UpdateControls();
                end;
            }
            action(ResetAll)
            {
                ApplicationArea = Basic, Suite;
                Image = ResetStatus;
                Enabled = ResetAllEnabled;
                Caption = 'Reset All';
                ToolTip = 'Reset the values that were applied to the account.';

                trigger OnAction()
                begin
                    UpdateAllDetailsStatus(Rec.Status::Accepted, Rec.Status::"Not Valid");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Accept_Promoted; Accept)
                {
                }
                actionref(AcceptAll_Promoted; AcceptAll)
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
                actionref(ResetAll_Promoted; ResetAll)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        AcceptEnabled := (Rec.Status = Rec.Status::"Not Valid") and (Rec.Response <> '');
        ResetEnabled := Rec.Status = Rec.Status::Accepted;
    end;

    var
        AcceptEnabled: Boolean;
        AcceptAllEnabled: Boolean;
        ResetEnabled: Boolean;
        ResetAllEnabled: Boolean;

    local procedure UpdateAllDetailsStatus(Before: Enum "VAT Reg. Log Details Field Status"; After: Enum "VAT Reg. Log Details Field Status")
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        VATRegistrationLogDetails.Copy(Rec);
        VATRegistrationLogDetails.SetFilter(Response, '<>%1', '');
        VATRegistrationLogDetails.SetRange(Status, Before);
        VATRegistrationLogDetails.ModifyAll(Status, After);

        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        VATRegistrationLogDetails: Record "VAT Registration Log Details";
    begin
        VATRegistrationLogDetails.CopyFilters(Rec);
        VATRegistrationLogDetails.SetFilter(Response, '<>%1', '');

        VATRegistrationLogDetails.SetRange(Status, VATRegistrationLogDetails.Status::"Not Valid");
        AcceptAllEnabled := not VATRegistrationLogDetails.IsEmpty();

        VATRegistrationLogDetails.SetRange(Status, VATRegistrationLogDetails.Status::Accepted);
        ResetAllEnabled := not VATRegistrationLogDetails.IsEmpty();
    end;
}
