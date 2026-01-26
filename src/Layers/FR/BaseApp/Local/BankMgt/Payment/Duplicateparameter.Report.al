// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

report 10872 "Duplicate parameter"
{
    Caption = 'Duplicate parameter';
    ProcessingOnly = true;

    dataset
    {
        dataitem(PaymentClass; "Payment Class")
        {
            DataItemTableView = sorting(Code);

            trigger OnAfterGetRecord()
            var
                PaymtClass: Record "Payment Class";
            begin
                PaymtClass.Copy(PaymentClass);
                PaymtClass.Name := '';
                PaymtClass.Validate(Code, NewName);
                PaymtClass.Insert();
            end;

            trigger OnPreDataItem()
            begin
                VerifyNewName();
            end;
        }
        dataitem("Payment Status"; "Payment Status")
        {
            DataItemTableView = sorting("Payment Class", Line);

            trigger OnAfterGetRecord()
            var
                PaymtStatus: Record "Payment Status";
            begin
                PaymtStatus.Copy("Payment Status");
                PaymtStatus.Validate("Payment Class", NewName);
                PaymtStatus.Insert();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Payment Class", PaymentClass.Code);
            end;
        }
        dataitem("Payment Step"; "Payment Step")
        {
            DataItemTableView = sorting("Payment Class", Line);

            trigger OnAfterGetRecord()
            var
                PaymtStep: Record "Payment Step";
            begin
                PaymtStep.Copy("Payment Step");
                PaymtStep.Validate("Payment Class", NewName);
                PaymtStep.Insert();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Payment Class", PaymentClass.Code);
            end;
        }
        dataitem("Payment Step Ledger"; "Payment Step Ledger")
        {
            DataItemTableView = sorting("Payment Class", Line, Sign);

            trigger OnAfterGetRecord()
            var
                PaymtStepLedger: Record "Payment Step Ledger";
            begin
                PaymtStepLedger.Copy("Payment Step Ledger");
                PaymtStepLedger.Validate("Payment Class", NewName);
                PaymtStepLedger.Insert();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Payment Class", PaymentClass.Code);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Which name do you want to attribute to the new parameter?")
                    {
                        Caption = 'Which name do you want to attribute to the new parameter?';
                        field(OldName; OldName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Old name';
                            Editable = false;
                            ToolTip = 'Specifies the previous name of the payment class.';
                        }
                        field(NewName; NewName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'New name';
                            ToolTip = 'Specifies the name of the new payment class.';
                        }
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        OldName: Text[30];
        NewName: Text[30];
        Text000: Label 'You must define a new name.';
        Text001: Label 'Name %1 already exist. Please define another name.';

    [Scope('OnPrem')]
    procedure InitParameter("Code": Text[30])
    begin
        OldName := Code;
    end;

    [Scope('OnPrem')]
    procedure VerifyNewName()
    var
        PaymtClass: Record "Payment Class";
    begin
        if NewName = '' then
            Error(Text000);
        if PaymtClass.Get(NewName) then
            Error(Text001, NewName);
    end;
}

