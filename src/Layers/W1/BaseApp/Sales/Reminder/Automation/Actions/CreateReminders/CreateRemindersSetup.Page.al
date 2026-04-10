// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Configures the parameters for the automated create reminders action including filters and options.
/// </summary>
page 6762 "Create Reminders Setup"
{
    PageType = Card;
    SourceTable = "Create Reminders Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    MultiLine = true;
                }
                group(RequestParameters)
                {
                    ShowCaption = false;
                    field(UseHeaderLevel; Rec."Set Header Level to all Lines")
                    {
                        ApplicationArea = All;
                        Caption = 'Set highest level on all reminder lines';
                    }
                    field("Include Entries On Hold"; Rec."Include Entries On Hold")
                    {
                        ApplicationArea = All;
                        Caption = 'Include entries on hold';
                    }
                    field("Only Overdue Amount Entries"; Rec."Only Overdue Amount Entries")
                    {
                        ApplicationArea = All;
                        Caption = 'Only entries with overdue amount';
                    }
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(CustomerFilter; CustomerFilterTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Filter';
                    ToolTip = 'Specifies a filter for the customers to be processed by this automation job.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.SetCustomerSelectionFilter();
                        CurrPage.Update(false);
                    end;
                }

                field(CustomerLedgerEntriesFilter; CustomerLedgerEntriesFilterTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Overdue Entries Filter';
                    ToolTip = 'Specifies a filter for the overdue entries to be processed by this automation job.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.SetCustomerLedgerEntriesSelectionFilter();
                        CurrPage.Update(false);
                    end;
                }
                field(ApplyFeeEntriesFilterTxt; ApplyFeeEntriesFilterTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Apply Fee Entries Filter';
                    ToolTip = 'Specifies a filter for the apply fee entries to be processed by this automation job.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.SetFeeCustomerLedgerEntriesSelectionFilter();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CustomerFilterTxt := Rec.GetCustomerSelectionDisplayText();
        CustomerLedgerEntriesFilterTxt := Rec.GetCustomerLedgerEntriesSelectionDisplayText();
        ApplyFeeEntriesFilterTxt := Rec.GetFeeCustomerLedgerEntriesSelectionDisplayText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CustomerFilterTxt := Rec.GetCustomerSelectionDisplayText();
        CustomerLedgerEntriesFilterTxt := Rec.GetCustomerLedgerEntriesSelectionDisplayText();
        ApplyFeeEntriesFilterTxt := Rec.GetFeeCustomerLedgerEntriesSelectionDisplayText();
    end;

    var
        CustomerFilterTxt: Text;
        CustomerLedgerEntriesFilterTxt: Text;
        ApplyFeeEntriesFilterTxt: Text;
}