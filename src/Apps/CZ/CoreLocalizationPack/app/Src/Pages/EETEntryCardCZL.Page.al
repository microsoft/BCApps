// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Security.User;

#pragma implicitwith disable
page 31146 "EET Entry Card CZL"
{
    Caption = 'EET Entry Card';
    Editable = false;
    PageType = Card;
    SourceTable = "EET Entry CZL";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Business Premises Code"; Rec."Business Premises Code")
                {
                }
                field("Cash Register Code"; Rec."Cash Register Code")
                {
                }
                field("Cash Register Type"; Rec."Cash Register Type")
                {
                }
                field("Cash Register No."; Rec."Cash Register No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field("Applied Document Type"; Rec."Applied Document Type")
                {
                }
                field("Applied Document No."; Rec."Applied Document No.")
                {
                }
                field("Receipt Serial No."; Rec."Receipt Serial No.")
                {
                }
                field("Created By"; Rec."Created By")
                {
                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Created By");
                    end;
                }
                field(CreatedAt; Rec.GetFormattedCreatedAt())
                {
                    Caption = 'Created At';
                    ToolTip = 'Specifies the date and time when the entry was created.';
                }
                field("Canceled By Entry No."; Rec."Canceled By Entry No.")
                {
                }
            }
            group(TaxpayerAuthorization)
            {
                Caption = 'Taxpayer and Authorization';
                field("Taxpayer ID"; Rec."Taxpayer ID")
                {
                }
                field("Authorizing Taxpayer ID"; Rec."Authorizing Taxpayer ID")
                {
                }
                field("Multiple Taxpayer Auth."; Rec."Multiple Taxpayer Auth.")
                {
                }
            }
            group(Sale)
            {
                Caption = 'Sale';
                field("Total Sales Amount"; Rec."Total Sales Amount")
                {
                    Importance = Promoted;
                }
                field("Amt. For Subseq. Draw/Settle"; Rec."Amt. For Subseq. Draw/Settle")
                {
                }
                field("Amt. Subseq. Drawn/Settled"; Rec."Amt. Subseq. Drawn/Settled")
                {
                }
                field("Amount Exempted From VAT"; Rec."Amount Exempted From VAT")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("VAT Base (Basic)"; Rec."VAT Base (Basic)")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("VAT Amount (Basic)"; Rec."VAT Amount (Basic)")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("VAT Base (Reduced)"; Rec."VAT Base (Reduced)")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("VAT Amount (Reduced)"; Rec."VAT Amount (Reduced)")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("VAT Base (Reduced 2)"; Rec."VAT Base (Reduced 2)")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("VAT Amount (Reduced 2)"; Rec."VAT Amount (Reduced 2)")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Amount - Art.89"; Rec."Amount - Art.89")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Amount (Basic) - Art.90"; Rec."Amount (Basic) - Art.90")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Amount (Reduced) - Art.90"; Rec."Amount (Reduced) - Art.90")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Amount (Reduced 2) - Art.90"; Rec."Amount (Reduced 2) - Art.90")
                {
                    Visible = false;
                    Enabled = false;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Status"; Rec."Status")
                {
                    Importance = Promoted;
                    StyleExpr = StatusStyleExpr;
                }
                field(StatusLastChangedAt; Rec.GetFormattedStatusLastChangedAt())
                {
                    Caption = 'Status Last Changed At';
                    Importance = Promoted;
                    ToolTip = 'Specifies the date and time of the last status change of the entry. Select the field to display the log of the status changes.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowStatusLog();
                    end;
                }
                field("Message UUID"; Rec."Message UUID")
                {
                }
                field("Acknowledgement Code"; Rec."Acknowledgement Code")
                {
                }
                field(SignatureCode; SignatureCode)
                {
                    Caption = 'Taxpayer''s Signature Code';
                    ToolTip = 'Specifies the taxpayer''s signature code (PKP). The code was used in the EET system version 1.0 and it is not used in version 2.0.';
                    Visible = false;
                    Enabled = false;
                }
                field("Taxpayer's Security Code"; Rec."Taxpayer's Security Code")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Fiscal Identification Code"; Rec."Fiscal Identification Code")
                {
                    Visible = false;
                    Enabled = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Entry Status Log")
            {
                Caption = 'Entry Status Log';
                Image = Status;
                ToolTip = 'Displays a log of the EET entry status changes.';

                trigger OnAction()
                begin
                    Rec.ShowStatusLog();
                end;
            }
            action("Show Document")
            {
                Caption = 'Show Document';
                Image = Document;
                ToolTip = 'Displays the document related to the entry.';

                trigger OnAction()
                begin
                    Rec.ShowDocument();
                end;
            }
        }
        area(processing)
        {
            action(Send)
            {
                Caption = 'Send';
                Image = SendElectronicDocument;
                ToolTip = 'Sends the selected entry to the EET service to register the sale.';

                trigger OnAction()
                begin
                    Rec.Send(true);
                    CurrPage.Update(false);
                end;
            }
            action(Verify)
            {
                Caption = 'Verify';
                Image = SendApprovalRequest;
                ToolTip = 'Sends the selected entry to the EET service in the verification mode. The sale is only checked, it is not registered and no acknowledgement code is assigned.';

                trigger OnAction()
                begin
                    Rec.Verify();
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                Image = Cancel;
                ToolTip = 'Creates an entry with the opposite amounts that cancels the selected entry and sends it to the EET service.';

                trigger OnAction()
                begin
                    Rec.Cancel(true);
                end;
            }
        }
        area(Reporting)
        {
            action(Confirmation)
            {
                Caption = 'Confirmation';
                Image = PrintReport;
                ToolTip = 'Print Confirmation of EET Entry';

                trigger OnAction()
                var
                    EETEntryCZL: Record "EET Entry CZL";
                    EETConfirmationCZL: Report "EET Confirmation CZL";
                begin
                    EETEntryCZL := Rec;
                    EETEntryCZL.SetRecFilter();
                    EETConfirmationCZL.SetTableView(EETEntryCZL);
                    EETConfirmationCZL.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Send_Promoted; Send)
                {
                }
                actionref(Verify_Promoted; Verify)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SignatureCode := Rec.GetSignatureCode();
        SetStatusStyle();
    end;

    var
        SignatureCode: Text;
        StatusStyleExpr: Text;

    local procedure SetStatusStyle()
    begin
        StatusStyleExpr := Rec.GetStatusStyleExpr();
    end;
}
