// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Security.User;
using System.Utilities;

page 31147 "EET Entry Preview Card CZL"
{
    Caption = 'EET Entry Preview Card';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "EET Entry CZL";
    SourceTableTemporary = true;
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
                field("Created At"; Rec."Created At")
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
                field("Status Last Changed At"; Rec."Status Last Changed At")
                {
                    Importance = Promoted;

                    trigger OnDrillDown()
                    begin
                        ShowStatusLogPreview();
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
    }

    actions
    {
        area(navigation)
        {
            action("Entry Status Log")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Entry Status Log';
                Image = Status;
                ToolTip = 'Displays a log of the EET entry status changes.';

                trigger OnAction()
                begin
                    ShowStatusLogPreview();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SignatureCode := Rec.GetSignatureCode();
        SetStatusStyle();
    end;

    var
        TempEETEntryStatusLogCZL: Record "EET Entry Status Log CZL" temporary;
        TempErrorMessage: Record "Error Message" temporary;
        SignatureCode: Text;
        StatusStyleExpr: Text;

    procedure Set(var NewTempEETEntryCZL: Record "EET Entry CZL" temporary; var NewTempEETEntryStatusLogCZL: Record "EET Entry Status Log CZL" temporary; var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        Rec.Copy(NewTempEETEntryCZL, true);
        TempEETEntryStatusLogCZL.Copy(NewTempEETEntryStatusLogCZL, true);
        TempErrorMessage.Copy(NewTempErrorMessage, true);
    end;

    local procedure SetStatusStyle()
    begin
        StatusStyleExpr := Rec.GetStatusStyleExpr();
    end;

    local procedure ShowStatusLogPreview()
    var
        EETEntryStatusLogPrevCZL: Page "EET Entry Status Log Prev. CZL";
    begin
        EETEntryStatusLogPrevCZL.Set(TempEETEntryStatusLogCZL, TempErrorMessage);
        EETEntryStatusLogPrevCZL.RunModal();
    end;
}
