// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Telemetry;

page 3010541 "DTA Setup"
{
    Caption = 'DTA Setup';
    PageType = Card;
    SourceTable = "DTA Setup";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Bank Code"; Rec."Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a short name for the partner bank.';
                }
                field("DTA/EZAG"; Rec."DTA/EZAG")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this setup is for DTA or EZAG.';
                }
                field("DTA Currency Code"; Rec."DTA Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the foreign currency used for the account.';
                }
                field("DTA Main Bank"; Rec."DTA Main Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current bank code as the main bank.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that is suggested as balance account in the payment suggestion.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance account number is used during the DTA Suggest Vendor Payments batch job, to make the balancing entry.';
                }
                field("Credit Limit"; Rec."Credit Limit")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit limit for the bank account can be entered here.';
                }
            }
            group(Sender)
            {
                Caption = 'Sender';
                field("DTA Sender Name"; Rec."DTA Sender Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the DTA sender name.';
                }
                field("DTA Sender Name 2"; Rec."DTA Sender Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the second line of the DTA sender name.';
                }
                field("DTA Sender Address"; Rec."DTA Sender Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies address of the DTA sender.';
                }
                field("DTA Sender Post Code"; Rec."DTA Sender Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DTA Sender ZIP/City';
                    ToolTip = 'Specifies the DTA sender post code.';
                }
                field("DTA Sender City"; Rec."DTA Sender City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the DTA sender city is stored here.';
                }
                field("DTA Customer ID"; Rec."DTA Customer ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification that is assigned by the bank and is normally identical to the DTA Sender ID.';
                }
                field("DTA Sender ID"; Rec."DTA Sender ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification that is assigned by the bank and is normally identical to the DTA Customer ID.';
                }
                field("DTA Sender Clearing"; Rec."DTA Sender Clearing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your bank.';
                }
                field("DTA Debit Acc. No."; Rec."DTA Debit Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that the payment orders are debited from.';
                }
                field("DTA Sender IBAN"; Rec."DTA Sender IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the IBAN account that DTA payments is made from.';
                }
            }
            group("Bank Address")
            {
                Caption = 'Bank Address';
                field("DTA Bank Name"; Rec."DTA Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Name 2"; Rec."DTA Bank Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Address"; Rec."DTA Bank Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Address 2"; Rec."DTA Bank Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank Post Code"; Rec."DTA Bank Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'DTA Bank Zip/City';
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank City"; Rec."DTA Bank City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies part of the bank address.';
                }
                field("DTA Bank E-Mail"; Rec."DTA Bank E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("DTA Bank Home Page"; Rec."DTA Bank Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
            }
            group("Computer Bureau")
            {
                Caption = 'Computer Bureau';
                field("Computer Bureau Name"; Rec."Computer Bureau Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau Name 2"; Rec."Computer Bureau Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau Address"; Rec."Computer Bureau Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau Post Code"; Rec."Computer Bureau Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Computer Bureau Zip/City';
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau City"; Rec."Computer Bureau City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the computer bureau that will receive the DTA file.';
                }
                field("Computer Bureau E-Mail"; Rec."Computer Bureau E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("Computer Bureau Home Page"; Rec."Computer Bureau Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
            }
            group("DTA File")
            {
                Caption = 'DTA File';
                field("DTA File Folder"; Rec."DTA File Folder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the folder that the DTA file is saved in.';
                }
                field("DTA Filename"; Rec."DTA Filename")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name with the standard value DTALSV.';
                }
                field("File Format"; Rec."File Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the individual DTA file records are closed.';
                }
                field("Backup Copy"; Rec."Backup Copy")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a backup copy is made each time a DTA file is written.';
                }
                field("Backup Folder"; Rec."Backup Folder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a backup copy is made each time a DTA file is written.';
                }
                field("Last Backup No."; Rec."Last Backup No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a backup copy is made each time a DTA file is written.';
                }
            }
            group(EZAG)
            {
                Caption = 'EZAG';
                field("EZAG File Folder"; Rec."EZAG File Folder")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the folder that the EZAG file is saved in.';
                }
                field("EZAG Filename"; Rec."EZAG Filename")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name with the standard value PTTCRIA.';
                }
                field("EZAG Debit Account No."; Rec."EZAG Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that on this postal checking account, the payment order is debited from the Swiss Post.';
                }
                field("EZAG Charges Account No."; Rec."EZAG Charges Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies all charges are debited to this account. It often corresponds to the EZAG Debit Account No.';
                }
                field("EZAG Media ID"; Rec."EZAG Media ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the EZAG Media ID.';
                }
                field("Yellownet E-Mail"; Rec."Yellownet E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("Yellownet Home Page"; Rec."Yellownet Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address to establish a connection with the computer bureau.';
                }
                field("Last EZAG Order No."; Rec."Last EZAG Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies each combined order has a unique number between 01 and 99.';
                }
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
                action("&Write Testfile")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Write Testfile';
                    Image = TestFile;
                    ToolTip = 'Test the DTA setup.';

                    trigger OnAction()
                    var
                        DtaFileWrite: Report "DTA File";
                        EzagFileWrite: Report "EZAG File";
                    begin
                        if Rec."DTA/EZAG" = Rec."DTA/EZAG"::DTA then begin
                            if DtaFileWrite.WriteTestFile(Rec) then
                                DtaFileWrite.DownloadToFile();
                        end else
                            EzagFileWrite.WriteTestFile(Rec);
                    end;
                }
                action("E&ZAG Pictures")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&ZAG Pictures';
                    Image = Picture;
                    ToolTip = 'View the EZAG post logo and the EZAG bar code to be used in the EZAG Payment Order report.';

                    trigger OnAction()
                    var
                        DTASetup: Record "DTA Setup";
                    begin
                        DTASetup.Copy(Rec);
                        PAGE.Run(PAGE::"DTA EZAG Pictures", DTASetup);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000KEE', 'DTA Local CH Functionality', 'DTA Setup page open');
    end;

    var
}

