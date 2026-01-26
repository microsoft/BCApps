// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

page 11408 "Post Code Updates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Post Code Updates';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Post Code Update Log Entry";
    SourceTableView = sorting("No.")
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies what kind of postal code file is concerned.';
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period';
                    Editable = false;
                    ToolTip = 'Specifies the month and year of the period of which the postal code file is based.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the postal code file was imported.';
                }
                field(Time; Rec.Time)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the time when the postal code file was imported.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who has imported the file.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Import &Post Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import &Post Codes';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Update the postal code directory, for example from the Swiss Post website. All postal codes in the range 1000 to 9999 will be deleted before import. International postal codes, which include a country/region code, such as DE-60000, are retained.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Import Post Codes");

                        CurrPage.Update();
                    end;
                }
                action("Import Post Codes &Update")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Post Codes &Update';
                    Ellipsis = true;
                    Image = ImportCodes;
                    ToolTip = 'Import the updated set of post code data. If the full set of post code data has not been imported, a message will display asking if you want to overwrite the existing data.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Import Post Codes Update");

                        CurrPage.Update();
                    end;
                }
            }
        }
    }
}

