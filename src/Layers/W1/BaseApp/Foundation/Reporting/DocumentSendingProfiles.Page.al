// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

page 359 "Document Sending Profiles"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Document Sending Profiles';
    CardPageID = "Document Sending Profile";
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Document Sending Profile";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify the document sending method in the system.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document sending format.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this document sending method will be used as the default method for all customers.';
                }
                field(Printer; Rec.Printer)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if and how the document is printed when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is printed according to settings that you must make on the printer setup dialog.';
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if and how the document is attached as a PDF file to an email to the involved customer when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is attached to an email according to settings that you must make in the Send Email window.';
                    Visible = false;
                }
                field("Electronic Document"; Rec."Electronic Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document is sent as an electronic document that the customer can import into their system when you choose the Post and Send button. To use this option, you must also fill the Electronic Format field. Alternatively, the file can be saved to disk.';
                    Visible = false;
                }
                field("Electronic Format"; Rec."Electronic Format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Format';
                    ToolTip = 'Specifies which format to use for electronic document sending. You must fill this field if you selected the Silent option in the Electronic Document field.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

