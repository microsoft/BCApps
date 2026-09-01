// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Utilities;

page 685 "Payment Periods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Periods';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Period";
    SourceTableView = sorting("Days From");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies code of the payment period.';
                }
                field("Days From"; Rec."Days From")
                {
                    ToolTip = 'Specifies the lowest number of "Actual Payment Days" for the payment to be included in the period.';
                }
                field("Days To"; Rec."Days To")
                {
                    ToolTip = 'Specifies the highest number of "Actual Payment Days" for the payment to be included in the period. 0 means no upper limit.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the payment period.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RestoreDefaults)
            {
                Caption = 'Restore Default Periods';
                ToolTip = 'Deletes all payment periods and restores the default periods for the current environment.';
                Image = Restore;

                trigger OnAction()
                var
                    PaymentPeriod: Record "Payment Period";
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if not ConfirmManagement.GetResponseOrDefault(RestoreDefaultsQst, false) then
                        exit;

                    PaymentPeriod.DeleteAll();
                    PaymentPeriod.SetupDefaults();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RestoreDefaults_Promoted; RestoreDefaults)
            {
            }
        }
    }

    var
        RestoreDefaultsQst: Label 'This will replace all payment periods with the default periods for your environment. Do you want to continue?';
}