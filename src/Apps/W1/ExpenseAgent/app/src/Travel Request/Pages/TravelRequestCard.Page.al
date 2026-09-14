// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.SpendRequest;

page 7129 "Travel Request Card"
{
    Caption = 'Travel Request';
    PageType = Document;
    ApplicationArea = Basic, Suite;
    SourceTable = "Spend Request";
    SourceTableView = where("Document Type" = filter("Travel Request"));

    AboutTitle = 'About the travel request';
    AboutText = 'A travel request captures the intent to travel, its purpose, expected cost, schedule, and travelers, so it can be reviewed and approved before any expense is incurred.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the travel request.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditNo();
                    end;
                }
                field("Requested For"; Rec."Requested For")
                {
                    ToolTip = 'Specifies the expense user for whom the travel request is being created.';
                }
                field(Purpose; Rec.Purpose)
                {
                    MultiLine = true;
                    ToolTip = 'Specifies the purpose of the travel request.';
                }
                field(Status; Rec.Status)
                {
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the travel request.';
                }
                field(ClosedAt; Rec."Closed At")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies when the travel request was closed.';
                }
                field(ClosedByDoc; Rec."Closed By Document No.")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the document that closed the travel request.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Importance = Additional;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the currency of the travel request.';
                }
                field("Total Expected Amount"; Rec."Total Expected Amount")
                {
                    Importance = Promoted;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the total expected amount of the travel request.';
                }
                field("Total Expected Amount (LCY)"; Rec."Total Expected Amount (LCY)")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the total expected amount of the travel request in local currency.';
                }
                field(TotalSpentAmountLCY; Rec."Total Spent Amount (LCY)")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the total amount that has been spent against the travel request in local currency.';
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
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up.';
                }
            }
            part(Lines; "Travel Request Subform")
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
                    ToolTip = 'Specifies the expected start date of the travel.';
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                    Importance = Promoted;
                    ToolTip = 'Specifies the expected end date of the travel.';
                }
                field("Actual Start Date and Time"; Rec."Actual Start Date and Time")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the actual start date and time of the travel.';
                }
                field("Actual End Date and Time"; Rec."Actual End Date and Time")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies the actual end date and time of the travel.';
                }
            }
            group("Travel Details")
            {
                Caption = 'Travel Details';

                field("Business Justification"; Rec."Business Justification")
                {
                    MultiLine = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the business justification for the travel.';
                }
                field("International Travel"; Rec."International Travel")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies whether the travel is international.';
                }
                field("Origin Country"; Rec."Origin Country/Region Code")
                {
                    ToolTip = 'Specifies the origin country for the travel.';
                }
                field("Destination Country"; Rec."Dest. Country/Region Code")
                {
                    ToolTip = 'Specifies the destination country for the travel.';
                }
                field(Restrictions; Rec.Restrictions)
                {
                    Importance = Additional;
                    ToolTip = 'Specifies any travel restrictions that apply.';
                }
                field("Travel Policy Acknowledgment"; Rec."Travel Policy Acknowledgment")
                {
                    ToolTip = 'Specifies whether the travel policy has been acknowledged.';
                }
                field("Per Diem Included"; Rec."Per Diem Included")
                {
                    Importance = Additional;
                    ToolTip = 'Specifies whether per diem is included in the travel request.';
                }
            }
            group(Approval)
            {
                Caption = 'Approval';

                field("Approved by User Name"; Rec."Approved/Rejected by User Name")
                {
                    Importance = Promoted;
                    Editable = false;
                    ToolTip = 'Specifies the name of the user who approved or rejected the travel request.';
                }
                field("Approved At"; Rec."Approved/Rejected At")
                {
                    Importance = Promoted;
                    ToolTip = 'Specifies when the travel request was approved or rejected.';
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
        }
        area(Navigation)
        {
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
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
            action(Travelers)
            {
                Image = Travel;
                Caption = 'Travelers';
                ToolTip = 'View the travelers associated with this travel request.';
                ApplicationArea = Basic, Suite;
                RunObject = page "Travelers";
                RunPageLink = "Spend Request No." = field("No.");
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
                    actionref(Reopen_Promoted; ReOpen)
                    {
                    }
                    actionref(Close_Promoted; Close)
                    {
                    }
                }
            }
            group(Category_TravelRequest)
            {
                Caption = 'Travel Request';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Travelers_Promoted; Travelers)
                {
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Document Type" := Rec."Document Type"::"Travel Request";
    end;
}
