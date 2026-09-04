#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

page 7099 "Spend Requests API"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the Travel Requests API (page 7134). The Expense Agent exposes requests through the dedicated Travel Request API.';
    ObsoleteTag = '30.0';
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Spend Request';
    EntitySetCaption = 'Spend Requests';
    DelayedInsert = true;
    EntityName = 'spendRequest';
    EntitySetName = 'spendRequests';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Spend Request";
    AboutText = 'Provides access to data from the Spend Request table';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(requestedBy; Rec."Requested By")
                {
                    Caption = 'Requested By';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(glAccountNo; Rec."G/L Account No.")
                {
                    Caption = 'G/L Account No.';
                }
                field(purpose; Rec.Purpose)
                {
                    Caption = 'Purpose';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(totalExpectedAmount; Rec."Total Expected Amount")
                {
                    Caption = 'Total Expected Amount';
                }
                field(totalExpectedAmountLCY; Rec."Total Expected Amount (LCY)")
                {
                    Caption = 'Total Expected Amount (LCY)';
                    Editable = false;
                }
                field(totalSpentAmountLCY; Rec."Total Spent Amount (LCY)")
                {
                    Caption = 'Total Spent Amount (LCY)';
                    Editable = false;
                }
                field(totalLineAmountLCY; Rec."Total Line Amount (LCY)")
                {
                    Caption = 'Total Line Amount (LCY)';
                    Editable = false;
                }
                field(expectedStartDate; Rec."Expected Start Date")
                {
                    Caption = 'Expected Start Date';
                }
                field(expectedEndDate; Rec."Expected End Date")
                {
                    Caption = 'Expected End Date';
                }
                field(closedAt; Rec."Closed At")
                {
                    Caption = 'Closed At';
                    Editable = false;
                }
                field(closedByDocumentNo; Rec."Closed By Document No.")
                {
                    Caption = 'Closed By Document No.';
                    Editable = false;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(requestedFor; Rec."Requested For")
                {
                    Caption = 'Requested For';
                }
                field(businessJustification; Rec."Business Justification")
                {
                    Caption = 'Business Justification';
                }
                field(travelPolicyAcknowledgment; Rec."Travel Policy Acknowledgment")
                {
                    Caption = 'Travel Policy Acknowledgment';
                }
                field(internationalTravel; Rec."International Travel")
                {
                    Caption = 'International Travel';
                }
                field(originCountry; Rec."Origin Country/Region Code")
                {
                    Caption = 'Origin Country';
                }
                field(destinationCountry; Rec."Dest. Country/Region Code")
                {
                    Caption = 'Destination Country';
                }
                field(restrictions; Rec.Restrictions)
                {
                    Caption = 'Restrictions';
                }
                field(perDiemIncluded; Rec."Per Diem Included")
                {
                    Caption = 'Per Diem Included';
                }
                field(actualStartDateAndTime; Rec."Actual Start Date and Time")
                {
                    Caption = 'Actual Start Date and Time';
                }
                field(actualEndDateAndTime; Rec."Actual End Date and Time")
                {
                    Caption = 'Actual End Date and Time';
                }
                part(spendRequestDetails; "Spend Request Details API")
                {
                    Caption = 'Spend Request Details';
                    EntityName = 'spendRequestDetail';
                    EntitySetName = 'spendRequestDetails';
                    SubPageLink = "Spend Request No." = field("No.");
                }
                part(travelers; "Travelers API")
                {
                    Caption = 'Travelers';
                    EntityName = 'traveler';
                    EntitySetName = 'travelers';
                    SubPageLink = "Spend Request No." = field("No.");
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if (Rec."Document Type" = Rec."Document Type"::"Travel Request") and
           (Rec."Requested By" <> xRec."Requested By")
        then
            Error(RequestedByCannotBeChangedErr);

        exit(true);
    end;

    var
        RequestedByCannotBeChangedErr: Label 'The owner of a travel request cannot be changed.';
}
#endif
