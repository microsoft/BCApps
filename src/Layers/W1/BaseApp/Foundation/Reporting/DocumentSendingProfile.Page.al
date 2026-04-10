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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group("Sending Options")
            {
                Caption = 'Sending Options';
                field(Printer; Rec.Printer)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                }
                group(Control15)
                {
                    ShowCaption = false;
                    Visible = Rec."E-Mail" <> Rec."E-Mail"::No;
                    field("E-Mail Attachment"; Rec."E-Mail Attachment")
                    {
                        ApplicationArea = Basic, Suite;

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
                        }
                    }
                }
                field(Disk; Rec.Disk)
                {
                    ApplicationArea = Basic, Suite;

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

