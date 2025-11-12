namespace System.IO;

using System.Environment.Configuration;
using System.Reflection;
using System.Security.User;

page 8629 "Config. Wizard"
{
    Caption = 'Welcome to RapidStart Services for Business Central';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Config. Setup";

    layout
    {
        area(content)
        {
            group("Step 1. Enter your company details.")
            {
                Caption = 'Step 1. Enter your company details.';
                group(Control5)
                {
                    ShowCaption = false;
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name (Required)';
                        ToolTip = 'Specifies the name of your company that you are configuring.';
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies an address for the company that you are configuring.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the city where the company that you are configuring is located.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("VAT Registration No."; Rec."VAT Registration No.")
                    {
                        ApplicationArea = VAT;
                        ToolTip = 'Specifies the customer''s VAT registration number.';
                    }
                    field("Industrial Classification"; Rec."Industrial Classification")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of industry that the company that you are configuring is.';
                    }
                }
                field(Picture; Rec.Picture)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the picture that has been set up for the company, for example, a company logo.';
                }
            }
            group("Step 2. Enter communication details.")
            {
                Caption = 'Step 2. Enter communication details.';
                field("Phone No.2"; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the company that you are configuring.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies fax number of the company that you are configuring.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the company that you are configuring.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies your company''s web site.';
                }
            }
            group("Step 3. Enter payment details.")
            {
                Caption = 'Step 3. Enter payment details.';
                field("Bank Name"; Rec."Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank the company uses.';
                }
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the branch number of the bank that the company that you are configuring uses.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number of the company that you are configuring.';
                }
                field("Payment Routing No."; Rec."Payment Routing No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment routing number of the company that you are configuring.';
                }
                field("Giro No."; Rec."Giro No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the giro number of the company that you are configuring.';
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the primary bank of the company that you are configuring.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank account number of the primary bank account of the company that you are configuring.';
                }
            }
            group("Step 4. Select package.")
            {
                Caption = 'Step 4. Select package.';
                group(Control2)
                {
                    ShowCaption = false;
                    field(PackageFileNameRtc; PackageFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Select the configuration package you want to load:';
                        Editable = false;
                        ToolTip = 'Specifies the name of the configuration package that you have created.';

                        trigger OnAssistEdit()
                        var
                            FileManagement: Codeunit "File Management";
                        begin
                            if ConfigVisible then
                                Error(PackageIsAlreadyAppliedErr);

                            Rec."Package File Name" := CopyStr(FileManagement.UploadFile(SelectPackageFileErr, ''), 1, MaxStrLen(Rec."Package File Name"));

                            if Rec."Package File Name" <> '' then begin
                                Rec.Validate("Package File Name");
                                ApplyVisible := true;
                            end else
                                ApplyVisible := false;
                            PackageFileName := FileManagement.GetFileName(Rec."Package File Name");
                        end;

                        trigger OnValidate()
                        begin
                            if Rec."Package File Name" = '' then
                                ApplyVisible := false;

                            CurrPage.Update();
                        end;
                    }
                    field("Package Code"; Rec."Package Code")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the code of the configuration package.';
                    }
                    field("Package Name"; Rec."Package Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ToolTip = 'Specifies the name of the package that contains the configuration information.';
                    }
                    label("Choose Apply Package action to load the data from the configuration to Business Central tables.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Choose Apply Package action to load the data from the configuration to Business Central tables.';
                        ToolTip = 'Specifies the action that loads the configuration data.';
                    }
                    label("Choose Configuration Worksheet if you want to edit and modify applied data.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Choose Configuration Worksheet if you want to edit and modify applied data.';
                        ToolTip = 'Specifies the action that loads the configuration data.';
                    }
                }
            }
            group("Step 5. Select profile.")
            {
                Caption = 'Step 5. Select profile.';
                group(Control11)
                {
                    ShowCaption = false;
                    group(Control9)
                    {
                        ShowCaption = false;
                        label(ProfileText)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'If you are finished setting up your company, select the profile that you want to use as your default, and then choose the OK button to close the Wizard.';
                            ToolTip = 'Specifies the action that loads the configuration data.';
                        }
                        field("Your Profile Code"; YourProfileCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Select the profile that you want to use after the setup has completed.';
                            DrillDown = false;
                            Editable = false;
                            ToolTip = 'Specifies the profile code for your configuration solution and package.';

                            trigger OnAssistEdit()
                            var
                                AllProfileTable: Record "All Profile";
                                Roles: Page Roles;
                            begin
                                Roles.Initialize();
                                Roles.LookupMode(true);
                                if Roles.RunModal() = Action::LookupOK then begin
                                    Roles.GetRecord(AllProfileTable);
                                    YourProfileCode := AllProfileTable."Profile ID";
                                    Rec."Your Profile Code" := AllProfileTable."Profile ID";
                                    Rec."Your Profile App ID" := AllProfileTable."App ID";
                                    Rec."Your Profile Scope" := AllProfileTable.Scope;
                                end;
                            end;
                        }
                    }
                    label(BeforeSetupCloseMessage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'If you still need to change setup data, do not change the profile. Choose the OK button to close the wizard, and then use the configuration worksheet to continue setting up Business Central.';
                        Style = Attention;
                        StyleExpr = true;
                        ToolTip = 'Specifies how to set up Dynamics 365 Business Central';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                action("Apply Package")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Package';
                    Enabled = ApplyVisible;
                    Image = Apply;
                    ToolTip = 'Import the configuration package and apply the package database data at the same time.';

                    trigger OnAction()
                    begin
                        if Rec.CompleteWizard() then
                            ConfigVisible := true
                        else
                            Error(SelectPackageToRunErr);
                    end;
                }
                action("Configuration Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Configuration Worksheet';
                    Enabled = ConfigVisible;
                    Image = SetupLines;
                    RunObject = Page "Config. Worksheet";
                    ToolTip = 'Plan and configure how to initialize a new solution based on legacy data and the customers requirements.';
                }
            }
            group(Setup)
            {
                Caption = 'Setup';
                action(Users)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users';
                    Image = User;
                    RunObject = Page Users;
                    ToolTip = 'Open the list of users that are registered in the system.';
                }
                action("Users Personalization")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Users Settings';
                    Image = UserSetup;
                    RunObject = Page "User Settings List";
                    ToolTip = 'Open the list of personalized UIs that are registered in the system.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Step 4', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Apply Package_Promoted"; "Apply Package")
                {
                }
                actionref("Configuration Worksheet_Promoted"; "Configuration Worksheet")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Step 5', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Users_Promoted; Users)
                {
                }
                actionref("Users Personalization_Promoted"; "Users Personalization")
                {
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        Rec.SelectDefaultRoleCenter(Rec."Your Profile Code", Rec."Your Profile App ID", Rec."Your Profile Scope");
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end else begin
            Rec."Package File Name" := '';
            Rec."Package Name" := '';
            Rec."Package Code" := '';
            Rec.Modify();
        end;
        YourProfileCode := Rec."Your Profile Code";
    end;

    var
        SelectPackageToRunErr: Label 'Select a package to run the Apply Package function.';
        SelectPackageFileErr: Label 'Select a package file.';
        YourProfileCode: Code[30];
        ApplyVisible: Boolean;
        ConfigVisible: Boolean;
        PackageIsAlreadyAppliedErr: Label 'A package has already been selected and applied.';
        PackageFileName: Text;
}

