namespace System.Security.User;

using Microsoft.Finance.VAT.Calculation;

page 119 "User Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Setup';
    PageType = List;
    AboutTitle = 'About User Setup';
    AboutText = 'Configure user permissions, posting policies, and responsibility centers to control access to documents and functional areas such as sales, purchases, and service management. Set approval limits, posting date ranges, and administrative roles to tailor user activities and visibility according to business requirements.';
    SourceTable = "User Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Allow Posting From"; Rec."Allow Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post to the company.';
                }
                field("Allow Posting To"; Rec."Allow Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the user is allowed to post to the company.';
                }
                field("Allow VAT From"; Rec."Allow VAT Date From")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post VAT to the company books is allowed.';
                    Visible = IsVATDateEnabled;
                }
                field("Allow VAT To"; Rec."Allow VAT Date To")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the last date on which the user is allowed to post VAT to the company books is allowed.';
                    Visible = IsVATDateEnabled;
                }
                field("Allow Deferral Posting From"; Rec."Allow Deferral Posting From")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date on which the user is allowed to post deferrals to the company.';
                }
                field("Allow Deferral Posting To"; Rec."Allow Deferral Posting To")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date on which the user is allowed to post deferrals to the company.';
                }
                field("Sales Invoice Posting Policy"; Rec."Sales Invoice Posting Policy")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify if you want user who posts warehouse shipment, sales shipments, or inventory pick to be able to post invoice/credit-memo as well.';
                }
                field("Purch. Invoice Posting Policy"; Rec."Purch. Invoice Posting Policy")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify if you want user who posts purchase receipt or inventory put-away to be able to post invoice/credit-memo as well.';
                }
                field("Service Invoice Posting Policy"; Rec."Service Invoice Posting Policy")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specify if you want user who posts warehouse shipment or service shipments to be able to post invoice/credit-memo as well.';
                }
                field("Register Time"; Rec."Register Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to register the user''s time usage defined as the time spent from when the user logs in to when the user logs out. Unexpected interruptions, such as idle session timeout, terminal server idle session timeout, or a client crash are not recorded.';
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the salesperson or purchaser for the user.';
                }
                field("Sales Resp. Ctr. Filter"; Rec."Sales Resp. Ctr. Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the responsibility center to which you want to assign the user.';
                }
                field("Purchase Resp. Ctr. Filter"; Rec."Purchase Resp. Ctr. Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the responsibility center to which you want to assign the user.';
                }
                field("Service Resp. Ctr. Filter"; Rec."Service Resp. Ctr. Filter")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the responsibility center you want to assign to the user. The user will only be able to see service documents for the responsibility center specified in the field. This responsibility center will also be the default responsibility center when the user creates new service documents.';
                }
                field("Time Sheet Admin."; Rec."Time Sheet Admin.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a user is a time sheet administrator. A time sheet administrator can access any time sheet and then edit, change, or delete it.';
                }
                field(Email; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s email address.';
                }
                field(PhoneNo; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s phone number.';
                }
                field(LicenseType; Rec."License Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user''s License Type.';
                    Visible = false;
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
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        IsVATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        Rec.HideExternalUsers();
    end;

    var
        IsVATDateEnabled: Boolean;
}

