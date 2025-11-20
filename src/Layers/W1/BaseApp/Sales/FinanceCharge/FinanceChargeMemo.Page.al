// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Reports;
using Microsoft.Utilities;

page 446 "Finance Charge Memo"
{
    Caption = 'Finance Charge Memo';
    PageType = Document;
    SourceTable = "Finance Charge Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the customer you want to create a finance charge memo for.';

                    trigger OnValidate()
                    begin
                        Customer.GetPrimaryContact(Rec."Customer No.", PrimaryContact);
                        SetPostingGroupEditable();
                        CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the customer the finance charge memo is for.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the customer the finance charge memo is for.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the customer the finance charge memo is for.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you communicate with the customer the finance charge memo is for.';
                }
                field(ContactPhoneNo; PrimaryContact."Phone No.")
                {
                    Caption = 'Phone No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the customer contact person the finance charge is for.';
                }
                field(ContactMobilePhoneNo; PrimaryContact."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the customer contact person the finance charge is for.';
                }
                field(ContactEmail; PrimaryContact."E-Mail")
                {
                    Caption = 'Email';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the email address of the customer contact person the finance charge is for.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the finance charge memo should be issued.';
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
            }
            part(FinChrgMemoLines; "Finance Charge Memo Lines")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Finance Charge Memo No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies when payment of the amount on the finance charge memo is due.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code of the finance charge memo.';

                    trigger OnAssistEdit()
                    var
                        CurrencyExchangeRate: Record "Currency Exchange Rate";
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        Rec.TestField("Posting Date");
                        ChangeExchangeRate.SetParameter(
                          Rec."Currency Code",
                          CurrencyExchangeRate.ExchangeRate(Rec."Posting Date", Rec."Currency Code"),
                          Rec."Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPostingGroupEditable;
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Memo")
            {
                Caption = '&Memo';
                Image = Notes;
                action(List)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all finance charges that exist.';

                    trigger OnAction()
                    begin
                        FinanceChargeMemoHeader.Copy(Rec);
                        if PAGE.RunModal(0, FinanceChargeMemoHeader) = ACTION::LookupOK then
                            Rec := FinanceChargeMemoHeader;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Fin. Charge Comment Sheet";
                    RunPageLink = Type = const("Finance Charge Memo"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("C&ustomer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ustomer';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    RunPageLink = "No." = field("Customer No.");
                    ToolTip = 'Open the card of the customer that the reminder or finance charge applies to. ';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                separator(Action32)
                {
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Finance Charge Memo Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateFinanceChargeMemos)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Finance Charge Memos';
                    Ellipsis = true;
                    Image = CreateFinanceChargememo;
                    ToolTip = 'Create finance charge memos for one or more customers with overdue payments.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Create Finance Charge Memos");
                    end;
                }
                action(SuggestFinChargeMemoLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Fin. Charge Memo Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    ToolTip = 'Create finance charge memo lines in existing finance charge memos for any overdue payments based on information in the Finance Charge Memo window.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinanceChargeMemoHeader);
                        REPORT.RunModal(REPORT::"Suggest Fin. Charge Memo Lines", true, false, FinanceChargeMemoHeader);
                    end;
                }
                action(UpdateFinChargeText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Finance Charge Text';
                    Ellipsis = true;
                    Image = RefreshText;
                    ToolTip = 'Replace the beginning and ending text that has been defined for the related finance charge terms with those from different terms.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinanceChargeMemoHeader);
                        REPORT.RunModal(REPORT::"Update Finance Charge Text", true, false, FinanceChargeMemoHeader);
                    end;
                }
            }
            group("&Issuing")
            {
                Caption = '&Issuing';
                Image = Add;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinanceChargeMemoHeader);
                        FinanceChargeMemoHeader.PrintRecords();
                    end;
                }
                action(Issue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issue';
                    Ellipsis = true;
                    Image = ReleaseDoc;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the specified finance charge entries according to your specifications in the Finance Charge Terms window. This specification determines whether interest and/or additional fees are posted to the customer''s account and the general ledger.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(FinanceChargeMemoHeader);
                        REPORT.RunModal(REPORT::"Issue Finance Charge Memos", true, true, FinanceChargeMemoHeader);
                    end;
                }
            }
        }
        area(reporting)
        {
#if not CLEAN25
            action("Finance Charge Memo Nos.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'The action will be obsoleted.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo";
                ToolTip = 'The action will be obsoleted.';
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'The related report doesn''t exist anymore.';
                ObsoleteTag = '25.0';
            }
#endif
            action("Finance Charge Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finance Charge Memo';
                Image = FinChargeMemo;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Finance Charge Memo";
                ToolTip = 'Create a new finance charge memo.';
            }
            action("Customer - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Balance to Date';
                Image = "Report";
                RunObject = Report "Customer - Balance to Date";
                ToolTip = 'View a list with customers'' payment history up until a certain date. You can use the report to extract your total sales income at the close of an accounting period or fiscal year.';
            }
            action("Customer - Detail Trial Bal.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer - Detail Trial Bal.';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Customer - Detail Trial Bal.";
                ToolTip = 'View the balance for customers with balances on a specified date. The report can be used at the close of an accounting period, for example, or for an audit.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Issue_Promoted; Issue)
                {
                }
                actionref(CreateFinanceChargeMemos_Promoted; CreateFinanceChargeMemos)
                {
                }
                actionref(SuggestFinChargeMemoLines_Promoted; SuggestFinChargeMemoLines)
                {
                }
                actionref(TestReport_Promoted; TestReport)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Memo', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("C&ustomer_Promoted"; "C&ustomer")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Customer - Balance to Date_Promoted"; "Customer - Balance to Date")
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if (not DocNoVisible) and (Rec."No." = '') then
            Rec.SetCustomerFromFilter();
    end;

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        SetDocNoVisible();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        Customer.GetPrimaryContact(Rec."Customer No.", PrimaryContact);
        SetPostingGroupEditable();
    end;

    var
        PrimaryContact: Record Contact;
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        DocNoVisible: Boolean;
        IsPostingGroupEditable: Boolean;
        VATDateEnabled: Boolean;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::FinChMemo, Rec."No.");
    end;

    procedure SetPostingGroupEditable()
    var
        Customer2: Record Customer;
    begin
        if Customer2.Get(Rec."Customer No.") then
            IsPostingGroupEditable := Customer2."Allow Multiple Posting Groups";
    end;
}

