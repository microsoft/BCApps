// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Security.User;

page 31145 "EET Entries CZL"
{
    Caption = 'EET Entries';
    CardPageId = "EET Entry Card CZL";
    Editable = false;
    PageType = List;
    SourceTable = "EET Entry CZL";
    UsageCategory = History;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
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
                field("Document No."; Rec."Document No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Total Sales Amount"; Rec."Total Sales Amount")
                {
                }
                field("Amount Exempted From VAT"; Rec."Amount Exempted From VAT")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Status"; Rec."Status")
                {
                    StyleExpr = StatusStyleExpr;
                }
                field(StatusLastChangedAt; Rec.GetFormattedStatusLastChangedAt())
                {
                    Caption = 'Status Last Changed At';
                    ToolTip = 'Specifies the date and time of the last status change of the entry. Select the field to display the log of the status changes.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowStatusLog();
                    end;
                }
                field("Receipt Serial No."; Rec."Receipt Serial No.")
                {
                }
                field("Applied Document Type"; Rec."Applied Document Type")
                {
                }
                field("Applied Document No."; Rec."Applied Document No.")
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
                field("Acknowledgement Code"; Rec."Acknowledgement Code")
                {
                }
                field("Multiple Taxpayer Auth."; Rec."Multiple Taxpayer Auth.")
                {
                }
                field("Simple Registration"; Rec."Simple Registration")
                {
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
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
            action(SimpleRegistration)
            {
                Caption = 'Simple EET Registration';
                Image = ReverseRegister;
                RunObject = page "EET Simple Registration CZL";
                ToolTip = 'Create simple EET entry.';
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
        SetStatusStyle();
    end;

    var
        StatusStyleExpr: Text;

    local procedure SetStatusStyle()
    begin
        StatusStyleExpr := Rec.GetStatusStyleExpr();
    end;
}
