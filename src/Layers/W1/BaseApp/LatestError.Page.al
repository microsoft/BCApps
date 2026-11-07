// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Utilities;

page 9180 "Latest Error"
{
    ApplicationArea = All;
    Caption = 'Latest Error';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    ShowFilter = false;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                group("Error Details")
                {
                    Caption = 'Error Details';
                    Visible = ErrorOccurred;
                    field(ErrorText; GetLastErrorText)
                    {
                        ApplicationArea = All;
                        Caption = 'Error Text';
                    }
                    field(ErrorCode; GetLastErrorCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Error Code';
                    }
                    group(ErrorCallStackLabel)
                    {
                        Caption = 'Error Callstack';
                        field(ErrorCallStack; GetLastErrorCallstack)
                        {
                            ApplicationArea = All;
                            MultiLine = true;
                            ShowCaption = false;
                        }
                    }
                }
                group(Control12)
                {
                    InstructionalText = 'No errors have occurred since you last logged in';
                    ShowCaption = false;
                    Visible = not ErrorOccurred;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        ErrorOccurred := GetLastErrorCallstack <> '';
    end;

    var
        ErrorOccurred: Boolean;
}

