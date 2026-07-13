// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

page 6841 "Spend Request Card"
{
    Caption = 'Spend Request';
    PageType = Document;
    ApplicationArea = Basic, Suite;
    SourceTable = "Spend Request";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditNo();
                    end;
                }
                field(Type; Rec.Type)
                {
                }
                field("Requested By"; Rec."Requested By")
                {
                }
                field(Purpose; Rec.Purpose)
                {
                    MultiLine = true;
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                }
                field(ClosedAt; Rec."Closed At")
                {
                    Importance = Additional;
                }
                field(ClosedByDoc; Rec."Closed By Document No.")
                {
                    Importance = Additional;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Importance = Promoted;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Total Expected Amount"; Rec."Total Expected Amount")
                {
                    Importance = Promoted;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Total Expected Amount (LCY)"; Rec."Total Expected Amount (LCY)")
                {
                    Importance = Promoted;
                }
                field(TotalSpentAmountLCY; Rec."Total Spent Amount (LCY)")
                {
                    Importance = Promoted;
                }
                field(RemainingAmountLCY; Rec.GetRemainingAmountLCY())
                {
                    Caption = 'Remaining Amount (LCY)';
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                    ToolTip = 'Specifies the difference between estimated amount and actually spent amount.';
                    Importance = Additional;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    Importance = Additional;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    Importance = Additional;
                }
            }
            part(Lines; "Spend Request Subform")
            {
                Caption = 'Lines';
                Editable = Rec.Status = Rec.Status::Open;
                SubPageLink = "Spend Request No." = field("No.");
                UpdatePropagation = Both;
            }
            group(Schedule)
            {
                Caption = 'Schedule';

                field("Expected Start Date"; Rec."Expected Start Date")
                {
                    Importance = Promoted;
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                    Importance = Promoted;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';

                field("Approved by User Name"; Rec."Approved/Rejected by User Name")
                {
                    Importance = Promoted;
                }
                field("Approved At"; Rec."Approved/Rejected At")
                {
                    Importance = Promoted;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(Action21)
            {
                Caption = 'Release';
                Image = ReleaseDoc;

                action(Release)
                {
                    Caption = 'Release';
                    ToolTip = 'Set the status field to Released so that it can be processed for approval.';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ReleaseDoc;

                    trigger OnAction()
                    var
                        ReleaseSpendRequest: Codeunit "Release Spend Request";
                    begin
                        ReleaseSpendRequest.PerformManualRelease(Rec);
                    end;
                }
                action(ReOpen)
                {
                    Caption = 'Reopen';
                    ToolTip = 'Set the status field to Open so that it can be edited.';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;

                    trigger OnAction()
                    var
                        ReleaseSpendRequest: Codeunit "Release Spend Request";
                    begin
                        ReleaseSpendRequest.PerformManualReopen(Rec);
                    end;
                }
                action(Close)
                {
                    Caption = 'Close';
                    ToolTip = 'Set the status field to Closed so it cannot be used anymore.';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Closed;
                    Image = CloseDocument;

                    trigger OnAction()
                    var
                        ReleaseSpendRequest: Codeunit "Release Spend Request";
                    begin
                        ReleaseSpendRequest.PerformManualClose(Rec);
                    end;
                }
            }
            group(SpendRequestApproval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    Caption = 'Approve';
                    ToolTip = 'Manually set the status field to Approved';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Approved;
                    Image = Approve;

                    trigger OnAction()
                    begin
                        if Rec.Status = Rec.Status::Approved then
                            exit;
                        Rec.Status := Rec.Status::Approved;
                        Rec."Approved/Rejected At" := CurrentDateTime();
                        Rec."Approved/Rejected by User ID" := UserSecurityId();
                        Rec.Modify();
                    end;
                }
                action(Reject)
                {
                    Caption = 'Reject';
                    ToolTip = 'Manually set the status field to Rejected';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Rejected;
                    Image = Reject;

                    trigger OnAction()
                    begin
                        if Rec.Status = Rec.Status::Rejected then
                            exit;
                        Rec.TestField(Status, Rec.Status::Released);
                        Rec.Status := Rec.Status::Rejected;
                        Rec."Approved/Rejected At" := CurrentDateTime();
                        Rec."Approved/Rejected by User ID" := UserSecurityId();
                        Rec.Modify();
                    end;
                }
            }
            action(RefreshCurrency)
            {
                Caption = 'Refresh Currency Exchange rate';
                ToolTip = 'Updates the currency exchange rate and Total Expected Amount (LCY).';
                Enabled = (Rec."Currency Code" <> '') and (Rec.Status <> Rec.Status::Closed);
                ApplicationArea = Basic, Suite;
                Image = Recalculate;

                trigger OnAction()
                begin
                    if Rec.Status = Rec.Status::Closed then
                        Error('A closed spend request cannot be updated.');
                    Rec.UpdateCurrencyExchangeRate();
                    Rec.Modify();
                end;
            }
        }
        area(Navigation)
        {
            action(Dimensions)
            {
                AccessByPermission = TableData Microsoft.Finance.Dimension.Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Enabled = Rec."No." <> '';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to expenses to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    Rec.ShowDocDim();
                    CurrPage.SaveRecord();
                end;
            }
        }
        area(Reporting)
        {
            group(Report)
            {
                Caption = 'Report';
                Image = Print;

                action(Print)
                {
                    Caption = 'Print';
                    ToolTip = 'Prints the spend request so it can be sent to the requester.';
                    ApplicationArea = Basic, Suite;
                    Image = Print;
                    RunObject = Report "Spend Request Document";
                    RunPageOnRec = true;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Release)
                {
                    Caption = 'Release';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                    actionref(Close_Promoted; Close)
                    {
                    }
                }
                group("Category_Request Approval")
                {
                    Caption = 'Request Approval';

                    actionref(Approve_Promoted; Approve)
                    {
                    }
                    actionref(Reject_Promoted; Reject)
                    {
                    }
                }
                actionref(RefreshCurrency_Promoted; RefreshCurrency)
                {
                }
                group(Category_SpendRequest)
                {
                    Caption = 'Spend Request';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                }
            }
        }
    }
}
