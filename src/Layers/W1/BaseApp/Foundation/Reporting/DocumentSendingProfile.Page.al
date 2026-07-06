// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

page 360 "Document Sending Profile"
{
    Caption = 'Document Sending Profile';
    PageType = Card;
    SourceTable = "Document Sending Profile";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
            }
            group("Sending Options")
            {
                Caption = 'Sending Options';
                field(Printer; Rec.Printer)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if and how the document is printed when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is printed according to settings that you must make on the printer setup dialog.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if and how the document is attached as a PDF file to an email to the involved customer when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is attached to an email according to settings that you must make in the Send Email window.';
                }
                group(Control15)
                {
                    ShowCaption = false;
                    Visible = Rec."E-Mail" <> Rec."E-Mail"::No;
                    field("E-Mail Attachment"; Rec."E-Mail Attachment")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of file to attach.';

                        trigger OnValidate()
                        begin
                            Rec."E-Mail Format" := GetFormat();
                        end;
                    }
                    group(Control16)
                    {
                        ShowCaption = false;
                        Visible = Rec."E-Mail Attachment" <> Rec."E-Mail Attachment"::PDF;
                        field("E-Mail Format"; Rec."E-Mail Format")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Format';
                            ToolTip = 'Specifies how customers are set up with their preferred method of sending sales documents.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupElectronicFormat(Rec."E-Mail Format");
                            end;

                            trigger OnValidate()
                            begin
                                LastFormat := Rec."E-Mail Format";
                            end;
                        }
                    }
                    group(Control19)
                    {
                        ShowCaption = false;
                        Visible = Rec."E-Mail" = Rec."E-Mail"::"Yes (Prompt for Settings)";
                        field("Combine PDF Documents"; Rec."Combine Email Documents")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Combine PDF Documents';
                            ToolTip = 'Merge selected documents into a single PDF file when you send the documents by email or print them. For example, this reduces the number of documents the recipient must process.';
                        }
                    }
                }
                field(Disk; Rec.Disk)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify if the document is saved as a PDF file when you choose the Post and Send button.';

                    trigger OnValidate()
                    begin
                        Rec."Disk Format" := GetFormat();
                    end;
                }
                group(Control17)
                {
                    ShowCaption = false;
                    Visible = (Rec.Disk <> Rec.Disk::No) and (Rec.Disk <> Rec.Disk::PDF);
                    field("Disk Format"; Rec."Disk Format")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format';
                        ToolTip = 'Specifies how customers are set up with their preferred method of sending sales documents.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupElectronicFormat(Rec."Disk Format");
                        end;

                        trigger OnValidate()
                        begin
                            LastFormat := Rec."Disk Format";
                        end;
                    }
                }
                field("Electronic Document"; Rec."Electronic Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document is sent as an electronic document that the customer can import into their system when you choose the Post and Send button. To use this option, you must also fill the Electronic Format field. Alternatively, the file can be saved to disk.';
                    Visible = ElectronicDocumentsVisible;

                    trigger OnValidate()
                    begin
                        Rec."Electronic Format" := GetFormat();
                    end;
                }
                group(Control18)
                {
                    ShowCaption = false;
                    Visible = Rec."Electronic Document" <> Rec."Electronic Document"::No;
                    field("Electronic Format"; Rec."Electronic Format")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format';
                        ToolTip = 'Specifies which format to use for electronic document sending. You must fill this field if you selected the Silent option in the Electronic Document field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupElectronicFormat(Rec."Electronic Format");
                        end;

                        trigger OnValidate()
                        begin
                            LastFormat := Rec."Electronic Format";
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.OnDiscoverElectronicFormat();
        ElectronicDocumentsVisible := not ElectronicDocumentFormat.IsEmpty();
    end;

    protected var
        LastFormat: Code[20];
        ElectronicDocumentsVisible: Boolean;

    procedure LookupElectronicFormat(var ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ElectronicDocumentFormats: Page "Electronic Document Formats";
    begin
        LastFormat := ElectronicFormat;
        ElectronicDocumentFormat.SetRange(Usage, Rec.Usage);
        ElectronicDocumentFormats.SetTableView(ElectronicDocumentFormat);
        ElectronicDocumentFormats.LookupMode := true;

        if ElectronicDocumentFormats.RunModal() = ACTION::LookupOK then begin
            ElectronicDocumentFormats.GetRecord(ElectronicDocumentFormat);
            ElectronicFormat := ElectronicDocumentFormat.Code;
            LastFormat := ElectronicDocumentFormat.Code;
            exit;
        end;

        ElectronicFormat := GetFormat();
    end;

    procedure GetFormat(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FindNewFormat: Boolean;
    begin
        FindNewFormat := false;

        if LastFormat = '' then
            FindNewFormat := true
        else begin
            ElectronicDocumentFormat.SetRange(Code, LastFormat);
            ElectronicDocumentFormat.SetRange(Usage, Rec.Usage);
            if not ElectronicDocumentFormat.FindFirst() then
                FindNewFormat := true;
        end;

        if FindNewFormat then begin
            ElectronicDocumentFormat.SetRange(Code);
            ElectronicDocumentFormat.SetRange(Usage, Rec.Usage);
            if not ElectronicDocumentFormat.FindFirst() then
                LastFormat := ''
            else
                LastFormat := ElectronicDocumentFormat.Code;
        end;

        exit(LastFormat);
    end;
}

