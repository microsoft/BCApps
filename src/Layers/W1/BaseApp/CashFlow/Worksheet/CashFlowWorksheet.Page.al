// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Dimension;
using System.Environment.Configuration;
using System.Integration.Excel;
using System.Utilities;

page 841 "Cash Flow Worksheet"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Cash Flow Worksheet';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Cash Flow Worksheet Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field("Cash Flow Date"; Rec."Cash Flow Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cash flow date that the entry is posted to.';
                }
                field(Overdue; Rec.Overdue)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry is related to an overdue payment. ';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document that represents the forecast entry.';
                }
                field("Cash Flow Forecast No."; Rec."Cash Flow Forecast No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the cash flow forecast.';

                    trigger OnValidate()
                    begin
                        CFName := CashFlowManagement.CashFlowNameFullLength(Rec."Cash Flow Forecast No.");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the worksheet.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = SourceNumEnabled;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Cash Flow Account No."; Rec."Cash Flow Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash flow account.';

                    trigger OnValidate()
                    begin
                        CFAccName := CashFlowManagement.CashFlowAccountName(Rec."Cash Flow Account No.");
                    end;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the worksheet line in LCY. Revenues are entered without a plus or minus sign. Expenses are entered with a minus sign.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
            group(Control1046)
            {
                ShowCaption = false;
                part(ErrorMessagesPart; "Error Messages Part")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Errors and Warnings';
                }
                fixed(Control1907160701)
                {
                    ShowCaption = false;
                    group("Cash Flow Forecast Description")
                    {
                        Caption = 'Cash Flow Forecast Description';
                        field(CFName; CFName)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the cash flow account name on the cash flow worksheet.';
                        }
                    }
                    group("Cash Flow Account Name")
                    {
                        Caption = 'Cash Flow Account Name';
                        field(CFAccName; CFAccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Cash Flow Account Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the cash flow forecast.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("&Cash Flow")
            {
                Caption = '&Cash Flow';
                Image = CashFlow;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Cash Flow Forecast Card";
                    RunPageLink = "No." = field("Cash Flow Forecast No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action(Entries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries';
                    Image = Entries;
                    RunObject = Page "Cash Flow Forecast Entries";
                    RunPageLink = "Cash Flow Forecast No." = field("Cash Flow Forecast No.");
                    RunPageView = sorting("Cash Flow Forecast No.", "Cash Flow Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the entries that exist for the cash flow account. ';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SuggestWorksheetLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Worksheet Lines';
                    Ellipsis = true;
                    Image = Import;
                    ShortCutKey = 'Shift+Ctrl+F';
                    ToolTip = 'Transfer information from the areas of general ledger, purchasing, sales, service, fixed assets, manual revenues, and manual expenses to the cash flow worksheet. You use the batch job to make a cash flow forecast.';

                    trigger OnAction()
                    begin
                        DeleteErrors();
                        SuggestWkshLines.RunModal();
                        Clear(SuggestWkshLines);
                    end;
                }
            }
            group(Action1051)
            {
                Caption = 'Register';
                Image = Approve;
                action(Register)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Register';
                    Image = Approve;
                    ShortCutKey = 'F9';
                    ToolTip = 'Update negative or positive amounts of cash inflows and outflows for the cash flow account by registering the worksheet lines. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh. - Register", Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            action(ShowSource)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show';
                Image = View;
                ToolTip = 'View the actual cash flow forecast entries.';

                trigger OnAction()
                begin
                    Rec.ShowSource();
                end;
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                    begin
                        EditinExcel.EditPageInExcel(CurrPage.Caption, Page::"Cash Flow Worksheet");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestWorksheetLines_Promoted; SuggestWorksheetLines)
                {
                }
                actionref(Register_Promoted; Register)
                {
                }
                actionref(ShowSource_Promoted; ShowSource)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Cash Flow', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Card_Promoted; Card)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(EditInExcel_Promoted; EditInExcel)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ShowErrors();
        CFName := CashFlowManagement.CashFlowNameFullLength(Rec."Cash Flow Forecast No.");
        CFAccName := CashFlowManagement.CashFlowAccountName(Rec."Cash Flow Account No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        SourceNumEnabled := Rec."Source Type" <> Rec."Source Type"::Tax;
    end;

    trigger OnClosePage()
    begin
        DeleteErrors();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        CFName := '';
        CFAccName := '';
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        DeleteErrors();
    end;

    var
        SuggestWkshLines: Report "Suggest Worksheet Lines";
        CashFlowManagement: Codeunit "Cash Flow Management";
        CFName: Text[100];
        CFAccName: Text[100];
        SourceNumEnabled: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;

    protected var
        ShortcutDimCode: array[8] of Code[20];

    local procedure ShowErrors()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if CashFlowSetup.Get() then begin
            ErrorMessage.SetRange("Context Record ID", CashFlowSetup.RecordId);
            ErrorMessage.CopyToTemp(TempErrorMessage);
            CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
            CurrPage.ErrorMessagesPart.PAGE.Update();
        end;
    end;

    procedure DeleteErrors()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        ErrorMessage: Record "Error Message";
    begin
        if CashFlowSetup.Get() then begin
            ErrorMessage.SetRange("Context Record ID", CashFlowSetup.RecordId);
            if ErrorMessage.FindFirst() then
                ErrorMessage.DeleteAll(true);
            Commit();
        end;
    end;
}

