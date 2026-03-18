page 101900 "Demonstration Data Tool"
{
    Caption = 'Demonstration Data Tool';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Demo Data Setup";
    SourceTableView = where("Primary Key" = filter(<> ''));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Starting Year"; "Starting Year")
                {

                    trigger OnValidate()
                    begin
                        if "Test Demonstration Company" then
                            "Starting Year" := 2000;
                        "Working Date" := DMY2Date(1, 1, "Starting Year");
                        Modify();
                    end;
                }
                field("Working Date"; "Working Date")
                {
                    Editable = false;
                }
                field("Company Type"; "Company Type")
                {
                }
                field("Advanced Setup"; "Advanced Setup")
                {
                }
                field("Adjust for Payment Discount"; "Adjust for Payment Discount")
                {
                }
                field("Data Language ID"; "Data Language ID")
                {
                    LookupPageID = "Windows Languages";
                }
                field("Data Language Name"; "Data Language Name")
                {
                    Editable = false;
                }
                field("Data Type"; "Data Type")
                {
                }
                field(PicturePath; Rec."Path to Picture Folder")
                {
                }
            }
            group("Country/Region")
            {
                Caption = 'Country/Region';
                field("Country/Region Code"; "Country/Region Code")
                {
                    Editable = false;
                }
                field("Language Code"; "Language Code")
                {
                    Editable = false;
                }
                field("Currency Code"; "Currency Code")
                {
                }
                field("Additional Currency Code"; "Additional Currency Code")
                {
                }
                field("LCY an EMU Currency"; "LCY an EMU Currency")
                {
                }
                field("Remove Country Prefix"; "Remove Country Prefix")
                {
                }
            }
            group(Domains)
            {
                Caption = 'Domains';
                field(Financials; Financials)
                {
                }
                field("Relationship Mgt."; "Relationship Mgt.")
                {
                }
                field("Service Management"; "Service Management")
                {
                }
                field(Distribution; Distribution)
                {
                }
                field(Manufacturing; Manufacturing)
                {
                }
                field(ADCS; ADCS)
                {
                }
                field("Test Demonstration Company"; "Test Demonstration Company")
                {

                    trigger OnValidate()
                    begin
                        TestDemonstrationCompanyOnPush();
                    end;
                }
            }
            group("VAT Rates")
            {
                Caption = 'VAT Rates';
                field("Goods VAT Rate"; "Goods VAT Rate")
                {
                }
                field("Services VAT Rate"; "Services VAT Rate")
                {
                }
                field("Reduced VAT Rate"; "Reduced VAT Rate")
                {
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Test)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Codeunit.run(Codeunit::"Create Custom Report Layout");
                end;
            }
            action("&Create Demo Data")
            {
                Caption = '&Create Demo Data';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Create Demonstration Data";
            }
            action("Create Demo Data from Config")
            {
                Caption = 'Create Demo Data from Config';
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Create Demo Data from Config";
            }
            action("H&ints")
            {
                Caption = 'H&ints';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Message(HintMsg);
                end;
            }
            action(SelectNone)
            {
                Caption = 'Select &None';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    SelectDomains(false);
                    Modify(true);
                end;
            }
            action(SelectAll)
            {
                Caption = 'Select &All';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    SelectDomains(true);
                    Modify(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset();
        if not Get() then begin
            Init();
            // Replace the values with your Country codes.
            "Country/Region Code" := 'GB';
            // Use EUR if you are in Economic and Monetary Union (EMU).
            "Currency Code" := 'GBP';
            // "Additional Currency Code" := 'EUR';
            "LCY an EMU Currency" := ("Currency Code" = 'EUR');
            // Should be the same for all countries.
            // "Starting Year" is hardcode due to training material
            "Starting Year" := Date2DMY(20090101D, 3) + 1;
            "Working Date" := DMY2Date(1, 1, "Starting Year");
            SetTaxRates();
            "Progress Window Design" := ProgressWindowDesign();
            Insert(true);
        end;
        Validate("Data Language ID", GlobalLanguage);
        Modify(true);
    end;

    var
        HintMsg: Label 'To Create Demo Data from Config, please, run the Initialize-DemoToolResources command from your enlistment first (also, make sure you are running web client in the Release configuration).\\To create data for selected domains, make your selection on the Domains tab.\\Then press Create Demo Data to create the demonstration data.';

    procedure ProgressWindowDesign(): Text[1024]
    begin
        exit(
          'Demonstration Data Tool:#3#############\\' +
          '#1#####################################\\' +
          '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\');
    end;

    local procedure TestDemonstrationCompanyOnPush()
    begin
        if "Test Demonstration Company" then begin
            "Starting Year" := 2000;
            "Remove Country Prefix" := false;
        end else begin
            "Starting Year" := Date2DMY(Today, 3) + 1;
            "Remove Country Prefix" := true;
        end;

        "Working Date" := DMY2Date(1, 1, "Starting Year");

        Modify();
    end;
}

