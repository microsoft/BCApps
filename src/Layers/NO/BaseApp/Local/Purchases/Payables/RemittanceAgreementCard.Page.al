// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using System.Environment;
using System.IO;

page 15000007 "Remittance Agreement Card"
{
    Caption = 'Remittance Agreement Card';
    PageType = Document;
    SourceTable = "Remittance Agreement";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a unique ID for the remittance agreement.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the remittance agreement.';
                }
                field("Payment System"; Rec."Payment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the available payment systems.';
                }
            }
            group(Bank)
            {
                Caption = 'Bank';
                field("Operator No."; Rec."Operator No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the operator.';
                }
                field("Company/Agreement No."; Rec."Company/Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the company or agreement.';
                }
                field(Division; Rec.Division)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the division.';
                }
                field("Latest Sequence No."; Rec."Latest Sequence No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest sequence number. This is set automatically, but you can change it.';
                }
                field("Latest Daily Sequence No."; Rec."Latest Daily Sequence No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest daily sequence number. This is set automatically, but you can change it.';
                }
                field("Latest Export"; Rec."Latest Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest export of the remittance agreement. This is set automatically, but you can change it.';
                }
            }
            group(BBS)
            {
                Caption = 'BBS';
                field("BBS Customer Unit ID"; Rec."BBS Customer Unit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification of the agreement for Bankenes BetalingsSentral (BBS). This code is provided by BBS.';
                }
                field("Latest BBS Payment Order No."; Rec."Latest BBS Payment Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number that was used when the payment was sent to BBS.';
                }
            }
            group(Send)
            {
                Caption = 'Send';
                Visible = not IsSaaS;
                field(FileName; FileName)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the path and the name of the file that contains the electronic payment order to the bank.';

                    trigger OnAssistEdit()
                    begin
                        ComDlgFilename := FileMgt.UploadFile(Rec.FieldCaption("Payment File Name"), Rec."Payment File Name");

                        if ComDlgFilename <> '' then begin
                            Rec.Validate("Payment File Name", ComDlgFilename);
                            FileName := FileMgt.GetFileName(ComDlgFilename);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Payment File Name", CopyStr(FileName, 1, MaxStrLen(Rec."Payment File Name")));
                        FileName := FileMgt.GetFileName(FileName);
                    end;
                }
            }
            group(Control1905833301)
            {
                Caption = 'Receive';
                field("Save Return File"; Rec."Save Return File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want save the electronic response from the bank.';
                }
                field("Receipt Return Required"; Rec."Receipt Return Required")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the message from the bank that the payment order has been received must be automatically imported.';
                }
                field("Return File Is Not In Use"; Rec."Return File Is Not In Use")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the file with the bank''s response is not used for approval and settlement of the payment.';
                }
                field("On Hold Rejection Code"; Rec."On Hold Rejection Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that will be used in the On Hold field on the vendor ledger entry, if an electronic payment is rejected.';
                }
            }
            group(Finance)
            {
                Caption = 'Finance';
                field("New Document Per."; Rec."New Document Per.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how documents are numbered when payments are posted.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Receive)
            {
                Caption = 'Receive';
                action("Return File Setup List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return File Setup List';
                    Image = List;
                    RunObject = Page "Return File Setup List";
                    RunPageLink = "Agreement Code" = field(Code);
                    ToolTip = 'View the return files that are associated with a remittance agreement.';
                }
            }
            group("Contr&act")
            {
                Caption = 'Contr&act';
                action(Accounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounts';
                    Image = Accounts;
                    RunObject = Page "Remittance Account Overview";
                    RunPageLink = "Remittance Agreement Code" = field(Code);
                    ToolTip = 'View the related remittance account.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FileName := FileMgt.GetFileName(Rec.GetPaymentFileName());
        IsSaaS := EnvironmentInfo.IsSaaS();
    end;

    var
        FileMgt: Codeunit "File Management";
        EnvironmentInfo: Codeunit "Environment Information";
        ComDlgFilename: Text[200];
        FileName: Text;
        IsSaaS: Boolean;
}

