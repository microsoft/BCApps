// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Email;
using System.Globalization;
using System.Integration.Word;
using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 5069 "Word Template Interactions"
{
    /// <summary>
    /// Performs mail merge on the Word templates from the attachments specified by TempDeliverySorterWord
    /// and sends them according to the correspondence Type.
    /// </summary>
    /// <param name="TempDeliverySorterWord">A temporary table containing information about attachments and their recipients.</param>
    procedure Merge(var TempDeliverySorterWord: Record "Delivery Sorter" temporary)
    var
        TempDeliverySorterBuffer: Record "Delivery Sorter" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
        ZipTempBlob: Codeunit "Temp Blob";
        LastAttachmentNo: Integer;
        LastCorrType: Enum "Correspondence Type";
        LastSubject: Text[100];
        ZipFileName: Text;
        LastSendWordDocsAsAttmt: Boolean;
        FirstRecord: Boolean;
        LineCount: Integer;
        NoOfRecords: Integer;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
    begin
        WindowDialog.Open(
          MergingInWordTxt +
          '#1############ @2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\' +
          '#3############ @4@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\' +
          '#5############ #6################################');

        WindowDialog.Update(1, PreparingTxt);
        WindowDialog.Update(5, ProgramStatusTxt);

        WindowDialog.Update(6, PreparingMergeTxt);
        TempDeliverySorterWord.SetCurrentKey(
          "Attachment No.", "Correspondence Type", Subject, "Send Word Docs. as Attmt.");
        TempDeliverySorterWord.SetFilter("Correspondence Type", '<>0');
        NoOfRecords := TempDeliverySorterWord.Count();
        TempDeliverySorterWord.Find('-');

        FirstRecord := true;
        LastAttachmentNo := 0;
        repeat
            LineCount := LineCount + 1;
            WindowDialog.Update(2, Round(LineCount / NoOfRecords * 10000, 1));
            WindowDialog.Update(3, Format(TempDeliverySorterWord."Correspondence Type"));

            if FirstRecord and (NoOfRecords > 1) then
                EnableZipArchive();

            if not FirstRecord and
               ((TempDeliverySorterWord."Attachment No." <> LastAttachmentNo) or
                (TempDeliverySorterWord."Correspondence Type" <> LastCorrType) or
                (TempDeliverySorterWord.Subject <> LastSubject) or
                (TempDeliverySorterWord."Send Word Docs. as Attmt." <> LastSendWordDocsAsAttmt))
            then begin
                ExecuteMerge(TempDeliverySorterBuffer);
                TempDeliverySorterBuffer.DeleteAll();
            end;

            TempDeliverySorterBuffer := TempDeliverySorterWord;
            TempDeliverySorterBuffer.Insert();
            LastAttachmentNo := TempDeliverySorterWord."Attachment No.";
            LastCorrType := TempDeliverySorterWord."Correspondence Type";
            LastSubject := TempDeliverySorterWord.Subject;
            LastSendWordDocsAsAttmt := TempDeliverySorterWord."Send Word Docs. as Attmt.";

            FirstRecord := false;
        until TempDeliverySorterWord.Next() = 0;

        if TempDeliverySorterBuffer.Find('-') then
            ExecuteMerge(TempDeliverySorterBuffer);

        if IsZipArchive() then begin
            ZipTempBlob.CreateOutStream(ZipOutStream);
            DataCompression.SaveZipArchive(ZipOutStream);
            DataCompression.CloseZipArchive();
            ZipTempBlob.CreateInStream(ZipInStream);
            if InteractionLogEntry.Get(TempDeliverySorterWord."No.") then
                ZipFileName := SegmentLbl + ' ' + InteractionLogEntry."Segment No." + ZipExtensionLbl
            else
                ZipFileName := TempDeliverySorterWord.Subject + ZipExtensionLbl;
            FileManagement.DownloadFromStreamHandler(ZipInStream, '', '', '', ZipFileName);
        end;
        WindowDialog.Close();
    end;

    local procedure ExecuteMerge(var TempDeliverySorter: Record "Delivery Sorter" temporary)
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
        TempSegmentLine: Record "Segment Line" temporary;
        InteractionMergeData: Record "Interaction Merge Data";
        WordTemplates: Codeunit "Word Template";
        AttachmentWordTemplateFileName: Text;
        NoOfRecords: Integer;
        Row: Integer;
        MailToValue: Text;
        MergeSourceText: Text;
        EditDoc: Boolean;
        DataSource: Dictionary of [Text, Text];
        DocumentInStream: InStream;
        SaveFormat: Enum "Word Templates Save Format";
    begin
        WindowDialog.Update(6, TransferringDataToMergeTxt);

        if TempDeliverySorter.Find('-') then
            NoOfRecords := TempDeliverySorter.Count();

        Row := 2;

        if TempDeliverySorter."Word Template Code" <> '' then begin
            WindowDialog.Update(6, MergingTxt);

            repeat
                InteractionLogEntry.Get(TempDeliverySorter."No.");
                InteractionMergeData.SetRange(ID);
                InteractionMergeData.Id := CreateGuid();
                InteractionMergeData."Contact No." := InteractionLogEntry."Contact No.";
                InteractionMergeData."Salesperson Code" := InteractionLogEntry."Salesperson Code";
                InteractionMergeData."Log Entry Number" := InteractionLogEntry."Entry No.";
                OnExecuteMergeOnBeforeInteractionMergeDataInsert(InteractionMergeData, InteractionLogEntry);
                InteractionMergeData.Insert();

                MailToValue := GetMailToAddress(InteractionLogEntry, TempDeliverySorter);

                if TempDeliverySorter."Correspondence Type" = TempDeliverySorter."Correspondence Type"::"Hard Copy" then begin
                    if TempDeliverySorter."Attachment No." > 0 then begin
                        Attachment.Get(TempDeliverySorter."Attachment No.");
                        Attachment.CalcFields("Attachment File");
                        Attachment."Attachment File".CreateInStream(DocumentInStream);
                        WordTemplates.Load(DocumentInStream, InteractionLogEntry."Word Template Code");
                    end else
                        WordTemplates.Load(InteractionLogEntry."Word Template Code");

                    SaveFormat := SaveFormat::PDF;
                    OnExecuteMergeOnBeforeMergeWordTemplates(TempDeliverySorter, InteractionLogEntry, SaveFormat);

                    WordTemplates.Merge(InteractionMergeData, false, SaveFormat); // Only merge, do not edit as the document has been edited.
                    WordTemplates.GetDocument(DocumentInStream);
                    SendMergedDocument(DocumentInStream, TempDeliverySorter, MailToValue, InteractionLogEntry);
                    InteractionMergeData.Delete();
                end else begin
                    InteractionMergeData.SetRange(ID, InteractionMergeData.ID); // A filter to current Record is needed

                    EditDoc := TempDeliverySorter."Wizard Action" = Enum::"Interaction Template Wizard Action"::Open;
                    if not InteractionLogEntry.Merged then begin
                        if TempDeliverySorter."Attachment No." > 0 then begin
                            Attachment.Get(TempDeliverySorter."Attachment No.");
                            Attachment.CalcFields("Attachment File");
                            Attachment."Attachment File".CreateInStream(DocumentInStream);
                            WordTemplates.Load(DocumentInStream, InteractionLogEntry."Word Template Code");
                        end else
                            WordTemplates.Load(InteractionLogEntry."Word Template Code");

                        if TempDeliverySorter."Send Word Docs. as Attmt." then
                            WordTemplates.Merge(InteractionMergeData, false, Enum::"Word Templates Save Format"::Docx, EditDoc) // Only one document
                        else
                            WordTemplates.Merge(InteractionMergeData, false, Enum::"Word Templates Save Format"::Html); // Only one document and no edit because Email Editor will open
                        WordTemplates.GetDocument(DocumentInStream); // Should combine PDFs? Attach and see
                    end else begin
                        Attachment.Get(TempDeliverySorter."Attachment No.");
                        Attachment.CalcFields("Attachment File");
                        Attachment."Attachment File".CreateInStream(DocumentInStream);

                        if not TempDeliverySorter."Send Word Docs. as Attmt." then begin
                            WordTemplates.Load(DocumentInStream);
                            WordTemplates.Merge(InteractionMergeData, false, Enum::"Word Templates Save Format"::Html);
                            WordTemplates.GetDocument(DocumentInStream);
                        end;
                    end;
                    SendMergedDocument(DocumentInStream, TempDeliverySorter, MailToValue, InteractionLogEntry);
                    InteractionMergeData.Delete();
                end;
                Row := Row + 1;
                WindowDialog.Update(4, Round(Row / NoOfRecords * 10000, 1));
            until TempDeliverySorter.Next() = 0;
        end else begin
            Attachment.Get(TempDeliverySorter."Attachment No.");
            Attachment.CalcFields("Attachment File");

            TempDeliverySorter.SetCurrentKey("Attachment No.", "Correspondence Type", Subject);
            TempDeliverySorter.Find('-');

            AttachmentWordTemplateFileName := FileManagement.ServerTempFileName('doc');
            Attachment.Get(TempDeliverySorter."Attachment No.");
            Attachment.CalcFields("Attachment File");
            if not IsWordDocumentExtension(Attachment."File Extension") then
                Error(IncorrectExtensionErr, Attachment."No.");

            if not Attachment.ExportAttachmentToServerFile(AttachmentWordTemplateFileName) then
                Error(AttachmentFileErr);

            WindowDialog.Update(6, MergingTxt);
            Attachment.CalcFields("Merge Source");
            if Attachment."Merge Source".HasValue() then
                repeat
                    InteractionLogEntry.Get(TempDeliverySorter."No.");

                    OnExecuteMergeOnAfterGetInteractLogEntry(InteractionLogEntry);

                    MergeSourceText := GetMergeSourceText(Attachment, TempDeliverySorter."No.", TempDeliverySorter."Correspondence Type".AsInteger());
                    DataSource := GetDataSource(MergeSourceText);
                    GetMergedDocumentStream(AttachmentWordTemplateFileName, DataSource, TempDeliverySorter, DocumentInStream);
                    SendMergedDocument(DocumentInStream, TempDeliverySorter, '', InteractionLogEntry);

                    Row := Row + 1;
                    WindowDialog.Update(4, Round(Row / NoOfRecords * 10000, 1))
                until TempDeliverySorter.Next() = 0
            else begin
                if (TempDeliverySorter.Count > 1) and not IsZipArchive() then
                    EnableZipArchive();
                repeat
                    InteractionLogEntry.Get(TempDeliverySorter."No.");

                    MailToValue := GetMailToAddress(InteractionLogEntry, TempDeliverySorter);
                    DataSource := GetDataSource(InteractionLogEntry, TempSegmentLine, MailToValue);
                    GetMergedDocumentStream(AttachmentWordTemplateFileName, DataSource, TempDeliverySorter, DocumentInStream);
                    SendMergedDocument(DocumentInStream, TempDeliverySorter, MailToValue, InteractionLogEntry);

                    Row := Row + 1;
                    WindowDialog.Update(4, Round(Row / NoOfRecords * 10000, 1))
                until TempDeliverySorter.Next() = 0;
            end;
            FileManagement.DeleteServerFile(AttachmentWordTemplateFileName);
        end;

        // Update delivery status on Interaction Log Entry
        if TempDeliverySorter.Find('-') then begin
            InteractionLogEntry.LockTable();
            repeat
                InteractionLogEntry.Get(TempDeliverySorter."No.");
                InteractionLogEntry."Delivery Status" := InteractionLogEntry."Delivery Status"::" ";
                InteractionLogEntry.Modify();
            until TempDeliverySorter.Next() = 0;
            Commit();
        end;
    end;

    local procedure GetMailToAddress(var InteractionLogEntry: Record "Interaction Log Entry"; var TempDeliverySorter: Record "Delivery Sorter" temporary) MailToValue: Text
    begin
        // Specify the recipient of the merged document
        case TempDeliverySorter."Correspondence Type" of
            TempDeliverySorter."Correspondence Type"::Email:
                MailToValue := AttachmentManagement.InteractionEMail(InteractionLogEntry);
            TempDeliverySorter."Correspondence Type"::"Hard Copy":
                MailToValue := '';
        end;
    end;

    local procedure SendMergedDocument(MergedDocumentInStream: InStream; TempDeliverySorter: Record "Delivery Sorter" temporary; ToAddress: Text; InteractionLogEntry: Record "Interaction Log Entry")
    var
        Contact: Record Contact;
        Attachment: Record Attachment;
        DocumentMailing: Codeunit "Document-Mailing";
        DummyTempBlob: Codeunit "Temp Blob";
        HtmlBodyTempBlob: Codeunit "Temp Blob";
        DummyInStream: InStream;
        HtmlBodyOutStream: OutStream;
        FileName: Text;
        SaveToFile: Text;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendMergedDocument(MergedDocumentInStream, TempDeliverySorter, ToAddress, InteractionLogEntry, IsHandled);
        if IsHandled then
            exit;

        HideDialog := TempDeliverySorter."Force Hide Email Dialog" or (not (TempDeliverySorter."Wizard Action" = TempDeliverySorter."Wizard Action"::Open));
        Attachment."Read Only" := true;

        case TempDeliverySorter."Correspondence Type" of
            TempDeliverySorter."Correspondence Type"::Email:
                begin
                    SourceTableIDs.Add(Database::"Interaction Log Entry");
                    SourceIDs.Add(InteractionLogEntry.SystemId);
                    SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

                    if Contact.Get(InteractionLogEntry."Contact No.") then begin
                        SourceTableIDs.Add(Database::Contact);
                        SourceIDs.Add(Contact.SystemId);
                        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
                    end;

                    Attachment.SetAttachmentFileFromStream(MergedDocumentInStream);

                    Attachment."Attachment File".CreateInStream(MergedDocumentInStream, TextEncoding::UTF8);

                    if TempDeliverySorter."Send Word Docs. as Attmt." then begin
                        FileName := TempDeliverySorter.Subject;
                        if TempDeliverySorter.Subject = '' then
                            FileName := 'Attachment';
                        FileName += '.docx';

                        Attachment."File Extension" := 'docx';
                        Clear(HtmlBodyTempBlob);
                        DocumentMailing.EmailFile(MergedDocumentInStream, FileName, HtmlBodyTempBlob, TempDeliverySorter.Subject, ToAddress, HideDialog, Enum::"Email Scenario"::"Interaction Template", SourceTableIDs, SourceIDs, SourceRelationTypes);
                    end else begin
                        HtmlBodyTempBlob.CreateOutStream(HtmlBodyOutStream, TextEncoding::UTF8);
                        CopyStream(HtmlBodyOutStream, MergedDocumentInStream);
                        Attachment."File Extension" := 'html';

                        DummyTempBlob.CreateInStream(DummyInStream);
                        DocumentMailing.EmailFile(DummyInStream, TempDeliverySorter.Subject, HtmlBodyTempBlob, TempDeliverySorter.Subject, ToAddress, HideDialog, Enum::"Email Scenario"::"Interaction Template", SourceTableIDs, SourceIDs, SourceRelationTypes);
                    end;
                    Attachment.Insert(true);

                    InteractionLogEntry."Attachment No." := Attachment."No.";
                    InteractionLogEntry.Modify();
                end;
            TempDeliverySorter."Correspondence Type"::"Hard Copy":
                begin
                    Attachment."File Extension" := 'pdf';
                    Attachment.SetAttachmentFileFromStream(MergedDocumentInStream);
                    Attachment."Attachment File".CreateInStream(MergedDocumentInStream, TextEncoding::UTF8);
                    Attachment.Insert(true);

                    InteractionLogEntry."Attachment No." := Attachment."No.";
                    InteractionLogEntry.Modify();

                    if IsZipArchive() then begin
                        if Contact.Get(InteractionLogEntry."Contact No.") then
                            if (Contact.Type = Contact.Type::Person) and (Contact."Company Name" <> '') then
                                SaveToFile := FileManagement.GetSafeFileName(Contact."Company Name" + ' - ' + Contact.Name) + '.pdf'
                            else
                                SaveToFile := FileManagement.GetSafeFileName(Contact.Name) + '.pdf';
                        DataCompression.AddEntry(MergedDocumentInStream, SaveToFile);
                    end else begin
                        if TempDeliverySorter.Subject = '' then
                            SaveToFile := 'default.pdf'
                        else
                            SaveToFile := FileManagement.GetSafeFileName(TempDeliverySorter.Subject) + '.pdf';

                        FileManagement.DownloadFromStreamHandler(MergedDocumentInStream, '', '', '', SaveToFile);
                    end;
                end;

        end;
    end;

    local procedure GetMergedDocumentStream(AttachmentWordTemplateFileName: Text; DataSource: Dictionary of [Text, Text]; TempDeliverySorter: Record "Delivery Sorter"; var MergedDocumentInStream: InStream)
    var
        EditDoc: Boolean;
    begin
        EditDoc := (TempDeliverySorter."Wizard Action" = Enum::"Interaction Template Wizard Action"::Open) and (TempDeliverySorter."Word Template Code" <> '');
        case TempDeliverySorter."Correspondence Type" of
            TempDeliverySorter."Correspondence Type"::Email:
                MergedDocumentInStream := GetMergedDocument(AttachmentWordTemplateFileName, DataSource, Enum::"Word Templates Save Format"::Html, EditDoc);
            TempDeliverySorter."Correspondence Type"::"Hard Copy":
                MergedDocumentInStream := GetMergedDocument(AttachmentWordTemplateFileName, DataSource, Enum::"Word Templates Save Format"::PDF, EditDoc);
        end;
    end;

    /// <summary>
    /// Download a merged Word template for a given segment line and attachment.
    /// </summary>
    /// <param name="SegLine">Specifies the segment line for which the attachment is for.</param>
    /// <param name="Attachment">Specifies the attachemnt (Word template) to be downloaded.</param>
    procedure RunMergedDocument(var SegLine: Record "Segment Line"; var Attachment: Record Attachment)
    var
        TempInteractLogEntry: Record "Interaction Log Entry" temporary;
        AttachmentWordTemplateFileName: Text;
        MergedDocFilename: Text;
        MergeSourceText: Text;
        DataSource: Dictionary of [Text, Text];
    begin
        if not IsWordDocumentExtension(Attachment."File Extension") then
            Error(IncorrectExtensionErr, Attachment."No.");

        AttachmentWordTemplateFileName := FileManagement.ServerTempFileName('doc');

        if not Attachment.ExportAttachmentToServerFile(AttachmentWordTemplateFileName) then
            Error(AttachmentFileErr);

        Attachment.CalcFields("Merge Source");
        if Attachment."Merge Source".HasValue() then begin
            MergeSourceText := GetMergeSourceText(Attachment, SegLine."Line No.", 0);
            DataSource := GetDataSource(MergeSourceText);
        end else
            DataSource := GetDataSource(TempInteractLogEntry, SegLine, '');

        MergedDocFilename := 'Attachment for contact ' + Format(SegLine."Contact No.") + '.pdf';
        DownloadFromStream(GetMergedDocument(AttachmentWordTemplateFileName, DataSource, Enum::"Word Templates Save Format"::PDF, false), DownloadAttachmentQst, '', '', MergedDocFilename);
        FileManagement.DeleteServerFile(AttachmentWordTemplateFileName);
    end;

    local procedure GetMergedDocument(AttachmentWordTemplateFileName: Text; DataSource: Dictionary of [Text, Text]; WordTemplatesSaveFormat: Enum "Word Templates Save Format"; EditDoc: Boolean): InStream
    var
        WordTemplateFile: File;
        WordTemplateInStream: InStream;
        DocumentInStream: InStream;
    begin
        WordTemplateFile.Open(AttachmentWordTemplateFileName);
        WordTemplateFile.CreateInStream(WordTemplateInStream);
        WordTemplate.Load(WordTemplateInStream);
        WordTemplateFile.Close();

        WordTemplate.Merge(DataSource, WordTemplatesSaveFormat, EditDoc);
        WordTemplate.GetDocument(DocumentInStream);
        exit(DocumentInStream);
    end;

    /// <summary>
    /// Checks if the provided file extension is a Word document extension.
    /// </summary>
    /// <param name="FileExtension">File extension to check.</param>
    /// <returns>True if the provided extension is a Word document extension, false otherwise.</returns>
    procedure IsWordDocumentExtension(FileExtension: Text): Boolean
    begin
        exit(LowerCase(FileExtension) in ['doc', 'docx', '.doc', '.docx']);
    end;

    local procedure GetMergeSourceText(var Attachment: Record Attachment; EntryNo: Integer; CorrespondenceType: Option ,"Hard Copy",Email,Fax): Text
    var
        InteractLogEntry: Record "Interaction Log Entry";
        MergeSourceInStream: InStream;
        CurrentLine: Text;
        NewLine: Text;
        LineIsFound: Boolean;
        HeaderIsReady: Boolean;
        MergeSourceText: Text;
    begin
        Attachment.CalcFields("Merge Source");
        Attachment."Merge Source".CreateInStream(MergeSourceInStream);
        repeat
            MergeSourceInStream.ReadText(CurrentLine);
            if (StrPos(CurrentLine, '<tr>') > 0) and HeaderIsReady then begin
                MergeSourceInStream.ReadText(NewLine);
                if StrPos(NewLine, Format(EntryNo)) > 0 then begin
                    MergeSourceText += CurrentLine;
                    MergeSourceText += NewLine;
                    LineIsFound := true;
                end;
            end;

            if not HeaderIsReady then begin
                MergeSourceText += CurrentLine;
                if StrPos(CurrentLine, '</tr>') > 0 then
                    HeaderIsReady := true
            end
        until LineIsFound or MergeSourceInStream.EOS();

        if LineIsFound then begin
            MergeSourceInStream.ReadText(NewLine);
            while StrPos(NewLine, '</tr>') = 0 do begin
                CurrentLine := NewLine;
                MergeSourceInStream.ReadText(NewLine);
                MergeSourceText += CurrentLine;
            end;
            if InteractLogEntry.Get(EntryNo) then
                case CorrespondenceType of
                    CorrespondenceType::Email:
                        MergeSourceText += '<td>' + AttachmentManagement.InteractionEMail(InteractLogEntry) + '</td>';
                    CorrespondenceType::"Hard Copy":
                        MergeSourceText += '<td></td>';
                end;
            MergeSourceText += NewLine;
        end;
        exit(MergeSourceText);
    end;

    local procedure GetDataSource(MergeSourceText: Text): Dictionary of [Text, Text]
    var
        AllValues: List of [Text];
        DataSource: Dictionary of [Text, Text];
        DataSourceKey: Text;
        DataSourceValue: Text;
        Iterator: Integer;
    begin
        AllValues := GetAllValuesFromHtmlTable(MergeSourceText);

        if AllValues.Count() mod 2 = 1 then
            Error(IncorrectMergeSourceErr);

        for Iterator := 1 to AllValues.Count() / 2 do begin
            DataSourceKey := AllValues.Get(Iterator);
            DataSourceValue := AllValues.Get(AllValues.Count() / 2 + Iterator);
            DataSource.Add(DataSourceKey, DataSourceValue);
        end;

        exit(DataSource);
    end;

    local procedure GetAllValuesFromHtmlTable(HtmlText: Text): List of [Text]
    var
        TempMatches: Record Matches temporary;
        TempGroups: Record Groups temporary;
        Regex: Codeunit Regex;
        TableCellPattern: Text;
        AllCellValues: List of [Text];
    begin
        TableCellPattern := '<td>((.|[\n\r])*?)<\/td>';
        Regex.Match(HtmlText, TableCellPattern, TempMatches);
        repeat
            Regex.Groups(TempMatches, TempGroups);
            TempGroups.Get(1); // Group 1
            AllCellValues.Add(TempGroups.ReadValue());
        until TempMatches.Next() = 0;
        exit(AllCellValues);
    end;

    local procedure GetDataSource(var InteractLogEntry: Record "Interaction Log Entry"; var SegLine: Record "Segment Line"; FaxMailToValue: Text): Dictionary of [Text, Text]
    var
        Salesperson: Record "Salesperson/Purchaser";
        Country: Record "Country/Region";
        Country2: Record "Country/Region";
        Contact: Record Contact;
        CompanyInfo: Record "Company Information";
        RMSetup: Record "Marketing Setup";
        InteractionLogEntry: Record "Interaction Log Entry";
        Language: Codeunit Language;
        MainLanguage: Integer;
        DataSource: Dictionary of [Text, Text];
        ContactAltAddressCode: Code[10];
        LineNo: Text;
        SalesPersonCode: Code[20];
        ContactNo: Code[20];
        LanguageCode: Code[10];
        ActiveDate: Date;
        IsHandled: Boolean;
    begin
        InitMergeFields(InteractLogEntry, SegLine, ContactAltAddressCode, LineNo, SalesPersonCode, ContactNo, LanguageCode, ActiveDate);

        MainLanguage := GlobalLanguage;

        if LanguageCode = '' then begin
            RMSetup.Get();
            if RMSetup."Mergefield Language ID" <> 0 then
                GlobalLanguage := RMSetup."Mergefield Language ID";
        end else
            GlobalLanguage := Language.GetLanguageIdOrDefault(LanguageCode);


        CompanyInfo.Get();
        if not Country2.Get(CompanyInfo."Country/Region Code") then
            Clear(Country2);

        Contact.Get(ContactNo);
        if not Country.Get(Contact."Country/Region Code") then
            Clear(Country);

        if not Salesperson.Get(SalesPersonCode) then
            Clear(Salesperson);

        IsHandled := false;
        OnGetDataSourceOnBeforeAddDataSources(DataSource, InteractionLogEntry, Contact, Salesperson, Country, LineNo, ContactAltAddressCode, LanguageCode, ActiveDate, IsHandled);
        if not IsHandled then begin
            DataSource.Add(InteractionLogEntry.FieldCaption("Entry No."), LineNo);
            DataSource.Add(Contact.TableCaption + MailAddressTxt, GetContactAltAddresses(Contact, ContactAltAddressCode, ActiveDate));
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("No."), Contact."No.");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Company Name"), Contact."Company Name");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption(Name), Contact.Name);
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Name 2"), Contact."Name 2");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption(Address), Contact.Address);
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Address 2"), Contact."Address 2");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Post Code"), Contact."Post Code");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption(City), Contact.City);
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption(County), Contact.County);
            DataSource.Add(Contact.TableCaption + ' ' + Country.TableCaption + ' ' + Country.FieldCaption(Name), Country.Name);
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Job Title"), Contact."Job Title");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Phone No."), Contact."Phone No.");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Fax No."), Contact."Fax No.");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("E-Mail"), Contact."E-Mail");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Mobile Phone No."), Contact."Mobile Phone No.");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("VAT Registration No."), Contact."VAT Registration No.");
            DataSource.Add(Contact.TableCaption + ' ' + Contact.FieldCaption("Home Page"), Contact."Home Page");
            DataSource.Add(FormalSalutationTxt, Contact.GetSalutation("Salutation Formula Salutation Type"::Formal, LanguageCode));
            DataSource.Add(InformalSalutationTxt, Contact.GetSalutation("Salutation Formula Salutation Type"::Informal, LanguageCode));
            DataSource.Add(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption(Code), Salesperson.Code);
            DataSource.Add(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption(Name), Salesperson.Name);
            DataSource.Add(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption("Job Title"), Salesperson."Job Title");
            DataSource.Add(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption("Phone No."), Salesperson."Phone No.");
            DataSource.Add(Salesperson.TableCaption + ' ' + Salesperson.FieldCaption("E-Mail"), Salesperson."E-Mail");
        end;
        if InteractLogEntry.IsEmpty() then begin
            DataSource.Add(DocumentTxt + SegLine.FieldCaption(Date), Format(SegLine.Date));
            DataSource.Add(DocumentTxt + SegLine.FieldCaption("Campaign No."), SegLine."Campaign No.");
            DataSource.Add(DocumentTxt + SegLine.FieldCaption("Segment No."), SegLine."Segment No.");
            DataSource.Add(DocumentTxt + SegLine.FieldCaption(Description), SegLine.Description);
            DataSource.Add(DocumentTxt + SegLine.FieldCaption(Subject), SegLine.Subject);
        end else begin
            DataSource.Add(DocumentTxt + SegLine.FieldCaption(Date), Format(InteractLogEntry.Date));
            DataSource.Add(DocumentTxt + SegLine.FieldCaption("Campaign No."), InteractLogEntry."Campaign No.");
            DataSource.Add(DocumentTxt + SegLine.FieldCaption("Segment No."), InteractLogEntry."Segment No.");
            DataSource.Add(DocumentTxt + SegLine.FieldCaption(Description), InteractLogEntry.Description);
            DataSource.Add(DocumentTxt + SegLine.FieldCaption(Subject), InteractLogEntry.Subject);
        end;

        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(Name), CompanyInfo.Name);
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Name 2"), CompanyInfo."Name 2");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(Address), CompanyInfo.Address);
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Address 2"), CompanyInfo."Address 2");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Post Code"), CompanyInfo."Post Code");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(City), CompanyInfo.City);
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption(County), CompanyInfo.County);
        DataSource.Add(CompanyInfo.TableCaption + ' ' + Country.TableCaption + ' ' + Country.FieldCaption(Name), Country2.Name);
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("VAT Registration No."), CompanyInfo."VAT Registration No.");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Registration No."), CompanyInfo."Registration No.");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Phone No."), CompanyInfo."Phone No.");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Fax No."), CompanyInfo."Fax No.");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Bank Branch No."), CompanyInfo."Bank Branch No.");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Bank Name"), CompanyInfo."Bank Name");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Bank Account No."), CompanyInfo."Bank Account No.");
        DataSource.Add(CompanyInfo.TableCaption + ' ' + CompanyInfo.FieldCaption("Giro No."), CompanyInfo."Giro No.");
        DataSource.Add(FaxMailToTxt, FaxMailToValue);

        OnGetDataSourceOnBeforeRestoreGlobalLanguage(DataSource, InteractLogEntry, SegLine);

        GlobalLanguage := MainLanguage;

        exit(DataSource);
    end;

    local procedure InitMergeFields(var InteractionLogEntry: Record "Interaction Log Entry"; var SegmentLine: Record "Segment Line";
       var ContactAltAddressCode: Code[10]; var LineNo: Text; var SalesPersonCode: Code[20]; var ContactNo: Code[20]; var LanguageCode: Code[10]; var ActiveDate: Date)
    begin
        if InteractionLogEntry.IsEmpty() then begin
            ContactNo := SegmentLine."Contact No.";
            SalesPersonCode := SegmentLine."Salesperson Code";
            LineNo := Format(SegmentLine."Line No.");
            ContactAltAddressCode := SegmentLine."Contact Alt. Address Code";
            LanguageCode := SegmentLine."Language Code";
            ActiveDate := SegmentLine.Date;
        end else begin
            ContactNo := InteractionLogEntry."Contact No.";
            SalesPersonCode := InteractionLogEntry."Salesperson Code";
            LineNo := Format(InteractionLogEntry."Entry No.");
            ContactAltAddressCode := InteractionLogEntry."Contact Alt. Address Code";
            LanguageCode := InteractionLogEntry."Interaction Language Code";
            ActiveDate := InteractionLogEntry.Date;
        end;
    end;

    local procedure GetContactAltAddresses(Contact: Record Contact; ContactAltAddressCode: Code[10]; Date: Date): Text
    var
        FormatAddr: Codeunit "Format Address";
        TypeHelper: Codeunit "Type Helper";
        ContactAddresses: array[8] of Text[100];
        Iterator: Integer;
        Addresses: Text;
    begin
        FormatAddr.ContactAddrAlt(ContactAddresses, Contact, ContactAltAddressCode, Date);
        for Iterator := 1 to 8 do
            if ContactAddresses[Iterator] <> '' then
                Addresses += ContactAddresses[Iterator] + TypeHelper.NewLine();

        exit(Addresses.TrimEnd(TypeHelper.NewLine()));
    end;

    local procedure IsZipArchive(): Boolean
    begin
        exit(ZipArchive)
    end;

    local procedure EnableZipArchive();
    begin
        ZipArchive := true;
        DataCompression.CreateZipArchive();
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCreateInteractionWordTemplate(var WordTemplateCreationWizard: Page "Word Template Creation Wizard")
    begin
    end;

    var
        FileManagement: Codeunit "File Management";
        WordTemplate: Codeunit "Word Template";
        AttachmentManagement: Codeunit AttachmentManagement;
        DataCompression: Codeunit "Data Compression";
        ZipArchive: Boolean;
        WindowDialog: Dialog;
        IncorrectExtensionErr: Label 'Attachment %1 must have file extension doc or docx.', Comment = '%1 = Attachment No.';
        AttachmentFileErr: Label 'Could not get attachment content.';
        FaxMailToTxt: Label 'FaxMailTo';
        MailAddressTxt: Label ' Mail Address';
        DocumentTxt: Label 'Document ';
        FormalSalutationTxt: Label 'Formal Salutation';
        InformalSalutationTxt: Label 'Informal Salutation';
        IncorrectMergeSourceErr: Label 'Incorrect content of the Merge Source';
        MergingInWordTxt: Label 'Merging Microsoft Word Documents...\\';
        PreparingTxt: Label 'Preparing';
        ProgramStatusTxt: Label 'Program status';
        PreparingMergeTxt: Label 'Preparing Merge...';
        TransferringDataToMergeTxt: Label 'Transferring data to merge...';
        MergingTxt: Label 'Merging...';
        DownloadAttachmentQst: Label 'Download merged attachment?';
        SegmentLbl: Label 'Segment';
        ZipExtensionLbl: Label '.zip';

    [IntegrationEvent(false, false)]
    local procedure OnGetDataSourceOnBeforeRestoreGlobalLanguage(var DataSource: Dictionary of [Text, Text]; var InteractLogEntry: Record "Interaction Log Entry"; var SegLine: Record "Segment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendMergedDocument(MergedDocumentInStream: InStream; TempDeliverySorter: Record "Delivery Sorter"; ToAddress: Text; InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteMergeOnBeforeMergeWordTemplates(TempDeliverySorter: Record "Delivery Sorter" temporary; InteractLogEntry: Record "Interaction Log Entry"; var SaveFormat: Enum "Word Templates Save Format")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteMergeOnAfterGetInteractLogEntry(InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDataSourceOnBeforeAddDataSources(var DataSource: Dictionary of [Text, Text]; var InteractionLogEntry: Record "Interaction Log Entry"; var Contact: Record Contact; var SalespersonPurchaser: Record "Salesperson/Purchaser"; var CountryRegion: Record "Country/Region"; LineNo: Text; ContactAltAddressCode: Code[10]; LanguageCode: Code[10]; ActiveDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExecuteMergeOnBeforeInteractionMergeDataInsert(var InteractionMergeData: Record "Interaction Merge Data"; var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;
}
