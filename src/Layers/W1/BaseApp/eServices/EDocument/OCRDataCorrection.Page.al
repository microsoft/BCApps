// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 1272 "OCR Data Correction"
{
    Caption = 'OCR Data Correction';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Incoming Document";

    layout
    {
        area(content)
        {
            group(Control35)
            {
                ShowCaption = false;
                grid(Control2)
                {
                    ShowCaption = false;
                    group(Control16)
                    {
                        ShowCaption = false;
                        field("Vendor Name"; Rec."Vendor Name")
                        {
                            ApplicationArea = Basic, Suite;
                            ShowMandatory = true;
                        }
                        field("Vendor VAT Registration No."; Rec."Vendor VAT Registration No.")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Vendor IBAN"; Rec."Vendor IBAN")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Vendor Bank Branch No."; Rec."Vendor Bank Branch No.")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Vendor Bank Account No."; Rec."Vendor Bank Account No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the new value that you want the OCR service to produce for this field going forward.';
                        }
                        field("Vendor Phone No."; Rec."Vendor Phone No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the new value that you want the OCR service to produce for this field going forward.';
                        }
                        field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Order No."; Rec."Order No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Order No.';
                        }
                        field("Document Date"; Rec."Document Date")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Due Date"; Rec."Due Date")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Currency Code"; Rec."Currency Code")
                        {
                            ApplicationArea = Suite;
                        }
                        field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("Amount Excl. VAT"; Rec."Amount Excl. VAT")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                        field("VAT Amount"; Rec."VAT Amount")
                        {
                            ApplicationArea = Basic, Suite;
                        }
                    }
                    group(Control18)
                    {
                        ShowCaption = false;
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor Name"""; TempOriginalIncomingDocument."Vendor Name")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Name';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor VAT Registration No."""; TempOriginalIncomingDocument."Vendor VAT Registration No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor VAT Registration No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor IBAN"""; TempOriginalIncomingDocument."Vendor IBAN")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor IBAN';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor Bank Branch No."""; TempOriginalIncomingDocument."Vendor Bank Branch No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Bank Branch No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor Bank Account No."""; TempOriginalIncomingDocument."Vendor Bank Account No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Bank Account No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor Phone No."""; TempOriginalIncomingDocument."Vendor Phone No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Phone No.';
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Vendor Invoice No."""; TempOriginalIncomingDocument."Vendor Invoice No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Invoice No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Order No."""; TempOriginalIncomingDocument."Order No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Order No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Document Date"""; TempOriginalIncomingDocument."Document Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document Date';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Due Date"""; TempOriginalIncomingDocument."Due Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Due Date';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Currency Code"""; TempOriginalIncomingDocument."Currency Code")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Amount Incl. VAT"""; TempOriginalIncomingDocument."Amount Incl. VAT")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount Incl. VAT';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""Amount Excl. VAT"""; TempOriginalIncomingDocument."Amount Excl. VAT")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount Excl. VAT';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
#pragma warning disable AA0100
                        field("TempOriginalIncomingDocument.""VAT Amount"""; TempOriginalIncomingDocument."VAT Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Reset OCR Data")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset OCR Data';
                Image = Reuse;
                ToolTip = 'Undo corrections that you have made since you opened the OCR Data Correction window.';

                trigger OnAction()
                begin
                    Rec.ResetOriginalOCRData();
                end;
            }
            action("Send OCR Feedback")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send OCR Feedback';
                Image = Undo;
                ToolTip = 'Send the corrections to the OCR service. The corrections will be included PDF or image files that contain the data the next time the service processes.';

                trigger OnAction()
                begin
                    if Rec.UploadCorrectedOCRData() then
                        CurrPage.Close();
                end;
            }
            action(ShowFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show File';
                Image = Export;
                ToolTip = 'Open the PDF or image file to see the corrections that you have made.';

                trigger OnAction()
                begin
                    Rec.ShowMainAttachment();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Reset OCR Data_Promoted"; "Reset OCR Data")
                {
                }
                actionref("Send OCR Feedback_Promoted"; "Send OCR Feedback")
                {
                }
                actionref(ShowFile_Promoted; ShowFile)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TempOriginalIncomingDocument := Rec;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec."OCR Data Corrected" := true;
        Rec.Modify();
        exit(false)
    end;

    var
        TempOriginalIncomingDocument: Record "Incoming Document" temporary;
}

