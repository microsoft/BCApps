// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Reports;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;

page 5600 "Fixed Asset Card"
{
    Caption = 'Fixed Asset Card';
    PageType = ListPlus;
    Permissions = TableData "FA Depreciation Book" = rim;
    RefreshOnActivate = true;
    SourceTable = "Fixed Asset";
    SourceTableView = sorting("FA Type")
                      where("FA Type" = filter("Fixed Assets" | "Intangible Asset"));
    AdditionalSearchTerms = 'FA, Asset Profile, Property Details, Tangible Asset Info, Asset Data, Capital Good Info, Asset Detail, Ownership Info, Property Data';
    AboutTitle = 'About Fixed Asset Card';
    AboutText = 'With the **Fixed Asset Card**, you manage information about a fixed asset and specify the Class Subclass and Depreciation details. From here you can also drill down on past and ongoing fixed asset activity.';

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

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the fixed asset''s serial number.';
                }
                field("Inventory Number"; Rec."Inventory Number")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the fixed asset''s inventory number.';
                }
                field("Factory No."; Rec."Factory No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the factory number that defines the location of the fixed asset.';
                }
                field("Passport No."; Rec."Passport No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the passport number of the manufacturer or distributor of the fixed asset.';
                }
                field(Manufacturer; Rec.Manufacturer)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the manufacturer of the vehicle associated with the fixed asset.';
                }
                field("Manufacturing Year"; Rec."Manufacturing Year")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the year the fixed asset was manufactured.';
                }
                field("FA Type"; Rec."FA Type")
                {
                    ApplicationArea = FixedAssets;
                    OptionCaption = 'Fixed Assets,Intangible Asset';
                    ToolTip = 'Specifies the type of asset.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Responsible Employee"; Rec."Responsible Employee")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Promoted;
                }
                field(Inactive; Rec.Inactive)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies when the fixed asset card was last modified.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the status of the fixed asset.';
                }
                field("Initial Release Date"; Rec."Initial Release Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date that the fixed asset was first released.';
                }
                field("Status Document No."; Rec."Status Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number assigned to the document that changed the value of the Status field after the document was posted.';
                }
            }
            part(DepreciationBook; "FA Depreciation Books Subform")
            {
                ApplicationArea = FixedAssets;
                AboutTitle = 'About Depreciation Table List';
                AboutText = 'Here you overview all the fixed assets with registered depreciation books, FA Posting Group, Depreciation Method, Starting date, Ending date, No. of depreciation years, Depreciation percentage, Book value details.';
                SubPageLink = "FA No." = field("No.");
            }
            group(Classification)
            {
                Caption = 'Classification';
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies a class code for the fixed asset.';
                }
                field("FA Subclass Code"; Rec."FA Subclass Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies a fixed asset subclass code, which can be used for subgrouping of fixed assets, for example, cars and machinery.';
                }
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the location (within a building, for example) of the fixed asset.';
                }
                field("Budgeted Asset"; Rec."Budgeted Asset")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the asset is for budgeting purposes.';
                }
                field("Tax Difference Code"; Rec."Tax Difference Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the tax difference code associated with the fixed asset.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
            group(Maintenance)
            {
                Caption = 'Maintenance';
                AboutTitle = 'Manage the Fixed Asset Maintenance';
                AboutText = 'Specify the vendor, warranty and service date details.';
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("Maintenance Vendor No."; Rec."Maintenance Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("Under Maintenance"; Rec."Under Maintenance")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Next Service Date"; Rec."Next Service Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                }
                field("Last Renovation Date"; Rec."Last Renovation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date of the last renovation associated with the fixed asset.';
                }
                field("Warranty Date"; Rec."Warranty Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Insured; Rec.Insured)
                {
                    ApplicationArea = FixedAssets;
                }
            }
            group(Depreciation)
            {
                Caption = 'Depreciation';
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation group to apply to this asset.';
                }
                field("Depreciation Code"; Rec."Depreciation Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation code to apply to this asset.';
                }
                field("Belonging to Manufacturing"; Rec."Belonging to Manufacturing")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how the fixed asset is used in manufacturing.';
                }
                field("Undepreciable FA"; Rec."Undepreciable FA")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if you can repay fixed assets with the whole amount of their acquisition at the time of their release.';
                }
            }
            group(Components)
            {
                Caption = 'Components';
                field("Main Asset/Component"; Rec."Main Asset/Component")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the asset is a main asset or a component of a main asset.';
                }
                field("Component of Main Asset"; Rec."Component of Main Asset")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the main asset that this asset is a component of, or the number of the asset itself, if the asset is a main asset.';
                }
            }
            group(Vehicle)
            {
                Caption = 'Vehicle';
                field("Vehicle Identification Number"; Rec."Vehicle Identification Number")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle identification number associated with the fixed asset.';
                }
                field("Vehicle Model"; Rec."Vehicle Model")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle model associated with the fixed asset.';
                }
                field("Vehicle Type"; Rec."Vehicle Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle type associated with the fixed asset.';
                }
                field("Vehicle Reg. No."; Rec."Vehicle Reg. No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle registration number associated with the fixed asset.';
                }
                field("Vehicle Class"; Rec."Vehicle Class")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle class associated with the fixed asset.';
                }
                field("Vehicle Engine No."; Rec."Vehicle Engine No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle engine number associated with the fixed asset.';
                }
                field("Vehicle Chassis No."; Rec."Vehicle Chassis No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle chassis number associated with the fixed asset.';
                }
                field("Vehicle Capacity"; Rec."Vehicle Capacity")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle capacity associated with the fixed asset.';
                }
                field("Vehicle Passport Weight"; Rec."Vehicle Passport Weight")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the vehicle passport weight associated with the fixed asset.';
                }
                field("Run after Release Date"; Rec."Run after Release Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the run after release date associated with the fixed asset.';
                }
                field("Run after Renovation Date"; Rec."Run after Renovation Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the run after renovation date associated with the fixed asset.';
                }
                field("Vehicle Writeoff Date"; Rec."Vehicle Writeoff Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date this vehicle is taken out of service.';
                }
            }
            group("Assessed Tax")
            {
                Caption = 'Assessed Tax';
                field("Assessed Tax Code"; Rec."Assessed Tax Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the assessed tax code associated with the fixed asset.';
                }
                field("Property Type"; Rec."Property Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the property type of the fixed asset.';
                }
                field("Book Value per Share"; Rec."Book Value per Share")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the book value of the fixed asset, per share.';
                }
                field("OKATO Code"; Rec."OKATO Code")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ToolTip = 'Specifies the region where the current fixed asset is situated.';
                }
                field("Tax Amount Paid Abroad"; Rec."Tax Amount Paid Abroad")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the amount of tax that was paid abroad for the fixed asset.';
                }
            }
            group(Control1904423301)
            {
                Caption = 'History';
                field("Accrued Depr. Amount"; Rec."Accrued Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the accrued depreciation amount of the fixed asset.';
                }
                field("Operation Life (Months)"; Rec."Operation Life (Months)")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the operation life of the fixed asset.';
                }
                group(Control38)
                {
                    ShowCaption = false;
                }
            }
        }
        area(factboxes)
        {
            part(FixedAssetPicture; "Fixed Asset Picture")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Fixed Asset Picture';
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Fixed Asset"),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Fixed &Asset")
            {
                Caption = 'Fixed &Asset';
                Image = FixedAssets;
                action("Depreciation &Books")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation &Books';
                    Image = DepreciationBooks;
                    RunObject = Page "FA Depreciation Books";
                    RunPageLink = "FA No." = field("No.");
                    ToolTip = 'View or edit the depreciation book or books that must be used for each of the fixed assets. Here you also specify the way depreciation must be calculated.';
                }
                action(Statistics)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Fixed Asset Statistics";
                    RunPageLink = "FA No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View detailed historical information about the fixed asset.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5600),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Maintenance &Registration")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance &Registration';
                    Image = MaintenanceRegistrations;
                    RunObject = Page "Maintenance Registration";
                    RunPageLink = "FA No." = field("No.");
                    ToolTip = 'View or edit the date and description regarding the maintenance of the fixed asset.';
                }
                action("FA Posting Types Overview")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Posting Types Overview';
                    Image = ShowMatrix;
                    RunObject = Page "FA Posting Types Overview";
                    ToolTip = 'View accumulated amounts for each field, such as book value, acquisition cost, and depreciation, and for each fixed asset. For every fixed asset, a separate line is shown for each depreciation book linked to the asset.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Fixed Asset"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
            group("Main Asset")
            {
                Caption = 'Main Asset';
                action("M&ain Asset Components")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'M&ain Asset Components';
                    Image = Components;
                    RunObject = Page "Main Asset Components";
                    RunPageLink = "Main Asset No." = field("No.");
                    ToolTip = 'View or edit fixed asset components of the main fixed asset that is represented by the fixed asset card.';
                }
                action("Ma&in Asset Statistics")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ma&in Asset Statistics';
                    Image = StatisticsDocument;
                    RunObject = Page "Main Asset Statistics";
                    RunPageLink = "FA No." = field("No.");
                    ToolTip = 'View detailed historical information about the fixed asset.';
                }
                separator(Action39)
                {
                    Caption = '';
                }
            }
            group(Insurance)
            {
                Caption = 'Insurance';
                Image = TotalValueInsured;
                action("Total Value Ins&ured")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Total Value Ins&ured';
                    Image = TotalValueInsured;
                    RunObject = Page "Total Value Insured";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View the amounts that you posted to each insurance policy for the fixed asset. The amounts shown can be more or less than the actual insurance policy coverage. The amounts shown can differ from the actual book value of the asset.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = FixedAssetLedger;
                    RunObject = Page "FA Ledger Entries";
                    RunPageLink = "FA No." = field("No.");
                    RunPageView = sorting("FA No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Error Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Error Ledger Entries';
                    Image = ErrorFALedgerEntries;
                    RunObject = Page "FA Error Ledger Entries";
                    RunPageLink = "Canceled from FA No." = field("No.");
                    RunPageView = sorting("Canceled from FA No.")
                                  order(descending);
                    ToolTip = 'View the entries that have been posted as a result of you using the Cancel function to cancel an entry.';
                }
                action("Main&tenance Ledger Entries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Main&tenance Ledger Entries';
                    Image = MaintenanceLedgerEntries;
                    RunObject = Page "Maintenance Ledger Entries";
                    RunPageLink = "FA No." = field("No.");
                    RunPageView = sorting("FA No.");
                    ToolTip = 'View all the maintenance ledger entries for a fixed asset.';
                }
                separator(Action1210012)
                {
                }
                action("Precious Metal")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Precious Metal';
                    Image = FixedAssets;
                    RunObject = Page "Item/FA Precious Metal";
                    RunPageLink = "Item Type" = const(FA),
                                  "No." = field("No.");
                    ToolTip = 'View the list of fixed assets that are registered as precious metal.';
                }
                action("Ta&x Differences Detailed")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ta&x Differences Detailed';
                    Image = TaxDetail;
                    ToolTip = 'View the tax difference detailed entries that are associated with the archived general journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowTaxDifferences();
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Create FA Depreciation Books")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Create FA Depreciation Books';
                    Image = NewDepreciationBook;

                    trigger OnAction()
                    begin
                        FixedAsset.Get(Rec."No.");
                        REPORT.Run(REPORT::"Create FA Depreciation Books", true, true, FixedAsset);
                    end;
                }
            }
            action(CalculateDepreciation)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Calculate Depreciation';
                Image = CalculateDepreciation;
                ToolTip = 'Calculate depreciation according to the conditions that you define. If the fixed assets that are included in the batch job are integrated with the general ledger (defined in the depreciation book that is used in the batch job), the resulting entries are transferred to the fixed assets general ledger journal. Otherwise, the batch job transfers the entries to the fixed asset journal. You can then post the journal or adjust the entries before posting, if necessary.';

                trigger OnAction()
                var
                    FixedAsset: Record "Fixed Asset";
                begin
                    FixedAsset.SetRange("No.", Rec."No.");
                    REPORT.RunModal(REPORT::"Calculate Depreciation", true, false, FixedAsset);
                end;
            }
            action("C&opy Fixed Asset")
            {
                ApplicationArea = FixedAssets;
                Caption = 'C&opy Fixed Asset';
                Ellipsis = true;
                Image = CopyFixedAssets;
                ToolTip = 'View or edit fixed asset components of the main fixed asset that is represented by the fixed asset card.';

                trigger OnAction()
                var
                    CopyFA: Report "Copy Fixed Asset";
                begin
                    CopyFA.SetFANo(Rec."No.");
                    CopyFA.RunModal();
                end;
            }
        }
        area(reporting)
        {
#if not CLEAN28
            action(Details)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Details (Obsolete)';
                Image = View;
                RunObject = Report "Fixed Asset - Details";
                ToolTip = 'View detailed information about the fixed asset ledger entries that have been posted to a specified depreciation book for each fixed asset.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Fixed Asset Details (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("FA Book Value")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Book Value';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 01";
            }
            action("FA Book Val. - Appr. & Write-D")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Book Val. - Appr. & Write-D';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 02";
            }
