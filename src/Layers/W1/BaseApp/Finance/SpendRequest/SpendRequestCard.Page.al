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
                    Editable = Rec."No." = '';
                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditNo();
                    end;
                }
                field("Requested By"; Rec."Requested By")
                {
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field(Purpose; Rec.Purpose)
                {
                    MultiLine = true;
                    Editable = Rec.Status = Rec.Status::Open;
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
                    AutoFormatExpression = '';
                    ToolTip = 'Specifies the difference between estimated amount and actually spent amount.';
                    Importance = Additional;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    Importance = Additional;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    Importance = Additional;
                    Editable = Rec.Status = Rec.Status::Open;
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
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                    Importance = Promoted;
                    Editable = Rec.Status = Rec.Status::Open;
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
                Caption = 'Submit';
                Image = ReleaseDoc;

                action(Release)
                {
                    Caption = 'Submit';
                    ToolTip = 'Set the status field to Submitted so that it can be processed for approval.';
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
                        Rec.Approve();
                    end;
                }
                action(Reject)
                {
                    Caption = 'Reject';
                    ToolTip = 'Manually set the status field to Rejected';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Closed;
                    Image = Reject;

                    trigger OnAction()
                    begin
                        Rec.Reject();
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
                        Error(SpendRequestClosedErr, Rec.GetDocumentTypeDescription());
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
                    Caption = 'Spend Request Document';
                    ToolTip = 'Prints the spend request so it can be sent to the requester.';
                    ApplicationArea = Basic, Suite;
                    Image = Print;

                    trigger OnAction()
                    var
                        SpendRequestDocument: Report "Spend Request Document";
                    begin
                        Rec.SetRecFilter();
                        SpendRequestDocument.SetTableView(Rec);
                        SpendRequestDocument.Run();
                    end;
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
                    Caption = 'Submit';
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
                actionref(RefreshCurrency_Promoted; RefreshCurrency)
                {
                }
            }
            group(Category_Approval)
            {
                Caption = 'Approval';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
            }
            group(Category_SpendRequest)
            {
                Caption = 'Spend Request';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Print_Promoted; Print)
                {
                }
            }
        }
    }

    var
        SpendRequestClosedErr: Label 'A closed %1 cannot be updated.', Comment = '%1 = document type description, e.g. spend request or Travel Request';
}
