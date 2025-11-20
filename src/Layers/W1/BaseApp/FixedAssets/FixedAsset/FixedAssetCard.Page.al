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
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;
using Microsoft.Utilities;
using System.Utilities;

page 5600 "Fixed Asset Card"
{
    Caption = 'Fixed Asset Card';
    PageType = Document;
    Permissions = TableData "FA Depreciation Book" = rim;
    RefreshOnActivate = true;
    SourceTable = "Fixed Asset";
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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;

                    trigger OnValidate()
                    begin
                        ShowAcquisitionNotification();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        ShowAcquisitionNotification();
                    end;
                }
                group(Control34)
                {
                    ShowCaption = false;
                    field("FA Class Code"; Rec."FA Class Code")
                    {
                        ApplicationArea = FixedAssets;
                        Importance = Promoted;
                        ToolTip = 'Specifies the class that the fixed asset belongs to.';
                    }
                    field("FA Subclass Code"; Rec."FA Subclass Code")
                    {
                        ApplicationArea = FixedAssets;
                        Importance = Promoted;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the subclass of the class that the fixed asset belongs to.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            FASubclass: Record "FA Subclass";
                        begin
                            if Rec."FA Class Code" <> '' then
                                FASubclass.SetFilter("FA Class Code", '%1|%2', '', Rec."FA Class Code");

                            if FASubclass.Get(Rec."FA Subclass Code") then;
                            if PAGE.RunModal(0, FASubclass) = ACTION::LookupOK then begin
                                Text := FASubclass.Code;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        var
                            IsHandled: Boolean;
                        begin
                            IsHandled := false;
                            OnBeforeOnValidateFASubclassCodePage(Rec, xRec, IsHandled);
                            if IsHandled then
                                exit;

                            SetDefaultDepreciationBook();
                            SetDefaultPostingGroup();
                            ShowAcquisitionNotification();
                        end;
                    }
                }
                field("FA Location Code"; Rec."FA Location Code")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                }
                field("Budgeted Asset"; Rec."Budgeted Asset")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies if the asset is for budgeting purposes.';

                    trigger OnValidate()
                    begin
                        ShowAcquisitionNotification();
                    end;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the fixed asset''s serial number.';
                }
                field("Main Asset/Component"; Rec."Main Asset/Component")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies if the fixed asset is a main fixed asset or a component of a fixed asset.';
                }
                field("Component of Main Asset"; Rec."Component of Main Asset")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the main fixed asset.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a search description for the fixed asset.';
                }
                field("Responsible Employee"; Rec."Responsible Employee")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies which employee is responsible for the fixed asset.';
                }
                field(Inactive; Rec.Inactive)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies that the fixed asset is inactive (for example, if the asset is not in service or is obsolete).';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field(Acquired; Rec.Acquired)
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies if the fixed asset has been acquired.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Additional;
                    ToolTip = 'Specifies when the fixed asset card was last modified.';
                }
            }
            group("Depreciation Book")
            {
                Caption = 'Depreciation Book';
                AboutTitle = 'Manage the Fixed Asset Invoicing and Depreciation';
                AboutText = 'Specify the depreciation method to calculate and post the depreciation. Assign posting groups to control how the fixed asset transactions are grouped and posted, based on the type of fixed asset.';
                Visible = Simple;
                field(DepreciationBookCode; FADepreciationBook."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Book Code';
                    Importance = Additional;
                    TableRelation = "Depreciation Book";
                    ToolTip = 'Specifies the depreciation book that is assigned to the fixed asset.';
                    Editable = AllowEditDepBookCode;

                    trigger OnValidate()
                    begin
                        LoadFADepreciationBooks();
                        FADepreciationBook.Validate("Depreciation Book Code");
                        SaveSimpleDepreciationBook(xRec."No.");
                        ShowAcquisitionNotification();
                    end;
                }
                field(FAPostingGroup; FADepreciationBook."FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Posting Group';
                    Importance = Additional;
                    TableRelation = "FA Posting Group";
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';

                    trigger OnValidate()
                    begin
                        LoadFADepreciationBooks();
                        FADepreciationBook.Validate("FA Posting Group");
                        SaveSimpleDepreciationBook(xRec."No.");
                        ShowAcquisitionNotification();
                    end;
                }
                field(DepreciationMethod; FADepreciationBook."Depreciation Method")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Method';
                    ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';

                    trigger OnValidate()
                    begin
                        LoadFADepreciationBooks();
                        FADepreciationBook.Validate("Depreciation Method");
                        SaveSimpleDepreciationBook(xRec."No.");
                        ShowAcquisitionNotification();
                    end;
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field(DepreciationStartingDate; FADepreciationBook."Depreciation Starting Date")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Starting Date';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';

                        trigger OnValidate()
                        begin
                            LoadFADepreciationBooks();
                            FADepreciationBook.Validate("Depreciation Starting Date");
                            SaveSimpleDepreciationBook(xRec."No.");
                            ShowAcquisitionNotification();
                        end;
                    }
                    field(NumberOfDepreciationYears; FADepreciationBook."No. of Depreciation Years")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'No. of Depreciation Years';
                        ToolTip = 'Specifies the length of the depreciation period, expressed in years.';

                        trigger OnValidate()
                        begin
                            LoadFADepreciationBooks();
                            FADepreciationBook.Validate("No. of Depreciation Years");
                            SaveSimpleDepreciationBook(xRec."No.");
                            ShowAcquisitionNotification();
                        end;
                    }
                    field(DepreciationEndingDate; FADepreciationBook."Depreciation Ending Date")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Ending Date';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';

                        trigger OnValidate()
                        begin
                            LoadFADepreciationBooks();
                            FADepreciationBook.Validate("Depreciation Ending Date");
                            SaveSimpleDepreciationBook(xRec."No.");
                            ShowAcquisitionNotification();
                        end;
                    }
                }
                field(BookValue; BookValue)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Book Value';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the book value for the fixed asset.';

                    trigger OnDrillDown()
                    begin
                        FADepreciationBook.DrillDownOnBookValue();
                    end;
                }
                field(DepreciationTableCode; FADepreciationBook."Depreciation Table Code")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Depreciation Table Code';
                    Importance = Additional;
                    TableRelation = "Depreciation Table Header";
                    ToolTip = 'Specifies the code of the depreciation table to use if you have selected the User-Defined option in the Depreciation Method field.';

                    trigger OnValidate()
                    begin
                        LoadFADepreciationBooks();
                        FADepreciationBook.Validate("Depreciation Table Code");
                        SaveSimpleDepreciationBook(xRec."No.");
                    end;
                }
                field(UseHalfYearConvention; FADepreciationBook."Use Half-Year Convention")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Use Half-Year Convention';
                    Importance = Additional;
                    ToolTip = 'Specifies that the Half-Year Convention is to be applied to the selected depreciation method.';

                    trigger OnValidate()
                    begin
                        LoadFADepreciationBooks();
                        FADepreciationBook.Validate("Use Half-Year Convention");
                        SaveSimpleDepreciationBook(xRec."No.");
                    end;
                }
                group(Control38)
                {
                    ShowCaption = false;
                    Visible = ShowAddMoreDeprBooksLbl;
                    field(AddMoreDeprBooks; AddMoreDeprBooksLbl)
                    {
                        ApplicationArea = FixedAssets;
                        DrillDown = true;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;

                        trigger OnDrillDown()
                        begin
                            Simple := not Simple;
                        end;
                    }
                }
            }
            part(DepreciationBook; "FA Depreciation Books Subform")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Depreciation Books';
                AboutTitle = 'About Depreciation Table List';
                AboutText = 'Here you overview all the fixed assets with registered depreciation books, FA Posting Group, Depreciation Method, Starting date, Ending date, No. of depreciation years, Depreciation percentage, Book value details.';
                SubPageLink = "FA No." = field("No.");
                Visible = not Simple;
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
                    ToolTip = 'Specifies the number of the vendor from which you purchased this fixed asset.';
                }
                field("Maintenance Vendor No."; Rec."Maintenance Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor who performs repairs and maintenance on the fixed asset.';
                }
                field("Under Maintenance"; Rec."Under Maintenance")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the fixed asset is currently being repaired.';
                }
                field("Next Service Date"; Rec."Next Service Date")
                {
                    ApplicationArea = FixedAssets;
                    Importance = Promoted;
                    ToolTip = 'Specifies the next scheduled service date for the fixed asset. This is used as a filter in the Maintenance - Next Service report.';
                }
                field("Warranty Date"; Rec."Warranty Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the warranty expiration date of the fixed asset.';
                }
                field(Insured; Rec.Insured)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that the fixed asset is linked to an insurance policy.';
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
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = All;
                Visible = false;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Fixed Asset"),
                              "No." = field("No.");
            }