#if not CLEAN28
            action(Analysis)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Analysis (Obsolete)';
                Image = "Report";
                RunObject = Report "Fixed Asset - Analysis";
                ToolTip = 'View an analysis of your fixed assets with various types of data for both individual fixed assets and groups of fixed assets.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Fixed Asset Analysis (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
            action("Projected Value")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Projected Value (Obsolete)';
                Image = "Report";
                RunObject = Report "Fixed Asset - Projected Value";
                ToolTip = 'View the calculated future depreciation and book value. You can print the report for one depreciation book at a time.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Fixed Asset Projected Value (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("G/L Analysis")
            {
                ApplicationArea = FixedAssets;
                Caption = 'G/L Analysis';
                Image = "Report";
                RunObject = Report "Fixed Asset - G/L Analysis";
            }
            action(Register)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Register';
                Image = Confirm;
                RunObject = Report "Fixed Asset Register";
            }
            action("Report FA Inventory Card FA-6")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Inventory Card FA-6';
                Image = "Report";

                trigger OnAction()
                begin
                    FixedAsset.Get(Rec."No.");
                    FixedAsset.SetRecFilter();
                    REPORT.Run(REPORT::"FA Inventory Card FA-6", true, true, FixedAsset);
                end;
            }
            action("FA G/L Turnover")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA G/L Turnover';
                Image = Turnover;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Page "FA G/L Turnover";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CalculateDepreciation_Promoted; CalculateDepreciation)
                {
                }
                actionref("C&opy Fixed Asset_Promoted"; "C&opy Fixed Asset")
                {
                }
            }
            group("Category_Fixed Asset")
            {
                Caption = 'Fixed Asset';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Attachments_Promoted; Attachments)
                {
                }
                actionref("Depreciation &Books_Promoted"; "Depreciation &Books")
                {
                }
                actionref("Maintenance &Registration_Promoted"; "Maintenance &Registration")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

#if not CLEAN28
                actionref(Analysis_Promoted; Analysis)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Fixed Asset Analysis (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                actionref("Projected Value_Promoted"; "Projected Value")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Fixed Asset Projected Value (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
                actionref(Details_Promoted; Details)
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Fixed Asset Details (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
            }
        }
    }

    protected var
        FixedAsset: Record "Fixed Asset";
}