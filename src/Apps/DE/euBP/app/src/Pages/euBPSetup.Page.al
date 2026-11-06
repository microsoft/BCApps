// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

page 6541 "euBP Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'euBP Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "euBP Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Sender ID"; Rec."Sender ID")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the sender identifier used in the eXTra transport header.';
                }
                field("Receiver ID"; Rec."Receiver ID")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the receiver identifier used in the eXTra transport header.';
                }
            }
            group("LOHN Mapping")
            {
                Caption = 'LOHN Mapping';

                field("Payroll Expense Filter"; Rec."Payroll Expense Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a G/L account filter for payroll expense accounts.';
                }
                field("Employer Contr. Filter"; Rec."Employer Contr. Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a G/L account filter for employer contribution accounts.';
                }
                field("Payroll Tax Filter"; Rec."Payroll Tax Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a G/L account filter for payroll tax accounts.';
                }
                field("Payroll Posting Filter"; Rec."Payroll Posting Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a G/L account filter for payroll posting entries.';
                }
                field("Payroll Vendor Filter"; Rec."Payroll Vendor Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a vendor number filter for outsourced payroll vendors.';
                }
            }
            group("LOHN Payload")
            {
                Caption = 'LOHN Payload';

                field("LOHN Payload Name"; Rec."LOHN Payload Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the imported LOHN XML payload file.';
                }
                field("LOHN Last Validated At"; Rec."LOHN Last Validated At")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies when the imported LOHN payload was last validated.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportLohnPayload)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import LOHN Payload';
                Image = Import;
                ToolTip = 'Imports a payroll XML payload that will be packaged together with FIBU data.';

                trigger OnAction()
                var
                    FileName: Text;
                    InputInStream: InStream;
                begin
                    if UploadIntoStream('Select LOHN XML payload', '', '', FileName, InputInStream) then begin
                        Rec.UploadLohnPayload(FileName, InputInStream);
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(ValidateLohnPayload)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Validate LOHN Payload';
                Image = ValidateEmailLoggingSetup;
                ToolTip = 'Validates that the stored LOHN payload follows the expected euBP structure.';

                trigger OnAction()
                begin
                    Rec.ValidateStoredLohnPayload();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.EnsureExists();
    end;
}