#endif
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
            }
        }
        area(processing)
        {
            action(Acquire)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Acquire';
                Enabled = Acquirable;
                Image = ValidateEmailLoggingSetup;
                ToolTip = 'Acquire the fixed asset.';

                trigger OnAction()
                var
                    FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
                begin
                    FixedAssetAcquisitionWizard.RunAcquisitionWizard(Rec."No.");
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
            action(Details)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Details';
                Image = View;
                RunObject = Report "Fixed Asset - Details";
                ToolTip = 'View detailed information about the fixed asset ledger entries that have been posted to a specified depreciation book for each fixed asset.';
            }
            action("FA Book Value")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Book Value';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 01";
                ToolTip = 'View detailed information about acquisition cost, depreciation and book value for both individual fixed assets and groups of fixed assets. For each of these three amount types, amounts are calculated at the beginning and at the end of a specified period as well as for the period itself.';
            }
            action("FA Book Val. - Appr. & Write-D")
            {
                ApplicationArea = FixedAssets;
                Caption = 'FA Book Val. - Appr. & Write-D';
                Image = "Report";
                RunObject = Report "Fixed Asset - Book Value 02";
                ToolTip = 'View detailed information about acquisition cost, depreciation, appreciation, write-down and book value for both individual fixed assets and groups of fixed assets. For each of these categories, amounts are calculated at the beginning and at the end of a specified period, as well as for the period itself.';
            }
            action(Analysis)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Analysis';
                Image = "Report";
                RunObject = Report "Fixed Asset - Analysis";
                ToolTip = 'View an analysis of your fixed assets with various types of data for both individual fixed assets and groups of fixed assets.';
            }
            action("Projected Value")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Projected Value';
                Image = "Report";
                RunObject = Report "Fixed Asset - Projected Value";
                ToolTip = 'View the calculated future depreciation and book value. You can print the report for one depreciation book at a time.';
            }
            action("G/L Analysis")
            {
                ApplicationArea = FixedAssets;
                Caption = 'G/L Analysis';
                Image = "Report";
                RunObject = Report "Fixed Asset - G/L Analysis";
                ToolTip = 'View an analysis of your fixed assets with various types of data for individual fixed assets and/or groups of fixed assets.';
            }
            action(Register)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Register';
                Image = Confirm;
                RunObject = Report "Fixed Asset Register";
                ToolTip = 'View registers containing all the fixed asset entries that are created. Each register shows the first and last entry number of its entries.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Acquire_Promoted; Acquire)
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

                actionref(Analysis_Promoted; Analysis)
                {
                }
                actionref("Projected Value_Promoted"; "Projected Value")
                {
                }
                actionref(Details_Promoted; Details)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."No." <> xRec."No." then
            SaveSimpleDepreciationBook(xRec."No.");

        LoadFADepreciationBooks();
        CurrPage.Update(false);
        FADepreciationBook.Copy(FADepreciationBookOld);
        ShowAcquisitionNotification();
        BookValue := GetBookValue();
    end;

    trigger OnOpenPage()
    begin
        Simple := true;
        AllowEditDepBookCode := true;
        SetNoFieldVisible();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        SaveSimpleDepreciationBook(Rec."No.");
    end;

    var
        FAAcquireWizardNotificationId: Guid;
        NoFieldVisible: Boolean;
        AddMoreDeprBooksLbl: Label 'Add More Depreciation Books';
        Acquirable: Boolean;
        ShowAddMoreDeprBooksLbl: Boolean;
        BookValue: Decimal;
        FAPostingGroupChangeDeniedMsg: Label 'The current FA posting group is %1 but the FA subclass %2 has the default FA posting group %3. \Because there are posted FA ledger entries we will not change the FA posting group.', Comment = '%1 = FA Posting Group Code, %2 = FA Subclass Code, %3 = Default FA Posting Group. Example: The current FA posting group is MACHINERY but the FA subclass TANGIBLE has the default FA posting group CAR. \Because there are posted FA ledger entries we will not change the FA posting group.';
        FAPostingGroupChangeConfirmTxt: Label 'The current FA posting group is %1, but the FA subclass %2 has the default FA posting group %3. \Do you want to update the FA posting group?', Comment = '%1 = FA Posting Group Code, %2 = FA Subclass Code, %3 = Default FA Posting Group. The current FA posting group is MACHINERY, but the FA subclass TANGIBLE has the default FA posting group CAR. \Do you want to update the FA posting group?';
        AllowEditDepBookCode: Boolean;

    protected var
        FADepreciationBook: Record "FA Depreciation Book";
        FADepreciationBookOld: Record "FA Depreciation Book";
        Simple: Boolean;

    protected procedure ShowAcquisitionNotification()
    var
        ShowNotification: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowAcquisitionNotification(Rec, Acquirable, IsHandled);
        if IsHandled then
            exit;

        ShowNotification :=
          (not Rec.Acquired) and (not Rec."Budgeted Asset") and
          Rec.FieldsForAcquitionInGeneralGroupAreCompleted() and AtLeastOneDepreciationLineIsComplete();
        if ShowNotification and IsNullGuid(FAAcquireWizardNotificationId) then begin
            Acquirable := true;
            Rec.ShowAcquireWizardNotification();
        end else
            Acquirable := false;
    end;

    local procedure AtLeastOneDepreciationLineIsComplete(): Boolean
    var
        FADepreciationBookMultiline: Record "FA Depreciation Book";
    begin
        if Simple then
            exit(FADepreciationBook.RecIsReadyForAcquisition());

        exit(FADepreciationBookMultiline.LineIsReadyForAcquisition(Rec."No."));
    end;

    procedure SaveSimpleDepreciationBook(FixedAssetNo: Code[20])
    begin
        if not SimpleFADepreciationBookHasChanged() then
            exit;

        if Simple then
            UpdateDepreciationBook(FixedAssetNo);
    end;

    procedure UpdateDepreciationBook(FixedAssetNo: Code[20])
    var
        FixedAsset: Record "Fixed Asset";
        LocalFADepreciationBook: Record "FA Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDepreciationBook(IsHandled, FixedAssetNo, FADepreciationBook);
        if IsHandled then
            exit;

        if FixedAsset.Get(FixedAssetNo) then
            if FADepreciationBook."Depreciation Book Code" <> '' then
                if FADepreciationBook."FA No." = '' then begin
                    FADepreciationBook.Validate("FA No.", FixedAssetNo);
                    FADepreciationBook.Insert(true)
                end else begin
                    if LocalFADepreciationBook.Get(FADepreciationBook."FA No.", FADepreciationBook."Depreciation Book Code") then
                        if LocalFADepreciationBook."Acquisition Date" <> 0D then begin
                            FADepreciationBook."Acquisition Date" := LocalFADepreciationBook."Acquisition Date";
                            FADepreciationBook."Acquisition Cost" := LocalFADepreciationBook."Acquisition Cost";
                            FADepreciationBook."G/L Acquisition Date" := LocalFADepreciationBook."G/L Acquisition Date";
                            FADepreciationBook."Last Acquisition Cost Date" := LocalFADepreciationBook."Last Acquisition Cost Date";
                        end;
                    FADepreciationBook.Description := Rec.Description;
                    FADepreciationBook.Modify(true);
                end;
    end;

    protected procedure SetDefaultDepreciationBook()
    var
        FASetup: Record "FA Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultDepreciationBook(Rec, FADepreciationBook, Simple, FADepreciationBookOld, ShowAddMoreDeprBooksLbl, AllowEditDepBookCode, IsHandled);
        if IsHandled then
            exit;

        if FADepreciationBook."Depreciation Book Code" = '' then begin
            FASetup.Get();
            FADepreciationBook.Validate("Depreciation Book Code", FASetup."Default Depr. Book");
            SaveSimpleDepreciationBook(Rec."No.");
            LoadFADepreciationBooks();
        end;
    end;

    protected procedure SetDefaultPostingGroup()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASubclass: Record "FA Subclass";
        ConfirmManagement: Codeunit "Confirm Management";
        UpdateAllowed: Boolean;
        UpdateConfirmed: Boolean;
        IsDifferentFAPostingGr: Boolean;
        IsHandled: Boolean;
    begin
        if FASubclass.Get(Rec."FA Subclass Code") then;
        UpdateAllowed := true;
        UpdateConfirmed := true;
        IsDifferentFAPostingGr := FADepreciationBook."FA Posting Group" <> FASubclass."Default FA Posting Group";

        if (FADepreciationBook."FA Posting Group" <> '') and IsDifferentFAPostingGr then begin
            FALedgerEntry.SetRange("FA No.", Rec."No.");
            UpdateAllowed := FALedgerEntry.IsEmpty();

            if UpdateAllowed then
                UpdateConfirmed := ConfirmManagement.GetResponseOrDefault(
                    StrSubstNo(
                        FAPostingGroupChangeConfirmTxt,
                        FADepreciationBook."FA Posting Group",
                        FASubclass.Code,
                        FASubclass."Default FA Posting Group"),
                    true)
        end;

        IsHandled := false;
        OnSetDefaultPostingGroupOnBeforeValidateFAPostingGroup(Rec, FADepreciationBook, FASubclass, UpdateConfirmed, UpdateAllowed, Simple, IsHandled);
        if not IsHandled then
            if UpdateConfirmed and UpdateAllowed then begin
                Rec.Validate("FA Posting Group", FASubclass."Default FA Posting Group");
                if IsDifferentFAPostingGr then begin
                    FADepreciationBook.Validate("FA Posting Group", FASubclass."Default FA Posting Group");
                    if Simple then
                        SaveSimpleDepreciationBook(Rec."No.")
                    else
                        UpdateDepreciationBook(Rec."No.");
                end;
            end;
        if not UpdateAllowed and IsDifferentFAPostingGr then
            Message(
                FAPostingGroupChangeDeniedMsg,
                FADepreciationBook."FA Posting Group",
                FASubclass.Code,
                FASubclass."Default FA Posting Group");
    end;

    protected procedure SimpleFADepreciationBookHasChanged(): Boolean
    begin
        exit(Format(FADepreciationBook) <> Format(FADepreciationBookOld));
    end;

    protected procedure LoadFADepreciationBooks()
    begin
        Clear(FADepreciationBookOld);
        FADepreciationBookOld.SetRange("FA No.", Rec."No.");
        if FADepreciationBookOld.Count <= 1 then begin
            if FADepreciationBookOld.FindFirst() then begin
                FADepreciationBookOld.CalcFields("Book Value");
                ShowAddMoreDeprBooksLbl := true
            end;
            Simple := true;
            AllowEditDepBookCode := FADepreciationBookOld."Depreciation Book Code" = '';
        end else
            Simple := false;

        OnAfterLoadDepreciationBooks(Rec, Simple);
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.FixedAssetNoIsVisible();
    end;

    local procedure GetBookValue(): Decimal
    begin
        if FADepreciationBook."Disposal Date" > 0D then
            exit(0);
        exit(FADepreciationBook."Book Value");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLoadDepreciationBooks(FixedAsset: Record "Fixed Asset"; var Simple: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAcquisitionNotification(FixedAsset: Record "Fixed Asset"; var Acquirable: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDepreciationBook(var IsHandled: Boolean; var FixedAssetNo: Code[20]; var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateFASubclassCodePage(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDefaultPostingGroupOnBeforeValidateFAPostingGroup(var FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; FASubClass: Record "FA Subclass"; var UpdateConfirmed: Boolean; var UpdateAllowed: Boolean; var Simple: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetDefaultDepreciationBook(var FixedAsset: Record "Fixed Asset"; FADepreciationBook: Record "FA Depreciation Book"; var Simple: Boolean; var FADepreciationBookOld: Record "FA Depreciation Book"; var ShowAddMoreDeprBooksLbl: Boolean; var AllowEditDepBookCode: Boolean; var IsHandled: Boolean)
    begin
    end;
}
