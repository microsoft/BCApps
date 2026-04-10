// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Security.User;

page 5177 "Job Archive Card"
{
    Caption = 'Project Archive Card';
    PageType = Document;
    DeleteAllowed = false;
    Editable = false;
    SourceTable = "Job Archive";
    AdditionalSearchTerms = 'Project, Archive';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    Visible = NoFieldVisible;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    NotBlank = true;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    NotBlank = true;
                    ShowMandatory = true;
                }
                field("Sell-to Customer Name 2"; Rec."Sell-to Customer Name 2")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer Name 2';
                    Importance = Additional;
                    Visible = false;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';

                    field("Sell-to Address"; Rec."Sell-to Address")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Address';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field("Sell-to Address 2"; Rec."Sell-to Address 2")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field("Sell-to City"; Rec."Sell-to City")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'City';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    group(Control60)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; Rec."Sell-to County")
                        {
                            ApplicationArea = Jobs;
                            CaptionClass = '5,1,' + Rec."Sell-to Country/Region Code";
                            Importance = Additional;
                            QuickEntry = false;
                        }
                    }
                    field("Sell-to Post Code"; Rec."Sell-to Post Code")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Post Code';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Country/Region Code';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field("Sell-to Contact No."; Rec."Sell-to Contact No.")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Contact No.';
                        Importance = Additional;
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person that the sales document will be sent to.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person that the sales document will be sent to.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person that the sales document will be sent to.';
                    }
                    field("Sell-to Contact"; Rec."Sell-to Contact")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Contact';
                        Importance = Additional;
                        Editable = Rec."Sell-to Customer No." <> '';
                    }
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional description of the project for searching purposes.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    Tooltip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    Tooltip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Jobs;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Jobs;
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                }
            }
            part(JobTaskLines; "Job Task Archive Lines Subform")
            {
                ApplicationArea = Jobs;
                Caption = 'Tasks';
                SubPageLink = "Job No." = field("No."),
                            "Version No." = field("Version No.");
                SubPageView = sorting("Job Task No.")
                              order(ascending);
            }
            group(Posting)
            {
                Caption = 'Posting';
                field(Status; Rec.Status)
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies a current status of the project. You can change the status for the project as it progresses. Final calculations can be made on completed projects.';
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Jobs;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field("WIP Method"; Rec."WIP Method")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
                field("WIP Posting Method"; Rec."WIP Posting Method")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
                field("Allow Schedule/Contract Lines"; Rec."Allow Schedule/Contract Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Allow Budget/Billable Lines';
                    Importance = Additional;
                }
                field("Apply Usage Link"; Rec."Apply Usage Link")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
            }
            group("Invoice and Shipping")
            {
                Caption = 'Invoice and Shipping';

                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field(BillToOptions; BillToOptions)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Bill-to';
                        ToolTip = 'Specifies the customer that the sales invoice will be sent to. Default (Customer): The same as the customer on the sales invoice. Another Customer: Any customer that you specify in the fields below.';
                    }
                    group(Control205)
                    {
                        ShowCaption = false;
                        Visible = not (BillToOptions = BillToOptions::"Default (Customer)");

                        field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                        {
                            ApplicationArea = Jobs;
                            Importance = Promoted;
                            ShowMandatory = true;
                            Visible = false;
                        }
                        field("Bill-to Name"; Rec."Bill-to Name")
                        {
                            Caption = 'Name';
                            ApplicationArea = Jobs;
                            Importance = Promoted;
                            Editable = ((BillToOptions = BillToOptions::"Another Customer") or ((BillToOptions = BillToOptions::"Custom Address") and not ShouldSearchForCustByName));
                            Enabled = ((BillToOptions = BillToOptions::"Another Customer") or ((BillToOptions = BillToOptions::"Custom Address") and not ShouldSearchForCustByName));
                            NotBlank = true;
                        }
                        field("Bill-to Name 2"; Rec."Bill-to Name 2")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Name 2';
                            Importance = Additional;
                            Visible = false;
                        }
                        field("Bill-to Address"; Rec."Bill-to Address")
                        {
                            Caption = 'Address';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            QuickEntry = false;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;
                        }
                        field("Bill-to Address 2"; Rec."Bill-to Address 2")
                        {
                            Caption = 'Address 2';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            QuickEntry = false;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;
                        }
                        field("Bill-to City"; Rec."Bill-to City")
                        {
                            Caption = 'City';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            QuickEntry = false;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;
                        }
                        group(Control56)
                        {
                            ShowCaption = false;
                            Visible = IsBillToCountyVisible;
                            field("Bill-to County"; Rec."Bill-to County")
                            {
                                ApplicationArea = Jobs;
                                CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                                QuickEntry = false;
                                Importance = Additional;
                                Editable = BillToInformationEditable;
                                Enabled = BillToInformationEditable;
                            }
                        }
                        field("Bill-to Post Code"; Rec."Bill-to Post Code")
                        {
                            Caption = 'Post Code';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            QuickEntry = false;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;
                        }
                        field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                        {
                            Caption = 'Country/Region';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            QuickEntry = false;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;

                            trigger OnValidate()
                            begin
                                IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
                            end;
                        }
                        field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                        {
                            Caption = 'Contact No.';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;
                        }
                        field(ContactPhoneNo; BillToContact."Phone No.")
                        {
                            Caption = 'Phone No.';
                            ApplicationArea = Jobs;
                            Editable = false;
                            Importance = Additional;
                            ExtendedDatatype = PhoneNo;
                            ToolTip = 'Specifies the telephone number of the customer contact person for the project.';
                        }
                        field(ContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                        {
                            Caption = 'Mobile Phone No.';
                            ApplicationArea = Jobs;
                            Editable = false;
                            Importance = Additional;
                            ExtendedDatatype = PhoneNo;
                            ToolTip = 'Specifies the mobile telephone number of the customer contact person for the project.';
                        }
                        field(ContactEmail; BillToContact."E-Mail")
                        {
                            Caption = 'Email';
                            ApplicationArea = Jobs;
                            ExtendedDatatype = EMail;
                            Editable = false;
                            Importance = Additional;
                            ToolTip = 'Specifies the email address of the customer contact person for the project.';
                        }
                        field("Bill-to Contact"; Rec."Bill-to Contact")
                        {
                            Caption = 'Contact';
                            ApplicationArea = Jobs;
                            Importance = Additional;
                            Editable = BillToInformationEditable;
                            Enabled = BillToInformationEditable;
                        }
                    }
                }
                group("Payment Terms")
                {
                    caption = 'Payment Terms';

                    field("Payment Terms Code"; Rec."Payment Terms Code")
                    {
                        ApplicationArea = Jobs;
                        Tooltip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    }
                    field("Payment Method Code"; Rec."Payment Method Code")
                    {
                        ApplicationArea = Jobs;
                        Tooltip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                        Importance = Additional;
                    }
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';

                    field(ShippingOptions; ShipToOptions)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Ship-to';
                        ToolTip = 'Specifies the address that the products on the sales document are shipped to. Default (Sell-to Address): The same as the customer''s sell-to address. Alternate Ship-to Address: One of the customer''s alternate ship-to addresses. Custom Address: Any ship-to address that you specify in the fields below.';
                    }
                    group(Control202)
                    {
                        ShowCaption = false;
                        Visible = not (ShipToOptions = ShipToOptions::"Default (Sell-to Address)");
                        field("Ship-to Code"; Rec."Ship-to Code")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Code';
                            Editable = ShipToOptions = ShipToOptions::"Alternate Shipping Address";
                            Importance = Promoted;
                        }
                        field("Ship-to Name"; Rec."Ship-to Name")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Name';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                        }
                        field("Ship-to Name 2"; Rec."Ship-to Name 2")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Name 2';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            Importance = Additional;
                            QuickEntry = false;
                            Visible = false;
                        }
                        field("Ship-to Address"; Rec."Ship-to Address")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Address';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            QuickEntry = false;
                        }
                        field("Ship-to Address 2"; Rec."Ship-to Address 2")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Address 2';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            QuickEntry = false;
                        }
                        field("Ship-to City"; Rec."Ship-to City")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'City';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            QuickEntry = false;
                        }
                        group(Control82)
                        {
                            ShowCaption = false;
                            Visible = IsShipToCountyVisible;
                            field("Ship-to County"; Rec."Ship-to County")
                            {
                                ApplicationArea = Jobs;
                                CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                                Editable = ShipToOptions = ShipToOptions::"Custom Address";
                                QuickEntry = false;
                            }
                        }
                        field("Ship-to Post Code"; Rec."Ship-to Post Code")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Post Code';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            QuickEntry = false;
                        }
                        field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Country/Region';
                            Editable = ShipToOptions = ShipToOptions::"Custom Address";
                            Importance = Additional;
                            QuickEntry = false;

                            trigger OnValidate()
                            begin
                                IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                            end;
                        }
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Phone No.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Contact';
                    }
                }
            }
            group(Duration)
            {
                Caption = 'Duration';
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Jobs;
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Invoice Currency Code"; Rec."Invoice Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Cost Calculation Method"; Rec."Cost Calculation Method")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Exch. Calculation (Cost)"; Rec."Exch. Calculation (Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how project costs are calculated if you change the Currency Date or the Currency Code fields on a project planning Line or run the Change Project Planning Line Dates batch project. Fixed LCY option: The project costs in the local currency are fixed. Any change in the currency exchange rate will change the value of project costs in a foreign currency. Fixed FCY option: The project costs in a foreign currency are fixed. Any change in the currency exchange rate will change the value of project costs in the local currency.';
                }
                field("Exch. Calculation (Price)"; Rec."Exch. Calculation (Price)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how project sales prices are calculated if you change the Currency Date or the Currency Code fields on a project planning Line or run the Change Project Planning Line Dates batch project. Fixed LCY option: The project prices in the local currency are fixed. Any change in the currency exchange rate will change the value of project prices in a foreign currency. Fixed FCY option: The project prices in a foreign currency are fixed. Any change in the currency exchange rate will change the value of project prices in the local currency.';
                }
            }
            group(Version)
            {
                Caption = 'Version';
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Suite;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = true;
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
            group("&Job")
            {
                Caption = '&Project';
                Image = Job;
                action(JobPlanningLines)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project &Planning Lines';
                    Image = JobLines;
                    ToolTip = 'View all planning lines for the project. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a project (Budget) or you can specify what you actually agreed with your customer that he should pay for the project (Billable).';

                    trigger OnAction()
                    var
                        JobPlanningLineArchive: Record "Job Planning Line Archive";
                        JobPlanningArchiveLines: Page "Job Planning Archive Lines";
                    begin
                        Rec.TestField("No.");
                        JobPlanningLineArchive.SetRange("Job No.", Rec."No.");
                        JobPlanningLineArchive.SetRange("Version No.", Rec."Version No.");
                        JobPlanningArchiveLines.SetTableView(JobPlanningLineArchive);
                        JobPlanningArchiveLines.Run();
                    end;
                }
                separator(Action64)
                {
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet Archive";
                    RunPageLink = "Table Name" = const(Job),
                                  "No." = field("No."),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Online Map")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Online Map';
                    Image = Map;
                    ToolTip = 'View online map for addresses assigned to this project.';

                    trigger OnAction()
                    begin
                        Rec.DisplayMap();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Restore)
            {
                ApplicationArea = Suite;
                Caption = '&Restore';
                Ellipsis = true;
                Image = Restore;
                ToolTip = 'Transfer the contents of this archived version to the original project.';

                trigger OnAction()
                var
                    JobArchiveManagement: Codeunit "Job Archive Management";
                begin
                    JobArchiveManagement.RestoreJob(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Restore_Promoted; Restore)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Project', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                separator(Navigate_Separator)
                {
                }
                actionref(JobPlanningLines_Promoted; JobPlanningLines)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        SetNoFieldVisible();
        ActivateFields();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
        UpdateShipToBillToGroupVisibility();
        SellToContact.GetOrClear(Rec."Sell-to Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
        UpdateBillToInformationEditable();
    end;

    var
        FormatAddress: Codeunit "Format Address";
        NoFieldVisible: Boolean;
        ExtendedPriceEnabled: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        BillToInformationEditable: Boolean;
        ShouldSearchForCustByName: Boolean;

    protected var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.JobNoIsVisible();
    end;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    local procedure UpdateShipToBillToGroupVisibility()
    begin
        case true of
            (Rec."Ship-to Code" = '') and Rec.ShipToNameEqualsSellToName() and Rec.ShipToAddressEqualsSellToAddress():
                ShipToOptions := ShipToOptions::"Default (Sell-to Address)";

            (Rec."Ship-to Code" = '') and (not Rec.ShipToNameEqualsSellToName() or not Rec.ShipToAddressEqualsSellToAddress()):
                ShipToOptions := ShipToOptions::"Custom Address";

            Rec."Ship-to Code" <> '':
                ShipToOptions := ShipToOptions::"Alternate Shipping Address";
        end;

        case true of
            (Rec."Bill-to Customer No." = Rec."Sell-to Customer No.") and Rec.BillToAddressEqualsSellToAddress():
                BillToOptions := BillToOptions::"Default (Customer)";

            (Rec."Bill-to Customer No." = Rec."Sell-to Customer No.") and (not Rec.BillToAddressEqualsSellToAddress()):
                BillToOptions := BillToOptions::"Custom Address";

            Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.":
                BillToOptions := BillToOptions::"Another Customer";
        end;
    end;

    local procedure UpdateBillToInformationEditable()
    begin
        BillToInformationEditable :=
            (BillToOptions = BillToOptions::"Custom Address") or
            (Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.");
    end;

    local procedure SetControlVisibility()
    begin
        ShouldSearchForCustByName := Rec.ShouldSearchForCustomerByName(Rec."Sell-to Customer No.");
    end;
}
